![On-Premises Infrastructure](./banner-onprem.png)

![Status](https://img.shields.io/badge/Status-Complete-green)
![VMs](https://img.shields.io/badge/VMs-3-blue)
![Hypervisor](https://img.shields.io/badge/Hypervisor-VMware%20Workstation%20Pro%2017-lightgrey)
![OS](https://img.shields.io/badge/OS-Windows%20Server%202019-blue)

# 01 — On-Premises Infrastructure

## Overview

Complete on-premises infrastructure built on **VMware Workstation Pro 17**, simulating a real enterprise environment with a Domain Controller, an Application Server and a Windows 10 client machine — all joined to the **daniel.local** domain.

This environment serves as the migration source for the Azure phase of the lab.

## Servers

| Server | OS | IP | RAM | Role |
|---|---|---|---|---|
| DC01 | Windows Server 2019 | 192.168.75.4 | 2GB | Domain Controller |
| APP01 | Windows Server 2019 | 192.168.75.5 | 2GB | Application Server |
| WS001 | Windows 10 | 192.168.75.7 | 2GB | Client Machine |

## Services Deployed

| Service | Server | Migrates To |
|---|---|---|
| AD DS (daniel.local) | DC01 | Entra ID |
| DNS | DC01 | Entra ID Private DNS |
| DHCP | DC01 | — |
| GPO | DC01 | Azure Policy |
| File Server | DC01 | Azure Files |
| WSUS | DC01 | Azure Update Manager |
| IIS + ASP.NET Core 8 | APP01 | App Service (F1 Free) |
| SQL Server Express | APP01 | Azure VM + SQL Server |
| Windows Server Backup | APP01 | Recovery Services Vault |

## AD Structure

| OU | Contents | Synced to Entra ID |
|---|---|---|
| Departamentos/Admin | user3_admin | ❌ (Admin_NoSync) |
| Departamentos/HR | user2_hr | ✅ |
| Departamentos/IT | user1_it | ✅ |
| Departamentos/General | user4_general | ✅ |
| Grupos | Sec_Admins · Sec_HR · Sec_IT | ✅ |
| Servers | APP01 | ❌ (computers excluded) |
| Workstations | WS001 | ❌ (computers excluded) |
| Admin_NoSync | user3_admin · App01Admin | ❌ (privileged accounts) |
| Service_Accounts | — | ❌ (reserved) |

## RBAC Mapping (On-Prem → Azure)

| AD Group | Azure Role | Scope |
|---|---|---|
| Sec_Admins | Contributor | rg-daniellab |
| Sec_IT | Reader | rg-daniellab |
| Sec_HR | Reader | rg-daniellab |

## Security Design Decisions

**Tier Model — Admin_NoSync OU**
Privileged accounts are isolated from cloud sync following the Tier Model security principle. A cloud compromise cannot be used to attack on-premises privileged accounts.

**Least Privilege — RBAC mapping**
AD security groups are mapped to Azure RBAC roles following least privilege — no user has more permissions than strictly necessary.

**Separate GPOs for Servers and Workstations**
APP01 (OU=Servers) receives GPO-WSUS-Servers with notify-only update behavior and no auto-restart. WS001 (OU=Workstations) receives GPO-WSUS with automatic install. This prevents unplanned service outages on the application server.

**Port 80 closed on APP01**
IIS is configured to serve only over HTTPS (port 443). Port 80 is closed to reduce the attack surface — no unencrypted traffic is accepted.

## Documentation

| Folder | Contents |
|---|---|
| [dc01](./dc01/) | Domain Controller — AD DS, DNS, DHCP, GPO, WSUS, File Server |
| [app01](./app01/) | Application Server — IIS, ASP.NET Core 8, SQL Server, WSB |
| [ws001](./ws001/) | Client Machine — Domain Join, GPO, WSUS, resource access |

## Status

- [x] DC01 — fully configured and documented
- [x] APP01 — fully configured and documented
- [x] WS001 — fully configured and documented
- [ ] Hybrid Azure AD Join (WS001) — pending Azure phase