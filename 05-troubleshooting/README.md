# 🔍 Troubleshooting & Lessons Learned

This section serves as a technical repository of the challenges encountered during the **On-Premise to Azure** migration lifecycle. It documents not only the "how-to" fix but also the "why" behind every solution and the strategic lessons learned for future deployments.

## 🛠️ Methodology: Root Cause Analysis (RCA)

Each documentation file follows a structured approach to problem-solving, moving beyond simple fixes to architectural understanding:

*   **Symptom:** What was failing and how it was detected (Logs, Portal Errors, CLI outputs).
*   **Root Cause:** Deep dive into the "why" (API Version deprecations, SKU unavailability, or Identity/RBAC constraints).
*   **Resolution:** Step-by-step fix applied (Portal, CLI, or IaC code adjustment).
*   **Prevention:** Strategic changes to ensure the issue is mitigated in future CI/CD or IaC pipelines.

---

## 🗂️ Knowledge Base Categories

### 1. [Hybrid Identity & Connectivity](./docs/01-hybrid-identity.md)
*   **Focus:** Entra ID Join synchronization, OU filtering in Entra Connect, and GPO conflicts during the hybrid transition.
*   **Tech Stack:** Microsoft Entra ID, Azure Arc, On-Prem Active Directory.

### 2. [SQL Server & VM Workloads](./docs/02-sql-vm-errors.md)
*   **Focus:** Named Pipes connectivity issues, SQL Login mode (Mixed vs. Windows) misconfigurations, and cross-version backup compatibility.
*   **Tech Stack:** SQL Server 2022, Azure VMs (IaaS), AzCopy.

### 3. [App Service & Web Deployment](./docs/03-webapp-deployment.md)
*   **Focus:** ZIP deployment timeouts, VNet Integration routing logic, and Key Vault Managed Identity permission propagation latencies.
*   **Tech Stack:** Azure App Service (PaaS), Key Vault, Private Endpoints.

### 4. [IaC: ARM Templates](./docs/04-iac-arm-errors.md)
*   **Focus:** API Version deprecations in specific regions (`francecentral`), SKU unavailability, and managing implicit resource dependencies.
*   **Tech Stack:** ARM Templates, JSON, Azure Resource Manager.

### 5. [IaC: Terraform & State Management](./docs/05-iac-terraform-errors.md)
*   **Focus:** Provider version conflicts, manual resource drift management, and `terraform import` logic for pre-existing backup policies.
*   **Tech Stack:** Terraform (HCL), State Management, AzureRM Provider.

---

## 💡 Top 3 Engineering Lessons Learned

1.  **Code-First for Resilience:** Transitioning from ARM to Terraform/Bicep highlighted the importance of modularity. Decoupling network and compute resources allows for faster migration when facing region-specific SKU limitations.
2.  **Identity as the Perimeter:** Most "connectivity" issues in Azure were actually Identity/RBAC issues. Implementing **Managed Identities** by default for App-to-DB communication significantly reduced the attack surface and simplified connection string management.
3.  **Governance as a Pre-requisite:** Implementing `Azure Policy` early in the IaC phase prevented the deployment of non-compliant or over-budgeted SKUs, saving an estimated 40% in initial lab costs.

---
> *Note: This log is a living document used to build a robust Internal Knowledge Base (IKB) for Cloud Operations.*
