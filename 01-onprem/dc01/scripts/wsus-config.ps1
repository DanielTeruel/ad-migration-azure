# WSUS Configuration — DC01
# Configures sync, products, classifications and client-side targeting

Import-Module UpdateServices

$wsus = Get-WsusServer -Name DC01 -PortNumber 8530

# Configure sync from Microsoft Update
$wsusConfig = $wsus.GetConfiguration()
$wsusConfig.SyncFromMicrosoftUpdate = $true
$wsusConfig.Save()

# Sync categories
$subscription = $wsus.GetSubscription()
$subscription.StartSynchronizationForCategoryOnly()
while ($subscription.GetSynchronizationStatus() -eq "Running") {
    Write-Host "Syncing categories..."
    Start-Sleep -Seconds 5
}

# Set products
$productCollection = New-Object Microsoft.UpdateServices.Administration.UpdateCategoryCollection
$wsus.GetUpdateCategories() | Where-Object {
    $_.Title -match "Windows 10" -or
    $_.Title -match "Windows 11" -or
    $_.Title -match "Windows Server 2019"
} | ForEach-Object { $productCollection.Add($_) }
$subscription.SetUpdateCategories($productCollection)

# Set classifications
$classCollection = New-Object Microsoft.UpdateServices.Administration.UpdateClassificationCollection
$wsus.GetUpdateClassifications() | Where-Object {
    $_.Title -match "Critical" -or
    $_.Title -match "Security" -or
    $_.Title -match "Críticas" -or
    $_.Title -match "Seguridad"
} | ForEach-Object { $classCollection.Add($_) }
$subscription.SetUpdateClassifications($classCollection)
$subscription.Save()

# Configure SQL Browser for auto start
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\SQLBrowser" -Name "DelayedAutostart" -Value 1
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\MSSQL`$SQLEXPRESS" -Name "DelayedAutostart" -Value 1
