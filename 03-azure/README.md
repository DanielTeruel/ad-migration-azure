![Azure Infrastructure](./screenshots/banner-azure.png)
![Status](https://img.shields.io/badge/Status-Complete-green)
![Region](https://img.shields.io/badge/Region-francecentral-0078D4)
![Resources](https://img.shields.io/badge/Resources-20+-blue)
![IaC](https://img.shields.io/badge/IaC-ARM%20Template-orange)

# 03 — Azure Infrastructure

## Overview

Complete Azure infrastructure deployed in **francecentral**, hosting the migrated workloads from the on-premises **daniel.local** environment. This phase covers identity synchronisation, networking, SQL Server on IaaS, web application on PaaS, backup, security and file storage — all deployed and managed under the Resource Group **rg-daniellab**.

The environment is fully reproducible via the ARM template in `04-iac/arm/template.json`.

## Resource Group

| Parameter | Value |
|---|---|
| Name | rg-daniellab |
| Region | francecentral |
| Tags | Environment=Lab · Proyecto=Fase10 |

![Resource Group Overview](./screenshots/portal-rg-daniellab-resources-1.png)
![Resource Visualizer](./screenshots/portal-resource-visualizer.png)

## Azure Resources Deployed

| Resource | Name | SKU / Tier | Purpose |
|---|---|---|---|
| Entra ID | daniellab.onmicrosoft.com | Free | Identity sync from daniel.local |
| Virtual Network | vnet-daniellab | Standard | Core networking — 10.0.0.0/16 |
| Network Security Group | nsg-sql | — | Traffic control for vm-sql01 |
| Azure Bastion | bastion-daniellab | Developer | Secure RDP to vm-sql01 |
| Virtual Machine | vm-sql01 | Standard_D2s_v3 | SQL Server host |
| SQL Server | MSSQLSERVER | Developer 2022 | DanielDB — migrated from APP01 |
| App Service Plan | asp-daniellab | B1 Linux | Compute for web application |
| App Service | app-daniellab | B1 Linux | ASP.NET Core 8 portfolio app |
| Key Vault | kv-daniellab | Standard | SQL connection string secret |
| Application Insights | ai-daniellab | Workspace-based | App Service monitoring |
| Log Analytics Workspace | law-daniellab | PerGB2018 | VM logs and metrics |
| Storage Account | stfilesdaniellab | Standard LRS | Azure Files + app transfer |
| Storage Account | stbkpdaniellab | Standard LRS | App Service backup |
| Azure Files Share | danielfiles | Standard | Migrated from DC01 file server |
| Recovery Services Vault | rsv-daniellab | RS0 Standard GRS | SQL workload backup |
| Azure Policy | — | Free | Tag enforcement + backup audit |
| Defender for Cloud | — | Free | Security posture |
| Azure Monitor Alert | alert-cpu-vm-sql01 | — | CPU > 80% on vm-sql01 |

## Migration Map

| On-Premises Service | Source | Azure Service | Section |
|---|---|---|---|
| AD DS (daniel.local) | DC01 | Entra ID | [01-identity](./01-identity/) |
| DNS | DC01 | Entra ID + VNet DNS | [01-identity](./01-identity/) |
| GPO | DC01 | Azure Policy | [07-security](./07-security/) |
| File Server (SharedFiles) | DC01 | Azure Files | [03-fileshare](./03-fileshare/) |
| WSUS | DC01 | Azure Update Manager | 02-azure-migrate/02-update-manager |
| IIS + ASP.NET Core 8 | APP01 | App Service (B1) | [05-webapp](./05-webapp/) |
| SQL Server Express — DanielDB | APP01 | Azure VM + SQL Server Dev | [04-sql-vm](./04-sql-vm/) |
| Windows Server Backup | APP01 | Recovery Services Vault | [06-backup](./06-backup/) |

## Network Architecture

```
10.0.0.0/16 — vnet-daniellab (francecentral)
│
├── snet-default      10.0.1.0/24   → vm-sql01 (10.0.1.10)
├── AzureBastionSubnet 10.0.2.0/26  → Azure Bastion Developer
└── snet-webapp       10.0.3.0/24   → App Service VNet Integration
```

Traffic flow — web application:
```
Browser (HTTPS)
    │
    ▼
App Service (app-daniellab)
    ├── Key Vault → SQL connection string (Managed Identity)
    └── VNet Integration (snet-webapp)
            │
            ▼
        vm-sql01:1433 (private IP — never exposed publicly)
            │
            ▼
        SQL Server — DanielDB
```

## Security Design Decisions

**Managed Identity instead of connection string in config**
The App Service uses a System-assigned Managed Identity to retrieve the SQL connection string from Key Vault at runtime. No credentials are stored in environment variables, source code or deployment configuration.

**No public IP on vm-sql01**
The SQL VM has no public IP address. Access is exclusively via Azure Bastion (administrative) and App Service VNet Integration (application). Port 3389 and 1433 are never exposed to the public internet.

**SQL port 1433 scoped to snet-webapp only**
The NSG rule allowing SQL traffic restricts the source to the App Service integration subnet — not the entire VNet, not the internet.

**Tier Model preserved in cloud identity**
Admin_NoSync OU users are excluded from Entra Connect sync — privileged on-premises accounts have no cloud identity, preventing lateral movement from a cloud compromise to on-premises.

**Azure Policy enforces governance baseline**
Tag enforcement and VM backup audit policies ensure all resources are compliant from day one — replacing the GPO governance model from on-premises.

## Documentation

| Folder | Contents |
|---|---|
| [01-identity](./01-identity/) | Entra Connect, OU filtering, user/group sync, RBAC, MFA |
| [02-networking](./02-networking/) | VNet, NSG, subnets, security rules |
| [03-fileshare](./03-fileshare/) | Azure Files — DC01 file server migration via AzCopy |
| [04-sql-vm](./04-sql-vm/) | VM deployment, SQL Server install, DanielDB migration |
| [05-webapp](./05-webapp/) | App Service, Key Vault, Managed Identity, ZIP deploy |
| [06-backup](./06-backup/) | Recovery Services Vault, SQL workload backup |
| [07-security](./07-security/) | Defender for Cloud, Policy, LAW, App Insights, alerts |

## Status

- [x] 01-identity — Entra Connect sync, RBAC assignments, MFA
- [x] 02-networking — VNet, NSG, subnets configured
- [x] 03-fileshare — DC01 SharedFiles migrated to Azure Files
- [x] 04-sql-vm — vm-sql01 deployed, SQL installed, DanielDB migrated
- [x] 05-webapp — App Service live, Key Vault integrated, ZIP deployed
- [x] 06-backup — RSV configured, DanielDB SQL backup running
- [x] 07-security — Defender, Policy, LAW, alerts configured
- [x] ARM Template — full environment exported to IaC (`04-iac`)
