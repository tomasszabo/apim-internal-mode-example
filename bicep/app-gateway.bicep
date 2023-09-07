
param location string
param prefix string
param publicIpAddressId string
param subnetAppGatewayId string
param primaryBackendEndFQDN string

param probeUrl string = '/status-0123456789abcdef'
param appGatewayName string = '${prefix}-app-gw-${uniqueString(resourceGroup().id)}'
param appGatewayIdentityId string = '${prefix}-app-gw-identity-${uniqueString(resourceGroup().id)}'

resource appGatewayIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: appGatewayIdentityId
  location: location
}

resource appGateway 'Microsoft.Network/applicationGateways@2023-02-01' = {
  name: appGatewayName
  location: location
  // dependsOn: [
  //   certificate
  // ]
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${appGatewayIdentity.id}': {}
    }
  }
  properties: {
    sku: {
      name: 'WAF_v2'
      tier: 'WAF_v2'
    }
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: subnetAppGatewayId
          }
        }
      }
    ]
    // sslCertificates: [
    //   {
    //     name: appGatewayFQDN
    //     properties: {
    //       keyVaultSecretId:  certificate.outputs.secretUri
    //     }
    //   }
    // ]
    sslPolicy: {
      minProtocolVersion: 'TLSv1_2'
      policyType: 'Custom'
      cipherSuites: [        
         'TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256'
         'TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384'
         'TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256'
         'TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384'
         'TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256'
         'TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA384'
         'TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256'
         'TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384'
      ]      
    }    
    trustedRootCertificates: []
    frontendIPConfigurations: [
      {
        name: 'appGwPublicFrontendIp'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIpAddressId
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'port_80'
        properties: {
          port: 80
        }
      }
      {
        name: 'port_443'
        properties: {
          port: 443
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'apim'
        properties: {
          backendAddresses: [
            {
              fqdn: primaryBackendEndFQDN
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'default'
        properties: {
          port: 80
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: false
          affinityCookieName: 'ApplicationGatewayAffinity'
          requestTimeout: 20
        }
      }
      {
        name: 'https'
        properties: {
          port: 443
          protocol: 'Https'
          cookieBasedAffinity: 'Disabled'
          hostName: primaryBackendEndFQDN
          pickHostNameFromBackendAddress: false
          requestTimeout: 20
          probe: {
            id: resourceId('Microsoft.Network/applicationGateways/probes', appGatewayName, 'APIM')
          }
        }
      }
    ]
    httpListeners: [
      {
        name: 'default'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', appGatewayName, 'appGwPublicFrontendIp')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', appGatewayName, 'port_80')
          }
          protocol: 'Http'
          hostNames: []
          requireServerNameIndication: false
        }
      }
      // {
      //   name: 'https'
      //   properties: {
      //     frontendIPConfiguration: {
      //       id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', appGatewayName, 'appGwPublicFrontendIp')
      //     }
      //     frontendPort: {
      //       id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', appGatewayName, 'port_443')
      //     }
      //     protocol: 'Https'
      //     sslCertificate: {
      //       id: resourceId('Microsoft.Network/applicationGateways/sslCertificates', appGatewayName, appGatewayFQDN)
      //     }
      //     hostNames: []
      //     requireServerNameIndication: false
      //   }
      // }
    ]
    urlPathMaps: []
    requestRoutingRules: [
      {
        name: 'apim'
        properties: {
          priority: 1
          ruleType: 'basic'
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', appGatewayName, 'default')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', appGatewayName, 'apim')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', appGatewayName, 'https')
          }
        }
      }
    ]
    probes: [
      {
        name: 'APIM'
        properties: {
          protocol: 'Https'
          host: primaryBackendEndFQDN
          path: probeUrl
          interval: 30
          timeout: 30
          unhealthyThreshold: 3
          pickHostNameFromBackendHttpSettings: false
          minServers: 0
          match: {
            statusCodes: [
              '200-399'
            ]
          }
        }
      }
    ]
    rewriteRuleSets: []
    redirectConfigurations: []
    webApplicationFirewallConfiguration: {
      enabled: true
      firewallMode: 'Detection'
      ruleSetType: 'OWASP'
      ruleSetVersion: '3.2'
      disabledRuleGroups: []
      requestBodyCheck: true
      maxRequestBodySizeInKb: 128
      fileUploadLimitInMb: 100
    }
    enableHttp2: true
    autoscaleConfiguration: {
      minCapacity: 2
      maxCapacity: 3
    }
  }
}
