# Deployment Log

## 2026-09-16 — Live implementation and validation

- Deployed `rg-kpmg-kpmg-prototype` in Canada Central with Azure SQL, ADF, Key Vault Standard, and a Consumption Logic App.
- Verified Azure SQL `GP_S_Gen5_1`, 0.5 minimum vCore, 1 maximum vCore, 32-GB maximum size, 60-minute auto-pause, free limit enabled, and `AutoPause` exhaustion behavior.
- Confirmed no Private Endpoint, Private DNS, VNet/NSG, VPN Gateway, ExpressRoute, Azure Firewall, SHIR, Log Analytics, Storage Account, or paid Power BI/Fabric capacity was provisioned.
- Deployed configuration, audit, reconciliation, schema history, RFC, notification, source, staging/curated, reporting, and stored-procedure objects.
- Published ADF linked services, parameterized dataset, `MasterMetadataDriven`, and `ProcessConfiguredTable`.
- Granted ADF managed identity custom least-privilege SQL execution rights and Key Vault Secrets User RBAC.
- Stored the Logic App callback endpoint in Key Vault. Corrected a Windows command-shell ampersand parsing issue and replaced the affected secret with a complete latest version; no value was committed.
- Created short-lived reporting app `sp-kpmg-report-reader-466kwo`, stored its two-day credential in Key Vault, and verified reporting-view SELECT succeeds while curated-table SELECT is denied.
- Live scenarios: first load succeeded; incremental update/insert succeeded; idempotent rerun preserved four distinct keys; additive schema change was PENDING then APPROVED as version 2; a second additive change was REJECTED and did not enter the target; a breaking rename produced one independent success, one failed table, four attempts, audit PARTIAL_SUCCESS, and ADF Failed; restoration returned the next run to success.
- Fixed two defects found by live tests: rejected-hash RFC deduplication and retry-aware latest-outcome aggregation. Also made ADF master status fail after audit finalization when any table failed.
- Created and validated the local PBIP. PBIR validation returned zero errors and warnings; Desktop opened the report and recognized 3 import tables and 8 measures. Data refresh remains a user organizational-account action because credentials are not embedded and the modeling MCP is intentionally read-only.
- Created tenant-native work account `powerbi-reader@priyadharsini0316gmail.onmicrosoft.com` after Power BI Desktop rejected Priya's personal Microsoft account. Granted only membership in `db_kpmg_reporting_reader`, verified that the role has only `SELECT` on the `reporting` schema, and stored the first-sign-in temporary password in Key Vault as `powerbi-reporting-user-temporary-password`. No Azure RBAC role or Power BI licence was assigned.


## 2026-09-15 — Azure Free Account plan revision (documentation only)

- Revised the pre-deployment architecture and security plan to use ADF AutoResolve Azure IR with Azure SQL/Key Vault secured public endpoints, managed identity, TLS, least privilege, Priya's current-IP rule, and the Azure-services SQL firewall exception.
- Fixed the planned Azure SQL selection at `GP_S_Gen5_1` (General Purpose serverless, Standard-series Gen5, 0.5–1 vCore, 32 GB, 60-minute auto-pause) with free-offer exhaustion set to auto-pause until the next month.
- Retained Key Vault Standard only for the service-principal/notification secret demonstration and retained Logic App Consumption for required messages.
- Removed Log Analytics, Storage, VNet/NSG, Azure SQL Private Endpoint, Key Vault Private Endpoint, Private DNS, and paid Power BI/Fabric capacity from the prototype plan.
- Added canonical `AZURE_RESOURCES.md`, `ARCHITECTURE.md`, `SECURITY.md`, `IMPLEMENTATION_GUIDE.md`, and `SCREENSHOT_CHECKLIST.md` planning documents.
- **Azure actions performed:** none. No sign-in, subscription query, resource creation, deployment, or configuration change occurred during this revision.
- **Current gate:** waiting for Priya's explicit approval before provisioning.

This log records actions that actually occurred. No Azure resources were deployed during environment setup.

## 2026-09-15 — Environment and tooling setup

- Inspected Windows, PowerShell, Codex, Node.js, npm/npx, Python, .NET SDK, Git, Azure CLI, Bicep, MCP configuration, skills/plugins, repository state, and Azure authentication state.
- Confirmed the repository contained only `README.md`; scanned tracked workspace content for common secret patterns and found none.
- Installed Node.js LTS 24.19.0 with npm/npx 11.17.0 from the OpenJS Foundation WinGet package.
- Installed Microsoft Azure CLI 2.90.0 from the official Microsoft WinGet package.
- Installed Microsoft Azure Developer CLI 1.34.0 from the official Microsoft WinGet package.
- Installed Python 3.13.15 from the Python Software Foundation WinGet package.
- Installed Bicep CLI 0.47.16 through Azure CLI and verified its version.
- Configured the official Microsoft Azure MCP Server in Codex through `@azure/mcp@latest` and verified package startup plus tool-catalog discovery.
- Configured the official Microsoft Learn MCP endpoint and verified a successful MCP initialize response.
- Installed the five requested Microsoft skills from `microsoft/azure-skills`: `azure-prepare`, `azure-validate`, `azure-deploy`, `azure-diagnostics`, and `azure-cost`.
- Connected the local Git repository to the supplied GitHub repository and switched to the remote `main` branch.
- Created the requested workspace directories, documentation, and secret-protection rules.
- Completed interactive device-code authentication for Azure CLI and Azure Developer CLI without storing credentials in the repository.
- Verified one default Azure subscription is visible and enabled, with the subscription spending limit set to `On`.
- Verified Azure MCP can communicate with Azure through a successful live, read-only subscription query.
- Confirmed the subscription contains zero resource groups after setup.
- Re-ran the repository credential-pattern scan; no matches were found.
- Verified the official `@openai/codex` CLI 0.154.0 npm shim is present in the user PATH and documented how to refresh PowerShell sessions opened before installation.
- Installed the focused Microsoft `powerbi-authoring` agent-skill bundle from `microsoft/skills-for-fabric`: semantic-model authoring plus report planning, design, authoring, and management.
- Preserved the bundle's shared Microsoft guidance files required by the semantic-model and report-management skills.
- Configured Microsoft's official Power BI Modeling MCP package in Codex as `powerbi-modeling-mcp` and verified version 0.5.0-beta.13 startup, tool registration, prompt registration, and stdio transport.
- Detected that the preview MCP package defaults to read-write mode with write confirmations skipped; changed the Codex registration to explicit `--readonly` mode and verified the server starts in `ReadOnly` mode.
- Installed Power BI Desktop 2.157.1354.0 from Microsoft's x64 installer; verified its Microsoft signature and launched it successfully with an untitled local model.
- Reverified the global `powerbi-modeling-mcp` registration and observed its local server process running.
- Completed an end-to-end, read-only MCP test: initialized the server, listed local Power BI Desktop instances, connected to the untitled local model, and listed its tables successfully. The blank model correctly returned zero tables.
- Confirmed the Firecrawl plugin already supplied the requested Firecrawl skill set, so no duplicate skill copy was installed.
- Installed the official Firecrawl CLI 1.20.0 from the `firecrawl/cli` npm package and completed a successful unauthenticated keyless scrape test.
- Detected a plaintext Firecrawl API key in the user-provided attachment. The credential was not used or copied into the repository, Codex configuration, or process environment; revocation and regeneration were recommended.
- Azure resources created: none.
# Final enhancement round — email connector gate (2026-09-16)

## Final enhancement live runs (UTC, 2026-09-16)

| Scenario | ADF master run ID | Master status | SQL reconciliation evidence |
|---|---|---|---|
| Pre-reset smoke (old approved state) | `5ba1dc97-b1f2-11f1-b05d-ec91616f91e2` | Succeeded | Config 1: Gate 1 4/4 PASS, Gate 2 3/3 PASS, zero delta; config 2: Gate 1 4/4 PASS, Gate 2 4/4 PASS. |
| 1. Reset and first load | `9d64382f-b1f2-11f1-a6a0-ec91616f91e2` | Succeeded | Both `IsFirstLoad=1`, 3 source and 3 curated rows each, `INITIAL_LOAD` APPROVED RFC for each; disabled config 3 absent from table audits. Gate results to be counted below. |
| 2. Incremental change | `d1d44b82-b1f2-11f1-8b2e-ec91616f91e2` | Succeeded | Watermark config 1: 2 source-window/staged rows, curated 4 distinct keys/4 rows; watermark advanced. Both configs had 0 FAIL checks. |
| 3. No-change rerun | `19475339-b1f3-11f1-820e-ec91616f91e2` | Succeeded | Config 1: 0 delta, curated 4 rows; config 2: 3 full rows; both gates PASS, no duplicate keys. |
| 4a. Add RegionCode, leave pending | `52b3938b-b1f3-11f1-98e1-ec91616f91e2` | Succeeded | Config 2 PENDING/OLD_PROJECTION_SAFE, old approved columns loaded, both gates PASS; email not configured. |
| 4b. Approve and rerun | `84476d39-b1f3-11f1-a444-ec91616f91e2` | Succeeded | Config 2 version 2, RegionCode exists in curated; both table attempts SUCCESS, gates PASS. |
| 5a. Add TemporaryNote pending | `c5103fe9-b1f3-11f1-ae5d-ec91616f91e2` | Succeeded | Config 2 PENDING; old approved columns and both gates PASS. |
| 5b. Reject and rerun | `f41f95e5-b1f3-11f1-b3d7-ec91616f91e2` | Succeeded | Config 2 REJECTED, old columns loaded, TemporaryNote absent from curated; gates PASS. Gmail email not configured. |
| 6. Breaking rename | `300601c9-b1f4-11f1-9ed2-ec91616f91e2` | Failed in ADF; audit PARTIAL_SUCCESS | Config 1: 1 SUCCESS, Gate 1 4 PASS/Gate 2 3 PASS. Config 2: 4 FAILURE attempts, Gate 1 APPROVED_SCHEMA FAIL on each, Gate 2 not entered. Curated 3 rows/checksum 1225204159 before and after; TABLE_FAILURE and SCHEMA_CHANGE audit rows 4 each; ADF sent latest of both event types to 202 Logic App. No Gmail inbox proof. |
| 7. Restore and rerun | `a74aa617-b1f4-11f1-959f-ec91616f91e2` | Succeeded | Both configs SUCCESS; config 1 Gate 1 4 PASS/Gate 2 3 PASS; config 2 Gate 1 4 PASS/Gate 2 4 PASS, 3 curated rows/checksum 1225204159. |
| 8. Reporting reader | — | PARTIAL | SQL group user has reporting role and reader is an Entra group member; reader-token SELECT on all new views and group-only access not yet verified. Direct reader role membership retained until verification. |

For runs 1–5, each successful FULL table had 4 PASS checks at each gate; successful WATERMARK subsequent runs had 4 Gate 1 PASS and 3 Gate 2 PASS. The initial WATERMARK first load had 4 checks at each gate. No Gate 2 FAIL/rollback was induced; the transactional rollback path is code-reviewed but not demonstrated live. The reset left historical pipeline audits intact while removing the synthetic earlier RFC/history records.

The reset script `sql/demo/00_reset_final_round.sql` removed three prior synthetic RFC rows, three historical schema-version rows, the demo-added RegionCode/TemporaryNote columns and their synthetic values, and synthetic source row 4. This is a controlled prototype reset, not a production operation; individual deleted rows are not recoverable without an Azure SQL point-in-time restore. Older pipeline audit records were retained but may refer to the prior schema/RFC demonstration.

Priya authorized the named `gmail-kpmg-notify` connection, and Azure now reports **Connected**. `infra/gmail-workflow-extension.bicep` deployed the Gmail Send email (V2) action after the existing 202 Response, preserving the ADF-facing Request/Compose/Response path. A manual `TEST_EMAIL` POST received HTTP 202, but Logic App run `08584120258021519282617111833CU16` failed at `Send_Gmail_Alert` with HTTP 403, **Request had insufficient authentication scopes**. Gmail delivery is **NOT VERIFIED**; no inbox screenshot should be claimed. Priya must re-authorize the connection and grant Gmail send-mail scope if prompted, then retest. The 202 response proves ADF remains decoupled from the email failure, not that email succeeded.

### Power BI Overview enhancement (September 16)

- Priya saved the open PBIP before file edits; Desktop bridge confirmed `hasUnsavedChanges=false`.
- Renamed the existing page to Overview, added pending-schema, reconciliation-failure, and retry-attempt cards and a KPMG flow caption, and moved the existing two tables down to avoid overlap. Kept the existing blue theme and 16:9 canvas.
- Priya refreshed and saved; the Desktop screenshot `screenshots/powerBI/PowerBI_home.png` was captured after a successful reload and shows the latest imported runs (18 SUCCESS, 3 failed/partial, 9 retry attempts). `powerbi-report-author validate` reports **zero errors** and one warning because Microsoft's `visualContainer/2.12.0` schema URL was unreachable.
- Detailed Schema Changes & Approvals and Data Quality & Retries pages remain **not implemented**; their SQL reporting views exist, but the semantic model does not yet import them. Do not claim those pages as evidence.
