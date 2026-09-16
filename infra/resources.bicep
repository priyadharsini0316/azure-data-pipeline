param location string
param normalizedEnv string
param uniqueSuffix string
param principalId string
param principalName string
param principalType string
param tags object

@description('Single public IPv4 address for Priya workstation access.')
param clientIpAddress string

var sqlServerName = 'sql-kpmg-${normalizedEnv}-${uniqueSuffix}'
var sqlDatabaseName = 'sqldb-kpmg-pipeline'
var dataFactoryName = 'adf-kpmg-${normalizedEnv}-${uniqueSuffix}'
var keyVaultName = 'kv-kpmg-${uniqueSuffix}'
var logicAppName = 'logic-kpmg-notify-${normalizedEnv}-${uniqueSuffix}'
var keyVaultAdministratorRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '00482a5a-887f-4fb3-b363-3b7fe8e74483')
var keyVaultSecretsUserRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')

resource sqlServer 'Microsoft.Sql/servers@2023-08-01-preview' = {
  name: sqlServerName
  location: location
  tags: tags
  properties: {
    administrators: {
      administratorType: 'ActiveDirectory'
      principalType: principalType
      login: principalName
      sid: principalId
      tenantId: subscription().tenantId
      azureADOnlyAuthentication: true
    }
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
    restrictOutboundNetworkAccess: 'Disabled'
  }
}

resource allowAzureServices 'Microsoft.Sql/servers/firewallRules@2023-08-01-preview' = {
  parent: sqlServer
  name: 'AllowAzureServicesForAdfPrototype'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

resource allowPriyaClient 'Microsoft.Sql/servers/firewallRules@2023-08-01-preview' = {
  parent: sqlServer
  name: 'AllowPriyaCurrentIp'
  properties: {
    startIpAddress: clientIpAddress
    endIpAddress: clientIpAddress
  }
}

resource sqlDatabase 'Microsoft.Sql/servers/databases@2023-08-01-preview' = {
  parent: sqlServer
  name: sqlDatabaseName
  location: location
  tags: tags
  sku: {
    name: 'GP_S_Gen5'
    tier: 'GeneralPurpose'
    family: 'Gen5'
    capacity: 1
  }
  properties: {
    autoPauseDelay: 60
    minCapacity: json('0.5')
    maxSizeBytes: 34359738368
    zoneRedundant: false
    readScale: 'Disabled'
    requestedBackupStorageRedundancy: 'Local'
    useFreeLimit: true
    freeLimitExhaustionBehavior: 'AutoPause'
  }
}

resource dataFactory 'Microsoft.DataFactory/factories@2018-06-01' = {
  name: dataFactoryName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publicNetworkAccess: 'Enabled'
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  tags: tags
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      ipRules: [
        {
          value: '${clientIpAddress}/32'
        }
      ]
      virtualNetworkRules: []
    }
  }
}

resource currentUserVaultAdmin 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, principalId, keyVaultAdministratorRoleId)
  scope: keyVault
  properties: {
    principalId: principalId
    principalType: principalType
    roleDefinitionId: keyVaultAdministratorRoleId
  }
}

resource adfVaultSecretReader 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, dataFactory.id, keyVaultSecretsUserRoleId)
  scope: keyVault
  properties: {
    principalId: dataFactory.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: keyVaultSecretsUserRoleId
  }
}

resource logicWorkflow 'Microsoft.Logic/workflows@2019-05-01' = {
  name: logicAppName
  location: location
  tags: tags
  properties: {
    state: 'Enabled'
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {}
      triggers: {
        manual: {
          type: 'Request'
          kind: 'Http'
          inputs: {
            schema: {
              type: 'object'
              properties: {
                eventType: { type: 'string' }
                pipelineRunId: { type: 'string' }
                tableName: { type: 'string' }
                status: { type: 'string' }
                message: { type: 'string' }
                occurredUtc: { type: 'string' }
              }
            }
          }
        }
      }
      actions: {
        Compose_Notification: {
          type: 'Compose'
          inputs: {
            subject: 'KPMG pipeline notification'
            body: '@{triggerBody()}'
          }
          runAfter: {}
        }
        Response: {
          type: 'Response'
          kind: 'Http'
          inputs: {
            statusCode: 202
            body: {
              accepted: true
              message: 'Notification event recorded in Logic Apps run history.'
            }
          }
          runAfter: {
            Compose_Notification: [
              'Succeeded'
            ]
          }
        }
      }
      outputs: {}
    }
    parameters: {}
  }
}

output sqlServerName string = sqlServer.name
output sqlServerFqdn string = sqlServer.properties.fullyQualifiedDomainName
output sqlDatabaseName string = sqlDatabase.name
output dataFactoryName string = dataFactory.name
output dataFactoryPrincipalId string = dataFactory.identity.principalId
output keyVaultName string = keyVault.name
output logicAppName string = logicWorkflow.name
