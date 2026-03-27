# 04-iac — Infraestructura como Código

## Visión general

Esta sección cubre la implementación completa de **Infraestructura como Código** para el proyecto daniellab. Toda la infraestructura de Azure está definida, versionada y desplegable desde código — eliminando los clics manuales en el portal y permitiendo despliegues repetibles y auditables.

## Estructura

```
04-iac/
├── arm/          # Plantillas ARM — exportar, modificar, volver a desplegar
└── terraform/    # Terraform — IaC completo desde cero con HCL
```

## Enfoques Cubiertos

| Herramienta    | Enfoque                                                             | Caso de uso                              |
| -------------- | ------------------------------------------------------------------- | ---------------------------------------- |
| Plantillas ARM | Exportar infraestructura existente → modificar → volver a desplegar | IaC nativo de Azure, iteraciones rápidas |
| Terraform      | Escribir HCL desde cero → plan → apply → destroy                    | IaC multi-cloud, gestión de estado       |

## Qué Permite Esto

| Capacidad                                          | Resultado |
| -------------------------------------------------- | --------- |
| Infraestructura completa reproducible desde código | ✅         |
| Infraestructura controlada por versiones           | ✅         |
| Destruir y recrear en minutos                      | ✅         |
| Historial de cambios auditable mediante git        | ✅         |
| Portabilidad multi-cloud (Terraform)               | ✅         |
