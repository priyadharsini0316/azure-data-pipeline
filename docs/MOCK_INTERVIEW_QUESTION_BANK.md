# KPMG Mock Interview Question Bank

Practice aloud. Start with the short answer, then expand only when the panel asks. Answers describe the checked-in prototype; labels such as “production” identify recommendations, not implemented features.

## Level 1 — Business and architecture

### 1. Walk me through your solution.

**Short answer:** One ADF master pipeline reads enabled metadata and calls one reusable child per table. Azure SQL owns schema approval, staging, reconciliation, transactional publishing and audit. Power BI reports pipeline health, while Logic Apps receive notification events.

**Detailed answer:** KPMG’s key requirement was that any configured row with `Load=Yes` becomes eligible without creating a table-specific pipeline. The master performs Lookup and ForEach; the child passes `ConfigId` to a stored procedure. The procedure selects the last approved schema, performs FULL or bounded-watermark loading into staging, runs two gates and publishes atomically. It logs schema RFCs and run evidence. The prototype uses one environment; production would promote the same package across four isolated environments.

**Likely follow-up:** Why put logic in SQL? The source and target are relational and co-located, and SQL transactions make publish, validation and watermark consistency easy to demonstrate. At lake scale I would move data processing to Spark/Delta.

### 2. What makes the pipeline dynamic?

The table, target, load mode, key, watermark and approved columns come from `ctl.PipelineConfiguration`. ADF does not contain a separate branch per source table. Adding a conforming source plus an enabled metadata row causes the same child framework to process it.

### 3. What happens when `Load=No`?

The master Lookup filters it out, so no child pipeline is started and no load audit is created for that table in that run.

### 4. Why did you choose ADF + Azure SQL?

KPMG explicitly permits them, the prototype is relational and small, and they make orchestration, transactions, audit and security easy to explain. Fabric would be attractive in an established OneLake/capacity estate; Databricks when Spark-scale, streaming, semi-structured data or ML justifies it.

### 5. Is Fabric required by the case?

No. Page 1 recommends Fabric for consistency but explicitly says it is not mandatory, and also permits Azure SQL and Data Factory.

### 6. What is your source data?

Representative synthetic relational asset and generation data, because KPMG supplied no business dataset. The sample declares its own keys, `LastModifiedUtc` watermark and delete assumptions; none are presented as KPMG requirements.

### 7. Explain the architecture to a non-technical stakeholder.

“A control list says which tables may travel. One reusable conveyor reads that list, checks whether the approved shape changed, moves only the correct records into a waiting area, validates them twice, and publishes them only when safe. Every decision is logged and a health screen shows the outcome.”

### 8. Draw the architecture.

Draw: source/config → ADF Lookup/ForEach → reusable child → SQL stage → Gate 1 → transactional curated publish/Gate 2 → audit/RFC → Logic App + Power BI. Add Key Vault/managed identity around service access. Label one prototype environment and separately draw production Dev→Test→Integ→Prod.

## Level 2 — Loads, reconciliation and recovery

### 9. How do you identify a first load?

`ApprovedSchemaHash` is null. The procedure captures the current schema as version 1, records an auditable initial approval, creates/aligns stage and target, and then loads. Automatic baseline approval is our prototype decision.

### 10. How does the incremental load work?

The configuration specifies `WATERMARK` and a modification column. The procedure reads the previous watermark, captures the source maximum before copying, and loads rows where the timestamp is greater than the old value and less than or equal to the captured maximum.

### 11. Why use an upper watermark bound?

It gives the run a stable input boundary. A row arriving after capture is intentionally deferred, so the query and saved watermark cannot disagree and skip it.

### 12. What if no reliable watermark exists?

Use FULL for a small table. For larger production tables, require CDC, Change Tracking, a source sequence/change feed or an immutable audit timestamp. I would not invent an unreliable watermark.

### 13. How do you prevent duplicates after rerun?

Each run reloads an empty stage. For WATERMARK, target rows matching staged primary keys are deleted before staged rows are inserted, inside one transaction. The watermark advances only after both gates pass. A rollback leaves target and watermark at the previous state.

### 14. Does the solution handle deletes?

FULL loads do because curated is replaced. WATERMARK loads do not propagate hard deletes; production needs CDC, Change Tracking, a soft-delete flag or tombstones.

### 15. Why use staging?

It separates movement from publication. Gate 1 can reject bad input before consumers see it, while Gate 2 can validate the atomic curated publish and roll it back.

### 16. What does Gate 1 validate?

Source-window count versus stage count, duplicate key count, null key count and presence of all approved source columns.

### 17. What does Gate 2 validate?

Every staged key exists in curated, target keys are unique and non-null, and FULL/first loads have equal stage and target counts.

### 18. Why are two gates necessary?

Gate 1 proves ingestion into stage; Gate 2 proves publication into curated. A correct stage does not prove the publish was correct.

### 19. What makes the load atomic?

Curated publication, Gate 2 decision, watermark update and success state are in one SQL transaction. An exception rolls them back together; failure evidence is then written outside the rolled-back work.

### 20. What happens if the pipeline fails halfway?

The table transaction rolls back, its watermark does not advance, failure is audited, and ADF retries. Other table children can complete independently. If any table remains failed, the parent records `PARTIAL_SUCCESS` and then fails visibly.

### 21. How many times does a failed table run?

At most four: the original attempt plus three ADF retries, 15 seconds apart. The prototype retries all errors; production should classify transient versus permanent failures.

### 22. What happens when one table fails?

Only that child/table fails. Other configured tables are not rolled back. The breaking-schema evidence shows one table exhausting four attempts while the other succeeds.

### 23. How would this scale to 1,000 tables?

Validate and partition metadata, limit concurrency based on source/SQL capacity, group by connection/domain, add per-table run locks, use separate integration runtimes, measure throughput and move heavy transforms to scalable compute. One unbounded ForEach is not the answer.

## Level 3 — Schema drift and RFC

### 24. How do you detect schema changes?

The procedure serializes ordered column name, type, maximum length, precision, scale and nullability and hashes it with SHA-256. It compares that hash with the approved hash.

### 25. Do you automatically accept additive changes?

No. Priya explicitly chose to follow the supplied process: every detected change requires approval. Auto-accepting safe nullable additions is documented only as a possible future optimization.

### 26. What happens when a column is added?

An RFC becomes pending and the old approved projection continues. If rejected, the new column remains ignored. If approved, the schema version increments and stage/curated receive a nullable column on the next run; old rows may require backfill.

### 27. What happens when a column is removed?

The approved projection can no longer be built. Gate 1 fails the table safely and leaves curated and watermark unchanged. Approval alone does not recreate the missing data; it requires a planned migration decision.

### 28. What happens when a column is renamed?

Without explicit lineage, a rename looks like a removal plus an addition. The old approved column is missing, so the table fails safely until mapping/migration is approved and implemented.

### 29. What happens on a datatype or nullability change?

It is detected by the hash. The prototype does not automatically ALTER an existing target column. Compatible values may still fit; incompatible values can fail. Production needs compatibility rules, migration SQL, backfill and rollback—not merely a status change to APPROVED.

### 30. How is approval stored?

In `rfc.SchemaChangeRequest`, with current/previous hashes, detected schema, summary, status, decision identity, timestamps and notes. `rfc.usp_DecideSchemaChange` applies APPROVED or REJECTED and writes approved history.

### 31. Why use SQL for RFC instead of ServiceNow?

SQL is the smallest auditable implementation for the prototype and the case did not mandate a platform. Production should integrate the client’s ITSM system so segregation of duties and enterprise approval policies apply.

### 32. How do pending and rejected changes follow Page 2?

They do not adopt the new schema. The run records/sends the schema state and uses only last-approved columns when that projection is possible—corresponding to the diagram’s old-schema Step 4.1 and schema message Step 5.1.

## Level 4 — Security, operations and platform choices

### 33. How are credentials secured?

ADF uses a system-assigned managed identity for SQL and Key Vault. The signed Logic App callback is stored in Key Vault, not config or source control. The prototype reporting SP is separate and its evidenced short-lived secret has expired; production should use managed identity, certificate or workload federation where possible.

### 34. Managed identity versus service principal?

Managed identity is best for an Azure resource because Azure manages its credential lifecycle. A service principal is useful for an external app or cross-boundary automation but requires certificate/secret/federation governance. Here ADF uses managed identity; the reporting identity demonstrates the SP pattern.

### 35. Explain RBAC versus SQL roles.

Azure RBAC controls management/data access to Azure resources such as Key Vault. SQL roles control permissions inside the database. Membership in an Entra Azure group does not by itself prove database access; an external provider/user/group must also be created and granted a SQL role.

### 36. How do internal and external users access data?

Technical identities receive least-privilege database access. The prototype assumes business/external consumers use Power BI, not direct SQL. Production would use Entra B2B, governed groups and a Power BI app/workspace with licensing and RLS if required.

### 37. How would on-premises data connect securely?

Production: highly available self-hosted integration runtime near the source, non-overlapping IP plan, VPN Gateway or ExpressRoute into hub/spoke VNets, private endpoints/private DNS, NSGs and optionally Azure Firewall. These are documented, not provisioned in the low-cost prototype.

### 38. Are the deployed endpoints private?

No. The prototype uses selected public network access/resource firewalls. Private endpoints, VPN, ExpressRoute and Azure Firewall were intentionally not provisioned for cost/scope.

### 39. What does the Logic App prove?

The base workflow proves ADF can securely obtain its callback and deliver events. A separate Gmail-enabled workflow proves the connector can send after OAuth authorization. The evidence does not show one ADF-originated event traversing all the way to Gmail, and SQL delivery status is not updated.

### 40. What does Power BI contain?

One Import-mode `Overview` page using three reporting views. It is pipeline-operations reporting, not business analytics. Other reporting views exist in SQL but are not additional implemented pages.

### 41. What does CI/CD do?

CI on pull requests to `main` parses ADF JSON, builds Bicep, runs static checks and scans for secrets. It uses no Azure login and deploys nothing. Production CD with OIDC, approvals and environment parameters is a documented recommendation.

### 42. How much did it cost?

The captured historical cost was CA$0.23 on 2026-09-16, not a price guarantee. Serverless SQL/free limit and usage-based services kept the demo small. Production costs add compute/storage, data movement/SHIR, private connectivity, logs and Power BI/Fabric capacity.

### 43. Why not use Microsoft Fabric?

Fabric would reduce service boundaries and is strong with OneLake, notebooks, pipelines, governance and existing capacity. For this small relational prototype, ADF + Azure SQL met the permitted requirement with lower adoption overhead and clearer SQL transaction semantics.

### 44. Why not Databricks?

Databricks is compelling for large/semi-structured/streaming data, Spark transformations, ML and Unity Catalog governance. This case did not need that scale or complexity. The design maps cleanly to Workflows, Bronze/Silver/Gold Delta, Auto Loader/CDF and Unity Catalog if requirements change.

### 45. Stored-procedure-heavy ETL: benefit and risk?

Benefit: ACID control, set-based operations and audit near relational data. Risk: dynamic SQL complexity, database compute bottleneck, harder portability and coupling. Keep orchestration in ADF, modularize procedures, test them, and move large transformations to scalable compute when warranted.

## Level 5 — Skeptical senior-engineer challenges

### 46. Your config has retry and connection fields. Why are they ignored?

They are forward-looking metadata that the prototype does not consume. The ADF linked service is fixed and retry is hard-coded at 3/15 seconds. I would either implement those fields with allow-listed connections/policies or remove them until supported, because unused configuration creates false expectations.

### 47. Can two runs corrupt the shared staging table?

Two different configuration rows have different target stage tables, but overlapping master runs for the same `ConfigId` could conflict because stage is shared. Production needs an application lock/control-table lease or run-specific staging followed by atomic publish.

### 48. Does approving an incompatible datatype make the pipeline safe?

No. Approval is governance, not migration. The prototype records approval but does not ALTER existing target types/nullability. Production needs compatibility classification, explicit DDL/backfill validation, consumer-impact analysis and rollback.

### 49. Row counts and keys are not value reconciliation. Is your validation sufficient?

It is sufficient only for the agreed prototype definition. It detects missing/duplicate/null keys and count/schema errors, not wrong non-key values or business-rule defects. Production should add hashes/checksums, domain rules, referential checks and anomaly thresholds.

### 50. Why does the parent say `PARTIAL_SUCCESS` and still fail?

`PARTIAL_SUCCESS` is the business summary: some tables succeeded and some failed. Throwing afterward is the orchestration signal so ADF monitoring, retry/alert policies and operators cannot mistake the overall run for success.

### 51. How do you avoid SQL injection in metadata-driven SQL?

Object identifiers are wrapped with `QUOTENAME`; values should be passed as parameters. I would also validate schemas/tables/column metadata against allow-lists and restrict who may edit configuration. `QUOTENAME` alone does not replace governance.

### 52. Could late-arriving data be missed?

Yes, if it arrives later with a modification timestamp less than or equal to the stored watermark. Production can use a lookback window with key-based idempotency, CDC/Change Tracking or a monotonic source sequence.

### 53. Why not use SQL `MERGE`?

Explicit delete-by-staged-key plus insert is transparent for the small prototype and easy to reason about during reruns. `MERGE` can work, but I would use a carefully tested pattern, appropriate locking and platform-specific guidance rather than treating it as automatically safer or faster.

### 54. Is the solution fully infrastructure as code?

No. Core SQL/ADF/Key Vault/base Logic App are represented, but Entra groups/app registration, Gmail OAuth authorization, Power BI Desktop refresh and some access setup are manual or separately scripted. It is partially IaC-managed.

### 55. Can you prove the report-reader group has SQL access?

No. Evidence shows the group and Azure memberships, while `sql/005_reporting_identity.sql` grants the reporting service principal the SQL reader role. The group-to-SQL mapping remains a documented gap.

### 56. Can you prove an ADF failure sent Gmail?

Not as one trace. The evidence separately proves ADF→base Logic App and a successful Gmail send from the Gmail-enabled workflow. I would consolidate the workflow and use a correlation ID plus delivery callback before claiming end-to-end alert delivery.

### 57. Why is an initial schema automatically approved if all changes require approval?

The first load has no prior schema to protect, so the prototype establishes its starting baseline and records it as an auditable `INITIAL_LOAD` approval. In a stricter organization, even baseline creation could remain pending until an owner approves it.

### 58. What would you change first for production?

First add private connectivity/SHIR HA and environment separation; then run locking and CDC/delete correctness; then controlled schema migrations and enterprise ITSM; then centralized observability and automated integration/CD. The order depends on the client’s security and recovery requirements.

### 59. What was the hardest design trade-off?

Following Page 2 literally while avoiding silent schema adoption. Continuing with old columns is safe for additive changes, but impossible when an approved column disappears. The design therefore keeps service for compatible changes and fails safely for breaking ones.

### 60. What are you most careful not to overclaim?

Production private networking, full four-environment deployment, hard-delete handling, automatic type migrations, group-only SQL reporting access, end-to-end ADF→Gmail evidence, Power BI Service publication, complete IaC and automated CD are not implemented.

## Whiteboard drills

1. Draw the KPMG Page 2 decision tree and mark how `PENDING`, `APPROVED` and `REJECTED` map to it.
2. Draw the bounded watermark timeline with a row arriving during the run.
3. Draw Gate 1 outside and Gate 2 inside the publish transaction.
4. Draw identity paths: ADF MI→SQL; ADF MI→Key Vault→Logic App; Power BI/SP→reporting views.
5. Draw prototype networking beside production private networking.
6. Map the design to Databricks Bronze/Silver/Gold and Unity Catalog.

## Self-scoring

- **Ready:** answer in under 90 seconds, state implemented vs recommended, and name one limitation/trade-off.
- **Needs practice:** correct idea but no concrete implementation detail.
- **Not ready:** guesses, claims an unimplemented feature, or cannot explain failure/rerun behavior.
