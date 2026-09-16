# Critique of the Supplied KPMG Process Flow

Status: Phase 2 critique only. These recommendations do not replace the KPMG business process unless Priya approves them.

## 1. Approval branch is visually ambiguous

**Provided approach:** Decision 5 asks `Approved?`; labels, the line to step 5.1, and the `To Step 4.1 / Load data with old scheme only` callout overlap conceptually.

**Concern:** The diagram does not unambiguously state what happens on approval, rejection, or continued loading with the old schema.

**Impact:** Implementers can reverse the branch or load an incompatible source into an old target, causing failures or silent data loss.

**Recommended improvement:** Define a state table and an explicit matrix: approved compatible change -> deploy new schema then resume; rejected/pending breaking change -> quarantine/stop that table; optionally continue only when an explicit backward-compatible projection is proven safe.

**Trade-off:** More states and governance records, but deterministic behavior and auditability.

## 2. `Does Data match` is undefined

**Provided approach:** Decisions 2 and 3 ask whether data matches across environments.

**Concern:** Row equality, row counts, checksums, key aggregates, tolerances, rejected records, and timing boundaries are unspecified.

**Impact:** A green result may be meaningless, or valid loads may fail because environments are compared at different source snapshots.

**Recommended improvement:** Define reconciliation per run/table with a shared extraction boundary, counts, rejected count, duplicate/null rules, and configured aggregate/hash checks. Record tolerance and evidence.

**Trade-off:** Stronger checks cost query time and compute; full-row hashes may be impractical at scale.

## 3. Environment promotion mixes code and data movement

**Provided approach:** The diagram refers to Dev-to-Test data move/deployment and then loading Integ/Prod.

**Concern:** Deployment pipelines normally promote code/configuration; copying production data through development environments can introduce privacy, cost, and consistency risks.

**Impact:** Sensitive data may be overexposed, and repeated cross-environment copies can be slow and difficult to reconcile.

**Recommended improvement:** Separate code/config promotion from data execution. Deploy the same versioned pipeline artifacts across environments; use masked/synthetic subsets in non-production unless production-like data is explicitly approved.

**Trade-off:** Test data management and environment-specific configuration require additional discipline.

## 4. Manual rerun/wait-for-next-run is operationally weak

**Provided approach:** After quality remediation, manually rerun or wait for the next configured run.

**Concern:** No durable restart point, ownership, or guarantee that corrected tables alone are rerun.

**Impact:** Long recovery time, accidental duplicate loads, and unnecessary reprocessing.

**Recommended improvement:** Persist table-level checkpoints and expose a controlled rerun mode for a failed run/table after remediation.

**Trade-off:** More orchestration metadata and operator procedures.

## 5. Schema changes are treated as one category

**Provided approach:** Any detected schema change enters alert/approval handling.

**Concern:** Adding a nullable column is materially different from dropping/renaming a column or narrowing a datatype.

**Impact:** Approving everything creates delays; auto-applying everything risks breakage or loss.

**Recommended improvement:** Classify changes. Safe candidates: additive nullable column or compatible widening, subject to policy. Breaking: removed/renamed columns, incompatible/narrowing type changes, nullable-to-non-nullable, key/watermark changes.

**Trade-off:** Classification logic must be tested for each supported source/target type system.

## 6. Loading with the old schema can silently discard data

**Provided approach:** A callout says `Load data with old scheme only`.

**Concern:** It is not stated whether new columns are intentionally projected out, whether removed columns are supplied as null, or what happens for incompatible changes.

**Impact:** Silent omission, mapping shifts, runtime conversion failures, or corrupted target meaning.

**Recommended improvement:** Allow old-schema projection only for explicitly compatible additive changes and log a warning/schema event. Block breaking changes until approved and deployed.

**Trade-off:** Some tables pause rather than continuing during governance delay.

## 7. First-load detection is unspecified

**Provided approach:** The pipeline asks `First Time Load?`.

**Concern:** It does not state whether this depends on target existence, row count, configuration, or audit history.

**Impact:** An emptied target may be mistaken for a first load, or a partial failed first load may be treated as incremental.

**Recommended improvement:** Base the decision on durable metadata: an approved schema version plus the last successful published load, with a controlled reset/reinitialize operation.

**Trade-off:** Operators must manage state intentionally.

## 8. No atomic publish boundary

**Provided approach:** `Load Data` does not distinguish staging from the consumer-visible table.

**Concern:** Failure halfway through a write can leave partial data visible.

**Impact:** Consumers see inconsistent data and reruns can duplicate rows.

**Recommended improvement:** Load into run-scoped staging, validate, then publish using a transaction/controlled `MERGE` or partition/table swap pattern appropriate to Azure SQL.

**Trade-off:** Extra storage and a more deliberate publish operation.

## 9. Incremental semantics and duplicate prevention are missing

**Provided approach:** Initial and subsequent loads are required, but no delta strategy is shown.

**Concern:** A timestamp watermark alone may miss rows with equal timestamps or updates committed after extraction begins.

**Impact:** Missing or duplicate data on normal runs and retries.

**Recommended improvement:** Use a closed extraction window, persist high watermark only after publish, include a deterministic key/tie-breaker, and upsert by key. Use full snapshot or source-native change tracking when no reliable watermark exists.

**Trade-off:** Upsert/change tracking is more complex than append-only copy.

## 10. Deletes and late-arriving updates are not addressed

**Provided approach:** The flow discusses loading and schema changes only.

**Concern:** Source deletes and delayed corrections may never reach the target.

**Impact:** Target diverges from source even when counts appear plausible.

**Recommended improvement:** Make delete handling a declared load policy: ignore, soft delete, snapshot replacement, or CDC-based propagation. Define a lookback/deduplication policy for late arrivals.

**Trade-off:** Correct delete propagation may require source features or heavier comparisons.

## 11. One table failure versus whole-run behavior is undefined

**Provided approach:** The process appears serial and pipeline-wide.

**Concern:** It does not specify fail-fast versus continue-independent-tables behavior.

**Impact:** One bad table can block all tables, or failures can be hidden in an overall success.

**Recommended improvement:** Capture table-level outcomes, continue independent tables within a controlled concurrency limit, and derive a clearly defined overall run result.

**Trade-off:** Aggregating failures and retrying selected tables adds orchestration logic.

## 12. Concurrency and configuration race conditions are absent

**Provided approach:** Enabled rows are read and processed, with no run snapshot or locking model.

**Concern:** Configuration or watermarks may change during a run; two triggers may process the same table concurrently.

**Impact:** Duplicate ingestion, lost watermark updates, or inconsistent behavior.

**Recommended improvement:** Snapshot configuration at run start, enforce one active run per table/environment or use optimistic concurrency, and update state conditionally.

**Trade-off:** Requires locking/state version logic and may queue overlapping schedules.

## 13. Retry policy does not distinguish failure type

**Provided approach:** Page 1 suggests automatic retries or alerting after a number of failures.

**Concern:** Retrying authentication, invalid schema, or data-quality failures wastes time and can intensify incidents.

**Impact:** Cost, noisy alerts, delayed diagnosis, and potentially repeated partial writes.

**Recommended improvement:** Retry only transient classes with bounded exponential backoff; fail fast on deterministic errors and route to remediation/approval.

**Trade-off:** Error classification needs maintained rules.

## 14. Configuration design is too thin for safe dynamic execution

**Provided approach:** The sample shows table, columns, load flag, connection parameters, and an ellipsis.

**Concern:** No source/target schema, load strategy, key/watermark, connection reference, or schema policy is defined. `Connection Parameters` could be misused for secrets.

**Impact:** Hard-coded logic reappears, metadata becomes unsafe, and credentials may leak.

**Recommended improvement:** Use validated normalized metadata and connection references; never store passwords/secrets in the table.

**Trade-off:** More metadata fields and validation procedures.

## 15. RFC execution is coupled ambiguously to data execution

**Provided approach:** Step 1.1 branches to an RFC lane; schema approval is also in the main run.

**Concern:** A long-running pipeline should not wait indefinitely for human approval, and the difference between business-initiated change and detected drift is unclear.

**Impact:** Run timeouts, orphaned executions, and poor auditability.

**Recommended improvement:** Create a durable RFC record and required notification rather than waiting inside the ADF run. If the last approved projection remains compatible, complete that table as `WARNING` using only approved columns; if it is no longer compatible, end it as `Blocked`/`FAILURE`. A later authorized run applies an approved version or records rejection/non-adoption.

**Trade-off:** Approval becomes asynchronous rather than visually continuous, and the operator must distinguish a compatible warning from an incompatible blocked table.

## 16. Security diagram lacks trust boundaries and access modes

**Provided approach:** Page 4 lists networking, RBAC, IAM, groups, and a service principal.

**Concern:** It does not identify which users access which service, private/public entry points, data entitlements, or whether external users are interactive people or applications.

**Impact:** Overprivileged users, exposed endpoints, incorrect licensing/tenant design, or misuse of service principals for people.

**Recommended improvement:** Define personas and paths: pipeline managed identity, admins/operators, report authors, internal viewers, external B2B viewers, and optional external application. Apply group-based roles, RLS where needed, private endpoints, and Conditional Access/MFA for people.

**Trade-off:** Requires identity/licensing decisions that are outside the supplied document.

## 17. Monitoring and alert ownership are missing

**Provided approach:** Success message and schema-change message are shown; failure alerting is only an example on page 1.

**Concern:** No metrics, log retention, alert recipient, escalation, correlation ID, or dashboard is specified.

**Impact:** Failures and drift may be noticed late and cannot be reconstructed reliably.

**Recommended improvement:** Correlate pipeline/table/activity runs, retain operational audits, emit actionable alerts after policy thresholds, and define owner/runbook links.

**Trade-off:** Monitoring adds small ongoing cost and operational ownership.

## 18. No explicit data-contract or consumer-impact check

**Provided approach:** Schema approval focuses on source and pipeline changes.

**Concern:** A technically loadable change may break semantic models, reports, or external consumers.

**Impact:** Successful ingestion can still cause downstream outages.

**Recommended improvement:** Include downstream dependency/contract checks in RFC review and version published schemas where compatibility cannot be maintained.

**Trade-off:** More coordination and slower rollout for breaking changes.

## 19. Page 2 step 5 is implemented asynchronously

**Classification:** **[A - KPMG REQUIRED, CLARIFIED BY PRIYA]** and **[C - DELIBERATE OPERATIONAL DEVIATION]**.

**Provided approach:** Page 2 shows `Send Schema Change Alert and Get Approval`, an `Approved?` decision, step 5.1 `Pipeline Schema Change Message`, and a callout to step 4.1 to load with the old schema. The original arrow placement is ambiguous. Priya clarified that pending/rejected changes must not be adopted and that the old approved columns continue when compatible.

**Concern:** Leaving a single ADF run waiting for a human decision risks timeout, cost, orphaned executions, and unclear recovery. Also, a removed/renamed/incompatible approved source column makes the old projection physically unsafe or impossible.

**Impact:** A literal long-running wait is operationally fragile. Blindly forcing an old projection could fabricate nulls, truncate values, or corrupt meaning.

**Recommended improvement:** Preserve the clarified business behavior but make approval asynchronous. Create immutable schema history and a durable `PENDING` RFC, send the required step 4.2 notification, and finish the compatible old-projection run as `WARNING`. A later run reads `APPROVED` or `REJECTED`. On rejection, send the required step 5.1 message confirming non-adoption and whether old-schema loading remains compatible. Fail the affected table safely if it is not compatible.

**Trade-off:** Approval is no longer represented by one continuously waiting pipeline run, but the result is restartable, auditable, and safer. This is an operational deviation, not a deviation from Priya's confirmed business outcome.
