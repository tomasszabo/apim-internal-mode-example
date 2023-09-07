
param location string
param prefix string
param keyVaultName string
param appInsightsInstrumentationKey string
param subnetAppServicesId string
param storageAccountName string
param storageKeyVaultSecretUri string

param hostingPlanName string = '${prefix}-func-asp-${uniqueString(resourceGroup().id)}'
param functionAppName string = '${prefix}-func-app-${uniqueString(resourceGroup().id)}'
param functionName string = 'GetUsers'

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: storageAccountName
}

resource fileShares 'Microsoft.Storage/storageAccounts/fileServices@2022-09-01' existing = {
  name: 'default'
  parent: storageAccount
}

// create file share for logic app (created automatically when deploying manually in Azure Portal, in IaC need to create it manually)
resource fileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2022-09-01' = {
  name: functionAppName
  parent: fileShares
  properties: {
    accessTier: 'TransactionOptimized'
    enabledProtocols: 'SMB'
  }
}

resource hostingPlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: hostingPlanName
  location: location
  sku: {
    name: 'EP1'
    tier: 'Premium'
  }
  properties: {}
}

resource functionApp 'Microsoft.Web/sites@2022-09-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: hostingPlan.id
    siteConfig: {
      // appSettings: [
      //   {
      //     name: 'AzureWebJobsStorage'
      //     value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
      //   }
      //   {
      //     name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
      //     value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
      //   }
      //   {
      //     name: 'WEBSITE_CONTENTSHARE'
      //     value: toLower(functionAppName)
      //   }
      //   {
      //     name: 'WEBSITE_CONTENTOVERVNET'
      //     value: '1'
      //   }
      //   {
      //     name: 'FUNCTIONS_EXTENSION_VERSION'
      //     value: '~4'
      //   }
      //   {
      //     name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
      //     value: appInsightsInstrumentationKey
      //   }
      //   {
      //     name: 'FUNCTIONS_WORKER_RUNTIME'
      //     value: 'dotnet'
      //   }
      // ]
      cors: {
        allowedOrigins: [
          '*'
        ]
      }
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      use32BitWorkerProcess: false
      netFrameworkVersion: '6.0'
      vnetRouteAllEnabled: true
    }
    virtualNetworkSubnetId: subnetAppServicesId    
    publicNetworkAccess: 'Disabled'
    httpsOnly: true
  }
}

// need to grant access to KeyVault for Logic App first before we can set the app settings
module keyVaultAccessPolicyModule './keyVaultAccessPolicy.bicep' = { 
  name: 'keyVaultAccessPolicyModule'
  params: {
    keyVaultName: keyVaultName
    applicationIds: [functionApp.identity.principalId]
  }
}

resource logicAppSettings 'Microsoft.Web/sites/config@2022-09-01' = {
  name: 'appsettings'
  parent: functionApp
  dependsOn: [
    keyVaultAccessPolicyModule
  ]
  properties: {
    AzureWebJobsStorage: '@Microsoft.KeyVault(SecretUri=${storageKeyVaultSecretUri})'
    WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: '@Microsoft.KeyVault(SecretUri=${storageKeyVaultSecretUri})'
    WEBSITE_CONTENTSHARE: toLower(functionAppName)
    WEBSITE_CONTENTOVERVNET: '1'
    FUNCTIONS_EXTENSION_VERSION: '~4'
    APPLICATIONINSIGHTS_CONNECTION_STRING: appInsightsInstrumentationKey
    FUNCTIONS_WORKER_RUNTIME: 'dotnet'
  }
}

resource function 'Microsoft.Web/sites/functions@2022-09-01' = {
  name: functionName
  parent: functionApp
  properties: {
    config: {
      disabled: false
      bindings: [
        {
          name: 'req'
          type: 'httpTrigger'
          direction: 'in'
          authLevel: 'function'
          methods: [
            'get'
          ]
        }
        {
          name: '$return'
          type: 'http'
          direction: 'out'
        }
      ]
    }
    files: {
      'function.json': loadTextContent('../GetUsers/function.json')
      'run.csx': loadTextContent('../GetUsers/run.csx')
    }
  }
}

output applicationName string = functionApp.name
output applicationId string = functionApp.id
output applicationPrincipalId string = functionApp.identity.principalId
output applicationKey string = listkeys('${functionApp.id}/host/default', '2022-09-01').masterKey
output applicationUrl string = 'https://${functionApp.properties.defaultHostName}'
