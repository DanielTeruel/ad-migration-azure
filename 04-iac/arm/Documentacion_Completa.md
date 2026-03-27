# Plantillas ARM

## Visión general

Las Plantillas de Azure Resource Manager (ARM) son archivos de Infraestructura como Código basados en JSON y nativos de Azure. Esta fase cubre la exportación de la infraestructura existente `rg-daniellab`, la modificación de la plantilla para corregir artefactos de exportación, y su redepliegue en un nuevo grupo de recursos.

## Flujo

```id="1b2j3k"
rg-daniellab (existente)
    │
    │  Exportar plantilla
    ▼
template.json + parameters.json
    │
    │  Modificar + corregir
    ▼
template_v2.json + parameters_v2.json
    │
    │  az deployment group create
    ▼
rg-daniellab-v2 (nuevo grupo de recursos)
    │
    │  Validar + verificar
    ▼
Todos los recursos redeplegados ✅
```

## Pasos

### 1 — Exportar plantilla ARM

La infraestructura existente en `rg-daniellab` se exporta desde el Portal de Azure como una plantilla ARM completa.

![ARM Template Exported](./screenshots/arm-template-exported.png)
![ARM Template Exported Show](./screenshots/arm-template-exported-show.png)

La exportación genera `template.json` (515KB) que contiene todas las definiciones de recursos y su configuración actual.

### 2 — Modificar plantilla

La plantilla exportada requiere modificaciones antes de su redepliegue — las plantillas exportadas suelen contener valores hardcodeados, IDs específicos de recursos y propiedades que provocan errores de validación al volver a desplegar.

![ARM Template V2 Exported](./screenshots/arm-template-v2-exported.png)
![Parameters V2](./screenshots/parameters_v2.json.png)
![Parameters Created](./screenshots/arm-parameters-created.png)

Modificaciones clave aplicadas:

* Eliminación de propiedades de recursos no redeplegables
* Parametrización de valores específicos del entorno
* Corrección de referencias de discos y de imágenes de máquinas virtuales
* Limpieza de políticas de acceso de Key Vault

### 3 — Validación

Antes de desplegar, la plantilla se valida contra la API de Azure para detectar errores sin crear recursos.

![Validation Passed](./screenshots/ARM-Template-Validation-Passed.png)
![Validation Passed 2](./screenshots/ARM-Template-Validation-Passed2.png)
![Validation Passed Portal](./screenshots/ARM-Template-Validation-Passed-portal.png)

```bash
az deployment group validate \
  --resource-group rg-daniellab-v2 \
  --template-file template_v2.json \
  --parameters parameters_v2.json
```

### 4 — Redepliegue

![Deploy Running](./screenshots/arm-template-deploy-v2-running.png)
![Deploy Partial](./screenshots/arm-deploy-partial.png)
![Deploy Troubleshooting](./screenshots/arm-deploy-troubleshooting.png)
![Deploy Final Resources](./screenshots/arm-deploy-final-resources.png)

Los recursos se redepliegan en `rg-daniellab-v2` usando la plantilla modificada.

### 5 — Verificación de recursos

![RG V2 Created](./screenshots/rg-v2-created.png)
![VM Created](./screenshots/arm-vm-created.png)
![Disk Before](./screenshots/arm-disk-before.png)
![Disk After](./screenshots/arm-disk-after.png)

### 6 — Key Vault

![Previous KV Purge](./screenshots/arm-previous-kv-purge.png)
![New KV](./screenshots/arm-new-kv.png)
![KV Secret](./screenshots/arm-kv-new.secret.png)
![KV Autorole](./screenshots/arm-kv-autorole.png)

Key Vault requiere un tratamiento especial — el soft-delete implica que el vault anterior debe ser purgado antes de poder redeplegar uno con el mismo nombre.

### 7 — Limpieza: Eliminar RG original

![RG Deleted](./screenshots/rg-daniellab-deleted.png)
![RG Deleting CLI](./screenshots/rg-daniellab-deleting-cli.png)

El `rg-daniellab` original se elimina tras validar correctamente el entorno redeplegado.

### 8 — Verificación de políticas

![Policy Working](./screenshots/policy-working-proof.png)

Se verifica que las asignaciones de Azure Policy siguen activas tras el redepliegue.

## Verificación

| Comprobación                                       | Resultado |
| -------------------------------------------------- | --------- |
| Validación de la plantilla superada                | ✅         |
| Todos los recursos redeplegados en rg-daniellab-v2 | ✅         |
| Key Vault purgado y recreado                       | ✅         |
| RG original eliminado                              | ✅         |
| Azure Policy sigue aplicándose                     | ✅         |
