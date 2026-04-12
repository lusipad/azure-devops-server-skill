# Azure DevOps Server Skill

[![Validate](https://github.com/lusipad/azure-devops-server-skill/actions/workflows/validate.yml/badge.svg)](https://github.com/lusipad/azure-devops-server-skill/actions/workflows/validate.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

Languages: [English](README.md) | [简体中文](README.zh-CN.md)

PowerShell-backed Azure DevOps Server toolkit for Azure DevOps Server 2020/2022 and best-effort older TFS deployments. The repository packages reusable REST helpers, an installable skill bundle, and focused reference notes so on-prem Azure DevOps work stays consistent, preview-first, and honest about support boundaries.

## What This Repository Provides

- An installable skill package under `azure-devops-server/`
- A generic REST wrapper for collection-, project-, and team-scoped Azure DevOps Server routes
- A bootstrap connection probe for auth, API version, and conditional release support
- Reference guides for repositories, work items, work/team routes, URL shape, and API versions
- Agent metadata for skill registration

## Support Scope

This repository is intentionally narrower than Azure DevOps Services tooling.

| Area | Support |
| --- | --- |
| `core` / projects | Required |
| `git` | Required |
| `wit` | Required |
| `build` | Required |
| `work` | Required |
| `release` | Conditional |
| `wiki`, `search`, `test`, `testresults` | Deferred |

Target support policy:

- First-class: Azure DevOps Server 2020 and 2022
- Best-effort: older TFS / Azure DevOps Server variants
- Required inputs: collection URL plus PAT or Windows integrated auth

## Repository Layout

```text
.
|-- azure-devops-server/
|   |-- SKILL.md
|   |-- agents/openai.yaml
|   |-- references/
|   `-- scripts/
|-- .github/
|-- CONTRIBUTING.md
|-- LICENSE
|-- README.md
|-- README.zh-CN.md
`-- SECURITY.md
```

## Requirements

- PowerShell 7+
- Network access to the target Azure DevOps Server collection
- One of:
  - Windows integrated auth via `default-credentials`
  - Personal Access Token via `pat`
- A local skills directory if you want to install the bundled skill into your agent environment

## Install

Clone the repository, then copy the `azure-devops-server/` folder into your local skills directory.

Windows example:

```powershell
git clone https://github.com/lusipad/azure-devops-server-skill.git
Copy-Item -Recurse -Force `
  .\azure-devops-server-skill\azure-devops-server `
  "$env:USERPROFILE\.codex\skills\azure-devops-server"
```

If your environment uses a different skill directory, place the folder there instead. The repository root is for GitHub hosting; the nested `azure-devops-server/` directory is the actual skill package.

## Configuration

Preferred environment variables:

- `AZURE_DEVOPS_SERVER_COLLECTION_URL`
- `AZURE_DEVOPS_SERVER_AUTH_MODE` as `pat` or `default-credentials`
- `AZURE_DEVOPS_SERVER_PAT` when auth mode is `pat`
- `AZURE_DEVOPS_SERVER_PROJECT` optional default project
- `AZURE_DEVOPS_SERVER_TEAM` optional default team
- `AZURE_DEVOPS_SERVER_API_VERSION` optional override
- `AZURE_DEVOPS_SERVER_SERVER_VERSION` optional hint: `2022`, `2020`, `2019`, `2018`, `2017`, `2015`, or `legacy`

Pipeline-style fallbacks are also supported:

- `SYSTEM_TEAMFOUNDATIONCOLLECTIONURI`
- `SYSTEM_TEAMPROJECT`

## Quick Start

Bootstrap the connection first:

```powershell
pwsh -File .\azure-devops-server\scripts\Test-AzureDevOpsServerConnection.ps1
pwsh -File .\azure-devops-server\scripts\Test-AzureDevOpsServerConnection.ps1 -CheckReleaseArea
pwsh -File .\azure-devops-server\scripts\Test-AzureDevOpsServerConnection.ps1 -CheckReleaseArea -DryRun
```

Read from supported areas with the generic wrapper:

```powershell
pwsh -File .\azure-devops-server\scripts\Invoke-AzureDevOpsServerApi.ps1 `
  -Method GET `
  -Resource projects `
  -Query @{ '$top' = 25 }

pwsh -File .\azure-devops-server\scripts\Invoke-AzureDevOpsServerApi.ps1 `
  -Method GET `
  -Area git `
  -Project Fabrikam `
  -Resource repositories
```

## Safety Model

- Writes are blocked unless `-AllowWrite` is present.
- Mutating commands should be previewed with `-DryRun` first.
- `release` routes are conditional and require a successful probe before live use.
- Deferred areas fail clearly instead of pretending Azure DevOps Services parity.
- `POST` is treated as safe read-only only for supported cases such as WIQL queries.

## Development

Local validation:

```powershell
$files = @(
  "azure-devops-server/scripts/AzureDevOpsServer.psm1",
  "azure-devops-server/scripts/Invoke-AzureDevOpsServerApi.ps1",
  "azure-devops-server/scripts/Test-AzureDevOpsServerConnection.ps1"
)

foreach ($file in $files) {
  $tokens = $null
  $errors = $null
  [System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path $file), [ref]$tokens, [ref]$errors) | Out-Null
  if ($errors.Count -gt 0) {
    throw "Parse errors in $file"
  }
}

Import-Module .\azure-devops-server\scripts\AzureDevOpsServer.psm1 -Force
Get-AzureDevOpsServerSupportMatrix
```

The same checks run in GitHub Actions on pushes and pull requests.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Keep changes tight, preserve support boundaries, and update docs together with script behavior.

## Security

See [SECURITY.md](SECURITY.md). Do not post active vulnerabilities with exploit details in public issues.

## License

This project is released under the [MIT License](LICENSE).
