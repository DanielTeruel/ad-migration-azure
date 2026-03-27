# ARM Templates

## Overview

Azure Resource Manager (ARM) Templates are JSON-based Infrastructure as Code files native to Azure. This phase covers exporting the existing `rg-daniellab` infrastructure, modifying the template to fix exportation artifacts, and redeploying into a new resource group.

## Flow
```
rg-daniellab (existing)
    │
    │  Export template
    ▼
template.json + parameters.json
    │
    │  Modify + fix
    ▼
template_v2.json + parameters_v2.json
    │
    │  az deployment group create
    ▼
rg-daniellab-v2 (new resource group)
    │
    │  Validate + verify
    ▼
All resources redeployed ✅
```

## Steps

### 1 — Export ARM Template

The existing infrastructure in `rg-daniellab` is exported from the Azure Portal as a full ARM template.

![ARM Template Exported](./screenshots/arm-template-exported.png)
![ARM Template Exported Show](./screenshots/arm-template-exported-show.png)

The export produces `template.json` (515KB) containing all resource definitions and their current configuration.

### 2 — Modify Template

The exported template requires modifications before redeployment — exported templates often contain hardcoded values, resource-specific IDs and properties that cause validation errors on redeploy.

![ARM Template V2 Exported](./screenshots/arm-template-v2-exported.png)
![Parameters V2](./screenshots/parameters_v2.json.png)
![Parameters Created](./screenshots/arm-parameters-created.png)

Key modifications applied:
- Removed non-redeployable resource properties
- Parameterized environment-specific values
- Fixed disk references and VM image references
- Cleaned up Key Vault access policies

### 3 — Validation

Before deploying, the template is validated against the Azure API to catch errors without creating resources.

![Validation Passed](./screenshots/ARM-Template-Validation-Passed.png)
![Validation Passed 2](./screenshots/ARM-Template-Validation-Passed2.png)
![Validation Passed Portal](./screenshots/ARM-Template-Validation-Passed-portal.png)
```bash
az deployment group validate \
  --resource-group rg-daniellab-v2 \
  --template-file template_v2.json \
  --parameters parameters_v2.json
```

### 4 — Redeploy

![Deploy Running](./screenshots/arm-template-deploy-v2-running.png)
![Deploy Partial](./screenshots/arm-deploy-partial.png)
![Deploy Troubleshooting](./screenshots/arm-deploy-troubleshooting.png)
![Deploy Final Resources](./screenshots/arm-deploy-final-resources.png)

Resources are redeployed into `rg-daniellab-v2` using the modified template.

### 5 — Resource Verification

![RG V2 Created](./screenshots/rg-v2-created.png)
![VM Created](./screenshots/arm-vm-created.png)
![Disk Before](./screenshots/arm-disk-before.png)
![Disk After](./screenshots/arm-disk-after.png)

### 6 — Key Vault

![Previous KV Purge](./screenshots/arm-previous-kv-purge.png)
![New KV](./screenshots/arm-new-kv.png)
![KV Secret](./screenshots/arm-kv-new.secret.png)
![KV Autorole](./screenshots/arm-kv-autorole.png)

Key Vault requires special handling — soft-delete means the previous vault must be purged before a same-named vault can be redeployed.

### 7 — Cleanup: Delete Original RG

![RG Deleted](./screenshots/rg-daniellab-deleted.png)
![RG Deleting CLI](./screenshots/rg-daniellab-deleting-cli.png)

Original `rg-daniellab` deleted after successful validation of the redeployed environment.

### 8 — Policy Verification

![Policy Working](./screenshots/policy-working-proof.png)

Azure Policy assignments verified as still active after redeployment.

## Verification

| Check | Result |
|---|---|
| Template validation passed | ✅ |
| All resources redeployed in rg-daniellab-v2 | ✅ |
| Key Vault purged and recreated | ✅ |
| Original RG deleted | ✅ |
| Azure Policy still enforced | ✅ |
