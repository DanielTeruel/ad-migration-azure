# 01 — Hybrid Identity Errors

## Overview

Errors encountered during Entra Connect synchronization setup and Hybrid Azure AD Join configuration for WS001.

---

## Problem 1 — WS001 Not Registering in Entra ID

**Symptom**
```
dsregcmd /status → AzureAdJoined: NO
error_missing_device → GUID not found in Azure
```

**Cause**
The `Workstations` OU was excluded from the Entra Connect synchronization scope. Computer objects in that OU were never synced to Entra ID, so the device registration had no identity to bind to.

**Fix**
1. Open Entra Connect → **OU Filtering**
2. Mark the `Workstations` OU as included ✅
3. Run a delta sync:
```powershell
Start-ADSyncSyncCycle -PolicyType Delta
```
4. Force device registration on WS001:
```cmd
dsregcmd /join
```
5. Verify:
```
AzureAdJoined: YES
```

**Lesson**
Verify which OUs are included in Entra Connect scope **before** configuring Hybrid Azure AD Join. Computer objects must be synced for device registration to succeed.

---

## Final Result

| Check | Result |
|---|---|
| WS001 AzureAdJoined | YES ✅ |
| WS001 DomainJoined | YES ✅ |
| DeviceAuthStatus | SUCCESS ✅ |
