# AD Migration Lab — On-Premises to Azure

End-to-end migration of a Windows Server Active Directory environment to Microsoft Azure, built as a hands-on portfolio project aligned with real enterprise migration scenarios.

## Architecture Overview
```
ON-PREM (VMware Workstation Pro 17)
─────────────────────────────────────────────────────
  DC01 · Windows Server 2019 · 2GB RAM
  ├─ AD DS (daniel.local) · DNS · DHCP · GPO
  ├─ File Server → E:\SharedFiles\
  └─ WSUS → manages APP01 + WS001

  APP01 · Windows Server 2019 · 2GB RAM
  ├─ IIS (HTTPS:443) + ASP.NET Core 8
  ├─ SQL Server Express → DanielDB
  └─ Windows Server Backup → DC01 File Share

  WS001 · Windows 10 · 2GB RAM
  └─ Domain Joined · GPO-WSUS · Hybrid Joined

AZURE (rg-daniellab)
─────────────────────────────────────────────────────
  Identity      → Entra ID (Entra Connect sync)
  Networking    → VNet + Subnet + NSG
  Arc           → DC01 + APP01 as Arc-enabled servers
  Update Mgmt   → Azure Update Manager (replaces WSUS)
  Web           → App Service F1 (migrated from IIS)
  Database      → Azure VM B2s + SQL Server (IaaS)
  File Storage  → Azure Files (migrated from File Server)
  Backup        → Recovery Services Vault + MARS Agent
  Security      → Defender for Cloud + Azure Policy
  IaC           → ARM Template export
```

## Migration Map

| On-Premises | Tool | Azure |
|---|---|---|
| AD DS (daniel.local) | Entra Connect | Entra ID |
| DNS | Included | Entra ID Private DNS |
| File Server | AzCopy | Azure Files |
| WSUS | Azure Arc | Azure Update Manager |
| IIS + ASP.NET | ZIP Deploy | App Service (F1 Free) |
| SQL Server Express | Backup/Restore .bak | Azure VM + SQL Server |
| Windows Server Backup | MARS Agent | Recovery Services Vault |

## Technologies

**On-Premises:** Windows Server 2019, Active Directory DS, DNS, DHCP, WSUS, Group Policy, IIS, ASP.NET Core 8, SQL Server Express, Windows Server Backup

**Azure:** Entra ID, Entra Connect, Azure Arc, Azure Update Manager, App Service, Azure VM, Azure Files, Recovery Services Vault, MARS Agent, Defender for Cloud, Azure Policy, ARM Templates, VNet, NSG

## Project Structure

| Folder | Contents |
|---|---|
| [00-architecture](./00-architecture/) | Infrastructure diagrams and migration decisions |
| [01-onprem](./01-onprem/) | On-premises setup: DC01, APP01, WS001 |
| [02-azure-migrate](./02-azure-migrate/) | Pre-migration assessment with Azure Migrate |
| [03-azure](./03-azure/) | Azure deployment: identity, networking, Arc, SQL, backup, security |
| [04-iac](./04-iac/) | ARM Template export — IaC awareness |

## Lab Specs

- **Hypervisor:** VMware Workstation Pro 17
- **DC01:** Windows Server 2019 · 2GB RAM
- **APP01:** Windows Server 2019 · 2GB RAM
- **WS001:** Windows 10 · 2GB RAM

## Status

- [x] On-premises infrastructure
- [ ] Azure Migrate assessment
- [ ] Azure deployment
- [ ] Documentation complete
