# 04 — IaC ARM Template Errors

## Overview

Errors encountered during ARM template export, modification and redeployment of the full daniellab Azure infrastructure. The template was exported from the existing resource group and required multiple fixes before a clean deployment could complete successfully.

## Environment

| Tool | Version |
|---|---|
| ARM Template | JSON |
| Azure CLI | latest |
| Region | francecentral |

---

## Problem 1 — Invalid API Version for Web/Serverfarms and Web/Sites

**Error**
```
InvalidRestApiParameter – properties parameter is invalid
```

**Cause**
The exported template used `apiVersion: "2024-11-01"` for `Microsoft.Web/*` resources. This API version does not exist in any Azure region at the time of deployment.

**Affected Resources**
- `Microsoft.Web/serverfarms`
- `Microsoft.Web/sites`

**Fix**
Downgrade the API version to a stable release:
```json
// Before
"apiVersion": "2024-11-01"

// After
"apiVersion": "2024-04-01"
```

---

## Problem 2 — Recent Network API Version Unavailable in Region

**Error**
```
InvalidTemplateDeployment / PreflightTemplateFailed
```

**Cause**
API version `"2024-07-01"` was unstable or not yet available in `francecentral` for network resources at the time of deployment.

**Affected Resources**
- `Microsoft.Network/networkSecurityGroups`
- `Microsoft.Network/virtualNetworks`
- `Microsoft.Network/publicIPAddresses`
- `Microsoft.Network/networkInterfaces`

**Fix**
Use `"2024-05-01"` as the consolidated stable version for all network resources:
```json
// Before
"apiVersion": "2024-07-01"

// After
"apiVersion": "2024-05-01"
```

---

## Problem 3 — Linux Web App Missing linuxFxVersion

**Error**
```
InvalidRestApiParameter – properties parameter is invalid
```

**Cause**
Resources with `kind: "app,linux"` require `siteConfig.linuxFxVersion` mandatorily. Without it, the ARM preflight rejects the request before deployment begins.

**Fix**
Add the required fields inside `properties.siteConfig`:
```json
"siteConfig": {
  "linuxFxVersion": "DOTNETCORE|8.0",
  "reserved": true,
  "httpsOnly": true
}
```

---

## Problem 4 — Incomplete SKU Block in Web/Serverfarms

**Error**
```
InvalidRestApiParameter – properties parameter is invalid
```

**Cause**
The exported `sku` block only contained `name`. The API requires `tier`, `size`, `family` and `capacity` for Linux App Service Plans.

**Fix**
Complete the `sku` block with all required fields:
```json
// Before
"sku": { "name": "B1" }

// After
"sku": {
  "name": "B1",
  "tier": "Basic",
  "size": "B1",
  "family": "B",
  "capacity": 1
}
```

---

## Problem 5 — NIC Deployed Before VNet (Broken Dependency)

**Error**
```
Subnet not found when creating networkInterface
```

**Cause**
The NIC referenced the subnet via `concat()` but had no explicit `dependsOn` on the VNet. ARM attempted to create the NIC in parallel before the VNet was ready.

**Fix**
Add explicit `dependsOn` in the `networkInterfaces` resource:
```json
"dependsOn": [
  "[resourceId('Microsoft.Network/virtualNetworks', variables('vnetName'))]"
]
```

---

## Problem 6 — Key Vault in Soft-Delete State Conflicts on Redeploy

**Error**
```
ConflictError – Vault already exists in deleted state
```

**Cause**
Azure retains deleted Key Vaults for 90 days in soft-delete state. If the same name is reused (same suffix), the ARM deployment fails because the name is still reserved even though the vault no longer appears in the resource group.

**Symptom**
Deployment fails only on the KeyVault resource while all other resources are created correctly.

**Fix A — Purge the existing soft-deleted vault before redeploying:**
```powershell
Remove-AzKeyVault -VaultName "kv-daniellab-XXXX" `
  -Location "francecentral" -InRemovedState -Force
```

![KV Purge](../screenshots/arm-previous-kv-purge.png)
![KV New](../screenshots/arm-new-kv.png)

**Fix B — Force a different suffix so ARM generates a new vault name:**
```powershell
-resourceNameSuffix "2601"   # different value from the previous deployment
```

**Fix C — Disable soft-delete for lab environments (not recommended for production):**
```json
"enableSoftDelete": false,
"enablePurgeProtection": false
```

> **Note:** The suffix in this template uses only the first 4 characters of `resourceNameSuffix` via `take(...,4)`. Identical suffixes within the same time interval will generate the same Key Vault name and cause a collision.

---

## Problem 7 — Bastion Developer Tier Does Not Support Public IP

**Cause**
The Developer tier of Azure Bastion does not support a dedicated public IP or require a dedicated `AzureBastionSubnet`. It connects directly to the VNet. Assigning a `publicIPAddress` causes a preflight validation error.

| Tier | Cost | Public IP | Access |
|---|---|---|---|
| Developer | Free | ❌ Not supported | Portal only |
| Basic | ~0.19€/hr | ✅ Required | Full |

**Fix**
Use only `virtualNetwork.id` in properties and remove `publicIPAddress` from the `bastionHosts` resource:
```json
"sku": { "name": "Developer" },
"properties": {
  "virtualNetwork": {
    "id": "[resourceId('Microsoft.Network/virtualNetworks', variables('vnetName'))]"
  }
}
```

> **Note:** The `AzureBastionSubnet` is kept in the VNet definition for future compatibility — upgrading to Basic tier will not require changes to the network definition.

---

## Final Result

| Check | Result |
|---|---|
| ARM Template validation passed | ✅ |
| All resources deployed in rg-daniellab-v2 | ✅ |
| Key Vault purged and recreated | ✅ |
| App Service running on Linux with .NET 8 | ✅ |
| Bastion Developer tier connected | ✅ |

![Validation Passed](../screenshots/ARM-Template-Validation-Passed.png)
![Deploy Final](../screenshots/arm-deploy-final-resources.png)
