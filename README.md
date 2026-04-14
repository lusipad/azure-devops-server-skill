# Azure DevOps Server Skill

[![Validate](https://github.com/lusipad/azure-devops-server-skill/actions/workflows/validate.yml/badge.svg)](https://github.com/lusipad/azure-devops-server-skill/actions/workflows/validate.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

Languages: [English](README.md) | [简体中文](README.zh-CN.md)

PowerShell-backed Azure DevOps Server toolkit for Azure DevOps Server 2020/2022 and best-effort older TFS deployments. The repository packages reusable REST helpers, an installable skill bundle, and focused reference notes so on-prem Azure DevOps work stays consistent, preview-first, and honest about support boundaries.

## What This Repository Provides

- An installable skill package under `azure-devops-server/`
- A generic REST wrapper for collection-, project-, and team-scoped Azure DevOps Server routes
- A bootstrap connection probe for auth, API version, and conditional area support
- Reference guides for repositories, work items, builds, releases, wiki, search, test routes, URL shape, and API versions
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
| `wiki` | Supported |
| `testplan` | Supported |
| `test` | Supported |
| `release` | Conditional |
| `search` | Conditional |
| `testresults` | Conditional |

Target support policy:

- First-class: Azure DevOps Server 2020 and 2022
- Best-effort: older TFS / Azure DevOps Server variants
- Deferred: advanced security, MCP-app integrations, and other cloud-only domains
- Required inputs: collection URL plus PAT or Windows integrated auth

## Repository Layout

```text
.
|-- azure-devops-server/
|   |-- SKILL.md
|   |-- agents/openai.yaml
|   |-- references/
|   |-- support-contract.json
|   `-- scripts/
|-- .github/
|-- CONTRIBUTING.md
|-- LICENSE
|-- README.md
|-- README.zh-CN.md
|-- tests/
`-- SECURITY.md
```

## Requirements

- PowerShell 7+
- Network access to the target Azure DevOps Server collection
- One of:
  - Windows integrated auth via `default-credentials`
  - Personal Access Token via `pat`
- A local skills directory if you want to install the bundled skill into your agent environment

## Authentication

This toolkit supports both Windows integrated auth and PAT-based auth.

- `default-credentials`
  Recommended on Windows hosts that already have access to the target Azure DevOps Server. The scripts use the current Windows identity, and this is the default mode when `AZURE_DEVOPS_SERVER_AUTH_MODE` is not set.
- `pat`
  Use this when integrated auth is unavailable or when controlled automation needs an explicit token.

Windows integrated auth example:

```powershell
$env:AZURE_DEVOPS_SERVER_COLLECTION_URL = "https://ado-server/tfs/DefaultCollection"
$env:AZURE_DEVOPS_SERVER_AUTH_MODE = "default-credentials"

pwsh -File .\azure-devops-server\scripts\Test-AzureDevOpsServerConnection.ps1
```

PAT example:

```powershell
$env:AZURE_DEVOPS_SERVER_COLLECTION_URL = "https://ado-server/tfs/DefaultCollection"
$env:AZURE_DEVOPS_SERVER_AUTH_MODE = "pat"
$env:AZURE_DEVOPS_SERVER_PAT = "<token>"

pwsh -File .\azure-devops-server\scripts\Test-AzureDevOpsServerConnection.ps1
```

For more auth details, see [auth-and-configuration.md](azure-devops-server/references/auth-and-configuration.md).

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
- `AZURE_DEVOPS_SERVER_AUTH_MODE` as `pat` or `default-credentials` and defaults to `default-credentials`
- `AZURE_DEVOPS_SERVER_PAT` when auth mode is `pat`
- `AZURE_DEVOPS_SERVER_PROJECT` optional default project
- `AZURE_DEVOPS_SERVER_TEAM` optional default team
- `AZURE_DEVOPS_SERVER_API_VERSION` optional override
- `AZURE_DEVOPS_SERVER_SERVER_VERSION` optional hint: `2022`, `2020`, `2019`, `2018`, `2017`, `2015`, or `legacy`
- `AZURE_DEVOPS_SERVER_SEARCH_BASE_URL` optional override when search is exposed on a dedicated host
- `AZURE_DEVOPS_SERVER_TESTRESULTS_BASE_URL` optional override when test results are exposed on a dedicated host

Pipeline-style fallbacks are also supported:

- `SYSTEM_TEAMFOUNDATIONCOLLECTIONURI`
- `SYSTEM_TEAMPROJECT`

## Quick Start

Bootstrap the connection first:

```powershell
pwsh -File .\azure-devops-server\scripts\Test-AzureDevOpsServerConnection.ps1
pwsh -File .\azure-devops-server\scripts\Test-AzureDevOpsServerConnection.ps1 -CheckReleaseArea
pwsh -File .\azure-devops-server\scripts\Test-AzureDevOpsServerConnection.ps1 -CheckSearchArea
pwsh -File .\azure-devops-server\scripts\Test-AzureDevOpsServerConnection.ps1 -CheckTestResultsArea
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

Additional supported examples:

```powershell
pwsh -File .\azure-devops-server\scripts\Invoke-AzureDevOpsServerApi.ps1 `
  -Method GET `
  -Area wiki `
  -Resource wikis

pwsh -File .\azure-devops-server\scripts\Invoke-AzureDevOpsServerApi.ps1 `
  -Method GET `
  -Area build `
  -Project Fabrikam `
  -Resource definitions

pwsh -File .\azure-devops-server\scripts\Test-AzureDevOpsServerConnection.ps1 `
  -Project Fabrikam `
  -CheckReleaseArea

$body = @{
  searchText = "active bug"
  '$top' = 25
}

pwsh -File .\azure-devops-server\scripts\Invoke-AzureDevOpsServerApi.ps1 `
  -Method POST `
  -Area search `
  -Project Fabrikam `
  -Resource workitemsearchresults `
  -Body $body `
  -AllowConditionalArea
```

## Safety Model

- Writes are blocked unless `-AllowWrite` is present.
- Mutating commands should be previewed with `-DryRun` first.
- `release` routes are conditional and require a successful probe before live use.
- `search` and `testresults` are conditional because some deployments expose them on separate hosts or service topologies.
- Only explicitly allowlisted POST read routes bypass write gating.

## Reference Guides

- [workflow-recipes.md](azure-devops-server/references/workflow-recipes.md) for common task patterns
- [repo-support.md](azure-devops-server/references/repo-support.md) for repositories, branches, and pull requests
- [work-item-support.md](azure-devops-server/references/work-item-support.md) for work items, WIQL, queries, comments, and JSON Patch routes
- [work-support.md](azure-devops-server/references/work-support.md) for work/team settings, iterations, backlogs, and capacity
- [build-support.md](azure-devops-server/references/build-support.md) for definitions, builds, logs, artifacts, and queue previews
- [release-support.md](azure-devops-server/references/release-support.md) for release definitions, releases, environments, deployments, and mutation previews
- [wiki-support.md](azure-devops-server/references/wiki-support.md) for wiki listing and page reads
- [search-support.md](azure-devops-server/references/search-support.md) for search routes and dedicated-host caveats
- [test-support.md](azure-devops-server/references/test-support.md) for test plans, suites, runs, and run-scoped results
- [test-results-support.md](azure-devops-server/references/test-results-support.md) for build-linked and work-item-linked test result routes
- [url-and-resource-areas.md](azure-devops-server/references/url-and-resource-areas.md) for collection URL shape, scoping rules, and area-routing caveats
- [auth-and-configuration.md](azure-devops-server/references/auth-and-configuration.md) for auth modes, environment variables, and override precedence
- [api-version-matrix.md](azure-devops-server/references/api-version-matrix.md) for server-version and `api-version` guidance

## Development

Local validation:

```powershell
pwsh -File .\tests\Validate-AzureDevOpsServerSkill.ps1
```

Optional non-production smoke harness:

```powershell
$env:AZURE_DEVOPS_SERVER_SMOKE = "1"
$env:AZURE_DEVOPS_SERVER_COLLECTION_URL = "https://ado-server/tfs/DefaultCollection"
$env:AZURE_DEVOPS_SERVER_AUTH_MODE = "default-credentials"
$env:AZURE_DEVOPS_SERVER_PROJECT = "Fabrikam"

pwsh -File .\tests\Smoke-AzureDevOpsServerSkill.ps1
```

If the opt-in env vars are absent, the smoke harness prints a skip message and exits successfully.

The same checks run in GitHub Actions on pushes and pull requests.

## Project Docs

- [CHANGELOG.md](CHANGELOG.md) for notable repository changes
- [SUPPORT.md](SUPPORT.md) for usage questions, issue routing, and report expectations
- [CONTRIBUTING.md](CONTRIBUTING.md) for contribution workflow and validation requirements
- [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) for collaboration expectations
- [SECURITY.md](SECURITY.md) for vulnerability reporting

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Keep changes tight, preserve support boundaries, and update docs together with script behavior.

## Security

See [SECURITY.md](SECURITY.md). Do not post active vulnerabilities with exploit details in public issues.

## License

This project is released under the [MIT License](LICENSE).
