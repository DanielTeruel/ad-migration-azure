# ARM Templates

## Overview

Azure Resource Manager (ARM) Templates are JSON-based Infrastructure as Code files native to Azure. This section covers exporting the existing `rg-daniellab` infrastructure as an ARM template, modifying it to fix export artifacts, and redeploying the full environment into a new resource group — validating that the infrastructure is fully reproducible from code.

**Role in the IaC journey:** The ARM export served as a first step toward Infrastructure as Code — a way to understand what Azure had actually deployed under the hood, and a reference when later rewriting the infrastructure from scratch in Bicep and Terraform.

## Flow

```
rg-daniellab (existing)
    │
    │  Export template
    ▼
template.json (515KB)
    │
    │  Modify + fix export artifacts
    ▼
template_v2.json + parameters_v2.json
    │
    │  az deployment group validate
    │  az deployment group create
    ▼
rg-daniellab-v2 (new resource group)
    │
    │  Validate + verify all resources
    ▼
Full environment redeployed ✅
    │
    │  Delete original rg-daniellab
    ▼
$0.00/day — Terraform and Bicep recreate on demand
```

## Steps

### 1 — Export ARM Template

The existing infrastructure in `rg-daniellab` is exported from the Azure Portal as a full ARM template.

![ARM Template Exported](./screenshots/arm-template-exported.png)
![ARM Template Exported Show](./screenshots/arm-template-exported-show.png)

The export produces `template.json` (515KB) containing all resource definitions and their current configuration. This file acts as both a deployment artifact and an emergency backup of the full environment.

### 2 — Modify Template

Exported ARM templates are rarely redeploy-ready out of the box — they contain hardcoded resource IDs, export-only properties, and values that cause validation errors on a fresh deployment.

![ARM Template V2 Exported](./screenshots/arm-template-v2-exported.png)
![Parameters V2](./screenshots/parameters_v2.json.png)
![Parameters Created](./screenshots/arm-parameters-created.png)

Key modifications applied:

- Removed non-redeployable resource properties (read-only export artifacts)
- Parameterized environment-specific values into `parameters_v2.json`
- Fixed disk references and VM image references
- Cleaned up Key Vault access policies

### 3 — Validation

The template is validated against the Azure API before deploying — catching errors without creating any resources.

![Validation Passed](./screenshots/ARM-Template-Validation-Passed.png)
![Validation Passed Portal](./screenshots/ARM-Template-Validation-Passed-portal.png)

```bash
az deployment group validate \
  --resource-group rg-daniellab-v2 \
  --template-file template_v2.json \
  --parameters @parameters_v2.json
```

### 4 — Redeploy

![Deploy Running](./screenshots/arm-template-deploy-v2-running.png)
![Deploy Troubleshooting](./screenshots/arm-deploy-troubleshooting.png)
![Deploy Final Resources](./screenshots/arm-deploy-final-resources.png)

Resources are redeployed into `rg-daniellab-v2` using the modified template. Several issues were encountered and resolved during this step — documented in [`05-troubleshooting/docs/04-iac-arm-errors.md`](../../05-troubleshooting/docs/04-iac-arm-errors.md).

### 5 — Key Vault

![Previous KV Purge](./screenshots/arm-previous-kv-purge.png)
![New KV](./screenshots/arm-new-kv.png)
![KV Autorole](./screenshots/arm-kv-autorole.png)
![KV Secret](./screenshots/arm-kv-new.secret.png)

Key Vault requires special handling on redeploy. Azure's soft-delete feature retains deleted vaults for 90 days, meaning a same-named vault cannot be recreated until the previous one is explicitly purged.

```bash
az keyvault purge --name kv-daniellab --location francecentral
```

After purge, the vault is redeployed via the ARM template and the connection string secret is recreated manually.

### 6 — Verification

![RG V2 Created](./screenshots/rg-v2-created.png)
![VM Created](./screenshots/arm-vm-created.png)
![Policy Working](./screenshots/policy-working-proof.png)

| Check | Result |
|---|---|
| Template validation passed | ✅ |
| All resources redeployed in rg-daniellab-v2 | ✅ |
| Key Vault purged and recreated | ✅ |
| Azure Policy still enforced | ✅ |

### 7 — Cleanup

![RG Deleted](./screenshots/rg-daniellab-deleted.png)
![RG Deleting CLI](./screenshots/rg-daniellab-deleting-cli.png)

Original `rg-daniellab` deleted after successful validation of the redeployed environment. From this point, the infrastructure costs $0.00/day — Bicep and Terraform recreate the full environment on demand when needed.

## Why ARM export and not Bicep or Terraform directly?

The ARM export was done first to capture a complete snapshot of the infrastructure as deployed, and to understand what Azure had created under the hood. It also provided a concrete reference when rewriting the environment from scratch in Bicep (Azure-native) and Terraform (multi-cloud). Starting from an export, then rewriting from scratch, demonstrates both the output and the understanding behind it.

## Files

| File | Description |
|---|---|
| `template.json` | Original ARM export (515KB) — full environment snapshot |
| `template_v2.json` | Modified template — redeploy-ready |
| `parameters_v2.json` | Parameterized values for template_v2 |
