# 01 — Infraestructura On-Premises

## Descripción General

Infraestructura on-premises completa construida sobre **VMware Workstation Pro 17**, simulando un entorno empresarial real con un Controlador de Dominio, un Servidor de Aplicaciones y un equipo cliente con Windows 10 — todos unidos al dominio **daniel.local**.

Este entorno sirve como origen de la migración para la fase de Azure del laboratorio.

## Resumen de Infraestructura
```
ON-PREMISES (192.168.75.x)
──────────────────────────────────────────────────────────────────
DC01 · Windows Server 2019 · 192.168.75.4 · 2GB RAM
├─ AD DS (daniel.local) · DNS · DHCP · GPO
├─ File Server → E:\SharedFiles\Backups\APP01\
└─ WSUS (puerto 8530) → grupos Servers + Workstations

APP01 · Windows Server 2019 · 192.168.75.5 · 2GB RAM
├─ IIS (HTTPS:443) + ASP.NET Core 8
├─ SQL Server Express → DanielDB
└─ Windows Server Backup → DC01 File Share (diario 02:00)

WS001 · Windows 10 · 192.168.75.7 · 2GB RAM
└─ Unido al dominio · GPO-WSUS · Acceso IIS + File Share
```

## Servidores

| Servidor | SO | IP | Rol |
|---|---|---|---|
| DC01 | Windows Server 2019 | 192.168.75.4 | Controlador de Dominio |
| APP01 | Windows Server 2019 | 192.168.75.5 | Servidor de Aplicaciones |
| WS001 | Windows 10 | 192.168.75.7 | Equipo Cliente |

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
```
daniel.local
└─ DANIEL (OU raíz — sincronizada con Entra ID)
    ├─ Departamentos
    │   ├─ Admin      → user3_admin
    │   ├─ HR         → user2_hr
    │   ├─ IT         → user1_it
    │   └─ General    → user4_general
    ├─ Grupos
    │   ├─ Sec_Admins → Contributor (Azure)
    │   ├─ Sec_HR     → Reader (Azure)
    │   └─ Sec_IT     → Reader (Azure)
    ├─ Servers        → APP01 (excluida de la sync)
    ├─ Workstations   → WS001
    ├─ Admin_NoSync   → cuentas privilegiadas (excluidas de sync)
    └─ Service_Accounts (reservada, excluida de sync)
```

## Decisiones de Seguridad

**Modelo de Niveles — OU Admin_NoSync**
Las cuentas privilegiadas están aisladas de la sincronización con la nube siguiendo el principio del Modelo de Niveles (Tier Model). Un compromiso en la nube no puede utilizarse para atacar las cuentas privilegiadas on-premises.

**Mínimo Privilegio — Mapeo RBAC**
Los grupos de seguridad de AD se mapean a roles RBAC de Azure siguiendo el principio de mínimo privilegio:
- Sec_Admins → Contributor en rg-daniellab
- Sec_IT → Reader en rg-daniellab
- Sec_HR → Reader en rg-daniellab

**GPOs separadas para Servidores y Puestos de Trabajo**
APP01 (OU=Servers) recibe GPO-WSUS-Servers con comportamiento de solo notificación y sin reinicio automático. WS001 (OU=Workstations) recibe GPO-WSUS con instalación automática. Esto evita interrupciones de servicio no planificadas en el servidor de aplicaciones.

**Puerto 80 cerrado en APP01**
IIS está configurado para servir únicamente sobre HTTPS (puerto 443). El puerto 80 está cerrado para reducir la superficie de ataque — no se acepta tráfico sin cifrar.

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