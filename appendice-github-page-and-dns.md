# Github page and Gandi DNS exploration

Objective is to have a DNS name like `registry.coulombel.site` pointing to our local registry.

## Repos for tests

From [README.md](README.md#github-page-basics).
User repo has same behavior as orga.
Thus we will start exploring solution `1a` and `1b` .

- a `scoulomb.github.io` within username `scoulomb`. 
 we can access to it via `scoulomb.github.io`. 
- b `helm-registry` within username `scoulomb`. <project>
 we can access to it via `scoulomb.github.io/helm-registry` 

Where we will define DNS name pointing to those URLs.

## Go

Defining DNS to github page is documented here:
https://docs.github.com/en/github/working-with-github-pages/managing-a-custom-domain-for-your-github-pages-site

A distinction is made beyween:
- subdomain,
- APEX


### Configure subdomain

[Subdomain doc](https://docs.github.com/en/github/working-with-github-pages/managing-a-custom-domain-for-your-github-pages-site#configuring-a-subdomain
).
 
 I own `coulombel.site`, a subdomain would be:
- `sylvain.coulombel.site` 

It can not be

- `coulombel.site`


We defined in Gandi DNS zone:

````shell script
sylvain 300 IN CNAME scoulomb.github.io.
````

And we activate github page with `scoulomb.github.io` DNS, this will create a CNAME file with that name.

#### Point importance

Note the importance of the point, otherwise we would define
`scoulomb.github.io.coulombel.site.`.

#### Use google DNS

We also changed windows DNS to point to google DNS recursive `8.8.8.8` to access the record.
Reason behind is that my current recursive DNS server has already requested this entry and the TTL was high.

Here is the procedure to change the recursive DNS server from Google:
https://developers.google.com/speed/public-dns/docs/using

#### Results

`scoulomb.github.io` is now accessible from `sylvain.coulombel.site` (and `scoulomb.github.io` is redirected to `sylvain.coulombel.site`).

Note same apply for `https://sylvain.coulombel.site/helm-registry/` and `https://scoulomb.github.io/helm-registry/`

#### Resolution flow

DNS resolution flow is: 
- `sylvain.coulombel.site` ->
-`DNS server` (autho is Gandi)` ->
- redirect to `scoulomb.github.io` ->
- `DNS server` (autho is Github) ->
- redirect to github IP ->
- github uses CNAME file to determine which github page to serve (similar to vhost)

(note that when using directly scoulomb.github.io CNAME file is not needed, as already known from Github)

#### nslookup github

The following output shows that scoulomb.github.io resolves to github IP.
We will make the parallel in [APEX section](#Configure-an-APEX).

````shell script
➤ nslookup scoulomb.github.io 8.8.8.8 (same IP define below in APEX A records)

Address:        8.8.8.8#53

Non-authoritative answer:
Name:   scoulomb.github.io
Address: 185.199.108.153
Name:   scoulomb.github.io
Address: 185.199.109.153
Name:   scoulomb.github.io
Address: 185.199.110.153
Name:   scoulomb.github.io
Address: 185.199.111.153

````


## Configure an APEX

[APEX doc](https://docs.github.com/en/github/working-with-github-pages/managing-a-custom-domain-for-your-github-pages-site#configuring-an-apex-domain).

This enables to define an entry like `coulombel.site` directly.

Using 2 mutual exclusive ways:

### Alias or ANAME:

Alias/ANAME is CNAME equivalent for APEX zone ([Source](https://support.dnsimple.com/articles/differences-between-a-cname-alias-url/)).

CNAME would define `something.coulombel.site`, and ALIAS is `coulombel.site`.

To not be confused with DNAME.

Flow is:
- `coulombel.site` ->
- DNS server redirect to `scoulomb.github.io` (autho is Gandi) ->
- DNS server redirect to github IP (autho is Github) ->
- Github uses CNAME file to determine which github page to serve (similar to vhost)

### A records 

Flow is:
- `coulombel.site` -> 
- DNS server -> 
- redirect to github IP ->
- github uses CNAME file to determine which github page to serve (similar to vhost)

Thus DNS zone file has:

````shell script
# remove gandi parking page A record
@ 300 IN A 185.199.108.153
@ 300 IN A 185.199.109.153
@ 300 IN A 185.199.110.153
@ 300 IN A 185.199.111.153
````

And we activate github page with `scoulomb.github.io` DNS, this will create a CNAME file with that name.
Those IP are the same as `scoulomb.github.io` [nslookup result](#nslookup-github). 

If we need `coulombel.site` and `www.coulombel.site`: 
we need to configure subdomain for [`www`](#Configure-subdomain)). 

````shell script
# remove ganding parking page CNAME record
www 300 IN CNAME scoulomb.github.io.
````

<details><summary>Test www</summary>
<p>

For same reason as [here](#Use-google-DNS).
I will use Ubuntu laptop, using ISP DNS (not google or corpo).
But even better I will plug directly to authoritative DNS.
BUT as this authoritative DNS is not recursive, I will not be able to access records outside of Gandi.
[HERE]
</p>
</details>

This what is done here: https://gist.github.com/matt-bailey/bbbc181d5234c618e4dfe0642ad80297

Though DNS entries are good as using `8.8.8.8` DNS and `nslookup coulombel.site 8.8.8.8` shows correct IP 
DNS entry in proxy could still point to old Gandi placeholder page (A record deleted) which may be be blocked in some machine.

<!--
see private
-->

Can I have both `coulombel.site` and subdomain `sylvain.coulombel.site` ? edit cname in repo to have 
`coulombel.site` 
and `sylvain.coulombel.site` leads to 404.
Note `www` see before seems a particular case.

With A record we could also configure subdomain like sylvain.coulombel.site (not tested).

I would keep [`sylvain.coulombel.site`](#Configure-subdomain)) only for final config.

## What about registry.coulombel.site 

It is not possible directy as we can not create a CNAME to project repo:
https://scoulomb.github.io/helm-registry/

### Solution i

We can use a Gandi web redirection:
For instance:
http://pdf.cv.coulombel.site  -> http://scoulomb.github.io/resume.pdf
http://helm.registry.coulombel.site  -> https://scoulomb.github.io/helm-registry/

In particular for second case it will do
http://helm.registry.coulombel.site -> https://coulombel.site/helm-registry/ (with the APEX records)

Not creating a redirection creates following CNAME in zone file:

````shell script
helm.registry 10800 IN CNAME webredir.vip.gandi.net.
pdf.cv 10800 IN CNAME webredir.vip.gandi.net.
````

<!-- Tested OK -->

#### Solution ii

Use solution `1a` in [README](./README.md#github-page-basics)
We create `helm-registry.github.io` [repo](https://github.com/helm-registry/helm-registry.github.io) within organization `helm-registry`.
we can access to it via `helm-registry.github.io`. 
     
From there we can configure a [subdomain](#configure-subdomain)

## Consequence 

As a consequence final CNAME file

````shell script
sylvain 300 IN CNAME scoulomb.github.io.
helm.registry 300 IN CNAME helm-registry.github.io.
````

Where following repo exists and deploy github page where declare custom DNS in setting (thus CNAME file present in repo):
- https://github.com/scoulomb/scoulomb.github.io
- https://github.com/helm-registry/helm-registry.github.io


or use https://admin.gandi.net/domain/69ba17f6-d4b2-11ea-8b42-00163e8fd4b8/coulombel.site/redirections
+glue