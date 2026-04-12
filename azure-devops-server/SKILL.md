---
name: azure-devops-server
description: Use for Azure DevOps Server or on-prem TFS/Azure DevOps REST work when Codex needs to inspect projects, repositories, pull requests, work items, WIQL queries, builds, or conditionally releases on a collection URL. Triggers include "Azure DevOps Server", "on-prem Azure DevOps", "TFS", collection-based REST calls, Windows-auth/PAT automation, and cases where the official Azure DevOps MCP for Azure DevOps Services is not the right fit.
---

# Azure DevOps Server

Use this skill for Azure DevOps Server 2020/2022 and best-effort older TFS scenarios. Prefer the bundled PowerShell helpers over ad hoc REST boilerplate so auth, URL handling, support boundaries, and write safety stay consistent.

## Workflow

### 1. Confirm the target fits this skill

Use this skill when the target is an on-prem Azure DevOps Server or TFS deployment and the caller can provide a collection URL such as:

- `https://ado-server/tfs/DefaultCollection`
- `https://ado-server/DefaultCollection`

Do not use this skill as a drop-in replacement for the official Azure DevOps Services MCP. This skill is intentionally narrower and server-specific.

Support policy:

- First-class: Azure DevOps Server 2020 and 2022
- Best-effort: older TFS
- Required: `projects`, `git`, `wit`, `build`, `work`
- Conditional: `release`
- Deferred: `wiki`, `search`, `test`, `testresults`, `advanced security`, `MCP-app` style integrations, and other cloud-only domains

### 2. Collect configuration and bootstrap the connection

Prefer environment variables:

- `AZURE_DEVOPS_SERVER_COLLECTION_URL`
- `AZURE_DEVOPS_SERVER_AUTH_MODE` as `pat` or `default-credentials`
- `AZURE_DEVOPS_SERVER_PAT` when auth mode is `pat`
- `AZURE_DEVOPS_SERVER_PROJECT` optional default project
- `AZURE_DEVOPS_SERVER_TEAM` optional default team for team-scoped `work` routes
- `AZURE_DEVOPS_SERVER_API_VERSION` optional override
- `AZURE_DEVOPS_SERVER_SERVER_VERSION` optional hint: `2022`, `2020`, `2019`, `2018`, `2017`, `2015`, or `legacy`

The helpers also fall back to pipeline-style variables when available:

- `SYSTEM_TEAMFOUNDATIONCOLLECTIONURI`
- `SYSTEM_TEAMPROJECT`

Run the bootstrap helper before other workflows:

```powershell
pwsh -File .\scripts\Test-AzureDevOpsServerConnection.ps1
pwsh -File .\scripts\Test-AzureDevOpsServerConnection.ps1 -CheckReleaseArea
pwsh -File .\scripts\Test-AzureDevOpsServerConnection.ps1 -CheckReleaseArea -DryRun
```

Read [references/auth-and-configuration.md](references/auth-and-configuration.md) when auth inputs are unclear.
Read [references/url-and-resource-areas.md](references/url-and-resource-areas.md) when URL shape or area routing is unclear.

### 3. Use the generic API wrapper for supported reads

Use `scripts/Invoke-AzureDevOpsServerApi.ps1` for supported reads. Pass an explicit `-Area` and `-Resource` instead of hand-building URLs.

Examples:

```powershell
pwsh -File .\scripts\Invoke-AzureDevOpsServerApi.ps1 `
  -Method GET `
  -Resource projects `
  -Query @{ '$top' = 25 }

pwsh -File .\scripts\Invoke-AzureDevOpsServerApi.ps1 `
  -Method GET `
  -Area git `
  -Project Fabrikam `
  -Resource repositories
```

Read [references/workflow-recipes.md](references/workflow-recipes.md) for common routes.
Read [references/work-support.md](references/work-support.md) for team settings, iterations, backlogs, and capacity routes.
Read [references/repo-support.md](references/repo-support.md) for repository, branch, and pull-request routes.
Read [references/work-item-support.md](references/work-item-support.md) for work item, WIQL, query, comment, and JSON Patch routes.
Read [references/api-version-matrix.md](references/api-version-matrix.md) before changing `api-version`.

### 4. Treat writes as explicit and preview-first

For `POST`, `PATCH`, `PUT`, or `DELETE`:

1. Run with `-DryRun` first.
2. Summarize the exact method, URL, query, and body that would be sent.
3. Only perform the live request when the user explicitly wants the mutation.
4. Add `-AllowWrite` to the second run.

The wrapper refuses live writes unless `-AllowWrite` is present.

Use `-JsonPatch` only for work item patch payloads.

### 5. Handle conditional and deferred areas honestly

- `release` is conditional. Run `Test-AzureDevOpsServerConnection.ps1 -CheckReleaseArea` first and use `-AllowConditionalArea` only after the probe succeeds.
- Deferred areas must fail clearly. Do not fake Azure DevOps Services parity.
- If the server behaves like an older or nonstandard TFS deployment, report that it is outside first-class support instead of guessing.

### 6. Escalate to references only when needed

- Auth choices or environment setup: [references/auth-and-configuration.md](references/auth-and-configuration.md)
- URL construction and resource-area caveats: [references/url-and-resource-areas.md](references/url-and-resource-areas.md)
- Version-selection guidance: [references/api-version-matrix.md](references/api-version-matrix.md)
- Common task recipes: [references/workflow-recipes.md](references/workflow-recipes.md)
- Team iterations, team settings, backlogs, and capacity: [references/work-support.md](references/work-support.md)
- Repositories, branches, and pull requests: [references/repo-support.md](references/repo-support.md)
- Work items, WIQL, saved queries, comments, and revisions: [references/work-item-support.md](references/work-item-support.md)
