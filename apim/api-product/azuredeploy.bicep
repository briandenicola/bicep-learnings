param apiManagementName   string
param primaryBackendUrl   string
param globalKeyPolicy     string
param createKeyPolicy     string
param rateLimitPolicy     string
param mockPolicy          string
param apiSet              string = newGuid()

resource apiManagementName_key_service 'Microsoft.ApiManagement/service/products@2019-01-01' = {
  name: '${apiManagementName}/key-service'
  properties: {
    displayName: 'Key Service'
    description: 'Simple Service to generate AES Keys'
    subscriptionRequired: true
    approvalRequired: false
    state: 'published'
  }
}

resource apiManagementName_key_service_1rps 'Microsoft.ApiManagement/service/products@2019-12-01' = {
  name: '${apiManagementName}/key-service-1rps'
  properties: {
    displayName: 'Key Service (1rps)'
    description: 'Key Service with only 1 request per second '
    subscriptionRequired: true
    approvalRequired: false
    state: 'published'
  }
}

resource apiManagementName_apiSet 'Microsoft.ApiManagement/service/apiVersionSets@2019-12-01' = {
  name: '${apiManagementName}/${apiSet}'
  properties: {
    displayName: 'Key Service'
    versioningScheme: 'Query'
    versionQueryName: 'api-version'
  }
}

resource apiManagementName_key_api 'Microsoft.ApiManagement/service/apis@2019-12-01' = {
  name: '${apiManagementName}/key-api'
  properties: {
    displayName: 'Key Service'
    apiRevision: '1'
    subscriptionRequired: true
    serviceUrl: '${primaryBackendUrl}/api/keys'
    path: 'k'
    protocols: [
      'https'
    ]
    isCurrent: true
    apiVersionSetId: apiManagementName_apiSet.id
  }
}

resource apiManagementName_key_api_v2 'Microsoft.ApiManagement/service/apis@2019-12-01' = {
  name: '${apiManagementName}/key-api-v2'
  properties: {
    displayName: 'Key Service'
    apiRevision: '1'
    subscriptionRequired: true
    serviceUrl: '${primaryBackendUrl}/api/keys'
    path: 'k'
    protocols: [
      'https'
    ]
    isCurrent: true
    apiVersion: '2020-05-04'
    apiVersionSetId: apiManagementName_apiSet.id
  }
}

resource apiManagementName_key_api_create_keys 'Microsoft.ApiManagement/service/apis/operations@2019-12-01' = {
  parent: apiManagementName_key_api
  name: 'create-keys'
  properties: {
    displayName: 'Create Keys'
    method: 'POST'
    urlTemplate: '/{NumberOfKeys}'
    templateParameters: [
      {
        name: 'NumberOfKeys'
        required: true
        values: []
        type: null
      }
    ]
    responses: [
      {
        statusCode: 200
        representations: [
          {
            contentType: 'application/json'
            sample: '{\r\n    "text": "Please supply api-version in query string"\r\n}'
          }
        ]
        headers: []
      }
    ]
  }
}

resource apiManagementName_key_api_v2_create_keys 'Microsoft.ApiManagement/service/apis/operations@2019-01-01' = {
  parent: apiManagementName_key_api_v2
  name: 'create-keys'
  properties: {
    displayName: 'Create Keys'
    method: 'POST'
    urlTemplate: '/{NumberOfKeys}'
    templateParameters: [
      {
        name: 'NumberOfKeys'
        required: true
        values: []
        type: null
      }
    ]
    responses: []
  }
}

resource apiManagementName_key_api_v2_get_key 'Microsoft.ApiManagement/service/apis/operations@2019-01-01' = {
  parent: apiManagementName_key_api_v2
  name: 'get-key'
  properties: {
    displayName: 'Get Key'
    method: 'GET'
    urlTemplate: '/{key}'
    templateParameters: [
      {
        name: 'key'
        required: true
        values: []
        type: null
      }
    ]
    description: 'Get specific key'
    responses: []
  }
}

resource apiManagementName_key_service_1rps_policy 'Microsoft.ApiManagement/service/products/policies@2019-12-01' = {
  parent: apiManagementName_key_service_1rps
  name: 'policy'
  properties: {
    value: rateLimitPolicy
    format: 'xml'
  }
}

resource apiManagementName_key_api_policy 'Microsoft.ApiManagement/service/apis/policies@2019-12-01' = {
  parent: apiManagementName_key_api
  name: 'policy'
  properties: {
    value: mockPolicy
    format: 'xml'
  }
}

resource apiManagementName_key_api_v2_policy 'Microsoft.ApiManagement/service/apis/policies@2019-01-01' = {
  parent: apiManagementName_key_api_v2
  name: 'policy'
  properties: {
    value: globalKeyPolicy
    format: 'rawxml'
  }
}

resource apiManagementName_key_api_v2_create_keys_policy 'Microsoft.ApiManagement/service/apis/operations/policies@2019-01-01' = {
  parent: apiManagementName_key_api_v2_create_keys
  name: 'policy'
  properties: {
    value: createKeyPolicy
    format: 'rawxml'
  }
  dependsOn: [
    apiManagementName_key_api_v2
  ]
}

resource apiManagementName_primaryBackendUrl 'Microsoft.ApiManagement/service/namedValues@2019-12-01' = {
  name: '${apiManagementName}/primaryBackendUrl'
  properties: {
    displayName: 'primaryBackendUrl'
    value: primaryBackendUrl
    secret: false
  }
}
