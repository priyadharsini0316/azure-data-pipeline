# Metadata-Driven Azure Data Pipeline

> One configuration-driven Azure pipeline that loads any table marked `Load = Yes`, detects source schema changes, waits for approval, checks the data at two gates, retries, alerts and reports its own health.

![ADF](https://img.shields.io/badge/Azure%20Data%20Factory-V2-0078D4?logo=microsoftazure&logoColor=white)
![Azure SQL](https://img.shields.io/badge/Azure%20SQL-Serverless-0078D4?logo=microsoftsqlserver&logoColor=white)
![Entra ID](https://img.shields.io/badge/Entra%20ID-RBAC%20%7C%20Groups-0078D4?logo=microsoft&logoColor=white)
![Bicep](https://img.shields.io/badge/IaC-Bicep-5C2D91)
![Power BI](https://img.shields.io/badge/Power%20BI-Health%20report-F2C811?logo=powerbi&logoColor=black)
![CI](https://img.shields.io/badge/CI-GitHub%20Actions-2088FF?logo=githubactions&logoColor=white)

**Status:** live and verified in one Azure environment. Production networking and multi-environment promotion are designed, not provisioned.

**Contents:** [Problem](#problem) · [Solution](#solution) · [Architecture](#architecture) · [Pipeline flow](#pipeline-flow) · [Requirements](docs/REQUIREMENTS_TRACEABILITY_MATRIX.md) · [Live results](#live-results) · [Dashboard](#dashboard) · [Documents](#documents) · [Repo map](#repo-map) · [Quick start](#quick-start)

---

## Problem

- The client's on-prem source tables change shape without warning.
- They want **one pipeline** driven by a **configuration table**: every row with `Load = Yes` is loaded.
- It must handle **first and incremental loads**.
- **Schema changes** need an **alert** and **human approval**; if rejected, keep loading the old shape.
- Data must be **checked at Dev/Test and Integ/Prod**, with **success and failure messages** and **retries**.
- Access must be **secure** for internal and external users.

## Solution

- **One reusable pipeline:** ADF Lookup (`Load = Yes`) → ForEach → one parameterised child pipeline.
- **Adding a table** takes one config row; no new pipeline.
- **Load types:** `FULL` reload or `WATERMARK` delta (watermark captured before loading).
- **Schema detection:** a SHA-256 fingerprint of each table's columns, compared with the last approved version.
- **Approval workflow:** `PENDING` / `APPROVED` / `REJECTED`; the first load is recorded as `INITIAL_LOAD`.
- **Safe by default:**
  - While a change is pending or rejected, the old approved columns are loaded.
  - If an approved column is removed or renamed, only that table fails; the target stays untouched.
- **Two quality gates:**
  - **Gate 1** (source → `stg`): row count, duplicate or null keys, schema.
  - **Gate 2** (`stg` → `curated`): keys published, duplicates or nulls, row count. A failure rolls back.
- **Resilience:** 3 retries per table; failures stay isolated; reruns never duplicate data.
- **Alerts:** Gmail emails for success, schema change and failure, sent through a Logic App (email can never fail a load).
- **Security:**
  - Entra-only SQL and ADF managed identity.
  - Key Vault with RBAC.
  - 4 Entra groups, a service principal, and a read-only report user.
- **Delivery:** Bicep IaC, GitHub Actions PR checks, Power BI health report.

## Architecture

```mermaid
flowchart LR
    subgraph Azure["Azure - rg-kpmg-kpmg-prototype"]
        ADF["Data Factory<br/>managed identity"]
        subgraph SQL["Azure SQL (serverless)"]
            CTL[("ctl<br/>config")]
            SRC[("src<br/>source")]
            STG[("stg<br/>Dev/Test")]
            CUR[("curated<br/>Integ/Prod")]
            AUD[("audit + rfc")]
            REP[("reporting")]
        end
        KV["Key Vault"]
        LA["Logic App"]
    end
    ENTRA["Entra ID<br/>groups, SP, report user"]
    PBI["Power BI"]
    MAIL["Gmail"]

    CTL -->|"Load = Yes"| ADF
    ADF --> SRC --> STG -->|"Gate 1, publish, Gate 2"| CUR
    ADF --> AUD --> REP --> PBI
    ADF --> KV
    ADF --> LA --> MAIL
    ENTRA -.-> ADF & SQL & KV & PBI
```

- **KPMG mapping:** `src` = Source Prod · `stg` + Gate 1 = Dev/Test · `curated` + Gate 2 = Integ/Prod.
- **Not provisioned (cost):** VNet, private endpoints, VPN, firewall, SHIR, separate environments.
- More detail: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)

## Pipeline flow

```mermaid
flowchart TD
    S([Start]) --> L["Read config: Load = Yes"]
    L --> FE{{"For each table"}}
    FE --> FL{"First load?"}
    FL -->|Yes| INIT["Schema v1 + INITIAL_LOAD approval"]
    FL -->|No| CHG{"Schema changed?"}
    CHG -->|No| LOAD
    CHG -->|Yes| RFC["RFC + alert"]
    RFC --> DEC{"Decision"}
    DEC -->|Approved| LOAD
    DEC -->|"Pending / Rejected"| SAFE{"Old columns exist?"}
    SAFE -->|Yes| LOAD
    SAFE -->|No| FAIL
    INIT --> LOAD["Load approved columns to stg"]
    LOAD --> G1{"Gate 1"}
    G1 -->|Fail| FAIL["FAILURE<br/>curated untouched"]
    G1 -->|Pass| PUB["Publish to curated"]
    PUB --> G2{"Gate 2"}
    G2 -->|Fail| FAIL
    G2 -->|Pass| OK["SUCCESS + alert"]
    FAIL --> RT{"Retries left?"}
    RT -->|Yes| FL
    RT -->|No| ALERT["Failure alert"]
    OK --> E([Finalize run audit])
    ALERT --> E
```

## Live results

| # | Scenario | Result |
|---|---|---|
| 1 | First load | ✅ Both tables loaded; `Load = No` skipped; gates pass |
| 2 | Incremental | ✅ Only 2 changed rows loaded |
| 3 | Rerun | ✅ 0 new rows, no duplicates |
| 4 | New column → approved | ✅ Schema v2 with `RegionCode` |
| 5 | New column → rejected | ✅ Old columns kept |
| 6 | Renamed column | ✅ That table failed after 4 attempts with alerts; the other table succeeded; data untouched |
| 7 | Restore and rerun | ✅ Both tables succeed |

Screenshots and run IDs: [docs/EVIDENCE.md](docs/EVIDENCE.md)

## Dashboard

![Power BI pipeline health](screenshots/powerBI/PowerBI_home.png)

- Shows configured and enabled tables, run outcomes, pending changes, gate failures, retries, and per-table health.
- Reads only the `reporting` schema, as a read-only Entra user.

## Documents

| Document | What's inside |
|---|---|
| [ARCHITECTURE.md](docs/ARCHITECTURE.md) | Diagrams, components, security, IP plan, production design |
| [DESIGN_DECISIONS.md](docs/DESIGN_DECISIONS.md) | Choices, trade-offs, flow issues in case study, limitations |
| [CICD_PROMOTION.md](docs/CICD_PROMOTION.md) | PR checks and Dev → Prod promotion |
| [REQUIREMENTS_TRACEABILITY_MATRIX.md](docs/REQUIREMENTS_TRACEABILITY_MATRIX.md) | Every KPMG requirement → how it was met → evidence |
| [EVIDENCE.md](docs/EVIDENCE.md) | Screenshots grouped by topic |

## Repo map

```text
.github/workflows/   PR validation
adf/                 Data Factory pipelines, dataset, linked services
infra/               Bicep (SQL, ADF, Key Vault, Logic App, Gmail)
sql/                 framework, procedures, security, views, demo/
scripts/             post-provision and ADF deploy
tests/               static and scenario checks
powerbi/             Power BI project
screenshots/         evidence
docs/                documentation
```

## Quick start

```powershell
az login
azd env new <env-name>
azd provision                 # infra + SQL (scripts/postprovision.ps1)
./scripts/deploy-adf.ps1 -SubscriptionId <id> -ResourceGroup <rg> -FactoryName <adf> `
  -SqlServerFqdn <fqdn> -SqlDatabaseName <db> -KeyVaultName <kv>
```

- Trigger `MasterMetadataDriven` in ADF Studio.
- Replay the scenarios with `sql/demo/00`–`07` (reset, incremental, pending, approve, reject, breaking, restore).
