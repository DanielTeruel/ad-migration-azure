![Azure Migrate](./screenshots/banner-migrate.png)
![Estado](https://img.shields.io/badge/Status-Complete-green)
![Servidores](https://img.shields.io/badge/Servers%20Onboarded-2-blue)
![Arc](https://img.shields.io/badge/Azure%20Arc-Enabled-0078D4)
![Hybrid Join](https://img.shields.io/badge/Hybrid%20Join-Complete-green)
![Intune](https://img.shields.io/badge/Intune-Enrolled-green)

# 02 — Azure Migrate y Onboarding Híbrido

## Visión general

Esta fase cubre el **onboarding híbrido** del entorno on-premises en Azure sin realizar una migración completa tipo lift-and-shift. En lugar de replicar las máquinas virtuales a Azure IaaS, el enfoque elegido utiliza **Azure Arc** para proyectar los servidores on-premises dentro de Azure Resource Manager — permitiendo gestión unificada, aplicación de políticas, gestión de actualizaciones y postura de seguridad desde el portal de Azure.

Tanto **DC01** como **APP01** siguen ejecutándose on-premises (VMware Workstation Pro 17) y se registran como servidores habilitados con Arc. **WS001** completa el Hybrid Azure AD Join y la inscripción en Intune, conectando las Group Policy on-premises con la gestión de dispositivos basada en la nube.

## Decisión de diseño: ¿Por qué Arc en lugar de una migración completa de VMs?

| Criterio             | Migración a Azure VM         | Azure Arc (elegido)                          |
| -------------------- | ---------------------------- | -------------------------------------------- |
| Movimiento de cargas | Lift & shift completo a IaaS | Permanece on-prem, gestionado desde Azure    |
| Coste                | VM facturada 24/7            | Gratis para el plano de gestión de Arc       |
| SQL Server           | Requiere SQL en VM de Azure  | APP01 sigue sirviendo SQL on-prem            |
| AD DS                | DC01 requeriría dcpromo      | DC01 sigue siendo el DC autoritativo         |
| Gestión              | Solo Azure                   | Unificada: on-prem + Azure en una sola vista |
| Caso de uso          | Desmantelar on-prem          | Extensión híbrida del entorno on-prem        |

La carga de SQL Server y la aplicación web se migran por separado como recursos PaaS/IaaS en `03-azure`. Arc se encarga del **plano de gestión**, mientras que los servidores on-prem siguen funcionando.

**¿Por qué no una evaluación formal con Azure Migrate?**
Azure Migrate Assessment es la herramienta adecuada para migraciones en producción — proporciona descubrimiento, mapeo de dependencias y análisis de TCO. Para este laboratorio, el alcance y los objetivos de la migración ya estaban definidos, por lo que una evaluación formal no era necesaria. Se eligió un enfoque Arc-first para demostrar gestión híbrida en lugar de una migración unidireccional a la nube.

---

## Servidores habilitados con Arc

![Arc Servers Portal](./01-arc/screenshots/arc-servers-portal.png)

| Servidor | SO                  | Estado Arc  |
| -------- | ------------------- | ----------- |
| DC01     | Windows Server 2019 | Conectado ✅ |
| APP01    | Windows Server 2019 | Conectado ✅ |

Ambos servidores se registraron generando un script desde el portal de Azure y ejecutándolo localmente en cada máquina. Una vez conectados, aparecen en Azure Resource Manager y son visibles en la sección Arc — Servers.

---

## Azure Update Manager

![DC01 Completado](./02-update-manager/screenshots/update-manager-dc01-completed.png)

Azure Update Manager sustituye WSUS como solución de gestión de parches para DC01 y APP01 una vez habilitados con Arc.

| Servidor | Evaluación             | Ciclo de parches                 | Estado                            |
| -------- | ---------------------- | -------------------------------- | --------------------------------- |
| DC01     | Periódica (habilitada) | Ejecución única de actualización | Sin actualizaciones pendientes 🟢 |
| APP01    | Periódica (habilitada) | Evaluado                         | Sin actualizaciones pendientes 🟢 |

---

## Hybrid Azure AD Join — WS001

![Hybrid Join Success](./03-hybrid-join/screenshots/hybrid-join-dsregcmd-status-success.png)
![Hybrid Join Portal](./03-hybrid-join/screenshots/hybrid-join-portal-verified.png)

WS001 está unido tanto a **daniel.local** (on-premises) como a **Entra ID** (nube), permitiendo una identidad híbrida gestionada desde un único dispositivo.

| Configuración    | Valor     |
| ---------------- | --------- |
| AzureAdJoined    | YES ✅     |
| DomainJoined     | YES ✅     |
| DeviceAuthStatus | SUCCESS ✅ |

**Cómo funciona:** Entra Connect establece un Service Connection Point (SCP) en AD DS. Cuando WS001 se autentica contra el dominio, se registra automáticamente en Entra ID — sin necesidad de pasos manuales en el dispositivo.

---

## Azure Bastion

![Bastion Creado](./04-bastion/screenshots/bastion-created.png)

Azure Bastion proporciona acceso RDP basado en navegador a máquinas virtuales de Azure sin exponer una IP pública. Se despliega en esta fase para permitir acceso seguro a **vm-sql01** en fases posteriores.

| Configuración | Valor                            |
| ------------- | -------------------------------- |
| SKU           | Developer                        |
| Subred        | AzureBastionSubnet (10.0.2.0/26) |
| Recurso       | bastion-daniellab                |
| IP pública    | Asignada                         |

**¿Por qué Bastion aquí y no en la fase de red?**
Sin una VM activa a la que conectarse, desplegar Bastion en la Fase 2 supondría un coste innecesario. Se despliega junto a la primera VM que requiere acceso remoto — vm-sql01 en la Fase 5.

---

## Intune — Gestión moderna de dispositivos

![Intune Inscrito](./05-intune/screenshots/05_intune_devices_ws001_enrolled.png)
![Intune Conforme](./05-intune/screenshots/10_intune_device_ws001_compliant.png)

WS001 se inscribe en Microsoft Intune mediante inscripción automática MDM activada por GPO, permitiendo la gestión de dispositivos desde la nube junto con las Group Policy on-premises.

### Política de cumplimiento

| Requisito                     | Estado      |
| ----------------------------- | ----------- |
| Firewall habilitado           | ✅           |
| Antivirus habilitado          | ✅           |
| Versión mínima del SO (19045) | ✅           |
| Cumplimiento general          | Conforme 🟢 |

### Despliegue de Microsoft 365 Apps

Word, Excel, PowerPoint y Teams se despliegan en WS001 mediante una política de aplicaciones de Intune — sin instalación manual en el dispositivo.

| Aplicación           | Estado      |
| -------------------- | ----------- |
| Microsoft Word       | Instalado ✅ |
| Microsoft Excel      | Instalado ✅ |
| Microsoft PowerPoint | Instalado ✅ |
| Microsoft Teams      | Instalado ✅ |

### Seguridad de Endpoint

Se aplica un mensaje de inicio de sesión interactivo (aviso legal) en WS001 mediante una política de seguridad de endpoint de Intune, mostrado antes de iniciar la sesión del usuario.

---

## Qué permite esta fase

| Capacidad                          | Herramienta                | Sustituye                     |
| ---------------------------------- | -------------------------- | ----------------------------- |
| Inventario unificado de servidores | Azure Arc                  | Seguimiento manual de activos |
| Gestión de parches                 | Azure Update Manager       | WSUS en DC01                  |
| Aplicación de políticas            | Azure Policy (vía Arc)     | GPO (parcial)                 |
| Puente de identidad                | Hybrid Azure AD Join       | Identidad solo de dominio     |
| Gestión de dispositivos            | Microsoft Intune           | Solo GPO on-prem              |
| Despliegue de aplicaciones         | Política de apps de Intune | Instalación manual            |
| Acceso remoto                      | Azure Bastion              | Exposición directa por RDP    |

---

## Estado

* [x] DC01 — onboarded en Arc y conectado
* [x] APP01 — onboarded en Arc y conectado
* [x] Azure Update Manager — ciclo de parches completado en ambos servidores
* [x] WS001 — Hybrid Azure AD Join completado
* [x] Azure Bastion — desplegado y verificado
* [x] WS001 — inscrito en Intune y conforme
* [x] Microsoft 365 Apps — desplegadas mediante Intune
* [x] Política de seguridad de endpoint — aplicada
