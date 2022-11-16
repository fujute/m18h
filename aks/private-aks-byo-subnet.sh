#!/bin/bash
# Creating AKS with " Bring your own subnet and route table with kubenet "
# To Address the following error messages.
#
#(CustomRouteTableWithUnsupportedMSIType) Clusters using managed identity type SystemAssigned do not support bringing your own route table. Please see https://aka.ms/aks/customrt for more information
#Code: CustomRouteTableWithUnsupportedMSIType
#Message: Clusters using managed identity type SystemAssigned do not support bringing your own route table. Please see https://aka.ms/aks/customrt for more information
#
# Reference : https://learn.microsoft.com/en-us/azure/aks/configure-kubenet
# Options for connecting to the private cluster ( https://learn.microsoft.com/en-us/azure/aks/private-clusters )

# Create Resource Group
_SN=005
_RN=009
PROJECT_ID=FUJU-$(( $RANDOM %100 + 1 ))
APPINFRA_RG=$_SN-Lab-AppInfra-$_RN-RG
APPDEV_RG=$_SN-Lab-AppDev-$_RN-RG
##
RANDOM_PWD=$(openssl rand -base64 12)
# v-net
APPINFRA_VNET=AppInfraVnet
# private-cluster-name
AKSCLUSTER_NAME=myAKSCluster$_RN
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

az network nsg create --resource-group $APPINFRA_RG --name MyDBSubnetNsg

az network vnet subnet create -g $APPINFRA_RG --vnet-name $APPINFRA_VNET -n MyDBSubnet \
    --address-prefixes 192.168.0.32/27  --network-security-group MyDBSubnetNsg 

az network nsg create --resource-group $APPINFRA_RG --name MyVMSubnetNsg    
	
az network vnet subnet create -g $APPINFRA_RG --vnet-name $APPINFRA_VNET -n MyVMSubnet \
    --address-prefixes 192.168.0.64/27 --network-security-group MyVMSubnetNsg 

SUBNET_ID=$(az network vnet subnet show --resource-group $APPINFRA_RG --vnet-name $APPINFRA_VNET --name myAKSSubnet --query id -o tsv)

# Create an AKS cluster with user-assigned managed identities

az identity create --name myIdentity$_RN --resource-group $APPINFRA_RG
#az identity show --ids <identity-resource-id>
IDENTITY_ID=$(az identity show --name myIdentity$_RN --resource-group $APPINFRA_RG --query id -o tsv)

echo $IDENTITY_ID

# Create ARC
## https://learn.microsoft.com/en-us/azure/aks/cluster-container-registry-integration?tabs=azure-cli
# set this to the name of your Azure Container Registry.  It must be globally unique
MYACR=myacregistry$_RN

# Run the following line to create an Azure Container Registry if you do not already have one
az acr create -n $MYACR -g $APPINFRA_RG --sku basic

# Create an AKS cluster with ACR integration
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
    --assign-identity $IDENTITY_ID \
    --enable-addons azure-keyvault-secrets-provider \
    --attach-acr $MYACR

# Offer = 0001-com-ubuntu-server-jammy , Plan = 22_04-lts-gen2 , Publisher = canonical
# az vm image list-skus --location southeastasia --offer 0001-com-ubuntu-server-jammy --publisher Canonical
# az vm image list -p canonical --location southeastasia -o table --all | grep 22_04-lts
# Canonical:0001-com-ubuntu-server-jammy:22_04-lts-gen2:latest
# Canonical:0001-com-ubuntu-server-jammy:22_04-lts-gen2:22.04.202211011
# 
az vm create \
  --resource-group $APPINFRA_RG \
  --name myVM$PROJECT_ID \
  --image Canonical:0001-com-ubuntu-server-jammy:22_04-lts-gen2:latest \
  --admin-username kouprex \
  --ssh-key-values $HOME/.ssh/id_rsa.pub \
  --vnet-name $APPINFRA_VNET \
  --subnet MyVMSubnet \
  --public-ip-address "" \
  --public-ip-sku Standard \
  --output json \
  --verbose

az vm run-command invoke \
   -g $APPINFRA_RG \
   -n myVM$PROJECT_ID \
   --command-id RunShellScript \
   --scripts "sudo apt-get update && curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash "

# Testing 
# https://learn.microsoft.com/en-us/azure/aks/cluster-container-registry-integration?tabs=azure-cli
az acr import  -n $MYACR --source docker.io/library/nginx:latest --image nginx:v1
#curl -s -Lo fuju-nginx https://raw.githubusercontent.com/fujute/m18h/master/aks/fuju-nginx.yaml
# image: $MYACR.azurecr.io/nginx:v1

# create private dns zone
az network private-dns zone create -g $APPINFRA_RG -n $PROJECT_ID.private.postgres.database.azure.com

# echo $RANDOM_PWD
DBSUBNET_ID=$(az network vnet subnet show --resource-group $APPINFRA_RG --vnet-name $APPINFRA_VNET --name MyDBSubnet --query id -o tsv)

PSQL_DNS=$(az network private-dns zone show --resource-group  $APPINFRA_RG -n $PROJECT_ID.private.postgres.database.azure.com  --query id -o tsv)

az postgres flexible-server create --resource-group $APPINFRA_RG --name ${PROJECT_ID}psqlsvr \
  --admin-user pgadmin --admin-password $RANDOM_PWD \
  --sku-name Standard_B1ms --tier Burstable --version 13 \
  --vnet $APPINFRA_VNET  --subnet MyDBSubnet --location  $LOCATION \
  --private-dns-zone $PSQL_DNS

az vm run-command invoke \
   -g $APPINFRA_RG \
   -n myVM$PROJECT_ID \
   --command-id RunShellScript \
   --scripts "sudo apt-get update -y && sudo apt-get upgrade -y && sudo apt install  postgresql-client -y"


# psql "host=$PROJECT_ID.private.postgres.database.azure.com port=5432 dbname={your_database} user=pgadmin password={your_password} sslmode=require"

echo "PostgreSQL : $RANDOM_PWD "


# Todo:
# 1. https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/tutorial-django-aks-database
