# Contributing

## Scope

This repository targets Azure DevOps Server and on-prem TFS workflows. Do not add Azure DevOps Services parity features unless the behavior is explicitly validated against supported server deployments.

Keep changes aligned with these rules:

- Prefer small, reviewable pull requests.
- Reuse the existing PowerShell helpers instead of adding duplicate REST logic.
- Keep write safety intact: `-DryRun` first, then explicit `-AllowWrite`.
- Preserve honest support boundaries for supported, conditional, and route-limited areas.
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

Without the explicit smoke env vars, the smoke harness should report a skip and exit successfully.

If your change affects examples, routes, support claims, or bootstrap behavior, update:

- `azure-devops-server/support-contract.json`
- `azure-devops-server/SKILL.md`
- `azure-devops-server/references/*.md`
- `tests/Validate-AzureDevOpsServerSkill.ps1`
- `tests/Smoke-AzureDevOpsServerSkill.ps1`
- Script comments or examples in the repository root docs when needed

## Pull Requests

Each pull request should include:

- The user-facing problem being solved
- The supported server/version assumptions
- Validation evidence
- Any intentionally unsupported behavior left unchanged

When a change touches mutating routes, include a dry-run example or equivalent safety proof in the PR description.

## Commit Style

This repository uses decision-oriented commits. Prefer commit messages that explain why the change exists, not only what changed. If you are contributing through automated agent workflows, preserve the existing Lore-style trailers when practical.
