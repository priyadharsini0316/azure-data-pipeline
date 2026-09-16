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
| Data match Dev/Test and Integ/Prod | KPMG p2 | Source-to-stg Gate 1 and stg-to-curated Gate 2 in the one-environment prototype | `sql/003_stored_procedures.sql`; live run IDs and gate counts in deployment log | PARTIAL | Two gates verified live, but no physical Dev/Test/Integ/Prod |
| Success/failure and retry | KPMG p1 expected outcome | Retry=3, audits, Logic App notification | ADF failure/recovery and Logic run history | COMPLETE | Initial plus 3 retry attempts |
| Screenshots for setup | KPMG p1/p4 | Checklist and genuine Power BI capture | `screenshots/`; checklist | PARTIAL | Portal captures still require final user capture |
| Azure SQL or Fabric | KPMG p1 | Azure SQL + ADF | Deployed resource inventory | COMPLETE | Fabric not required |
| Network configuration | KPMG p4 | TLS public endpoints and narrow firewall for prototype | Azure firewall inventory | PARTIAL | VPN/private topology documented only |
| IP addressing | KPMG p4 | Single public-IP allow rule; non-overlapping production CIDRs in security/architecture docs | Approved checkpoint IP plan; SQL firewall evidence | PARTIAL | Production VNet/subnets documented only |
| Firewalls/security groups | KPMG p4 | SQL/Key Vault firewalls; four Entra groups and scoped RG roles | Entra group member and RG role CLI checks; portal screenshots pending | PARTIAL | No NSG without VNet; report reader group SQL role granted but effective login pending |
| RBAC/IAM/MFA/groups | KPMG p4 | Entra-only SQL, RG group RBAC, reporting SQL group role | Group list/member, RG assignment, database role checks | PARTIAL | Reader login through group and MFA policy not independently verified |
| Service principal/app registration | KPMG p4 | Short-lived reporting app identity | Reporting query allowed; curated denied | COMPLETE | Secret stored in Key Vault |
| Internal/external access | KPMG p4 | Power BI consumption assumption; technical SQL restriction | Security design and PBIP | PARTIAL | External method was not specified by KPMG |
| Power BI health reporting | User-approved design | Local PBIP Overview enhanced with pending-schema/reconciliation/retry cards and flow caption; detailed SQL views deployed | `screenshots/powerBI/PowerBI_home.png` after refresh; PBIR validation 0 errors | PARTIAL | Detailed RFC/quality pages not authored; group-only reader test pending; schema URL unreachable warning |
| First-load RFC | KPMG p2 step 1.1 / user clarification | Approved INITIAL_LOAD request in revised procedure | Run `9d64382f-b1f2-11f1-a6a0-ec91616f91e2`; two APPROVED RFC rows with DecisionBy INITIAL_LOAD | COMPLETE | First load and both gates verified live |
| Notification email | KPMG p1/p2 success/schema alert; user enhancement | ADF/Logic App 202 response plus connected Gmail action | Test Logic run `08584120258021519282617111833CU16`: 202 response, Gmail 403 insufficient scopes | PARTIAL | No inbox proof; re-authorize with send-mail scope and retest |
| Pull-request CI checks | User enhancement | JSON, Bicep, static, gitleaks workflow | `.github/workflows/ci.yml`; GitHub PR #1 validate check success on head `d86a2f6` | COMPLETE | Recheck after the final Power BI/doc commit; PR must not merge without Priya's approval |
| Dev→Test→Integ→Prod | KPMG diagram/user decision | Parameterized IaC/artifacts and documented promotion | Architecture/deployment docs | PARTIAL | Reduced-cost single environment only |
| Private endpoints/VPN/ER/Azure Firewall | Production recommendation | Documented only | Security/architecture docs | NOT IMPLEMENTED | Explicitly excluded unless required; end-to-end works without them |

## Skeptical senior-engineer review

Likely challenges are watermark trust, hard-delete handling, generic datatype migration, concurrency on overlapping schedules, table-size scalability, public endpoints, Logic App callback-secret handling, lack of enterprise ITSM integration, and local-only Power BI. These are documented limitations, not hidden production claims.
