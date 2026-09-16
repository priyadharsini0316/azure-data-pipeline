# Environment Setup

Last verified: 2026-09-15 (America/Toronto)

## Environment

- Operating system: Windows 11 Home Single Language, 64-bit, build 26200
- Shell used by Codex: PowerShell 7.6.5
- Codex Desktop: 26.908.9136.0
- Codex CLI: 0.154.0-alpha.6.2
- Repository: `priyadharsini0316/azure-data-pipeline`, branch `main`

## Installed tooling

| Tool | Version | Installation source | Purpose |
|---|---:|---|---|
| Git | 2.53.0.windows.3 | Codex bundled runtime | Source control |
| Node.js LTS | 24.19.0 | OpenJS Foundation package via WinGet | Azure MCP runtime |
| npm / npx | 11.17.0 | Included with Node.js | Run the official Azure MCP package |
| Python | 3.13.15 | Python Software Foundation package via WinGet | Data validation and project scripts |
| Azure CLI | 2.90.0 | Microsoft package via WinGet | Azure authentication and management |
| Azure Developer CLI | 1.34.0 | Microsoft package via WinGet | Supports Microsoft Azure deployment skills |
| Bicep CLI | 0.47.16 | Installed by Azure CLI | Azure infrastructure as code |
| Power BI Desktop | 2.157.1354.0 | Microsoft x64 installer | Local semantic-model and report authoring |
| .NET SDK | Not installed | Not required for the selected Node-based MCP route | Optional alternative runtime |

New terminal sessions are required for Windows PATH updates. This setup used absolute executable paths for same-session verification.

The official `@openai/codex` command is available through the user npm directory. If an older PowerShell window reports that `codex` is not recognized, close and reopen PowerShell or refresh that window with:

```powershell
$env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')
```

Codex's embedded terminal inherits the environment from the Codex Desktop process. If Codex was open while Node.js or the CLI was installed, fully exit and reopen Codex before opening a new embedded terminal. Until then, the absolute shim works directly:

```powershell
& "$env:APPDATA\npm\codex.cmd" mcp get azure
```

## Azure MCP Server

- Publisher: Microsoft
- Official implementation: `microsoft/mcp`, package `@azure/mcp`
- Configured Codex server name: `azure`
- Transport: local stdio
- Launch command: official npm package through `npx`, using the installed Node.js LTS runtime
- Verified package version: `3.0.0-beta.43+aa38e86ad35387198f906484d831a80700dae298`
- Local verification: package launched and returned a successful Azure MCP tool catalog
- Azure communication verification: authenticated live subscription query succeeded

The server is configured globally in the user Codex configuration. No tokens or credentials are stored in this repository.

## Microsoft Learn MCP Server

- Publisher: Microsoft
- Configured Codex server name: `microsoft-learn`
- Endpoint: `https://learn.microsoft.com/api/mcp`
- Transport: Streamable HTTP
- Authentication: none required
- Verification: HTTP 200 MCP initialization succeeded; server identified itself as Microsoft Learn MCP Server 1.0.0

## Microsoft Azure agent skills

The following skills were installed from the official `microsoft/azure-skills` repository into the user Codex skills directory. The skills were verified as discoverable after installation.

| Requested capability | Installed skill | Version |
|---|---|---:|
| Prepare | `azure-prepare` | 1.3.3 |
| Validate | `azure-validate` | 1.2.2 |
| Deploy | `azure-deploy` | 1.2.1 |
| Diagnostics | `azure-diagnostics` | 1.2.6 |
| Cost management | `azure-cost` | 1.3.1 |

Only these project-relevant skills were installed. The broader Azure plugin catalog was not installed.

## Microsoft Power BI agentic tooling

The focused `powerbi-authoring` bundle was installed from Microsoft's official `microsoft/skills-for-fabric` repository. Its shared Microsoft guidance files are preserved under the Codex user configuration so relative skill references remain valid.

| Capability | Installed skill | Skill version |
|---|---|---:|
| Semantic model authoring | `semantic-model-authoring` | Bundle 0.3.10 |
| Report requirements and planning | `powerbi-report-planning` | 0.1.0 |
| Report visual design | `powerbi-report-design` | 0.1.0 |
| PBIR/PBIP report authoring | `powerbi-report-authoring` | 0.1.0 |
| Fabric report publishing and management | `powerbi-report-management` | 0.1.0 |

The official Microsoft Power BI Modeling MCP Server is configured globally in Codex as `powerbi-modeling-mcp`:

- Package: `@microsoft/powerbi-modeling-mcp@latest`
- Verified version: `0.5.0-beta.13`
- Transport: local stdio
- Mode: `ReadOnly`
- Verification: package launched, registered its Power BI modeling tools and prompts, and started its MCP stdio transport
- Power BI Desktop verification: Microsoft-signed executable launched successfully with an untitled local model
- Live MCP semantic-model verification: succeeded against an untitled local Power BI Desktop model; local-instance discovery, connection, and a read-only table-list request all completed successfully

The preview package currently defaults to read-write mode with skipped write confirmations. This environment explicitly passes `--readonly` to prevent accidental semantic-model modification during setup. Power BI Desktop is installed and can be used for local PBIX/PBIP authoring and visual verification. Fully exit and reopen Codex after installing or changing an MCP server; MCP tools available to an existing task are fixed when that task starts. Keep the target PBIX/PBIP open in Desktop when asking Codex to inspect its local semantic model.

## Firecrawl web tooling

- Publisher: Firecrawl
- Official source: `firecrawl/cli`
- CLI package: `firecrawl-cli` 1.20.0
- Codex skills: focused Firecrawl search, scrape, interact, crawl, map, agent, monitor, parse, download, research-index, and developer-index skills are installed through the Firecrawl plugin
- Authentication: not configured
- Verification: an unauthenticated keyless scrape completed successfully

Basic keyless operations are rate-limited. An authenticated Firecrawl account/API key is needed for higher limits and capabilities such as crawl, map, monitor, extract, batch scrape, and agent jobs. Never place a Firecrawl API key in this repository; `.firecrawl/` and `.env*` are ignored.

## Authentication

Azure CLI and Azure Developer CLI use Microsoft interactive authentication. Credentials are kept in their standard user-level caches outside the repository.

Authentication was completed interactively with device-code sign-in for both Azure CLI and Azure Developer CLI. To verify the current session:

```powershell
az account show --query "{name:name,state:state,isDefault:isDefault}" --output table
azd auth login --check-status
```

Do not place access tokens, refresh tokens, passwords, client secrets, connection strings, or storage keys in repository files. For deployed workloads, prefer managed identity, Microsoft Entra ID, and least-privilege RBAC. Use Key Vault only when a real secret cannot be eliminated.

## Cost controls

- No Azure resources were created during environment setup.
- Use one dedicated resource group for the prototype unless the approved architecture requires otherwise.
- Prefer free, serverless, and smallest practical SKUs.
- Use Bicep and review `what-if` output before deployment.
- Record every resource and its estimated cost impact in `docs/AZURE_RESOURCES.md`.
- Document expensive production architecture rather than deploying it for the prototype.
- Never upgrade the subscription or change billing without explicit approval.

## Reconnect and verify

Open a new terminal or restart Codex so Windows PATH and newly installed skills are refreshed, then run:

```powershell
node --version
npm --version
npx --version
python --version
az version --query '"azure-cli"' --output tsv
az account show --query "{name:name,state:state,isDefault:isDefault}" --output table
az bicep version
azd version
codex mcp list
codex mcp get azure
codex mcp get powerbi-modeling-mcp
```

If Azure authentication expires, run `az login` and `azd auth login` interactively. If MCP tools do not appear, restart Codex after checking `codex mcp list`. If Azure MCP fails to start, confirm `npx` works and run `npx -y @azure/mcp@latest --version`.

The verified subscription state is `Enabled`, and its spending limit is `On`. Azure CLI subscription metadata does not conclusively identify the commercial offer as an Azure Free Account or expose the remaining promotional-credit balance, so that label and balance should be checked in Azure Cost Management in the portal when needed.

## Updating tooling

```powershell
winget upgrade --exact --id Microsoft.AzureCLI
winget upgrade --exact --id Microsoft.Azd
winget upgrade --exact --id OpenJS.NodeJS.LTS
winget upgrade --exact --id Python.Python.3.13
az bicep upgrade
```

Re-check Microsoft documentation and the official `microsoft/azure-skills` repository before updating MCP or skills because command names and workflows can change.
