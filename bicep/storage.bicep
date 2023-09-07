param location string
param prefix string
param keyVaultName string

param storageAccountName string = '${prefix}blob${uniqueString(resourceGroup().id)}'

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    publicNetworkAccess: 'Disabled'
    allowBlobPublicAccess: false
    networkAcls: {
      bypass: 'None'
      defaultAction: 'Deny'
    }
  }
}

module connectionStringSecret 'keyVaultSecret.bicep' = {
  name: 'storageKeyVaultSecretPrimaryConnectionString'
  params: {
    keyVaultName: keyVaultName
    secretName: '${storageAccountName}-PrimaryConnectionString'
    secretValue: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
  }
}

output connectionStringKeyVaultUri string = connectionStringSecret.outputs.keyVaultSecretUri
output storageAccountName string = storageAccount.name
output storageAccountId string = storageAccount.id
