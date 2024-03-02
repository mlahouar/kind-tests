#!/bin/bash

# shellcheck disable=SC2170
# shellcheck disable=SC2170

if [ $# != 1 ]; then
  echo "Only one argument is required (small or ha)"
  exit 1
fi

if [ $1 != "small" ] && [ $1 != "ha" ]; then
  echo "Only 'small' or 'ha' values are accepted as argument !"
  exit 1
fi

echo "## Create kind cluster"
if [ $1 == "small" ]; then
  echo "## Create a single node Kind cluster (1 container)"
  kind create cluster --config=small-cluster-config.yaml
else
  echo "## Create a multi-node Kind cluster (5 containers)"
  kind create cluster --config=ha-cluster-config.yaml
fi


echo "## Deploy ingress (nginx)"
kubectl apply -f nginx.yaml

echo "## Deploy Cert manager"
kubectl create namespace cert-manager
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --version v1.1.0 \
  --set installCRDs=true

echo "## Wait 200s ";sleep 200

echo "#### Add cluster-issuer"
kubectl apply -f ca_key_pair.yaml
echo "## Wait 20s ";sleep 20
kubectl apply -f cert-issuer.yaml

echo "## Deploy argocd (https://argocd.ingress.kind)"
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
echo "## Wait 120s ";sleep 120
echo "#### ArgoCD Ingress :"

kubectl apply -f argocd-ingress.yaml
echo "## Wait 60s ";sleep 60

echo "###### Argo-cd Post install : Get initial password and change it"
argocd login --insecure argocd.ingress.kind --username admin --password $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
argocd account update-password --current-password $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d) --new-password admin123
argocd login --insecure argocd.ingress.kind --username admin --password admin123


echo "###### Argo-cd Post install :  Add kdc01 repo:"
argocd repo add https://github.com/OpenDataPlatform/kdc01.git --username "mlahouar" --password $GITHUB_PASSWORD

echo "## Deploy minio"
kubectl apply -f argocd/minio1.yaml

echo "## Deploy openldap"
kubectl create namespace openldap
helm repo add helm-openldap https://jp-gouin.github.io/helm-openldap/
echo "## Wait 30s ";sleep 30
helm install openldap helm-openldap/openldap-stack-ha --namespace openldap --values=openldap-values.yaml
