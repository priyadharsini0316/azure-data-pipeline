# KPMG Pipeline Interview Master Guide

This is the main learning entry point. It teaches the finished prototype from zero and links to the authoritative implementation instead of duplicating it.

## If you have only X hours

### 2-hour crash prep

1. Read [README](../README.md): problem, solution, two diagrams and live results — 20 minutes.
2. Read this guide: “one simple story,” metadata, watermark, two gates, schema approval, security and limitations — 55 minutes.
3. Read [INTERVIEW_CHEAT_SHEET.md](INTERVIEW_CHEAT_SHEET.md) — 20 minutes.
4. Rehearse the 10-minute flow in [PRESENTATION_RUNBOOK.md](PRESENTATION_RUNBOOK.md) — 15 minutes.
5. Answer Level 2 and Level 5 questions in [MOCK_INTERVIEW_QUESTION_BANK.md](MOCK_INTERVIEW_QUESTION_BANK.md) aloud — 10 minutes.

### 1-day prep

Follow the crash prep, then study the actual control flow in `adf/` and `sql/003_stored_procedures.sql`, replay all seven scenarios from [EVIDENCE.md](EVIDENCE.md), and rehearse the 15-minute presentation twice.

### Full end-to-end prep

Read in this order: case pages → README → this guide → actual SQL/ADF → evidence → security/architecture → CI/CD → question bank → runbook. Finish by drawing the architecture, watermark window and schema-approval state machine from memory.

## Vocabulary used in this guide

- **KPMG REQUIREMENT** — explicitly present in the supplied case.
- **IMPLEMENTED PROTOTYPE** — verified in code and/or live evidence.
- **OUR DESIGN DECISION** — a choice made to fill a gap in the case.
- **OUR ASSUMPTION** — needed because the case did not specify it.
- **PRODUCTION RECOMMENDATION** — documented but not deployed.
- **KNOWN LIMITATION** — honest boundary of the prototype.

---

## 1. The business problem, page by page

### Page 1

**KPMG REQUIREMENT:** build a dynamic pipeline for source tables whose schemas may change. A row in a configuration table with `Load = Yes` is eligible. Handle first and subsequent loads, success and failure, retry or alert, explain the solution simply and document it with screenshots. Azure SQL + ADF or Fabric are allowed; Fabric is recommended, not mandatory.

Why a static pipeline is insufficient: a static pipeline hard-codes one table and one column mapping. Every added table or changed column would require pipeline editing and redeployment. A metadata-driven pipeline reads instructions as data, so the same orchestration can process multiple tables.

### Page 2

The supplied flow asks:

1. Is this the first load?
2. If first, create the schema/load Dev-Test and initiate RFC work.
3. If subsequent, did Source Prod schema change from the last load?
4. If changed, alert and obtain approval.
5. If approved, adopt the schema; otherwise send a schema-change message and load only the old schema.
6. Compare Source vs Dev/Test, then Dev/Test vs Integ/Prod.
7. Fix mismatches; send success only after matching.

**OUR DESIGN DECISION:** because the diagram does not define a durable “waiting” state, an RFC is stored as `PENDING`; the run continues with the last approved columns when that projection is still possible. This follows the old-schema Step 4.1/5.1 behavior without holding an ADF run open for human action.

### Page 3

The sample configuration contains table, columns, `Load`, connection parameters and room for more metadata. It is illustrative, not a complete mandated schema. Our actual table is `ctl.PipelineConfiguration` in [sql/001_create_framework.sql](../sql/001_create_framework.sql).

### Page 4

**KPMG REQUIREMENT:** describe secure on-premises-to-cloud networking, non-overlapping IP design, firewalls/security groups, RBAC, IAM/MFA, role-based groups and a service principal/app registration.

**IMPLEMENTED PROTOTYPE:** Entra-only SQL, ADF managed identity, RBAC-enabled Key Vault, resource firewalls, four security groups, service-principal demonstration and a report user.

**PRODUCTION RECOMMENDATION:** VPN/ExpressRoute, hub VNet, private endpoints, private DNS, Azure Firewall/NSGs and separate environments. These were not provisioned.

Full mapping: [REQUIREMENTS_TRACEABILITY_MATRIX.md](REQUIREMENTS_TRACEABILITY_MATRIX.md).

---

## 2. The whole solution as one simple story

```text
Synthetic relational source
        ↓
Configuration: Load = Yes
        ↓
ADF Lookup → ForEach → child pipeline
        ↓
Schema fingerprint and RFC decision
        ↓
Approved columns copied to stg
        ↓
Gate 1: source window vs staging
        ↓
Transactional publish to curated
        ↓
Gate 2: staging vs curated
        ↓
Audit + notification event
        ↓
Logic App and Power BI reporting views
```

### 30-second explanation

“I built one metadata-driven ADF framework over Azure SQL. A Lookup reads every configuration row marked Yes, a ForEach calls the same child pipeline, and SQL performs schema approval, staging, two reconciliation gates and an atomic publish. Watermarks make incremental runs restartable. A schema change creates an RFC; pending or rejected changes keep the last approved columns, while breaking changes fail only that table. Audit views feed a Power BI health page, and Logic Apps handle notifications.”

### 2-minute explanation

Add four points: the source is synthetic because KPMG supplied no business data; first load creates version 1 with an `INITIAL_LOAD` approval; incremental windows use `> old watermark AND <= captured watermark`; and the prototype uses one low-cost environment while production would use private networking and Dev/Test/Integ/Prod promotion.

### 5-minute technical explanation

Walk left-to-right through [ARCHITECTURE.md](ARCHITECTURE.md), name the seven SQL schemas, explain ADF’s master/child split, demonstrate Gate 1 and Gate 2, then finish with identity, evidence, limitations and production changes. Use [PRESENTATION_RUNBOOK.md](PRESENTATION_RUNBOOK.md) for exact timing.

---

## 3. Architecture components

| Component | What it is / why | Project role | Alternative / limitation |
|---|---|---|---|
| Azure SQL Database | Managed relational database | Holds source, metadata, stage, curated, RFC, audit and reporting views | One DB simulates environments; not a large-scale lakehouse |
| Azure Data Factory | Managed orchestration service | Lookup, ForEach, child execution, retries, Key Vault call and notification Web activities | Fabric pipelines or Databricks Workflows at other scale/context |
| Stored procedures | Server-side SQL routines | Own atomic load and validation logic | Concentrates complexity in SQL but makes transactions clear |
| Key Vault | Secret store with RBAC | Stores Logic App callback and prototype SP secret | SP secret expired; managed identity is preferred |
| Logic App Consumption | Event workflow billed per use | Accepts HTTP event, returns 202, optional Gmail send | SQL delivery status is not updated; ADF→Gmail is not captured end-to-end |
| Entra ID | Cloud identity provider | Users, groups, managed identity, service principal, MFA/security defaults | Conditional Access/PIM are production recommendations |
| Azure RBAC | Azure resource authorization | Group roles and Key Vault roles | Separate from SQL database roles |
| SQL roles | Database authorization | `db_kpmg_pipeline_executor`, `db_kpmg_reporting_reader` | Report-reader group mapping is not proven in repo/evidence |
| Power BI Desktop | Reporting tool | Imports three reporting views into one operational `Overview` page | Not published to paid capacity; no business report |
| Bicep | Declarative Azure IaC | SQL, ADF, Key Vault and base Logic App | Some Entra/Gmail/report setup was manual or separate |
| GitHub Actions | CI runner | Validates pull requests without cloud deployment | CD is designed only |

Why ADF + Azure SQL here: the case explicitly permits it, the sample is small and relational, transactional gates and audit are easy to demonstrate, and it avoids Fabric/Databricks capacity and operational overhead. It is not universally best. Choose Fabric when OneLake/capacity and an integrated analytics estate already exist; Databricks for large/semi-structured/streaming/ML workloads; Synapse for an existing Synapse estate; custom Python for specialized orchestration that justifies owning runtime/operations.

---

## 4. Metadata-driven pipeline

**Metadata** is data that describes how other data should be processed. Here, one row tells the framework what source/target to use, whether to load it, how to identify rows, and what schema is approved.

### Actual configuration columns

`ConfigId`, `SourceSchema`, `SourceTable`, `TargetSchema`, `TargetTable`, `Load`, `LoadType`, `WatermarkColumn`, `PrimaryKeyColumn`, `ConnectionReference`, `RetryCount`, `RetryIntervalSeconds`, `ApprovedColumnList`, `ApprovedSchemaHash`, `ApprovedSchemaVersion`, `LastWatermarkValue`, `LastRunStatus`, `LastSuccessfulRunUtc`, `CreatedUtc`, `ModifiedUtc`.

Example: `src.Asset_Generation_PI_Data_T` → `curated.Asset_Generation_PI_Data_T`, `Load=Yes`, `LoadType=WATERMARK`, key `AssetGenerationId`, watermark `LastModifiedUtc`.

ADF flow:

1. `Lookup enabled configuration` runs `WHERE [Load]='Yes'`.
2. `ForEach enabled table` processes up to two rows in parallel.
3. `Execute table framework` passes `ConfigId` and parent run ID to the same child pipeline.
4. The child calls `ctl.usp_ProcessConfiguredTable`.
5. The procedure re-reads the row and uses `QUOTENAME` for object/column names.

`adf/dataset_DynamicAzureSqlTable.json` is a parameterized dataset: `SchemaName` and `TableName` are expressions rather than fixed object names. In the current pipelines it is used for the configuration and notification Lookups. The actual table copy is performed by the generic SQL procedure, so the ADF child remains table-independent.

Adding a conforming new table requires the source object plus one configuration row; no ADF pipeline redeployment. `Load=No` means Lookup excludes it.

Important honesty:

- `ConnectionReference`, `RetryCount` and `RetryIntervalSeconds` exist, but the prototype uses one fixed linked service and hard-coded ADF retry `3` / `15` seconds.
- Secrets do not belong in this table. Store secret material in Key Vault; store only a connection reference in metadata.
- At hundreds of tables, validate metadata, control `batchCount`, use workload classes/partitioning, and prevent overlapping runs per `ConfigId`.

---

## 5. First load

First load means no approved schema hash exists for the configuration row.

Actual sequence:

1. Read the current source columns and types from `sys.columns`.
2. Build a schema definition and SHA-256 hash.
3. Set approved columns/hash/version 1.
4. Insert `rfc.SchemaHistory` version 1.
5. Insert an `APPROVED` `SchemaChangeRequest` with `DecisionBy='INITIAL_LOAD'`.
6. Create/align `stg` and `curated` tables from approved columns.
7. Load stage, pass Gate 1, publish in a transaction, pass Gate 2.
8. Initialize the watermark and audit success.

Why automatic initial approval? **OUR DESIGN DECISION:** the prototype needs a baseline before it can compare future changes. It records the baseline as an auditable approval. KPMG requires first-load schema creation/RFC work but does not explicitly mandate automatic approval.

Concrete evidence: first-load run ID and screenshots are in [EVIDENCE.md](EVIDENCE.md). The source/config definitions are in `sql/002_sample_source.sql`; RFC/audit/reconciliation rows are shown under SQL evidence.

Concrete trace for the watermark sample:

| Stage | Actual example |
|---|---|
| Source row | `AssetGenerationId=1`, `AssetCode=SOLAR-01`, `GenerationMWh=125.500`, `ReadingDate=2026-09-13`, `LastModifiedUtc=2026-09-13 10:00Z` |
| Config row | `src.Asset_Generation_PI_Data_T` → `curated.Asset_Generation_PI_Data_T`; `Load=Yes`; `WATERMARK`; key `AssetGenerationId`; watermark `LastModifiedUtc` |
| Stage | The three initial approved source rows are copied to `stg.Asset_Generation_PI_Data_T` |
| Curated | The same three keys are published to `curated.Asset_Generation_PI_Data_T` after both gates |
| RFC/history | Version 1 is recorded as the `INITIAL_LOAD` baseline and approved schema history |
| Audit | One table-attempt row records counts/status; the master run aggregates table outcomes |
| Reconciliation | Gate 1 and Gate 2 checks record PASS for count/key/schema conditions |

The repository seeds source/config values; the exact live RFC/audit identifiers are environment-generated and belong in evidence, not memorization.

---

## 6. Incremental watermark load

A watermark is the latest modification timestamp safely processed.

If the previous watermark is 10:00, rows at 09:55, 10:05 and 10:10 produce a delta of 10:05 and 10:10.

The prototype first captures `MAX(LastModifiedUtc)`—for example 10:10—then selects:

```text
LastModifiedUtc > 10:00
AND LastModifiedUtc <= 10:10
```

Why capture the maximum before the load? If a row arrives at 10:12 during processing, it is deliberately outside this run and will be picked up next time. Without a fixed upper bound, the query and watermark could observe different sets and silently skip a row.

- Zero-row delta is a valid success.
- The watermark advances only inside the same transaction as successful publish/Gate 2.
- A failure rolls back publish and watermark together.
- Delta publish deletes matching target keys then inserts staged rows, so reruns do not duplicate keys.
- Late records with a modification timestamp **older than or equal to** the stored watermark can be missed.
- Hard deletes are not propagated for `WATERMARK` tables.

Production delete options: CDC, Change Tracking, soft-delete flag, source change feed or tombstone/audit table.

---

## 7. Staging

Staging is a temporary landing area between source and consumer-facing curated data. Each configured target uses `stg.<TargetTable>`.

- `FULL`: truncate stage, copy all approved columns; curated is replaced in a transaction.
- `WATERMARK`: truncate stage, copy only the bounded delta; matching curated keys are replaced.
- Added approved columns are created in stage/curated as nullable.
- Pending/rejected unapproved columns are not projected.

Without staging, validation would occur while modifying curated data, exposing partial/bad results and making rollback harder.

Known concurrency limitation: the stage table is shared per configured target. Different `ConfigId` values are safe, but overlapping master runs for the same `ConfigId` are not explicitly prevented by the checked-in ADF JSON.

---

## 8. Data quality and reconciliation

### Gate 1 — Source/load window vs staging

Checks source-window row count = stage row count, duplicate primary keys = 0, null primary keys = 0, and all previously approved source columns still exist. It runs before publish, so a failure leaves curated untouched and the watermark unchanged.

### Gate 2 — Staging vs curated

Checks every staged key exists in curated, duplicate target keys = 0, null target keys = 0, and for FULL/first loads stage row count = target row count.

Why Gate 2 if Gate 1 passed? Gate 1 proves ingestion; Gate 2 proves publishing. A correct stage can still be published incorrectly.

Transaction in plain English:

```text
TRY
  BEGIN TRANSACTION
  publish
  calculate Gate 2 checks
  if good: update watermark and COMMIT
CATCH
  ROLLBACK
  write audit failure outside the rolled-back work
```

Gate 2 check rows are first held in a table variable, then written after rollback in `CATCH`, so failure evidence survives. The rollback path is code-reviewed but was not deliberately triggered live.

Not implemented: value-level checksums, domain/business rules, referential integrity across tables or statistical anomaly detection.

---

## 9. Schema change management

The procedure fingerprints ordered column name, type, length, precision, scale and nullability. A different hash means the source shape changed.

Example:

```text
v1: AssetId, AssetName, AssetType, IsActive, LastModifiedUtc
v2: AssetId, AssetName, AssetType, IsActive, LastModifiedUtc, RegionCode
```

State flow:

```text
different hash → RFC PENDING → old approved projection loads
                           ├─ APPROVED → version increments; next run adds/loads column
                           └─ REJECTED → old version stays active; new column ignored
```

All changes require approval in this prototype—even a safe nullable addition.

Actual behaviors:

- Added column: old projection is safe; pending/rejected load continues; approved column is added nullable.
- Removed or renamed approved column: old projection cannot execute; Gate 1 records failure and only that table fails.
- Type/nullability change: detected by hash, but existing target columns are not altered. Compatible reads may continue with the old target definition; incompatible changes can fail. Approval does not magically solve target type migration.
- Historical rows receive `NULL` for newly approved additive columns unless backfilled.

Auto-accepting safe nullable additions is a future optimization, not implemented behavior.

---

## 10. RFC approval

Actual table: `rfc.SchemaChangeRequest`.

Actual fields include `SchemaChangeRequestId` (the RequestId), `ConfigId` (join to obtain source object), detected/previous hashes, detected columns/definition, summary, compatibility, status, detected/decision timestamps, decision user and notes. `SourceObject` is exposed by the reporting view, not stored directly in the RFC table.

- `PENDING`: no decision yet.
- `APPROVED`: `rfc.usp_DecideSchemaChange` writes a new schema-history version and updates config.
- `REJECTED`: old approved version remains.
- `INITIAL_LOAD`: compatibility label and decision identity used for the automatically established baseline.

SQL was chosen because it is simple and auditable for a prototype. Production would integrate ServiceNow, Jira, Azure DevOps or another client ITSM approval workflow.

---

## 11. Retries and failure handling

The child stored-procedure activity has `retry: 3`, meaning one original attempt plus three retries—four audit attempts. ADF retries every procedure failure; it does not classify transient vs permanent failures.

Each configured table runs in its own child pipeline. In the breaking-change demo, one table failed four times while the other succeeded. The parent audit became `PARTIAL_SUCCESS`, and `usp_FinalizePipelineRun` then throws so ADF monitoring visibly reports failure.

Restartability comes from transactional publish, unchanged watermark on failure, and key-based replacement. One table’s transaction does not corrupt another table.

Notification distinction:

- `TABLE_FAILURE` describes load failure.
- `SCHEMA_CHANGE` describes detected schema state; ADF derives pending/rejected status for the payload.

Known limitations: permanent schema errors are retried unnecessarily; retry metadata is not consumed per table; SQL `NotificationAudit` can contain one row per failed attempt; and external email deduplication is not implemented.

---

## 12. Audit and observability

| Table | Purpose |
|---|---|
| `audit.PipelineRunAudit` | One master-run summary, counts and final status |
| `audit.TableLoadAudit` | One table attempt; retries create multiple rows |
| `audit.ReconciliationResult` | Gate/check-level PASS/WARNING/FAIL evidence |
| `audit.NotificationAudit` | Events for ADF/Logic App pickup |
| `rfc.SchemaHistory` | Approved versions and effective history |
| `rfc.SchemaChangeRequest` | Human decision record |

This gives the prototype durable, queryable operational history without Log Analytics. Production Log Analytics would add cross-service logs, KQL alerts, retention controls, dashboards and centralized incident correlation.

Fields `RowsInserted`/`RowsUpdated` are not populated, and `NotificationAudit.DeliveryStatus` is not updated after Logic App execution. Say this plainly if challenged.

---

## 13. Notifications and Logic Apps

Implemented pattern:

```text
SQL writes notification row
→ ADF reads latest row
→ ADF gets callback from Key Vault using managed identity
→ Web activity posts JSON
→ Logic App Compose
→ HTTP 202 Response
→ optional Gmail action
```

Returning 202 before email decouples data success from connector availability. Never expose the callback URL because it contains an invocation signature. Store it in Key Vault and mark ADF activity input/output secure.

Evidence boundary: the repository proves many ADF calls reached the base Logic App and separately proves the Gmail-enabled workflow sent a test message after reauthorization. It does not capture a single ADF-originated email end to end. Two Logic App resources appear in final evidence; production should retain one correctly named workflow.

---

## 14. Security from zero

- **Authentication:** proving who/what you are.
- **Authorization:** deciding what that identity may do.
- **Managed identity:** Azure-managed service identity; no secret to rotate.
- **Service principal:** application identity, commonly with certificate/secret/federation.
- **Azure RBAC:** permissions on Azure resources.
- **SQL role:** permissions inside a database.

Actual prototype:

- SQL is Entra-only; TLS 1.2 minimum.
- ADF system-assigned identity uses custom SQL role `db_kpmg_pipeline_executor`.
- Key Vault uses Azure RBAC; ADF has Key Vault Secrets User.
- SQL/Key Vault public endpoints allow selected networks; Azure-service bypass is enabled where required.
- Four Entra security groups exist. Admin/developer Contributor and support Reader roles are evidenced.
- A tenant work user belongs to the report-reader group.
- `sql/005_reporting_identity.sql` grants the **service principal** reporting-only SQL access. Group-only SQL-role mapping is not proven.
- The short-lived SP credential shown in evidence expired on 2026-09-18; rotate or replace with federation/certificate before reuse.

External users are assumed to consume curated information through Power BI. Direct database access is limited to technical identities. Production would invite external users through Entra B2B and secure Power BI workspace/app access with group membership and governance.

Production network: on-prem → HA self-hosted IR → VPN/ExpressRoute → hub/spoke VNet → private endpoints/private DNS → environment-specific services. “Direct Connect” on KPMG page 4 is AWS terminology; Azure equivalents are ExpressRoute or VPN Gateway.

---

## 15. Power BI

Power BI exists for **pipeline operations reporting**, not business energy analytics.

Actual final report:

- One page: `Overview`.
- Import mode, not DirectQuery.
- Imported views: `reporting.vw_PipelineDashboardSummary`, `reporting.vw_RecentPipelineRuns`, `reporting.vw_PipelineHealth`.
- Visuals: configured/enabled table cards; success/failure/rows/retry/reconciliation/pending-schema cards; recent pipeline run table; configured-table health table.

Additional SQL views exist for schema requests/history, reconciliation, table attempts and notifications, but they are not imported into additional report pages. Therefore “Schema Changes & Approvals” and “Data Quality & Retries” are future-page ideas, not implemented pages.

Why views instead of raw tables: stable reporting contract, simpler names, less exposure and easier least-privilege grants. Import mode fits a small prototype and avoids continuous source queries; DirectQuery is preferable when near-real-time data outweighs latency/performance constraints.

---

## 16. Synthetic business data

KPMG supplied no business dataset. The project uses a small representative energy/asset model:

- `src.Asset_Generation_PI_Data_T`: generation readings; key `AssetGenerationId`; watermark `LastModifiedUtc`.
- `src.CSD_Assets_T`: asset master; key `AssetId`; FULL load.
- `src.Asset_Gen_PI_Data_T_STG`: disabled-row example with `Load=No`.

The small volume makes behavior visible. `RegionCode` is the approved additive-change demo and `TemporaryNote` the rejected addition. Do not say `CarbonIntensity`; it is not the final implemented demo column.

---

## 17. CI/CD

- Git stores versioned changes.
- Branch isolates work (`feature/kpmg-data-pipeline`).
- Commit records a logical snapshot.
- Pull request requests review before `main`.
- CI validates; CD deploys.

Actual `.github/workflows/ci.yml` runs only on PRs to `main`: checkout, parse ADF JSON, build Bicep, static implementation tests and gitleaks. It has read-only permissions, no Azure login and no deployment. That prevents unreviewed PR code from mutating cloud resources or needing cloud secrets.

Production CD: merge approved package, authenticate using OIDC federation, parameterize each environment, deploy the same artifact Dev→Test→Integ→Prod with approvals, preserve previous artifact/database migration strategy for rollback, and separate code-release approval from data-schema RFC approval.

---

## 18. Infrastructure as code

`infra/main.bicep` creates the resource group and calls `resources.bicep`. The module declares SQL server/database, ADF managed identity, Key Vault/RBAC, base Logic App and resource firewalls. `gmail-connection.bicep` and `gmail-workflow-extension.bicep` are separate connector artifacts.

Bicep is declarative: describe desired state, version it, review changes and recreate consistently. The prototype is **partially IaC-managed** because Entra groups/app registration, Gmail OAuth authorization, Power BI Desktop credentials/content refresh, and some reporting access steps are manual or scripted separately.

---

## 19. Why we chose this approach

| Decision | Why here | When another option wins |
|---|---|---|
| ADF vs Fabric | Case permits ADF; no capacity; clear orchestration | Existing Fabric estate/OneLake/capacity |
| ADF vs Databricks | Small relational SQL-first case | Large, streaming, semi-structured, ML/PySpark |
| Azure SQL vs lakehouse | Transactions/audit/RFC are natural relational patterns | Massive analytical data, open formats, decoupled storage |
| Metadata vs pipeline per table | Consistency and one-row onboarding | Few highly irregular sources |
| Watermark vs full | Efficient delta | Small table/delete correctness favors full |
| Watermark vs CDC | Simpler prototype | Deletes, ordered changes and high fidelity require CDC |
| Staging vs direct curated | Validate before consumers see data | Very low-risk append-only data may permit direct writes |
| Delete+insert vs MERGE | Transparent, idempotent per key | MERGE/upsert optimized platform with careful concurrency testing |
| Two gates vs one | Separates ingestion correctness from publish correctness | One atomic platform layer might collapse checks |
| SQL RFC vs ITSM | Minimal, auditable demo | Enterprise ServiceNow/Jira governance |
| Logic App vs direct email | Connector separation and 202 decoupling | Azure Monitor action groups for infrastructure alerts |
| Audit tables vs Log Analytics | Business/run context in SQL | Enterprise cross-service observability |
| Managed identity vs password | No secret rotation | External/non-Azure client may require SP/federation |
| Groups vs individuals | Lifecycle and least privilege | Individual grants only for emergency/break-glass cases |
| Public vs private endpoints | Time/cost-effective demo | Production sensitive enterprise network |
| Desktop vs capacity | No paid capacity | Sharing, refresh, governance and scale require service/capacity |
| One vs four environments | Prototype scope | Production separation and release governance |
| Bicep vs portal-only | Repeatability and review | Portal only for exploration, never authoritative production setup |

---

## 20. What this prototype does not do

| Limitation | Why acceptable here | Production response |
|---|---|---|
| One Azure environment | Demonstrates logic cheaply | Separate Dev/Test/Integ/Prod subscriptions/resource groups |
| Public endpoints | Interview prototype | Private endpoints, DNS, VNet, VPN/ExpressRoute |
| No WATERMARK hard deletes | Case did not define deletes | CDC/Change Tracking/tombstones |
| SQL RFC only | Easy to inspect | ITSM approval/API integration |
| Synthetic small data | No source data supplied | Profile real volumes and business rules |
| Fixed linked service/retry | One source and controlled demo | Consume per-row metadata; classify retryable errors |
| Shared staging per target | No overlapping demo runs | Run locking or run-specific stage tables |
| Basic gate checks | Demonstrates control pattern | Value checks, referential/business rules and observability |
| Existing columns not type-altered | Avoid unsafe automatic DDL | Planned migrations, compatibility rules and backfill |
| Delivery status not fed back | Logic history is enough for demo | Correlation ID and callback/status update |
| One Power BI page | Core health visible | Add governed operational pages and publish securely |
| Partial IaC / no CD | Prototype deadline | Entra automation, OIDC release pipeline and policy-as-code |
| SP secret expired | Intentionally short-lived | Rotate or use certificate/workload federation |

---

## 21. Cost decisions

Historical capture showed CA$0.23 on 2026-09-16. Do not present that as a guaranteed current or future cost.

- SQL uses serverless `GP_S_Gen5_1`, free limit and auto-pause-on-exhaustion.
- ADF, Key Vault and Logic Apps are usage/transaction based.
- No Log Analytics, private endpoints/private DNS, VPN/ExpressRoute or paid Fabric/Power BI capacity was provisioned.

At enterprise scale, major drivers are SQL compute/storage/backup, ADF activity/data movement and SHIR, private connectivity, log ingestion/retention, Power BI/Fabric capacity, and Databricks compute if introduced.

---

## 22. Code-reading guide

| File | Read this part | Why |
|---|---|---|
| `sql/001_create_framework.sql` | tables and constraints | Understand metadata, audit and RFC state |
| `sql/002_sample_source.sql` | sources + three config rows | Know the actual demo data |
| `sql/003_stored_procedures.sql` | all three procedures | Core behavior |
| `sql/004_security_template.sql` | grants | ADF least privilege |
| `sql/005_reporting_identity.sql` | reporting role | SP-only reporting access |
| `sql/006_powerbi_reporting_views.sql` | summary/health/run views | Power BI contract |
| `adf/pipeline_MasterMetadataDriven.json` | Lookup, ForEach, finalize | Dynamic orchestration |
| `adf/pipeline_ProcessConfiguredTable.json` | retry and notification branches | Failure isolation |
| `infra/resources.bicep` | identity/network/free SQL | Deployed resource posture |
| `.github/workflows/ci.yml` | four validation steps | Safe PR CI |

Pseudo-code for `usp_ProcessConfiguredTable`:

```text
read configuration
calculate current schema hash
if first load: establish v1 baseline
else if changed: reuse/create RFC decision
verify old approved projection still exists
capture high watermark
create/align stage and target for approved columns
load bounded window to stage
write Gate 1 checks; stop on failure
begin transaction
publish full or key-based delta
calculate Gate 2 checks; rollback on failure
update watermark/status; commit
write audit/notification
on error: rollback, preserve checks, audit failure, rethrow
```

You do not need to memorize dynamic SQL. Understand why identifiers use `QUOTENAME`, why values are parameters, where the transaction begins, and when the watermark advances.

---

## 23. Verified demo scenarios

| Scenario | Action | Expected / what to say |
|---|---|---|
| First load | Reset, run master | v1 baseline, two enabled tables, all gates pass |
| Incremental | Run `01_incremental_change.sql`, trigger | Two changed rows only; watermark advances |
| No-change rerun | Trigger again | Zero delta; no duplicate |
| Add + approve | `02`, run, `03`, run | Pending old columns; then v2 `RegionCode` |
| Add + reject | `04`, run, `05`, run | `TemporaryNote` ignored; old schema continues |
| Breaking rename | `06`, run | CSD fails four attempts; other table succeeds; curated unchanged |
| Recovery | `07`, run | Both tables succeed; gates pass |
| Reporting security | Show views/report + identity evidence | Reporting boundary exists; do not claim group-only SQL mapping is proven |

Exact ADF run IDs and screenshots: [EVIDENCE.md](EVIDENCE.md).

---

## 24. Databricks version of the design

| Current | Databricks equivalent |
|---|---|
| ADF master/child | Databricks Workflows, or ADF orchestrating notebooks/jobs |
| `src` / `stg` / `curated` | Delta Bronze / Silver / Gold |
| SQL configuration | Delta control table |
| Watermark | Control metadata, Change Data Feed or source CDC |
| SQL transaction/upsert | Delta `MERGE` with ACID transactions |
| Schema history | Delta metadata + Unity Catalog governance |
| Reconciliation | PySpark/SQL expectations and audit Delta tables |
| RFC | Workflow + enterprise ITSM API |
| SQL reporting views | Gold Delta tables / Databricks SQL Warehouse |
| Entra/SQL roles | Unity Catalog catalogs, schemas, tables, groups |

- **Delta Lake:** files plus transaction log for ACID/versioning.
- **Auto Loader:** scalable incremental file discovery/ingestion.
- **Structured Streaming:** continuous/micro-batch processing.
- **Unity Catalog:** centralized access, lineage and governance.
- **Databricks Workflows:** job/task orchestration.

Strong answer to “Why not Databricks?”: “The case explicitly allowed Azure SQL with Data Factory or Fabric. For a small relational, approval-heavy prototype, ADF plus Azure SQL was the simplest architecture that met the requirement and made transactions and audit easy to demonstrate. I would choose Databricks when volume, semi-structured data, streaming, ML or lakehouse governance justified it. The same metadata, watermark, medallion, reconciliation and idempotency principles transfer directly.”

---

## 25. Beginner glossary

| Term | Simple meaning |
|---|---|
| ADF | Azure service that schedules and coordinates data work |
| ETL / ELT | Transform before / after loading to target |
| Metadata | Instructions describing how data should be processed |
| Schema | Column names, types and rules |
| Schema drift | Source shape changed |
| Schema evolution | Controlled adoption of that change |
| Watermark | Latest safely processed change timestamp |
| CDC | Ordered insert/update/delete changes captured from source |
| Idempotent | Safe to rerun without duplicating/corrupting results |
| Staging | Temporary validated landing area |
| Curated | Consumer-ready target data |
| Reconciliation | Comparing expected and actual results |
| PK | Primary key uniquely identifying a row |
| Transaction | All-or-nothing unit of database work |
| Rollback | Undo uncommitted transaction work |
| Retry | Repeat after failure |
| RFC | Recorded request for approval of a change |
| Managed identity | Azure-managed service login without stored secret |
| Service principal | Application identity in Entra |
| Entra ID | Microsoft cloud identity service |
| RBAC | Role-based permission assignment |
| Key Vault | Protected store for secrets/keys/certificates |
| Logic App | Managed integration/workflow service |
| Bicep | Azure declarative infrastructure language |
| CI/CD | Automated validation and controlled delivery |
| PBIR/PBIP | Text-based Power BI report/project formats |
| Private endpoint | Private VNet IP for an Azure service |
| Private DNS | Resolves service name to private endpoint |
| VPN / ExpressRoute | Encrypted internet tunnel / private WAN circuit to Azure |
| Delta Lake | ACID table format on object storage |
| Unity Catalog | Databricks governance and permissions layer |

---

## 26. What to know deeply

### Must know deeply

KPMG problem; end-to-end architecture; configuration-driven flow; first vs incremental; bounded watermark; staging; Gate 1/Gate 2; transaction and rollback; pending/approved/rejected schema behavior; breaking-change safe failure; retries/table isolation; actual security posture; limitations; production private-network design; ADF-vs-Fabric-vs-Databricks trade-off.

### Should understand

Audit tables; Logic App decoupling; reporting views/Import mode; CI checks; Bicep structure; SQL roles; synthetic data; every demo scenario.

### Good to know

Exact resource names, run IDs, every view column, exact Bicep API versions and all generated Power BI local date tables.

Do not memorize GUIDs, object IDs, hashes, passwords, callback URLs, every line of dynamic SQL or every screenshot timestamp.

---

## 27. Which document should I read for what?

| Goal | Read |
|---|---|
| Start learning | `INTERVIEW_MASTER_GUIDE.md` |
| Rapid revision | `INTERVIEW_CHEAT_SHEET.md` |
| Architecture/security | `ARCHITECTURE.md` |
| Choices/limitations | `DESIGN_DECISIONS.md` |
| KPMG mapping | `REQUIREMENTS_TRACEABILITY_MATRIX.md` |
| Actual evidence/run IDs | `EVIDENCE.md` |
| CI/CD/promotion | `CICD_PROMOTION.md` |
| Presentation/demo | `PRESENTATION_RUNBOOK.md` |
| Interview practice | `MOCK_INTERVIEW_QUESTION_BANK.md` |
| Existing-artifact audit | `DOCUMENTATION_INVENTORY.md` |
| Actual implementation | `../sql/`, `../adf/`, `../infra/`, `../powerbi/` |
