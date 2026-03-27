# Terraform

## Visión general

Terraform es una herramienta de Infraestructura como Código multi-cloud que utiliza **HCL (HashiCorp Configuration Language)** para definir infraestructura de forma declarativa. A diferencia de las plantillas ARM, Terraform mantiene un **archivo de estado** que rastrea la infraestructura real y detecta desviaciones entre el código y la realidad.

Esta fase cubre la creación de `main.tf` desde cero para toda la infraestructura de Azure de daniellab, la importación de recursos existentes al estado, la resolución de problemas específicos del provider, y la ejecución completa del ciclo apply → destroy.

## Flujo

```id="z9dcga"
main.tf (HCL)
    │
    │  terraform init
    ▼
Provider descargado (azurerm v4.58.0)
    │
    │  terraform import (recursos existentes)
    ▼
terraform.tfstate poblado
    │
    │  terraform plan
    ▼
Plan de ejecución (sin cambios esperados)
    │
    │  terraform apply
    ▼
Infraestructura desplegada ✅
    │
    │  terraform destroy
    ▼
Todos los recursos eliminados ✅
```

## Entorno

| Herramienta      | Versión              |
| ---------------- | -------------------- |
| Terraform        | v1.14.7              |
| AzureRM Provider | v4.58.0              |
| SO               | Windows (PowerShell) |

## Pasos

### 1 — Instalar Terraform

![Terraform Installed](./screenshots/terraform-installed.png)

Terraform instalado en Windows y añadido al PATH.

### 2 — Importar recursos existentes

Dado que la infraestructura ya existía en Azure de fases anteriores, los recursos se importan al estado de Terraform en lugar de crearse desde cero.

![Pre Import](./screenshots/pre%20terraform%20importing%20resources.png)
![Azure Import](./screenshots/azure%20import%20resources.png)
![Importing](./screenshots/importing%20resources.png)
![Imported](./screenshots/imported%20resources+.png)

```powershell id="mpmcz9"
terraform import azurerm_resource_group.res-0 /subscriptions/.../resourceGroups/rg-daniellab-v3
```

### 3 — Terraform Plan (sin cambios)

![Plan No Changes](./screenshots/10_terraform_plan_no_changes.png)

Tras resolver todos los problemas, `terraform plan` confirma que el estado coincide con la infraestructura real.

```
No changes. Your infrastructure matches the configuration.
```

### 4 — Terraform Apply

![Apply](./screenshots/10_terraform_apply.png)
![RG Deployed](./screenshots/01_rg_daniellab_recursos_desplegados.png)

Infraestructura completa desplegada desde código. Todos los recursos creados correctamente.

### 5 — Terraform Destroy

![Destroy](./screenshots/10_terraform_destroy.png)
![Destroy 2](./screenshots/10_terraform_destroy2.png)
![Destroy 3](./screenshots/10_terraform_destroy3.png)
![Destroy 4](./screenshots/10_terraform_destroy4.png)

Infraestructura completamente destruida con `terraform destroy`, confirmando la gestión completa del ciclo de vida.

---

## Resolución de problemas

Todos los problemas encontrados y resueltos durante esta fase están documentados con capturas de pantalla.

### os_managed_disk_id incompatible

![Fix](./screenshots/02_fix_lifecycle_ignore_changes_admin_password.png)

`os_managed_disk_id` generado por la auto-importación entra en conflicto con `source_image_reference`, `admin_password` y `os_disk`. Eliminado del bloque de recurso.

### violación de política de admin_password

![Fix](./screenshots/02_fix_lifecycle_ignore_changes_admin_password.png)

El valor `"ignored-as-imported"` no cumple la política de contraseñas de Azure. Se corrigió con un valor válido y `lifecycle { ignore_changes = [admin_password] }` para evitar que Terraform modifique la contraseña real.

### Application Insights context canceled

![Error](./screenshots/03_error_application_insights_context_canceled.png)
![Fix](./screenshots/03_error_application_insights_context_canceled_fix.png)

El provider AzureRM v4.x requiere `workspace_id` para Application Insights. Sin ello, la llamada a la API se queda colgada indefinidamente. Se solucionó añadiendo `workspace_id = azurerm_log_analytics_workspace.res-12.id`.

### Tablas de Log Analytics contaminando el estado

![Fix](./screenshots/05_fix_terraform_state_rm_log_analytics_tables.png)

La auto-importación capturó cientos de tablas de sistema por defecto de Log Analytics. Eliminadas del estado y del código:

```powershell id="94fsd0"
terraform state list | Where-Object {
  $_ -match "azurerm_log_analytics_workspace_table_custom_log"
} | ForEach-Object { terraform state rm $_ }
```

### IP privada de NIC faltante

![Error](./screenshots/06_error_nic_private_ip_missing.png)
![Fix](./screenshots/06_error_nic_private_ip_missing_fix.png)

La asignación de IP estática requiere un valor explícito de `private_ip_address`. Solucionado añadiendo `private_ip_address = "10.0.1.4"`.

### Políticas de backup ya existen

![Fix](./screenshots/08_fix_terraform_import_backup_policies.png)

Azure crea automáticamente políticas de backup por defecto al crear un Recovery Services Vault. Estas ya existían en Azure pero no en el estado de Terraform — se importaron con `terraform import`.

## Verificación

| Comprobación                                      | Resultado |
| ------------------------------------------------- | --------- |
| terraform plan → Sin cambios                      | ✅         |
| terraform apply → Todos los recursos creados      | ✅         |
| terraform destroy → Todos los recursos eliminados | ✅         |
| Ciclo de vida completo gestionado desde código    | ✅         |
