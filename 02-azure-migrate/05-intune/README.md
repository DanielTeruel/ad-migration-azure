# 05 – Intune (Modern Device Management)

## Objetivo

Enrollar WS001 en Microsoft Intune y aplicar políticas de gestión moderna como
sustitución parcial de GPOs on-prem, completando así la migración de WS001 a
gestión cloud.

---

## Contexto

WS001 ya tenía Hybrid Azure AD Join completado en la fase anterior (03-hybrid-join).
Esta fase añade la capa MDM (Mobile Device Management) sobre el dispositivo ya unido,
sin romper el dominio on-prem existente.

---

## Limitaciones encontradas

| Limitación | Causa | Solución aplicada |
|---|---|---|
| Auto-enrollment MDM bloqueado | Requiere Entra ID P1 (no incluido en Azure for Students) | Enrollment manual via Company Portal |
| Configuration Profile - Wallpaper bugueado | Bug conocido en el portal de Intune | Sustituido por Interactive Logon Message |

---

## Pasos realizados

### 1. Enrollment MDM via Company Portal

WS001 ya estaba Hybrid Joined. El auto-enrollment MDM requiere licencia Entra ID P1,
no disponible en Azure for Students. Se optó por enrollment manual:

1. Instalar **Company Portal** desde Microsoft Store en WS001
2. Abrir Company Portal → iniciar sesión con cuenta Entra ID
3. Seleccionar **"Este dispositivo no está configurado para uso corporativo"**
4. Completar el flujo de enrollment

**Resultado:** WS001 aparece en Intune con estado enrolled y gestionado por MDM.
```
Obtener acceso a trabajo o escuela:
├─ Conectado a DanielLabTenant MDM  ✅
└─ Conectado al dominio de AD DANIEL ✅
```

---

### 2. Compliance Policy

**Nombre:** `compliance-ws001-daniellab`
**Plataforma:** Windows 10 and later

Reglas configuradas:

| Regla | Valor |
|---|---|
| Firewall | Requerido |
| Antivirus | Requerido |
| Versión mínima del SO | 10.0.19041 |

**Assignments:** asignada al grupo que contiene WS001
**Resultado:** WS001 → estado **Compliant** 🟢

---

### 3. Configuration Profile – Interactive Logon Message

**Nombre:** `cfg-interactive-logon-daniellab`
**Tipo:** Settings Catalog
**Plataforma:** Windows 10 and later

Política aplicada como sustitución de GPO on-prem. Muestra un aviso legal antes
de que el usuario inicie sesión en WS001.

| Setting | Valor |
|---|---|
| Interactive Logon Message Title | Aviso Legal – DanielLabTenant |
| Interactive Logon Message Text | Este equipo es propiedad de la organización... |

**Assignments:** asignada al mismo grupo que la Compliance Policy
**Resultado:** Mensaje visible en WS001 antes del login ✅

---

## Verificación final

| Check | Resultado |
|---|---|
| WS001 visible en Intune → Devices | ✅ |
| Estado Compliance | Compliant 🟢 |
| Interactive Logon Message aplicado | ✅ |
| Hybrid Join mantenido (no roto) | ✅ |

---

## Screenshots

| Archivo | Descripción |
|---|---|
| `01_company_portal_inicio.png` | Company Portal abierto, dispositivo no configurado |
| `03_company_portal_mdm_enrolled.png` | Compliance Policy – reglas configuradas |
| `05_intune_devices_ws001_enrolled.png` | WS001 visible en Intune Devices |
| `06_intune_compliance_policy_config.png` | Compliance Policy – reglas configuradas |
| `06_intune_compliance_policy_config2.png` | Compliance Policy – configuración detallada |
| `06_intune_compliance_policy_config0.png` | Compliance Policy – vista general |
| `07_intune_compliance_policy_assignment.png` | Compliance Policy – assignments |
| `07_intune_compliance_policy_confirmation.png` | Compliance Policy – confirmación creación |
| `07_intune_compliance_policy_assignment_show_portal.png` | Compliance Policy en portal |
| `10_intune_device_ws001_compliant.png` | WS001 con estado Compliant 🟢 |
| `08_intune_config_policy_interactive_logon.png` | Config Profile – Interactive Logon |
| `08_intune_config_policy_interactive_logon_all_devices.png` | Config Profile – assignments |
| `08_intune_config_policy_interactive_logon_final.png` | Config Profile – confirmación final |
| `ws001_intune_legal_notice_check.png` | WS001 mostrando el aviso legal antes del login |
| `intune_m365_apps_config1.png` | M365 Apps – configuración paso 1 |
| `intune_m365_apps_config2.png` | M365 Apps – configuración paso 2 |
| `intune_m365_apps_config3.png` | M365 Apps – configuración paso 3 |
| `intune_m365_apps_config4.png` | M365 Apps – configuración paso 4 |
| `intune_m365_apps_config5.png` | M365 Apps – configuración paso 5 |
| `intune_m365_apps_configfinal.png` | M365 Apps – configuración final |
| `intune_m365_apps_task_manager_installing.png` | M365 Apps instalándose en WS001 |
