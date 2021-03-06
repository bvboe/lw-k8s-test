#!/bin/bash
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <lacework-agent-access-token>"
    exit
fi

echo Creating clusters
#kind create cluster --name clientnginx-cip-oneagent-client --config kind-config.yaml --image kindest/node:v1.20.7@sha256:cbeaf907fc78ac97ce7b625e4bf0de16e3ea725daf6b04f930bd14c67c671ff9
#kind create cluster --name clientnginx-cip-oneagent-server --config kind-config.yaml --image kindest/node:v1.20.7@sha256:cbeaf907fc78ac97ce7b625e4bf0de16e3ea725daf6b04f930bd14c67c671ff9
kind create cluster --name clientnginx-cip-oneagent-client --image kindest/node:v1.20.7@sha256:cbeaf907fc78ac97ce7b625e4bf0de16e3ea725daf6b04f930bd14c67c671ff9
kind create cluster --name clientnginx-cip-oneagent-server --image kindest/node:v1.20.7@sha256:cbeaf907fc78ac97ce7b625e4bf0de16e3ea725daf6b04f930bd14c67c671ff9

#echo Setup Calico
#kubectl config use-context kind-clientnginx-cip-oneagent-client
#kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
#kubectl config use-context kind-clientnginx-cip-oneagent-server
#kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

echo Deploying Lacework agent on server
kubectl config use-context kind-clientnginx-cip-oneagent-server
kubectl create namespace lacework
kubectl config set-context --current --namespace lacework
cat lacework-cfg-k8s.yaml | sed "s/insertaccesstoken/$1/" | sed "s/insertkubernetesclusterhere/clientnginx-cip-oneagent-server/" | kubectl apply -f -
kubectl apply -f lacework-k8s.yaml
kubectl config set-context --current --namespace default

echo Deploy server apps
kubectl config use-context kind-clientnginx-cip-oneagent-server
kubectl config set-context --current --namespace default
kubectl apply -f k8s-lw-proxy-test-server.yaml
kubectl delete svc k8s-lw-proxy-test-server-svc-lb

echo Deploy test apps
echo Getting IP for Kubernetes server
serverIP=`docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' clientnginx-cip-oneagent-server-control-plane`
echo Server IP: $serverIP
remoteAddress=$serverIP:31000
echo Remote Address: $remoteAddress
kubectl config use-context kind-clientnginx-cip-oneagent-client
kubectl config set-context --current --namespace default
cat k8s-lw-proxy-test-proxy.yaml | sed "s/k8s-lw-proxy-test-server-svc-cip/$remoteAddress/" | kubectl apply -f -
kubectl delete svc k8s-lw-proxy-test-proxy-svc-lb
kubectl apply -f k8s-lw-proxy-test-client.yaml
