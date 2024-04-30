# Setup a local k8s cluster using Kind

## **Index**

- [Prerequisites](#Prerequisites)
- [Setup](#Setup)
  - [Manual Setup](##Manual setup)
  - [Automatic setup](##Automatic setup)

## Prerequisites
* Kind (tested with 0.22.0)
* Docker-Desktop (tested with 4.26.1, make sure that Advanced/'Allow the default Docker socket to be used (requires password)' box is checked on the docker-desktop configuration panel)
* kubectl (tested with 1.29.2)
* Helm (tested with 3.14.2)
* (Optional) k9s
* Taskfile

___

## Setup
___

### Install Docker Mac Net Connect
Install Docker Mac Net Connect on your machine to be able to connect directly to Docker-for-Mac containers via their IP addresses.

### Create a certificate authority for kind (ca.kind)

    task create-ca

### Create a kind cluster : Automatic setup
You can try to use the setup-kind or the setup-kind-ha tasks to install kind with metallb, cert-manager and nginx-ingress controller.

For a single node cluster (1 container) :

    task setup-kind

For a HA cluster (5 containers) :

    task setup-kind-ha



### Create a kind cluster : Manual setup
#### Create kind cluster
Prepare the cluster config file (X-cluster-config.yaml) and then create the cluster. Kind will create a config file to the KUBECONFIG path (Make sure to set the KUBECONFIG environement variable to set a custom path if needed, ~/.kube/config is the default one).
For a single node cluster (1 container) :
  
    kind create cluster --config=small-cluster-config.yaml
  
For a HA cluster (5 containers) :

    kind create cluster --config=ha-cluster-config.yaml

#### Deploy MetalLB (https://kind.sigs.k8s.io/docs/user/loadbalancer/)
    
    install-metallb

#### Deploy Cert manager
    
    task install-cert-manager

#### Deploy ingress controller (nginx)
    
    task install-nginx-ingress

#### TODO : Install & configure dnsmasq

Install & configure dnsmask on your machine to have a .kind local domain (https://gist.github.com/ogrrd/5831371) 

























