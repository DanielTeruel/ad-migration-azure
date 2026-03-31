# 1. Variables
$location = "francecentral"
$templatePath = "C:\Users\estudio\Desktop\json\final\bicep\finalbicep\files\main.bicep"
$suffix = (Get-Date).ToString("yyMMddHH")

# 2. Pedir contraseña
$adminPassword = Read-Host "Introduce la contraseña para la VM" -AsSecureString

# 3. Despliegue a nivel de SUSCRIPCIÓN (no resource group)
New-AzSubscriptionDeployment `
  -Location $location `
  -TemplateFile $templatePath `
  -adminPassword $adminPassword `
  -resourceNameSuffix $suffix `
  -Verbose