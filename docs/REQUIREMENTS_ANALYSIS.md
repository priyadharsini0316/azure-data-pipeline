# KPMG Data Pipeline - Source-of-Truth Requirements Analysis

Status: Phase 0-3 review only. No implementation has been authorized.

## Evidence reviewed

- Authoritative source: `C:\Users\priya\Downloads\KPMG Technical Use Case - Data Pipeline.pdf` (all four pages, visually rendered and inspected).
- Searchable cross-check: `C:\Users\priya\Downloads\KPMG Technical Use Case.md`.
- User-supplied screenshots of pages 1-4, including the page 1 architecture inset at a larger size.

The PDF is authoritative. The Markdown is useful for search but is not sufficient for page 2 because it omits most nodes, arrows, decisions, and branch relationships.

## Classification legend

- **[A - REQUIRED]** Explicitly required or an expected outcome in the KPMG document.
- **[B - RECOMMENDED]** Recommended or illustrative in the KPMG document, not mandatory.
- **[C - PROPOSED]** Our proposed design choice, subject to Priya's approval.
- **[D - ASSUMPTION]** Not established by KPMG; requires confirmation.

## Plain-English problem understanding

KPMG's client needs a pipeline that can load many source tables without building one pipeline per table. A configuration row controls whether a table is eligible to run. The pipeline must handle initial and later loads, recognize source-schema changes, follow an approval/change process, verify data as it moves through environments, and handle success and failure. Data starts on premises and is ultimately made available securely to internal and external users. The candidate must both demonstrate the solution and explain it in accessible language.

## Page-by-page visual findings

### Page 1 - case summary, reference architecture, expected outcomes

Explicit requirements and outcomes:

- **[A - REQUIRED]** Implement a dynamic data pipeline for a source data model subject to random changes.
- **[A - REQUIRED]** The target must adapt to source changes while adhering to the established process.
- **[A - REQUIRED]** Drive table eligibility from a configuration table: a table with `Load = Yes` is considered for pipeline loading.
- **[A - REQUIRED]** Support initial and subsequent loads.
- **[A - REQUIRED]** Manage success and failure scenarios.
- **[A - REQUIRED]** Explain the architecture in non-technical language.
- **[A - REQUIRED]** Provide screenshots of each setup step according to the supplied flow.
- **[A - REQUIRED]** The candidate may call out issues in the supplied process flow and logic.
- **[A - REQUIRED]** Tables and structures may be chosen freely if they satisfy the requirements.
- **[B - RECOMMENDED]** Microsoft Fabric is recommended for consistency with the client's medallion data-warehouse platform, but is explicitly not mandatory.
- **[B - RECOMMENDED]** Azure SQL Server can be used to manage the database.
- **[A - REQUIRED]** The implementation technology is Azure SQL plus Data Factory, or Microsoft Fabric.
- **[B - RECOMMENDED]** Automatic retry and alerting after repeated failure are examples, not prescribed thresholds.

The page 1 visual depicts, but does not by itself mandate:

- Source Development -> Source Test -> Source Integration -> Source Production.
- A source-to-Bronze pipeline.
- Fabric workspaces labeled Dev, Test, Integ, and Prod.
- Bronze in Dev/Test, Silver in Integ, Gold and a semantic model in Prod.
- Dev-to-Test data movement/deployment and Bronze-to-Silver and Silver-to-Gold pipelines.
- An existing-versus-new schema comparison during first/next load.

### Page 2 - supplied process flow, traced visually

The following is a literal trace of visible nodes and branches. Where the drawing is semantically unclear, it is marked ambiguous instead of being normalized.

1. `Start Data Pipeline` -> decision 1: `First Time Load?`.
2. Decision 1, `Yes` -> step 1.1: `Create Schema and load data (Fabric Dev & Test)`.
3. Step 1.1 also has a branch to `Request for change (RFC)`.
4. Step 1.1 -> decision 2: `Does Data match between Source Prod and Fabric (Dev & Test)?`
5. Decision 2, `Yes` -> step 2.1: `Load Data to Fabric Integ and Prod`.
6. Step 2.1 -> decision 3: `Does Data match between Fabric Dev/Test and Fabric (Integ & Prod)?`
7. Decision 3, `Yes` -> step 3.1: `Send Success Load Message` -> `Stop Data Pipeline`.
8. Decision 3, `No` -> `Review the Data quality/gap Report and Fix the Issue` -> callout `To Step 3` -> `Manually run the pipeline or wait for next run (Ref Configuration Table)`.
9. Decision 2, `No` -> step 2.2: `Review the Data quality/gap Report and Fix the Issue` -> callout `To Step 1` -> `Manually run the pipeline or wait for next run (Ref Configuration Table)`.
10. Decision 1, non-first-load path -> decision 4: `Has Data Schema (Source Prod = Fabric Dev) Changed from Last Load?`
11. Decision 4, `No` -> step 4.1: `Load Data` -> decision 2.
12. Decision 4, `Yes` -> step 4.2: `Send Schema Change Alert and Get Approval` -> decision 5: `Approved?`
13. Around decision 5, the visible routing is ambiguous:
    - `Yes` is printed above the decision, and a return line appears to lead toward step 4.1.
    - `No` is printed below/right of the decision, and the horizontal route continues to step 5.1, `Pipeline Schema Change Message`, then to `Stop Data Pipeline`.
    - A grey callout above step 5.1 says `To Step 4.1` and `Load data with old scheme only`, but the exact relationship between this callout, approval result, and step 5.1 is not unambiguously drawn.
14. A lower RFC lane begins `From Step 1.1 RFC` -> `Business Initiated New change(s) for Fabric` -> `Developer makes & test the changes in Fabric Test Env. And test the changes, once approved` -> `Deploy the changes to Fabric Pipelines` -> callout `To Step 1. Manually run the pipeline or wait for next run (Ref Configuration Table)`.

Page 2 does not define retry counts, transactional boundaries, watermark behavior, schema compatibility rules, concurrent table handling, or audit record structure.

### Page 3 - sample configuration

Visible columns are `Tables`, `Columns`, `Load`, `Connection Parameters`, and an open-ended `..........` field. Sample rows:

- `Asset_Generation_PI_Data_T`, `C1,C2,C3,......`, `Yes`.
- `Asset_Gen_PI_Data_T_STG`, `C1,C2,C3,......`, `No`.
- `CSD_Assets_T`, `C1,C2,C3,......`, `Yes`.

Only the `Load = Yes` eligibility behavior is explicitly required. The other fields are illustrative and underspecified. The document does not require credentials or secrets to be stored in this table.

### Page 4 - access and control

- **[A - REQUIRED]** Design secure access for internal and external users after on-premises data reaches the cloud.
- **[A - REQUIRED]** Provide a screenshot for each step of the access/security process.
- **[A - REQUIRED]** Secure on-premises-to-cloud connectivity, with routing and firewall rules.
- **[A - REQUIRED]** Plan non-overlapping private IP ranges and scalable subnetting.
- **[A - REQUIRED]** Restrict traffic through firewalls/security controls to only necessary paths.
- **[A - REQUIRED]** Use RBAC and least privilege and periodically review access.
- **[A - REQUIRED]** Use identity/access management with MFA and provisioning/de-provisioning.
- **[A - REQUIRED]** Create role/function-based security groups and assign permissions to groups, not individuals.
- **[A - REQUIRED]** Address application identity through an app registration/service principal, appropriate permissions, and non-user authentication.

Terminology requiring Azure translation:

- `Direct Connect` is AWS terminology. Azure equivalents are ExpressRoute for private WAN connectivity or VPN Gateway for encrypted site-to-site connectivity. Private Link/private endpoints address private PaaS access and are not themselves a replacement for on-premises WAN connectivity.
- `Security groups` should be expressed as Microsoft Entra security groups for identity authorization and Network Security Groups/Azure Firewall rules for network traffic.
- `Azure Active Directory (AAD)` is now Microsoft Entra ID.
- A service principal is a workload/application identity, not the normal mechanism for interactive end-user sign-in. Internal/external people should ordinarily use Entra identities, groups, Conditional Access/MFA, and Power BI or data-layer permissions.

## Structured requirements analysis

### 1. Functional requirements

- **[A - REQUIRED]** Read table-processing eligibility from configuration.
- **[A - REQUIRED]** Process every valid configured row with `Load = Yes` without a separate hard-coded pipeline per table.
- **[A - REQUIRED]** Detect first versus subsequent load.
- **[A - REQUIRED]** Detect source-schema change on subsequent load and invoke alert/approval behavior.
- **[A - REQUIRED]** Load through the supplied environment/process stages and compare data at prescribed gates.
- **[A - REQUIRED]** Record and communicate success/failure behavior.
- **[C - PROPOSED]** Use one master ADF pipeline with Lookup -> ForEach -> parameterized child activities/pipelines and parameterized datasets.

### 2. Non-functional requirements

- **[A - REQUIRED]** Dynamic/extensible behavior, explainability, secure access, and documented screenshots.
- **[C - PROPOSED]** Add idempotency, restartability, observability, controlled concurrency, auditability, and least-privilege implementation because they are necessary for a defensible production-quality design.
- **[D - ASSUMPTION]** No formal availability, RPO/RTO, volume, latency, retention, or regulatory targets have been supplied.

### 3. Source-system assumptions

- **[A - REQUIRED]** Source data is on premises and its schema may change unpredictably.
- **[D - ASSUMPTION]** The source engine is SQL Server; the document never identifies the engine.
- **[D - ASSUMPTION]** Stable primary keys and reliable watermark columns exist; neither is stated.
- **[D - ASSUMPTION]** Source-side deletes, late-arriving updates, and change capture requirements are unspecified.

### 4. Target-system requirements

- **[A - REQUIRED]** Use Azure SQL + Data Factory or Microsoft Fabric.
- **[B - RECOMMENDED]** Fabric is recommended because the client uses a Fabric medallion architecture.
- **[D - ASSUMPTION]** Whether the prototype must physically reproduce Dev/Test/Integ/Prod is not specified.
- **[D - ASSUMPTION]** Required serving pattern for external users (Power BI only, SQL, files, or application/API) is unspecified.

### 5. Configuration-driven requirements

- **[A - REQUIRED]** A new table row with `Load = Yes` becomes eligible for processing.
- **[A - REQUIRED]** `Load = No` excludes the row.
- **[C - PROPOSED]** Validate configuration before execution, including unique source/target identity, supported load type, valid identifiers, and required key/watermark metadata.
- **[C - PROPOSED]** Store connection references, not secrets, in metadata. Resolve secrets through managed identity/Key Vault only when secrets are unavoidable.

### 6. First-load requirements

- **[A - REQUIRED]** Create target schema and load data into Dev/Test, reconcile, promote/load into Integ/Prod, reconcile again, then signal success.
- **[D - ASSUMPTION]** Whether `create schema` means database schema, table DDL, or both is not stated.
- **[C - PROPOSED]** Identify first load from absence of a successful table-load state and absence of an approved target schema version, not merely target row count.

### 7. Subsequent/incremental-load requirements

- **[A - REQUIRED]** Subsequent loads are required.
- **[D - ASSUMPTION]** The document does not mandate incremental loading, watermarking, CDC, or full reload.
- **[C - PROPOSED]** Support metadata-selected `FULL` and `WATERMARK` modes; require a reliable watermark plus deterministic tie-breaker/primary key for the latter.

### 8. Schema-change requirements

- **[A - REQUIRED]** Compare the current source schema with the last-load/reference schema.
- **[A - REQUIRED]** Alert and obtain approval when the supplied process identifies a change.
- **[D - ASSUMPTION]** The supplied flow does not define which changes can be auto-accepted or whether all changes require approval.
- **[C - PROPOSED]** Fingerprint normalized column metadata and persist versions/differences; classify additive nullable columns as potentially safe and removals, renames, narrowing/incompatible datatype changes, or nullable-to-non-nullable changes as breaking.

### 9. Data reconciliation requirements

- **[A - REQUIRED]** Compare Source Prod with Fabric Dev/Test and compare Fabric Dev/Test with Integ/Prod.
- **[A - REQUIRED]** Review a data-quality/gap report and fix issues when comparison fails.
- **[D - ASSUMPTION]** `Does Data match` has no stated algorithm, tolerances, or severity rules.
- **[C - PROPOSED]** Reconcile counts and rejected rows for every load, plus duplicate/null/key checks and optional aggregate/hash checks selected by configuration.

### 10. Success/failure/retry requirements

- **[A - REQUIRED]** Handle success and failure scenarios.
- **[B - RECOMMENDED]** Automatic retries and alerts after repeated failures are suggested examples.
- **[C - PROPOSED]** Retry transient failures only, with bounded retries/backoff. Do not retry deterministic schema, permission, or data-quality failures without correction.
- **[C - PROPOSED]** Isolate each table's run state so one table can fail while independent tables continue, then calculate an overall `Succeeded`, `SucceededWithWarnings`, or `Failed` status.

### 11. RFC/approval requirements

- **[A - REQUIRED]** The supplied flow includes an RFC from step 1.1 and an approval path for schema change.
- **[D - ASSUMPTION]** Approver, SLA, evidence, tooling, and approval granularity are not supplied.
- **[C - PROPOSED]** Represent approval as durable data with requested/approved/rejected timestamps, approver, reason, schema versions, and immutable audit links; do not leave an ADF run waiting indefinitely for a human.

### 12. Security requirements

- **[A - REQUIRED]** Private/secure connectivity, routing, firewall controls, IP planning, RBAC, IAM, MFA, groups, least privilege, application identity, and periodic access review.
- **[C - REVISED PROTOTYPE DESIGN]** Prefer ADF managed identity, TLS, least-privilege roles, secured public endpoints/firewall rules, Key Vault references for unavoidable secrets, SQL/ADF audit evidence, and separation of duties. Private endpoints and disabled public access remain production recommendations only and are not provisioned for this prototype.

### 13. Internal-user access requirements

- **[A - REQUIRED]** Internal users require access governed by role and group membership.
- **[D - ASSUMPTION]** Specific personas and whether access is report-only or direct data access are unknown.

### 14. External-user access requirements

- **[A - REQUIRED]** External users require secure access.
- **[D - ASSUMPTION]** Their organizations, tenants, interaction mode, data entitlements, and licensing are unknown.
- **[C - PROPOSED]** Default to Entra B2B guest identities/groups and Power BI app/RLS for human consumers; use a service principal only for an approved application integration.

### 15. Reporting requirements

- **[A - REQUIRED]** No Power BI report is explicitly required by the KPMG PDF.
- **[C - PROPOSED]** A small pipeline-health report is valuable evidence and should show configured/enabled tables, recent outcomes, rows, duration, schema events, and reconciliation failures.

### 16. Screenshot/documentation requirements

- **[A - REQUIRED]** Screenshots of each setup step for the pipeline and access/security process.
- **[C - PROPOSED]** Maintain a screenshot checklist that distinguishes genuine portal/runtime evidence from diagrams and documentation; never fabricate screenshots.

### 17. Ambiguous or underspecified requirements

- Source technology, sample schemas, data volume, cadence, SLA, recovery targets, and retention.
- Required Azure/Fabric topology and whether four physical environments are expected in the prototype.
- Meaning and algorithm of `Does Data match`.
- Exact decision-5 routing and meaning of `load data with old scheme only`.
- Safe versus breaking schema policy and who approves.
- Handling of deletes, updates with equal timestamps, late-arriving data, and tables without keys/watermarks.
- External-user access mode and data entitlements.
- RFC system/tool, notification channel, and retry/alert thresholds.
- Required deployment target, budget, region, and exact deadline.

## How one framework can process all enabled tables

**[C - PROPOSED]** A master pipeline queries active configuration rows. A `ForEach` passes each row as parameters to common activities: inspect source metadata, resolve load state, compare schema fingerprint, extract with a parameterized query, write to a table-specific staging target, validate, publish atomically, update the watermark only after success, and write audit records. Dataset/linked-service parameters select schema, table, connection reference, and columns at runtime. Adding a valid configuration row therefore changes data, not pipeline code.

Source-specific exceptions should be explicit metadata-controlled strategies or a reviewed extension point. Arbitrary SQL expressions should not be accepted from an untrusted configuration editor.

## Preliminary acceptance boundary

The source review is complete, but the architecture cannot be considered final until the decisions in `ASSUMPTIONS_AND_QUESTIONS.md` are answered or explicitly accepted as prototype assumptions.
