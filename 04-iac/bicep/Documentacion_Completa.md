# Bicep

## Visión general

Bicep es un lenguaje específico de dominio (DSL) para desplegar recursos de Azure de forma declarativa. Es la alternativa oficial nativa de Azure a las plantillas ARM en JSON — compilando a ARM JSON antes del despliegue, pero con una sintaxis significativamente más limpia, mejor modularidad y herramientas nativas en VS Code.

Esta fase cubre la conversión del `template.json` existente (ARM) a un archivo Bicep usando `az bicep decompile`, corrigiendo los warnings de decompilación, y desplegando toda la infraestructura de daniellab desde el archivo `.bicep` resultante.

## Bicep vs ARM vs Terraform

| Característica       | ARM JSON     | Bicep      | Terraform    |
| -------------------- | ------------ | ---------- | ------------ |
| Sintaxis             | JSON verboso | DSL limpio | HCL          |
| Nativo de Azure      | ✅            | ✅          | ❌ (provider) |
| Multi-cloud          | ❌            | ❌          | ✅            |
| Archivo de estado    | ❌            | ❌          | ✅            |
| Decompilar desde ARM | N/A          | ✅          | ❌            |
| Madurez              | Alta         | Alta       | Alta         |

## Flujo

```
template.json (ARM)
    │
    │  az bicep decompile
    ▼
main.bicep
    │
    │  Corregir warnings + parámetros no usados
    ▼
main.bicep (limpio)
    │
    │  az deployment group create
    ▼
Infraestructura completa desplegada ✅
```

## Entorno

| Herramienta | Versión       |
| ----------- | ------------- |
| Azure CLI   | latest        |
| Bicep CLI   | latest        |
| Región      | francecentral |

---

## Paso 1 — Verificar instalación de Bicep

![Bicep Version](./screenshots/01_bicep_version.png)

```bash
az bicep version
```

CLI de Bicep confirmado como instalado y actualizado.

---

## Paso 2 — Decompilar plantilla ARM a Bicep

![Bicep Decompile](./screenshots/02_bicep_decompile.png)

```bash
az bicep decompile --file template.json
```

El decompilador convierte `template.json` en `template.bicep` automáticamente. El proceso genera warnings para:

* Parámetros no utilizados
* Recursos que no pudieron tiparse completamente
* Expresiones que requieren revisión manual

Estos warnings no bloquean el despliegue pero indican áreas donde el archivo Bicep puede optimizarse.

---

## Paso 3 — Revisar el archivo Bicep generado

![Bicep File Created](./screenshots/03_bicep_file_created.png)

El `template.bicep` generado contiene todas las definiciones de recursos de la plantilla ARM original traducidas a sintaxis Bicep. Diferencias clave respecto a ARM JSON:

* No se requieren cabeceras `"$schema"` ni `"contentVersion"`
* Las declaraciones de recursos usan la palabra clave `resource` en lugar de JSON anidado
* `dependsOn` se infiere automáticamente en la mayoría de los casos
* Parámetros y variables usan una sintaxis de asignación más limpia

---

## Paso 4 — Primer despliegue

![First Deploy](./screenshots/04_bicep_first_deploy-ok-but-no-optimal.png)
![First Deploy Portal](./screenshots/04_bicep_first_deploy-portal.png)

```bash
$resourceGroupName = "rg-daniellab-v3"
$location = "francecentral"
$templatePath = "C:\Users\estudio\Desktop\json\final\bicep\template.bicep"
$suffix = (Get-Date).ToString("yyMMddHH") # Genera un sufijo basado en la hora

Write-Host "Preparando el Grupo de Recursos..." -ForegroundColor Cyan
New-AzResourceGroup -Name $resourceGroupName -Location $location -Tag @{"Environment"="Lab"; "Proyecto"="Fase10"} -Force

$adminPassword = Read-Host "Introduce la contraseña para la VM" -AsSecureString

New-AzResourceGroupDeployment `
  -ResourceGroupName $resourceGroupName `
  -TemplateFile $templatePath `
  -adminPassword $adminPassword `
  -resourceNameSuffix $suffix `
  -Verbose
```

Primer despliegue completado con éxito. El portal confirma que todos los recursos se han creado. Los warnings sobre parámetros no utilizados estaban presentes en la salida pero no afectaron al resultado del despliegue.

---

## Paso 5 — Despliegue final (limpio)

```
$location = "francecentral"
$templatePath = "C:\Users\estudio\Desktop\json\final\bicep\finalbicep\files\main.bicep"
$suffix = (Get-Date).ToString("yyMMddHH")

$adminPassword = Read-Host "Introduce la contraseña para la VM" -AsSecureString

New-AzSubscriptionDeployment `
  -Location $location `
  -TemplateFile $templatePath `
  -adminPassword $adminPassword `
  -resourceNameSuffix $suffix `
  -Verbose
```

![Final Deploy 1](./screenshots/04_bicep_final%20deploy1.png)
![Final Deploy 2](./screenshots/04_bicep_final%20deploy2.png)

Despliegue final confirmado con todos los recursos aprovisionados correctamente y la infraestructura coincidiendo con los despliegues de ARM y Terraform de fases anteriores.

![Final Deploy](./screenshots/04_bicep-final-deploy.png)

---

## Warnings encontrados

| Warning                            | Causa                                                                          | Impacto                          |
| ---------------------------------- | ------------------------------------------------------------------------------ | -------------------------------- |
| Parámetros no usados               | El decompilador genera todos los parámetros del ARM; no todos se usan en Bicep | Ninguno — el despliegue funciona |
| Inferencia de tipo de recurso      | Algunos recursos no pudieron tiparse completamente                             | Ninguno — usa tipo genérico      |
| Expresiones que requieren revisión | Expresiones complejas de ARM traducidas literalmente                           | Ninguno — equivalencia funcional |

---

## Verificación

| Comprobación                                | Resultado |
| ------------------------------------------- | --------- |
| Decompile de Bicep completado               | ✅         |
| main.bicep generado desde template.json     | ✅         |
| Despliegue completado sin errores           | ✅         |
| Todos los recursos visibles en el portal    | ✅         |
| Infraestructura coincide con despliegue ARM | ✅         |
