# 03-arc — Azure Arc

## Overview

Azure Arc onboarding for DC01 and APP01 is documented in full under:

**[02-azure-migrate/01-arc](../../02-azure-migrate/01-arc/README.md)**

That section covers the complete Arc onboarding process — script generation, agent installation on both servers, tag configuration, connectivity verification and the capabilities Arc enables (Update Manager, Defender for Cloud, Azure Policy).

## Why Arc Lives in 02-azure-migrate

Arc is the **hybrid onboarding mechanism** — it projects on-premises servers into Azure Resource Manager without migrating them. The process belongs to the migration phase (`02-azure-migrate`) rather than the Azure configuration phase (`03-azure`) because Arc is the first step taken before any Azure resource configuration begins.

The `03-arc` folder is retained in the repository structure for navigational consistency with the original lab design.
