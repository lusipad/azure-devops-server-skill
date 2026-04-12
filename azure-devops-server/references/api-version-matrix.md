# API Version Matrix

## Use This File For

- choosing a safe default `api-version`
- deciding when to override for Azure DevOps Server 2022
- understanding support limits for older TFS

## Microsoft Support Matrix

Microsoft's REST API versioning guidance lists:

- Azure DevOps Server 2022: supports `1.0` through `7.0`
- Azure DevOps Server 2020: supports `1.0` through `6.0`
- Azure DevOps Server 2019: supports `1.0` through `5.0`
- TFS 2018: supports `1.0` through `4.0`

## Skill Default

This skill defaults to:

- `7.0` when the server hint is `2022`
- `6.0` when the server hint is `2020` or unspecified
- `5.0` when the server hint maps to `legacy`

Rationale:

- it keeps Azure DevOps Server 2020 safe by default
- it uses `7.0` only when the target is explicitly marked as 2022
- it avoids choosing a too-new version for older TFS hints

If you know the target is Azure DevOps Server 2022 and an endpoint requires newer behavior, set:

```powershell
$env:AZURE_DEVOPS_SERVER_API_VERSION = "7.0"
```

Or pass:

```powershell
-ApiVersion 7.0
```

## Server Version Hint

Optional:

```powershell
$env:AZURE_DEVOPS_SERVER_SERVER_VERSION = "2022"
```

Accepted values:

- `2022`
- `2020`
- `2019`
- `2018`
- `2017`
- `2015`
- `legacy`

The helper maps `2019`, `2018`, `2017`, and `2015` to `legacy` for best-effort behavior. It does not claim to auto-detect every server build.

## Upgrade Rules

- keep `6.0` as the safe default unless the target is confirmed 2022-only
- use `5.0` for explicit legacy hints unless the target proves it needs something else
- prefer explicit overrides over silent guessing
- if older TFS behavior appears, report that the target is outside first-class support
