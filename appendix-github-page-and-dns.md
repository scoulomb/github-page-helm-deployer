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
# coulombel.site zone file
sylvain 300 IN CNAME scoulomb.github.io.
````

And we activate github page with `sylvain.coulombel.site` custom domain, this will create a CNAME file with that name.

#### Point importance

Note the importance of the point, otherwise we would define
`scoulomb.github.io.coulombel.site.`.

#### DNS propagation effect 

We also changed windows DNS to point to google DNS recursive `8.8.8.8` to access the record.
Reason behind is that my current recursive DNS server has already requested this entry and the TTL was high.
More details are given in this [page](https://github.com/scoulomb/myDNS/blob/master/2-advanced-bind/5-real-world-application/3-dns-propagation-effect.md).

Here is the procedure to change the recursive DNS server from Google:
https://developers.google.com/speed/public-dns/docs/using

To set it back apply the reverse and connect/disconnet from network (be careful with update and cache).

#### Results

`scoulomb.github.io` is now accessible from `sylvain.coulombel.site` (and `scoulomb.github.io` is redirected to `sylvain.coulombel.site`).

Note same apply for `https://sylvain.coulombel.site/helm-registry/` and `https://scoulomb.github.io/helm-registry/`

#### Resolution flow

DNS resolution flow is: 
- `sylvain.coulombel.site` ->
-`DNS server` (autho is Gandi) ->
- redirect to `scoulomb.github.io` ->
- `DNS server` (autho is Github) ->
- redirect to github IP ->
- github uses CNAME file to determine which github page to serve (similar to vhost, OpenShift route, K8s Ingress controller)

(note that when using directly scoulomb.github.io CNAME file is not needed, as already known from Github)

#### Mutildomain

Can I have `sylvain.coulombel.site` and `coulombel.it`,
2 CNAMEs to `scoulomb.github.io`?

We can define 2 CNAME but vhost resolution at github will not work.
So that we can not use 2 CNAMES.

Solution is also here to use web redirection from Gandi in `it` domain:
For instance:
````shell script
(1) http://coulombel.it	PERMANENT https://sylvain.coulombel.site		
(2) http://sylvain.coulombel.it	PERMANENT https://scoulomb.github.io
````

When we use  `https://sylvain.coulombel.site`, we can use `https://scoulomb.github.io` and vice versa.
As long as in zone `coulombel.site` we have 

````shell script
# coulombel.site zone file
sylvain	CNAME	300	scoulomb.github.io.
````

Make a test with Gandi live DNS -> Both are working
Note that CNAME pointing to another CNAME does not solve the issue:

````shell script
# coulombel.it zone file
lol	CNAME	300	sylvain.coulombel.site.
````
Leads also to `404 - There isn't a GitHub Pages site here.`

If remove those 2 generated records (and target from another DNS recursive (phone)) to not have cache:

````shell script
@ 10800 IN A 217.70.184.38
sylvain	CNAME	1800	webredir.vip.gandi.net.
````

Note that

````shell script
[vagrant@archlinux myDNS]$ nslookup -type=ptr 217.70.184.38
Server:         10.0.2.3
Address:        10.0.2.3#53

Non-authoritative answer:
38.184.70.217.in-addr.arpa      name = webredir.vip.gandi.net.

Authoritative answers can be found from:
````

<!-- I believed www as generated but actually not confirm it is this behavior when did https://github.com/scoulomb/dns-config -->

If using an external DNS (for it domain) rather than Gandi Live DNS it is still possible to use Gandi redirection but we need to define records in delegated DNS.

This is explained here: https://github.com/scoulomb/myDNS/blob/master/2-advanced-bind/5-real-own-dns-application/2-modify-tld-ns-record.md#About-web-forwarding

External DNS config is the same as our final results here and makes more sense.

We had to chane DNS for same reason as section [above](#DNS-propagation-effect)

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

Note also A resolution in A request:

<!-- Add to show resolution is made in nslookup, as shown in DNS checker APP, broken link but nslookup is A and then AAAA if no specified, we can not give the 2 types otherwise with -t STOP -->

````shell script
sylvain@sylvain-hp:~$ nslookup -type=A sylvain.coulombel.site
Server:		127.0.0.53
Address:	127.0.0.53#53

Non-authoritative answer:
sylvain.coulombel.site	canonical name = scoulomb.github.io.
Name:	scoulomb.github.io
Address: 185.199.109.153
Name:	scoulomb.github.io
Address: 185.199.110.153
Name:	scoulomb.github.io
Address: 185.199.108.153
Name:	scoulomb.github.io
Address: 185.199.111.153

sylvain@sylvain-hp:~$ nslookup -type=CNAME sylvain.coulombel.site
Server:		127.0.0.53
Address:	127.0.0.53#53

Non-authoritative answer:
sylvain.coulombel.site	canonical name = scoulomb.github.io.

Authoritative answers can be found from:

# equivalent of A, cf. https://github.com/scoulomb/myDNS/blob/master/1-basic-bind-lxa/p2-3-DNS-querying.md#run-the-nslookup-command
sylvain@sylvain-hp:~$ nslookup sylvain.coulombel.site
Server:		127.0.0.53
Address:	127.0.0.53#53

Non-authoritative answer:
sylvain.coulombel.site	canonical name = scoulomb.github.io.
Name:	scoulomb.github.io
Address: 185.199.109.153
Name:	scoulomb.github.io
Address: 185.199.110.153
Name:	scoulomb.github.io
Address: 185.199.108.153
Name:	scoulomb.github.io
Address: 185.199.111.153

````


### Configure an APEX

[APEX doc](https://docs.github.com/en/github/working-with-github-pages/managing-a-custom-domain-for-your-github-pages-site#configuring-an-apex-domain).

This enables to define an entry like `coulombel.site` directly.

Using 2 mutual exclusive ways:

#### Alias or ANAME:

Alias/ANAME is CNAME equivalent for APEX zone ([Source](https://support.dnsimple.com/articles/differences-between-a-cname-alias-url/)).

CNAME would define `something.coulombel.site`, and ALIAS is `coulombel.site`.

To not be confused with DNAME.

Flow is:
- `coulombel.site` ->
- DNS server redirect to `scoulomb.github.io` (autho is Gandi) ->
- DNS server redirect to github IP (autho is Github) ->
- Github uses CNAME file to determine which github page to serve (similar to vhost)

#### A records 

Flow is:
- `coulombel.site` -> 
- DNS server -> 
- redirect to github IP ->
- github uses CNAME file to determine which github page to serve (similar to vhost)

Thus DNS zone file has:

````shell script
; remove gandi parking page A record
@ 300 IN A 185.199.108.153
@ 300 IN A 185.199.109.153
@ 300 IN A 185.199.110.153
@ 300 IN A 185.199.111.153
````

And we activate github page for both cases with `scoulomb.github.io` DNS, this will create a CNAME file with that name.
Those IP are the same as `scoulomb.github.io` [nslookup result](#nslookup-github). 

#### APEX and domain living together

##### `www` case

If we need `coulombel.site` and `www.coulombel.site`: 
we need to configure subdomain for [`www`](#Configure-subdomain)). 

````shell script
; remove ganding parking page CNAME record
www 300 IN CNAME scoulomb.github.io.
````

<details><summary>Test with APEX record and `www` subdomain</summary>
<p>

For same reason as [here](#DNS-propagation-effect).
I will use Ubuntu laptop, using ISP DNS (not google or enterprise).
I will plug directly to authoritative DNS.
BUT as this authoritative DNS is not recursive, I will not be able to access records outside of Gandi.

###### Step 1: determine Gandi Autho DNS

````shell script
sylvain@sylvain-hp:~$ nslookup -type=ns coulombel.site
Server:		127.0.0.53
Address:	127.0.0.53#53

Non-authoritative answer:
coulombel.site	nameserver = ns-72-b.gandi.net.
coulombel.site	nameserver = ns-219-c.gandi.net.
coulombel.site	nameserver = ns-252-a.gandi.net.

Authoritative answers can be found from:

sylvain@sylvain-hp:~$ nslookup -type=A ns-252-a.gandi.net 8.8.8.8
Server:		8.8.8.8
Address:	8.8.8.8#53

Non-authoritative answer:
Name:	ns-252-a.gandi.net
Address: 173.246.100.253
````

###### Step 2: Use Gandi DNS

````shell script
sylvain@sylvain-hp:~$ sudo sed -i 's/nameserver.*/nameserver 173.246.100.253/g' /etc/resolv.conf
[sudo] password for sylvain: 
sylvain@sylvain-hp:~$ cat /etc/resolv.conf | grep nameserver
nameserver 173.246.100.253
````

###### Step 3: Configure Gandi DNS to add wwww

Now from another machine (with access to Github domain) I will configure Gandi DNS to have CNAME entry

````shell script
www 300 IN CNAME scoulomb.github.io.
````
###### Step 4: Test it

````shell script
sylvain@sylvain-hp:~$ nslookup www.coulombel.site
Server:		173.246.100.253
Address:	173.246.100.253#53

www.coulombel.site	canonical name = scoulomb.github.io.
** server can't find scoulomb.github.io: REFUSED

sylvain@sylvain-hp:~$ sudo systemd-resolve --flush-caches

Firefox ==> www.coulombel.site WORKING
````

###### Step 5: remove it

Then I will remove it

###### Step 6: Test removal

````shell script
sylvain@sylvain-hp:~$ nslookup www.coulombel.site
Server:		173.246.100.253
Address:	173.246.100.253#53

** server can't find www.coulombel.site: NXDOMAIN


sylvain@sylvain-hp:~$ sudo systemd-resolve --flush-caches

Firefox ==> www.coulombel.site NOT WORKING
````

Note that I had to flush the cache as browser use OS cache, more details here:
- https://www.commentcamarche.net/faq/13384-desactiver-le-cache-dns-de-mozilla-firefox
- https://vitux.com/how-to-flush-the-dns-cache-on-ubuntu/

</p>
</details>

This what is done here: https://gist.github.com/matt-bailey/bbbc181d5234c618e4dfe0642ad80297

 <details><summary>GIST content</summary>
 <p>
 How to set up DNS records on gandi.net to use a custom domain on Github Pages
> You would think it would be easy to find this information, but none of the Github or Gandi documentation is clear so I have recorded the required steps here.

Create the following A records:

```
@ 1800 IN A 185.199.108.153
@ 1800 IN A 185.199.109.153
@ 1800 IN A 185.199.110.153
@ 1800 IN A 185.199.111.153
```

Remove the Gandi parking page A record:

```
@ 10800 IN A 217.70.184.38
```

Create the following CNAME record:

```
www 10800 IN CNAME [github-username].github.io.
```

Remove the Gandi parking page CNAME record:

```
www 1800 IN CNAME webredir.vip.gandi.net.
```

Finally, in your Github repo create a file called `CNAME` which contains your Gandi domain name, e.g. `[my-domain].io`.

Note: If not using `www` for [redirection](#mutildomain) we can use it for this.
 </p>
 </details>
 
###### Blocking

Though DNS entries are good as using `8.8.8.8` DNS and `nslookup coulombel.site 8.8.8.8` shows correct IP 
DNS entry in proxy could still point to old Gandi placeholder page (A record deleted) which may be be blocked in some machine.

<!--
see private: Configure an APEX  (like coulombel.site directly) - BLOCK
-->

##### Other than `www`

Same [multidomain](#mutildomain) question as before.

Can I have both `coulombel.site` and subdomain `sylvain.coulombel.site` ? 
edit cname in repo to have `coulombel.site` 
and `sylvain.coulombel.site` leads to 404.
Note `www` see before seems a particular case.

With A record we could also configure subdomain like sylvain.coulombel.site (not tested).


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

<!-- aligned with [multidomain](#mutildomain), but better to check it has been actually created -->
<!-- Tested OK -->

### Solution ii

Use solution `1a` in [README](./README.md#github-page-basics)
We create `helm-registry.github.io` [repo](https://github.com/helm-registry/helm-registry.github.io) within organization `helm-registry`.
we can access to it via `helm-registry.github.io`. 
     
From there we can configure a [subdomain](#configure-subdomain)

## Consequences 

As a consequence we can be satisifed with [subdomain](#configure-subdomain)  and use [solution ii](#solution-ii) which is pure DNS.

Retore to first back-up and add:

````shell script
sylvain 300 IN CNAME scoulomb.github.io.
helm.registry 300 IN CNAME helm-registry.github.io.
````

Where following repo exists and deploy github page where declare custom DNS in setting (thus CNAME file present in repo):
- https://github.com/scoulomb/scoulomb.github.io (github custom domain is sylvain.coulombel.site)
- https://github.com/helm-registry/helm-registry.github.io (github custom domain is helm.registry.coulombel.site)

They are accessible with

- `sylvain.coulombel.site`
- `helm.registry.coulombel.site`

However it maybe blocked by some proxy. Cf [README](README.md#Usage-of-helm-registry-once-helm-deliverable-are-pushed).
So I will not use it.

## Links

- https://medium.com/@hossainkhan/using-custom-domain-for-github-pages-86b303d3918a
- https://github.com/scoulomb/scoulomb.github.io/settings
- https://docs.github.com/en/github/working-with-github-pages/managing-a-custom-domain-for-your-github-pages-site
- https://admin.gandi.net/domain/69ba17f6-d4b2-11ea-8b42-00163e8fd4b8/coulombel.site/records?view=text
- https://gist.github.com/matt-bailey/bbbc181d5234c618e4dfe0642ad80297

<!--
TODO Optional: try Gandi glue record, mail redirection OK
-->


## Similarities with OpenShift route and Ingress

Reminder k8s:
- https://github.com/scoulomb/myk8s/blob/master/Services/service_deep_dive.md
- https://github.com/scoulomb/myk8s/blob/master/Services/k8s_f5_integration.md

1. Assume we have a query 
    ````shell script
    GET /index.html HTTP/1.1
     
    Host  customer-facing-page.coulombel.it
    Empty body
    ````

2. Then we have a CNAME entry :
    ````shell script
    customer-facing-page.coulombel.it. IN CNAME scoulomb-k8snodes.aws.net.
    ````
3. Then we have a wildcard HOST record rule which is resolving

    ````shell script
    *.scoulomb-k8snodes.aws.net. IN A <ipv4 of k8s node>
    ````
    Where we target one node or DNS RR, or with a load balancer in front instead of targetting directly k8s nodes.
    
    So that
    ````shell script
    customer-facing-page.coulombel.it. resolves to <ipv4 of OpenShift node>
    ````
    
4.  Then the OpenShift router is directing to the correct service using Host header (virtual hosting mechanism)

5. Service redirect to the correct pod

In step 2 we could target directly what the wildcard is targetting with a A
But using a CNAME is convenient for flexibility.

<!--
<-> OS route deep dive
--> 

## Conclusion 

Based on all of this I will determine a DNS config to access `scoulomb.github.io.` in following repo:
https://github.com/scoulomb/dns-config

<!--
page reviewed and aligned with dns-config 23aug2020
-->

