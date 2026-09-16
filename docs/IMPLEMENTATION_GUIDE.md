# Implementation Guide

## Prerequisites

- Azure subscription access with rights to deploy Bicep and create Entra applications.
- Azure CLI, Azure Developer CLI, Bicep, `sqlcmd`, Git, PowerShell 7, Power BI Desktop, and Node.js 20+.
- Current developer public IP added narrowly to Azure SQL and Key Vault firewalls.
- Power BI Desktop signed in with an organizational account allowed to read the SQL `reporting` schema.

## Deploy infrastructure

```powershell
az login
az account set --subscription e106c2e0-4edf-4b3f-8078-958c232b541f
azd env select kpmg-prototype
azd provision
```

The deployment creates Azure SQL, ADF, Key Vault Standard, and a Consumption Logic App. Review `infra/main.parameters.json` before any new environment. Private networking and paid Power BI/Fabric capacity are intentionally excluded from this reduced-cost prototype.

## Deploy SQL and ADF

`scripts/postprovision.ps1` deploys the SQL framework and grants the ADF system-assigned managed identity the custom `db_kpmg_pipeline_executor` role. `scripts/deploy-adf.ps1` publishes the linked services, parameterized dataset, child pipeline, and master pipeline.

SQL deployment order:

1. `sql/001_create_framework.sql`
2. `sql/002_sample_source.sql`
3. `sql/003_stored_procedures.sql`
4. `sql/004_security_template.sql`
5. `sql/005_reporting_identity.sql` after the reporting app registration exists
6. `sql/006_powerbi_reporting_views.sql`

## Configure a table

Insert one row into `ctl.PipelineConfiguration`. Source/target names, load strategy, key, and optional watermark are metadata—not ADF hard-coding. Set literal `Load` to `Yes` to make the table eligible; `No` rows are skipped.

Use `WATERMARK` only when the timestamp or increasing key is stable, non-null for changed rows, and updated for every mutation. Use `FULL` when no trustworthy watermark exists. Hard deletes are an explicit prototype assumption/out-of-scope item; production can add soft-delete flags, change tracking, CDC, or periodic anti-join reconciliation.

## Run the pipeline

Trigger `MasterMetadataDriven`. It starts a run audit, looks up enabled rows, executes `ProcessConfiguredTable` concurrently with batch count 2, finalizes the audit, and fails the ADF master run if any table's latest attempt failed. Retries create attempt rows, but pipeline totals count only the latest outcome per `ConfigId`.

### First load

With no approved hash and no target, the procedure records schema version 1, creates the target from the approved projection, loads, reconciles, and advances the watermark only after success.

### Incremental load and rerun

Run `sql/demo/01_incremental_change.sql`, then trigger the pipeline. The framework selects rows above the last watermark, deletes matching target keys inside the same transaction, inserts the delta, validates, and commits. A rerun with no new watermark produces no duplicates.

### Schema-change demonstrations

- Pending additive: `02_add_column_pending.sql`; the old projection loads while the RFC is PENDING.
- Approve: `03_decide_latest_rfc.sql`; the next run adopts a new version and target column.
- Reject: `04_add_column_for_rejection.sql`, trigger, then `05_reject_latest_rfc.sql`; later runs reuse REJECTED without duplicate RFCs.
- Breaking: `06_breaking_change.sql`; the renamed approved column fails after initial plus three retries while the other table succeeds. Run `07_restore_breaking_change.sql` and trigger again to prove restartability.

## Reconciliation status

- `SUCCESS`: all configured checks pass.
- `WARNING`: reserved for future non-blocking rules; the prototype does not silently downgrade a failed gate.
- `FAILURE`: a row-count, key-completeness, duplicate/null-key, approved-schema check, or load operation fails.

Evidence is stored in `audit.ReconciliationResult`, `audit.TableLoadAudit`, and `audit.PipelineRunAudit`.

## Power BI

Open `powerbi/KPMG Pipeline Health.pbip`, select **Refresh now**, and authenticate with an organizational account. The model imports only three `reporting` views and contains no secret. The page shows headline health metrics, recent runs, and configured-table status.

## Security

- Azure SQL is Entra-only.
- ADF uses managed identity and a custom least-privilege executor role.
- Key Vault uses RBAC and default-deny firewall rules.
- The reporting service principal can select only `reporting`; direct `curated` access was tested and denied.
- Its prototype secret expires in two days and is stored in Key Vault. Prefer workload identity or a certificate in production.
- Internal/external business users consume through Power BI; direct SQL is restricted to technical identities.

## Screenshots and cleanup

Follow `docs/SCREENSHOT_CHECKLIST.md`; never fabricate screenshots. After evidence and PR review, Priya may separately authorize deletion of the resource group and demo app registration. Cleanup is not automatic because it is destructive.
