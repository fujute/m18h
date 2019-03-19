#!/bin/bash
# az vm get-instance-view --name $VMName --resource-group $RG --query instanceView.statuses[1] --output table
RG='MyRG'
VMName='MyVM'
az vm start --name $VMName --resource-group $RG

#az vm stop --name $VMName --resource-group $RG
#az vm deallocate --name $VMName --resource-group $RG

