#!/bin/bash
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <lacework-agent-access-token>"
    exit
fi

echo Creating clusters
#kind create cluster --name cip-twoagents-client --config kind-config.yaml --image kindest/node:v1.20.7@sha256:cbeaf907fc78ac97ce7b625e4bf0de16e3ea725daf6b04f930bd14c67c671ff9
#kind create cluster --name cip-twoagents-server --config kind-config.yaml --image kindest/node:v1.20.7@sha256:cbeaf907fc78ac97ce7b625e4bf0de16e3ea725daf6b04f930bd14c67c671ff9
kind create cluster --name cip-twoagents-client --image kindest/node:v1.20.7@sha256:cbeaf907fc78ac97ce7b625e4bf0de16e3ea725daf6b04f930bd14c67c671ff9
kind create cluster --name cip-twoagents-server --image kindest/node:v1.20.7@sha256:cbeaf907fc78ac97ce7b625e4bf0de16e3ea725daf6b04f930bd14c67c671ff9

#echo Setup Calico
#kubectl config use-context kind-cip-twoagents-client
#kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
#kubectl config use-context kind-cip-twoagents-server
#kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

echo Deploying Lacework agent on client
kubectl config use-context kind-cip-twoagents-client
kubectl create namespace lacework
kubectl config set-context --current --namespace lacework
cat lacework-cfg-k8s.yaml | sed "s/insertaccesstoken/$1/" | sed "s/insertkubernetesclusterhere/cip-twoagents-client/" | kubectl apply -f -
kubectl apply -f lacework-k8s.yaml
kubectl config set-context --current --namespace default

echo Deploying Lacework agent on server
kubectl config use-context kind-cip-twoagents-server
kubectl create namespace lacework
kubectl config set-context --current --namespace lacework
cat lacework-cfg-k8s.yaml | sed "s/insertaccesstoken/$1/" | sed "s/insertkubernetesclusterhere/cip-twoagents-server/" | kubectl apply -f -
kubectl apply -f lacework-k8s.yaml
kubectl config set-context --current --namespace default

echo Deploy server apps
kubectl config use-context kind-cip-twoagents-server
kubectl config set-context --current --namespace default
kubectl apply -f k8s-lw-proxy-test-server.yaml
kubectl apply -f k8s-lw-proxy-test-proxy.yaml
kubectl delete svc k8s-lw-proxy-test-proxy-svc-lb k8s-lw-proxy-test-server-svc-lb

echo Deploy test client
echo Getting IP for Kubernetes server
serverIP=`docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' cip-twoagents-server-control-plane`
echo Server IP: $serverIP
remoteAddress=$serverIP:30000
echo Remote Address: $remoteAddress
kubectl config use-context kind-cip-twoagents-client
kubectl config set-context --current --namespace default
cat k8s-lw-proxy-test-client.yaml | sed "s/k8s-lw-proxy-test-proxy-svc-cip/$remoteAddress/" | kubectl apply -f -
