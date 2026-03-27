# 🔍 Troubleshooting & Lessons Learned

This documentation serves as a technical log and Knowledge Base (KB) of the challenges encountered during the **On-Premise to Azure** migration. It documents the resolution of critical errors across Identity, Databases, App Services, and Infrastructure as Code (IaC).

## 🛠️ Methodology: Root Cause Analysis (RCA)

Each entry in this repository follows a structured problem-solving framework:

*   **Symptom:** Evidence of failure (Logs, HTTP 5xx, CLI errors, Portal validation).
*   **Root Cause:** The "Why" (API deprecations, Identity mismatches, or Protocol constraints).
*   **Resolution:** Precise fix applied (Code snippet, CLI command, or configuration change).
*   **Prevention:** Strategic guardrails to avoid regression in production environments.

---

## 🗂️ Knowledge Base Categories

### 1. [Hybrid Identity & Entra ID](./docs/01-hybrid-identity.md)
*   **Key Challenge:** Device registration failures (`dsregcmd`) due to synchronization scope.
*   **Key Takeaway:** Always verify **OU Filtering** in Entra Connect before initiating Hybrid Joins; computer objects must exist in the cloud before the device can bind.
*   **Tech:** Microsoft Entra Connect, Active Directory, GPO.

### 2. [SQL Server & VM Workloads](./docs/02-sql-vm-errors.md)
*   **Key Challenge:** Region-specific SKU availability (France Central) and SQL version backward-incompatibility (2025 to 2022).
*   **Key Takeaway:** Migrating from higher to lower SQL versions requires data-tier exports (JSON/CSV) as `.bak` files are not backward compatible. 
*   **Tech:** SQL Server 2025/2022, Azure VMs, Azure Backup (Workload).

### 3. [App Service & Web Deployment](./docs/03-webapp-deployment.md)
*   **Key Challenge:** 504 Timeouts during ZIP deploys and connectivity "Error 40" (Named Pipes vs TCP).
*   **Key Takeaway:** Connection strings targeting SQL on Azure VMs must explicitly use `tcp:`, include the port (1433), and require **Mixed Mode Authentication** enabled at the SQL instance level.
*   **Tech:** Azure App Service (Linux), Key Vault, .NET 8.

### 4. [IaC: ARM Template Deep Dive](./docs/04-iac-arm-errors.md)
*   **Key Challenge:** API version volatility and Key Vault "Soft-Delete" name collisions.
*   **Key Takeaway:** Exported templates often contain unstable API versions (e.g., `2024-11-01`). Pinning to stable versions and implementing unique naming suffixes for Key Vaults is mandatory for idempotent deployments.
*   **Tech:** ARM Templates (JSON), Azure Resource Manager, Bastion Developer Tier.

### 5. [IaC: Terraform & State Management](./docs/05-iac-terraform-errors.md)
*   **Key Challenge:** Argument conflicts in `azurerm_windows_virtual_machine` and state "pollution" from system-managed Log Analytics tables.
*   **Key Takeaway:** Use `lifecycle { ignore_changes }` for passwords and manually prune the state (`terraform state rm`) when `aztfexport` captures non-managed system resources.
*   **Tech:** Terraform v1.14+, AzureRM Provider v4.x, `aztfexport`.

---

## 💡 Top Engineering Lessons Learned

1.  **Version Parity is Non-Negotiable:** The migration from SQL Server 2025 (on-prem) to 2022 (Azure VM) highlighted that cloud-readiness starts with version alignment. When parity is impossible, transition to **Data-First** migration (JSON/BACPAC) instead of **Image-First** (.BAK).
2.  **Explicit over Implicit (Networking):** App Service to SQL VM connectivity frequently fails when relying on default drivers. Explicitly defining protocols (`tcp:`) and wrapping passwords with special characters (e.g., `!!`) in single quotes in Key Vault are "small" details that prevent hours of debugging.
3.  **Stateful Resource Lifecycle:** Resources like Key Vault and Backup Policies have a "life after death" (Soft-delete/Auto-generated defaults). IaC logic must account for purging or importing these existing entities to avoid `ConflictError` during redeployments.
4.  **API Resilience:** Never trust "Export Template" API versions blindly. Always validate against the [Azure Resource Reference](https://learn.microsoft.com/en-us/azure/templates/) to ensure compatibility with the target region (e.g., `francecentral`).
