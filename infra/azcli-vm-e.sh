#!/bin/bash
# az vm get-instance-view --name $VMName --resource-group $RG --query instanceView.statuses[1] --output table
RG='MyRG'
VMName='MyVM'
az vm start --name $VMName --resource-group $RG

#az vm stop --name $VMName --resource-group $RG
#az vm deallocate --name $VMName --resource-group $RG


# creating vm with 100gb OS disk
#az vm list-sizes --location southeastasia --output table  | grep D2s_v3
#az vm create -n apr17m -g 1RG --image UbuntuLTS --location "southeastasia" --generate-ssh-keys --os-disk-size-gb 100 --size Standard_D2s_v3 --admin-username helloadmin 
