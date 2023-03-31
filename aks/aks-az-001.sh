#!/bin/bash
# https://learn.microsoft.com/en-us/azure/aks/availability-zones 

RG="1TL-300323-AKSAZ-RG-01"
AKSNAME="myAKSCluster300301"
LOCATION="westus2"

az group create --name ${RG} --location eastus2

# 1.1 Deploy fixed node
az aks create \
    --resource-group ${RG} \
    --name ${AKSNAME} \
    --generate-ssh-keys \
    --node-vm-size standard_d2as_v5 \
    --load-balancer-sku standard \
    --node-count 3 \
    --zones 1 2 3 \
    --location ${LOCATION}

az aks get-credentials --resource-group ${RG} --name ${AKSNAME}

kubectl describe nodes | grep -e "Name:" -e "topology.kubernetes.io/zone"
kubectl get nodes -o custom-columns=NAME:'{.metadata.name}',REGION:'{.metadata.labels.topology\.kubernetes\.io/region}',ZONE:'{metadata.labels.topology\.kubernetes\.io/zone}'

az aks scale --resource-group ${RG} --name ${AKSNAME} --node-count 2
kubectl describe nodes | grep -e "Name:" -e "topology.kubernetes.io/zone"

az aks scale --resource-group ${RG} --name ${AKSNAME} --node-count 3
kubectl describe nodes | grep -e "Name:" -e "topology.kubernetes.io/zone"


## App
kubectl create deployment nginx --image=mcr.microsoft.com/oss/nginx/nginx:1.15.5-alpine
kubectl scale deployment nginx --replicas=3
kubectl describe pod | grep -e "^Name:" -e "^Node:"
## 

## Second Cluster 
RG="1TL-300323-AKSAZ-RG-01"
AKSNAME="myAKSCluster300302"
LOCATION="westus2"

# 1.2 Deploy autoscale
az aks create \
    --resource-group ${RG} \
    --name ${AKSNAME} \
    --generate-ssh-keys \
    --vm-set-type VirtualMachineScaleSets \
    --node-vm-size standard_d2as_v5 \
    --enable-cluster-autoscaler --min-count 3 --max-count 6 \
    --load-balancer-sku standard \
    --node-count 3 \
    --zones 1 2 3 \
    --location ${LOCATION}

az aks get-credentials --resource-group ${RG} --name ${AKSNAME}

kubectl describe nodes | grep -e "Name:" -e "topology.kubernetes.io/zone"
kubectl get nodes -o custom-columns=NAME:'{.metadata.name}',REGION:'{.metadata.labels.topology\.kubernetes\.io/region}',ZONE:'{metadata.labels.topology\.kubernetes\.io/zone}'

# https://learn.microsoft.com/en-us/azure/aks/cluster-autoscaler
az aks update --resource-group ${RG} --name ${AKSNAME} \
  --update-cluster-autoscaler --min-count 2 --max-count 6

kubectl get nodes -o custom-columns=NAME:'{.metadata.name}',REGION:'{.metadata.labels.topology\.kubernetes\.io/region}',ZONE:'{metadata.labels.topology\.kubernetes\.io/zone}'

az aks update --resource-group ${RG} --name ${AKSNAME} \
--update-cluster-autoscaler --min-count 3 --max-count 6

kubectl get nodes -o custom-columns=NAME:'{.metadata.name}',REGION:'{.metadata.labels.topology\.kubernetes\.io/region}',ZONE:'{metadata.labels.topology\.kubernetes\.io/zone}'

# Cleaning 
az group delete --name ${RG} 
