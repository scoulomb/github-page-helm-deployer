#!/bin/bash

helm_chart_location=/home/vagrant/dev/soapUI-docker/kubernetes_integration_example/helm-k8s-integration \
helm_repo=helm-registry/helm-registry.github.io
helm_project='soapui'
url=helm-registry.github.io \
token=1423a52e3fb0343f4f4f45157d9328d9065f6a72

function doc {
  echo "usage: ./deliver_helm.sh [-h] --chart <chart-path> --repo <helm-repo> --project <helm-project-name> --url <helm-registry-public-url> --token <github-token>"
	echo -e "A script to push helm chart to github helm chart repository. As a prerequisite crate a github repo with readme from the UI and activate github page (master, /root). Check committer name."
	echo "Arguments"
	echo "   -c, --chart         Path to the helm chart to be delivered"
	echo "   -r, --repo:         Your helm chart github repository <username or organization name>/<repository name>"
	echo "   -p, --project       Project to update within your helm chart github repository"
	echo "   -u, --url           URL to the helm registry"
	echo "   -t, -token          Github token for registry access"
	echo ""
  echo "Example: See readme at https://github.com/scoulomb/github-page-helm-deployer"
}

# Credits for args parsing: http://linuxcommand.org/lc3_wss0120.php
while [ "$1" != "" ]; do
    case $1 in
        -c | --chart )          shift
                                helm_chart_location=$1
                                ;;
        -r | --repo )           shift
		                            helm_repo=$1
                                ;;
        -p | --project )        shift
		                            helm_project=$1
                                ;;
        -u | --url )            shift
		                            url=$1
                                ;;
        -t | --token )          shift
		                            token=$1
                                ;;
        -h | --help )           doc
                                exit
                                ;;
        * )                     doc
                                exit 1
    esac
    shift
done


echo "tmp folder"
tmp="$(mktemp -d)"
date="$(date +'%Y_%m_%d_%H_%M_%S')"
cd $tmp

echo "== cloning artifactory"
git clone https://github.com/${helm_repo}.git $tmp/helm-registry

echo "== deliver helm package"
helm lint $helm_chart_location
helm package $helm_chart_location --destination $tmp/helm-registry/$helm_project/$date
helm repo index --url https://$url/$helm_project $tmp/helm-registry/$helm_project
cat $tmp/helm-registry/$helm_project/index.yaml
echo "== update artifactory"
cd $tmp/helm-registry/$helm_project
# https://github.com/scoulomb/myk8s/blob/master/Repo-mgmt/repo-mgmt.md
git config user.name "CI robot"
git config user.email "auto-deployer@coulombel.site"

git remote rm origin
# Add new "origin" with access token in the git URL for authentication

# Credits to https://www.vinaygopinath.me/blog/tech/commit-to-master-branch-on-github-using-travis-ci/ for gh token as env var
git remote add origin https://dummySinceTokenIsUsed:${token}@github.com/${helm_repo}.git #> /dev/null 2>&1
git remote -v
git add --all 
git commit -m "Push helm deliverable"
echo "=== Push artifactory"
git push origin master
