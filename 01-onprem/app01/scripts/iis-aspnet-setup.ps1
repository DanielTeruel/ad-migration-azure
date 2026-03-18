# IIS + ASP.NET Core 8 Setup

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
New-Item -ItemType Directory -Force -Path C:\temp
Invoke-WebRequest -Uri "https://aka.ms/dotnet/8.0/dotnet-hosting-win.exe" -OutFile "C:\temp\dotnet-hosting.exe"
Start-Process "C:\temp\dotnet-hosting.exe" -ArgumentList "/quiet /norestart" -Wait

New-Item -ItemType Directory -Force -Path C:\inetpub\DanielPortfolio
cd C:\inetpub\DanielPortfolio
dotnet new web -n DanielPortfolio
cd DanielPortfolio
dotnet add package Microsoft.Data.SqlClient
dotnet publish -c Release -o C:\inetpub\DanielPortfolio\publish

iisreset /stop
Copy-Item -Path "C:\inetpub\DanielPortfolio\publish\*" -Destination "C:\inetpub\wwwroot\" -Recurse -Force
iisreset /start

Import-Module WebAdministration
Set-ItemProperty "IIS:\AppPools\DefaultAppPool" managedRuntimeVersion ""
