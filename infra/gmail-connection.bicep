// Optional, user-authorized Gmail connector for the existing Consumption Logic App.
// Deploys only this named API connection. It does not carry OAuth tokens or secrets.
param location string = resourceGroup().location
param connectionName string = 'gmail-kpmg-notify'

resource gmailConnection 'Microsoft.Web/connections@2016-06-01' = {
  name: connectionName
  location: location
  properties: {
    displayName: connectionName
    api: {
      id: subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'gmail')
    }
  }
}

output connectionName string = gmailConnection.name
