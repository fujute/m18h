# ref: https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-template-deploy-cli
# template file : https://raw.githubusercontent.com/mspnp/reference-architectures/master/managed-web-app/basic-web-app/Paas-Basic/Templates/PaaS-Basic.json
# appName,environment,locationShort,databaseName,administratorLogin,administratorLoginPassword
# $app_name,dev,dev,appdb6<databasename>,dbuser,<<password>>

resource_group_name="1D614wRG2"
deployment_name="D614WDeployment"
app_name="d61webapp"
adminiLogin=<<your admin name >>
adminiLoginPassword=<<your password >>
databaseName=<<Database Name>>

az group create --name "$resource_group_name"  --location southeastasia && 
az deployment group validate --resource-group "$resource_group_name" --parameters appName="$app_name" environment="dev" locationShort="sea" databaseName="appdb6_$databaseName" \
administratorLogin="$adminiLogin" administratorLoginPassword="$adminiLoginPassword" \
--template-file ./PaaS-Basic.json


az group create --name "$resource_group_name"  --location southeastasia && 
az deployment group create --resource-group "$resource_group_name" --parameters appName="$app_name" environment="dev" locationShort="sea" databaseName="appdb6_$databaseName" \
administratorLogin="$adminiLogin" administratorLoginPassword="$adminiLoginPassword" \
--template-file ./PaaS-Basic.json


#az group deployment delete --name   --resource-group
