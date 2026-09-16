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
