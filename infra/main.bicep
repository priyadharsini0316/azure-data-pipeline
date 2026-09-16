targetScope = 'subscription'

@minLength(3)
@maxLength(20)
param environmentName string

param location string = 'canadacentral'

param principalId string
param principalName string

@allowed([
  'User'
  'Group'
])
param principalType string = 'User'

@description('Single public IPv4 address for Priya workstation access.')
param clientIpAddress string

var normalizedEnv = toLower(replace(environmentName, '-', ''))
var suffix = substring(uniqueString(subscription().id, environmentName), 0, 6)
var resourceGroupName = 'rg-kpmg-${environmentName}'
var tags = {
  workload: 'kpmg-data-pipeline'
  environment: 'prototype'
  owner: 'Priya'
  purpose: 'interview-case-study'
  'cost-control': 'short-lived-free-account'
}

resource resourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

module resources 'resources.bicep' = {
  name: 'kpmg-prototype-resources'
  scope: resourceGroup
  params: {
    location: location
    normalizedEnv: normalizedEnv
    uniqueSuffix: suffix
    principalId: principalId
    principalName: principalName
    principalType: principalType
    clientIpAddress: clientIpAddress
    tags: tags
  }
}

output AZURE_RESOURCE_GROUP string = resourceGroup.name
output AZURE_LOCATION string = location
output SQL_SERVER_NAME string = resources.outputs.sqlServerName
output SQL_SERVER_FQDN string = resources.outputs.sqlServerFqdn
output SQL_DATABASE_NAME string = resources.outputs.sqlDatabaseName
output ADF_NAME string = resources.outputs.dataFactoryName
output ADF_PRINCIPAL_ID string = resources.outputs.dataFactoryPrincipalId
output KEY_VAULT_NAME string = resources.outputs.keyVaultName
output LOGIC_APP_NAME string = resources.outputs.logicAppName
