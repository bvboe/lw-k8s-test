#!/bin/bash
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <lacework-agent-access-token>"
    exit
fi

echo Creating cluster
minikube start

echo Deploying Lacework agent on server
kubectl config use-context minikube
kubectl create namespace lacework
kubectl config set-context --current --namespace lacework
cat lacework-cfg-k8s.yaml | sed "s/insertaccesstoken/$1/" | sed "s/insertkubernetesclusterhere/minikube-singlek8s/" | kubectl apply -f -
kubectl apply -f lacework-k8s.yaml
kubectl config set-context --current --namespace default

echo Deploy server apps
cd ../k8s-testcase
kubectl config use-context kind-singlek8s
kubectl config set-context --current --namespace default
kubectl apply -f k8s-lw-proxy-test-server.yaml
kubectl apply -f k8s-lw-proxy-test-proxy.yaml
kubectl apply -f k8s-lw-proxy-test-client.yaml
kubectl delete svc k8s-lw-proxy-test-proxy-svc-lb k8s-lw-proxy-test-server-svc-lb
