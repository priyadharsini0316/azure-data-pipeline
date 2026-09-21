# Design Decisions

[← README](../README.md)

## Key decisions

| Decision | Why | Trade-off |
|---|---|---|
| **ADF + Azure SQL** | Small relational workload; audit trail is easy to read in SQL; no paid capacity | Fabric fits better if the client already runs OneLake |
| **One metadata-driven pipeline** | New table = one config row; the same controls everywhere | Metadata must be validated carefully |
| **Every schema change needs approval** | Protects downstream reports | Manual delay |
| **Keep loading while a change is pending** | Data keeps flowing with the last approved columns and follows the Step 5.1/4.1 old-schema path | The case does not define a durable `PENDING` state, so asynchronous pending behavior is our prototype interpretation |
| **Fail safely on breaking changes** | Never invent or silently drop approved data | The table stops until fixed |
| **Staging + two gates + one-transaction publish** | Consumers never see unchecked or half-loaded data | An extra copy step |
| **Capture the watermark before loading** | Rows changed during a load aren't missed | Needs a reliable timestamp |
| **RFC stored in SQL** | Simple, auditable, easy to demo | Production would use ServiceNow or Jira |
| **Email sent after ADF gets its response** | Email problems can't fail a data load | Email failures only show in Logic App history |
| **One environment, narrow firewall** | Stays within the free allowance | Documented prototype exception |

## Alternatives considered

| Option | Best when |
|---|---|
| **ADF + Azure SQL** (chosen) | Relational ingestion with strong governance and audit |
| **Microsoft Fabric** | The client already standardises on OneLake and Fabric capacity |
| **Databricks** | Large, semi-structured, streaming or ML-heavy workloads |
| **Table-specific pipelines** | A few irregular sources that don't fit the metadata model |

- **Full vs incremental:** full load is simple and captures deletes; watermark load is efficient but needs trustworthy timestamps.
- **Auto vs approved schema changes:** auto-approving safe nullable columns reduces delay but can still break consumers.

## Issues found in Case study's process flow

- **Step 5 has no "pending" path.** Implemented as asynchronous: keep loading the old columns and apply the decision on the next run.
- **"Does data match" isn't defined.** Defined as row counts, key completeness, duplicates and approved schema, checked at two gates.
- **Loading the old schema can break.** If a column was removed or renamed, the table fails safely instead.
- **There's no atomic publish step.** Added staging plus a single-transaction publish with rollback.
- **Incremental rules and duplicate prevention are missing.** Added a watermark window and key-based publish.
- **Deletes aren't addressed.** Full load captures them; watermark load doesn't (see limitations).
- **Retries don't distinguish failure types.** Noted; a permanent schema failure still retries 3 times.
- **First-load detection isn't specified.** Defined as "no approved schema yet"; the first load is recorded as an `INITIAL_LOAD` approval.
- **One table failing vs the whole run isn't specified.** Tables are isolated; the run ends as `PARTIAL_SUCCESS` and ADF shows it as failed.
- **Code deployment and data approval are mixed together.** Kept as two separate tracks ([CICD_PROMOTION.md](CICD_PROMOTION.md)).

## Problems solved during the build

- **Key Vault name too long** → shortened to a deterministic name.
- **Logic App URL cut off by Windows shell parsing** → stored the value safely and never logged it.
- **A rejected schema could raise a new RFC on every run** → reuse the decision for the same schema fingerprint.
- **Retries were counted as extra tables** → count only the latest attempt per table.
- **ADF showed success on a partial failure** → finalize the audit, then raise the error.
- **Gmail returned 403 (missing scope)** → re-authorized the connector.
- **Power BI rejected a personal account** → created a tenant work account for reports.

## Limitations

- One environment stands in for Dev/Test/Integ/Prod.
- Watermark loads don't propagate hard deletes.
- Public endpoints with narrow firewall rules; no private networking.
- Gate 2's rollback path is code-reviewed but wasn't triggered live.
- Power BI runs in Desktop only, with a single overview page.
- `RetryCount`, `RetryIntervalSeconds`, and `ConnectionReference` exist in configuration, but the child pipeline currently uses one fixed linked service and hard-coded retry 3 / 15 seconds.
- `RowsInserted` and `RowsUpdated` are present in the audit table but are not populated.
- `NotificationAudit.DeliveryStatus` remains `PENDING`; Logic App delivery status is not written back to SQL.
- Overlapping master runs for the same `ConfigId` are not explicitly prevented and could contend for the shared staging table.
- Type/nullability evolution is detected, but existing target columns are not altered; renamed/dropped columns fail safely and incompatible type changes require engineering work.
- The Entra report-reader group exists, but group-to-SQL-role enforcement is not verified by the checked-in artifacts.
- The ADF-to-Logic-App path and Gmail send action are evidenced separately; the screenshots do not prove that the captured Gmail message originated from an ADF run.

## Next steps

- Power BI pages for schema changes and data quality (the views already exist).
- Automated deployment to multiple environments with approvals and OIDC sign-in.
- Auto-approval policy for safe nullable columns.
- Don't retry permanent errors; use CDC for deletes.
- Private networking, Log Analytics alerts and ITSM integration.
