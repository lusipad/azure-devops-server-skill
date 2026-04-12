# Contributing

## Scope

This repository targets Azure DevOps Server and on-prem TFS workflows. Do not add Azure DevOps Services parity features unless the behavior is explicitly validated against supported server deployments.

Keep changes aligned with these rules:

- Prefer small, reviewable pull requests.
- Reuse the existing PowerShell helpers instead of adding duplicate REST logic.
- Keep write safety intact: `-DryRun` first, then explicit `-AllowWrite`.
- Preserve honest support boundaries for deferred and conditional areas.
- Update docs and references together with script behavior.

## Development Setup

Requirements:

- PowerShell 7+
- Git

Optional for live testing:

- An Azure DevOps Server collection URL
- A PAT or Windows integrated auth access to that server

## Local Validation

Run these checks before opening a pull request:

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
Get-AzureDevOpsServerSupportMatrix | Format-Table -AutoSize
```

If your change affects examples, routes, support claims, or bootstrap behavior, update:

- `azure-devops-server/SKILL.md`
- `azure-devops-server/references/*.md`
- Script comments or examples in the repository root docs when needed

## Pull Requests

Each pull request should include:

- The user-facing problem being solved
- The supported server/version assumptions
- Validation evidence
- Any intentionally unsupported behavior left unchanged

When a change touches mutating routes, include a dry-run example or equivalent safety proof in the PR description.

## Commit Style

This repository uses decision-oriented commits. Prefer commit messages that explain why the change exists, not only what changed. If you are contributing through Codex/OMX workflows, preserve the existing Lore-style trailers when practical.
