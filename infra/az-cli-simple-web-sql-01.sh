# ref: https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-template-deploy-cli
# appName,environment,locationShort,databaseName,administratorLogin,administratorLoginPassword
# $app_name,dev,dev,appdb6<databasename>,dbuser,<<password>>

resource_group_name="1D614wRG2"
deployment_name="D614WDeployment"
app_name="d61webapp"
sample.web.sql-18032019-e.ps1

az login
az group create --name "$resource_group_name"  --location southeastasia


az group deployment validate --parameters '{ \
   "appName": {"value":"$app_name"}, \ 
   "environment": {"value":"dev"}, \
   "locationShort": {"value":"sea"}, \
   "databaseName": {"value":"appdb6<databasename>"}, \
   "administratorLogin": {"value":"dbuser"}, \
   "administratorLoginPassword": {"value":"<<password>>}" \
                            }' --resource-group "$resource_group_name" --template-file https://raw.githubusercontent.com/mspnp/reference-architectures/master/managed-web-app/basic-web-app/Paas-Basic/Templates/PaaS-Basic.json
