[CmdletBinding()]
param(
    [string]$CollectionUrl,
    [string]$Project,
    [ValidateSet("pat", "default-credentials")]
    [string]$AuthMode,
    [string]$Pat,
    [string]$ApiVersion,
    [ValidateSet("2022", "2020", "2019", "2018", "2017", "2015", "legacy")]
    [string]$ServerVersionHint,
    [string]$SearchBaseUrl,
    [string]$TestResultsBaseUrl,
    [switch]$Enable
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$contractPath = Join-Path $repoRoot "azure-devops-server/support-contract.json"
if (-not (Test-Path $contractPath)) {
    throw "Support contract not found at $contractPath."
}

$contract = Get-Content -Raw $contractPath | ConvertFrom-Json -AsHashtable
$smokeContract = $contract["smokeHarness"]
$conditionalSmokeAreas = @($contract["conditionalSmokeAreas"])
$optInEnv = [string]$smokeContract["optInEnv"]
$requiredEnv = @($smokeContract["requiredEnv"])
$conditionalRequiredEnv = @($smokeContract["conditionalRequiredEnv"])
$envValues = @{}
Get-ChildItem Env: | ForEach-Object {
    $envValues[$_.Name] = $_.Value
}
$parameterByEnv = @{
    AZURE_DEVOPS_SERVER_COLLECTION_URL = "CollectionUrl"
    AZURE_DEVOPS_SERVER_AUTH_MODE      = "AuthMode"
    AZURE_DEVOPS_SERVER_PROJECT        = "Project"
    AZURE_DEVOPS_SERVER_PAT            = "Pat"
}

$optInValue = if ($Enable) {
    "1"
}
elseif ($envValues.ContainsKey($optInEnv)) {
    $envValues[$optInEnv]
}
else {
    $null
}

$isEnabled = $false
if (-not [string]::IsNullOrWhiteSpace($optInValue)) {
    $normalized = $optInValue.Trim().ToLowerInvariant()
    $isEnabled = $normalized -in @("1", "true", "yes", "on")
}

if (-not $isEnabled) {
    Write-Host ("Skipping Azure DevOps Server conditional-area smoke tests. Set {0}=1 or pass -Enable to opt in." -f $optInEnv)
    return
}

$missingRequiredEnv = @()
foreach ($name in $requiredEnv) {
    $parameterName = $parameterByEnv[$name]
    $hasParameterOverride = $parameterName -and $PSBoundParameters.ContainsKey($parameterName)
    $hasEnvironmentValue = $envValues.ContainsKey($name) -and -not [string]::IsNullOrWhiteSpace([string]$envValues[$name])
    if (-not $hasParameterOverride -and -not $hasEnvironmentValue) {
        $missingRequiredEnv += $name
    }
}

if ($missingRequiredEnv.Count -gt 0) {
    throw ("Smoke tests require these environment variables when enabled: {0}" -f ($missingRequiredEnv -join ", "))
}

if (($AuthMode -eq "pat" -or $envValues["AZURE_DEVOPS_SERVER_AUTH_MODE"] -eq "pat") -and [string]::IsNullOrWhiteSpace($Pat) -and [string]::IsNullOrWhiteSpace($envValues["AZURE_DEVOPS_SERVER_PAT"])) {
    throw ("Smoke tests require these environment variables for PAT auth: {0}" -f ($conditionalRequiredEnv -join ", "))
}

$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\\azure-devops-server\\scripts\\AzureDevOpsServer.psm1"
Import-Module $modulePath -DisableNameChecking -Force

$invokeParams = @{}
foreach ($area in $conditionalSmokeAreas) {
    switch ($area) {
        "release" {
            $invokeParams.CheckReleaseArea = $true
        }
        "search" {
            $invokeParams.CheckSearchArea = $true
        }
        "testresults" {
            $invokeParams.CheckTestResultsArea = $true
        }
        default {
            throw "Smoke harness does not know how to probe conditional area '$area'."
        }
    }
}

foreach ($entry in $PSBoundParameters.GetEnumerator()) {
    if ($entry.Key -eq "Enable") {
        continue
    }

    if ($entry.Value -is [string] -and [string]::IsNullOrWhiteSpace($entry.Value)) {
        continue
    }

    $invokeParams[$entry.Key] = $entry.Value
}

$result = Test-AzureDevOpsServerBootstrap @invokeParams
Write-Output $result
