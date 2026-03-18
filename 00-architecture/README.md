# Architecture Overview

## On-Premises Infrastructure

Built on VMware Workstation Pro 17. Three virtual machines connected on the same internal network (192.168.75.x).

![On-Premises Infrastructure](./screenshots/onprem-infrastructure.png)

| Server | OS | IP | RAM | Roles |
|---|---|---|---|---|
| DC01 | Windows Server 2019 | 192.168.75.4 | 2GB | AD DS · DNS · DHCP · GPO · WSUS · File Server |
| APP01 | Windows Server 2019 | 192.168.75.5 | 2GB | IIS · ASP.NET Core 8 · SQL Server Express · WSB |
| WS001 | Windows 10 | 192.168.75.7 | 2GB | Domain Joined · GPO-WSUS · Client |

## Azure Infrastructure

![Azure Infrastructure](./screenshots/azure-infrastructure.png)

| Service | SKU | Purpose |
|---|---|---|
| Entra ID | Free | Identity sync from daniel.local via Entra Connect |
| VNet + NSG | Standard | Networking for Azure VM |
| Azure Arc | Free | Hybrid management of DC01 + APP01 |
| Azure Update Manager | Free | Replaces WSUS on-prem |
| App Service | F1 Free | Hosts migrated IIS + ASP.NET web app |
| Azure VM B2s + SQL Server | Pay-as-you-go | Hosts migrated SQL Server Express (IaaS) |
| Azure Files | Standard LRS | Migrated from DC01 File Server |
| Recovery Services Vault | GRS | Cloud backup via MARS Agent |
| Defender for Cloud | Free | Security posture and compliance |
| Azure Policy | Free | Cloud governance (≈ GPO on-prem) |
| ARM Template | — | IaC export of full Azure environment |

## Web Application Architecture (3-Tier)

![Web Application 3-Tier Architecture](./screenshots/webapp-3tier.png)

## Migration Map

![Migration Map](./screenshots/migration-map.png)

## Key Design Decisions

**Why App Service instead of Azure VM for IIS?**
The web application is a standard ASP.NET Core app with no OS-level dependencies. App Service (PaaS) eliminates OS management overhead, provides built-in scaling, and costs $0 on the F1 tier — making it the right choice for this workload.

**Why Azure VM for SQL Server instead of Azure SQL Database?**
Choosing IaaS for SQL demonstrates a realistic lift & shift scenario where full SQL Server compatibility is required. It also justifies the VNet and NSG configuration, and shows understanding of the IaaS vs PaaS decision-making process.

**Why Azure Arc?**
Arc enables managing on-premises servers (DC01, APP01) directly from Azure Portal without migrating them. This is the foundation for Azure Update Manager, Defender for Cloud coverage on hybrid servers, and Azure Policy enforcement across on-prem and cloud resources.

**Why separate GPOs for Servers and Workstations?**
Servers require controlled maintenance windows — an unplanned restart of APP01 would take down IIS, SQL Server and the web application. Workstations can be patched automatically without business impact.

**Why Admin_NoSync OU?**
Privileged accounts are excluded from Entra Connect sync following the Tier Model security principle — preventing a cloud compromise from becoming an on-premises breach.