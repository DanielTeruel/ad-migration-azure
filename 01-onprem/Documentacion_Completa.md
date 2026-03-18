![Infraestructura On-Premises](./banner-onprem.png)

![Estado](https://img.shields.io/badge/Estado-Completo-green)
![VMs](https://img.shields.io/badge/VMs-3-blue)
![Hypervisor](https://img.shields.io/badge/Hypervisor-VMware%20Workstation%20Pro%2017-lightgrey)
![SO](https://img.shields.io/badge/SO-Windows%20Server%202019-blue)

# 01 — Infraestructura On-Premises

## Descripción General

Infraestructura on-premises completa construida sobre **VMware Workstation Pro 17**, simulando un entorno empresarial real con un Controlador de Dominio, un Servidor de Aplicaciones y un equipo cliente con Windows 10 — todos unidos al dominio **daniel.local**.

Este entorno sirve como origen de la migración para la fase de Azure del laboratorio.

## Servidores

| Servidor | SO | IP | RAM | Rol |
|---|---|---|---|---|
| DC01 | Windows Server 2019 | 192.168.75.4 | 2GB | Controlador de Dominio |
| APP01 | Windows Server 2019 | 192.168.75.5 | 2GB | Servidor de Aplicaciones |
| WS001 | Windows 10 | 192.168.75.7 | 2GB | Equipo Cliente |

## Servicios Desplegados

| Servicio | Servidor | Migra a |
|---|---|---|
| AD DS (daniel.local) | DC01 | Entra ID |
| DNS | DC01 | DNS Privado de Entra ID |
| DHCP | DC01 | — |
| GPO | DC01 | Azure Policy |
| File Server | DC01 | Azure Files |
| WSUS | DC01 | Azure Update Manager |
| IIS + ASP.NET Core 8 | APP01 | App Service (F1 Free) |
| SQL Server Express | APP01 | Azure VM + SQL Server |
| Windows Server Backup | APP01 | Recovery Services Vault |

## Estructura de AD

| OU | Contenido | Sincronizado con Entra ID |
|---|---|---|
| Departamentos/Admin | user3_admin | ❌ (Admin_NoSync) |
| Departamentos/HR | user2_hr | ✅ |
| Departamentos/IT | user1_it | ✅ |
| Departamentos/General | user4_general | ✅ |
| Grupos | Sec_Admins · Sec_HR · Sec_IT | ✅ |
| Servers | APP01 | ❌ (equipos excluidos) |
| Workstations | WS001 | ❌ (equipos excluidos) |
| Admin_NoSync | user3_admin · App01Admin | ❌ (cuentas privilegiadas) |
| Service_Accounts | — | ❌ (reservada) |

## Mapeo RBAC (On-Prem → Azure)

| Grupo AD | Rol Azure | Ámbito |
|---|---|---|
| Sec_Admins | Contributor | rg-daniellab |
| Sec_IT | Reader | rg-daniellab |
| Sec_HR | Reader | rg-daniellab |

## Decisiones de Seguridad

**Modelo de Niveles — OU Admin_NoSync**
Las cuentas privilegiadas están aisladas de la sincronización con la nube siguiendo el principio del Modelo de Niveles. Un compromiso en la nube no puede utilizarse para atacar las cuentas privilegiadas on-premises.

**Mínimo Privilegio — Mapeo RBAC**
Los grupos de seguridad de AD se mapean a roles RBAC de Azure siguiendo el principio de mínimo privilegio — ningún usuario tiene más permisos de los estrictamente necesarios.

**GPOs separadas para Servidores y Puestos de Trabajo**
APP01 (OU=Servers) recibe GPO-WSUS-Servers con comportamiento de solo notificación y sin reinicio automático. WS001 (OU=Workstations) recibe GPO-WSUS con instalación automática. Esto evita interrupciones de servicio no planificadas en el servidor de aplicaciones.

**Puerto 80 cerrado en APP01**
IIS está configurado para servir únicamente sobre HTTPS (puerto 443). El puerto 80 está cerrado para reducir la superficie de ataque.

## Documentación

| Carpeta | Contenido |
|---|---|
| [dc01](./dc01/) | Controlador de Dominio — AD DS, DNS, DHCP, GPO, WSUS, File Server |
| [app01](./app01/) | Servidor de Aplicaciones — IIS, ASP.NET Core 8, SQL Server, WSB |
| [ws001](./ws001/) | Equipo Cliente — Unión al dominio, GPO, WSUS, acceso a recursos |

## Estado

- [x] DC01 — completamente configurado y documentado
- [x] APP01 — completamente configurado y documentado
- [x] WS001 — completamente configurado y documentado
- [ ] Hybrid Azure AD Join (WS001) — pendiente fase Azure