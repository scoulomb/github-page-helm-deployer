#!/bin/bash

helm_chart_location=/home/vagrant/dev/soapUI-docker/kubernetes_integration_example/helm-k8s-integration
helm_repo=https://github.com/scoulomb/helm-registry.git
helm_project='soapui'

function doc {
    echo "usage: ./deliver_helm.sh [-h] --chart <chart-path> --repo <helm-repo> --project <helm-project-name>"
	echo -e "A script to push helm chart to github helm chart repository. As a prerequisite crate a github repo with readme from the UI and activate github page (master, /root). Check committer name."
	echo "Arguments"
	echo "   -c, --chart         Path to the helm chart to be delivered"
	echo "   -r, --repo:         Your helm chart github repository"
	echo "   -p, --project       Project to update within your helm chart github repository"
	echo ""
    echo "Example: ./deliver_helm.sh -c /home/vagrant/dev/soapUI-docker/kubernetes_integration_example/helm-k8s-integration -r https://github.com/scoulomb/helm-registry.git -p soapui "
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
git clone $helm_repo $tmp/helm-registry

echo "== deliver helm package"
helm lint $helm_chart_location
helm package $helm_chart_location --destination $tmp/helm-registry/$helm_project/$date
helm repo index --url https://scoulomb.github.io/helm-registry/soapui $tmp/helm-registry/$helm_project

echo "== update artifactory"
cd $tmp/helm-registry/$helm_project
# https://github.com/scoulomb/myk8s/blob/master/Repo-mgmt/repo-mgmt.md
git config user.name "CI robot"
git config user.email "auto-deployer@coulombel.site"
git add --all 
git commit -m "Push helm deliverable"
echo "=== Push artifactory"
git push

## TEST IT
# sudo su # Otherwise given kubectl config will not target minikube (but cluster in vagrant kubeconfig, like the one setup by OpenShift)
# minikube start --vm-driver=none
# helm repo add soapui https://scoulomb.github.io/helm-registry/soapui
# helm search repo soapui
# helm uninstall test-helm-k8s-integration 
# https://github.com/scoulomb/soapui-docker/blob/master/kubernetes_integration_example/helm-k8s-integration/values.yaml
# helm install test-helm-k8s-integration soapui/helm-k8s-integration  --set args.sender="robot.deploy@gmail.com" --set args.recipient="robot.deploy@gmail.com" --set args.password="241189DECpdp" 
# watch kubectl get cj

# NEXT: CI/CD with alphine image for helm deliveries, credentials?
# DNS
# separate repo?