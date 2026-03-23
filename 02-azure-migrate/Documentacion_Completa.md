# 02 — Azure Migrate y Onboarding Híbrido — Documentación Completa

## Índice

1. [Decisión de arquitectura — Arc vs migración completa](#1-decisión-de-arquitectura)
2. [Preparación previa](#2-preparación-previa)
3. [Azure Arc — Onboarding de DC01 y APP01](#3-azure-arc--onboarding)
4. [Azure Update Manager — Gestión de parches](#4-azure-update-manager)
5. [Hybrid Azure AD Join — WS001](#5-hybrid-azure-ad-join)
6. [Azure Bastion](#6-azure-bastion)
7. [Verificación del estado híbrido](#7-verificación-del-estado-híbrido)
8. [Troubleshooting documentado](#8-troubleshooting-documentado)

---

## 1. Decisión de arquitectura

### Por qué Arc en lugar de migración completa de VMs

El objetivo del laboratorio es demostrar un escenario híbrido realista. Una migración lift-and-shift completa de DC01 a Azure IaaS no tiene sentido práctico porque:

- DC01 es el Controlador de Dominio autoritativo de `daniel.local`. Moverlo a Azure IaaS sin reconfiguración profunda rompería la resolución DNS y la autenticación Kerberos para WS001 y APP01.
- APP01 aloja SQL Server Express. La migración de la base de datos se realiza de forma independiente como recurso IaaS en `03-azure/04-sql-vm`, no como réplica de la VM completa.
- El coste de dos VMs Azure B2s corriendo 24/7 en un laboratorio no está justificado cuando el objetivo es gestión híbrida, no computación en la nube.

**Azure Arc** permite registrar los servidores on-prem como recursos de Azure Resource Manager sin moverlos. Esto proporciona inventario unificado, Update Manager, Defender for Cloud y Azure Policy sobre los servidores físicos/virtuales on-prem desde el portal de Azure.

### Mapa de servicios migrados vs gestionados

| Servicio on-prem | Estrategia | Dónde queda |
|---|---|---|
| AD DS (daniel.local) | Sincronización → Entra ID | 03-azure/01-identity |
| DNS | Permanece en DC01 + Entra Private DNS | Híbrido |
| WSUS | Sustituido por Update Manager | 02-azure-migrate |
| File Server | Migrado a Azure Files | 03-azure/05-webapp |
| IIS + ASP.NET Core 8 | Migrado a App Service | 03-azure/05-webapp |
| SQL Server Express | Migrado a Azure VM IaaS | 03-azure/04-sql-vm |
| Windows Server Backup | Sustituido por Recovery Services Vault | 03-azure/06-backup |
| GPO | Sustituida parcialmente por Azure Policy | 03-azure/07-security |

---

## 2. Preparación previa

### Requisitos cumplidos antes de iniciar el onboarding

- Suscripción de Azure activa con permisos de Contributor sobre el Resource Group `rg-daniellab`
- Resource Group creado en `francecentral`
- Conectividad de las VMs on-prem hacia internet (necesaria para que el agente Arc contacte con los endpoints de Azure)
- PowerShell 5.1 o superior en DC01 y APP01
- Windows Management Framework actualizado en ambos servidores

### Endpoints de Azure Arc que deben ser accesibles desde on-prem

```
*.his.arc.azure.com
*.guestconfiguration.azure.com
guestnotificationservice.azure.com
*.servicebus.windows.net
dc.services.visualstudio.com
login.microsoftonline.com
management.azure.com
```

---

## 3. Azure Arc — Onboarding

### 3.1 Generación del script de onboarding

Desde el portal de Azure → **Azure Arc** → **Servers** → **Add** → **Add a single server**:

- Sistema operativo: Windows
- Suscripción: la del laboratorio
- Resource Group: `rg-daniellab`
- Región: `francecentral`
- Tags: `Environment=Lab`, `Proyecto=Fase10`

El portal genera un script PowerShell personalizado con el token de registro. Este script se descarga y se ejecuta localmente en cada servidor.

![arc-script-download](./screenshots/arc-script-download.png)

### 3.2 Onboarding de APP01

Se ejecuta el script en APP01 con una sesión de PowerShell elevada (Ejecutar como administrador):

```powershell
# El script descargado del portal realiza internamente:
# 1. Descarga e instala el agente AzureConnectedMachineAgent
# 2. Ejecuta azcmagent connect con los parámetros de la suscripción
# 3. Registra la máquina en Azure Resource Manager

.\OnboardingScript.ps1
```

El agente se instala en `C:\Program Files\AzureConnectedMachineAgent\` y crea el servicio `himds` (Hybrid Instance Metadata Service).

![arc-app01-install](./screenshots/arc-app01-install.png)

Una vez completado, APP01 aparece como **Connected** en Azure Arc → Servers.

![arc-app01-completed](./screenshots/arc-app01-completed.png)

### 3.3 Onboarding de DC01

Mismo procedimiento. Se genera un script separado para DC01 (el token de registro es de un solo uso por script generado) y se ejecuta en una sesión elevada.

![arc-dc01-install](./screenshots/arc-dc01-install.png)
![arc-dc01-completed](./screenshots/arc-dc01-completed.png)

### 3.4 Verificación en el portal

Ambos servidores aparecen en **Azure Arc → Servers** con estado Connected, OS correctamente detectado y Resource Group `rg-daniellab`.

![arc-servers-portal](./screenshots/arc-servers-portal.png)

### 3.5 Tags aplicados durante el onboarding

Se aplican tags consistentes con el resto de recursos del laboratorio para facilitar el filtrado en Cost Management y en Policy.

![arc-onboard-tags](./screenshots/arc-onboard-tags.png)

---

## 4. Azure Update Manager

### 4.1 Por qué sustituye a WSUS

WSUS en DC01 requiere mantenimiento activo: sincronizaciones programadas, aprobación manual de actualizaciones, gestión del disco de la base de datos WSUS. Azure Update Manager evalúa y parchea máquinas Arc-enabled y Azure VMs desde un único panel sin infraestructura adicional.

| Característica | WSUS | Azure Update Manager |
|---|---|---|
| Infraestructura requerida | Windows Server + SQL | Ninguna (SaaS) |
| Cobertura | Solo máquinas del dominio | Arc + Azure VMs |
| Coste | Licencia Windows Server | Gratuito |
| Reporting | Limitado | Dashboard unificado |

### 4.2 Evaluación de actualizaciones pendientes en DC01

Desde **Azure Update Manager → Machines** → seleccionar DC01 → **Check for updates**:

Se lanza una evaluación one-time que inventaría los parches pendientes clasificados por severidad (Critical, Security, Other).

![update-manager-dc01-updates-selected](./screenshots/update-manager-dc01-updates-selected.png)

### 4.3 Instalación one-time de parches

Se seleccionan todas las actualizaciones pendientes y se lanza la instalación inmediata (one-time update):

![update-manager-dc01-onetime-start](./screenshots/update-manager-dc01-onetime-start.png)
![update-manager-dc01-install-confirmed](./screenshots/update-manager-dc01-install-confirmed.png)

### 4.4 Dashboard post-parcheo

Una vez completada la instalación, el dashboard refleja el estado actualizado de ambas máquinas.

![update-manager-dc01-dashboard-final](./screenshots/update-manager-dc01-dashboard-final.png)
![update-manager-manager-over-view](./screenshots/update-manager-manager-over-view.png)

---

## 5. Hybrid Azure AD Join

### 5.1 Objetivo

WS001 es una máquina Windows 10 unida al dominio `daniel.local`. El objetivo es completar el **Hybrid Azure AD Join** para que la identidad de la máquina exista simultáneamente en AD on-prem y en Entra ID — habilitando políticas de acceso condicional y cumplimiento de dispositivos desde Azure.

### 5.2 Prerrequisitos

- Entra Connect instalado y sincronizando usuarios desde `daniel.local` hacia Entra ID (configurado en `03-azure/01-identity`)
- WS001 unida al dominio `daniel.local`
- GPO de Hybrid Join configurada y enlazada a la OU `Workstations`
- SCP (Service Connection Point) publicado en AD DS para que los clientes descubran el tenant de Azure

### 5.3 Configuración del SCP

El SCP informa a los clientes Windows del tenant de Azure al que deben registrarse. Se configura mediante Entra Connect o manualmente vía PowerShell:

```powershell
# Verificar SCP existente
$scp = New-Object System.DirectoryServices.DirectoryEntry
$scp.Path = "LDAP://CN=62a0ff2e-97b9-4513-943f-0d221bd30080,CN=Device Registration Configuration,CN=Services,CN=Configuration,DC=daniel,DC=local"
$scp.Keywords
```

![hybrid-join-scp-config](./screenshots/hybrid-join-scp-config.png)

### 5.4 GPO de Hybrid Join

Se crea la GPO `GPO-HybridJoin` enlazada a la OU `Workstations` con la configuración:

**Ruta:** `Computer Configuration → Administrative Templates → Windows Components → Device Registration`

**Configuración:** `Register domain joined computers as devices` → **Enabled**

![hybrid-join-gpo-config](./screenshots/hybrid-join-gpo-config.png)
![hybrid-join-gpo-linked](./screenshots/hybrid-join-gpo-linked.png)

### 5.5 Filtro de OU para sincronización de dispositivos

En Entra Connect se configura el filtro de OU para incluir `Workstations` en la sincronización de objetos de equipo:

![hybrid-join-ou-filter](./screenshots/hybrid-join-ou-filter.png)

### 5.6 Verificación del join

Desde WS001, tras aplicar la GPO y forzar una sincronización de Entra Connect:

```cmd
dsregcmd /status
```

El campo `AzureAdJoined` debe mostrar `YES` y `DomainJoined` también `YES` — confirmando el estado híbrido.

![hybrid-join-status-success](./screenshots/hybrid-join-status-success.png)

### 5.7 Verificación en Entra ID

WS001 aparece en **Entra ID → Devices** con tipo `Hybrid Azure AD joined` y estado de cumplimiento visible.

![hybrid-join-portal-verified](./screenshots/hybrid-join-portal-verified.png)
![hybrid-join-portal-dev](./screenshots/hybrid-join-portal-dev.png)

---

## 6. Azure Bastion

### 6.1 Por qué Bastion

El acceso RDP directo a `vm-sql01` (desplegada en la VNet de Azure en `03-azure`) requeriría exponer el puerto 3389 en el NSG con una IP pública en la VM. Bastion elimina esta exposición — el acceso se realiza íntegramente desde el navegador a través del portal de Azure, sin IP pública en la VM destino y sin reglas RDP abiertas en el NSG.

### 6.2 Tier seleccionado: Developer

El tier **Developer** de Azure Bastion es gratuito y no requiere IP pública propia ni subnet `AzureBastionSubnet` dedicada. El acceso se realiza exclusivamente desde el portal de Azure. Es suficiente para el laboratorio donde el único requisito es acceso administrativo a `vm-sql01`.

| Tier | IP Pública | Subnet dedicada | Coste | Acceso |
|---|---|---|---|---|
| Developer | No | No | Gratuito | Solo desde portal Azure |
| Basic | Sí (Standard) | AzureBastionSubnet /27 | ~0.19€/h | Navegador + cliente nativo |
| Standard | Sí | AzureBastionSubnet /27 | ~0.35€/h | Todas las opciones |

### 6.3 Despliegue

Bastion se despliega mediante el ARM template del laboratorio (`04-iac/arm/template.json`) enlazado directamente a la VNet `vnet-daniellab`. No se asigna IP pública ni subnet dedicada en el tier Developer.

```json
"sku": { "name": "Developer" },
"properties": {
  "virtualNetwork": {
    "id": "[resourceId('Microsoft.Network/virtualNetworks', variables('vnetName'))]"
  }
}
```

![bastion-created](./screenshots/bastion-created.png)

### 6.4 Verificación de conectividad

Desde el portal de Azure → **vm-sql01** → **Connect** → **Bastion**: se abre una sesión RDP en el navegador sin requerir cliente RDP ni exponer ningún puerto en el NSG.

![bastion-portal-verified](./screenshots/bastion-portal-verified.png)

---

## 7. Verificación del estado híbrido

### Checklist de verificación completa

| Componente | Verificación | Estado |
|---|---|---|
| DC01 en Azure Arc | Estado Connected en portal | ✅ |
| APP01 en Azure Arc | Estado Connected en portal | ✅ |
| DC01 parches | Update Manager — sin pendientes críticos | ✅ |
| APP01 parches | Update Manager — sin pendientes críticos | ✅ |
| WS001 Hybrid Join | dsregcmd /status — AzureAdJoined: YES | ✅ |
| WS001 en Entra ID | Visible en Devices — Hybrid Azure AD joined | ✅ |
| Bastion | Sesión RDP a vm-sql01 desde portal | ✅ |

---

## 8. Troubleshooting documentado

### PROBLEMA 1 │ Arc agent no conecta — error de endpoint

**Síntoma:** El script de onboarding se ejecuta pero el agente queda en estado `Disconnected` o falla al ejecutar `azcmagent connect`.

**Causa:** Las VMs on-prem (VMware Workstation) comparten la conexión a internet del host pero pueden tener restricciones de salida que bloquean los endpoints `*.his.arc.azure.com` y `management.azure.com`.

**Fix:**
```powershell
# Verificar conectividad a los endpoints de Arc desde la VM
Test-NetConnection -ComputerName "management.azure.com" -Port 443
Test-NetConnection -ComputerName "login.microsoftonline.com" -Port 443

# Ver estado del agente instalado
& "C:\Program Files\AzureConnectedMachineAgent\azcmagent.exe" show
```

### PROBLEMA 2 │ Hybrid Join — dsregcmd muestra AzureAdJoined: NO

**Síntoma:** La GPO está aplicada y Entra Connect está sincronizando pero WS001 no completa el join.

**Causa más frecuente:** El SCP no está publicado correctamente en AD DS, o la OU `Workstations` no está incluida en el filtro de sincronización de objetos de equipo en Entra Connect.

**Fix:**
```powershell
# Forzar sincronización de Entra Connect desde DC01
Import-Module ADSync
Start-ADSyncSyncCycle -PolicyType Delta

# Desde WS001 — forzar aplicación de GPO y reintentar join
gpupdate /force
# Reiniciar WS001 para que el join se complete en el siguiente arranque
```

### PROBLEMA 3 │ Bastion Developer — error al asignar IP pública

**Síntoma:** El ARM preflight falla al desplegar Bastion Developer con una IP pública asignada.

**Causa:** El tier Developer no admite IP pública ni `AzureBastionSubnet`. Son exclusivos de los tiers Basic y Standard.

**Fix:** Eliminar la referencia a `publicIPAddress` del recurso `bastionHosts` en el template y usar únicamente `virtualNetwork.id` en properties. Ver `04-iac/arm/template.json` para la configuración correcta.
