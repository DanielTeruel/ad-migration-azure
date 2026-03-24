# 🛠️ Errores de IaC y Plantillas ARM

### Problema: API Version Inexistente o No Disponible
- **Sintoma**: Error InvalidRestApiParameter al intentar desplegar recursos.
- **Causa**: Versiones de API obsoletas o no disponibles en la región seleccionada (ej. 2024-07-01 en France Central).
- **Solución**: Validar versiones estables (ej. 2024-05-01) y estandarizar en todos los recursos.

### Problema: Dependencia de Red (NIC antes que VNET)
- **Sintoma**: La NIC falla al crearse porque la VNET/Subnet aún no está lista.
- **Solución**: Añadir bloque "dependsOn" en el recurso de la Network Interface referenciando a la Virtual Network.

### Problema: Soft-delete en Key Vault
- **Sintoma**: Error ConflictError al intentar recrear un Key Vault con el mismo nombre.
- **Solución**: Realizar un Purge del Key Vault eliminado mediante Azure CLI antes de re-ejecutar el despliegue.
