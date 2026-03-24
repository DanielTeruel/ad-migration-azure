# 01-identity — Entra ID & Identity

## Overview

This section covers the identity bridge between the on-premises **daniel.local** domain and Azure. **Entra Connect** synchronises users and groups from AD DS to Entra ID, RBAC roles are assigned to the synced security groups, and MFA is enforced via Security Defaults.

**Migration source:** AD DS on DC01 (daniel.local)
**Migration target:** Entra ID (Free tier)

## Entra Tenant

![Tenant Overview](./screenshots/entra-tenant-overview.png)

| Field | Value |
|---|---|
| Tenant | daniellab.onmicrosoft.com |
| Tier | Entra ID Free |
| Sync tool | Entra Connect (Azure AD Connect) |

## Entra Connect — Installation

![Download](./screenshots/entra-connect-download.png)
![Install Start](./screenshots/entra-connect-install-start.png)
![Install Custom](./screenshots/entra-connect-install-custom.png)
![Installing](./screenshots/entra-connect-installing.png)

Entra Connect is installed on **DC01** — the Domain Controller hosting AD DS. Custom installation is selected to enable granular OU filtering and control over which objects are synchronised.

| Setting | Value |
|---|---|
| Installation host | DC01 (192.168.75.4) |
| Installation type | Custom |
| Service account | Auto-created by installer |

## Entra Connect — Configuration

### Sign-in Method

![Sign-in Method](./screenshots/entra-connect-signin-method.png)

**Password Hash Synchronisation** selected — hashes are synced to Entra ID enabling cloud authentication without on-prem dependency for each login.

### Directory Connection

![Directories 0](./screenshots/entra-connect-directories0.png)
![Directories 1](./screenshots/entra-connect-directories1.png)

`daniel.local` domain connected as the source directory.

### UPN Warning

![UPN Warning](./screenshots/entra-connect-upn-warning.png)

The `daniel.local` domain suffix is non-routable (not a public DNS domain). Entra Connect warns that users will sync with the `onmicrosoft.com` UPN suffix — expected and accepted for a lab environment.

### User Identification

![User Identification](./screenshots/entra-connect-user-identification.png)

Users identified by `objectGUID` — standard for single-forest environments.

### OU Filtering

![OU Filter](./screenshots/entra-connect-ou-filter.png)
![Filtering](./screenshots/entra-connect-filtering.png)

Only specific OUs are included in sync scope — following the security design from `01-onprem`:

| OU | Synced | Reason |
|---|---|---|
| Departamentos/HR | ✅ | Business users |
| Departamentos/IT | ✅ | Business users |
| Departamentos/General | ✅ | Business users |
| Grupos | ✅ | Security groups for RBAC |
| Admin_NoSync | ❌ | Privileged accounts — Tier Model |
| Departamentos/Admin | ❌ | Admin users excluded |
| Servers | ❌ | Computer objects excluded |
| Workstations | ❌ | Computer objects excluded |
| Service_Accounts | ❌ | Service accounts excluded |

### Optional Features

![Optional Features](./screenshots/entra-connect-optional-features.png)

No optional features enabled — Password Writeback and Group Writeback are not required for this lab scenario.

### Ready to Configure

![Ready to Configure](./screenshots/entra-connect-ready-to-configure.png)
![Learn](./screenshots/entra-connect-learn.png)

### Installation Completed

![Completed](./screenshots/entra-connect-completed.png)
![Sync Service](./screenshots/entra-connect-sync-service.png)

Entra Connect sync service starts automatically after installation. Initial sync cycle runs immediately.

## Sync Results

### Users

![Users Before Sync](./screenshots/entra-users-before-sync.png)
![Users After Sync](./screenshots/entra-users-after-sync.png)

| User | OU | Synced |
|---|---|---|
| user1_it | Departamentos/IT | ✅ |
| user2_hr | Departamentos/HR | ✅ |
| user4_general | Departamentos/General | ✅ |
| user3_admin | Admin_NoSync | ❌ (excluded) |

![User Detail](./screenshots/entra-user-detail.png)

### Groups

![Groups Before Sync](./screenshots/entra-groups-before-sync.png)
![Groups After Sync](./screenshots/entra-groups-after-sync.png)

| Group | Synced | Purpose |
|---|---|---|
| Sec_Admins | ✅ | Maps to Contributor on rg-daniellab |
| Sec_IT | ✅ | Maps to Reader on rg-daniellab |
| Sec_HR | ✅ | Maps to Reader on rg-daniellab |

## Sync Service Account

![Sync Admin Created](./screenshots/entra-sync-admin-created.png)
![Sync Role](./screenshots/entra-sync-role.png)

A dedicated sync account is created in Entra ID by the Entra Connect installer with the minimum permissions required for directory synchronisation.

## RBAC Assignments

![RBAC Resource Group](./screenshots/entra-rbac-resource-group.png)
![All Assignments](./screenshots/entra-rbac-all-assignments.png)

RBAC roles are assigned at the **Resource Group** scope (`rg-daniellab`) to the synced security groups — following least privilege:

| AD Group | Entra ID Group | Azure Role | Scope |
|---|---|---|---|
| Sec_Admins | Sec_Admins | Contributor | rg-daniellab |
| Sec_IT | Sec_IT | Reader | rg-daniellab |
| Sec_HR | Sec_HR | Reader | rg-daniellab |

![Sec Admins](./screenshots/entra-rbac-sec-admins.png)
![Sec Admins 2](./screenshots/entra-rbac-sec-admins2.png)
![Sec HR](./screenshots/entra-rbac-sec-hr.png)
![Sec IT](./screenshots/entra-rbac-sec-it.png)

**Why group-based RBAC instead of per-user assignment?**
Assigning roles to groups mirrors enterprise practice — when a user joins or leaves a team, AD group membership controls their Azure access automatically without touching RBAC assignments.

## MFA — Security Defaults

![MFA Security Defaults](./screenshots/mfa-security-defaults-portal.png)

Security Defaults enabled on the tenant — enforces MFA for all users on privileged operations and provides baseline protection at zero additional cost on the Free tier.

## Design Decisions

**Why exclude Admin_NoSync from sync?**
Privileged accounts are isolated from cloud sync following the Tier Model security principle. A cloud identity compromise cannot be used to escalate to on-premises domain admin. This is a deliberate security boundary, not an oversight.

**Why Password Hash Sync instead of Pass-through Authentication?**
PHS does not require an on-premises agent to be available for every authentication. In a lab where VMs can be shut down, PHS ensures cloud authentication continues working regardless of DC01 availability.

**Why Free tier Entra ID?**
The lab demonstrates synchronisation, RBAC and MFA — all available on Free. Paid features (Conditional Access policies, Identity Protection, Privileged Identity Management) are out of scope for this phase.
