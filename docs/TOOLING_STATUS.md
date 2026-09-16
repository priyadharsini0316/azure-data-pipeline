# Tooling Status

Last verified: 2026-09-15 (America/Toronto)

| Tool | Purpose | Installed | Configured | Authenticated | Verified | Version | Notes |
|---|---|---:|---:|---:|---:|---|---|
| Codex Desktop | Local agent environment | Yes | Yes | Yes | Yes | 26.908.9136.0 | Desktop app package detected |
| Codex CLI | MCP and plugin configuration | Yes | Yes | Yes | Yes | 0.154.0-alpha.6.2 | Bundled with Codex Desktop |
| Git | Source control | Yes | Yes | Via HTTPS/plugin | Yes | 2.53.0.windows.3 | `origin` points to the project repository; `main` tracks `origin/main` |
| GitHub plugin | Repository connector | Yes | Yes | Yes | Yes | 0.1.12-5f7cd798dc99 | Repository lookup succeeded; no repository write was performed |
| Node.js LTS | Azure MCP runtime | Yes | Yes | N/A | Yes | 24.19.0 | Official OpenJS Foundation package |
| npm | Package runner support | Yes | Yes | N/A | Yes | 11.17.0 | Installed with Node.js |
| npx | Launch Azure MCP | Yes | Yes | N/A | Yes | 11.17.0 | Installed with Node.js |
| Python | Data/test scripting | Yes | Yes | N/A | Yes | 3.13.15 | Official Python Software Foundation package |
| .NET SDK | Alternative Azure MCP runtime | No | No | N/A | N/A | — | Not needed for the selected Node route |
| Azure CLI | Azure auth and management | Yes | Yes | Yes | Yes | 2.90.0 | One enabled default subscription is visible |
| Azure Developer CLI | Microsoft skill deployment workflow | Yes | Yes | Yes | Yes | 1.34.0 | Device-code authentication completed and status check passed |
| Bicep CLI | Infrastructure as code | Yes | Yes | N/A | Yes | 0.47.16 | Installed and version-checked through Azure CLI |
| Azure MCP Server | Azure inspection and operations | Yes | Yes | Yes | Yes | 3.0.0-beta.43 | Official Microsoft `@azure/mcp`; live read-only subscription query succeeded |
| Microsoft Learn MCP | Current Microsoft documentation | Remote service | Yes | Not required | Yes | Server 1.0.0 | MCP initialize handshake returned HTTP 200 |
| `azure-prepare` skill | Prepare an azd-based Azure project | Yes | Yes | N/A | Yes | 1.3.3 | Publisher metadata: Microsoft; discoverable by Codex |
| `azure-validate` skill | Pre-deployment validation | Yes | Yes | N/A | Yes | 1.2.2 | Publisher metadata: Microsoft; discoverable by Codex |
| `azure-deploy` skill | Controlled deployment | Yes | Yes | N/A | Yes | 1.2.1 | Publisher metadata: Microsoft; discoverable by Codex |
| `azure-diagnostics` skill | Azure troubleshooting | Yes | Yes | N/A | Yes | 1.2.6 | Publisher metadata: Microsoft; discoverable by Codex |
| `azure-cost` skill | Cost querying and optimization | Yes | Yes | N/A | Yes | 1.3.1 | Publisher metadata: Microsoft; discoverable by Codex |
| Power BI Modeling MCP | Semantic-model inspection and DAX/model operations | Yes | Yes | Local Desktop needs no cloud sign-in | Yes; live local-model connection and read-only table query succeeded | 0.5.0-beta.13 | Official Microsoft package; configured `ReadOnly` because the preview default skips write confirmation |
| `semantic-model-authoring` skill | Power BI semantic models and DAX | Yes | Yes | N/A | File/dependencies verified | Bundle 0.3.10 | From Microsoft `skills-for-fabric` |
| `powerbi-report-planning` skill | Guided report requirements and plan | Yes | Yes | N/A | File/dependencies verified | 0.1.0 | From Microsoft `skills-for-fabric` |
| `powerbi-report-design` skill | Report layout and visual design guidance | Yes | Yes | N/A | File/dependencies verified | 0.1.0 | From Microsoft `skills-for-fabric` |
| `powerbi-report-authoring` skill | PBIR/PBIP report implementation | Yes | Yes | N/A | File/dependencies verified | 0.1.0 | From Microsoft `skills-for-fabric` |
| `powerbi-report-management` skill | Publish and manage Fabric reports | Yes | Yes | Uses Azure/Fabric permissions when invoked | File/dependencies verified | 0.1.0 | From Microsoft `skills-for-fabric` |
| Power BI Desktop | Local PBIX/PBIP authoring and visual verification | Yes | Yes | Local use does not require Fabric sign-in | Yes | 2.157.1354.0 | Microsoft-signed x64 installation; launched successfully with an untitled model |
| Firecrawl CLI and skills | Web search, scraping, interaction, parsing, and monitoring | Yes | Yes | No; keyless mode only | Yes; keyless scrape succeeded | CLI 1.20.0 | Third-party Firecrawl tooling explicitly requested; advanced features require authentication |

## Existing Codex MCP servers observed before setup

- `node_repl` — enabled, bundled
- `cua_repl` — enabled, bundled
- `codex_app` — present but disabled

The setup added `azure`, `microsoft-learn`, and `powerbi-modeling-mcp`.

## Initial environment classification

### Already available

- Windows 11, PowerShell, Codex Desktop/CLI, Git, WinGet
- Bundled Node.js runtime without npm/npx
- GitHub connector access to the requested repository

### Needed installation

- Full Node.js LTS distribution with npm/npx
- Azure CLI
- Azure Developer CLI
- Python
- Bicep CLI
- Five selected Microsoft Azure skills

### Needed configuration

- Official Azure MCP Server
- Microsoft Learn MCP Server
- Local Git remote and tracking branch
- Project structure, secret exclusions, and setup documentation

### Authentication completed

- Azure CLI interactive sign-in succeeded.
- Azure Developer CLI interactive sign-in succeeded.
- Azure MCP live subscription access succeeded using the Azure credentials.
- One default subscription is visible with state `Enabled` and spending limit `On`.
- The exact Azure Free Account offer and remaining promotional-credit balance are not conclusively exposed by the CLI metadata used here.
