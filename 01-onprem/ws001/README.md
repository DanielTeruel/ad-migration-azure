\# WS001 — Client Machine



\## Overview



WS001 is the domain-joined client machine of the \*\*daniel.local\*\* domain, running \*\*Windows 10\*\* with 2GB RAM on VMware Workstation Pro 17. It simulates an end-user workstation used to verify domain policies, access to shared resources and web application connectivity.



\## Domain Join



!\[Domain Joined](./screenshots/ws001-domain-joined.png)



WS001 is joined to the \*\*daniel.local\*\* domain, managed by DC01.



| Setting | Value |

|---|---|

| Computer name | WS001 |

| Domain | daniel.local |

| Domain Controller | DC01 |

| OU | OU=Workstations,OU=DANIEL,DC=daniel,DC=local |



> \*\*Note:\*\* Hybrid Azure AD Join will be configured during the Azure migration phase, once Entra Connect sync is established.



\## Group Policy



!\[GPO Applied](./screenshots/ws001-gpo-applied.png)



The following GPOs are applied to WS001 via the \*\*OU=Workstations\*\* scope:



| GPO | Applied | Effect |

|---|---|---|

| Default Domain Policy | ✅ | Base domain settings |

| GPO-WSUS | ✅ | Points WS001 to WSUS on DC01:8530 |

| Deshabilitar almacenamiento USB | ✅ | Disables USB storage devices |

| Añadir usuario a grupo local Administrators | ✅ | Adds domain user to local admins |



\## WSUS — Windows Update



!\[WSUS Connection](./screenshots/ws001-wsus-connection.png)



WS001 receives Windows updates from WSUS running on DC01, port 8530. Confirmed connectivity and reporting to the \*\*Workstations\*\* group in WSUS console.



| Setting | Value |

|---|---|

| WSUS Server | http://DC01:8530 |

| WSUS Group | Workstations |

| AUOptions | 4 (Auto download and schedule install) |

| Port reachable | TcpTestSucceeded: True ✅ |



\## Access to Resources



\### Web Application



!\[Web Access](./screenshots/ws001-web-access.png)



WS001 successfully accesses the portfolio web application hosted on APP01 over HTTPS.



| Setting | Value |

|---|---|

| URL | https://192.168.75.5 |

| Protocol | HTTPS |

| Result | Portfolio page loads correctly ✅ |



\### File Share



!\[File Share Access](./screenshots/ws001-fileshare-access.png)



WS001 successfully accesses the shared folder on DC01.



| Setting | Value |

|---|---|

| Path | \\\\DC01\\SharedFiles |

| Result | Contents visible ✅ |



\## Post-Migration (Azure Phase)



The following will be configured during the Azure migration phase:



\- \*\*Hybrid Azure AD Join\*\* → WS001 joined to both daniel.local and Entra ID

\- \*\*Intune enrollment\*\* (optional) → device management from Azure

\- \*\*Entra ID SSO\*\* → single sign-on with synced credentials

