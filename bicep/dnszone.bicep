
param vnetId string
param apimName string

resource apim 'Microsoft.ApiManagement/service@2023-03-01-preview' existing = {
  name: apimName
}

/*
Createa a Private DNS Zone, A Record and Vnet Link for each of the below endpoints

API Gateway	                contosointernalvnet.azure-api.net
Developer portal	          contosointernalvnet.portal.azure-api.net
The new developer portal	  contosointernalvnet.developer.azure-api.net
Direct management endpoint	contosointernalvnet.management.azure-api.net
Git	                        contosointernalvnet.scm.azure-api.net
*/

resource gatewayDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'azure-api.net'
  location: 'global'
  properties: {}
}

resource portalDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'portal.azure-api.net'
  location: 'global'
  properties: {}
}

resource developerDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'developer.azure-api.net'
  location: 'global'
  properties: {}
}

resource managementDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'management.azure-api.net'
  location: 'global'
  properties: {}
}

resource scmDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'scm.azure-api.net'
  location: 'global'
  properties: {}
}

// A Records

resource gatewayRecord 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  parent: gatewayDnsZone
  name: apimName
  dependsOn: [
    apim
  ]
  properties: {
    aRecords: [
      {
        ipv4Address: apim.properties.privateIPAddresses[0]
      }
    ]
    ttl: 36000
  }
}

resource portalRecord 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  parent: portalDnsZone
  name: apimName
  dependsOn: [
    apim
  ]
  properties: {
    aRecords: [
      {
        ipv4Address: apim.properties.privateIPAddresses[0]
      }
    ]
    ttl: 36000
  }
}

resource developerRecord 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  parent: developerDnsZone
  name: apimName
  dependsOn: [
    apim
  ]
  properties: {
    aRecords: [
      {
        ipv4Address: apim.properties.privateIPAddresses[0]
      }
    ]
    ttl: 36000
  }
}

resource managementRecord 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  parent: managementDnsZone 
  name: apimName
  dependsOn: [
    apim
  ]
  properties: {
    aRecords: [
      {
        ipv4Address: apim.properties.privateIPAddresses[0]
      }
    ]
    ttl: 36000
  }
}

resource scmRecord 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  parent: scmDnsZone
  name: apimName
  dependsOn: [
    apim
  ]
  properties: {
    aRecords: [
      {
        ipv4Address: apim.properties.privateIPAddresses[0]
      }
    ]
    ttl: 36000
  }
}

// Vnet Links

resource gatewayVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: gatewayDnsZone
  name: 'gateway-vnet-dns-link'
  location: 'global'
  properties: {
    registrationEnabled: true
    virtualNetwork: {
      id: vnetId
    }
  }
}

resource portalVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: portalDnsZone 
  name: 'gateway-vnet-dns-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

resource developerVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: developerDnsZone
  name: 'gateway-vnet-dns-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

resource managementVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: managementDnsZone
  name: 'gateway-vnet-dns-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

resource scmVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: scmDnsZone
  name: 'gateway-vnet-dns-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}
