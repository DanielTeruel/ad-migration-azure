# Architecture Overview

## On-Premises Infrastructure

Built on VMware Workstation Pro 17. Three virtual machines connected on the same internal network (192.168.75.x).

![On-Premises Architecture](../01-onprem/screenshots/architecture-onprem.png)
```
DC01 · Windows Server 2019 · 192.168.75.4 · 2GB RAM
├─ AD DS (daniel.local)
├─ DNS
├─ DHCP
├─ GPO
│   ├─ GPO-WSUS → OU=Workstations
│   └─ Security policies
├─ File Server → E:\SharedFiles\
│   └─ Backups\APP01\ ← receives WSB backups
└─ WSUS (port 8530)
    ├─ app01.daniel.local ✓
    └─ ws001.daniel.local ✓

APP01 · Windows Server 2019 · 192.168.75.5 · 2GB RAM
├─ IIS (HTTPS:443, port 80 closed)
├─ ASP.NET Core 8
├─ SQL Server Express
│   └─ DanielDB
│       ├─ Proyectos
│       └─ Certificaciones
└─ Windows Server Backup (wbadmin)
    ├─ C:\inetpub\wwwroot
    ├─ C:\inetpub\DanielPortfolio
    ├─ C:\temp\DanielDB.bak
    ├─ Schedule: daily 02:00
    └─ Target: \\DC01\SharedFiles\Backups\APP01\

WS001 · Windows 10 · 192.168.75.7 · 2GB RAM
├─ Domain Joined (daniel.local)
├─ Hybrid Joined
├─ GPO-WSUS applied
└─ Reporting to WSUS
```

## Azure Infrastructure
```
Resource Group: rg-daniellab
│
├─ Identity
│   └─ Entra ID
│       └─ Entra Connect sync from DC01
│           └─ Users + Groups from daniel.local
│
├─ Networking
│   ├─ VNet: vnet-daniellab (10.0.0.0/16)
│   └─ Subnet: snet-app (10.0.1.0/24)
│       └─ NSG-SQL
│           ├─ RDP 3389 → your IP only
│           └─ SQL 1433 → App Service only
│
├─ Compute
│   └─ VM-SQL01 · B2s · Windows Server 2022
│       └─ SQL Server Developer 2022
│           └─ DanielDB (restored from .bak)
│
├─ Web
│   └─ App Service (F1 Free)
│       └─ ASP.NET Core 8 (migrated from APP01)
│           └─ Connection string → VM-SQL01:1433
│
├─ Storage
│   └─ Azure Files (Standard LRS)
│       └─ Migrated from DC01 File Server
│
├─ Backup
│   └─ Recovery Services Vault (GRS)
│       └─ MARS Agent on APP01 (on-prem)
│
├─ Hybrid Management
│   └─ Azure Arc
│       ├─ DC01 (Arc-enabled server)
│       └─ APP01 (Arc-enabled server)
│           └─ Azure Update Manager
│               └─ Replaces WSUS on-prem
│
└─ Security & Compliance
    ├─ Defender for Cloud
    ├─ Azure Policy
    └─ ARM Template export (IaC)
```

## Web Application Architecture (3-Tier)
```
User / WS001
    │
    │ HTTPS :443
    ▼
┌─────────┐     ┌──────────────┐     ┌─────────────────┐
│   IIS   │────►│  ASP.NET 8   │────►│  SQL Server     │
│  :443   │     │  Program.cs  │     │  Express        │
└─────────┘     └──────────────┘     │  └─ DanielDB    │
  ON-PREM          ON-PREM           │     ├─ Proyectos │
                                     │     └─ Certs     │
                                     └─────────────────┘
                                          ON-PREM

After migration:

User
    │
    │ HTTPS
    ▼
┌──────────────┐     ┌─────────────────┐
│ App Service  │────►│ Azure VM B2s    │
│ ASP.NET Core │     │ SQL Server 2022 │
└──────────────┘     │ └─ DanielDB     │
    AZURE             └─────────────────┘
                           AZURE
```

## Migration Map

| On-Premises | Why migrate | Tool | Azure | Approach |
|---|---|---|---|---|
| AD DS | Cloud identity + SSO | Entra Connect | Entra ID | Hybrid sync |
| DNS | Included with Entra | Automatic | Private DNS | Included |
| File Server | Cloud storage + availability | AzCopy | Azure Files | Lift & shift |
| WSUS | Centralized cloud update management | Azure Arc | Azure Update Manager | Replace |
| IIS + ASP.NET | PaaS — no OS management | ZIP Deploy | App Service | PaaS modernization |
| SQL Server Express | IaaS — full SQL compatibility | Backup/Restore .bak | Azure VM + SQL Server | Lift & shift |
| Windows Server Backup | Cloud backup + offsite retention | MARS Agent | Recovery Services Vault | Extend to cloud |

## Key Design Decisions

**Why App Service instead of Azure VM for IIS?**
The web application is a standard ASP.NET Core app with no OS-level dependencies. App Service (PaaS) eliminates OS management overhead, provides built-in scaling, and costs $0 on the F1 tier — making it the right choice for this workload.

**Why Azure VM for SQL Server instead of Azure SQL Database?**
Choosing IaaS for SQL demonstrates a realistic lift & shift scenario where full SQL Server compatibility is required. It also justifies the VNet and NSG configuration, and shows understanding of the IaaS vs PaaS decision-making process.

**Why Azure Arc?**
Arc enables managing on-premises servers (DC01, APP01) directly from Azure Portal without migrating them. This is the foundation for Azure Update Manager, Defender for Cloud coverage on hybrid servers, and Azure Policy enforcement across on-prem and cloud resources.
