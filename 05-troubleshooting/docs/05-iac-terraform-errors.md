# 05 — IaC Terraform Errors

## Overview

Errors encountered during Terraform import and apply of the full daniellab Azure infrastructure. The code was generated via `aztfexport` from an existing resource group and required multiple fixes before a clean `terraform plan` and `terraform apply` could complete successfully.

## Environment

| Tool | Version |
|---|---|
| Terraform | v1.14.7 |
| AzureRM Provider | v4.58.0 |
| OS | Windows (PowerShell) |

---

## Problem 1 — os_managed_disk_id Incompatible

**Error**
```
"os_managed_disk_id" conflicts with source_image_reference, admin_password, admin_username, os_disk
```

**Cause**
`aztfexport` generated `os_managed_disk_id` as an argument in `azurerm_windows_virtual_machine`. This argument is mutually exclusive with `source_image_reference`, `admin_password`, `admin_username` and `os_disk` — making the resource block invalid.

**Fix**
Remove `os_managed_disk_id` entirely from the `azurerm_windows_virtual_machine` block.

![Fix](../screenshots/.gitkeep)

---

## Problem 2 — VM Password Does Not Meet Azure Policy

**Error**
```
"admin_password" has to fulfill 3 out of 4 conditions:
Has lower characters, Has upper characters, Has a digit, Has a special character
```

**Cause**
The exported value `"ignored-as-imported"` does not meet Azure password complexity requirements. Terraform validates this before sending the request to the API.

**Fix**
Replace with a policy-compliant value and add `lifecycle ignore_changes` to prevent Terraform from ever modifying the real VM password:
```hcl
admin_password = "Ignored@Import1!"

lifecycle {
  ignore_changes = [admin_password]
}
```

![Fix](../screenshots/02_fix_lifecycle_ignore_changes_admin_password.png)

---

## Problem 3 — Log Analytics Tables Contaminating State

**Error**
Terraform state contaminated with hundreds of `azurerm_log_analytics_workspace_table_custom_log` resources, causing extremely slow plan refreshes.

**Cause**
`aztfexport` captured all default system tables from the Log Analytics workspace. These are managed by Azure automatically and should not be in Terraform state.

**Fix**
Remove all entries from state and delete the corresponding blocks from `main.tf`:
```powershell
terraform state list | Where-Object {
  $_ -match "azurerm_log_analytics_workspace_table_custom_log"
} | ForEach-Object { terraform state rm $_ }
```

![Fix](../screenshots/05_fix_terraform_state_rm_log_analytics_tables.png)

---

## Problem 4 — Subnet ID Hardcoded in Network Interface

**Error**
```
InvalidResourceReference - subnet not found
```

**Cause**
The exported `subnet_id` was a hardcoded Azure resource ID string instead of a dynamic Terraform reference. Terraform could not resolve the dependency and attempted to create the NIC before the subnet existed.

**Fix**
Replace the hardcoded ID with a direct resource reference:
```hcl
subnet_id = azurerm_subnet.res-10.id
```

---

## Problem 5 — Unclosed Block in Network Interface

**Error**
```
Unclosed configuration block on main.tf line 81
```

**Cause**
When editing the `ip_configuration` block to fix Problem 4, the closing brace `}` was accidentally removed, leaving the block open.

**Fix**
Close the `ip_configuration` block correctly:
```hcl
ip_configuration {
  name                          = "ipconfig1"
  private_ip_address_allocation = "Static"
  private_ip_address            = "10.0.1.4"
  subnet_id                     = azurerm_subnet.res-10.id
}
```

---

## Problem 6 — Private IP Missing on Static NIC

**Error**
```
PrivateIPAddressMissing - Private IP address is required when privateIPAllocationMethod is Static
```

**Cause**
The NIC was configured with `Static` allocation but no explicit IP address was provided. Azure requires a specific IP when allocation method is Static.

**Fix**
Add the explicit private IP address:
```hcl
private_ip_address = "10.0.1.4"
```

![Error](../screenshots/06_error_nic_private_ip_missing.png)
![Fix](../screenshots/06_error_nic_private_ip_missing_fix.png)

---

## Problem 7 — Backup Policies Already Existed in Azure

**Error**
```
Resource already exists - to be managed via Terraform this resource needs to be imported into State
```

**Cause**
Azure automatically creates default backup policies (`DefaultPolicy`, `EnhancedPolicy`, `HourlyLogBackup`) when a Recovery Services Vault is provisioned. These existed in Azure but were not in Terraform state, so Terraform tried to create them again.

**Fix**
Import the three policies into Terraform state:
```powershell
terraform import azurerm_backup_policy_vm.res-689 ".../backupPolicies/DefaultPolicy"
terraform import azurerm_backup_policy_vm.res-690 ".../backupPolicies/EnhancedPolicy"
terraform import azurerm_backup_policy_vm_workload.res-691 ".../backupPolicies/HourlyLogBackup"
```

![Fix](../screenshots/08_fix_terraform_import_backup_policies.png)

---

## Problem 8 — Application Insights Timeout (context canceled)

**Error**
```
Put ".../ai-daniellab?api-version=2020-02-02": context canceled
```

**Cause**
AzureRM provider v4.x requires `workspace_id` for `azurerm_application_insights`. Without it, the Azure API waits indefinitely for a Log Analytics workspace association, causing the request to hang and eventually time out after 20+ minutes.

**Fix**
Add `workspace_id` pointing to the existing Log Analytics workspace:
```hcl
resource "azurerm_application_insights" "res-2" {
  application_type    = "web"
  location            = "francecentral"
  name                = "ai-daniellab"
  resource_group_name = azurerm_resource_group.res-0.name
  sampling_percentage = 0
  workspace_id        = azurerm_log_analytics_workspace.res-12.id
}
```

![Error](../screenshots/03_error_application_insights_context_canceled.png)
![Fix](../screenshots/03_error_application_insights_context_canceled_fix.png)

---

## Final Result

| Check | Result |
|---|---|
| `terraform plan` → No changes | ✅ |
| `terraform apply` → Apply complete | ✅ |
| `terraform destroy` → Destroy complete | ✅ |

![Plan No Changes](../screenshots/10_terraform_plan_no_changes.png)
![Apply](../screenshots/10_terraform_apply.png)
![Destroy](../screenshots/10_terraform_destroy.png)
