# 02 — SQL VM Errors

## Overview

Errors encountered during SQL Server VM provisioning, database migration and backup configuration.

---

## Problem 1 — VM SKU Not Available in Region

**Symptom**
```
SkuNotAvailable in francecentral
```

**Cause**
The initially selected VM size was not available in the target region and availability zone combination. `Standard_D2s_v3` is only available in zone 2 in `francecentral`.

**Fix**
Verify SKU availability before deploying:
```bash
az vm list-skus --location francecentral --size Standard_D --output table
```
Select a SKU and zone combination confirmed as available.

**Lesson**
Always check SKU availability per zone before planning a VM deployment.

---

## Problem 2 — SQL Backup Incompatible Between Versions

**Symptom**
```
RESTORE cannot restore a backup from a higher SQL version to a lower version
```

**Cause**
Source machine (APP01) had SQL Server 2025 (v17). Target VM had SQL Server 2022 (v16). Native `.bak` restore does not support restoring from a higher version to a lower version.

**Fix**
Export data via JSON using `sqlcmd` with `FOR JSON AUTO`, then import on the target using PowerShell:
```powershell
Invoke-Sqlcmd -Query "SELECT * FROM Table FOR JSON AUTO" | Out-File data.json
```

**Lesson**
In real migrations, verify source and destination SQL Server versions before planning the migration method.

---

## Problem 3 — sqlcmd Exporting SSL Errors Instead of Data

**Symptom**
JSON output file contained SSL error messages instead of actual data.

**Cause**
Missing `-C` parameter in `sqlcmd`. SQL Server 2025 requires explicit certificate trust for local connections.

**Fix**
Add the `-C` (Trust Server Certificate) parameter:
```bash
sqlcmd -S localhost -d DanielDB -C -Q "SELECT * FROM Table FOR JSON AUTO"
```

**Lesson**
SQL Server 2025 requires `-C` for local connections without a properly configured SSL certificate.

---

## Problem 4 — Azure Backup Not Finding vm-sql01 in Portal

**Symptom**
Portal did not show `vm-sql01` when running SQL workload discovery.

**Cause**
The VM was registered via CLI using `AzureWorkload` but the portal was searching with `AzureIaasVM` — two different registration types that are not interchangeable.

**Fix**
1. Unregister via CLI
2. Re-register directly from the portal
3. Run discovery by selecting `vm-sql01` manually from the portal UI

**Lesson**
For SQL Backup on Azure VMs, always use the portal for the initial registration. CLI registration with `AzureWorkload` can conflict with portal-based SQL discovery.

---

## Final Result

| Check | Result |
|---|---|
| VM deployed in francecentral zone 2 | ✅ |
| DanielDB migrated via JSON export/import | ✅ |
| SQL Backup configured and first backup completed | ✅ |
