# Workflow Recipes

## Use This File For

- common read-only tasks
- dry-run-first write patterns
- supported wrapper shapes
- quick links into the detailed domain references

All examples assume you already set:

- `AZURE_DEVOPS_SERVER_COLLECTION_URL`
- `AZURE_DEVOPS_SERVER_AUTH_MODE`
- `AZURE_DEVOPS_SERVER_PAT` when using `pat`
- `AZURE_DEVOPS_SERVER_PROJECT` when you want a default project
- `AZURE_DEVOPS_SERVER_TEAM` when you want a default team for `work` routes

Domain references:

- repository, branches, and pull requests: [repo-support.md](repo-support.md)
- work items, WIQL, saved queries, comments, revisions: [work-item-support.md](work-item-support.md)
- team settings, iterations, backlogs, capacity: [work-support.md](work-support.md)

## List Projects

```powershell
pwsh -File .\scripts\Invoke-AzureDevOpsServerApi.ps1 `
  -Method GET `
  -Resource projects `
  -Query @{ '$top' = 50 }
```

## List Repositories In A Project

```powershell
pwsh -File .\scripts\Invoke-AzureDevOpsServerApi.ps1 `
  -Method GET `
  -Area git `
  -Project Fabrikam `
  -Resource repositories
```

## List Teams In A Project

```powershell
pwsh -File .\scripts\Invoke-AzureDevOpsServerApi.ps1 `
  -Method GET `
  -Resource 'projects/Fabrikam/teams'
```

## Read One Work Item

```powershell
pwsh -File .\scripts\Invoke-AzureDevOpsServerApi.ps1 `
  -Method GET `
  -Area wit `
  -Resource workitems/12345 `
  -Query @{ '$expand' = 'relations' }
```

## Run WIQL

```powershell
$body = @{
  query = "Select [System.Id], [System.Title], [System.State] From WorkItems Where [System.AssignedTo] = @Me And [System.WorkItemType] = 'Bug' And [System.State] <> 'Closed'"
}

pwsh -File .\scripts\Invoke-AzureDevOpsServerApi.ps1 `
  -Method POST `
  -Area wit `
  -Project Fabrikam `
  -Resource wiql `
  -Body $body
```

`wit/wiql` is a safe read route even though it uses `POST`, so the wrapper allows a live call without `-AllowWrite`.

## List Team Iterations

```powershell
pwsh -File .\scripts\Invoke-AzureDevOpsServerApi.ps1 `
  -Method GET `
  -Area work `
  -Project Fabrikam `
  -Team 'Fabrikam Team' `
  -Resource teamsettings/iterations
```

## Read Team Settings

```powershell
pwsh -File .\scripts\Invoke-AzureDevOpsServerApi.ps1 `
  -Method GET `
  -Area work `
  -Project Fabrikam `
  -Team 'Fabrikam Team' `
  -Resource teamsettings
```

## List Builds

```powershell
pwsh -File .\scripts\Invoke-AzureDevOpsServerApi.ps1 `
  -Method GET `
  -Area build `
  -Project Fabrikam `
  -Resource builds `
  -Query @{ '$top' = 10; statusFilter = 'completed' }
```

## List Pull Requests

```powershell
pwsh -File .\scripts\Invoke-AzureDevOpsServerApi.ps1 `
  -Method GET `
  -Area git `
  -Project Fabrikam `
  -Resource repositories/MyRepo/pullrequests `
  -Query @{ 'searchCriteria.status' = 'active'; '$top' = 20 }
```

## Probe Release Support

```powershell
pwsh -File .\scripts\Test-AzureDevOpsServerConnection.ps1 `
  -Project Fabrikam `
  -CheckReleaseArea
```

Offline preview only:

```powershell
pwsh -File .\scripts\Test-AzureDevOpsServerConnection.ps1 `
  -Project Fabrikam `
  -CheckReleaseArea `
  -DryRun
```

Only if that probe reports `ReleaseAreaStatus = available`:

```powershell
pwsh -File .\scripts\Invoke-AzureDevOpsServerApi.ps1 `
  -Method GET `
  -Area release `
  -Project Fabrikam `
  -Resource definitions `
  -Query @{ '$top' = 10 } `
  -AllowConditionalArea
```

## Preview A Work Item Patch

```powershell
$patch = @(
  @{
    op = "add"
    path = "/fields/System.Title"
    value = "Example title"
  }
)

pwsh -File .\scripts\Invoke-AzureDevOpsServerApi.ps1 `
  -Method PATCH `
  -Area wit `
  -Resource workitems/12345 `
  -Body $patch `
  -JsonPatch `
  -DryRun
```

Live patch:

```powershell
pwsh -File .\scripts\Invoke-AzureDevOpsServerApi.ps1 `
  -Method PATCH `
  -Area wit `
  -Resource workitems/12345 `
  -Body $patch `
  -JsonPatch `
  -AllowWrite
```

## Unsupported Areas

The wrapper intentionally rejects:

- `wiki`
- `search`
- `test`
- `testresults`

If a user asks for one of these, say that the capability is deferred for this server-focused skill and avoid inventing a cloud-only route.
