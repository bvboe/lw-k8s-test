#!/bin/bash
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <lacework-agent-access-token>"
    exit
fi

echo Creating clusters
kind create cluster --name lb-twoagents-client
kind create cluster --name lb-twoagents-server

echo Deploying Lacework agent on client
kubectl config use-context kind-lb-twoagents-client
kubectl create namespace lacework
kubectl config set-context --current --namespace lacework
cat lacework-cfg-k8s.yaml | sed "s/insertaccesstoken/$1/" | sed "s/insertkubernetesclusterhere/lb-twoagents-client/" | kubectl apply -f -
kubectl apply -f lacework-k8s.yaml
kubectl config set-context --current --namespace default

echo Deploying Lacework agent on server
kubectl config use-context kind-lb-twoagents-server
kubectl create namespace lacework
kubectl config set-context --current --namespace lacework
cat lacework-cfg-k8s.yaml | sed "s/insertaccesstoken/$1/" | sed "s/insertkubernetesclusterhere/lb-twoagents-server/" | kubectl apply -f -
kubectl apply -f lacework-k8s.yaml
kubectl config set-context --current --namespace default

echo Install MetalLB
kubectl config use-context kind-lb-twoagents-server
kubectl config set-context --current --namespace default
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.10.2/manifests/namespace.yaml
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.10.2/manifests/metallb.yaml
kubectl create -f metallb-conf.yaml

echo Deploy server apps
kubectl config use-context kind-lb-twoagents-server
kubectl config set-context --current --namespace default
kubectl apply -f k8s-lw-proxy-test-server.yaml
kubectl apply -f k8s-lw-proxy-test-proxy.yaml
kubectl delete service k8s-lw-proxy-test-proxy-svc-np

echo Wait for all services to be up and running
kubectl config use-context kind-lb-twoagents-server
kubectl config set-context --current --namespace default
kubectl get svc -A | grep pending
while [ `kubectl get svc -A | grep pending | wc -l` -ne 0 ]
do
    kubectl get svc -A | grep pending
    sleep 1
done

echo Deploy test client
echo Getting IP for Kubernetes server
kubectl config use-context kind-lb-twoagents-server
kubectl config set-context --current --namespace default
serverIP=`kubectl get service k8s-lw-proxy-test-proxy-svc-lb -o jsonpath="{.status.loadBalancer.ingress[0].ip}"`
echo Server IP: $serverIP
kubectl config use-context kind-lb-twoagents-client
kubectl config set-context --current --namespace default
cat k8s-lw-proxy-test-client.yaml | sed "s/insertremoteaddress/$serverIP/" | kubectl apply -f -
