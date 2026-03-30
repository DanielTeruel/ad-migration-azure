![IAC](./screenshots/banner.png)

![Status](https://img.shields.io/badge/Status-Complete-green)
![ARM](https://img.shields.io/badge/ARM-Template-orange)
![Bicep](https://img.shields.io/badge/IaC-Bicep-0078D4?logo=microsoft)
![Terraform](https://img.shields.io/badge/IaC-Terraform-7B42BC?logo=terraform)
![CI/CD](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-black?logo=github)

# 04 — Infrastructure as Code

## Overview

This section covers the full **Infrastructure as Code** implementation for the daniellab project. The entire Azure infrastructure is defined, versioned, and deployable from code — eliminating manual portal clicks and enabling repeatable, auditable deployments.

Three approaches are covered in sequence, each building on the previous:

1. **ARM Template** — export the existing infrastructure to understand what Azure deployed, modify it, and redeploy as a validation exercise
2. **Terraform** — rewrite the full infrastructure from scratch in HCL, managing state, handling import of existing resources, and tearing down and recreating the environment
3. **Bicep** — rewrite the infrastructure using Azure-native IaC, deploying App Service, Key Vault, and vm-sql01 from a single `main.bicep`
4. **GitHub Actions** — automate application deployment to App Service on every `git push`, completing the full CI/CD loop

## Structure

```
04-iac/
├── arm/          # ARM Template — export, modify, redeploy
├── bicep/        # Bicep — Azure-native IaC from scratch
├── terraform/    # Terraform — HCL from scratch, state management
└── cicd/         # GitHub Actions — CI/CD workflow for App Service
```

## IaC Approaches

| Tool | Language | Scope | State |
|---|---|---|---|
| ARM Template | JSON | Full environment export + redeploy | Stateless |
| Bicep | Bicep DSL | VNet, App Service, Key Vault, vm-sql01 | Stateless |
| Terraform | HCL | Full environment from scratch | State file (azurerm backend) |
| GitHub Actions | YAML | App Service deploy on git push | — |

## Design Decisions

**Why ARM Template first?**
The export served as a full infrastructure snapshot and a way to understand what Azure had actually deployed under the hood. It also provided a concrete reference when rewriting from scratch in Bicep and Terraform. Starting from an export, then rewriting from scratch, demonstrates both the output and the understanding behind it.

**Why Bicep and not only Terraform?**
Bicep is Azure-native — no state file to manage, tight ARM integration, and strong typing. It is the right choice when the infrastructure scope is Azure-only. Terraform was implemented alongside it to demonstrate multi-cloud portability and familiarity with the broader IaC ecosystem.

**Why GitHub Actions for CI/CD?**
ZIP Deploy (used in Phase 6) was done first to understand the manual deployment flow end-to-end. GitHub Actions automates that same flow — on every `git push`, the workflow builds, tests, and deploys the ASP.NET Core app to App Service in 3–5 minutes.

## What This Enables

| Capability | Result |
|---|---|
| Full infrastructure reproducible from code | ✅ |
| Version-controlled infrastructure via git | ✅ |
| Destroy and recreate in minutes | ✅ |
| Auditable change history | ✅ |
| Multi-cloud portability (Terraform) | ✅ |
| Automated application deploys on push | ✅ |
| $0.00/day when not in use | ✅ |

## Documentation

| Folder | Contents |
|---|---|
| [arm](./arm/) | ARM Template export, modification, validation, redeploy |
| [bicep](./bicep/) | Bicep deployment from scratch — Azure-native IaC |
| [terraform](./terraform/) | Terraform from scratch — HCL, state management, import, destroy |
| [cicd](./cicd/) | GitHub Actions workflow — build, test, deploy to App Service |

## Status

- [x] ARM Template — exported, modified, validated, redeployed
- [x] Bicep — full infrastructure deployed from main.bicep
- [x] Terraform — full infrastructure from scratch, apply and destroy verified
- [x] GitHub Actions — CI/CD pipeline live, automated deploy on git push
