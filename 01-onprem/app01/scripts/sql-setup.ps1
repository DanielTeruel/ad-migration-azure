# SQL Server Express — DanielDB Setup
# Creates database, tables and inserts initial data

sqlcmd -S APP01\SQLEXPRESS -E -No -Q "
CREATE DATABASE DanielDB;
GO
USE DanielDB;
GO
CREATE TABLE Proyectos (
    Id          INT IDENTITY(1,1) PRIMARY KEY,
    Titulo      NVARCHAR(100)  NOT NULL,
    Tags        NVARCHAR(200)  NOT NULL,
    Descripcion NVARCHAR(1000) NOT NULL,
    Fecha       DATE           NOT NULL
);
GO
CREATE TABLE Certificaciones (
    Id      INT IDENTITY(1,1) PRIMARY KEY,
    Nombre  NVARCHAR(100) NOT NULL,
    Entidad NVARCHAR(100) NOT NULL,
    Fecha   DATE          NOT NULL,
    Skills  NVARCHAR(300) NOT NULL
);
GO
INSERT INTO Proyectos (Titulo, Tags, Descripcion, Fecha) VALUES
('Despliegue de un SOC en AWS', 'AWS,ELK Stack,Docker,SIEM', 'Implementé un sistema de monitoreo con ELK Stack para analizar miles de registros diarios.', '2024-01-01'),
('Red Corporativa Segura & Gestión de Servicios IT', 'Windows Server,Active Directory,VLANs,GPOs,DNS/DHCP', 'Diseñé y configuré una red WAN simulada con más de 20 VLANs.', '2024-06-01'),
('Migración AD Local a Azure', 'Azure,Entra ID,SQL Server,IIS,Recovery Vault', 'Migración completa de infraestructura on-prem hacia Azure.', '2025-01-01');
GO
INSERT INTO Certificaciones (Nombre, Entidad, Fecha, Skills) VALUES
('Microsoft Azure Administrator (AZ-104)', 'Microsoft', '2024-01-01', 'Azure,VMs,RBAC,Storage,ARM,Backup,Entra ID'),
('Inglés C1 - Cambridge Advanced', 'University of Cambridge', '2026-06-01', 'Comprensión y expresión técnica y profesional'),
('Especialización en Ciberseguridad en Entornos TI', 'IES Mar de Cádiz', '2023-06-01', 'Wireshark,Firewalling,Docker,AWS,SQLMap,Metasploit'),
('FPGS Administración de Sistemas Informáticos en Red', 'Colegio San Ignacio Cádiz', '2022-06-01', 'Windows Server,Active Directory,VLANs,TCP/IP,GPOs,DNS');
GO
"

sqlcmd -S APP01\SQLEXPRESS -E -No -Q "
CREATE LOGIN [IIS APPPOOL\DefaultAppPool] FROM WINDOWS;
USE DanielDB;
CREATE USER [IIS APPPOOL\DefaultAppPool] FOR LOGIN [IIS APPPOOL\DefaultAppPool];
ALTER ROLE db_datareader ADD MEMBER [IIS APPPOOL\DefaultAppPool];
"

Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\MSSQL`$SQLEXPRESS" -Name "DelayedAutostart" -Value 1
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\SQLBrowser" -Name "DelayedAutostart" -Value 1
Set-Service -Name "SQLBrowser" -StartupType Automatic
Start-Service -Name "SQLBrowser"

$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-Command `"Start-Service -Name 'MSSQL`$SQLEXPRESS'; Start-Service -Name 'SQLBrowser'`""
$trigger = New-ScheduledTaskTrigger -AtStartup
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest
Register-ScheduledTask -TaskName "StartSQLExpress" -Action $action -Trigger $trigger -Principal $principal -Force
