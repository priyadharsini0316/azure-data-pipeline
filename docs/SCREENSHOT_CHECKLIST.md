# Screenshot Checklist

Never fabricate evidence. Redact tenant/subscription/object IDs, personal IP/email, callback URLs, and all secret values. CLI/SQL evidence is already verified, but the KPMG submission should include the selected human-readable portal screens below.

| Status | Screen to open | Capture/action | What it proves |
|---|---|---|---|
| NEEDED | Azure portal → resource group `rg-kpmg-kpmg-prototype` | Resource list and tags | Only approved prototype services exist |
| NEEDED | Azure SQL DB → Compute + storage | SKU, 0.5–1 vCore, 32 GB, auto-pause, free-limit behavior | Cost guardrails |
| NEEDED | SQL server → Networking | Current-IP and Azure-services rules; redact IP | Prototype connectivity control |
| NEEDED | SQL server → Microsoft Entra ID | Admin configured; redact identifiers | Entra-only administration |
| NEEDED | Data Factory → Identity | System-assigned identity On | Secretless ADF runtime |
| NEEDED | Key Vault → Access control + Networking | ADF Secrets User; default deny/trusted services | RBAC and firewall posture |
| NEEDED | Entra → App registrations | Reporting app and credential expiry; never open value | Page-4 service-principal pattern |
| NEEDED | ADF Studio → Manage → linked services | SQL managed identity and Key Vault link | Runtime authentication |
| NEEDED | ADF Studio → Author → MasterMetadataDriven | Lookup, ForEach, child, finalizer | Dynamic orchestration |
| NEEDED | ADF Studio → Author → ProcessConfiguredTable | Stored procedure, retry=3, notification path | Reusable table processing and retry |
| NEEDED | ADF Monitor → run `8779155c-b184-11f1-b82e-ec91616f91e2` | Successful first-load activities | Initial load |
| NEEDED | SQL query window | Config rows 1/2 Yes, row 3 No; target/reconciliation results | Eligibility and skipped row |
| NEEDED | ADF Monitor + SQL results | Incremental `e983...` and rerun `3362...`, target 4 rows/4 keys | Incremental and idempotency |
| NEEDED | SQL RFC/schema history/target | RFC 1 APPROVED, version 2, RegionCode present | Approved schema adoption |
| NEEDED | SQL RFC/audit/target | RFC 2 REJECTED, TemporaryNote absent | Rejected old-projection behavior |
| NEEDED | ADF Monitor → run `988dee6f-b189-11f1-ab19-ec91616f91e2` | Failed master and failed child beside successful child | Retry, isolation, truthful failure |
| NEEDED | SQL audit | Same run PARTIAL_SUCCESS, 1 success/1 failure, 4 attempts for config 2 | Retry-aware audit aggregation |
| NEEDED | ADF Monitor → recovery run | Both tables succeeded after restore | Restartability |
| NEEDED | Logic App → Run history | Successful notification runs; do not expose callback | Notification execution |
| IN PROGRESS | Power BI Desktop → `KPMG Pipeline Health.pbip` | Click Refresh now, organizational account, then capture populated page | Local health reporting |
| COMPLETE | `screenshots/powerbi-pipeline-health.png` | Current genuine Desktop capture | PBIP opens and visuals bind; this pre-refresh image is not final submission evidence |
| NEEDED | Azure Cost Management → Cost analysis | Resource-group filtered cost | Observed prototype cost, not an estimate |

No screenshot should claim Private Endpoints, VNet/NSG, VPN/ExpressRoute, Azure Firewall, SHIR, Log Analytics, Storage, separate environments, or paid Power BI/Fabric capacity; those were not provisioned.

📸 SCREENSHOT NEEDED (Priya): four KPMG security groups — Entra ID → Groups → All groups, filter grp-kpmg — group names visible; redact object IDs.

📸 SCREENSHOT NEEDED (Priya): Power BI reader group membership — Entra ID → Groups → grp-kpmg-report-readers → Members — reader account visible; redact identifiers.

📸 SCREENSHOT NEEDED (Priya): resource-group role assignments — rg-kpmg-kpmg-prototype → Access control (IAM) → Role assignments — admin/developer Contributor and support Reader; no report-reader RG assignment.
