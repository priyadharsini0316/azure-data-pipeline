# CI/CD and Environment Promotion

Status: **DOCUMENTED ONLY - NOT PROVISIONED.** The prototype runs in one Azure environment to keep cost at zero. This page shows how the same code would move from Dev to Prod in a real KPMG client setup.

## What KPMG's use case shows

- Page 1 diagram: four workspaces (**Dev -> Test -> Integ -> Prod**) connected by a "Dev to Test Data Move" and a "Deployment Pipeline".
- Page 2 bottom lane: *Business-initiated change -> Developer makes and tests the change in Test -> Deploy the changes to the pipelines -> Rerun the pipeline*.

So KPMG expects code to be **built once, tested, approved, and promoted** through environments, never edited directly in Prod.

## Simple explanation

Think of it like publishing a book. The author writes a draft (**Dev**), an editor checks it (**Test**), a proof copy is printed and compared with the draft (**Integ**), and only then is it sold in shops (**Prod**). The *same* manuscript moves forward. Nobody rewrites it at the printing press.

## 1. The promotion flow

```mermaid
flowchart LR
    DEV["Developer<br/>feature branch"] --> PR["Pull request<br/>peer review"]
    PR --> CI{"CI checks<br/>pass?"}
    CI -- No --> DEV
    CI -- Yes --> MERGE["Merge to main"]
    MERGE --> BUILD["Build one versioned<br/>release package"]
    BUILD --> D["Deploy to DEV<br/>smoke test"]
    D --> T["Deploy to TEST<br/>run demo scenarios"]
    T --> A1{"Test lead<br/>approves?"}
    A1 -- No --> DEV
    A1 -- Yes --> I["Deploy to INTEG<br/>Gate 2 data match"]
    I --> A2{"Change board<br/>approves RFC?"}
    A2 -- No --> DEV
    A2 -- Yes --> P["Deploy to PROD<br/>pause and resume triggers"]
    P --> MON["Monitor run<br/>success message"]
```

## 2. What the CI checks do (before merge)

```mermaid
flowchart TD
    START(["Pull request opened"]) --> J["Validate ADF pipeline JSON"]
    J --> B["Build and lint Bicep infrastructure"]
    B --> S["Check SQL scripts compile<br/>and naming rules"]
    S --> SEC["Scan for secrets<br/>no passwords in Git"]
    SEC --> TST["Run static tests<br/>Test-StaticImplementation.ps1"]
    TST --> R{"All green?"}
    R -- Yes --> OK(["Ready to merge"])
    R -- No --> FIX(["Developer fixes"])
```

## 3. What gets promoted, and what changes per environment

```mermaid
flowchart LR
    subgraph PKG["One release package - identical everywhere"]
        IAC["Bicep infrastructure"]
        SQL["SQL scripts<br/>tables, procedures, views"]
        ADF["ADF pipelines<br/>and datasets"]
        PBI["Power BI report"]
    end
    subgraph PARAMS["Environment settings - different per stage"]
        P1["SQL server and database name"]
        P2["Key Vault name"]
        P3["Integration runtime"]
        P4["Alert recipients"]
        P5["Concurrency and schedule"]
    end
    PKG --> DEPLOY["Deployment step"]
    PARAMS --> DEPLOY
    DEPLOY --> ENVS["Dev / Test / Integ / Prod"]
```

Secrets are **never** in the package. Each environment has its own Key Vault, and the pipeline signs in with a **federated identity** (no stored password).

## 4. Two different approvals - don't mix them up

```mermaid
flowchart TD
    subgraph CODE["Code change approval - CI/CD"]
        C1["Developer changes a pipeline or procedure"] --> C2["Release approved by test lead and change board"] --> C3["Promoted to Prod"]
    end
    subgraph DATA["Schema change approval - pipeline RFC"]
        D1["Source adds or renames a column"] --> D2["Pipeline raises RFC and alert"] --> D3["Data owner approves or rejects in SQL"] --> D4["Next run applies the decision"]
    end
    D3 -. "if new code is needed" .-> C1
```

## Mapping to KPMG and to this prototype

| KPMG item | Production design | Prototype today |
|---|---|---|
| Dev / Test / Integ / Prod | Separate resource groups or subscriptions, same package | One environment (cost choice) |
| Deployment pipeline | GitHub Actions or Azure DevOps, one build promoted | Manual `azd up` + `scripts/deploy-adf.ps1` |
| Developer tests change in Test | Automated scenario tests in Test | Live demo scenarios run in the one environment |
| Deploy changes to pipelines | ADF published by release, triggers paused/resumed | ADF published by script |
| Approval | GitHub Environments / Azure DevOps approval gates | Documented only |
| Secrets | Per-environment Key Vault, OIDC federated sign-in | Key Vault used; OIDC not configured |

## Talking points

1. "We build once and promote the same package, so what we tested is exactly what reaches Prod."
2. "Only environment settings change between stages. Secrets live in each environment's Key Vault."
3. "Pull requests run automatic checks, so broken JSON, bad SQL or leaked secrets never reach main."
4. "There are two approval tracks: the release approval for code, and the RFC approval for source schema changes. KPMG's bottom lane connects them."
5. "For cost, the prototype has one environment. The scripts are parameterised, so adding Test, Integ and Prod means new parameter files, not new code."
