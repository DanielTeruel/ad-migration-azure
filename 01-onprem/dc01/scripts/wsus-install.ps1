# WSUS Installation — DC01
# Installs WSUS role with Windows Internal Database

Install-WindowsFeature -Name UpdateServices, UpdateServices-WidDB, UpdateServices-Services, UpdateServices-RSAT, UpdateServices-API -IncludeManagementTools

# Create content directory and run post-install
New-Item -ItemType Directory -Force -Path "C:\WSUS"
& "C:\Program Files\Update Services\Tools\WsusUtil.exe" postinstall CONTENT_DIR=C:\WSUS
