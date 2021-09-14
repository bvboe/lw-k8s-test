#!/bin/bash
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <lacework-agent-access-token>"
    exit
fi


echo Creating clusters
kind create cluster --name cip-client-oneagent
kind create cluster --name cip-server-oneagent

echo Deploying Lacework agent on server
kubectl config use-context kind-cip-server-oneagent
kubectl delete namespace lacework
kubectl create namespace lacework
kubectl config set-context --current --namespace lacework
cat lacework-cfg-k8s.yaml | sed "s/insertaccesstoken/$1/" | sed "s/insertkubernetesclusterhere/cip-server-oneagent/" | kubectl apply -f -
kubectl apply -f lacework-k8s.yaml
kubectl config set-context --current --namespace default

echo Deploy server apps
kubectl config use-context kind-cip-server-oneagent
kubectl config set-context --current --namespace default
kubectl apply -f k8s-lw-proxy-test-server.yaml
kubectl apply -f k8s-lw-proxy-test-proxy.yaml
kubectl delete svc k8s-lw-proxy-test-proxy-svc-lb k8s-lw-proxy-test-server-svc-lb

echo Deploy test client
echo Getting IP for Kubernetes server
serverIP=`docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' cip-server-oneagent-control-plane`
echo Server IP: $serverIP
remoteAddress=$serverIP:30000
echo Remote Address: $remoteAddress
kubectl config use-context kind-cip-client-oneagent
kubectl config set-context --current --namespace default
cat k8s-lw-proxy-test-client.yaml | sed "s/insertremoteaddress/$remoteAddress/" | kubectl apply -f -
