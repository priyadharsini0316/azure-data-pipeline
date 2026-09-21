# KPMG Presentation and Demo Runbook

This runbook is designed for a live technical panel. It uses checked-in artifacts and captured evidence, so the story survives even if Azure or Power BI is slow. Never expose credentials, tokens, connection strings or signed Logic App callback URLs.

## Before the meeting

### Ten-minute technical check

1. Confirm the local branch and working tree with `git branch --show-current` and `git status --short`.
2. Open `README.md`, this runbook, `EVIDENCE.md`, `sql/003_stored_procedures.sql` and the two ADF JSON files.
3. Open Power BI Desktop to the saved `KPMG Pipeline Health.pbip` `Overview` page.
4. If using Azure live, sign in and open the resource group, ADF Monitor and SQL query editor/SSMS before screen sharing.
5. Run `pwsh -File tests/Test-StaticImplementation.ps1` locally.
6. Put screenshots in presentation order and close tabs that expose subscription/tenant details unnecessarily.
7. Keep the captured evidence ready as fallback. Do not run destructive/reset demo SQL unless you deliberately choose a live scenario.

### Safe presentation rules

- Say “prototype,” “implemented,” “documented production recommendation” and “known limitation” precisely.
- Do not present CA$0.23 as a forecast; it is a historical capture from 2026-09-16.
- Do not claim Power BI Service publication, four environments or private endpoints.
- Do not claim ADF→Gmail is proven as one end-to-end trace.
- Do not claim the report-reader Entra group is mapped into SQL.
- Do not reveal Key Vault secret values, SP secrets or callback signatures.

## Recommended screen order

1. KPMG page 1 — objective and technology choice.
2. KPMG page 2 — required business decision flow.
3. README architecture diagram — implemented translation.
4. `sql/002_sample_source.sql` — representative sources and config rows.
5. ADF master JSON or Azure canvas — Lookup/ForEach/reusable child.
6. `sql/003_stored_procedures.sql` — schema, watermark, gates and transaction.
7. Evidence screenshots — first, incremental, schema decision, failure/recovery.
8. Power BI `Overview` — operational result.
9. Architecture/security evidence — identities/firewalls/Key Vault.
10. Requirements matrix and limitations — honest close.

## 10-minute version

| Time | Screen | What to say |
|---:|---|---|
| 0:00–0:45 | KPMG page 1 | “The core problem is a configuration-driven pipeline that tolerates source schema change and handles first/subsequent loads.” |
| 0:45–1:30 | KPMG page 2 | Trace first load, schema changed, approval, old-schema load, two comparisons and success/failure. |
| 1:30–2:30 | README architecture | “One ADF framework and one SQL engine process every enabled metadata row.” Name components and one-environment prototype boundary. |
| 2:30–3:30 | Config + master pipeline | Show `Load=Yes`, FULL/WATERMARK, PK/watermark; show Lookup→ForEach→same child. |
| 3:30–5:00 | Stored procedure | Explain hash/RFC, captured watermark, stage, Gate 1, transaction, Gate 2 and watermark commit. Do not read code line by line. |
| 5:00–6:15 | Schema evidence | Explain additive pending/approved/rejected and breaking rename. Say why old-schema load is possible only if old columns exist. |
| 6:15–7:15 | Failure/recovery evidence | One table retries four times, other succeeds, parent records partial success and fails visibly; recovery later succeeds. |
| 7:15–8:10 | Power BI | Show cards, recent runs and table health. State one page/Import/three views. |
| 8:10–9:05 | Security | Entra-only SQL, ADF MI, Key Vault RBAC, SQL roles; public/firewalled prototype vs private production. |
| 9:05–10:00 | Matrix/limitations | Close with traceability and top production changes. Invite questions. |

## 15-minute version

Use the 10-minute flow, adding:

- 1 minute: why ADF + Azure SQL rather than Fabric/Databricks.
- 1 minute: draw the bounded-watermark timeline and rerun/idempotency logic.
- 1 minute: explain Gate 1 versus Gate 2 with transaction boundary.
- 1 minute: distinguish managed identity, service principal, Azure RBAC and SQL roles.
- 1 minute: CI validation, environment promotion and rollback strategy.

### Full panel cue table

| Time | Show | Say / key message | Do not say | Likely question → short answer |
|---:|---|---|---|---|
| 0:00 | Case page 1 | Client needs dynamic, approval-controlled loading | “Fabric was mandatory” | Why ADF? → Explicitly permitted and proportionate for relational prototype. |
| 0:45 | Case page 2 | Trace first/subsequent, RFC, old-schema and match gates | Pending means pipeline waits forever | Pending uses old approved columns when possible. |
| 1:45 | Architecture | One control plane, one reusable data path | Four environments were deployed | One prototype environment; four are production topology. |
| 3:00 | Config | Behavior is metadata, not table-specific branches | Any arbitrary table works without validation | A conforming, validated row becomes eligible. |
| 4:00 | ADF | Lookup→ForEach→same child; table isolation | Retry metadata drives ADF | Retry is fixed at 3/15 in this prototype. |
| 5:00 | Watermark | Stable bounded window; watermark commits with data | Late data can never be missed | Old-timestamp late records need lookback/CDC. |
| 6:00 | Stage/gates | Gate 1 protects; Gate 2 verifies transactional publish | Row counts prove value equality | Production adds hashes and business rules. |
| 7:15 | RFC evidence | All changes require approval; breaking ones fail safely | Approval automatically migrates types | Existing target types are not auto-altered. |
| 8:30 | Failure evidence | Four attempts, peer succeeds, parent partial then failed | All errors deserve retries | Production classifies transient/permanent errors. |
| 9:30 | Logic App | Notification is decoupled from load result | ADF→Gmail trace is fully proven | ADF→Logic App and Gmail send are separate evidence. |
| 10:30 | Security | MI, Key Vault, RBAC and SQL roles are separate layers | Public endpoint is production ideal | It is a firewalled prototype exception. |
| 11:45 | Power BI | One-page imported operational report | Three report pages/service publication | Extra SQL views are future report options. |
| 12:45 | CI/Bicep | PR validation without cloud mutation | CI deploys Azure | CD is a production recommendation. |
| 13:45 | Limitations/matrix | Honest boundary and priority improvements | “100% production-ready” | Correct prototype, with documented production gaps. |
| 14:45 | Closing | Reusable, safe, auditable and explainable | Overrun the close | Offer depth on watermark/schema/security. |

## 20-minute version

Use the 15-minute flow, adding:

- 2 minutes: execute or replay one approved-additive schema scenario.
- 1 minute: explain notification decoupling and the exact evidence boundary.
- 1 minute: production on-prem/private-network architecture.
- 1 minute: map the design to Databricks/Fabric and explain when they become better choices.

## Opening script

“I treated the supplied KPMG PDF as the source of truth. The explicit requirement was not simply to copy a table; it was to build a configuration-driven process that handles first and subsequent loads, detects random schema changes, obtains approval, continues with the last approved schema when possible, reconciles data and makes failures recoverable. I chose ADF plus Azure SQL because it was explicitly permitted and fit a small relational prototype. I’ll first map the requirement to the architecture, then show the implementation and evidence, and finish with security, limitations and production evolution.”

## Click-by-click core demonstration

### 1. Establish the requirement

Open `tmp/pdfs/kpmg-page-1.png`, then `kpmg-page-2.png`.

Say:

- “A configuration row with `Load=Yes` must become eligible.”
- “Every schema change requires approval in this prototype.”
- “Rejected/not-yet-approved changes do not alter the target; old approved columns continue where possible.”
- “The exact keys, watermarks and reconciliation checks were not supplied, so I label those as assumptions.”

### 2. Show the dynamic control plane

Open `sql/002_sample_source.sql` at the configuration inserts, then `adf/pipeline_MasterMetadataDriven.json`.

Point to:

- two enabled rows and one disabled row;
- FULL and WATERMARK examples;
- Lookup filtering enabled rows;
- `ForEach` with `batchCount=2`;
- the same child receiving only `ConfigId` and parent run ID.

Say: “Adding a conforming fourth source requires a valid configuration row, not a fourth ADF pipeline.”

### 3. Explain the processing engine

Open `sql/003_stored_procedures.sql`. Use Find rather than scrolling blindly. Search in this order:

1. `ApprovedSchemaHash` — first-load versus subsequent-load decision.
2. `HASHBYTES` — schema fingerprint.
3. `LastWatermarkValue` — bounded window.
4. `Gate1` / reconciliation inserts — pre-publish validation.
5. `BEGIN TRANSACTION` — atomic publish boundary.
6. `Gate2` — post-publish validation.
7. watermark/config update and `COMMIT`.
8. `CATCH` / `ROLLBACK` — recovery.

Say: “The important point is the order, not the dynamic SQL syntax.”

### 4. Show evidence, not claims

Open [EVIDENCE.md](EVIDENCE.md), then the linked screenshots. Use this sequence:

1. successful first load;
2. incremental watermark change;
3. no-change rerun;
4. additive pending then approved;
5. additive rejected;
6. breaking rename with four failed attempts and peer-table success;
7. recovery;
8. Power BI overview;
9. identity/network evidence.

For each scenario say: action → expected control → observed evidence → remaining limitation.

### 5. Show Power BI

In Desktop, select the `Overview` page and fit page to view.

Point to:

- configured and enabled table counts;
- successful/failed or partial runs;
- rows processed and health indicators;
- recent runs;
- configured-table status and pending schema changes.

Say: “This is an imported operations snapshot. It is not a live business dashboard or a Power BI Service deployment.”

### 6. Show security

Use [ARCHITECTURE.md](ARCHITECTURE.md) and its screenshots. If Azure is available, show resource Overview/IAM without opening secret values.

Explain three separate layers:

1. Network: resource firewalls now; private endpoints/VPN or ExpressRoute in production.
2. Identity: Entra groups for people, managed identity for ADF, separate application identity for reporting demonstration.
3. Authorization: Azure RBAC for resources and SQL roles inside the database.

### 7. Close with honest production evolution

Open [DESIGN_DECISIONS.md](DESIGN_DECISIONS.md) or the limitations table in the master guide.

Name the first five improvements: private connectivity/environment isolation, concurrency lock, CDC/deletes, controlled type migrations/ITSM, centralized observability and end-to-end alert correlation.

## Optional live scenario: approved additive column

This changes the prototype database. Use it only if the environment is disposable and you understand the current state.

1. Capture before-state from configuration, curated schema, RFC and audit views.
2. Apply `sql/demo/02_additive_change.sql`.
3. Trigger the master pipeline.
4. Show RFC `PENDING`; show old approved schema continued.
5. Apply `sql/demo/03_approve_additive_change.sql`.
6. Trigger again.
7. Show approved version increment, nullable `RegionCode`, reconciliation PASS and success audit.
8. Do not reset afterward unless the panel asks and the reset is safe.

If any step is slow, switch to captured evidence immediately. A reliable explanation is stronger than waiting on a spinner.

## Optional whiteboard sequence

Draw four small diagrams:

```text
Config → Lookup → ForEach → Same child
```

```text
old watermark < included rows <= captured maximum
```

```text
Stage → Gate 1 → [transaction: publish → Gate 2 → watermark → commit]
```

```text
schema hash differs → PENDING → APPROVED / REJECTED
                         ↓
              old approved projection
```

Then add the exception: if an approved column was removed/renamed, the old projection is impossible and that table fails safely.

## Questions to invite

- “Would you like me to go deeper into watermark restartability or schema approval?”
- “Would it be useful to compare this implementation with a Fabric or Databricks version?”
- “I can also show the exact evidence for one-table failure isolation and recovery.”

## Recovery lines for difficult questions

- **Unknown client fact:** “The case does not specify that. For the prototype I assumed X; in discovery I would confirm Y before production design.”
- **Unimplemented control:** “That is not implemented, and I would not claim it is. The production approach would be…”
- **Why a limitation exists:** “I prioritized the case’s control flow and demonstrable recovery within the deadline. The trade-off is…, and the next change is…”
- **Unexpected live result:** “I will use the captured run evidence so we can discuss the intended and observed control without spending panel time troubleshooting the UI.”

## Closing script

“The result is intentionally not the most complex architecture. It meets the central KPMG behavior with one reusable pipeline, approval-controlled schema evolution, restartable loads, two reconciliation gates, failure isolation and auditable evidence. I have separated what is implemented from what belongs in production: private networking and environment isolation, CDC/delete handling, controlled type migration, enterprise ITSM, centralized monitoring and governed Power BI publication. That makes the prototype both defensible today and evolvable without overstating it.”

## After the presentation

- Do not merge or deploy based only on a panel conversation.
- Record requested changes as decisions with requirement, owner and evidence.
- Rotate any credential exposed during screen sharing.
- Reconcile any live demo mutation before reusing the environment.
