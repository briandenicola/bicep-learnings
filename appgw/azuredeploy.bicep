param appGatewayName string
param location string = resourceGroup().location
param primaryVnetName string
param primaryVnetResourceGroup string
param domainCertificateData string

@secure()
param domainCertificatePassword string
param primaryBackendEndFQDN string

var appGatewayName_var = '${appGatewayName}-${location}'
var appGatewayPrimaryPip_var = '${appGatewayName_var}-pip'
var appGatewayPrimaryNSG_var = '${appGatewayName_var}-nsg'
var subnetName = '/subnets/AppGateway'
var primarySubnetId = '${resourceId(primaryVnetResourceGroup, 'Microsoft.Network/virtualNetworks', primaryVnetName)}${subnetName}'

resource appGatewayPrimaryNSG 'Microsoft.Network/networkSecurityGroups@2020-05-01' = {
  name: appGatewayPrimaryNSG_var
  location: location
  properties: {
    securityRules: [
      {
        name: 'HealthProbes'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '65200-65535'
          sourceAddressPrefix: 'GatewayManager'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'Allow_FrontDoor_TLS'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'AzureFrontDoor.Backend'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 110
          direction: 'Inbound'
        }
      }
      {
        name: 'Allow_FrontDoor_HTTP'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: 'AzureFrontDoor.Backend'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 111
          direction: 'Inbound'
        }
      }
      {
        name: 'Allow_AzureLoadBalancer'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'AzureLoadBalancer'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 120
          direction: 'Inbound'
        }
      }
      {
        name: 'DenyAll'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 130
          direction: 'Inbound'
        }
      }
    ]
  }
}

module apply_nsg_to_subnet_primary './apply_nsg_to_subnet_primary.bicep' = {
  name: 'apply-nsg-to-subnet-primary'
  scope: resourceGroup(primaryVnetResourceGroup)
  params: {
    appGatewayName: appGatewayName
    primaryVnetName: primaryVnetName
    primarySubnetId: primarySubnetId
  }
}

resource appGatewayPrimaryPip 'Microsoft.Network/publicIPAddresses@2019-09-01' = {
  name: appGatewayPrimaryPip_var
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
  }
}

resource appGatewayName_resource 'Microsoft.Network/applicationGateways@2019-09-01' = {
  name: appGatewayName_var
  location: location
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
            id: primarySubnetId
          }
        }
      }
    ]
    sslCertificates: [
      {
        name: 'portal_us'
        properties: {
          data: domainCertificateData
          password: domainCertificatePassword
        }
      }
    ]
    trustedRootCertificates: []
    frontendIPConfigurations: [
      {
        name: 'appGwPublicFrontendIp'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: appGatewayPrimaryPip.id
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
            id: '${resourceId('Microsoft.Network/applicationGateways', appGatewayName_var)}/probes/APIM'
          }
        }
      }
    ]
    httpListeners: [
      {
        name: 'default'
        properties: {
          frontendIPConfiguration: {
            id: '${resourceId('Microsoft.Network/applicationGateways', appGatewayName_var)}/frontendIPConfigurations/appGwPublicFrontendIp'
          }
          frontendPort: {
            id: '${resourceId('Microsoft.Network/applicationGateways', appGatewayName_var)}/frontendPorts/port_80'
          }
          protocol: 'Http'
          hostnames: []
          requireServerNameIndication: false
        }
      }
      {
        name: 'https'
        properties: {
          frontendIPConfiguration: {
            id: '${resourceId('Microsoft.Network/applicationGateways', appGatewayName_var)}/frontendIPConfigurations/appGwPublicFrontendIp'
          }
          frontendPort: {
            id: '${resourceId('Microsoft.Network/applicationGateways', appGatewayName_var)}/frontendPorts/port_443'
          }
          protocol: 'Https'
          sslCertificate: {
            id: '${resourceId('Microsoft.Network/applicationGateways', appGatewayName_var)}/sslCertificates/portal_us'
          }
          hostnames: []
          requireServerNameIndication: false
        }
      }
    ]
    urlPathMaps: []
    requestRoutingRules: [
      {
        name: 'apim'
        properties: {
          ruleType: 'Basic'
          httpListener: {
            id: '${resourceId('Microsoft.Network/applicationGateways', appGatewayName_var)}/httpListeners/https'
          }
          backendAddressPool: {
            id: '${resourceId('Microsoft.Network/applicationGateways', appGatewayName_var)}/backendAddressPools/apim'
          }
          backendHttpSettings: {
            id: '${resourceId('Microsoft.Network/applicationGateways', appGatewayName_var)}/backendHttpSettingsCollection/https'
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
          path: '/status-0123456789abcdef'
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
      ruleSetVersion: '3.0'
      disabledRuleGroups: []
      requestBodyCheck: true
      maxRequestBodySizeInKb: 128
      fileUploadLimitInMb: 100
    }
    enableHttp2: true
    autoscaleConfiguration: {
      minCapacity: 1
      maxCapacity: 2
    }
  }
  dependsOn: [
    apply_nsg_to_subnet_primary
  ]
}

output Primary_IP_Address string = appGatewayPrimaryPip.properties.ipAddress
