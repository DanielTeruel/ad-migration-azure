// ─── Parámetros ───────────────────────────────────────────────────────────
@description('Sufijo único para nombres de recursos (lo pasa main.bicep)')
param resourceNameSuffix string

@description('Contraseña administrador de la VM')
@secure()
param adminPassword string

@description('Usuario administrador de la VM')
param adminUsername string

param vmSize string = 'Standard_D2s_v3'
param appServicePlanSku string = 'B1'

// ─── Variables ─────────────────────────────────────────────────────────────
var suffix        = take(resourceNameSuffix, 4)
var location      = resourceGroup().location
var tenantId      = subscription().tenantId
var unique5       = take(uniqueString(resourceGroup().id), 5)
var unique4       = take(uniqueString(resourceGroup().id), 4)

// Nombres de recursos — deterministas (sin utcNow en el nombre)
var kvName          = 'kv-daniellab-${suffix}'
var vnetName        = 'vnet-daniellab-${suffix}'
var appServiceName  = 'app-daniellab-${suffix}'
var storageBackupName = 'stbkp${suffix}${unique5}'
var storageFilesName  = 'stfiles${suffix}${unique4}'

// ─── Action Group ──────────────────────────────────────────────────────────
resource actionGroup 'microsoft.insights/actionGroups@2023-01-01' = {
  name: 'Application Insights Smart Detection'
  location: 'Global'
  properties: {
    groupShortName: 'SmartDetect'
    enabled: true
    emailReceivers: []
    smsReceivers: []
    webhookReceivers: []
    armRoleReceivers: []
  }
}

// ─── Key Vault ─────────────────────────────────────────────────────────────
resource kv 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: kvName
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: tenantId
    enableRbacAuthorization: true
    accessPolicies: []
  }
}

// ─── NSG ───────────────────────────────────────────────────────────────────
resource nsgSql 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: 'nsg-sql'
  location: location
  properties: {
    securityRules: []
  }
}

// ─── VNet ──────────────────────────────────────────────────────────────────
resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: ['10.0.0.0/16']
    }
    subnets: [
      {
        name: 'snet-default'
        properties: {
          addressPrefix: '10.0.1.0/24'
          networkSecurityGroup: { id: nsgSql.id }
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: '10.0.2.0/27'
        }
      }
    ]
  }
}

// ─── NIC ───────────────────────────────────────────────────────────────────
resource nic 'Microsoft.Network/networkInterfaces@2024-05-01' = {
  name: 'vm-sql01VMNic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAddress: '10.0.1.10'
          privateIPAllocationMethod: 'Static'
          subnet: { id: '${vnet.id}/subnets/snet-default' }
          primary: true
        }
      }
    ]
    enableIPForwarding: false
    enableAcceleratedNetworking: false
  }
}

// ─── Bastion ───────────────────────────────────────────────────────────────
resource bastion 'Microsoft.Network/bastionHosts@2024-05-01' = {
  name: 'bastion-daniellab'
  location: location
  sku: { name: 'Developer' }
  properties: {
    virtualNetwork: { id: vnet.id }
  }
}

// ─── Storage — Backup ──────────────────────────────────────────────────────
resource storageBackup 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageBackupName
  location: location
  sku: { name: 'Standard_LRS' }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
  }
}

// ─── Storage — Files ───────────────────────────────────────────────────────
resource storageFiles 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageFilesName
  location: location
  sku: { name: 'Standard_LRS' }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
  }
}

// ─── Log Analytics Workspace ───────────────────────────────────────────────
resource law 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: 'law-daniellab'
  location: location
  properties: {
    sku: { name: 'PerGB2018' }
    retentionInDays: 30
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}

// ─── Application Insights ──────────────────────────────────────────────────
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: 'ai-daniellab'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Flow_Type: 'Redfield'
    Request_Source: 'IbizaAIExtension'
    WorkspaceResourceId: law.id
    IngestionMode: 'LogAnalytics'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// ─── Smart Detector Alert ──────────────────────────────────────────────────
resource failureAnomalies 'microsoft.alertsmanagement/smartdetectoralertrules@2021-04-01' = {
  name: 'failure-anomalies-ai-daniellab'
  location: 'global'
  properties: {
    description: 'Alerta cuando la tasa de errores de la app aumenta de forma anómala'
    state: 'Enabled'
    severity: 'Sev3'
    frequency: 'PT1M'
    detector: { id: 'FailureAnomaliesDetector' }
    scope: [appInsights.id]
    actionGroups: {
      groupIds: [actionGroup.id]
    }
  }
}

// ─── App Service Plan ──────────────────────────────────────────────────────
resource asp 'Microsoft.Web/serverfarms@2024-04-01' = {
  name: 'asp-daniellab'
  location: location
  sku: {
    name: appServicePlanSku
    tier: 'Basic'
    size: appServicePlanSku
    family: 'B'
    capacity: 1
  }
  kind: 'linux'
  properties: {
    reserved: true
    isSpot: false
    zoneRedundant: false
  }
}

// ─── Recovery Services Vault ───────────────────────────────────────────────
resource rsv 'Microsoft.RecoveryServices/vaults@2024-04-01' = {
  name: 'rsv-daniellab'
  location: location
  sku: {
    name: 'RS0'
    tier: 'Standard'
  }
  properties: {
    publicNetworkAccess: 'Enabled'
  }
}

// ─── Virtual Machine (SQL01) ───────────────────────────────────────────────
resource vmSql01 'Microsoft.Compute/virtualMachines@2024-07-01' = {
  name: 'vm-sql01'
  location: location
  identity: { type: 'SystemAssigned' }
  properties: {
    hardwareProfile: { vmSize: vmSize }
    osProfile: {
      computerName: 'vm-sql01'
      adminUsername: adminUsername          
      adminPassword: adminPassword
      windowsConfiguration: {
        enableAutomaticUpdates: true
        provisionVMAgent: true
        patchSettings: {
          patchMode: 'AutomaticByOS'
          assessmentMode: 'ImageDefault'
        }
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-datacenter-azure-edition'
        version: 'latest'
      }
      osDisk: {
        name: 'vm-sql01-osdisk'
        createOption: 'FromImage'
        managedDisk: { storageAccountType: 'Premium_LRS' }
        diskSizeGB: 128
      }
      dataDisks: []
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
          properties: { primary: true }
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: { enabled: true }
    }
  }
}

// ─── Alerta CPU VM ─────────────────────────────────────────────────────────
resource alertCpuVm 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'alert-cpu-vm-sql01'
  location: 'global'
  properties: {
    description: 'Alerta cuando CPU de vm-sql01 supera el 80% durante 1 minuto'
    severity: 2
    enabled: true
    scopes: [vmSql01.id]
    evaluationFrequency: 'PT1M'
    windowSize: 'PT1M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'cpu-over-80'
          criterionType: 'StaticThresholdCriterion'
          metricNamespace: 'Microsoft.Compute/virtualMachines'
          metricName: 'Percentage CPU'
          operator: 'GreaterThan'
          threshold: 80
          timeAggregation: 'Average'
        }
      ]
    }
    actions: [
      { actionGroupId: actionGroup.id }
    ]
  }
}

// ─── App Service ───────────────────────────────────────────────────────────
resource appService 'Microsoft.Web/sites@2024-04-01' = {
  name: appServiceName
  location: location
  identity: { type: 'SystemAssigned' }
  kind: 'app,linux'
  properties: {
    serverFarmId: asp.id
    reserved: true
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'DOTNETCORE|8.0'
      alwaysOn: false
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      http20Enabled: true
    }
  }
}
