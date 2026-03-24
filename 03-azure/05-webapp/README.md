# 05-webapp — App Service & Web Application Migration

## Overview

This section covers the migration of the ASP.NET Core 8 portfolio web application from **IIS on APP01** to **Azure App Service**, including the Key Vault integration for secure database credentials, VNet Integration for private SQL connectivity, and Application Insights for monitoring.

**Migration source:** APP01 — IIS + ASP.NET Core 8 — HTTPS:443
**Migration target:** Azure App Service (B1 Linux) — app-daniellab

## App Service Plan

![App Service Plan Created](./screenshots/appservice-plan-created.png)

| Parameter | Value |
|---|---|
| Name | asp-daniellab |
| SKU | B1 (Basic) |
| OS | Linux |
| Region | francecentral |

## App Service

![App Service Created](./screenshots/appservice-created.png)

| Parameter | Value |
|---|---|
| Name | app-daniellab |
| Runtime | .NET 8 |
| Plan | asp-daniellab (B1) |
| HTTPS only | Enabled |

## Key Vault — Secure Credential Storage

Key Vault stores the SQL Server connection string so it never appears in plain text in App Service configuration or source code.

![Key Vault Created](./screenshots/keyvault-created.png)
![Key Vault Secret Created](./screenshots/keyvault-secret-created.png)
![Key Vault Secret Portal](./screenshots/keyvault-secret-portal.png)
![Key Vault Secret Correct](./screenshots/keyvault-secret-correct.png)
![Key Vault Access Policy](./screenshots/keyvault-access-policy.png)

| Resource | Value |
|---|---|
| Name | kv-daniellab |
| SKU | Standard |
| Secret | ConnectionStrings--DanielDB |
| Value | Server=10.0.1.10;Database=DanielDB;... |
| Access | App Service Managed Identity (get, list) |

## Managed Identity

![Managed Identity Enabled](./screenshots/appservice-managed-identity-enabled.png)
![Managed Identity Portal](./screenshots/appservice-managed-identity-enabled-portal.png)

**System-assigned Managed Identity** enabled on the App Service. The identity is granted `get` and `list` permissions on Key Vault secrets — allowing the application to retrieve the SQL connection string at runtime without any credentials stored in config files or environment variables.

```
App Service (Managed Identity)
    │
    │ get secret
    ▼
Key Vault (kv-daniellab)
    │
    │ returns connection string
    ▼
App Service → connects to vm-sql01:1433
```

## VNet Integration

![VNet Integration](./screenshots/appservice-vnet-integration.png)
![VNet Integration Portal](./screenshots/appservice-vnet-integration-portal.png)
![VNet Integration Capture](./screenshots/appservice-vnet-integratio.png)

App Service integrated with `snet-webapp` (10.0.3.0/24) — enabling outbound connectivity to vm-sql01 on its **private IP 10.0.1.10** without exposing SQL Server to the public internet.

| Setting | Value |
|---|---|
| Integration subnet | snet-webapp (10.0.3.0/24) |
| VNet | vnet-daniellab |
| SQL target | 10.0.1.10:1433 (private) |

## Application Migration — ZIP Deploy

### Why ZIP Deploy Instead of .bak Restore

The original plan was to restore the full application from a Windows Server Backup `.bak`. This was abandoned because:
- App Service runs on Linux — Windows-format backups are incompatible
- The ASP.NET Core 8 app has no OS-level dependencies
- ZIP Deploy is the standard, clean deployment method for App Service

### Step 1 — Prepare Application on APP01

![dotnet Version](./screenshots/app01-dotnet-version.png)
![Packages Added](./screenshots/app01-packages-added.png)
![Program.cs Updated](./screenshots/app01-program-cs-updated.png)
![Publish Updated](./screenshots/app01-publish-updated.png)

Application updated on APP01 to replace the SQL Server Express connection string with the Key Vault reference, and the `publish` profile updated to target Linux runtime.

### Step 2 — Smoke Test On-Premises

![Smoke Test On-Prem](./screenshots/app01-smoke-test-onprem.png)

Application verified working on APP01 with the updated configuration before packaging.

### Step 3 — Create ZIP Package

![ZIP Created](./screenshots/app01-zip-created.png)

Application published to a local folder and zipped with all runtime dependencies included.

### Step 4 — Upload to Storage via AzCopy

![AzCopy Download on APP01](./screenshots/app01-azcopy-download.png)
![AzCopy Upload](./screenshots/app01-azcopy-upload.png)
![JSON Uploaded](./screenshots/app01-json-uploaded.png)
![ZIP Uploaded](./screenshots/app01-zip-uploaded.png)

AzCopy used to upload the ZIP package and supporting files to the Azure Storage Account. This also served as the transfer path for the database JSON export files used in `04-sql-vm`.

### Step 5 — Deploy ZIP to App Service

![Deploy ZIP Downloaded](./screenshots/deploy-zip-downloaded.png)
![Deploy Completed](./screenshots/appservice-deploy-completed.png)
![Deploy Success](./screenshots/appservice-deploy-success.png)

ZIP package deployed to App Service via Kudu ZIP Deploy API.

## Logging & Diagnostics

![Stdout Enabled](./screenshots/appservice-stdout-enabled.png)
![Logs Named Pipes](./screenshots/appservice-logs-namedpipes.png)

stdout logging enabled on App Service to capture application startup errors. Named pipes log entry confirmed ASP.NET Core runtime initialised correctly on Linux.

## Backup

![Backup Configured](./screenshots/appservice-backup-configured.png)

App Service backup configured to the Storage Account — covers the deployed application files.

## Application Insights

![App Insights Created](./screenshots/appinsights-created.png)
![App Insights Connected](./screenshots/appinsights-connected-appservice.png)
![App Insights Dashboard](./screenshots/appinsights-dashboard.png)

Application Insights connected to the App Service for live metrics, request tracking and failure detection. Documented in detail in `03-azure/07-security`.

## Verification

![Web Running](./screenshots/appservice-web-running.png)
![Web Running Final](./screenshots/appservice-web-running-final.png)

Portfolio web application running on App Service — serving the same content as on APP01 on-premises, with data read from DanielDB on vm-sql01 via VNet Integration.

## Architecture Summary

```
Browser (HTTPS)
    │
    ▼
App Service (app-daniellab — Linux B1)
    │
    ├─── Key Vault (kv-daniellab)
    │         Managed Identity → get ConnectionStrings--DanielDB
    │
    └─── VNet Integration (snet-webapp)
              │
              ▼
         vm-sql01 — 10.0.1.10:1433
              │
              ▼
         SQL Server Developer 2022 — DanielDB
```
