param name string
param location string = resourceGroup().location
param sku string = 'Free'

param keyVaultResourceId string
#disable-next-line secure-secrets-in-params
param tokenName string

resource staticWebApp 'Microsoft.Web/staticSites@2022-09-01' = {
  name: name
  location: location
  sku: {
    name: sku
  }
  properties: {
    allowConfigFileUpdates: false
  }
}

// Reference the existing Key Vault
resource adminCredentialsKeyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: last(split(keyVaultResourceId, '/')) // Extract the name from the resource ID
}

// Store the static web app token in Key Vault
resource secretStaticWebAppToken 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = {
  name: tokenName
  parent: adminCredentialsKeyVault
  properties: {
    value: staticWebApp.listSecrets().properties.apiKey
  }
}

output staticWebAppUrl string = staticWebApp.properties.defaultHostname
