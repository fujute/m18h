terraform plan -out main-vnet.tfplan
terraform plan -destroy -out main-vnet.destroy.tfplan
terraform apply main-vnet.destroy.tfplan

// https://docs.microsoft.com/en-us/azure/virtual-machines/linux/quick-create-cli
