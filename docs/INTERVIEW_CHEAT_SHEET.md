# KPMG Pipeline Interview Cheat Sheet

Use this for rapid revision. For explanations and evidence links, use [INTERVIEW_MASTER_GUIDE.md](INTERVIEW_MASTER_GUIDE.md).

## The answer in 30 seconds

“I implemented one metadata-driven Azure Data Factory framework over Azure SQL. A master pipeline reads every configuration row where `Load=Yes`, runs one reusable child pipeline per table, and SQL handles approved-schema projection, staging, reconciliation and transactional publishing. FULL and bounded-watermark loads are supported. Every schema change creates an RFC; pending or rejected changes keep the last approved columns when possible, while breaking removal or rename changes fail that table safely. Audit views feed a one-page Power BI operations report, and Logic Apps receive notification events. The prototype uses one low-cost environment; production would use separate environments and private networking.”

## What KPMG actually required

- Dynamic pipeline; a configured table with `Load=Yes` becomes eligible.
- Source schema may change randomly.
- First and subsequent loads.
- Schema-change alert, RFC/approval and old-schema load when not approved.
- Data comparisons before success, plus failure handling/retry/alerting.
- Azure SQL + ADF or Microsoft Fabric. Fabric is recommended, not mandatory.
- Explainability, process screenshots, networking, IAM/RBAC/MFA, groups and service-principal design.

KPMG did **not** specify source data, primary keys, watermark columns, delete handling, exact reconciliation rules, external-consumption method or approval platform. Those are documented prototype assumptions/design decisions.

## Actual implementation at a glance

| Area | Implemented fact |
|---|---|
| Orchestration | ADF `MasterMetadataDriven` → Lookup → ForEach (`batchCount=2`) → `ProcessConfiguredTable` |
| SQL | One database with `src`, `ctl`, `stg`, `curated`, `audit`, `rfc`, `reporting` schemas |
| Config | Three sample rows: two enabled, one disabled |
| Loads | `FULL` and `WATERMARK` |
| Watermark | `> previous` and `<= captured MAX`; advances only after successful transaction |
| Idempotency | Staging + target-key delete/insert + transactional watermark |
| Schema | SHA-256 over ordered name/type/size/precision/scale/nullability |
| RFC | `PENDING`, `APPROVED`, `REJECTED`; initial baseline recorded as approved v1 |
| Quality | Gate 1 source-window→stage; Gate 2 stage→curated |
| Retry | ADF retry `3`, so at most four attempts, 15 seconds apart |
| Isolation | One table can fail while another succeeds; parent records `PARTIAL_SUCCESS` then fails visibly |
| Reporting | Power BI Import mode, one `Overview` page, three imported reporting views |
| Security | Entra-only SQL, ADF managed identity, Key Vault RBAC, SQL custom roles, four Entra groups |
| CI | ADF JSON parse, Bicep build, static tests, gitleaks; no deployment |

## First load vs subsequent load

**First:** approved hash is null → inspect schema → create version 1 baseline → create stage/target → load → Gate 1 → transaction/publish → Gate 2 → commit/audit.

**Subsequent:** compare schema hash → resolve/create RFC if changed → use approved columns → calculate bounded load window → stage → gates → transactional publish → advance watermark.

Automatic v1 approval is **our design decision**, not a literal KPMG requirement.

## The two most important technical explanations

### Bounded watermark

```text
previous watermark < row timestamp <= MAX captured before the copy
```

The upper bound freezes the run’s input. Rows arriving later belong to the next run. The watermark and publish commit together, so a failure cannot advance the watermark past uncommitted data.

### Two reconciliation gates

- Gate 1 proves the intended source window reached staging: row count, duplicate key, null key and approved-column presence.
- Gate 2 proves staging was published correctly: staged-key completeness, duplicate/null target keys and FULL-load count.
- Gate 2 is inside the publish transaction; failure rolls back curated data and watermark.

## Schema-change outcomes

| Change | Pending/rejected | After approval |
|---|---|---|
| Add nullable column | Old projection continues | Column added nullable and loaded; history may need backfill |
| Remove approved column | Old projection impossible; table fails safely | Requires planned target/code migration; approval alone is insufficient |
| Rename approved column | Treated as missing old + added new; table fails | Requires migration/mapping decision |
| Type/nullability change | Detected; old target definition remains | Existing target type is not automatically altered; incompatible data may fail |

All changes require approval in this prototype. Auto-accepting safe additive changes is only a future optimization.

## Security answer

“The prototype uses Entra-only SQL and an ADF system-managed identity, so the pipeline does not store a database password. ADF receives a least-privilege SQL execution role and Key Vault Secrets User; humans are assigned through role-based Entra groups. Resource firewalls are enabled. The low-cost prototype uses selected public networks, while production should use private endpoints, private DNS, hub/spoke networking and VPN or ExpressRoute. External consumers are assumed to use a governed Power BI app. The repo proves the reporting service principal’s SQL role, but not the report-reader group’s SQL mapping.”

Do not claim the SP credential is reusable: the evidenced secret expired on 2026-09-18.

## Notification answer

SQL records an event → ADF reads it → retrieves a signed Logic App callback from Key Vault using managed identity → posts JSON → Logic App acknowledges with HTTP 202 and can send Gmail.

Evidence is split: ADF→base Logic App is proven, and a Gmail-enabled workflow separately sent a test message. A single ADF-originated email is **not** captured end to end. `NotificationAudit.DeliveryStatus` is not fed back.

## Power BI answer

It is an operational report, not a business analytics dashboard. The final PBIP has one `Overview` page in Import mode using three reporting views. It shows configured/enabled tables, successes/failures, rows/retries/reconciliation/schema state, recent runs and table health. More SQL views exist, but extra report pages are not implemented.

## Why these technologies?

| Choice | Defensible answer |
|---|---|
| ADF + Azure SQL | Small relational use case; KPMG permits it; easy orchestration, audit and ACID transactions; no Fabric capacity required |
| Not Fabric | Strong option if client already owns capacity/OneLake; unnecessary platform commitment for this prototype |
| Not Databricks | Best when scale, semi-structured data, streaming, ML or lakehouse governance justifies Spark/Delta complexity |
| Metadata-driven | Onboard a conforming table with config, not a new pipeline |
| SQL RFC | Simple auditable prototype; production should integrate enterprise ITSM |
| One environment | Reduced cost and deadline; production promotes one package across Dev/Test/Integ/Prod |

## Top 15 points to say accurately

1. `Load=Yes` makes a row eligible; it does not guarantee its metadata is valid.
2. The framework passes `ConfigId`, then SQL re-reads authoritative metadata.
3. Two enabled tables share the same child pipeline.
4. FULL handles small tables and delete correctness; WATERMARK reduces transfer.
5. The watermark window has both lower and captured upper bounds.
6. The watermark advances only in the successful publish transaction.
7. Delete+insert by key makes a delta rerun idempotent.
8. Gate 1 protects curated data; Gate 2 verifies publication.
9. Every schema change requires approval in this prototype.
10. Pending/rejected changes use last approved columns only when those columns still exist.
11. A removed/renamed approved column fails safely rather than silently losing data.
12. One table failure does not undo another table’s success.
13. ADF performs up to four attempts because `retry=3` means three retries after the original.
14. CI validates but does not deploy; production CD is documented only.
15. The prototype is deliberately honest about unimplemented production controls.

## Limitations you should volunteer

- No hard-delete propagation for WATERMARK loads.
- Fixed linked service and hard-coded retry despite metadata fields.
- Shared per-table staging can conflict if the same configuration overlaps.
- Approved type/nullability changes do not alter existing target columns automatically.
- `RowsInserted`/`RowsUpdated` and notification delivery status are not populated.
- Gate 2 rollback was code-reviewed but not deliberately forced live.
- Group-only SQL reporting access and one ADF-originated Gmail delivery are not proven.
- One environment, public endpoints, partial IaC, synthetic low-volume data and no enterprise ITSM/Log Analytics.

## If asked “What would you do next?”

1. Add per-configuration run locking and typed metadata validation.
2. Implement CDC/Change Tracking for deletes and late-arriving changes.
3. Separate schema detection from approved DDL migration/backfill.
4. Consume configured connections/retry policy and classify transient errors.
5. Consolidate the Logic App and add correlation/delivery callback.
6. Add private networking, SHIR HA, Log Analytics and environment separation.
7. Map the report-reader Entra group to SQL and publish a governed Power BI app.
8. Add automated integration tests, OIDC CD and rollback/migration procedures.

## Top 25 likely questions — one-line recall

1. **What makes it dynamic?** Metadata selects objects and behavior; one reusable child processes every enabled row.
2. **How do I add a table?** Add a conforming source and valid `Load=Yes` config row; no new ADF pipeline.
3. **First load?** Null approved hash establishes version 1, then stage/gates/publish/audit.
4. **Incremental load?** `> old watermark AND <= captured MAX`.
5. **Why capture MAX first?** Stable window prevents rows arriving mid-run from being skipped.
6. **No watermark?** FULL for small tables; CDC/change feed for scalable production.
7. **Duplicate prevention?** Empty stage, key delete+insert, transactional watermark.
8. **Deletes?** FULL handles them; WATERMARK hard deletes are unsupported.
9. **Why staging?** Validate without exposing partial/bad curated data.
10. **Why two gates?** One verifies ingestion; one verifies publication.
11. **Gate 2 failure?** Transaction rolls back curated changes and watermark.
12. **Schema detection?** SHA-256 of ordered column metadata.
13. **Added column?** RFC first; approved addition becomes nullable.
14. **Removed/renamed column?** Old projection fails safely until planned migration.
15. **Datatype change?** Detected, but approval does not automatically ALTER existing targets.
16. **Rejected change?** Last approved columns remain; unapproved addition is ignored.
17. **One table fails?** Peer tables continue; parent records partial success and fails visibly.
18. **Retries?** Original plus three retries, 15 seconds apart.
19. **How is ADF authenticated?** System-assigned managed identity and least-privilege SQL/Key Vault roles.
20. **Why Key Vault?** Keep signed callback/secret material out of code and metadata.
21. **Why ADF + SQL?** Permitted, relational, low-overhead, transactional and explainable.
22. **Why not Fabric?** Good with existing capacity/OneLake; unnecessary commitment here.
23. **Why not Databricks?** Choose it for Spark-scale, streaming, semi-structured data, ML or lakehouse governance.
24. **What does Power BI show?** One imported operations page based on three reporting views.
25. **Biggest production changes?** Private networking/environments, locking, CDC, controlled schema migrations, ITSM and centralized monitoring.

### Numbers and names to remember

- **3** configuration rows; **2** enabled; **1** disabled.
- **2** load modes; **2** gates; **2** ADF pipelines.
- `batchCount=2`; `retry=3` means **4 total attempts**; retry interval **15 seconds**.
- **7** SQL schemas: `src`, `ctl`, `stg`, `curated`, `audit`, `rfc`, `reporting`.
- Power BI: **1** page, **3** imported views, Import mode.
- Actual schema examples: approved `RegionCode`; rejected `TemporaryNote`; rename `AssetType`→`AssetCategory`.

## Files to show

- Overview: [README.md](../README.md)
- Requirements: [REQUIREMENTS_TRACEABILITY_MATRIX.md](REQUIREMENTS_TRACEABILITY_MATRIX.md)
- Architecture/security: [ARCHITECTURE.md](ARCHITECTURE.md)
- Actual behavior: [`sql/003_stored_procedures.sql`](../sql/003_stored_procedures.sql)
- Dynamic orchestration: [`adf/pipeline_MasterMetadataDriven.json`](../adf/pipeline_MasterMetadataDriven.json)
- Live proof: [EVIDENCE.md](EVIDENCE.md)
- Presentation sequence: [PRESENTATION_RUNBOOK.md](PRESENTATION_RUNBOOK.md)

Never expose passwords, connection strings, Logic App callback URLs, tokens, tenant/object IDs unless specifically necessary and redacted.
