# Requirements Traceability Matrix

Status reflects verified implementation, not intention.

| Requirement | Source/page | Implementation | Evidence/screenshot | Status | Notes |
|---|---|---|---|---|---|
| Dynamic pipeline | KPMG p1 | Lookup + ForEach + reusable child/procedure | ADF JSON; live runs | COMPLETE | No table-specific ADF pipeline |
| Config row with Load=Yes is eligible | KPMG p1/p3 | Literal `Load` filter | Config ID 1/2 processed; ID 3 No skipped | COMPLETE | Matches sample terminology |
| Initial and subsequent loads | KPMG p1 expected outcome | First schema/version; FULL/WATERMARK paths | First, incremental, rerun run IDs in deployment log | COMPLETE | Source rules are assumptions |
| Source schema changes | KPMG p1/p2 | Ordered metadata hash and RFC | RFC 1 approved, 2 rejected, 3 pending/breaking | COMPLETE | All changes require approval |
| Pending/rejected loads old schema | KPMG p2 steps 4.1/5.1 | Approved projection retained when safe | Pending/rejected live table-load audit SUCCESS | COMPLETE | New source column absent from target |
| Approval adopts schema | KPMG p2 RFC flow | `usp_DecideSchemaChange` and schema history | RegionCode appears after approval; version 2 | COMPLETE | SQL-backed workflow is a prototype choice |
| Breaking change safety | KPMG p2 | Missing approved column blocks table | Failed ADF run + 4 attempts + untouched target | COMPLETE | Independent table still succeeds |
| Data match Dev/Test and Integ/Prod | KPMG p2 | Prototype reconciliation gates | `audit.ReconciliationResult` | PARTIAL | One environment; topology documented |
| Success/failure and retry | KPMG p1 expected outcome | Retry=3, audits, Logic App notification | ADF failure/recovery and Logic run history | COMPLETE | Initial plus 3 retry attempts |
| Screenshots for setup | KPMG p1/p4 | Checklist and genuine Power BI capture | `screenshots/`; checklist | PARTIAL | Portal captures still require final user capture |
| Azure SQL or Fabric | KPMG p1 | Azure SQL + ADF | Deployed resource inventory | COMPLETE | Fabric not required |
| Network configuration | KPMG p4 | TLS public endpoints and narrow firewall for prototype | Azure firewall inventory | PARTIAL | VPN/private topology documented only |
| IP addressing | KPMG p4 | Single public-IP allow rule; production plan documented | SQL firewall evidence | PARTIAL | No VNet IP plan provisioned by approved cost choice |
| Firewalls/security groups | KPMG p4 | SQL/Key Vault firewalls; Azure RBAC | Resource configuration evidence | PARTIAL | NSG not applicable without VNet |
| RBAC/IAM/MFA/groups | KPMG p4 | Entra-only SQL, Azure RBAC, database roles; group/MFA design | Role assignments and SQL principals | PARTIAL | MFA/group lifecycle is tenant-admin configuration |
| Service principal/app registration | KPMG p4 | Short-lived reporting app identity | Reporting query allowed; curated denied | COMPLETE | Secret stored in Key Vault |
| Internal/external access | KPMG p4 | Power BI consumption assumption; technical SQL restriction | Security design and PBIP | PARTIAL | External method was not specified by KPMG |
| Power BI health reporting | User-approved design | Local PBIP over reporting views | PBIR validator 0 errors/warnings; Desktop binding screenshot | PARTIAL | Final data refresh/save and populated screenshot require Priya's organizational sign-in |
| Dev→Test→Integ→Prod | KPMG diagram/user decision | Parameterized IaC/artifacts and documented promotion | Architecture/deployment docs | PARTIAL | Reduced-cost single environment only |
| Private endpoints/VPN/ER/Azure Firewall | Production recommendation | Documented only | Security/architecture docs | NOT IMPLEMENTED | Explicitly excluded unless required; end-to-end works without them |

## Skeptical senior-engineer review

Likely challenges are watermark trust, hard-delete handling, generic datatype migration, concurrency on overlapping schedules, table-size scalability, public endpoints, Logic App callback-secret handling, lack of enterprise ITSM integration, and local-only Power BI. These are documented limitations, not hidden production claims.
