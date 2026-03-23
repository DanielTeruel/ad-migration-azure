![Azure Migrate](./banner-migrate.png)
![Status](https://img.shields.io/badge/Status-Complete-green)
![Servers](https://img.shields.io/badge/Servers%20Onboarded-2-blue)
![Arc](https://img.shields.io/badge/Azure%20Arc-Enabled-0078D4)
![Hybrid Join](https://img.shields.io/badge/Hybrid%20Join-Complete-green)

# 02 — Azure Migrate & Hybrid Onboarding

## Overview

This phase covers the **hybrid onboarding** of the on-premises environment into Azure without a full lift-and-shift migration. Rather than replicating VMs to Azure IaaS, the chosen approach uses **Azure Arc** to project on-premises servers into Azure Resource Manager — enabling unified management, policy enforcement, update management and security posture from the Azure Portal.

Both **DC01** and **APP01** remain running on-premises (VMware Workstation Pro 17) and are registered as Arc-enabled servers. **WS001** completes Hybrid Azure AD Join, bridging on-premises Group Policy with Entra ID conditional access.

## Approach: Why Arc instead of full VM migration?

| Criteria | Azure VM Migration | Azure Arc (chosen) |
|---|---|---|
| Workload movement | Full lift & shift to IaaS | Stays on-prem, managed from Azure |
| Cost | VM compute billed 24/7 | Free for Arc management plane |
| SQL Server | Requires SQL on Azure VM | APP01 continues serving SQL on-prem |
| AD DS | DC01 would need dcpromo | DC01 stays as authoritative DC |
| Management | Azure-native only | Unified: on-prem + Azure in one pane |
| Use case fit | Decommission on-prem | Hybrid extension of on-prem |

The SQL Server workload and the web application are migrated separately as PaaS/IaaS resources in `03-azure`. Arc handles the **management plane** while the on-prem servers continue running.

## Servers Onboarded via Azure Arc

| Server | OS | Arc Status | Extensions |
|---|---|---|---|
| DC01 | Windows Server 2019 | Connected | MMA · Defender · Policy |
| APP01 | Windows Server 2019 | Connected | MMA · Defender · Policy |

## Hybrid Join

| Machine | Type | Status |
|---|---|---|
| WS001 | Windows 10 | Hybrid Azure AD Joined |

## What This Phase Enables

| Capability | Tool | Replaces |
|---|---|---|
| Unified server inventory | Azure Arc | Manual asset tracking |
| Patch management | Azure Update Manager | WSUS on DC01 |
| Security posture | Defender for Cloud | — |
| Policy enforcement | Azure Policy (via Arc) | GPO (partial) |
| Identity bridge | Hybrid Azure AD Join | Domain-only identity |
| Remote access | Azure Bastion | RDP direct exposure |

## Phase Steps

| Step | Description |
|---|---|
| 1 | Arc onboarding script generated and executed on DC01 |
| 2 | Arc onboarding script generated and executed on APP01 |
| 3 | Arc connectivity verified in Azure Portal |
| 4 | Azure Update Manager — assessment and patch cycle on both servers |
| 5 | WS001 Hybrid Azure AD Join configured via GPO |
| 6 | Hybrid Join verified in Entra ID device list |
| 7 | Azure Bastion deployed and connectivity tested to vm-sql01 |
| 8 | Update Manager dashboard reviewed post-patching |

## Screenshots

| File | Description |
|---|---|
| arc-script-download.png | Arc onboarding script downloaded from Azure Portal |
| arc-app01-install.png | Arc agent installation running on APP01 |
| arc-dc01-install.png | Arc agent installation running on DC01 |
| arc-app01-completed.png | APP01 showing as Connected in Arc |
| arc-dc01-completed.png | DC01 showing as Connected in Arc |
| arc-servers-portal.png | Both servers visible in Azure Arc — Servers blade |
| arc-onboard-config.png | Arc onboarding configuration options |
| arc-onboard-tags.png | Tags applied during Arc onboarding |
| arc-portal-start.png | Azure Arc portal entry point |
| arc-app01-instll.png | Arc agent install detail on APP01 |
| hybrid-join-status-success.png | WS001 Hybrid Join status — success |
| hybrid-join-ou-filter.png | OU filter configuration for Hybrid Join sync |
| hybrid-join-portal-dev.png | WS001 visible in Entra ID devices |
| hybrid-join-portal-verified.png | Device compliance verified in portal |
| hybrid-join-gpo-config.png | GPO settings for Hybrid Azure AD Join |
| hybrid-join-gpo-linked.png | GPO linked to Workstations OU |
| hybrid-join-ready-to-configure.png | Pre-join readiness check |
| hybrid-join-os-selection.png | OS selection during join wizard |
| hybrid-join-scp-config.png | SCP (Service Connection Point) configuration |
| hybrid-join-all-assignments.png | All policy assignments post-join |
| bastion-created.png | Azure Bastion resource created |
| bastion-pip.png | Public IP associated to Bastion |
| bastion-subnet-created.png | AzureBastionSubnet created in VNet |
| bastion-portal-verified.png | Bastion connectivity test to vm-sql01 |
| update-manager-dc01-updates-selected.png | Updates selected for DC01 |
| update-manager-dc01-onetime-start.png | One-time update run initiated on DC01 |
| update-manager-dc01-install-confirmed.png | DC01 patch installation confirmed |
| update-manager-dc01-dashboard-final.png | Update Manager dashboard post-patching |
| update-manager-dc01-updates-after.png | DC01 update status after patching |
| update-manager-manager-over-view.png | Update Manager overview — all machines |

## Status

- [x] DC01 — Arc onboarded and connected
- [x] APP01 — Arc onboarded and connected
- [x] Azure Update Manager — patch cycle completed on both servers
- [x] WS001 — Hybrid Azure AD Join completed
- [x] Azure Bastion — deployed and verified
- [ ] Azure Migrate Assessment (formal) — not performed (Arc-first approach chosen)
