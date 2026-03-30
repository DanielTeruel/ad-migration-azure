# CI/CD — GitHub Actions + Azure App Service

## Overview

This section implements a full CI/CD pipeline using **GitHub Actions** to automatically deploy the ASP.NET Core 8 portfolio web application to Azure App Service on every `git push` to `main`.

This is the final piece of the IaC phase — infrastructure is provisioned by Bicep, and the application is deployed and kept up to date by the pipeline. No manual portal interaction after initial setup.

> **Context:** This phase uses a fresh environment provisioned by the Bicep template (`04-iac/bicep/`), which is why resource names include a deployment suffix (e.g. `app-daniellab-2603`). The SQL VM in this phase runs **SQL Server 2025 Express** — reinstalled to match the original on-premises version after a version incompatibility with the `.bak` restore format from SQL 2022.

## Architecture

```
Developer (local)
    │
    │  git push → main
    ▼
GitHub Repository
    │
    │  GitHub Actions triggered
    ▼
Build & Publish (.NET 8)
    │
    │  Deploy via Publish Profile
    ▼
Azure App Service (Linux · B1)
    │
    │  VNet Integration (snet-appservice · 10.0.3.0/24)
    ▼
vm-sql01 — SQL Server 2025 Express (10.0.1.10)
    │
    │  TCP 1433 (private IP — never public)
    ▼
DanielDB (Proyectos + Certificaciones)
```

## Stack

| Component | Technology |
|---|---|
| Web application | ASP.NET Core 8 |
| Database | SQL Server 2025 Express on Azure VM |
| Hosting | Azure App Service (Linux, B1) |
| CI/CD | GitHub Actions |
| Networking | Azure VNet Integration |
| Secrets | App Service Connection String |

---

## Steps

### 1 — Push code to GitHub

![Git Push Portfolio](./screenshots/01_git_push_portfolio.png)

```powershell
git init
git add .
git commit -m "feat: initial portfolio upload"
git branch -M main
git remote add origin https://github.com/DanielTeruel/daniel-portfolio-web.git
git push -u origin main
```

No secrets or credentials in the codebase — the connection string is read from the App Service environment variable `SQLCONNSTR_DanielDB` at runtime.

### 2 — Obtain Publish Profile

![Publish Profile Output](./screenshots/02_publish_profile_output.png)

```powershell
az webapp deployment list-publishing-profiles `
  --name app-daniellab-2603 `
  --resource-group rg-daniellab-v3 `
  --xml
```

The XML output contains the deployment credentials used by GitHub Actions to authenticate against the App Service.

### 3 — Configure GitHub Secret

![GitHub Secret Created](./screenshots/03_github_secret_created.png)

```
Repository → Settings → Secrets and variables → Actions → New repository secret

Name:  AZURE_WEBAPP_PUBLISH_PROFILE
Value: <XML from previous step>
```

The secret name must match exactly what is referenced in the workflow file.

### 4 — VNet Integration

![VNet Integration](./screenshots/04_vnet_integration.png)

```powershell
az network vnet subnet create `
  --resource-group rg-daniellab-v3 `
  --vnet-name vnet-daniellab-2603 `
  --name snet-appservice `
  --address-prefix 10.0.3.0/24

az webapp vnet-integration add `
  --name app-daniellab-2603 `
  --resource-group rg-daniellab-v3 `
  --vnet vnet-daniellab-2603 `
  --subnet snet-appservice
```

A dedicated subnet is required — App Service VNet Integration cannot share the subnet used by the VM. This allows the App Service to reach the VM's private IP (`10.0.1.10`) over port 1433 without any public exposure.

### 5 — SQL Server 2025 on VM

![SQL Installed](./screenshots/05_sql_installed.png)

SQL Server 2025 Express reinstalled on `vm-sql01` to resolve a `.bak` format incompatibility — the backup generated from the on-premises SQL 2025 instance could not be restored to SQL 2022 Developer (used in Phase 5). Mixed Mode authentication and fixed port 1433 configured.

### 6 — GitHub Actions Workflow

![Workflow Updated](./screenshots/06_workflow_yml_updated.png)

```yaml
name: Deploy to Azure App Service

on:
  push:
    branches: [main]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4.2.2

      - name: Setup .NET
        uses: actions/setup-dotnet@v4.3.1
        with:
          dotnet-version: '8.0.x'

      - name: Build
        run: dotnet build --configuration Release

      - name: Publish
        run: dotnet publish --configuration Release --output ./publish

      - name: Deploy to Azure App Service
        uses: azure/webapps-deploy@v3.0.2
        with:
          app-name: app-daniellab-2603
          publish-profile: ${{ secrets.AZURE_WEBAPP_PUBLISH_PROFILE }}
          package: ./publish
```

### 7 — Pipeline Success

![GitHub Actions Success](./screenshots/09_github_actions_success.png)

Pipeline running end-to-end in under 3 minutes:

| Stage | Duration |
|---|---|
| Checkout | ~5s |
| Setup .NET | ~15s |
| Build | ~20s |
| Publish | ~15s |
| Deploy | ~60s |
| **Total** | **~2 min** |

### 8 — Portfolio Live

![Webpage Projects](./screenshots/11_webpage_projects.png)

- **URL:** https://app-daniellab-2603.azurewebsites.net
- **Runtime:** DOTNETCORE 8.0
- **Data source:** DanielDB via VNet Integration (private IP 10.0.1.10)

---

## Pipeline Run History

![GitHub Actions History](./screenshots/12_github_actions_history.png)

The full run history shows the real iteration process — initial failures, fixes, and final stable state. This is the expected workflow when setting up CI/CD for the first time.

| Run | Commit | Result |
|---|---|---|
| #1 | ci: add GitHub Actions deploy workflow | ❌ Wrong app-name |
| #2 | fix: correct app service name and update action versions | ✅ |
| #3 | Update Program.cs | ❌ Container timeout |
| #4 | Update appsettings.json | ❌ Container timeout |
| #5 | ci: redeploy to new app service | ✅ |
| #6 | Update Program.cs | ✅ Lazy SQL connection |
| #7 | fix: remove unused Azure KeyVault packages | ✅ |
| #8 | fix: downgrade SqlClient to 5.2.2 for Linux compatibility | ✅ |
| #9 | docs: add README | ✅ |

---

## Issues & Fixes

| Issue | Cause | Fix |
|---|---|---|
| Wrong app-name in workflow | Bicep adds suffix to resource names | Updated to `app-daniellab-2603` |
| Container timeout on startup | SQL connection blocking app startup | Moved connection inside endpoint handler (lazy init) |
| SQL login failed | `sqladmin` existed only as Windows login | Created SQL login with password + db_owner role |
| SQLEXPRESS dynamic port | Express uses random port by default | Fixed port to 1433 via registry + service restart |
| BAK incompatible (SQL 2025 → 2022) | BAK format version mismatch | Reinstalled SQL 2025 Express on VM |
| SqlClient crash on Linux | v6.x incompatible with Linux App Service | Downgraded to v5.2.2 |

Full details in [05-troubleshooting/docs/06-cicd-errors.md](../../05-troubleshooting/docs/06-cicd-errors.md).

---

## Key Decisions

**Why App Service Connection String instead of Key Vault?**
The connection string is stored as an App Service Connection String and exposed as `SQLCONNSTR_DanielDB` at runtime. The Bicep template already provisions Key Vault and Managed Identity — in production, that would be the correct path. For this lab, the connection string approach was chosen to isolate CI/CD troubleshooting from identity troubleshooting.

**Why lazy SQL connection?**
The SQL connection is opened inside the endpoint handler rather than at startup. This prevents container timeout during cold starts on the Linux B1 plan — the app starts and passes the health check before attempting the database connection.

**Why a dedicated subnet for App Service?**
Azure VNet Integration requires a subnet delegated exclusively to the App Service. It cannot share the subnet used by the VM.

**Why reinstall SQL 2025 instead of keeping SQL 2022?**
The original on-premises instance ran SQL 2025 Express. The `.bak` backup format is not backward compatible — a SQL 2025 backup cannot be restored to SQL 2022. Rather than re-exporting via JSON again, SQL 2025 was reinstalled on the VM to keep the restore path clean.
