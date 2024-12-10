param userAlias string = 'ipicazo'
param location string = resourceGroup().location

// App Service Plan
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
param keyVaultName string
param keyVaultRoleAssignments array

module keyVault 'infra/key-vault.bicep' = {
  name: 'keyVault-${userAlias}'
  params: {
    name: keyVaultName
    location: location
    roleAssignments: keyVaultRoleAssignments
  }
}

// Container Registry
param registryName string
param containerRegistryUsernameSecretName string 
param containerRegistryPassword0SecretName string 
param containerRegistryPassword1SecretName string 

module containerRegistry 'infra/azure-container-registry.bicep' = {
  name: 'containerRegistry-${userAlias}'
  params: {
    name: registryName
    location: location
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
  }
  dependsOn: [
    containerRegistry
    keyVault
  ]
}
