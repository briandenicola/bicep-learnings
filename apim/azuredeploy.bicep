param apiManagementName                 string
param location                          string = resourceGroup().location
param primaryVnetName                   string
param primaryVnetResourceGroup          string
param apimSubnetName                    string = 'APIM'
param customDomain                      string
param primaryProxyFQDN                  string
param publisherName                     string = 'constructorset'
param publisherEmail                    string = 'apim@constructorset.cloud'

@allowed([
  'Developer'
  'Premium'
])
param apimSKU                           string = 'Developer'

@secure()
param customDomainCertificatePassword   string
param customDomainCertificateData       string

var skuCount        = 1
var subnetName      = '/subnets/${apimSubnetName}'
var primarySubnetId = '${resourceId(primaryVnetResourceGroup, 'Microsoft.Network/virtualNetworks', primaryVnetName)}/${subnetName}'

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
