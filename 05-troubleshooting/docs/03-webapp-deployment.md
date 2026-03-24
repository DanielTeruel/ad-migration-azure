# 🌐 Errores de SQL Server y Web App

### Problema: Named Pipes Provider (Error 40)
- **Sintoma**: App Service no puede conectar con SQL VM.
- **Causa**: SQL Server no configurado para aceptar conexiones remotas o puerto 1433 cerrado.
- **Solución**: Habilitar TCP/IP en SQL Configuration Manager y usar string de conexión: 	cp:10.0.1.4,1433.

### Problema: Named Pipes en Linux App Service
- **Causa**: El driver de Linux interpreta mal las barras invertidas en el string.
- **Solución**: Usar 	cp:IP,PUERTO en lugar de nombres de instancia.

### Problema: Deployment Timeout (HTTP 504)
- **Sintoma**: Error al subir el ZIP de la web.
- **Solución**: Añadir app setting SCM_COMMAND_IDLE_TIMEOUT = 300 en el App Service.
