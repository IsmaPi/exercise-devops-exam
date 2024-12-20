using '../main.bicep'

// App Service Plan
param appServicePlanName = 'appServicePlan'

// Key Vault
param keyVaultName = 'ipicazo-kv'
param keyVaultRoleAssignments = [
  {
    principalId: '25d8d697-c4a2-479f-96e0-15593a830ae5' // BCSAI2024-DEVOPS-STUDENTS-A-SP
    roleDefinitionIdOrName: 'Key Vault Secrets User'
    principalType: 'ServicePrincipal'
  }
]

// Container Registry
param registryName = 'ipicazocr'
param containerRegistryUsernameSecretName = 'ipicazo-cr-username'
param containerRegistryPassword0SecretName = 'ipicazo-cr-password0'
param containerRegistryPassword1SecretName = 'ipicazo-cr-password1'

// Container App Service
param containerName = 'ipicazo-appservice'
param dockerRegistryImageName = 'ipicazo-dockerimg'
param dockerRegistryImageVersion = 'latest'
