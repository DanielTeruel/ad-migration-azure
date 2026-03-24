# 04-bastion — Azure Bastion

## Overview

Azure Bastion provides secure RDP access to **vm-sql01** directly from the Azure Portal browser — without exposing port 3389 on the NSG, without a public IP on the VM and without installing any client software. It is the only remote access method used for the Azure VM in this lab.

Bastion is deployed via **Azure CLI** with the **Developer SKU**, linked to the existing VNet `vnet-daniellab`.

**Target VM:** vm-sql01 (Windows Server 2022, private IP 10.0.1.10)

## Tier Selected — Developer

| Tier | Public IP | Dedicated Subnet | Cost | Access Method |
|---|---|---|---|---|
| **Developer** ✅ | Optional | Optional | Free | Azure Portal only |
| Basic | Yes (Standard) | AzureBastionSubnet /27 min | ~0.19€/h | Portal + native client |
| Standard | Yes (Standard) | AzureBastionSubnet /27 min | ~0.35€/h | All options |

Developer tier chosen — zero cost, sufficient for administrative access to vm-sql01 via portal.

## Why Not Open RDP on the NSG?

| Approach | Port 3389 Exposed | Public IP on VM | Risk |
|---|---|---|---|
| Direct RDP | Yes | Yes | Brute-force exposure |
| NSG + IP restriction | Yes (restricted) | Yes | Still a surface |
| **Azure Bastion** ✅ | **No** | **No** | None |

RDP traffic flows encrypted over HTTPS through the Azure backbone — it never touches the public internet and port 3389 is never opened on the NSG.

## Deployment — Azure CLI

### Step 1 — Create AzureBastionSubnet

![Bastion Subnet Created](./screenshots/bastion-subnet-created.png)

```bash
az network vnet subnet create \
  --name AzureBastionSubnet \
  --resource-group rg-daniellab \
  --vnet-name vnet-daniellab \
  --address-prefix 10.0.2.0/26
```

| Parameter | Value |
|---|---|
| Subnet name | AzureBastionSubnet |
| Address prefix | 10.0.2.0/26 |
| VNet | vnet-daniellab |
| Resource Group | rg-daniellab |

> **Note:** The subnet name must be exactly `AzureBastionSubnet` — Azure enforces this name for all Bastion deployments regardless of tier.

### Step 2 — Create Public IP

![Bastion PIP Created](./screenshots/bastion-pip-created.png)

```bash
az network public-ip create \
  --resource-group rg-daniellab \
  --name pip-bastion \
  --sku Standard \
  --location francecentral
```

| Parameter | Value |
|---|---|
| Name | pip-bastion |
| SKU | Standard |
| Allocation | Static |
| IP Address | 51.103.109.61 |
| Location | francecentral |

### Step 3 — Create Bastion Host

![Bastion Created](./screenshots/bastion-created.png)

```bash
az network bastion create \
  --name bastion-daniellab \
  --resource-group rg-daniellab \
  --vnet-name vnet-daniellab \
  --location francecentral \
  --sku Developer
```

| Parameter | Value |
|---|---|
| Name | bastion-daniellab |
| SKU | Developer |
| VNet | vnet-daniellab |
| Resource Group | rg-daniellab |
| Location | francecentral |
| Provisioning State | Succeeded |
| DNS Name | omnibrain.francecentral.bastionglobal.azure.com |

> The CLI required installing the `bastion` extension on first run — accepted interactively with `y`. To avoid the prompt in future runs: `az config set extension.use_dynamic_install=yes_without_prompt`

## Network Configuration Summary

| Resource | Value | Notes |
|---|---|---|
| VNet | vnet-daniellab | Shared with vm-sql01 |
| AzureBastionSubnet | 10.0.2.0/26 | Created via CLI |
| Public IP | pip-bastion — 51.103.109.61 | Standard SKU, Static |
| vm-sql01 public IP | None | No public IP on the VM |
| NSG rule for RDP | None | Port 3389 never opened |

## Verification

![Bastion Portal Verified](./screenshots/bastion-portal-verified.png)

Access flow — **Azure Portal → vm-sql01 → Connect → Bastion**:

```
Browser (HTTPS:443)
    │
    ▼
Azure Portal
    │
    │ Bastion Developer tier (Azure backbone)
    ▼
vm-sql01 — private IP 10.0.1.10
    │
    ▼
Windows Server 2022 desktop in browser tab
```

Full RDP session established inside the browser — no client install, no public IP on the VM, port 3389 never opened on the NSG.
