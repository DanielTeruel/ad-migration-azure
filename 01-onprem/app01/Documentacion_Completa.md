

\# APP01 — Servidor de Aplicaciones



\## Descripción General



APP01 es el servidor de aplicaciones del dominio \*\*daniel.local\*\*, ejecutándose sobre \*\*Windows Server 2019\*\* con 2GB de RAM en VMware Workstation Pro 17. Aloja la aplicación web, la base de datos y los servicios de backup del entorno de laboratorio.



\## Roles del Servidor



!\[Roles del Servidor](./screenshots/app01-server-roles.png)



\- Internet Information Services (IIS)

\- ASP.NET Core 8

\- SQL Server Express 2022

\- Windows Server Backup (wbadmin)



\## Aplicación Web — IIS



!\[Bindings IIS](./screenshots/app01-iis-bindings.png)

!\[Ruta Física IIS](./screenshots/app01-iis-physical-path.png)

!\[Web Portfolio](./screenshots/app01-web-portfolio.png)



IIS sirve la aplicación web de portfolio personal sobre \*\*HTTPS en el puerto 443\*\*. El puerto 80 está cerrado siguiendo las mejores prácticas de hardening — reduciendo la superficie de ataque al no exponer un endpoint sin cifrar.



| Configuración | Valor |

|---|---|

| Protocolo | HTTPS |

| Puerto | 443 |

| Ruta física | C:\\inetpub\\wwwroot |

| Puerto 80 | Cerrado |



\*\*Destino de migración:\*\* Azure App Service (F1 Free)



\## Aplicación Web — ASP.NET Core 8



!\[Archivos ASP.NET](./screenshots/app01-aspnet-files.png)

!\[Versión .NET](./screenshots/app01-dotnet-version.png)



La aplicación web está construida sobre \*\*ASP.NET Core 8\*\*, conectando IIS con SQL Server Express mediante una arquitectura de 3 capas. La aplicación renderiza dinámicamente el contenido del portfolio (proyectos y certificaciones) desde la base de datos en lugar de tenerlo hardcodeado en HTML.

```

Usuario / WS001

&#x20;   │

&#x20;   │ HTTPS:443

&#x20;   ▼

┌─────────┐     ┌──────────────┐     ┌─────────────────┐

│   IIS   │────►│  ASP.NET 8   │────►│  SQL Server     │

│  :443   │     │  Program.cs  │     │  Express        │

└─────────┘     └──────────────┘     │  └─ DanielDB    │

&#x20;                                     └─────────────────┘

```



\*\*¿Por qué ASP.NET Core en vez de HTML estático?\*\*

Una página HTML estática no puede demostrar un escenario de migración realista. Al añadir un backend conectado a SQL Server, la aplicación se convierte en una carga de trabajo real de 3 capas — la misma arquitectura que se encuentra en entornos empresariales — haciendo que la migración a Azure App Service + Azure VM SQL Server sea significativa y defendible en una entrevista.



\*\*Destino de migración:\*\* Azure App Service (F1 Free)



\## Base de Datos — SQL Server Express



!\[SSMS DanielDB](./screenshots/app01-ssms-danieldb.png)

!\[Consulta Proyectos](./screenshots/app01-ssms-query-proyectos.png)

!\[Consulta Certificaciones](./screenshots/app01-ssms-query-certs.png)



\*\*SQL Server Express 2022\*\* aloja la base de datos \*\*DanielDB\*\*, que almacena el contenido del portfolio servido por la aplicación ASP.NET.



\### Estructura de la Base de Datos



| Tabla | Filas | Contenido |

|---|---|---|

| Proyectos | 3 | Proyectos del portfolio |

| Certificaciones | 4 | Certificaciones y formación |



\### Detalles de Conexión



| Configuración | Valor |

|---|---|

| Instancia | APP01\\SQLEXPRESS |

| Base de datos | DanielDB |

| Autenticación | Autenticación de Windows |

| IIS App Pool | IIS APPPOOL\\DefaultAppPool (db\_datareader) |



\*\*¿Por qué SQL Server Express y no Azure SQL Database directamente?\*\*

Ejecutar SQL Server on-premises simula un escenario realista de lift \& shift. Migrar la base de datos a una Azure VM con SQL Server (IaaS) demuestra el proceso de toma de decisiones entre los enfoques IaaS y PaaS — un tema clave en las migraciones empresariales y en las entrevistas de administrador de Azure.



\*\*Destino de migración:\*\* Azure VM B2s + SQL Server Developer 2022



\## Windows Server Backup



!\[Política WSB](./screenshots/app01-wbadmin-policy.png)

!\[Trabajo WSB](./screenshots/app01-wbadmin-job.png)

!\[Carpeta Backup](./screenshots/app01-backup-share.png)



Windows Server Backup (wbadmin) está configurado para hacer backup de todos los componentes de la aplicación diariamente a las \*\*02:00\*\*, almacenando el backup en el File Share de DC01 a través de la red.



\### Alcance del Backup



| Componente | Ruta |

|---|---|

| Aplicación web | C:\\inetpub\\wwwroot |

| Código fuente ASP.NET | C:\\inetpub\\DanielPortfolio |

| Exportación base de datos | C:\\temp\\DanielDB.bak |



\### Política de Backup



| Configuración | Valor |

|---|---|

| Programación | Diario a las 02:00 |

| Destino | \\\\DC01\\SharedFiles\\Backups\\APP01\\ |

| System State | No (backup ligero) |

| Último resultado | HResult = 0 ✅ |



\### Ruta del Backup en DC01

```

E:\\SharedFiles\\

└─ Backups\\

&#x20;   └─ APP01\\

&#x20;       └─ WindowsImageBackup\\

&#x20;           └─ APP01\\

&#x20;               └─ Backup YYYY-MM-DD\\ (diario)

```



\*\*¿Por qué excluir el System State?\*\*

El objetivo es un backup ligero de la aplicación — archivos web, código y base de datos. Un backup completo de System State incluiría toda la configuración del sistema operativo Windows, aumentando significativamente el tamaño y el tiempo del backup sin añadir valor para este escenario de recuperación específico.



\*\*Destino de migración:\*\* Recovery Services Vault + Agente MARS



\## Servicios en Ejecución



!\[Servicios Running](./screenshots/app01-services-running.png)



| Servicio | Estado | Tipo de Inicio |

|---|---|---|

| W3SVC (IIS) | Running | Automático |

| MSSQL$SQLEXPRESS | Running | Automático (Retrasado) |



\## Destinos de Migración



| Servicio | Herramienta | Servicio Azure |

|---|---|---|

| IIS + ASP.NET | ZIP Deploy | App Service (F1 Free) |

| SQL Server Express | Backup/Restore .bak | Azure VM B2s + SQL Server |

| Windows Server Backup | Agente MARS | Recovery Services Vault |

