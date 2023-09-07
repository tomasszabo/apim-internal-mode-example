
@description('Azure location where resources should be deployed (e.g., westeurope)')
param location string = 'westeurope'

param prefix string = 'apimint'

module sharedModule './shared.bicep' = {
  name: 'sharedModule'
  params: {
    location: location
    prefix: prefix
  }
}

module keyVaultModule './keyVault.bicep' = {
  name: 'keyVaultModule'
  params: {
    location: location
  }
}

module networkModule './network.bicep' = {
  name: 'networkModule'
  dependsOn: [
    sharedModule
  ]
  params: {
    location: location
    prefix: prefix
  }
}

module storageModule './storage.bicep' = {
  name: 'storageModule'
  dependsOn: [
    keyVaultModule
  ]
  params: {
    location: location
    prefix: prefix
    keyVaultName: keyVaultModule.outputs.keyVaultName
  }
}

var storageAccountId = storageModule.outputs.storageAccountId
var keyVaultId = keyVaultModule.outputs.keyVaultId

module privateEndpointsModule './private-endpoints.bicep' = {
  name: 'privateEndpointsModule'
  dependsOn: [
    keyVaultModule
    networkModule
  ]
  params: {
    location: location
    prefix: prefix
    vnetId: networkModule.outputs.vnetId
    subnetPrivateEndpointsId: networkModule.outputs.subnetPrivateEndpointsId
    endpoints: [
      {
        name: 'storage-blob'
        dnsZoneName: 'privatelink.blob.${environment().suffixes.storage}'
        groupIds: ['blob']
        serviceId: storageAccountId
      }
      {
        name: 'storage-file'
        dnsZoneName: 'privatelink.file.${environment().suffixes.storage}'
        groupIds: ['file']
        serviceId: storageAccountId
      }
      {
        name: 'storage-queue'
        dnsZoneName: 'privatelink.queue.${environment().suffixes.storage}'
        groupIds: ['queue']
        serviceId: storageAccountId
      }
      {
        name: 'storage-table'
        dnsZoneName: 'privatelink.table.${environment().suffixes.storage}'
        groupIds: ['table']
        serviceId: storageAccountId
      }
      {
        name: 'keyVault'
        dnsZoneName: 'privatelink.vaultcore.azure.net'
        groupIds: ['vault']
        serviceId: keyVaultId
      }
    ]
  }
}
  
module computeModule './compute.bicep' = {
  name: 'computeModule'
  dependsOn: [
    sharedModule
  ]
  params: {
    location: location
    prefix: prefix
    keyVaultName: keyVaultModule.outputs.keyVaultName
    appInsightsInstrumentationKey: sharedModule.outputs.appInsightsInstrumentationKey
    subnetAppServicesId: networkModule.outputs.subnetAppServicesId
    storageAccountName: storageModule.outputs.storageAccountName
    storageKeyVaultSecretUri: storageModule.outputs.connectionStringKeyVaultUri  
  }
}

module computePrivateEndpointModule './private-endpoints.bicep' = {
  name: 'computePrivateEndpointModule'
  dependsOn: [
    computeModule
    networkModule
  ]
  params: {
    location: location
    prefix: prefix
    vnetId: networkModule.outputs.vnetId
    subnetPrivateEndpointsId: networkModule.outputs.subnetPrivateEndpointsId
    endpoints: [
      {
        name: 'function-app'
        dnsZoneName: 'privatelink.azurewebsites.net'
        groupIds: ['sites']
        serviceId: computeModule.outputs.applicationId
      }
    ]
  }
}

module apimModule './apim.bicep' = {
  name: 'apimModule'
  dependsOn: [
    sharedModule
    networkModule
    computeModule
  ]
  params: {
    location: location
    prefix: prefix
    subnetApimId: networkModule.outputs.subnetApimId
    publicIpAddressId: networkModule.outputs.apimIpAddressId
    appInsightsName: sharedModule.outputs.appInsightsName
    appInsightsId: sharedModule.outputs.appInsightsId
    appInsightsInstrumentationKey: sharedModule.outputs.appInsightsInstrumentationKey
    functionName: computeModule.outputs.applicationName
    functionId: computeModule.outputs.applicationId
    functionKey: computeModule.outputs.applicationKey
    functionUrl: computeModule.outputs.applicationUrl
  }
}

module dnsZone './dnszone.bicep' = {
  name: 'dnsZoneModule'
  dependsOn: [
    networkModule
    apimModule
  ]
  params: {
    vnetId: networkModule.outputs.vnetId
    apimName: apimModule.outputs.apimName
  }
}

module appGwModule './app-gateway.bicep' = {
  name: 'appGwModule'
  dependsOn: [
    networkModule
    apimModule
  ]
  params: {
    location: location
    prefix: prefix
    subnetAppGatewayId: networkModule.outputs.subnetAppGatewayId
    publicIpAddressId: networkModule.outputs.gatewayIpAddressId
    primaryBackendEndFQDN: apimModule.outputs.FQDN
  }
}

// module keyVaultAccessPolicyModule './keyVaultAccessPolicy.bicep' = if (deployFunction) { 
//   name: 'keyVaultAccessPolicyModule'
//   params: {
//     keyVaultName: keyVaultModule.outputs.keyVaultName
//     applicationId: functionModule.outputs.applicationId
//   }
// }
