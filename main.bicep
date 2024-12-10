@sys.description('The environment type (nonprod or prod)')
@allowed([
  'nonprod'
  'prod'
])
param environmentType string = 'nonprod'
@sys.description('The user alias to add to the deployment name')
param userAlias string = 'ipicazo'
@sys.description('The Azure location where the resources will be deployed')
param location string = 'northeurope'

// App Service Plan
@sys.description('The name of the App Service Plan')
param appServicePlanName string

module appServicePlan 'infra/azure-service-plan.bicep' = {
  name: 'appServicePlan'
  params: {
    location: location
    name: appServicePlanName
    sku: 'B1'
  }
}

// Key Vault
@sys.description('The name of the Key Vault')
param keyVaultName string
@sys.description('Role assignments for the Key Vault')
param keyVaultRoleAssignments array = []

module keyVault 'infra/key-vault.bicep' = {
  name: 'keyVault-${userAlias}'
  params: {
    name: keyVaultName
    location: location
    enableRbacAuthorization: true
    enableVaultForTemplateDeployment: true
    enableVaultForDeployment: true 
    enableSoftDelete: true
    roleAssignments: keyVaultRoleAssignments
  }
}

// Container Registry
@description('The name of the container registry')
param registryName string
@description('The location of the container registry')
param registryLocation string
param containerRegistryUsernameSecretName string 
param containerRegistryPassword0SecretName string 
param containerRegistryPassword1SecretName string 

module containerRegistry 'infra/azure-container-registry.bicep' = {
  name: 'containerRegistry-${userAlias}'
  params: {
    name: registryName
    location: registryLocation
    keyVaultResourceId: keyVault.outputs.keyVaultId
    usernameSecretName: containerRegistryUsernameSecretName
    password0SecretName: containerRegistryPassword0SecretName
    password1SecretName: containerRegistryPassword1SecretName
  }
}

// Container App Service
param containerName string
param dockerRegistryImageName string
param dockerRegistryImageVersion string
param containerAppSettings array
@secure()
param adminUsername string = '' // Default to empty string which will be filled with the values in the key vault
@secure()
param adminPassword string = ''

resource keyVaultReference 'Microsoft.KeyVault/vaults@2023-07-01'existing = {
  name: keyVaultName
}

module containerAppService 'infra/azure-app-service.bicep' = {
  name: 'containerAppService-${userAlias}'
  params: {
    location: location
    name: containerName
    appServicePlanId: appServicePlan.outputs.id
    registryName: registryName
    registryServerUserName: keyVaultReference.getSecret(containerRegistryUsernameSecretName)
    registryServerPassword: keyVaultReference.getSecret(containerRegistryPassword0SecretName)
    registryImageName: dockerRegistryImageName
    registryImageVersion: dockerRegistryImageVersion
    adminUsername: adminUsername
    adminPassword: adminPassword
    appSettings: containerAppSettings
    appCommandLine: ''
  }
  dependsOn: [
    containerRegistry
    keyVault
  ]
}

// Static Web App
@sys.description('The name of the Static Web App')
param staticWebAppName string
@sys.description('The location of the Static Web App')
param staticWebAppLocation string
param staticWebAppTokenName string

module staticWebApp 'infra/static-webapp.bicep' = {
  name: 'staticWebApp-${userAlias}'
  params: {
    name: staticWebAppName
    location: staticWebAppLocation
    keyVaultResourceId: keyVault.outputs.keyVaultId
    tokenName: staticWebAppTokenName
  }
}
