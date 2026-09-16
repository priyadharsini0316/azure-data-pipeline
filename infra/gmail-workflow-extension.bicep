// Updates only the existing prototype Logic App after Priya authorizes gmail-kpmg-notify.
// The HTTP Request trigger and 202 Response stay unchanged; email runs afterward.
param location string = resourceGroup().location
param workflowName string
param gmailConnectionName string = 'gmail-kpmg-notify'
param notificationRecipient string = 'priyadharsini0316@gmail.com'

resource gmailConnection 'Microsoft.Web/connections@2016-06-01' existing = {
  name: gmailConnectionName
}

resource workflow 'Microsoft.Logic/workflows@2019-05-01' = {
  name: workflowName
  location: location
  properties: {
    state: 'Enabled'
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {
        '$connections': {
          type: 'Object'
          defaultValue: {}
        }
      }
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
        Send_Gmail_Alert: {
          type: 'ApiConnection'
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'gmail\'][\'connectionId\']'
              }
            }
            method: 'post'
            path: '/v2/Mail'
            body: {
              To: notificationRecipient
              Subject: '@{concat(\'KPMG pipeline: \', triggerBody()?[\'eventType\'], \' / \', triggerBody()?[\'status\'])}'
              Body: '@{concat(\'<p>Table: \', triggerBody()?[\'tableName\'], \'</p><p>Run: \', triggerBody()?[\'pipelineRunId\'], \'</p><p>Message: \', triggerBody()?[\'message\'], \'</p>\')}'
            }
          }
          runAfter: {
            Response: [
              'Succeeded'
            ]
          }
        }
      }
      outputs: {}
    }
    parameters: {
      '$connections': {
        value: {
          gmail: {
            id: subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'gmail')
            connectionId: gmailConnection.id
            connectionName: gmailConnection.name
          }
        }
      }
    }
  }
}
