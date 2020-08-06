# README: 

A helm deployer to github page helm repository.

Unlike DockerHub we do not have a cloud HelmHub accessible to everyone. Only this is available: 
https://hub.helm.sh/charts

But we can turn Github page to a private HelmHub as explained here:
https://helm.sh/docs/topics/chart_repository/#github-pages-example

Objective of this project is to deploy helm chart present in a github repository automatically to this helm chart repository using Travis CI/CD.
An example is given [in this readme here](#CI-CD-pipeline-with-travis). 
 
Note the Helm repository using Github page could be replaced by a Jfrog artifactory.

<!--
Also if we do not want a separate registry we could tar the helm archive in the project.
Tar sounds mandatory.
--> 

## User guide 

### Prerequisite 1: Repo creation

#### Github page basics

We will turn github page feature to an helm registry. 
This repo  will be our helm repository/artifactory. 

From: https://docs.github.com/en/github/working-with-github-pages/about-github-pages#types-of-github-pages-sites
> There are three types of GitHub Pages sites: project, user, and organization.


1. we can create repo inside an orga such as:
    - a `helm-registry.github.io` within organization `helm-registry`. <organisation>
      we can access to it via `helm-registry.github.io`. 
      It is an organisation page.
    - b helm-registry` within organization `helm-registry. 
      we can access to it via `helm-registry.github.io/helm-registry`.
      It is a project page.
2. Or create a user repo
    - a `scoulomb.github.io` within username `scoulomb`. 
     we can access to it via `scoulomb.github.io`. It is usually allocated for user personal page.
     It is a user page.
    - b `helm-registry` within username `scoulomb`. <project>
     we can access to it via `scoulomb.github.io/helm-registry` 
     It is a project page.
   
Note repo `xxxx.github.io` is limited to 1 per orga/username.
A user can be part/own of several organisations.
We can also do actually a la project access for 1a and 2a:
- `helm-registry.github.io/helm-registry.github.io`
- `scoulomb.github.io/scoulomb.github.io`

A user repo has the same behavior as orga repo when it comes to github page.

As explained in [githb page and DNS](appendice-github-page-and-dns.md#what-about-registrycoulombelsite), I recomend option 1a,
for better DNS definition.

#### Operations

In this repo we will perform a git init by adding at least a readme or html index.
Note adding empty ready can be performed via the UI (create file) or at repo creation time.
Then will activate github page for naster branch at /root level (not /doc).


### Prerequisite 2: Generate a github token

`> settings> developer settings > Personal access tokens`, or use this direct [link]( github repo which will be our helm repository/artifactory):

- Generate new token 
- Tick on select scope: `repo`
- Copy your token, for instance `1423a52e3fb0343f4f4f45157d9328d9065f6a72`.

<!--
Github revoke token if copied in the repo!
-->

### Run from docker or docker-compose

For instance using 
- helm chart:  in [soapUI-docker/kubernetes_integration_example](https://github.com/scoulomb/soapui-docker/tree/master/kubernetes_integration_example/helm-k8s-integration)
- registry: [helm-registry/helm-registry.github.io](https://helm-registry.github.io/)

#### Docker

````shell script
➤ docker run scoulomb/github-page-helm-deployer -h                       
usage: ./deliver_helm.sh [-h] --chart <chart-path> --repo <helm-repo> --project <helm-project-name> --url <helm-registry-public-url> --token <github-token>
A script to push helm chart to github helm chart repository. As a prerequisite crate a github repo with readme from the UI and activate github page (master, /root). Check committer name.
Arguments
   -c, --chart         Path to the helm chart to be delivered
   -r, --repo:         Your helm chart github repository <username or organization name>/<repository name>
   -p, --project       Project to update within your helm chart github repository
   -u, --url           URL to the helm registry
   -t, -token          Github token for registry access

Example: See readme at https://github.com/scoulomb/github-page-helm-deployer
````

````shell script
docker run -v "/home/vagrant/dev/soapUI-docker/kubernetes_integration_example/helm-k8s-integration:/tmp/helm-chart" \
scoulomb/github-page-helm-deployer \
-c /tmp/helm-chart \
-r helm-registry/helm-registry.github.io \
-p soapui \
-u helm-registry.github.io \
-t 1423a52e3fb0343f4f4f45157d9328d9065f6a72 
````

#### Delivered compose

````shell script
export TOKEN="<your-token>"
docker-compose -f docker-compose-delivered.yaml up
````

TOKEN is an environment taken by compose file. It is useful for CI/CD pipeline integration.


### CI CD pipeline with travis 

You may want to deliver a new helmchart in helmhub at each delivery of your code.
This is possible via this image and modifying previous docker-compose.

For instance we will use this [project](https://github.com/scoulomb/soapui-docker/tree/master/kubernetes_integration_example#deliver-a-helm-package-in-helmhub).

- [Travis file](https://github.com/scoulomb/soapui-docker/blob/master/.travis.yml#L19)
- [Compose file](https://github.com/scoulomb/soapui-docker/blob/master/docker-compose-deliver-helm-chart.yaml)

it is taking an environment var `TOKEN`, let's define it in Travis.
https://travis-ci.com/github/scoulomb/soapui-docker/settings

<!-- 
Note soapui-Docker travis is launching locally built image of its project
Dockerhub delivers released image used in docker-compose-dockerhub
And delivered image of github-helm-page-deployer are built by dokcerhub from this project
-->

### Usage of helm registry once helm deliverable are pushed


````shell script
sudo minikube start --vm-driver=none
sudo su # Otherwise given kubectl config will not target minikube (but cluster in vagrant kubeconfig, like the one setup by OpenShift)
# See for more details: https://github.com/scoulomb/myk8s/blob/master/Master-Kubectl/kube-config.md
# if user project do instead: helm repo add soapui https://scoulomb.github.io/helm-registry/soapui
helm repo add soapui https://helm-registry.github.io/helm-registry.github.io/soapui
# See it is updated
helm search repo soapui # should see last pushed version
helm uninstall test-helm-k8s-integration 
# https://github.com/scoulomb/soapui-docker/blob/master/kubernetes_integration_example/helm-k8s-integration/values.yaml
helm install test-helm-k8s-integration soapui/helm-k8s-integration  --set args.sender="robot.deploy@gmail.com" --set args.recipient="robot.deploy@gmail.com" --set args.password="<the-password-of-gmail-account>"
watch kubectl get cj
````

<tested ok with 1.20; https://github.com/scoulomb/soapui-docker/commit/93485e15ed00b3e2783c74d43e56d13d4af51d81>

We can also do cf explanation at the [beginning](#github-page-basics): 

````shell script
helm repo add soapui https://helm-registry.github.io/soapui (orga site, though it can be accessible as a project)
````

And since we define a CNAME for `helm.registry.coulombel.site` in [appendice github page and DNS](appendice-github-page-and-dns.md#consequences).
We can do:

````shell script
helm repo add soapui https://helm.registry.coulombel.site/soapui 
````

Output is

````shell script
➤ helm repo add soapui https://helm.registry.coulombel.site/soapui                                                                                                         
"soapui" has been added to your repositories
````

## Dev guide


### Script without docker 

Needs helm and git on machine

````shell script
./deliver_helm.sh \
-c /home/vagrant/dev/soapUI-docker/kubernetes_integration_example/helm-k8s-integration \
-r helm-registry/helm-registry.github.io \
-p soapui \
-u helm-registry.github.io \
-t 1423a52e3fb0343f4f4f45157d9328d9065f6a72
````

<!--
https://stackoverflow.com/questions/18599711/how-can-i-split-a-shell-command-over-multiple-lines-when-using-an-if-statement
No space after \ 
-->

For 2b (if using user project repo) we would do instead, 
`-r scoulomb/helm-registry -u scoulomb.github.io/helm-registry`

Note the full URL path as it is a project repo as explained in repo [creation](#Repo-creation).

### Script with docker 

````shell script
docker build . -t github-page-helm-deployer
# https://docs.docker.com/engine/reference/commandline/run/
docker run github-page-helm-deployer -h
docker run -v "/home/vagrant/dev/soapUI-docker/kubernetes_integration_example/helm-k8s-integration:/tmp/helm-chart" \
github-page-helm-deployer \
-c /tmp/helm-chart \
-r helm-registry/helm-registry.github.io \
-p soapui \
-u helm-registry.github.io \
-t 1423a52e3fb0343f4f4f45157d9328d9065f6a72                        
````

### Script with docker-compose

Adapt [docker-compose](./docker-compose.yaml) file.

````shell script
export TOKEN="<your-token>"
docker-compose up --build
````

### Automatic delivery of deployer

At each master branch merge, a new deployer is released on docker-hub here:
https://hub.docker.com/repository/docker/scoulomb/github-page-helm-deployer

Those images are used in user-guide which can be seen as the next section of this guide.

<!--
[here](README.md#usage-of-helm-registry-once-helm-deliverables-are-pushed)
TODO Optional: We could change the repo index (--url), at delivery time I would expect it to work too (not tried-stop)
-->
