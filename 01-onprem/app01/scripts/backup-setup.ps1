# Windows Server Backup Setup — APP01

Install-WindowsFeature -Name Windows-Server-Backup

sqlcmd -S APP01\SQLEXPRESS -E -No -Q "
BACKUP DATABASE DanielDB
TO DISK = 'C:\temp\DanielDB.bak'
WITH FORMAT, INIT, NAME = 'DanielDB Full Backup';
"

$policy = New-WBPolicy
$specWeb  = New-WBFileSpec -FileSpec "C:\inetpub\wwwroot"
$specCode = New-WBFileSpec -FileSpec "C:\inetpub\DanielPortfolio"
$specBak  = New-WBFileSpec -FileSpec "C:\temp\DanielDB.bak"
Add-WBFileSpec -Policy $policy -FileSpec $specWeb
Add-WBFileSpec -Policy $policy -FileSpec $specCode
Add-WBFileSpec -Policy $policy -FileSpec $specBak

$cred   = Get-Credential
$target = New-WBBackupTarget -NetworkPath "\\DC01\SharedFiles\Backups\APP01" -Credential $cred
Add-WBBackupTarget -Policy $policy -Target $target
Set-WBSchedule -Policy $policy -Schedule 02:00
Set-WBPolicy -Policy $policy

Start-WBBackup -Policy $policy
Get-WBJob -Previous 1 | Select-Object JobState, HResult
