# 03 — Web App Deployment Errors

## Overview

Errors encountered during App Service deployment, Key Vault integration and SQL connectivity configuration.

---

## Problem 1 — Deployment Timeout (HTTP 504)

**Symptom**
```
az webapp deploy → Status Code: 504
```

**Cause**
ZIP file (5.7MB) exceeded the default deployment timeout in App Service.

**Fix**
Add `--timeout 300` to the deploy command:
```bash
az webapp deploy --resource-group rg-daniellab \
  --name app-daniellab \
  --src-path app.zip \
  --timeout 300
```

**Lesson**
Large ZIP deployments to App Service require an explicit timeout parameter.

---

## Problem 2 — Malformed Connection String in Key Vault

**Symptom**
```
Keyword not supported: 'formacion8!!;trustservercertificate'
```

**Cause**
Password containing `!!` without single quotes caused the SQL connection string parser to interpret the special characters as part of a keyword instead of the password value.

**Fix**
Wrap the password in single quotes inside the connection string stored in Key Vault:
```
Server=tcp:10.0.1.4,1433;Database=DanielDB;User Id=sqladmin;Password='Formacion8!!';TrustServerCertificate=True
```

**Lesson**
Passwords with special characters must be wrapped in single quotes in SQL connection strings.

---

## Problem 3 — App Service Using Named Pipes Instead of TCP

**Symptom**
```
Named Pipes Provider, error: 40
Could not open a connection to SQL Server
```

**Cause**
Connection string did not specify the protocol explicitly. Without `tcp:` prefix, the Linux .NET driver attempted Named Pipes — which does not work for remote connections to Azure VMs.

**Fix**
Change the connection string to use explicit TCP with port:
```
// Before
Server=10.0.1.4

// After
Server=tcp:10.0.1.4,1433
```

**Lesson**
Always specify `tcp:` and the port number in connection strings targeting SQL Server on Azure VMs.

---

## Problem 4 — SQL Server in Windows Authentication Only Mode

**Symptom**
```
Login failed for user 'sqladmin'
IsIntegratedSecurityOnly = 1
```

**Cause**
SQL Server was installed in Windows Authentication Only mode. SQL logins (username/password) are not permitted in this mode.

**Fix**
Switch to Mixed Mode authentication:
```powershell
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQLServer" `
  -Name LoginMode -Value 2
Restart-Service MSSQLSERVER -Force
```

**Lesson**
SQL Server on Azure VMs requires Mixed Mode authentication when using SQL logins with a connection string.

---

## Problem 5 — web.config hostingModel Incorrect

**Symptom**
```
The specified CGI application encountered an error
```

**Cause**
`hostingModel="inprocess"` was failing in App Service. The in-process model requires specific configuration that was not present.

**Fix**
Change to out-of-process model via Kudu and enable stdout logging for diagnostics:
```xml
<aspNetCore processPath="dotnet"
            arguments="./app.dll"
            hostingModel="outofprocess"
            stdoutLogEnabled="true"
            stdoutLogFile="\\?\%home%\LogFiles\stdout" />
```

**Lesson**
`outofprocess` is more robust for initial diagnostics in App Service. Switch to `inprocess` only after confirming the app works correctly.

---

## Final Result

| Check | Result |
|---|---|
| ZIP deployed successfully | ✅ |
| Key Vault secret correctly formatted | ✅ |
| App Service connecting to SQL via TCP | ✅ |
| SQL Mixed Mode enabled | ✅ |
| Web app running at app-daniellab.azurewebsites.net | ✅ |
