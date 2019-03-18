$resource_group_name="1D614wRG2"
$deployment_name="D614WDeployment"
$app_name="d61webapp"

(Get-Module -ListAvailable | Where-Object{ $_.Name -eq 'Azure' }) | Select Name , Version , Author, PowerShellVersion | Format-List;

Login-AzureRmAccount

New-AzureRmResourceGroup -Name  $resource_group_name -Location "Southeast Asia"

$parameters = @{"appName"="$app_name";"environment"="dev";"locationShort"="sea";"databaseName"="appdb6<databasename>";"administratorLogin"="dbuser";"administratorLoginPassword"="<<password>>"}

Write-Output "$deployment_name"

$str = $parameters | Out-String 
Write-Host $str

New-AzureRmResourceGroupDeployment -Name $deployment_name -ResourceGroupName $resource_group_name -TemplateFile https://raw.githubusercontent.com/mspnp/reference-architectures/master/managed-web-app/basic-web-app/Paas-Basic/Templates/PaaS-Basic.json -TemplateParameterObject  $parameters

# Get-AzureRmResourceGroup -Name $resource_group_name | Remove-AzureRmResourceGroup -Verbose
