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
| App Service | B1 | Hosts migrated IIS + ASP.NET web app |
| Azure VM D2s_v3 + SQL Server 2022 | Pay-as-you-go | Hosts migrated SQL Server (IaaS lift & shift) |
| Key Vault | Standard | Stores DB connection string — no secrets in code |
| Azure Files | Standard LRS | Migrated from DC01 File Server |
| Recovery Services Vault | GRS | Cloud backup for SQL Server and App Service |
| Azure Policy | Free | Cloud governance (≈ GPO on-prem) |
| Log Analytics + App Insights | Pay-as-you-go | Monitoring and observability |
| Bicep | — | IaC — reproducible infrastructure from code |
| GitHub Actions | Free | CI/CD — automated deploy on git push |

## Web Application Architecture (3-Tier)

![Web Application 3-Tier Architecture](./screenshots/webapp-3tier.png)

## Migration Map

![Migration Map](./screenshots/migration-map.png)

---

## Architecture Decisions

### Identity

**Why Admin_NoSync OU?**
Privileged accounts are excluded from Entra Connect sync following the Tier Model security principle. Keeping admin accounts out of Entra ID prevents a cloud compromise from propagating to the on-premises domain.

**Why separate GPOs for Servers and Workstations?**
Servers require controlled maintenance windows — an unplanned restart of APP01 would take down IIS, SQL Server, and the web application simultaneously. Workstations can be patched automatically without business impact.

---

### Compute and data

**Why App Service instead of Azure VM for IIS?**
The web application is a standard ASP.NET Core app with no OS-level dependencies. App Service eliminates OS management overhead, provides built-in scaling, and integrates natively with Key Vault via Managed Identity — making it the right PaaS choice for the presentation tier.

**Why Azure VM for SQL Server instead of Azure SQL Database?**
Intentional IaaS lift & shift to demonstrate realistic migration of a SQL workload. It also justifies the VNet, NSG, and Bastion configuration, and shows understanding of the IaaS vs PaaS decision trade-off. In production with a small database, Azure SQL Database (PaaS) would be the preferred option.

**Why JSON export instead of .bak for the SQL migration?**
SQL Server 2025 Express (APP01 on-prem) is not compatible with a restore to SQL Server 2022 (Azure VM) — backup files are not portable downward across versions. JSON export/import is version-agnostic and sufficient for a lab migration. In production, the right tools would be BACPAC or Azure Database Migration Service.

---

### Networking and security

**Why Azure Bastion instead of a public IP on vm-sql01?**
The SQL VM has no public IP. RDP access is only available through Bastion from within the VNet, eliminating direct internet exposure. NSG rules restrict SQL port 1433 to VNet traffic only.

**Why Bastion in Phase 5 and not in Phase 2?**
Without an active VM in Phase 2, Bastion provided no value. Deploying it alongside vm-sql01 in Phase 5 avoids unnecessary cost during earlier phases.

**Why no VPN Site-to-Site?**
Home lab environment without a hardware VPN gateway on-prem. In production, a VPN S2S or ExpressRoute would be required for secure hybrid traffic between on-premises and Azure.

**Why Managed Identity instead of connection strings?**
The App Service accesses Key Vault using its System-assigned Managed Identity — no credentials stored in code or configuration files. This eliminates manual secret rotation and reduces the attack surface.

---

### Storage and deployment

**Why Storage Account as an intermediary for deploy and AzCopy?**
APP01 has no direct internet access to push files to Azure. The Storage Account acts as a secure staging area — the same pattern is reused in Phase 6 (deploy.zip upload) and Phase 7 (AzCopy file migration), keeping the approach consistent.

**Why ZIP Deploy before GitHub Actions?**
ZIP Deploy was done first to understand the manual deployment flow end-to-end. GitHub Actions (Phase 10) then automates that same flow. In production, CI/CD would always be the starting point — but understanding what it automates is valuable.

---

### IaC

**Why ARM Template export first?**
The ARM export served as a full infrastructure backup and a way to understand what Azure actually deployed under the hood. It also provided a reference when rewriting the infrastructure in Bicep and Terraform.

**Why Bicep for IaC?**
Bicep is Azure-native — no state file to manage, tight integration with the Azure Resource Manager, and strong typing. It is the right choice when the infrastructure scope is Azure-only.

**Why also Terraform?**
Terraform was implemented alongside Bicep to demonstrate multi-cloud portability and familiarity with the broader IaC ecosystem. Both tools produce the same result — the difference is portability vs native integration.

---

### FinOps

**Cost decisions made in this lab:**
- `D2s_v3` chosen for vm-sql01 due to availability in francecentral zone 2. In production, a 1-year Reserved Instance reduces cost by ~40%.
- `App Service B1` required for VNet Integration — the F1 free tier does not support it.
- Resource group deleted after completing all phases → $0.00/day. Terraform and Bicep recreate the full infrastructure on demand.
- In production, replacing the SQL VM with Azure SQL Database (PaaS) would eliminate the VM cost entirely for small workloads.
