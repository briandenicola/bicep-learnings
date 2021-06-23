param apiManagementName string
param multiRegionDeployment string = 'false'

@description('Location for all resources.')
param location string = resourceGroup().location
param primaryVnetName string
param primaryVnetResourceGroup string
param apimSubnetName string = 'APIM'
param customDomain string
param primaryProxyFQDN string
param customDomainCertificateData string

@secure()
param customDomainCertificatePassword string

var skuCount = 1
var publisherName = 'bjdcsacloud'
var publisherEmail = 'brian@bjdcsa.cloud'
var subnetName = '/subnets/${apimSubnetName}'
var primarySubnetId = concat(resourceId(primaryVnetResourceGroup, 'Microsoft.Network/virtualNetworks', primaryVnetName), subnetName)
var apimSKU = ((multiRegionDeployment == 'true') ? 'Premium' : 'Developer')

resource apiManagementName_resource 'Microsoft.ApiManagement/service@2019-01-01' = {
  name: apiManagementName
  location: location
  sku: {
    name: apimSKU
    capacity: skuCount
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publisherEmail: publisherEmail
    publisherName: publisherName
    hostnameConfigurations: [
      {
        type: 'DeveloperPortal'
        hostName: 'developer.${customDomain}'
        negotiateClientCertificate: false
        encodedCertificate: customDomainCertificateData
        certificatePassword: customDomainCertificatePassword
        defaultSslBinding: false
      }
      {
        type: 'Management'
        hostName: 'management.${customDomain}'
        negotiateClientCertificate: false
        encodedCertificate: customDomainCertificateData
        certificatePassword: customDomainCertificatePassword
        defaultSslBinding: false
      }
      {
        type: 'Proxy'
        hostName: primaryProxyFQDN
        negotiateClientCertificate: false
        encodedCertificate: customDomainCertificateData
        certificatePassword: customDomainCertificatePassword
        defaultSslBinding: true
      }
    ]
    virtualNetworkConfiguration: {
      subnetResourceId: primarySubnetId
    }
    customProperties: {
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Tls10': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Tls11': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Ssl30': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TripleDes168': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Tls10': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Tls11': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Ssl30': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Protocols.Server.Http2': 'True'
    }
    virtualNetworkType: 'Internal'
  }
}