// beased on https://github.com/Azure/bicep/tree/main/docs/examples/101/webapp-privateendpoint-vnet-injection
// fixed NSG & Added SQLDatabase 
@description('Name of the VNet')
param virtualNetworkName string = 'vnet1'

@description('Name of the Web Farm')
param serverFarmName string = 'serverfarm'

@description('Web App 1 name must be unique DNS name worldwide')
param webAppBackend_Name string = 'webappbackend-${uniqueString(resourceGroup().id)}'

@description('Web App 2 name must be unique DNS name worldwide')
param webAppFrontend_Name string = 'webappfrontend-${uniqueString(resourceGroup().id)}'

@description('CIDR of your VNet')
param virtualNetwork_CIDR string = '10.200.0.0/16'

@description('Name of the subnet')
param subnet1Name string = 'Subnet1'

@description('Name of the subnet')
param subnet2Name string = 'Subnet2'

@description('CIDR of your subnet')
param subnet1_CIDR string = '10.200.1.0/24'

@description('CIDR of your subnet')
param subnet2_CIDR string = '10.200.2.0/24'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('SKU name, must be minimum P1v2')
@allowed([
  'P1v2'
  'P2v2'
  'P3v2'
])
param skuName string = 'P1v2'

@description('SKU size, must be minimum P1v2')
@allowed([
  'P1v2'
  'P2v2'
  'P3v2'
])
param skuSize string = 'P1v2'

@description('SKU family, must be minimum P1v2')
@allowed([
  'P1v2'
  'P2v2'
  'P3v2'
])
param skuFamily string = 'P1v2'

@description('Name of your Private Endpoint')
param privateEndpointName string = 'PrivateEndpoint1Web'

@description('Link name between your Private Endpoint and your Web App')
param privateLinkConnectionName string = 'PrivateEndpointLink1Web'

@description('Name of your Private Endpoint')
param privateEndpointDBName string = 'PrivateEndpoint2DB'

@description('Link name between your Private Endpoint and your Web App')
param privateLinkConnectionDBName string = 'PrivateEndpointLink2DB'


@description('sqladmin login')
param sqlAdministratorLogin string = 'sqladmin'

@description('sqladmin password')
@secure()
param sqlAdministratorLoginPassword string

var webapp_dns_name = '.azurewebsites.net'
var privateDNSZoneName = 'privatelink.azurewebsites.net'
var SKU_tier = 'PremiumV2'

var nsgName = 'nsg-001'

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        virtualNetwork_CIDR
      ]
    }
  }
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2021-05-01' = {
  name: nsgName
  location: location
  tags: {
    Owner: '@fujuTE'
  }
  properties: {}   
}

resource subnet1 'Microsoft.Network/virtualNetworks/subnets@2020-06-01' = {
  parent: virtualNetwork
  name: subnet1Name
  properties: {
    addressPrefix: subnet1_CIDR
    privateEndpointNetworkPolicies: 'Disabled'
    networkSecurityGroup: {
      id: nsg.id 
      properties: {
      }
    } 
  }
}

resource subnet2 'Microsoft.Network/virtualNetworks/subnets@2020-06-01' = {
  parent: virtualNetwork
  name: subnet2Name
  dependsOn: [
    subnet1
  ]
  properties: {
    addressPrefix: subnet2_CIDR
    delegations: [
      {
        name: 'delegation'
        properties: {
          serviceName: 'Microsoft.Web/serverfarms'
        }
      }
    ]
    privateEndpointNetworkPolicies: 'Enabled'
    networkSecurityGroup: {
      id: nsg.id 
      properties: {
      }
    }
  }
}

resource serverFarm 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: serverFarmName
  location: location
  sku: {
    name: skuName
    tier: SKU_tier
    size: skuSize
    family: skuFamily
    capacity: 1
  }
  kind: 'app'
}

resource webAppBackend 'Microsoft.Web/sites@2020-06-01' = {
  name: webAppBackend_Name
  location: location
  kind: 'app'
  properties: {
    serverFarmId: serverFarm.id
  }
}

resource webAppFrontend 'Microsoft.Web/sites@2020-06-01' = {
  name: webAppFrontend_Name
  location: location
  kind: 'app'
  properties: {
    serverFarmId: serverFarm.id
  }
}

resource webApp2AppSettings 'Microsoft.Web/sites/config@2020-06-01' = {
  parent: webAppFrontend
  name: 'appsettings'
  properties: {
    WEBSITE_DNS_SERVER: '168.63.129.16'
    WEBSITE_VNET_ROUTE_ALL: '1'
  }
}

resource webApp1Config 'Microsoft.Web/sites/config@2020-06-01' = {
  parent: webAppBackend
  name: 'web'
  properties: {
    ftpsState: 'AllAllowed'
  }
}

resource webApp2Config 'Microsoft.Web/sites/config@2020-06-01' = {
  parent: webAppFrontend
  name: 'web'
  properties: {
    ftpsState: 'AllAllowed'
  }
}

resource webApp1Binding 'Microsoft.Web/sites/hostNameBindings@2019-08-01' = {
  parent: webAppBackend
  name: '${webAppBackend.name}${webapp_dns_name}'
  properties: {
    siteName: webAppBackend.name
    hostNameType: 'Verified'
  }
}

resource webApp2Binding 'Microsoft.Web/sites/hostNameBindings@2019-08-01' = {
  parent: webAppFrontend
  name: '${webAppFrontend.name}${webapp_dns_name}'
  properties: {
    siteName: webAppFrontend.name
    hostNameType: 'Verified'
  }
}

resource webApp2NetworkConfig 'Microsoft.Web/sites/networkConfig@2020-06-01' = {
  parent: webAppFrontend
  name: 'virtualNetwork'
  properties: {
    subnetResourceId: subnet2.id
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2020-06-01' = {
  name: privateEndpointName
  location: location
  properties: {
    subnet: {
      id: subnet1.id
    }
    privateLinkServiceConnections: [
      {
        name: privateLinkConnectionName
        properties: {
          privateLinkServiceId: webAppBackend.id
          groupIds: [
            'sites'
          ]
        }
      }
    ]
  }
}

resource privateDnsZones 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: privateDNSZoneName
  location: 'global'
  dependsOn: [
    virtualNetwork
  ]
}

resource privateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  parent: privateDnsZones
  name: '${privateDnsZones.name}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: virtualNetwork.id
    }
  }
}

resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-03-01' = {
  parent: privateEndpoint
  name: 'dnsgroupname'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: privateDnsZones.id
        }
      }
    ]
  }
}


var sqlserverName = 'sqlserver${uniqueString(resourceGroup().id)}'
var databaseName = 'ligordb001'


resource sqlserver 'Microsoft.Sql/servers@2019-06-01-preview' = {
  name: sqlserverName
  location: location
  properties: {
    administratorLogin: sqlAdministratorLogin
    administratorLoginPassword: sqlAdministratorLoginPassword
    version: '12.0'
  }
}

resource sqlserverName_databaseName 'Microsoft.Sql/servers/databases@2020-08-01-preview' = {
  name: '${sqlserver.name}/${databaseName}'
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 1073741824
  }
}

resource sqlserverName_AllowAllWindowsAzureIps 'Microsoft.Sql/servers/firewallRules@2014-04-01' = {
  name: '${sqlserver.name}/AllowAllWindowsAzureIps'
  properties: {
    endIpAddress: '0.0.0.0'
    startIpAddress: '0.0.0.0'
  }
}


resource privateEndpointSQL 'Microsoft.Network/privateEndpoints@2020-06-01' = {
  name: privateEndpointDBName
  location: location
  properties: {
    subnet: {
      id: subnet1.id
    }
    privateLinkServiceConnections: [
      {
        name: privateLinkConnectionDBName
        properties: {
          privateLinkServiceId: sqlserver.id
          groupIds: [
            'sqlServer'
          ]
        }
      }
    ]
  }
}
