# CI/CD and Environment Promotion

[← README](../README.md)

- **Live:** pull-request checks in [.github/workflows/ci.yml](../.github/workflows/ci.yml).
- **Designed only:** promoting one package through Dev → Test → Integ → Prod.
- **Why it matters:** KPMG's diagram shows Dev → Test → Integ → Prod joined by a *deployment pipeline*, with changes built and tested in Test before they're deployed.

## Pull-request checks (live)

```mermaid
flowchart LR
    PR(["Pull request to main"]) --> J["Parse ADF JSON"] --> B["Build Bicep"] --> T["Static tests"] --> S["Secret scan (gitleaks)"] --> R{"All green?"}
    R -->|Yes| OK(["Ready to merge"])
    R -->|No| FIX(["Fix and push"])
```

- No cloud login and no deployment, so the checks are safe and free.

## Promotion flow (designed)

```mermaid
flowchart LR
    DEV["Feature branch"] --> PR["PR + review"] --> CI{"CI"}
    CI -->|pass| M["Merge"] --> B["Build one package"]
    B --> D["Dev"] --> T["Test<br/>demo scenarios"] --> A1{"Approve"}
    A1 --> I["Integ<br/>Gate 2 match"] --> A2{"Change board"}
    A2 --> P["Prod<br/>pause and resume triggers"]
```

- **Build once, promote the same package:** what was tested is exactly what reaches Prod.
- **Only settings change per environment:** SQL server, Key Vault, integration runtime, alert recipients, schedule.
- **No stored secrets:** each environment has its own Key Vault, and the pipeline signs in with OIDC federation.

## What gets promoted

```mermaid
flowchart LR
    subgraph PKG["Same package everywhere"]
        IAC["Bicep"]
        SQLS["SQL scripts"]
        ADFP["ADF pipelines"]
        PBIX["Power BI"]
    end
    subgraph CFG["Per-environment settings"]
        C1["Server and DB"]
        C2["Key Vault"]
        C3["IR and schedule"]
    end
    PKG --> DEP["Deploy"]
    CFG --> DEP
    DEP --> ENV["Dev / Test / Integ / Prod"]
```

## Two separate approval tracks

```mermaid
flowchart TD
    subgraph CODE["Code release (CI/CD)"]
        C1["Change pipeline or SQL"] --> C2["Test + change-board approval"] --> C3["Promote to Prod"]
    end
    subgraph DATA["Schema change (pipeline RFC)"]
        D1["Source column changes"] --> D2["RFC + alert"] --> D3["Data owner approves or rejects"] --> D4["Next run applies it"]
    end
    D3 -.->|"if new code is needed"| C1
```

## Prototype vs production

| Item | Prototype | Production |
|---|---|---|
| Environments | One | Dev, Test, Integ, Prod |
| Deployment | `azd provision` + script | GitHub Actions / Azure DevOps release |
| Approvals | — | Environment approval gates |
| Sign-in | Developer login | OIDC federated identity |
