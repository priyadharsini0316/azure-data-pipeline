# Security Design

**Status:** live prototype controls below are separately identified from production recommendations. Group-based SQL reporting access requires a reader login verification before removing the direct membership.

| Entra security group | Azure RG role | Azure SQL role | Purpose / live status |
|---|---|---|---|
| `grp-kpmg-admins` | Contributor | None | Administration; group and RG assignment created. |
| `grp-kpmg-developers` | Contributor | None | Prototype development; group and RG assignment created. |
| `grp-kpmg-support` | Reader | None | Resource monitoring; group and RG assignment created. |
| `grp-kpmg-report-readers` | None | `db_kpmg_reporting_reader` | Power BI reader is a group member; SQL group user and role membership verified. Effective reader-token query still pending. |

No individual members are added to the first three groups; their RBAC grants confer no access until an authorized owner assigns members. Azure RBAC does not grant Azure SQL data-plane SELECT. The reporting SQL role grants SELECT on `reporting` only. Do not remove the reader's direct SQL role membership until an actual reader-token query succeeds through the group (token refresh may be needed).

## Implemented prototype controls

- **Azure SQL:** use its public endpoint with public network access restricted to selected networks. Add only Priya's current public IP for administration and Power BI Desktop, plus the Azure-services server firewall exception required by ADF AutoResolve Azure IR. Do not create a broad internet CIDR rule. Require TLS, configure Microsoft Entra administration, create the ADF managed-identity database user, and grant only the schemas/procedures it needs.
- **ADF:** enable a system-assigned managed identity. Use it for SQL and Key Vault. Do not put connection passwords or secrets in `PipelineConfiguration`.
- **Key Vault:** Standard tier, public endpoint, selected firewall/trusted-service controls, Priya's current public IP for administration, Entra authentication, and least-privilege Azure RBAC. Store only the KPMG-requested service-principal demonstration secret and a Logic App callback secret if the connector design requires one.
- **Logic App:** Consumption workflow used only for operational messages. It cannot approve schema changes; `SchemaChangeApproval` in Azure SQL is authoritative.
- **Users:** assign permissions to Entra groups rather than individuals where practical. Business/external consumers use the local prototype report demonstration; direct SQL access is restricted to authorized technical identities.
- **Demo service principal:** use a short-lived client secret, store it in Key Vault, grant read-only reporting/demo access, never print it in logs/screenshots, and remove or disable it after evidence capture.
- **Audit:** retain pipeline/table run, schema history, RFC decision, and reconciliation records in Azure SQL. ADF Monitor supplies prototype execution telemetry.

## Known prototype trade-off

The Azure-services SQL firewall switch is broader than a dedicated private network path because the public Azure IR does not provide one fixed outbound IP. Managed identity, least-privilege SQL grants, TLS, and selected client-IP rules reduce—but do not remove—that network-level trade-off. This is acceptable only as an explicitly documented, reduced-cost prototype decision.

If organizational policy blocks this configuration, do not weaken the firewall or provision an excluded private endpoint. Stop and seek approval for a self-hosted integration runtime or private-network redesign.

## Secrets and configuration

Connection strings in ADF contain server/database references, not embedded credentials. The metadata table holds connection references, table names, load behavior, keys, watermarks, retry policy, and approved schema state—not secrets. Managed identity is preferred over the service principal for pipeline-to-Azure-resource access.

## Recommended for Production — Not Provisioned in Case-Study Prototype

Production should evaluate private endpoints for Azure SQL and Key Vault, Private DNS, isolated hub/spoke networking, NSGs, Azure Firewall, VPN Gateway or ExpressRoute, resilient SHIR nodes, Conditional Access/MFA policies, privileged identity management, centralized SIEM/Log Analytics, Defender plans, periodic access reviews, secret rotation automation, and separate Dev/Test/Integration/Prod identities and resources.

These are production recommendations only. The prototype does **not** provision SQL or Key Vault private endpoints, Private DNS, VPN Gateway, ExpressRoute, Azure Firewall, SHIR, paid Power BI capacity, or paid Fabric capacity.
