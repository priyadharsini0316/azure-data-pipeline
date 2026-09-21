# Requirements Traceability

[← README](../README.md)

✅ done and verified live · 🟡 partly done or designed only

## Pipeline

| Requirement | Status | How | Evidence |
|---|---|---|---|
| Dynamic, config-driven pipeline | ✅ | Lookup → ForEach → one child pipeline | [ADF pipelines](EVIDENCE.md#data-factory) |
| `Load = Yes` rows loaded, `No` skipped | ✅ | Literal `Load` filter | [Config table](EVIDENCE.md#sql-results) |
| Initial and subsequent loads | ✅ | First-load detection; FULL / WATERMARK | [Runs 1–3](EVIDENCE.md#live-runs) |
| Step 1.1: create schema + RFC on first load | ✅ | Schema v1 + `INITIAL_LOAD` approval | [RFC table](EVIDENCE.md#sql-results) |
| Step 4: detect schema change | ✅ | SHA-256 column fingerprint | [RFC table](EVIDENCE.md#sql-results) |
| Step 4.2: alert + approval | ✅ | RFC `PENDING` + schema event reaches Logic App; Gmail action validated separately | [Alerts](EVIDENCE.md#notifications) |
| Step 5: approved → new schema | ✅ | `rfc.usp_DecideSchemaChange`, version 2 | [Curated](EVIDENCE.md#sql-results) |
| Step 5.1: rejected → old schema only | ✅ | Approved columns reused | [Run 5](EVIDENCE.md#live-runs) |
| Step 2: source vs Dev/Test match | ✅ | Gate 1 on `stg` | [Gates](EVIDENCE.md#sql-results) |
| Step 3: Dev/Test vs Integ/Prod match | 🟡 | Gate 2 `stg` vs `curated`, in one environment | [Gates](EVIDENCE.md#sql-results) |
| Step 3.1: success message | ✅ | `TABLE_SUCCESS` notification reaches Logic App; Gmail action validated separately | [Alerts](EVIDENCE.md#notifications) |
| Retry + alert on failure | ✅ | Retry ×3; `TABLE_FAILURE` notification reaches Logic App | [Run 6](EVIDENCE.md#live-runs) |
| Azure SQL + Data Factory | ✅ | Deployed with Bicep | [Resources](EVIDENCE.md#azure-resources) |
| Plain-English explanation | ✅ | README problem and solution sections | [README](../README.md#problem) |
| Call out process-flow issues | ✅ | 10 issues + fixes | [Design decisions](DESIGN_DECISIONS.md#issues-found-in-kpmgs-process-flow) |
| Screenshots of each step | ✅ | Evidence gallery | [EVIDENCE.md](EVIDENCE.md) |

## Access and control

| Requirement | Status | How | Evidence |
|---|---|---|---|
| Network configuration (VPN / Direct Connect) | 🟡 | Designed; prototype uses narrow public firewalls | [Architecture](ARCHITECTURE.md#production-design-not-provisioned) |
| IP addressing | 🟡 | Non-overlapping plan, not deployed | [IP plan](ARCHITECTURE.md#ip-address-plan-non-overlapping) |
| Firewalls | ✅ | SQL + Key Vault allow selected networks only | [Networking](EVIDENCE.md#azure-resources) |
| RBAC | ✅ | Group roles on the resource group; SQL database roles | [Key Vault IAM](EVIDENCE.md#identity-and-access) |
| IAM + MFA | ✅ | Entra-only SQL; security defaults on | [MFA](EVIDENCE.md#identity-and-access) |
| Security groups | ✅ | Admins, Developers, Support, Report readers | [Groups](EVIDENCE.md#identity-and-access) |
| Permissions to groups | 🟡 | Azure roles are evidenced for admin/developer/support groups; report-reader group-to-SQL-role mapping is not proven | [Key Vault IAM](EVIDENCE.md#identity-and-access) |
| Service principal via app registration | ✅ | Secret in Key Vault; reads `reporting` only | [App registration](EVIDENCE.md#identity-and-access) |
| Internal and external users | 🟡 | Read-only report user; external guests via Entra B2B (designed) | [Architecture](ARCHITECTURE.md#security) |
| Dev → Test → Integ → Prod | 🟡 | PR checks live; promotion designed | [CI/CD](CICD_PROMOTION.md) |
