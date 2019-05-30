#!/bin/bash

# ref: https://docs.microsoft.com/en-us/azure/sql-database/scripts/sql-database-create-and-configure-database-cli
# Set an admin login and password for your database
export adminlogin="**ServerAdmin**"
export password="**ChangeYourAdminPassword1**"
# The logical server name has to be unique in the system
export servername=server-$RANDOM
# The ip address range that you want to allow to access your DB
export startip=0.0.0.0
export endip=0.0.0.0

# Create a resource group
az group create \
    --name myResourceGroup \
    --location westeurope

# Create a logical server in the resource group
az sql server create \
    --name $servername \
    --resource-group 1myResourceGroup \
    --location westeurope  \
    --admin-user $adminlogin \
    --admin-password $password

# Configure a firewall rule for the server
az sql server firewall-rule create \
    --resource-group 1myResourceGroup \
    --server $servername \
    -n AllowYourIp \
    --start-ip-address $startip \
    --end-ip-address $endip

# Create a database in the server with zone redundancy as true
az sql db create \
    --resource-group 1myResourceGroup \
    --server $servername \
    --name mySampleDatabase \
    --sample-name AdventureWorksLT \
    --service-objective S0 \
    --zone-redundant

# Update database and set zone redundancy as false
az sql db update \
    --resource-group myResourceGroup \
    --server $servername \
    --name mySampleDatabase \
    --zone-redundant false
