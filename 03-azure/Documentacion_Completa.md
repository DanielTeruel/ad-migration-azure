# 03 — Azure Infrastructure — Documentación Completa

## Índice

1. [Visión general del entorno Azure](#1-visión-general)
2. [Resource Group y organización](#2-resource-group)
3. [Decisiones de arquitectura](#3-decisiones-de-arquitectura)
4. [Orden de despliegue](#4-orden-de-despliegue)
5. [Resumen de subapartados](#5-resumen-de-subapartados)
6. [Troubleshooting documentado](#6-troubleshooting-documentado)

---

## 1. Visión general

Este apartado documenta la infraestructura Azure completa del laboratorio — el destino final de todos los servicios que corrían on-premises en `daniel.local`. El objetivo no es una migración lift-and-shift de VMs completas, sino una migración selectiva que aprovecha los servicios PaaS y IaaS de Azure según el tipo de workload:

- **PaaS donde tiene sentido:** la aplicación web ASP.NET Core 8 no tiene dependencias de OS — migra a App Service sin modificaciones significativas.
- **IaaS donde se requiere compatibilidad:** SQL Server Express en APP01 migra a una VM Azure con SQL Server Developer — manteniendo compatibilidad total con el esquema y los datos existentes.
- **Gestión híbrida sin mover lo que no necesita moverse:** DC01 y APP01 permanecen on-premises, gestionados desde Azure a través de Azure Arc.

### Entorno resultante

```
rg-daniellab (francecentral)
│
├── Identidad
│   └── Entra ID ← sincronizado desde daniel.local via Entra Connect
│
├── Red
│   ├── vnet-daniellab (10.0.0.0/16)
│   │   ├── snet-default (10.0.1.0/24) → vm-sql01
│   │   ├── AzureBastionSubnet (10.0.2.0/26) → Bastion
│   │   └── snet-webapp (10.0.3.0/24) → App Service VNet Integration
│   └── nsg-sql → snet-default
│
├── Computación
│   ├── vm-sql01 (Standard_D2s_v3 · Windows Server 2022)
│   │   └── SQL Server Developer 2022 → DanielDB
│   └── app-daniellab (App Service B1 Linux)
│       └── ASP.NET Core 8 → conecta a DanielDB via VNet
│
├── Seguridad y acceso
│   ├── kv-daniellab → secreto: cadena de conexión SQL
│   ├── bastion-daniellab (Developer) → acceso RDP a vm-sql01
│   └── Managed Identity → App Service accede a Key Vault sin credenciales
│
├── Almacenamiento y backup
│   ├── stfilesdaniellab → Azure Files (danielfiles)
│   ├── stbkpdaniellab → backup de App Service
│   └── rsv-daniellab → backup SQL workload (DanielDB)
│
└── Monitorización y gobernanza
    ├── law-daniellab → Log Analytics (conectado a vm-sql01)
    ├── ai-daniellab → Application Insights (conectado a App Service)
    ├── alert-cpu-vm-sql01 → alerta CPU > 80% durante 1 min
    ├── Defender for Cloud → postura de seguridad
    └── Azure Policy → tag enforcement + auditoría de backup
```

---

## 2. Resource Group

### Creación

El Resource Group `rg-daniellab` se crea en `francecentral` como contenedor de todos los recursos del laboratorio. Se aplican tags desde el primer momento para cumplir la política de etiquetado que se configurará posteriormente en Azure Policy.

```powershell
New-AzResourceGroup `
  -Name "rg-daniellab" `
  -Location "francecentral" `
  -Tag @{"Environment"="Lab"; "Proyecto"="Fase10"} `
  -Force
```

### Por qué francecentral

Francia Central es la región Azure más cercana geográficamente para un laboratorio con sede en España — menor latencia desde las VMs on-premises (VMware Workstation) que conectan a Azure, y precios equivalentes a West Europe.

### Gestión del ciclo de vida

El Resource Group se elimina y recrea durante el desarrollo del laboratorio usando el ARM template de `04-iac` para verificar que toda la infraestructura es reproducible desde cero. Este proceso está documentado en `04-iac/Documentacion_Completa.md`.

---

## 3. Decisiones de arquitectura

### PaaS vs IaaS para la aplicación web

La aplicación web es un proyecto ASP.NET Core 8 estándar sin dependencias de sistema operativo Windows. App Service (PaaS) elimina la gestión del OS, proporciona escalado automático, HTTPS nativo y despliegue via ZIP sin configuración adicional. No hay motivo técnico para usar una VM IaaS para este workload.

### PaaS vs IaaS para SQL Server

Se elige IaaS (VM con SQL Server) en lugar de Azure SQL Database por varias razones:

1. **Compatibilidad de migración:** el proceso de exportación JSON desde SQL Server Express y la recreación manual de la BD demuestra el flujo real de migración de datos.
2. **Control total:** SQL Server Developer en VM permite configurar el modo de autenticación mixto, gestionar logins SQL y ajustar la instancia — operaciones no disponibles o más restrictivas en Azure SQL Database.
3. **Escenario realista:** en entornos empresariales, las migraciones de SQL Server a PaaS requieren validación de compatibilidad extensa. El enfoque IaaS lift-and-shift es el camino de menor riesgo y más común en proyectos de migración reales.

### Sin IP pública en vm-sql01

La VM no tiene IP pública. El acceso administrativo se realiza exclusivamente a través de Azure Bastion — eliminando la exposición del puerto 3389 y del puerto 1433 a internet. El acceso de la aplicación a SQL Server se realiza a través de VNet Integration, nunca por internet.

### Key Vault para credenciales

La cadena de conexión SQL nunca aparece en texto plano en ningún lugar del despliegue:
- No está en el código fuente
- No está en las variables de entorno de App Service
- No está en el ARM template
- Se almacena en Key Vault y se recupera en runtime mediante Managed Identity

### Entra Connect con filtrado de OUs

Solo las OUs de usuarios de negocio se sincronizan a Entra ID. Las cuentas privilegiadas (`Admin_NoSync`) se excluyen explícitamente siguiendo el principio de Tier Model — una cuenta de administrador de dominio comprometida en cloud no puede usarse para atacar el AD on-premises.

---

## 4. Orden de despliegue

El orden importa — algunos recursos dependen de otros para funcionar correctamente.

| Paso | Recurso | Dependencia |
|---|---|---|
| 1 | Resource Group | — |
| 2 | VNet + subnets + NSG | — |
| 3 | Storage Accounts | — |
| 4 | Log Analytics Workspace | — |
| 5 | Key Vault | — |
| 6 | vm-sql01 (sin SQL aún) | VNet, NSG |
| 7 | Azure Bastion | VNet, AzureBastionSubnet |
| 8 | Entra Connect en DC01 | Entra ID tenant |
| 9 | SQL Server en vm-sql01 | vm-sql01 running |
| 10 | Migración DanielDB | SQL Server instalado, Storage Account |
| 11 | App Service Plan + App Service | — |
| 12 | Key Vault secret + Managed Identity | App Service, Key Vault |
| 13 | VNet Integration en App Service | snet-webapp, App Service |
| 14 | ZIP Deploy de la aplicación | App Service configurado |
| 15 | Application Insights | Log Analytics Workspace |
| 16 | Recovery Services Vault | — |
| 17 | Backup SQL workload | RSV, vm-sql01 con SQL |
| 18 | Azure Files + AzCopy desde DC01 | Storage Account |
| 19 | Azure Policy assignments | Resource Group |
| 20 | Defender for Cloud | Suscripción |
| 21 | Log Analytics → vm-sql01 | LAW, vm-sql01 |
| 22 | Alerta CPU vm-sql01 | vm-sql01, Action Group |
| 23 | ARM Template export | Todo desplegado |

---

## 5. Resumen de subapartados

### 01-identity — Entra ID e Identidad

Entra Connect instalado en DC01 sincroniza usuarios y grupos desde `daniel.local` hacia Entra ID. Se aplica filtrado de OUs para excluir cuentas privilegiadas. Los grupos de seguridad sincronizados (`Sec_Admins`, `Sec_IT`, `Sec_HR`) se mapean a roles RBAC de Azure en el Resource Group. MFA habilitado mediante Security Defaults.

**Documentación completa:** [01-identity/README.md](./01-identity/README.md)

### 02-networking — Red Virtual y NSG

VNet `vnet-daniellab` con tres subnets. NSG `nsg-sql` controla el tráfico hacia vm-sql01 — puerto 3389 restringido a IP de administración, puerto 1433 permitido únicamente desde `snet-webapp`. La subnet `snet-webapp` habilita la VNet Integration de App Service para conectividad privada a SQL Server.

**Documentación completa:** [02-networking/README.md](./02-networking/README.md)

### 03-fileshare — Azure Files

La carpeta compartida de DC01 (`E:\SharedFiles`) se migra a Azure Files mediante AzCopy ejecutado directamente en DC01. Se genera un token SAS con permisos mínimos para la transferencia. El contenido se verifica en el portal tras la copia.

**Documentación completa:** [03-fileshare/README.md](./03-fileshare/README.md)

### 04-sql-vm — Azure VM + SQL Server

vm-sql01 desplegada con Windows Server 2022, SQL Server Developer 2022 instalado manualmente via Bastion. La migración de DanielDB requirió abandonar el enfoque `.bak` por incompatibilidad de versiones entre SQL Server Express (APP01) y SQL Server Developer (vm-sql01) — se usó exportación JSON como alternativa. Los datos se transfirieron via AzCopy a través de un Storage Account.

**Documentación completa:** [04-sql-vm/README.md](./04-sql-vm/README.md)

### 05-webapp — App Service y Aplicación Web

La aplicación ASP.NET Core 8 se empaqueta en ZIP desde APP01 y se despliega en App Service via Kudu ZIP Deploy. La conexión a SQL Server se gestiona sin credenciales en texto plano: Managed Identity + Key Vault. VNet Integration conecta App Service a vm-sql01 por IP privada. Application Insights conectado para monitorización en tiempo real.

**Documentación completa:** [05-webapp/README.md](./05-webapp/README.md)

### 06-backup — Recovery Services Vault

RSV configurado con redundancia GRS. vm-sql01 registrada como host para habilitar el backup de workload SQL. La base de datos DanielDB se protege con una política de backup semanal completo + logs cada 2 horas. Se ejecuta un backup on-demand inicial para verificar la configuración.

**Documentación completa:** [06-backup/README.md](./06-backup/README.md)

### 07-security — Seguridad, Monitorización y Gobernanza

Defender for Cloud habilitado a nivel de suscripción. Log Analytics Workspace conectado a vm-sql01 via extensión MMA. Application Insights conectado a App Service con el mismo workspace como backend. Alerta de CPU en vm-sql01 configurada con umbral 80% / 1 minuto. Azure Policy aplica tag `Environment` y audita backup en VMs. Todo centralizado bajo el mismo Action Group (SmartDetect).

**Documentación completa:** [07-security/README.md](./07-security/README.md)

---

## 6. Troubleshooting documentado

### PROBLEMA 1 │ Migración .bak bloqueada por incompatibilidad de versiones SQL

**Síntoma:** El restore del `.bak` generado en APP01 (SQL Server Express 2022) falla en vm-sql01 (SQL Server Developer 2022).

**Causa:** Diferencia en el nivel de compatibilidad de la base de datos entre instancias. SQL Server Express y Developer pueden tener niveles de parche diferentes aunque sean el mismo año, y los backups no son siempre intercambiables entre ediciones.

**Fix aplicado:** Exportación de las tablas a JSON desde SSMS en APP01, transferencia via AzCopy → Storage Account → vm-sql01, recreación manual del esquema y carga de datos desde JSON.

---

### PROBLEMA 2 │ App Service no conecta a SQL Server tras VNet Integration

**Síntoma:** La aplicación devuelve error de conexión a base de datos después de desplegar en App Service, aunque VNet Integration está configurada.

**Causa más frecuente:** La regla NSG en `nsg-sql` no incluía `snet-webapp` como origen permitido en el puerto 1433, o la VNet Integration no estaba delegada correctamente a `snet-webapp`.

**Fix:**
1. Verificar que la regla `AllowSQL` en `nsg-sql` tiene como origen el bloque CIDR `10.0.3.0/24` o el nombre de subnet `snet-webapp`
2. Verificar en App Service → Networking → VNet Integration que la subnet asignada es `snet-webapp` y el estado es `Connected`
3. Verificar que el secreto en Key Vault contiene la cadena de conexión con la IP privada `10.0.1.10` y no un hostname público

---

### PROBLEMA 3 │ Key Vault acceso denegado desde App Service

**Síntoma:** La aplicación arranca pero falla al recuperar el secreto de Key Vault — error `403 Forbidden` en los logs de App Service.

**Causa:** La Managed Identity del App Service no tiene el permiso `get` sobre los secretos del Key Vault, o el Key Vault tiene RBAC habilitado pero el rol `Key Vault Secrets User` no está asignado a la identidad.

**Fix:**
```
Azure Portal → Key Vault → Access policies
→ Add Access Policy
→ Secret permissions: Get, List
→ Principal: app-daniellab (Managed Identity)
→ Save
```
Si el KV usa RBAC en lugar de Access Policies:
```
Key Vault → IAM → Add role assignment
→ Role: Key Vault Secrets User
→ Assign to: Managed Identity → app-daniellab
```

---

### PROBLEMA 4 │ Entra Connect — usuarios sincronizan con UPN incorrecto

**Síntoma:** Los usuarios sincronizan a Entra ID pero su UPN termina en `@daniellab.onmicrosoft.com` en lugar de `@daniel.local`.

**Causa:** El sufijo `daniel.local` no es un dominio verificado en Entra ID (es un dominio privado no enrutable). Entra Connect sustituye el sufijo por el dominio `onmicrosoft.com` del tenant automáticamente.

**Resolución:** Este comportamiento es esperado y correcto para entornos de laboratorio con dominios `.local`. No requiere corrección — los usuarios se autentican con el UPN `onmicrosoft.com` en Azure.
