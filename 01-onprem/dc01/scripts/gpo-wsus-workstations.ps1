# GPO-WSUS — Workstations
# Creates and links WSUS GPO for OU=Workstations

Import-Module GroupPolicy

New-GPO -Name "GPO-WSUS" -Comment "Points clients to WSUS on DC01"

Set-GPRegistryValue -Name "GPO-WSUS" -Key "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" -ValueName "WUServer" -Type String -Value "http://DC01:8530"
Set-GPRegistryValue -Name "GPO-WSUS" -Key "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" -ValueName "WUStatusServer" -Type String -Value "http://DC01:8530"
Set-GPRegistryValue -Name "GPO-WSUS" -Key "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" -ValueName "UseWUServer" -Type DWord -Value 1
Set-GPRegistryValue -Name "GPO-WSUS" -Key "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" -ValueName "AUOptions" -Type DWord -Value 4
Set-GPRegistryValue -Name "GPO-WSUS" -Key "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" -ValueName "TargetGroupEnabled" -Type DWord -Value 1
Set-GPRegistryValue -Name "GPO-WSUS" -Key "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" -ValueName "TargetGroup" -Type String -Value "Workstations"

New-GPLink -Name "GPO-WSUS" -Target "OU=Workstations,OU=DANIEL,DC=daniel,DC=local"
