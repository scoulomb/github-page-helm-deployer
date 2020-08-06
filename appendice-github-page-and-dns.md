# Github page and Gandi DNS exploration

we will explore 1a and 1b as orga works the same
and decude use helm project
## Github page type 

https://docs.github.com/en/github/working-with-github-pages/about-github-pages#types-of-github-pages-sites

> There are three types of GitHub Pages sites: project, user, and organization.

## Repos for tests

- https://scoulomb.github.io/ (user site, repo scoulomb.github.io of user scoulomb). HTML and fgithub page activated.
- https://scoulomb.github.io/helm-registry/ (project site). A readme and github page activated.
- https://scoulomb.github.io/scoulomb.github.io/  (user site used like a project site)

And an organisation site behaves as a user site.
Each user/orga can have only 1 user/orga site, but multiple project side.
A user can be part of several orga.



## Configure subdomain
 
(like sylvain.coulombel.site but not coulombel.site) for page

https://docs.github.com/en/github/working-with-github-pages/managing-a-custom-domain-for-your-github-pages-site#configuring-a-subdomain

We defined

````shell script
sylvain 300 IN CNAME scoulomb.github.io.
````


change windows DNS to `8.8.8.8` to access site if not replicated in current DNS server (as ttl too long and retrieved in current dns server)
https://developers.google.com/speed/public-dns/docs/using

`scoulomb.github.io` is now accessible from `sylvain.coulombel.site` (and `scoulomb.github.io` is redirected to `sylvain.coulombel.site`)

Note same apply for `https://sylvain.coulombel.site/helm-registry/` and `https://scoulomb.github.io/helm-registry/`

Flow is 

`sylvain.coulombel.site` -> `DNS server (autho is Gandi)` -> redirect to `scoulomb.github.io` -> `DNS server` (autho is github)-> redirect to github IP -> github uses CNAME file to determine which github page to serve (similar to vhost)

(note that when using directly scoulomb.github.io CNAME file is not needed, as already known from Github)

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


## Configure an APEX  (like coulombel.site directly) ,

https://docs.github.com/en/github/working-with-github-pages/managing-a-custom-domain-for-your-github-pages-site#configuring-a-subdomain

Using 2 ways:

- Alias:

Flow is `coulombel.site` -> DNS server -> redirect to `scoulomb.github.io` -> DNS server -> redirect to github IP -> github uses CNAME file to determine which github page to serve (similar to vhost)

- A records (with A record we could also configure subdomain like sylvain.coulombel.site):

Flow is `coulombel.site` -> DNS server -> redirect to github IP -> github uses CNAME file to determine which github page to serve (similar to vhost)


if we need `coulombel.site` and `www.coulombel.site` (we need to configure subdomain for [`www`](#Configure-subdomain)). Confirm www is not setup.

This what is done here: https://gist.github.com/matt-bailey/bbbc181d5234c618e4dfe0642ad80297

Though DNS entries are good as using `8.8.8.8` DNS and `nslookup coulombel.site 8.8.8.8` shows correct IP 
DNS entry in proxy could still point to old Gandi placeholder page (A record deleted) which may be be blocked in some machine.

<!--
see private
-->

I can not have  both with `coulombel.site` ? edit cname in repo to have 
`coulombel.site` 
and `sylvain.coulombel.site` leads to 404.

I would keep [`sylvain.coulombel.site`](#Configure-subdomain)) only for final config.

## What about registry.coulombel.site 

It is not possible directy as we can not create a CNAME to:
https://scoulomb.github.io/helm-registry/

So either we use scoulomb.github.io or use an orga (case 1a)
 
We will create in orga helm registry repo helm-registry.githin.io
Sp that as expained above we will have helm-registry.githin.io and the abilty to define an alias 
registry.coulombel.site as done configure subdomain for scoulomb.github.io.

to create https://helm-registry.github.io/.
And use subdomain [configuration](#Configure-subdomain).

or use https://admin.gandi.net/domain/69ba17f6-d4b2-11ea-8b42-00163e8fd4b8/coulombel.site/redirections
+glue