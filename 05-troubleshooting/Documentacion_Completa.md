# Troubleshooting y Lecciones Aprendidas

Esta documentación sirve como un registro técnico y una Base de Conocimiento (KB) de los problemas encontrados durante la migración de **On-Premise a Azure**. Documenta la resolución de errores críticos en Identidad, Bases de Datos, App Services e Infraestructura como Código (IaC).

## Metodología: Análisis de Causa Raíz (RCA)

Cada entrada sigue un marco estructurado de resolución de problemas:

* **Síntoma:** Evidencia del fallo (logs, HTTP 5xx, errores de CLI, validación en portal)
* **Causa raíz:** El “por qué” (deprecaciones de API, desajustes de identidad, limitaciones de protocolo)
* **Resolución:** Solución aplicada con precisión (fragmento de código, comando CLI o cambio de configuración)
* **Prevención:** Medidas estratégicas para evitar regresiones en entornos de producción

---

## Base de Conocimiento

### 1. [Identidad híbrida y Entra ID](./docs/01-hybrid-identity.md)

* **Desafío clave:** Fallos en el registro de dispositivos (`dsregcmd`) debido al alcance de sincronización.
* **Conclusión clave:** Verificar siempre el filtrado de OU en Entra Connect antes de iniciar Hybrid Join — los objetos de equipo deben existir en la nube antes de que el dispositivo pueda vincularse.
* **Tecnología:** Microsoft Entra Connect, Active Directory, GPO.

### 2. [SQL Server y cargas en VM](./docs/02-sql-vm-errors.md)

* **Desafío clave:** Disponibilidad de SKU por región (francecentral) e incompatibilidad entre versiones de SQL (2025 a 2022).
* **Conclusión clave:** Migrar de una versión superior a una inferior de SQL requiere exportaciones a nivel de datos (JSON/BACPAC) — los archivos `.bak` no son compatibles hacia atrás.
* **Tecnología:** SQL Server 2025/2022, Azure VMs, Azure Backup (Workload).

### 3. [App Service y despliegue web](./docs/03-webapp-deployment.md)

* **Desafío clave:** Timeouts 504 durante despliegues ZIP y error de conectividad 40 (Named Pipes vs TCP).
* **Conclusión clave:** Las cadenas de conexión hacia SQL en Azure VM deben usar explícitamente `tcp:`, incluir el puerto (1433) y requerir autenticación en modo mixto habilitada en la instancia de SQL.
* **Tecnología:** Azure App Service (Linux), Key Vault, .NET 8.

### 4. [IaC: ARM Template](./docs/04-iac-arm-errors.md)

* **Desafío clave:** Volatilidad de versiones de API y conflictos de nombres en Key Vault con soft-delete.
* **Conclusión clave:** Los templates exportados suelen incluir versiones de API inestables (ej. `2024-11-01`). Es necesario fijar versiones estables y purgar Key Vaults eliminados antes de redeplegar para lograr despliegues idempotentes.
* **Tecnología:** ARM Templates (JSON), Azure Resource Manager, Bastion SKU Developer.

### 5. [IaC: Terraform y gestión del estado](./docs/05-iac-terraform-errors.md)

* **Desafío clave:** Conflictos de argumentos en `azurerm_windows_virtual_machine` y contaminación del estado con tablas gestionadas por el sistema en Log Analytics.
* **Conclusión clave:** Usar `lifecycle { ignore_changes }` para contraseñas y limpiar manualmente el estado (`terraform state rm`) cuando `aztfexport` capture recursos del sistema no gestionados.
* **Tecnología:** Terraform v1.14+, AzureRM Provider v4.x, `aztfexport`.

### 6. [CI/CD: GitHub Actions](./docs/06-cicd-errors.md)

* **Desafío clave:** Fallos en workflows de GitHub Actions durante despliegues automáticos a App Service — autenticación con publish profile, conflictos de integración con VNet y conectividad con base de datos tras despliegues del pipeline.
* **Conclusión clave:** El publish profile debe descargarse de nuevo tras cualquier cambio en la configuración de App Service (VNet Integration, managed identity). Las cadenas de conexión definidas como variables de entorno en el pipeline tienen prioridad sobre las referencias a Key Vault — validar siempre toda la cadena end-to-end tras un despliegue CI/CD, no solo el build.
* **Tecnología:** GitHub Actions, Azure App Service, Azure Key Vault, ASP.NET Core 8.

---

## Principales lecciones de ingeniería

**1. La paridad de versiones es innegociable**
La migración de SQL Server 2025 (on-prem) a 2022 (Azure VM) demuestra que la preparación para la nube empieza por alinear versiones. Cuando no es posible, se debe usar una migración basada en datos (JSON/BACPAC) en lugar de una basada en imagen (.bak).

**2. Lo explícito sobre lo implícito en red**
La conectividad entre App Service y SQL VM falla frecuentemente al depender de configuraciones por defecto. Definir explícitamente protocolos (`tcp:`) y gestionar correctamente contraseñas con caracteres especiales en Key Vault evita horas de troubleshooting.

**3. Ciclo de vida de recursos con estado**
Recursos como Key Vault o las políticas de backup siguen existiendo tras su eliminación (soft-delete, configuraciones automáticas). La lógica IaC debe contemplar la purga o importación de estos recursos para evitar `ConflictError` en redeployments.

**4. Resiliencia frente a versiones de API**
No confiar ciegamente en las versiones de API exportadas. Validar siempre contra la documentación oficial de Azure Resource Reference para asegurar compatibilidad con la región objetivo.

**5. CI/CD expone suposiciones de configuración**
Automatizar un despliegue que funcionaba manualmente revela todas las dependencias implícitas — variables de entorno, permisos de managed identity, rutas de red en VNet. Que el pipeline pase no significa que la aplicación funcione. Los tests end-to-end tras cada despliegue no son opcionales.
