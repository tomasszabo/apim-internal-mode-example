
param keyVaultName string
param applicationIds array

resource accessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2022-07-01' = {
  name: '${keyVaultName}/add'
  properties: {
    accessPolicies: [for applicationId in applicationIds: {
      tenantId: subscription().tenantId
      objectId: applicationId
      permissions: {
        secrets: [
          'get'
        ]
      }
    }]
  }
}
