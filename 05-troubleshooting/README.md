# Troubleshooting & Lessons Learned

This documentation serves as a technical log and Knowledge Base (KB) of the challenges encountered during the **On-Premise to Azure** migration. It documents the resolution of critical errors across Identity, Databases, App Services, and Infrastructure as Code (IaC).

## Methodology: Root Cause Analysis (RCA)

Each entry follows a structured problem-solving framework:

- **Symptom:** Evidence of failure (logs, HTTP 5xx, CLI errors, portal validation)
- **Root Cause:** The "why" (API deprecations, identity mismatches, protocol constraints)
- **Resolution:** Precise fix applied (code snippet, CLI command, or configuration change)
- **Prevention:** Strategic guardrails to avoid regression in production environments

---

## Knowledge Base

### 1. [Hybrid Identity & Entra ID](./docs/01-hybrid-identity.md)

- **Key Challenge:** Device registration failures (`dsregcmd`) due to synchronisation scope.
- **Key Takeaway:** Always verify OU Filtering in Entra Connect before initiating Hybrid Joins — computer objects must exist in the cloud before the device can bind.
- **Tech:** Microsoft Entra Connect, Active Directory, GPO.

### 2. [SQL Server & VM Workloads](./docs/02-sql-vm-errors.md)

- **Key Challenge:** Region-specific SKU availability (francecentral) and SQL version backward-incompatibility (2025 to 2022).
- **Key Takeaway:** Migrating from a higher to a lower SQL version requires data-tier exports (JSON/BACPAC) — `.bak` files are not backward compatible.
- **Tech:** SQL Server 2025/2022, Azure VMs, Azure Backup (Workload).

### 3. [App Service & Web Deployment](./docs/03-webapp-deployment.md)

- **Key Challenge:** 504 timeouts during ZIP deploys and connectivity Error 40 (Named Pipes vs TCP).
- **Key Takeaway:** Connection strings targeting SQL on Azure VMs must explicitly use `tcp:`, include the port (1433), and require Mixed Mode Authentication enabled at the SQL instance level.
- **Tech:** Azure App Service (Linux), Key Vault, .NET 8.

### 4. [IaC: ARM Template](./docs/04-iac-arm-errors.md)

- **Key Challenge:** API version volatility and Key Vault soft-delete name collisions.
- **Key Takeaway:** Exported templates often contain unstable API versions (e.g., `2024-11-01`). Pinning to stable versions and purging soft-deleted Key Vaults before redeployment is required for idempotent deployments.
- **Tech:** ARM Templates (JSON), Azure Resource Manager, Bastion Developer SKU.

### 5. [IaC: Terraform & State Management](./docs/05-iac-terraform-errors.md)

- **Key Challenge:** Argument conflicts in `azurerm_windows_virtual_machine` and state pollution from system-managed Log Analytics tables.
- **Key Takeaway:** Use `lifecycle { ignore_changes }` for passwords and manually prune the state (`terraform state rm`) when `aztfexport` captures non-managed system resources.
- **Tech:** Terraform v1.14+, AzureRM Provider v4.x, `aztfexport`.

### 6. [CI/CD: GitHub Actions](./docs/06-cicd-errors.md)

- **Key Challenge:** GitHub Actions workflow failures during automated deploy to App Service — publish profile authentication, VNet Integration conflicts, and database connectivity after pipeline-triggered deployments.
- **Key Takeaway:** The publish profile must be re-downloaded after any App Service configuration change (VNet Integration, managed identity). Connection strings set via pipeline environment variables take precedence over Key Vault references — always validate the full chain end-to-end after a CI/CD deploy, not just the build step.
- **Tech:** GitHub Actions, Azure App Service, Azure Key Vault, ASP.NET Core 8.

---

## Top Engineering Lessons Learned

**1. Version parity is non-negotiable**
The migration from SQL Server 2025 (on-prem) to 2022 (Azure VM) highlighted that cloud-readiness starts with version alignment. When parity is impossible, use a data-first migration (JSON/BACPAC) instead of an image-first approach (.bak).

**2. Explicit over implicit in networking**
App Service to SQL VM connectivity frequently fails when relying on default drivers. Explicitly defining protocols (`tcp:`) and correctly quoting passwords with special characters in Key Vault are small details that prevent hours of debugging.

**3. Stateful resource lifecycle**
Resources like Key Vault and Backup Policies have a life after deletion (soft-delete, auto-generated defaults). IaC logic must account for purging or importing these existing entities to avoid `ConflictError` during redeployments.

**4. API version resilience**
Never trust exported template API versions blindly. Always validate against the [Azure Resource Reference](https://learn.microsoft.com/en-us/azure/templates/) to confirm compatibility with the target region.

**5. CI/CD exposes configuration assumptions**
Automating a deployment that worked manually will surface every implicit dependency — environment variables, managed identity scopes, VNet routing. A passing pipeline build does not mean a working application. End-to-end smoke tests after each deploy are not optional.
