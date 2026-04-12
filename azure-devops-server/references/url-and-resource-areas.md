# URL And Resource Areas

## Use This File For

- collection URL handling
- route construction rules
- resource-area caveats
- deciding when to trust the collection URL and when to probe an area

## Core Rule

Use the full collection URL as the primary base, not an organization shorthand.

Examples:

- `https://ado-server/tfs/DefaultCollection`
- `https://ado-server/DefaultCollection`

This skill appends:

- `/{project}` when the API is project-scoped
- `/{project}/{team}` when the API is team-scoped
- `/_apis/{area}/{resource}`

## Why This Skill Avoids Cloud URL Assumptions

Microsoft's URL guidance says:

- do not assume a fixed URL form
- do not build new URLs by parsing old ones
- do not assume every REST area lives on the same domain
- prefer client libraries when possible

Those warnings matter even more for Azure DevOps Server, where collection paths and enabled areas vary across installations.

## Resource Areas In Practice

For Azure DevOps Services, Microsoft documents resource-area lookup so clients can discover alternate base URLs.

For this skill:

- required read areas use the configured collection URL directly
- `release` is treated as conditional and is probed explicitly
- deferred or cloud-only areas are rejected instead of guessed

The bootstrap helper does this:

1. call a stable read endpoint: `/_apis/projects`
2. optionally probe `/_apis/release/definitions` against a project
3. record whether release is available on the target

## Release Caveat

Microsoft's URL article includes a placeholder release resource-area GUID in its example table. This skill does not depend on that placeholder. Instead, it treats release support as an observed capability of the target server.

Use:

```powershell
pwsh -File .\scripts\Test-AzureDevOpsServerConnection.ps1 -CheckReleaseArea
```

Only use `-AllowConditionalArea` for release requests after that probe succeeds.

## Route Tips

- list projects: area omitted, resource `projects`
- list teams in a project: area omitted, resource `projects/{project}/teams`
- list repos: area `git`, resource `repositories`
- work items: area `wit`, resource `workitems/{id}`
- WIQL: area `wit`, resource `wiql`
- builds: area `build`, resource `builds`
- pull requests: area `git`, resource `repositories/{repoIdOrName}/pullrequests`
- team iterations: area `work`, project + team set, resource `teamsettings/iterations`
- team settings: area `work`, project + team set, resource `teamsettings`

Collection-scoped routes:

- `projects`
- `projects/{project}/teams`

These routes stay at the collection root even if `AZURE_DEVOPS_SERVER_PROJECT` or `AZURE_DEVOPS_SERVER_TEAM` are configured.

Team-scoped routes:

- use `-Project` plus `-Team`
- the team is often the default team name like `Fabrikam Team`, not just the project name
- Azure DevOps Server also accepts team IDs in places where names are awkward or duplicated

If a route 404s on Server:

- verify project scoping
- verify team scoping
- verify the api-version
- verify the area is not deferred or conditional
- treat older TFS as outside first-class support until proven otherwise
