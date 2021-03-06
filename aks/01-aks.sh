#!/bin/bash
az provider register -n Microsoft.ContainerService
# https://docs.microsoft.com/en-us/azure/aks/kubernetes-service-principal
az ad sp create-for-rbac --skip-assignment
az group create --name 1myResourceGroup --location southeastasia
az aks create --resource-group 1myResourceGroup --name myK8sCluster --node-count 1 --generate-ssh-keys
az aks install-cli
az aks get-credentials --resource-group 1myResourceGroup --name myK8sCluster --overwrite
kubectl get nodes
# file location : https://docs.microsoft.com/en-us/azure/aks/kubernetes-walkthrough
kubectl apply -f https://raw.githubusercontent.com/fujute/m18h/master/azure-vote.yaml
kubectl get service azure-vote-front --watch
kubectl create clusterrolebinding kubernetes-dashboard --clusterrole=cluster-admin --serviceaccount=kube-system:kubernetes-dashboard
az aks browse --resource-group 1myResourceGroup --name myK8sCluster
# https://kubernetes.io/docs/reference/kubectl/cheatsheet/
#az aks scale --resource-group 1myResourceGroup --name myK8sCluster --node-count 3
#az aks delete --resource-group 1myResourceGroup --name myK8sCluster
#az group delete --name 1myResourceGroup --yes --no-wait
