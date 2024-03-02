# Setup a local k8s cluster using Kind

## **Index**

- [Prerequisites](#Prerequisites)
- [Setup](#Setup)
  - [Manual Setup](##Manual setup)
  - [Automatic setup](##Automatic setup)
- [Post setup actions ](#Post setup actions )

## Prerequisites
* Kind (tested with 0.22.0)
* Docker-Desktop (tested with 4.26.1, make sure that Advanced/'Allow the default Docker socket to be used (requires password)' box is checked on the docker-desktop configuration panel)
* kubectl (tested with 1.29.2)
* (Optional) k9s
* (Optional) Increase the maximum memory and cpu allocated to Docker

___
#### à faire après : Install dnsmasq

Install & configure dnsmask on your machine to have a .kind local domain (https://gist.github.com/ogrrd/5831371) 

#### Install Docker Mac Net Connect
Install Docker Mac Net Connect on your machine to be able to connect directly to Docker-for-Mac containers via their IP addresses.


#### à faire après : Prepare github credentials (token) :

    export GITHUB_PASSWORD=XXXX

## Setup
___
### à faire après : Automatic setup
You can try to use the setup.sh script. It contains all manual steps we need.

$ ./setup.sh (small or ha)

### Manual setup
#### Create kind cluster
Prepare the cluster config file (X-cluster-config.yaml) and then create the cluster. Kind will create a config file to the KUBECONFIG path (Make sure to set the KUBECONFIG environement variable to set a custom path if needed, ~/.kube/config is the default one).
For a single node cluster (1 container) :
  
    kind create cluster --config=small-cluster-config.yaml
  
For a HA cluster (5 containers) :

    kind create cluster --config=ha-cluster-config.yaml

#### Deploy ingress (nginx)
    helm pull oci://ghcr.io/nginxinc/charts/nginx-ingress --untar --version 1.1.3
    cd nginx-ingress
    kubectl create namespace ingress-nginx
    helm install ingress-nginx . -n ingress-nginx

#### Deploy Cert manager
    kubectl create namespace cert-manager
    helm repo add jetstack https://charts.jetstack.io
    helm repo update
    helm install \
      cert-manager jetstack/cert-manager \
      --namespace cert-manager \
      --version v1.1.0 \
      --set installCRDs=true

###### Add cluster-issuer
    kubectl apply -f ca_key_pair.yaml
    kubectl apply -f cert-issuer.yaml

#### Deploy argocd (https://argocd.ingress.kind)
    kubectl create namespace argocd
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
###### ArgoCD Ingress :
    kubectl apply -f argocd-ingress.yaml

###### Argo-cd Post install

Get initial password and change it

(KUBECONFIG must be set to target cluster as admin)
    
    argocd login argocd.ingress.kind --username admin --password $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
    argocd account update-password --current-password $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d) --new-password admin123
    argocd login argocd.ingress.kind --username admin --password admin123

###### Add kdc01 repo:

```
argocd repo add https://github.com/OpenDataPlatform/kdc01.git --username "mlahouar" --password <pull kdc01 token>
```

#### Deploy minio
    kubectl apply -f argocd/minio1.yaml

You should sync the argocd app just after.
#### Deploy openldap
    kubectl create namespace openldap
    helm repo add helm-openldap https://jp-gouin.github.io/helm-openldap/
    helm install openldap helm-openldap/openldap-stack-ha --namespace openldap --values=openldap-values.yaml

## Post setup actions 
___
#### Patch coredns 
You should edit the coredns configMap (kube-system/coredns) in order to redirect all *.ingress.kind traffic to nginx ingress controller :

       ready
     + rewrite name regex .*\.ingress\.kind ingress-nginx-controller.ingress-nginx.svc.cluster.local
       kubernetes cluster.local in-addr.arpa ip6.arpa {

ref : https://coredns.io/2017/05/08/custom-dns-entries-for-kubernetes/)

And then restart coredns.

