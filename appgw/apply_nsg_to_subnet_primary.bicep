param appGatewayName string
param location string = resourceGroup().location
param primaryVnetName string
param primarySubnetId string

var appGatewayNameFQDN = '${appGatewayName}-${location}'
var appGatewayPrimaryNSG = '${appGatewayNameFQDN}-nsg'
var subnetName = '/subnets/AppGateway'
var subnet = reference('${primarySubnetId}')

resource AppGatewaySubnet 'Microsoft.Network/virtualNetworks/subnets@2020-06-01' = {
  name: '${primaryVnetName}${subnetName}'
  properties: {
    addressPrefix: subnet.addressPrefix
    networkSecurityGroup: {
      id: resourceId('Microsoft.Network/networkSecurityGroups', appGatewayPrimaryNSG)
    }
  }
}
