# Descripción de la Arquitectura

## Infraestructura On-Premises

Construida sobre VMware Workstation Pro 17. Tres máquinas virtuales conectadas en la misma red interna (192.168.75.x).

![Arquitectura On-Premises](../01-onprem/screenshots/architecture-onprem.png)
```
DC01 · Windows Server 2019 · 192.168.75.4 · 2GB RAM
├─ AD DS (daniel.local)
├─ DNS
├─ DHCP
├─ GPO
│   ├─ GPO-WSUS → OU=Workstations
│   └─ Políticas de seguridad
├─ File Server → E:\SharedFiles\
│   └─ Backups\APP01\ ← recibe backups de WSB
└─ WSUS (puerto 8530)
    ├─ app01.daniel.local ✓
    └─ ws001.daniel.local ✓

APP01 · Windows Server 2019 · 192.168.75.5 · 2GB RAM
├─ IIS (HTTPS:443, puerto 80 cerrado)
├─ ASP.NET Core 8
├─ SQL Server Express
│   └─ DanielDB
│       ├─ Proyectos
│       └─ Certificaciones
└─ Windows Server Backup (wbadmin)
    ├─ C:\inetpub\wwwroot
    ├─ C:\inetpub\DanielPortfolio
    ├─ C:\temp\DanielDB.bak
    ├─ Programado: diario 02:00
    └─ Destino: \\DC01\SharedFiles\Backups\APP01\

WS001 · Windows 10 · 192.168.75.7 · 2GB RAM
├─ Unido al dominio (daniel.local)
├─ Hybrid Joined
├─ GPO-WSUS aplicada
└─ Reportando a WSUS
```

## Infraestructura Azure
```
Resource Group: rg-daniellab
│
├─ Identidad
│   └─ Entra ID
│       └─ Sincronización con Entra Connect desde DC01
│           └─ Usuarios + Grupos de daniel.local
│
├─ Red
│   ├─ VNet: vnet-daniellab (10.0.0.0/16)
│   └─ Subnet: snet-app (10.0.1.0/24)
│       └─ NSG-SQL
│           ├─ RDP 3389 → solo tu IP
│           └─ SQL 1433 → solo App Service
│
├─ Cómputo
│   └─ VM-SQL01 · B2s · Windows Server 2022
│       └─ SQL Server Developer 2022
│           └─ DanielDB (restaurada desde .bak)
│
├─ Web
│   └─ App Service (F1 Free)
│       └─ ASP.NET Core 8 (migrado desde APP01)
│           └─ Cadena de conexión → VM-SQL01:1433
│
├─ Almacenamiento
│   └─ Azure Files (Standard LRS)
│       └─ Migrado desde File Server de DC01
│
├─ Backup
│   └─ Recovery Services Vault (GRS)
│       └─ Agente MARS en APP01 (on-prem)
│
├─ Gestión Híbrida
│   └─ Azure Arc
│       ├─ DC01 (servidor Arc-enabled)
│       └─ APP01 (servidor Arc-enabled)
│           └─ Azure Update Manager
│               └─ Sustituye al WSUS on-prem
│
└─ Seguridad y Cumplimiento
    ├─ Defender for Cloud
    ├─ Azure Policy
    └─ Exportación de plantilla ARM (IaC)
```

## Arquitectura de la Aplicación Web (3 Capas)
```
Usuario / WS001
    │
    │ HTTPS :443
    ▼
┌─────────┐     ┌──────────────┐     ┌─────────────────┐
│   IIS   │────►│  ASP.NET 8   │────►│  SQL Server     │
│  :443   │     │  Program.cs  │     │  Express        │
└─────────┘     └──────────────┘     │  └─ DanielDB    │
  ON-PREM          ON-PREM           │     ├─ Proyectos │
                                     │     └─ Certs     │
                                     └─────────────────┘
                                          ON-PREM

Tras la migración:

Usuario
    │
    │ HTTPS
    ▼
┌──────────────┐     ┌─────────────────┐
│ App Service  │────►│ Azure VM B2s    │
│ ASP.NET Core │     │ SQL Server 2022 │
└──────────────┘     │ └─ DanielDB     │
    AZURE             └─────────────────┘
                           AZURE
```

## Mapa de Migración

| On-Premises | Por qué migrar | Herramienta | Azure | Enfoque |
|---|---|---|---|---|
| AD DS | Identidad en nube + SSO | Entra Connect | Entra ID | Sincronización híbrida |
| DNS | Incluido con Entra | Automático | DNS Privado | Incluido |
| File Server | Almacenamiento en nube + disponibilidad | AzCopy | Azure Files | Lift & shift |
| WSUS | Gestión centralizada de updates en nube | Azure Arc | Azure Update Manager | Sustitución |
| IIS + ASP.NET | PaaS — sin gestión de SO | ZIP Deploy | App Service | Modernización PaaS |
| SQL Server Express | IaaS — compatibilidad total con SQL | Backup/Restore .bak | Azure VM + SQL Server | Lift & shift |
| Windows Server Backup | Backup en nube + retención offsite | Agente MARS | Recovery Services Vault | Extensión a nube |

## Decisiones de Diseño

**¿Por qué App Service en vez de Azure VM para IIS?**
La aplicación web es una app ASP.NET Core estándar sin dependencias a nivel de sistema operativo. App Service (PaaS) elimina la gestión del SO, ofrece escalado integrado y tiene coste $0 en el tier F1 — lo que lo convierte en la opción correcta para esta carga de trabajo.

**¿Por qué Azure VM para SQL Server en vez de Azure SQL Database?**
Elegir IaaS para SQL demuestra un escenario realista de lift & shift donde se requiere compatibilidad total con SQL Server. Además justifica la configuración de VNet y NSG, y demuestra comprensión del proceso de decisión entre IaaS y PaaS.

**¿Por qué Azure Arc?**
Arc permite gestionar los servidores on-premises (DC01, APP01) directamente desde Azure Portal sin necesidad de migrarlos. Es la base para Azure Update Manager, la cobertura de Defender for Cloud en servidores híbridos y la aplicación de Azure Policy tanto en recursos on-prem como en la nube.
