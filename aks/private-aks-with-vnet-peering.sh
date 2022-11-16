#!/bin/bash
# AKS - Private Cluster with v-net peering
# Resource Group
APPINFRA_RG=001-Lab-AppInfra-007-RG
APPDEV_RG=001-Lab-AppDev-007-RG
# v-net
APPINFRA_VNET=AppInfraVnet
# private-cluster-name
AKSCLUSTER_NAME=myAKSCluster008
# Location
LOCATION=southeastasia

############## App Infra Structure ########################
az group create --name $APPINFRA_RG --location $LOCATION

##
az network vnet create \
    --resource-group $APPINFRA_RG \
    --name $APPINFRA_VNET \
    --address-prefixes 192.168.0.0/24 \
    --subnet-name myAKSSubnet \
    --subnet-prefix 192.168.0.0/27

SUBNET_ID=$(az network vnet subnet show --resource-group $APPINFRA_RG --vnet-name $APPINFRA_VNET --name myAKSSubnet --query id -o tsv)

# Create an Azure AD group ( ref: https://learn.microsoft.com/en-us/azure/aks/managed-aad ) 
az ad group create --display-name myAKSAdminGroup --mail-nickname myAKSAdminGroup
AAD_AKS_ADMIN_GROUP=$(az ad group list --filter "displayname eq 'myAKSAdminGroup'" --query [].id -o tsv)

az aks create \
    --resource-group $APPINFRA_RG \
    --name $AKSCLUSTER_NAME \
    --node-count 2 \
    --node-vm-size Standard_D2s_v5 \
    --vm-set-type VirtualMachineScaleSets \
    --network-plugin kubenet --network-policy calico \
    --load-balancer-sku standard \
    --vnet-subnet-id $SUBNET_ID \
    --kubernetes-version 1.23.12 \
    --enable-private-cluster \
    --enable-cluster-autoscaler \
    --min-count 2 \
    --max-count 3 \
    --enable-aad --aad-admin-group-object-ids $AAD_AKS_ADMIN_GROUP

############## Applicatio Development  ########################
# APPDEV Resource Group
APPDEV_RG=001-TTB-AppDev-007-RG
## APPDEV VNET
APPDEV_VNET=AppDevVnet

az group create --name $APPDEV_RG --location $LOCATION

### Dev environment
az network vnet create \
    --resource-group $APPDEV_RG \
    --name $APPDEV_VNET \
    --address-prefixes 192.168.2.0/24 \
    --subnet-name myVMSubnet \
    --subnet-prefix 192.168.2.0/27

## ToDO.
# 1. create devVM and ssh to the devVM in  $APPDEV_VNET 
# 1.1. devvm$ https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-linux?pivots=apt
# 1.2. devvm$ az aks get-credentials --resource-group 001-TTB-AppInfra-007-RG --name myAKSCluster008
# 1.3. devvm$ sudo az aks install-cli
#
# 2.VENET peering  $APPINFRA_VNET  with  $APPDEV_VNET 
# 3.create private DNS Zone for $APPDEV_VNET by getting sample data from MC_ group
# 3.1 Add entry in Private DNS Zone for $APPDEV_VNET 
#
# 4.kubectl get nodes
#
# 5.Deploy simple deployment  
# 5.1 External loadbalance ( git clone https://github.com/Azure-Samples/azure-voting-app-redis.git )
# 5.2 Internal loadbalance ( https://raw.githubusercontent.com/fujute/m18h/master/aks/fuju-nginx.yaml )
# 5.3 $devvm$ kubectl get deployment,svc
# 5.4 curl http://<<local IP from svc>>  
## 
# 6. Authenticate with Azure Container Registry from Azure Kubernetes Service " https://learn.microsoft.com/en-us/azure/aks/cluster-container-registry-integration?tabs=azure-cli " 
# 7. Bastion  " https://learn.microsoft.com/en-us/azure/bastion/tutorial-create-host-portal " 
# 8. Create PostgreSQL with private Endpoint and connect from AKS via private Endpoint
# 9. Logging and debuging 
# 10. AKS , Azure Monitor, Log Analytics , and Application Insight ( https://learn.microsoft.com/en-us/azure/azure-monitor/containers/container-insights-overview )
# 11. "https://learn.microsoft.com/en-us/azure/aks/azure-ad-rbac " 
