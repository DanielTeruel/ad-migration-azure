# 05-intune — Modern Device Management (MDM)

## Overview

**WS001** is already Hybrid Azure AD Joined to both `daniel.local` and Entra ID. This phase adds the **MDM layer** on top of the existing join — enrolling WS001 into Microsoft Intune without breaking the on-premises domain membership.

Once enrolled, Intune replaces GPO-based device configuration for cloud-managed policies: compliance rules, security baselines, and application deployment.

## Machine

| Machine | OS | IP | Domain | MDM Status |
|---|---|---|---|---|
| WS001 | Windows 10 | 192.168.75.7 | daniel.local | Intune Enrolled ✅ |

## How Intune Enrollment Works
```
WS001 (Windows 10)
    │
    ├─ Domain joined ──────────────► AD DS on DC01 (daniel.local)
    │                                      │
    │                                      │ Entra Connect sync
    │                                      ▼
    ├─ Hybrid Azure AD joined ────► Entra ID (cloud)
    │                                      │
    │                                      │ MDM enrollment
    │                                      ▼
    └─ MDM enrolled ───────────────► Microsoft Intune
                                           │
                                           ├─ Compliance policies
                                           ├─ Configuration profiles
                                           └─ App deployment
```

The device maintains both identities simultaneously — on-prem GPOs still apply via AD DS, while Intune policies layer on top through the MDM channel.

## Prerequisites

| Requirement | Status |
|---|---|
| WS001 Hybrid Azure AD Joined | ✅ (02-azure-migrate/03-hybrid-join) |
| Intune license assigned to admin user | ✅ |
| Company Portal installed on WS001 | ✅ |
| WS001 reachable and logged in | ✅ |

## Limitations

| Limitation | Root Cause | Workaround Applied |
|---|---|---|
| Auto-enrollment blocked | Requires Entra ID P1 — not included in Azure for Students | Manual enrollment via Company Portal |
| Wallpaper Configuration Profile bugged | Known portal issue at time of lab | Replaced with Interactive Logon Message policy |

Auto-enrollment via MDM scope in Entra ID (`Mobility → Microsoft Intune`) requires an **Entra ID P1** license. In a production environment with the appropriate licensing, WS001 would enroll automatically on domain logon with no user interaction required.

---

## Step 1 — MDM Enrollment via Company Portal

Since auto-enrollment requires Entra ID P1, enrollment was performed manually through the **Company Portal** application installed on WS001.

![Company Portal Inicio](./screenshots/01_company_portal_inicio.png)

Company Portal opens and detects the tenant `DANIELLABTENANT`. The device is not yet configured for corporate management.

![Company Portal MDM Enrolled](./screenshots/03_company_portal_mdm_enrolled.png)

After completing the enrollment flow, **Settings → Accounts → Access work or school** shows two simultaneous connections:
```
Access work or school:
├─ Connected to DanielLabTenant MDM   (Intune)     ✅
└─ Connected to AD DANIEL domain      (on-prem)    ✅
```

Both connections coexist — the domain join is fully preserved.

![Intune Devices WS001](./screenshots/05_intune_devices_ws001_enrolled.png)

WS001 appears in **Intune → Devices → All devices**, confirming successful enrollment.

---

## Step 2 — Compliance Policy

A compliance policy defines the minimum security requirements WS001 must meet to be considered trusted by the organization. Non-compliant devices can be blocked from accessing corporate resources via Conditional Access.

**Policy name:** `compliance-ws001-daniellab`  
**Platform:** Windows 10 and later

### Rules Configured

| Rule | Value |
|---|---|
| Firewall | Required |
| Antivirus | Required |
| Minimum OS version | 10.0.19041 |

![Compliance Policy Config](./screenshots/06_intune_compliance_policy_config.png)
![Compliance Policy Config 2](./screenshots/06_intune_compliance_policy_config2.png)
![Compliance Policy Config 0](./screenshots/06_intune_compliance_policy_config0.png)

### Assignment

![Compliance Policy Assignment](./screenshots/07_intune_compliance_policy_assignment.png)
![Compliance Policy Assignment Portal](./screenshots/07_intune_compliance_policy_assignment_show_portal.png)
![Compliance Policy Confirmation](./screenshots/07_intune_compliance_policy_confirmation.png)

The policy is assigned to the group containing WS001. After Intune evaluates the device:

![Device Compliant](./screenshots/10_intune_device_ws001_compliant.png)

| Check | Result |
|---|---|
| Firewall active | ✅ |
| Antivirus active | ✅ |
| OS version ≥ 10.0.19041 | ✅ |
| **Overall compliance state** | **Compliant 🟢** |

---

## Step 3 — Configuration Profile (Interactive Logon Message)

Configuration profiles push settings directly to managed devices, replacing the equivalent on-prem GPO. This profile configures a **legal notice** displayed to users before login — a direct cloud equivalent of the on-prem GPO setting `Interactive logon: Message text for users attempting to log on`.

**Profile name:** `cfg-interactive-logon-daniellab`  
**Type:** Settings Catalog  
**Platform:** Windows 10 and later

### Settings Applied

| Setting | Value |
|---|---|
| Interactive Logon Message Title | Aviso Legal – DanielLabTenant |
| Interactive Logon Message Text | Este equipo es propiedad de la organización... |

![Config Profile Interactive Logon](./screenshots/08_intune_config_policy interactive logon.png)
![Config Profile All Devices](./screenshots/08_intune_config_policy interactive logon all devicves.png)
![Config Profile Final](./screenshots/08_intune_config_policy interactive logon final.png)

### Verification on WS001

![WS001 Legal Notice](./screenshots/ws001-intune-legal-notice-check.png)

The message appears on WS001 at the login screen, confirming the profile was received and applied by the Intune MDM agent.

---

## Step 4 — Microsoft 365 Apps Deployment

Microsoft 365 Apps (Word, Excel, PowerPoint, Teams) deployed to WS001 via Intune app deployment — no manual installation or SCCM required.

![M365 Config 1](./screenshots/intune-m365-apps-config1.png)
![M365 Config 2](./screenshots/intune-m365-apps-config2.png)
![M365 Config 3](./screenshots/intune-m365-apps-config3.png)
![M365 Config 4](./screenshots/intune-m365-apps-config4.png)
![M365 Config 5](./screenshots/intune-m365-apps-config5.png)
![M365 Config Final](./screenshots/intune-m365-apps-configfinal.png)
![M365 Installing](./screenshots/intune-m365-apps-task manager installing.png)

| App | Deployed via | Status |
|---|---|---|
| Microsoft Word | Intune App Deployment | ✅ |
| Microsoft Excel | Intune App Deployment | ✅ |
| Microsoft PowerPoint | Intune App Deployment | ✅ |
| Microsoft Teams | Intune App Deployment | ✅ |

---

## Final Verification

| Check | Result |
|---|---|
| WS001 visible in Intune → Devices | ✅ |
| MDM + Domain join coexisting | ✅ |
| Compliance state | Compliant 🟢 |
| Interactive Logon Message applied | ✅ |
| M365 Apps deployed | ✅ |
| On-prem GPOs still applying | ✅ |

## What Intune Enrollment Enables

| Capability | Requires Intune Enrollment |
|---|---|
| Cloud-based compliance evaluation | ✅ |
| Configuration profiles as GPO replacement | ✅ |
| App deployment without SCCM | ✅ |
| Remote device actions (wipe, retire, sync) | ✅ |
| Integration with Conditional Access | ✅ |
| Unified device management across on-prem and cloud | ✅ |
