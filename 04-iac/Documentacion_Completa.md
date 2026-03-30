![IAC](./screenshots/banner.png)

![Estado](https://img.shields.io/badge/Status-Complete-green)
![ARM](https://img.shields.io/badge/ARM-Template-orange)
![Bicep](https://img.shields.io/badge/IaC-Bicep-0078D4?logo=microsoft)
![Terraform](https://img.shields.io/badge/IaC-Terraform-7B42BC?logo=terraform)
![CI/CD](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-black?logo=github)

# 04 — Infraestructura como Código

## Visión general

Esta sección cubre la implementación completa de **Infrastructure as Code (IaC)** para el proyecto daniellab. Toda la infraestructura de Azure está definida, versionada y desplegable desde código — eliminando la necesidad de configuraciones manuales en el portal y permitiendo despliegues repetibles y auditables.

Se cubren tres enfoques en secuencia, cada uno construyendo sobre el anterior:

1. **ARM Template** — exportar la infraestructura existente para entender qué ha desplegado Azure, modificarla y redeplegarla como ejercicio de validación
2. **Terraform** — reescribir toda la infraestructura desde cero en HCL, gestionando el estado, importando recursos existentes y destruyendo/recreando el entorno
3. **Bicep** — reescribir la infraestructura usando IaC nativo de Azure, desplegando App Service, Key Vault y vm-sql01 desde un único `main.bicep`
4. **GitHub Actions** — automatizar el despliegue de la aplicación en App Service en cada `git push`, completando el ciclo completo de CI/CD

## Estructura

```
04-iac/
├── arm/          # ARM Template — exportar, modificar, redeplegar
├── bicep/        # Bicep — IaC nativo de Azure desde cero
├── terraform/    # Terraform — HCL desde cero, gestión de estado
└── cicd/         # GitHub Actions — workflow CI/CD para App Service
```

## Enfoques de IaC

| Herramienta    | Lenguaje     | Alcance                                     | Estado                              |
| -------------- | ------------ | ------------------------------------------- | ----------------------------------- |
| ARM Template   | JSON         | Exportación completa del entorno + redeploy | Sin estado                          |
| Bicep          | DSL de Bicep | VNet, App Service, Key Vault, vm-sql01      | Sin estado                          |
| Terraform      | HCL          | Entorno completo desde cero                 | Archivo de estado (backend azurerm) |
| GitHub Actions | YAML         | Deploy de App Service en git push           | —                                   |

## Decisiones de diseño

**¿Por qué ARM Template primero?**
La exportación sirvió como una instantánea completa de la infraestructura y como forma de entender qué había desplegado realmente Azure por debajo. También proporcionó una referencia concreta al reescribir desde cero en Bicep y Terraform. Empezar desde un export y luego reescribir desde cero demuestra tanto el resultado como el entendimiento detrás del mismo.

**¿Por qué Bicep y no solo Terraform?**
Bicep es nativo de Azure — no requiere gestionar un archivo de estado, tiene integración directa con ARM y tipado fuerte. Es la mejor opción cuando el alcance es únicamente Azure. Terraform se implementó en paralelo para demostrar portabilidad multi-cloud y conocimiento del ecosistema IaC más amplio.

**¿Por qué GitHub Actions para CI/CD?**
ZIP Deploy (usado en la Fase 6) se realizó primero para entender el flujo manual de despliegue de principio a fin. GitHub Actions automatiza ese mismo flujo — en cada `git push`, el workflow construye, testea y despliega la aplicación ASP.NET Core en App Service en 3–5 minutos.

## Qué permite esto

| Capacidad                                          | Resultado |
| -------------------------------------------------- | --------- |
| Infraestructura completa reproducible desde código | ✅         |
| Infraestructura versionada con git                 | ✅         |
| Destruir y recrear en minutos                      | ✅         |
| Historial de cambios auditable                     | ✅         |
| Portabilidad multi-cloud (Terraform)               | ✅         |
| Despliegue automático de aplicaciones en push      | ✅         |
| $0.00/día cuando no está en uso                    | ✅         |

## Documentación

| Carpeta                   | Contenido                                                           |
| ------------------------- | ------------------------------------------------------------------- |
| [arm](./arm/)             | Exportación ARM Template, modificación, validación, redeploy        |
| [bicep](./bicep/)         | Despliegue con Bicep desde cero — IaC nativo de Azure               |
| [terraform](./terraform/) | Terraform desde cero — HCL, gestión de estado, importación, destroy |
| [cicd](./cicd/)           | Workflow de GitHub Actions — build, test y deploy a App Service     |

## Estado

* [x] ARM Template — exportado, modificado, validado y redeplegado
* [x] Bicep — infraestructura completa desplegada desde main.bicep
* [x] Terraform — infraestructura completa desde cero, apply y destroy verificados
* [x] GitHub Actions — pipeline CI/CD activo, despliegue automático en git push
