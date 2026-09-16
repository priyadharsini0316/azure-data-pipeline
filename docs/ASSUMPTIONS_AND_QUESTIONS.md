# Assumptions and Questions Register

Last updated: 2026-09-16

Status: Design and implementation approved. Live prototype deployed and tested; remaining user actions are final portal screenshots, Power BI refresh/save, PR review, and later cleanup approval.

## Confirmed directly from KPMG

1. The source model is subject to random schema changes.
2. A configuration table controls eligibility; rows with `Load = Yes` are considered for loading.
3. The implementation may use Azure SQL + Data Factory or Microsoft Fabric.
4. Fabric is recommended for client consistency but explicitly not mandatory.
5. Initial and subsequent loads, success and failure handling, screenshots, and understandable documentation are expected.
6. The supplied process may be critiqued.
7. The security design must address secure on-premises/cloud connectivity, IP/routing/firewalls, RBAC, MFA/IAM, groups, least privilege, internal/external access, and application identity.

## Open questions - decisions required from Priya

The original critical questions were answered on 2026-09-15. Items below are retained as an audit trail; their resolutions are recorded in the decisions log.

### Q1 - Deadline and deliverable boundary (critical)

- What is the exact submission/presentation date and time, including time zone?
- Must the final demonstration use live Azure resources, or is a deployment-ready repository plus local/test evidence acceptable?

Why it matters: determines how much live infrastructure, Power BI, screenshot evidence, and hardening can realistically be completed.

### Q2 - Platform choice (critical)

Should the prototype use:

- ADF + Azure SQL (preliminary recommendation for a focused, explainable prototype), or
- Microsoft Fabric (closer to the client's pictured medallion environment)?

Why it matters: changes orchestration artifacts, target storage, deployment, security, screenshots, and cost/licensing.

### Q3 - Actual source and sample data (critical)

- What is the source engine (on-prem SQL Server, files, another database, or a simulated source)?
- Are sample schemas/data available?
- Do tables have stable primary keys and reliable `last modified`/sequence columns?
- Must deletes be propagated?

Why it matters: governs linked services/gateway, copy queries, incremental correctness, merge keys, and delete handling.

### Q4 - Azure/Fabric access and budget (critical before implementation)

- Does the Azure Free Account currently expose the guarded Azure SQL free offer and `GP_S_Gen5_1` in Canada Central? This is a deployment-time stop/go check; paid Fabric/Power BI capacity is explicitly excluded.
- Which tenant, subscription/resource group, region, and naming constraints apply?
- What spending limit is acceptable?

Access that would later be needed for a live Azure implementation:

1. Access: least-privilege contributor access to the approved resource group, permission to create/use ADF, Azure SQL, Key Vault, and Logic Apps, plus Entra read/group/app permissions only where required. Private endpoints and Private DNS are explicitly out of scope.
2. Why: to deploy, configure identities/networking, run the pipeline, and capture genuine evidence.
3. Intended actions: only the resources listed in an approved implementation plan; no tenant-wide changes.
4. Can proceed without it: design and local/deployment-ready artifacts can proceed; live deployment, portal screenshots, identity/network validation, and end-to-end cloud proof cannot.

This historical access question was resolved by Priya's approval; deployment was performed only within the approved prototype scope.

### Q5 - Schema-change governance (critical)

- Must every schema change require approval exactly as the supplied flow suggests?
- Or may safe additive changes (for example, a nullable added column) be auto-accepted while breaking changes require approval?
- Who is the approver, and may a table continue using an explicit old-column projection while approval is pending?

Why it matters: determines whether the framework blocks, auto-evolves, or continues in compatibility mode.

### Q6 - Meaning of page 2 decision 5 (critical)

Please confirm the intended behavior after `Approved?`:

- On `Yes`, should the new target/pipeline schema be deployed and the load resume?
- On `No`, should the affected table stop, or should it load only the old approved columns?

The visual is readable, but the arrows/callout do not establish this unambiguously.

### Q7 - Environment scope

Does the prototype need four separate Dev/Test/Integ/Prod environments/workspaces/databases, or may it demonstrate environment promotion logically within a smaller footprint?

Why it matters: affects cost, setup time, data movement, and screenshot volume.

### Q8 - Reconciliation definition

What does KPMG/the recruiter expect `Does Data match` to prove: exact row equality, counts, key aggregates, checksums, or a reasonable prototype combination?

Why it matters: exact comparisons can be expensive and require a consistent source snapshot.

### Q9 - External-user access mode (critical for security architecture)

Are external users expected to:

- view Power BI reports,
- query Azure SQL/Fabric directly, or
- access data through an application/API?

Are they in partner Entra tenants?

Why it matters: Entra B2B + Power BI/RLS, direct SQL permissions, and service-principal application access are different designs.

### Q10 - RFC and notifications

Is there an expected RFC/approval tool (ServiceNow, Azure DevOps, email/Teams, or a prototype SQL approval table)? Which notification channel is available?

Why it matters: the case requires the process, but not a specific integration. A SQL-backed simulated approval is simplest if no tool is required.

### Q11 - GitHub publication

The supplied repository URL is `https://github.com/priyadharsini0316/azure-data-pipeline`. After design approval, should changes be pushed directly to its current branch, or should a `codex/...` branch and pull request be used?

Why it matters: pushing is an external state change and should follow the desired review path. Nothing has been pushed.

## Confirmed prototype assumptions

1. **[D - ASSUMPTION, ACCEPTED FOR PROTOTYPE]** Use a representative relational source and synthetic data because KPMG did not specify the source technology or supply data.
2. **[D - ASSUMPTION, ACCEPTED FOR PROTOTYPE]** Give representative tables stable primary keys and `LastModifiedUtc` watermarks; source-side hard-delete propagation is outside the watermark prototype and is documented as a limitation.
3. **[D - ASSUMPTION, ACCEPTED FOR PROTOTYPE]** Support `FULL` and `WATERMARK` strategies; use full snapshot when no trustworthy key/watermark exists.
4. **[D - ASSUMPTION, ACCEPTED FOR PROTOTYPE]** One table may fail without preventing independent tables from completing; overall run status exposes partial failure.
5. **[D - ASSUMPTION, ACCEPTED FOR PROTOTYPE]** `Does Data match` means row counts, key completeness, duplicate/null validation, and approved-schema validation, recorded as `PASS`/`FAIL`.
6. **[D - ASSUMPTION, ACCEPTED FOR PROTOTYPE]** External business consumers use Power BI; direct database access is limited to authorized technical identities.
7. **[D - ASSUMPTION, ACCEPTED FOR PROTOTYPE]** No secrets are stored in configuration. Managed identity is preferred; Key Vault holds any unavoidable secret.

## Risks

| Risk | Consequence | Proposed mitigation | Status |
|---|---|---|---|
| Deadline is less than one day away | Scope may exceed available time | Prioritize the approved live MVP and mark incomplete evidence honestly | Active |
| Source schema/data unavailable | Prototype could be mistaken for a client data model | Use accepted synthetic representative tables and label keys/watermarks/deletes as assumptions | Resolved by D-007 |
| No Azure/Fabric access | No live run or authentic portal screenshots | Approved Azure access was used for live deployment; remaining portal captures are listed | Resolved |
| Page 2 approval ambiguity | Incorrect business behavior | Use Priya's confirmed old-approved-projection interpretation plus compatibility safety guard | Resolved by D-009 |
| No reliable key/watermark | Missed/duplicate increments | Full snapshot or source-native change tracking; do not fake incremental guarantees | Open |
| External access mode not stated by KPMG | Wrong identity/network architecture | Use Priya-approved Power BI/B2B prototype assumption | Resolved by D-012 |
| Four environments may be costly | Time/cost overrun | One physical prototype environment; document production topology | Resolved by D-010 |
| Automatic drift may break consumers | Report/data contract outage | Compatibility classification, approval, schema history, dependency testing | Open |
| Existing uncommitted repo content | Accidental overwrite | Work isolated on `feature/kpmg-data-pipeline`; unrelated temporary files ignored | Mitigated |
| `Old schema only` is impossible after removal/rename of an approved source column | Runtime failure or fabricated data | Preflight approved projection; affected table fails safely while independent tables continue | Implemented and tested |
| Deadline stated as EST during Toronto daylight-saving time | One-hour interpretation difference | Treat deadline as 2:00 PM Toronto local time on 2026-09-16 unless Priya says fixed UTC-5 | Open clarification, does not block design |

## Decisions log

| ID | Decision | Owner | Date | Rationale |
|---|---|---|---|---|
| D-001 | PDF is the authoritative source; Markdown is only a cross-check | Priya/KPMG request | 2026-09-15 | Explicit user instruction |
| D-002 | No implementation or cloud action before design approval | Priya | 2026-09-15 | Explicit approval gate |
| D-003 | Do not store connection secrets in pipeline configuration | Pending Priya approval | - | Proposed least-privilege design |
| D-004 | Submission target is 2:00 PM EST on 2026-09-16 | Priya | 2026-09-15 | Explicit deadline |
| D-005 | Deliver a live Azure prototype | Priya | 2026-09-15 | Explicit implementation target |
| D-006 | Use Azure Data Factory + Azure SQL | Priya | 2026-09-15 | Selected permitted KPMG option |
| D-007 | Use representative relational source and synthetic data; label keys/watermarks/deletes as assumptions | Priya | 2026-09-15 | Source details absent from case |
| D-008 | Require approval for every detected schema change; safe auto-accept is future optimization only | Priya | 2026-09-15 | Follow KPMG process literally |
| D-009 | Pending/rejected schema changes continue with last approved projection and generate schema-change record/message | Priya | 2026-09-15 | Interpretation of page 2 step 4.1/5.1 |
| D-010 | Use one reduced-cost prototype environment; document Dev/Test/Integ/Prod and CI/CD for production | Priya | 2026-09-15 | Deadline/cost decision |
| D-011 | Prototype reconciliation uses count, key completeness, duplicate/null, and approved-schema validation | Priya | 2026-09-15 | KPMG did not prescribe criteria |
| D-012 | External consumers use Power BI; direct database access is technical-only; application/API is future scope | Priya | 2026-09-15 | Prototype access assumption |
| D-013 | Use Azure SQL RFC table with PENDING/APPROVED/REJECTED; ITSM integration is future scope | Priya | 2026-09-15 | Prototype approval mechanism |
| D-014 | After implementation approval, work on `feature/kpmg-data-pipeline`, open PR to `main`, and do not merge without approval | Priya | 2026-09-15 | Git workflow |
| D-015 | **SUPERSEDED by D-019.** Earlier plan to provision private endpoints/private DNS | Priya | 2026-09-15 | Retained for decision history only; must not be implemented |
| D-016 | VPN Gateway, ExpressRoute, Azure Firewall, and on-premises SHIR remain documented only because the prototype source is synthetic Azure SQL and does not require corporate-network connectivity | Design scope | 2026-09-15 | Avoid cost and false evidence for infrastructure not needed by the live prototype |
| D-017 | Use literal `Load` values `Yes`/`No` with a CHECK constraint rather than `LoadEnabled` bit | Design gap closure | 2026-09-15 | Matches KPMG page 3 exactly while preserving validation |
| D-018 | Provision one shared Logic App for required success, exhausted-failure, schema-change, and rejection notifications | Design gap closure | 2026-09-15 | Implements page 2 steps 3.1, 4.2, and 5.1 plus page 1 retry alert example |
| D-019 | Never provision Azure SQL Private Endpoint, Key Vault Private Endpoint, Private DNS, paid Power BI capacity, or paid Fabric capacity for this prototype | Priya | 2026-09-15 | Explicit Azure Free Account constraint; supersedes D-015 |
| D-020 | Use SQL/Key Vault secured public endpoints: Priya current-IP rules, the Azure-services SQL firewall exception required by ADF AutoResolve Azure IR, managed identity, TLS, and least privilege | Priya/design | 2026-09-15 | Simplest end-to-end path without prohibited networking resources |
| D-021 | SQL must be `GP_S_Gen5_1`, General Purpose serverless Standard-series Gen5, 0.5–1 vCore, 32 GB, 60-minute auto-pause, free-offer exhaustion set to auto-pause until next month | Priya/design | 2026-09-15 | Avoid paid overage; stop if the free offer/SKU/region is unavailable |
| D-022 | Retain Key Vault Standard only for the KPMG service-principal demonstration and an unavoidable Logic App secret; managed identity remains the runtime default | Design | 2026-09-15 | Page-4 evidence without storing secrets in configuration |
| D-023 | Retain Logic App Consumption for visible messages; Azure SQL remains the authoritative RFC/approval state | Design | 2026-09-15 | SQL-only state does not itself send the page-2 messages |
| D-024 | Do not provision Log Analytics or Storage for the MVP | Design | 2026-09-15 | ADF Monitor plus SQL audits suffice; SQL-to-SQL copy needs no file staging |

## Gap-closure assumptions

1. **[D - PROTOTYPE ASSUMPTION]** `GATE_1_PRE_PUBLISH` compares `src` with `stg`; `GATE_2_POST_PUBLISH` compares `stg` with `curated`. KPMG requires two match decisions but does not define their algorithms.
2. **[D - PROTOTYPE ASSUMPTION]** Three retries after the initial attempt, with a default 60-second interval, are sufficient to demonstrate the configurable retry requirement.
3. **[D - PROTOTYPE ASSUMPTION]** A Consumption Logic App delivering to Priya's approved email or Teams destination is an acceptable implementation of KPMG's required messages.
4. **[D - PROTOTYPE ASSUMPTION]** A short-expiry client secret is used only because KPMG page 4 explicitly asks for an app-registration secret demonstration. Managed identity remains preferred for ADF runtime.
5. **[D - PRODUCTION DESIGN ASSUMPTION]** A future production spoke could use `10.30.0.0/16`, subject to client network validation. No VNet or subnet is provisioned for the prototype.
6. **[D - LICENSING DEPENDENCY]** Entra PIM/access reviews/Conditional Access and Power BI external sharing are implemented only if tenant permissions and licences exist; otherwise they are accurately documented as not implemented.
