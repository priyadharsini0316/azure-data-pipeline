# KPMG Metadata-Driven Azure Data Pipeline

Production-minded interview prototype implementing the supplied KPMG process with Azure Data Factory, Azure SQL Database, Key Vault, Logic Apps, Microsoft Entra ID, and a local Power BI Desktop project.

## What is implemented

- One metadata-driven ADF master pipeline reads every configuration row where `Load = 'Yes'` and invokes one reusable child pipeline.
- First load, full reload, watermark incremental loading, transactional replacement, retry, restartability, and duplicate prevention.
- Approval-controlled schema evolution with `PENDING`, `APPROVED`, and `REJECTED` RFC states. Every change requires approval; pending/rejected compatible changes load only the last approved projection.
- Row-count, key completeness, duplicate, null-key, and approved-schema reconciliation with persisted PASS/FAIL evidence.
- Entra-only Azure SQL, ADF managed identity, Key Vault RBAC, least-privilege reporting service principal, and a Logic App notification endpoint.
- Local PBIP pipeline-health report backed only by the `reporting` schema.
- Bicep infrastructure, repeatable SQL/ADF deployment scripts, scenario scripts, static tests, and interview documentation.

## Live prototype resources

All resources are in Canada Central under `rg-kpmg-kpmg-prototype`. The Azure SQL database uses the free-limit-enabled `GP_S_Gen5_1` serverless configuration with 0.5 minimum vCore, 60-minute auto-pause, 32-GB maximum size, and `AutoPause` free-limit exhaustion behavior.

Not provisioned: Private Endpoint, Private DNS, VNet/NSG, VPN Gateway, ExpressRoute, Azure Firewall, on-premises SHIR, Log Analytics, Storage Account, and paid Power BI/Fabric capacity. These are documented production options, not prototype claims.

## Start here

1. Read [docs/IMPLEMENTATION_GUIDE.md](docs/IMPLEMENTATION_GUIDE.md).
2. Review [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) and [docs/ASSUMPTIONS_AND_QUESTIONS.md](docs/ASSUMPTIONS_AND_QUESTIONS.md).
3. Use [docs/PRIYA_LEARNING_GUIDE.md](docs/PRIYA_LEARNING_GUIDE.md) and [docs/INTERVIEW_QA.md](docs/INTERVIEW_QA.md) for the panel.
4. Check actual delivery status in [docs/REQUIREMENTS_TRACEABILITY_MATRIX.md](docs/REQUIREMENTS_TRACEABILITY_MATRIX.md).

## Repository layout

- `infra/` — Bicep and Azure parameters
- `sql/` — framework, procedures, security, reporting views, and demo scripts
- `adf/` — linked services, dynamic dataset, master pipeline, and child pipeline
- `powerbi/` — local PBIP report and TMDL semantic model
- `scripts/` — post-provision and ADF deployment automation
- `tests/` — static and live SQL validation assets
- `docs/` — design, implementation, security, traceability, learning, and interview evidence
- `screenshots/` — genuine captured evidence only

No credentials or callback URLs are committed. Do not merge the feature branch until Priya approves the Pull Request.
