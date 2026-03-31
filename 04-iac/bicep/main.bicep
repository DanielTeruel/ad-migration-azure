targetScope = 'subscription'

// ─── Parámetros globales ───────────────────────────────────────────────────
@description('Región donde se desplegará toda la infraestructura')
param location string = 'francecentral'

@description('Sufijo para nombres únicos de recursos. Se pasa desde GitHub Actions.')
param resourceNameSuffix string

@description('Contraseña del administrador de la VM')
@secure()
param adminPassword string

@description('Usuario administrador de la VM')
param adminUsername string = 'sqladmin'

param vmSize string = 'Standard_D2s_v3'
param appServicePlanSku string = 'B1'

// ─── Grupo de Recursos ─────────────────────────────────────────────────────
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-daniellab-v3'
  location: location
  tags: {
    Environment: 'Lab'
    Proyecto: 'Fase10'
  }
}

// ─── Módulo de infraestructura ─────────────────────────────────────────────
module infra './infra.bicep' = {
  name: 'infraDeployment'
  scope: rg
  params: {
    resourceNameSuffix: resourceNameSuffix
    adminPassword: adminPassword
    adminUsername: adminUsername
    vmSize: vmSize
    appServicePlanSku: appServicePlanSku
  }
}
