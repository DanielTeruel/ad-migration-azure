# GPO-WSUS-Servers
# Creates and links WSUS GPO for OU=Servers
# Download and notify only — no auto restart

Import-Module GroupPolicy

New-GPO -Name "GPO-WSUS-Servers" -Comment "WSUS policy for servers - notify only, no auto-restart"

Set-GPRegistryValue -Name "GPO-WSUS-Servers" -Key "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" -ValueName "WUServer" -Type String -Value "http://DC01:8530"
Set-GPRegistryValue -Name "GPO-WSUS-Servers" -Key "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" -ValueName "WUStatusServer" -Type String -Value "http://DC01:8530"
Set-GPRegistryValue -Name "GPO-WSUS-Servers" -Key "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" -ValueName "UseWUServer" -Type DWord -Value 1
Set-GPRegistryValue -Name "GPO-WSUS-Servers" -Key "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" -ValueName "AUOptions" -Type DWord -Value 3
Set-GPRegistryValue -Name "GPO-WSUS-Servers" -Key "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" -ValueName "NoAutoRebootWithLoggedOnUsers" -Type DWord -Value 1
Set-GPRegistryValue -Name "GPO-WSUS-Servers" -Key "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" -ValueName "TargetGroupEnabled" -Type DWord -Value 1
Set-GPRegistryValue -Name "GPO-WSUS-Servers" -Key "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate" -ValueName "TargetGroup" -Type String -Value "Servers"

New-GPLink -Name "GPO-WSUS-Servers" -Target "OU=Servers,OU=DANIEL,DC=daniel,DC=local"
