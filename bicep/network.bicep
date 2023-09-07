
param location string
param prefix string

param gatewayIpAddressName string = '${prefix}-public-ip-gw-${uniqueString(resourceGroup().id)}'
param apimIpAddressName string = '${prefix}-public-ip-apim-${uniqueString(resourceGroup().id)}'
param vnetName string = '${prefix}-vnet-${uniqueString(resourceGroup().id)}'
param vnetAddressPrefix string = '10.0.0.0/16'
param subnetAppGatewayName string = 'app-gw'
param subnetAppGatewayPrefix string = '10.0.1.0/26'
param subnetApimName string = 'apim'
param subnetApimPrefix string = '10.0.2.0/26'
param subnetPrivateEndpointsName string = 'private-endpoints'
param subnetPrivateEndpointsPrefix string = '10.0.3.0/24'
param subnetAppServicesName string = 'app-services'
param subnetAppServicesPrefix string = '10.0.4.0/24'
param nsgApimName string = '${prefix}-nsg-apim-${uniqueString(resourceGroup().id)}'
param nsgAppGatewayName string = '${prefix}-nsg-app-gw-${uniqueString(resourceGroup().id)}'

resource gatewayIpAddress 'Microsoft.Network/publicIPAddresses@2023-02-01' = {
  name: gatewayIpAddressName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: gatewayIpAddressName    
    }
  }
}

resource apimIpAddress 'Microsoft.Network/publicIPAddresses@2023-02-01' = {
  name: apimIpAddressName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: apimIpAddressName    
    }
  }
}

resource nsgAppGateway 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: nsgAppGatewayName
  location: location
  properties: {
    securityRules: [
      {
        name: 'HealthProbesInbound'
        properties: {
          sourceAddressPrefix: 'GatewayManager'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '65200-65535'
          protocol: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowTLSInbound'
        properties: {
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
          protocol: 'Tcp'
          access: 'Allow'
          priority: 110
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowHTTPInbound'
        properties: {
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '80'
          protocol: 'Tcp'
          access: 'Allow'
          priority: 120
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowAzureLoadBalancerInbound'
        properties: {
          sourceAddressPrefix: 'AzureLoadBalancer'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
          protocol: '*'
          access: 'Allow'
          priority: 130
          direction: 'Inbound'
        }
      }
      {
        name: 'HealthProbesOutbound'
        properties: {
          sourceAddressPrefix: 'GatewayManager'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '65200-65535'
          protocol: '*'
          access: 'Allow'
          priority: 100
          direction: 'Outbound'
        }
      }
    ]
  }
}

resource nsgApim 'Microsoft.Network/networkSecurityGroups@2023-02-01' = {
  name: nsgApimName
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowAPIMInbound'
        properties: {
          sourceAddressPrefix: 'ApiManagement'
          sourcePortRange: '*'
          destinationAddressPrefix: 'VirtualNetwork'
          destinationPortRange: '3443'
          protocol: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowAzureLoadBalancerInbound'
        properties: {
          sourceAddressPrefix: 'AzureLoadBalancer'
          sourcePortRange: '*'
          destinationAddressPrefix: 'VirtualNetwork'
          destinationPortRange: '6390'
          protocol: '*'
          access: 'Allow'
          priority: 110
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowStorageOutbound'
        properties: {
          sourceAddressPrefix: 'VirtualNetwork'
          sourcePortRange: '*'
          destinationAddressPrefix: 'Storage'
          destinationPortRange: '443'
          protocol: '*'
          access: 'Allow'
          priority: 120
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowSqlOutbound'
        properties: {
          sourceAddressPrefix: 'VirtualNetwork'
          sourcePortRange: '*'
          destinationAddressPrefix: 'Sql'
          destinationPortRange: '1433'
          protocol: '*'
          access: 'Allow'
          priority: 130
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowKeyVaultOutbound'
        properties: {
          sourceAddressPrefix: 'VirtualNetwork'
          sourcePortRange: '*'
          destinationAddressPrefix: 'AzureKeyVault'
          destinationPortRange: '443'
          protocol: '*'
          access: 'Allow'
          priority: 140
          direction: 'Outbound'
        }
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2023-02-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: subnetApimName
        properties: {
          addressPrefix: subnetApimPrefix
          networkSecurityGroup: {
            id: nsgApim.id
          }
        }
      }
      {
        name: subnetAppGatewayName
        properties: {
          addressPrefix: subnetAppGatewayPrefix
          networkSecurityGroup: {
            id: nsgAppGateway.id
          }
        }
      }
      {
        name: subnetPrivateEndpointsName
        properties: {
          addressPrefix: subnetPrivateEndpointsPrefix
        }
      }
      {
        name: subnetAppServicesName
        properties: {
          addressPrefix: subnetAppServicesPrefix
          delegations: [
            {
              name: 'Microsoft.Web/serverFarms'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
        }
      }
    ]
  }
}

output vnetId string = vnet.id
output gatewayIpAddressId string = gatewayIpAddress.id
output apimIpAddressId string = apimIpAddress.id
output subnetApimId string = vnet.properties.subnets[0].id
output subnetAppGatewayId string = vnet.properties.subnets[1].id
output subnetPrivateEndpointsId string = vnet.properties.subnets[2].id
output subnetAppServicesId string = vnet.properties.subnets[3].id
