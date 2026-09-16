# Azure Resource Inventory and Implemented Prototype

Status: Deployed and validated on 2026-09-16. The YES rows below exist; the NO rows were confirmed absent from the resource group.

Cost classification: Azure SQL was verified live with `useFreeLimit=true` and exhaustion behavior `AutoPause`. ADF, Logic Apps, and Key Vault remain consumption/transaction cost-bearing; the final observed Cost Management amount still requires a portal capture after billing data settles.

## Final resource inventory

| Resource | Purpose | SKU/Tier | Region | Expected Cost Behavior | Required or Optional | Reason Required | Will Be Provisioned? YES/NO |
|---|---|---|---|---|---|---|---|
| Resource Group | Isolated lifecycle and cleanup boundary | N/A | Canada Central | No direct charge | Required | Keeps all prototype resources auditable and removable together | YES |
| Azure SQL Database | Synthetic source, configuration, state, staging, curated target, RFC, reconciliation, audit, and reporting views | **Azure SQL free offer; General Purpose serverless; Standard-series Gen5; `GP_S_Gen5_1`; 0.5 min/1 max vCore; 32 GB; 60-minute auto-pause; LRS backup; free-limit behavior `AutoPause`** | Canada Central, subject to free-offer availability | Target $0 inside the monthly free allowance: 100,000 vCore-seconds, 32 GB data, and 32 GB backup. Auto-pauses until the next month at exhaustion; never select paid continuation. Open connections consume the allowance. | Required | Core relational source/control/target needed for every case-study scenario | YES |
| Azure Data Factory | Metadata-driven orchestration, Lookup, ForEach, Copy, schema checks, retries, reconciliation calls, and notifications | V2; Azure Integration Runtime (`AutoResolveIntegrationRuntime`); no Mapping Data Flow/Spark | Canada Central | Consumption-based activity/orchestration/data-movement charges; small but not guaranteed free. Keep runs/data tiny and stop triggers after evidence. | Required | Implements KPMG's dynamic pipeline | YES |
| Azure SQL Private Endpoint | Production network isolation | Private Link | N/A | Cost-bearing if created | Excluded | User explicitly prohibited it; prototype uses selected public network/firewall controls | **NO** |
| Azure Key Vault | Store only the short-expiry reporting service-principal demo secret and Logic App callback secret if SAS-based invocation is used | Standard | Canada Central | Transaction-based; expected to be negligible for a handful of secret create/get operations, but not guaranteed free | Required | Managed identity removes SQL credentials, but it cannot eliminate the KPMG-required client-secret demo; secrets must not enter Git/configuration | YES |
| Azure Key Vault Private Endpoint | Production network isolation | Private Link | N/A | Cost-bearing if created | Excluded | User explicitly prohibited it; Key Vault uses secured public endpoint, firewall/trusted-service controls, Entra authentication, and RBAC | **NO** |
| Private DNS | Production private-endpoint name resolution | Private DNS Zones | N/A | Cost-bearing if created | Excluded | No private endpoints in prototype and user explicitly prohibited Private DNS | **NO** |
| Logic App | Required success, failure-after-retries, schema-change, and rejection notifications; SQL remains approval authority | Consumption, multitenant | Canada Central | Pay per trigger/action/connector call; published pricing includes a small action allowance but connector calls can still be metered. Execute only demo events. | Required | Page 2 explicitly shows success and schema messages; SQL-only audit does not demonstrate outbound notification | YES |
| Log Analytics | Centralized diagnostics/querying | Pay-as-you-go | Canada Central | Ingestion and retention can incur cost | Optional, not justified for MVP | ADF Monitor plus Azure SQL audit/reconciliation tables provide enough prototype observability | **NO** |
| Storage Account | File landing/staging | Standard LRS if ever required | Canada Central | Storage and transaction charges | Optional, not justified | SQL-to-SQL prototype requires no file landing or Mapping Data Flow staging | **NO** |
| Power BI/Fabric Capacity | Cloud publishing/sharing/capacity | Paid Power BI/Fabric capacity | N/A | Licence/capacity cost | Excluded | User explicitly prohibited paid capacity; local Power BI Desktop is sufficient | **NO** |
| Power BI Desktop | Local pipeline-health report | Installed desktop application | Local workstation | No Azure capacity provisioned; local Desktop usage only | Required for report demo | Demonstrates curated Azure SQL/reporting data locally | YES (LOCAL ONLY) |
| Microsoft Entra app registration/service principal | Page-4 workload-identity demonstration | Entra application | Tenant/global | No standalone Azure resource charge expected; tenant licensing can affect advanced governance | Required | KPMG explicitly requests app registration/service principal and secret-based application access | YES |
| VNet / NSG | Production network segmentation | N/A | N/A | No direct base charge, but unnecessary here | Not required | Without private endpoints or SHIR, a prototype VNet does not sit in the ADF-to-SQL data path and would be misleading evidence | **NO** |
| VPN Gateway / ExpressRoute / Azure Firewall / on-prem SHIR | Enterprise on-premises connectivity and inspection | Production-specific | N/A | Potentially material recurring cost | Production only | Synthetic Azure SQL source removes the prototype dependency | **NO** |

## Verified Azure SQL selection

The live database reports the following:

1. `useFreeLimit=true`.
2. General Purpose serverless `GP_S_Gen5`, capacity 1, minimum capacity 0.5.
3. Maximum data size 32 GB.
4. Auto-pause delay 60 minutes.
5. Free-limit exhaustion behavior `AutoPause`.

The guard remains in Bicep so a future environment must not silently choose a paid SKU.

## Public-endpoint connectivity controls

- Azure SQL: public network enabled with selected firewall access; add only Priya's current public IPv4 rule for local tools/Power BI Desktop. Enable the Azure-services firewall exception only because public Azure Integration Runtime needs a reachable endpoint. Keep Entra/managed-identity authentication and contained least-privilege database permissions. Do not add `0.0.0.0/0` or broad internet ranges.
- Key Vault: Standard vault, public endpoint, Azure RBAC permission model, Priya's public IP for administration, and trusted Microsoft services bypass as required for ADF managed-identity access. Only the specific ADF identity receives `Key Vault Secrets User`; only the setup identity receives controlled secret-management access.
- ADF: system-assigned managed identity; Azure SQL contained user with only required source/control/staging/curated/audit/RFC procedure permissions; no SQL username/password.
- Logic App: minimal Consumption workflow. Store a callback/SAS URL in Key Vault if used; otherwise prefer Entra-authenticated invocation. Never write callback URLs or tokens to source control or screenshots.

## Cost controls and cleanup

- Do not upgrade the Azure Free Account or change its spending limit/billing offer.
- Do not enable Microsoft Defender paid plans, geo-redundant backup, paid SQL overage, Mapping Data Flow, Fabric capacity, Power BI capacity, or Log Analytics for the MVP.
- Use small synthetic tables, bounded ForEach concurrency, manual triggers, and only the runs required for evidence.
- Close SQL clients/Object Explorer after use so serverless auto-pause can occur.
- Add a free-amount-remaining alert if offered at no charge and verify consumption before each demo batch.
- Disable ADF triggers after testing. Consumption services with no executions produce no workflow activity charges, but every actual action/call can be metered.
- Cleanup is separately authorized. Never delete automatically; first export screenshots/audits and obtain Priya's explicit deletion approval.
