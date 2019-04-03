#!/bin/bash
_location=southeastasia
_rg=1myResourceGroup
_mystrgeaccount="mystrgaccount$((RANDOM%100))"
# ref : https://docs.microsoft.com/en-us/azure/batch/quick-create-cli
az group create --name $_rg  --location $_location
az storage account create \
    --resource-group $_rg \
    --name $_mystrgeaccount\
    --location $_location \
    --sku Standard_LRS

az batch account create \
    --name mybatchaccount \
    --storage-account $_mystrgeaccount \
    --resource-group $_rg \
    --location $_location
	
az batch account login \
    --name mybatchaccount \
    --resource-group $_rg  \
    --shared-key-auth	
	
az batch pool create \
    --id mypool --vm-size Standard_A1_v2 \
    --target-dedicated-nodes 2 \
    --image canonical:ubuntuserver:16.04-LTS \
    --node-agent-sku-id "batch.node.ubuntu 16.04"	
	
az batch pool show --pool-id mypool \
    --query "allocationState"

az batch job create \
    --id myjob \
    --pool-id mypool	
	
for i in {1..4}
do
   az batch task create \
    --task-id mytask$i \
    --job-id myjob \
    --command-line "/bin/bash -c 'printenv | grep AZ_BATCH; sleep 90s'"
done

for i in {5..6}
do
   az batch task create \
    --task-id mytask$i \
    --job-id myjob \
    --command-line "/bin/bash -c 'printenv | grep AZ_BATCH;uname -a; sleep 90s'"
done

az batch task show \
    --job-id myjob \
    --task-id mytask1

for i in {1..4}
do
az batch task file list \
    --job-id myjob \
    --task-id mytask$i \
    --output table
done

#az batch pool delete --pool-id mypool
#az group delete --name $_rg 	
