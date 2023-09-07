
param location string
param prefix string

param subnetApimId string
param publicIpAddressId string
param appInsightsName string
param appInsightsId string
param appInsightsInstrumentationKey string
param functionName string
param functionId string
param functionKey string
param functionUrl string

param apimName string = '${prefix}-apim-${uniqueString(resourceGroup().id)}'
param skuName string = 'Developer'
param capacity int = 1
param publisherEmail string = 'apim@contoso.com'
param publisherName string = 'Contoso'
param testApiName string = 'test-api'

resource apim 'Microsoft.ApiManagement/service@2023-03-01-preview' = {
  name: apimName
  location: location
  sku:{
    capacity: capacity
    name: skuName
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties:{
    virtualNetworkType: 'Internal'
    publisherEmail: publisherEmail
    publisherName: publisherName
    publicIpAddressId: publicIpAddressId
    virtualNetworkConfiguration: {
      subnetResourceId: subnetApimId

    }
  }

  resource namedValueKey 'namedValues' = {
    name: 'key-${functionName}'
    properties: {
      displayName: 'key-${functionName}'
      secret: true
      value: functionKey
    }
  }

  resource backend 'backends' = {
    name: functionName
    properties: {
      title: functionName
      protocol: 'http'
      resourceId: '${environment().resourceManager}${functionId}'
      url: functionUrl
      credentials: {
        header: {
          'x-functions-key': [
            '{{${namedValueKey.name}}}'
          ]
        }
      }
    }
  }

  resource testApi 'apis' = {
    name: testApiName
    properties: {
      displayName: 'Test API'
      path: 'test'
      protocols: [
        'https'
      ]
    }

    resource getUsersSchema 'schemas' = {
      name: 'getUsers'
      properties: {
        contentType: 'application/vnd.oai.openapi.components+json'
        document: {
          components: {
            schemas: {
              getUsers: {
                type: 'array'
                items: {
                  type: 'object'
                  properties: {
                    name: {
                      type: 'string'
                    }
                    email: {
                      type: 'string'
                    }
                  }
                  required: [
                    'name'
                    'email'
                  ]
                }
              }
            }
          }
        }
      }
    }

    resource operations 'operations' = {
      name: 'operations'
      properties: {
        displayName: 'GET users'
        method: 'GET'
        urlTemplate: '/api/GetUsers'
        request: {
          queryParameters: [
            {
              name: 'name'
              required: false
              type: 'string'
            }
          ]
        }
        responses: [
          {
            statusCode: 200
            description: 'OK'
            representations: [
              {
                contentType: 'application/json'
                examples: {
                  default: {
                    value: [
                      {
                        name: 'Alice'
                        email: 'alice@example.com'
                      }
                    ]
                  }
                }
                typeName: getUsersSchema.name
              }
            ]
          }
        ]
      }

      resource policies 'policies' = {
        name: 'policy'
        properties: {
          format: 'rawxml'
          value: '<policies><inbound><base /><set-backend-service backend-id="${backend.name}" /></inbound><backend><base /></backend><outbound><base /></outbound><on-error><base /></on-error></policies>'
        }
      }
    }
  }
}

resource unlimitedProduct 'Microsoft.ApiManagement/service/products@2023-03-01-preview' existing = {
  name: 'Unlimited'
  parent: apim
}

resource symbolicname 'Microsoft.ApiManagement/service/products/apis@2023-03-01-preview' = {
  name: testApiName
  parent: unlimitedProduct
}

resource apimAppInsightsLogger 'Microsoft.ApiManagement/service/loggers@2023-03-01-preview' = {
  parent: apim
  name: appInsightsName
  properties: {
    loggerType: 'applicationInsights'
    resourceId: appInsightsId
    credentials: {
      instrumentationKey: appInsightsInstrumentationKey
    }
  }
}

resource apimNameAppInsights 'Microsoft.ApiManagement/service/diagnostics@2023-03-01-preview' = {
  parent: apim
  name: 'applicationinsights'
  properties: {
    loggerId: apimAppInsightsLogger.id
    alwaysLog: 'allErrors'
    sampling: {
      percentage: 100
      samplingType: 'fixed'
    }
  }
}

output apimName string = apimName
output FQDN string = replace(apim.properties.gatewayUrl, 'https://', '')
