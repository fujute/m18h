#!/bin/bash
# Modified from Original from  https://learn.microsoft.com/en-us/azure/aks/limit-egress-traffic  to run AKS with kubenet
# 12-12-2022
_RN=01
PREFIX="aks-egress"
RG="101-${PREFIX}-rg"
LOC="eastasia"
PLUGIN=azure
AKSNAME="${PREFIX}"
VNET_NAME="${PREFIX}-vnet"
AKSSUBNET_NAME="aks-subnet"
VMSUBNET_NAME="vm-subnet"
# DO NOT CHANGE FWSUBNET_NAME - This is currently a requirement for Azure Firewall.
FWSUBNET_NAME="AzureFirewallSubnet"
FWNAME="${PREFIX}-fw"
FWPUBLICIP_NAME="${PREFIX}-fwpublicip"
FWIPCONFIG_NAME="${PREFIX}-fwconfig"
FWROUTE_TABLE_NAME="${PREFIX}-fwrt"
FWROUTE_NAME="${PREFIX}-fwrn"
FWROUTE_NAME_INTERNET="${PREFIX}-fwinternet"
##
MYACR=myacregistry001
PROJECT_ID=001
VMADMIN_USERNAME=azureadmin 
##

# Create Resource Group
az group create --name $RG --location $LOC


# Dedicated virtual network with AKS subnet
az network vnet create \
    --resource-group $RG \
    --name $VNET_NAME \
    --location $LOC \
    --address-prefixes 10.42.0.0/16 \
    --subnet-name $AKSSUBNET_NAME \
    --subnet-prefix 10.42.1.0/24

# Dedicated subnet for Azure Firewall (Firewall name cannot be changed)
az network vnet subnet create \
    --resource-group $RG \
    --vnet-name $VNET_NAME \
    --name $FWSUBNET_NAME \
    --address-prefix 10.42.2.0/24
	
	
az network public-ip create -g $RG -n $FWPUBLICIP_NAME -l $LOC --sku "Standard"

# Install Azure Firewall preview CLI extension
az extension add --name azure-firewall

# Deploy Azure Firewall
az network firewall create -g $RG -n $FWNAME -l $LOC --enable-dns-proxy true


# Configure Firewall IP Config
az network firewall ip-config create -g $RG -f $FWNAME -n $FWIPCONFIG_NAME --public-ip-address $FWPUBLICIP_NAME --vnet-name $VNET_NAME


# Capture Firewall IP Address for Later Use
FWPUBLIC_IP=$(az network public-ip show -g $RG -n $FWPUBLICIP_NAME --query "ipAddress" -o tsv)
FWPRIVATE_IP=$(az network firewall show -g $RG -n $FWNAME --query "ipConfigurations[0].privateIpAddress" -o tsv)


# Create UDR and add a route for Azure Firewall
az network route-table create -g $RG -l $LOC --name $FWROUTE_TABLE_NAME
az network route-table route create -g $RG --name $FWROUTE_NAME --route-table-name $FWROUTE_TABLE_NAME --address-prefix 0.0.0.0/0 --next-hop-type VirtualAppliance --next-hop-ip-address $FWPRIVATE_IP
az network route-table route create -g $RG --name $FWROUTE_NAME_INTERNET --route-table-name $FWROUTE_TABLE_NAME --address-prefix $FWPUBLIC_IP/32 --next-hop-type Internet


# Add FW Network Rules
az network firewall network-rule create -g $RG -f $FWNAME --collection-name 'aksfwnr' -n 'apiudp' --protocols 'UDP' --source-addresses '*' --destination-addresses "AzureCloud.$LOC" --destination-ports 1194 --action allow --priority 100
az network firewall network-rule create -g $RG -f $FWNAME --collection-name 'aksfwnr' -n 'apitcp' --protocols 'TCP' --source-addresses '*' --destination-addresses "AzureCloud.$LOC" --destination-ports 9000
az network firewall network-rule create -g $RG -f $FWNAME --collection-name 'aksfwnr' -n 'time' --protocols 'UDP' --source-addresses '*' --destination-fqdns 'ntp.ubuntu.com' --destination-ports 123

# Add FW Application Rules
az network firewall application-rule create -g $RG -f $FWNAME --collection-name 'aksfwar' -n 'fqdn' --source-addresses '*' --protocols 'http=80' 'https=443' --fqdn-tags "AzureKubernetesService" --action allow --priority 100


# Associate route table with next hop to Firewall to the AKS subnet
az network vnet subnet update -g $RG --vnet-name $VNET_NAME --name $AKSSUBNET_NAME --route-table $FWROUTE_TABLE_NAME

SUBNETID=$(az network vnet subnet show -g $RG --vnet-name $VNET_NAME --name $AKSSUBNET_NAME --query id -o tsv)

##### AKS with CNI #########################
#az aks create -g $RG -n $AKSNAME -l $LOC \
#  --node-count 3 \
#  --network-plugin azure \
#  --outbound-type userDefinedRouting \
#  --vnet-subnet-id $SUBNETID \
#  --api-server-authorized-ip-ranges $FWPUBLIC_IP
#  
#### AKS with CNI ######################### 
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
##### AKS with kubnet #########################
az identity create --name myIdentity$PROJECT_ID --resource-group $RG
#az identity show --ids <identity-resource-id>
IDENTITY_ID=$(az identity show --name myIdentity$PROJECT_ID --resource-group $RG --query id -o tsv)

az identity create --name myKubeletIdentity$PROJECT_ID --resource-group $RG
KUBELET_IDENTITY_ID=$(az identity show --name myKubeletIdentity$PROJECT_ID --resource-group $RG --query id -o tsv)

echo $IDENTITY_ID 
echo $KUBELET_IDENTITY_ID

MYACR=myacregistry001
echo $MYACR

# Run the following line to create an Azure Container Registry if you do not already have one
az acr create -n $MYACR -g $RG --sku basic

# Create an AKS cluster with ACR integration and outbound-type = userDefinedRouting
##   --api-server-authorized-ip-ranges $FWPUBLIC_IP \ ## --api-server-authorized-ip-ranges is not supported for private cluster
## 
## Add role assignment for managed identity
#az role assignment create --assignee <control-plane-identity-principal-id> --scope $VNET_ID --role "Network Contributor"
#az role assignment create --assignee $IDENTITY_ID --scope $VNET_ID --role "Network Contributor"
## ref: https://learn.microsoft.com/en-us/azure/aks/configure-kubenet#bring-your-own-subnet-and-route-table-with-kubenet

#  *** Add "$IDENTITY_ID" to routetable
RT_ID=$(az network route-table show --name $FWROUTE_TABLE_NAME --resource-group $RG --query id -o tsv)
OBJECT_ID=$(az identity show --name myIdentity$PROJECT_ID --resource-group $RG --query principalId -o tsv)

az role assignment create --assignee-object-id $OBJECT_ID \
--assignee-principal-type "ServicePrincipal" \
--scope $RT_ID \
--role "Network Contributor"

# creat AKS private cluster 
az aks create -g $RG -n $AKSNAME -l $LOC \
  --node-count 2 --node-vm-size Standard_D2s_v5 --vm-set-type VirtualMachineScaleSets \
  --network-plugin kubenet --network-policy calico \
  --outbound-type userDefinedRouting \
  --vnet-subnet-id $SUBNETID \
  --enable-managed-identity \
  --assign-identity $IDENTITY_ID \
  --assign-kubelet-identity $KUBELET_IDENTITY_ID \
  --kubernetes-version 1.24.3 \
  --enable-private-cluster \
  --enable-cluster-autoscaler --min-count 2 --max-count 3 \
  --enable-addons azure-keyvault-secrets-provider \
  --load-balancer-sku standard \
  --attach-acr $MYACR 

# Testing 101
#
# create VM Subnet
# VM subnet for VM client to Private AKS )
az network vnet subnet create \
    --resource-group $RG \
    --vnet-name $VNET_NAME \
    --name $VMSUBNET_NAME \
    --address-prefix 10.42.3.0/24
# create myVM001
az vm create \
  --resource-group $RG \
  --name my2VM${PROJECT_ID} \
  --image Canonical:0001-com-ubuntu-server-jammy:22_04-lts-gen2:latest \
  --admin-username $VMADMIN_USERNAME \
  --ssh-key-values $HOME/.ssh/id_rsa.pub \
  --vnet-name $VNET_NAME \
  --subnet $VMSUBNET_NAME  \
  --public-ip-sku Standard \
  --output json \
  --verbose

az vm run-command invoke \
   -g $RG \
   -n my2VM$PROJECT_ID \
   --command-id RunShellScript \
   --scripts "sudo apt-get update -y && curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash "

################################################################################################################
## Manual Test from VM to AKS via private IP
## VM001 to work as jump host to connect to AKS private cluster
##
#ssh myuser@vm001-ip
## Get docker image from  MCR
# sample yaml from "  https://learn.microsoft.com/en-us/azure/aks/limit-egress-traffic  "
# curl -s -Lo  example.yaml https://raw.githubusercontent.com/fujute/m18h/master/aks/voting-example.yaml
# kubectl apply -f example.yaml
# https://learn.microsoft.com/en-us/troubleshoot/azure/azure-kubernetes/cannot-pull-image-from-acr-to-aks-cluster?source=recommendations
#
# az aks get-credentials --resource-group $RG --name $AKSNAME
#
#az acr check-health --name $MYACR --ignore-errors --yes
#az aks check-acr --resource-group $RG --name $AKSNAME --acr $MYACR.azurecr.io
#https://learn.microsoft.com/en-us/azure/container-registry/container-registry-firewall-access-rules
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#
# get docker image from ARC
# https://learn.microsoft.com/en-us/azure/aks/cluster-container-registry-integration?tabs=azure-cli
az acr import  -n $MYACR --source docker.io/library/nginx:latest --image nginx:v1
# Allow fw to acr over public IP ": Both endpoints are reached over port 443"
#https://learn.microsoft.com/en-us/azure/container-registry/container-registry-firewall-access-rules
# Add FW Application Rules for publics ARC
az network firewall application-rule create -g $RG -f $FWNAME --collection-name 'aksfwar' -n 'acrlogin' \
--source-addresses '*' --protocols 'https=443' --target-fqdns 'myacregistry001.azurecr.io' 

az network firewall application-rule create -g $RG -f $FWNAME --collection-name 'aksfwar' -n 'acrdata' \
--source-addresses '*' --protocols 'https=443' --target-fqdns '*.blob.core.windows.net' 

## *.docker.io
## production.cloudflare.docker.com
#
#curl -s -Lo fuju-nginx.yaml https://raw.githubusercontent.com/fujute/m18h/master/aks/fuju-nginx-ilb.yaml
## chage the image from ningx to  $MYACR.azurecr.io/nginx:v1
# 
#az aks show --name $AKSNAME --resource-group $RG
# Final
# az group delete -g $RG
##############################################################################################################

## See Also:
# https://learn.microsoft.com/en-us/samples/azure/azure-quickstart-templates/private-aks-cluster-with-public-dns-zone/?source=recommendations
