Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$modulePath = Join-Path $repoRoot "azure-devops-server/scripts/AzureDevOpsServer.psm1"
Import-Module $modulePath -Force
$contractPath = Join-Path $repoRoot "azure-devops-server/support-contract.json"

function Assert-Equal {
    param(
        $Actual,
        $Expected,
        [string]$Message
    )

    if ($Actual -ne $Expected) {
        throw "$Message Expected '$Expected' but got '$Actual'."
    }
}

function Assert-True {
    param(
        [bool]$Condition,
        [string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

function Assert-TextContainsLiteral {
    param(
        [string]$Text,
        [string]$Literal,
        [string]$Message
    )

    if ($Text -notmatch [regex]::Escape($Literal)) {
        throw $Message
    }
}

function Assert-TextNotContainsLiteral {
    param(
        [string]$Text,
        [string]$Literal,
        [string]$Message
    )

    if ($Text -match [regex]::Escape($Literal)) {
        throw $Message
    }
}

function Assert-ThrowsLike {
    param(
        [scriptblock]$ScriptBlock,
        [string]$Pattern,
        [string]$Message
    )

    try {
        & $ScriptBlock
    }
    catch {
        if ($_.Exception.Message -match $Pattern) {
            return
        }

        throw "$Message Unexpected error: $($_.Exception.Message)"
    }

    throw "$Message Expected an exception matching '$Pattern'."
}

$collectionUrl = "https://ado-server/tfs/DefaultCollection"
Assert-True (Test-Path $contractPath) "Support contract should exist."
$contract = Get-Content -Raw $contractPath | ConvertFrom-Json -AsHashtable
$expectedSupportMatrix = $contract["supportMatrix"]
$requiredReferences = @($contract["requiredReferences"])
$readmeIndexEn = @($contract["readmeIndex"]["en"])
$readmeIndexZh = @($contract["readmeIndex"]["zh-CN"])
$readmeSupportLabelsEn = $contract["readmeSupportLabels"]["en"]
$readmeSupportLabelsZh = $contract["readmeSupportLabels"]["zh-CN"]
$smokeHarnessContract = $contract["smokeHarness"]
$smokeOptInEnv = [string]$smokeHarnessContract["optInEnv"]
$smokeConditionalAreas = @($contract["conditionalSmokeAreas"])
$deferredPolicyLines = $contract["deferredPolicyLines"]
$requiredMetadataTerms = @($contract["metadataCoverage"]["openaiDefaultPromptMustMention"])
$forbiddenMetadataTerms = @($contract["metadataCoverage"]["openaiDefaultPromptMustNotMention"])
$englishSupportLabels = @{
    required    = "Required"
    supported   = "Supported"
    conditional = "Conditional"
}
$chineseSupportLabels = @{
    required    = "必需支持"
    supported   = "已支持"
    conditional = "条件支持"
}

$configuration = Get-AzureDevOpsServerConfiguration -CollectionUrl $collectionUrl
Assert-Equal $configuration.AuthMode "default-credentials" "Default auth mode should stay on Windows integrated auth."

$previousApiVersionEnv = $env:AZURE_DEVOPS_SERVER_API_VERSION
try {
    $env:AZURE_DEVOPS_SERVER_API_VERSION = "7.0"
    $environmentApiVersionConfiguration = Get-AzureDevOpsServerConfiguration `
        -CollectionUrl $collectionUrl `
        -ServerVersionHint "2020"
    Assert-Equal $environmentApiVersionConfiguration.ApiVersion "7.0" "Environment API version override should be honored."

    $explicitApiVersionConfiguration = Get-AzureDevOpsServerConfiguration `
        -CollectionUrl $collectionUrl `
        -ServerVersionHint "2020" `
        -ApiVersion "6.0"
    Assert-Equal $explicitApiVersionConfiguration.ApiVersion "6.0" "Explicit ApiVersion should override the environment value."
}
finally {
    if ($null -eq $previousApiVersionEnv) {
        Remove-Item Env:AZURE_DEVOPS_SERVER_API_VERSION -ErrorAction SilentlyContinue
    }
    else {
        $env:AZURE_DEVOPS_SERVER_API_VERSION = $previousApiVersionEnv
    }
}

$matrix = @{}
Get-AzureDevOpsServerSupportMatrix | ForEach-Object {
    $matrix[$_.Area] = $_.Support
}

Assert-Equal $matrix.Count $expectedSupportMatrix.Count "Support matrix size should match the shared contract."
foreach ($area in $expectedSupportMatrix.Keys) {
    Assert-Equal $matrix[$area] $expectedSupportMatrix[$area] "Support matrix should match the contract for area '$area'."
}

$wiqlPreview = Invoke-AzureDevOpsServerRequest `
    -Method POST `
    -Area wit `
    -Project Fabrikam `
    -Resource wiql `
    -Body @{ query = "Select [System.Id] From WorkItems" } `
    -CollectionUrl $collectionUrl `
    -DryRun
Assert-Equal $wiqlPreview.RequiresAllowWrite $false "WIQL POST should remain a safe read."

$wikiBatchPreview = Invoke-AzureDevOpsServerRequest `
    -Method POST `
    -Area wiki `
    -Project Fabrikam `
    -Resource "wikis/Fabrikam.wiki/pagesbatch" `
    -Body @{ top = 20 } `
    -CollectionUrl $collectionUrl `
    -DryRun
Assert-Equal $wikiBatchPreview.RequiresAllowWrite $false "Wiki pages batch should be treated as a safe read POST."

Assert-ThrowsLike `
    -ScriptBlock {
        Invoke-AzureDevOpsServerRequest `
            -Method POST `
            -Area search `
            -Project Fabrikam `
            -Resource workitemsearchresults `
            -Body @{ searchText = "bug"; '$top' = 10 } `
            -CollectionUrl $collectionUrl `
            -DryRun
    } `
    -Pattern "Area 'search' is conditional" `
    -Message "Search should remain conditional until explicitly allowed."

$searchPreview = Invoke-AzureDevOpsServerRequest `
    -Method POST `
    -Area search `
    -Project Fabrikam `
    -Resource workitemsearchresults `
    -Body @{ searchText = "bug"; '$top' = 10 } `
    -CollectionUrl $collectionUrl `
    -AllowConditionalArea `
    -DryRun
Assert-Equal $searchPreview.RequiresAllowWrite $false "Allowlisted search query routes should be treated as safe reads."

foreach ($resource in @("codesearchresults", "wikisearchresults")) {
    $conditionalSearchPreview = Invoke-AzureDevOpsServerRequest `
        -Method POST `
        -Area search `
        -Project Fabrikam `
        -Resource $resource `
        -Body @{ searchText = "bug"; '$top' = 10 } `
        -CollectionUrl $collectionUrl `
        -AllowConditionalArea `
        -DryRun
    Assert-Equal $conditionalSearchPreview.RequiresAllowWrite $false "Allowlisted search route '$resource' should be treated as a safe read."
}

$buildQueuePreview = Invoke-AzureDevOpsServerRequest `
    -Method POST `
    -Area build `
    -Project Fabrikam `
    -Resource builds `
    -Body @{
        definition = @{
            id = 12
        }
        sourceBranch = "refs/heads/main"
    } `
    -CollectionUrl $collectionUrl `
    -DryRun
Assert-Equal $buildQueuePreview.RequiresAllowWrite $true "Build queue requests must still require AllowWrite."

$writePreview = Invoke-AzureDevOpsServerRequest `
    -Method POST `
    -Area git `
    -Project Fabrikam `
    -Resource "repositories/MyRepo/pullrequests" `
    -Body @{
        sourceRefName = "refs/heads/feature/example"
        targetRefName = "refs/heads/main"
        title = "Example"
    } `
    -CollectionUrl $collectionUrl `
    -DryRun
Assert-Equal $writePreview.RequiresAllowWrite $true "Git pull request creation must still require AllowWrite."

Assert-ThrowsLike `
    -ScriptBlock {
        Invoke-AzureDevOpsServerRequest `
            -Method POST `
            -Area git `
            -Project Fabrikam `
            -Resource "repositories/MyRepo/pullrequests" `
            -Body @{
                sourceRefName = "refs/heads/feature/example"
                targetRefName = "refs/heads/main"
                title = "Example"
            } `
            -CollectionUrl $collectionUrl
    } `
    -Pattern "Live writes are blocked by default" `
    -Message "Live writes should still be blocked by default."

Assert-ThrowsLike `
    -ScriptBlock {
        Invoke-AzureDevOpsServerRequest `
            -Method GET `
            -Area release `
            -Project Fabrikam `
            -Resource definitions `
            -CollectionUrl $collectionUrl `
            -DryRun
    } `
    -Pattern "Area 'release' is conditional" `
    -Message "Release should still require AllowConditionalArea."

Assert-ThrowsLike `
    -ScriptBlock {
        Invoke-AzureDevOpsServerRequest `
            -Method GET `
            -Area testresults `
            -Project Fabrikam `
            -Resource resultsummarybybuild `
            -Query @{ buildId = 1 } `
            -CollectionUrl $collectionUrl `
            -DryRun
    } `
    -Pattern "Area 'testresults' is conditional" `
    -Message "Test results should remain conditional until explicitly allowed."

$releasePreview = Invoke-AzureDevOpsServerRequest `
    -Method GET `
    -Area release `
    -Project Fabrikam `
    -Resource definitions `
    -CollectionUrl $collectionUrl `
    -AllowConditionalArea `
    -DryRun
Assert-Equal $releasePreview.AreaSupport "conditional" "Conditional release preview should still report conditional support."

$releaseCreatePreview = Invoke-AzureDevOpsServerRequest `
    -Method POST `
    -Area release `
    -Project Fabrikam `
    -Resource releases `
    -Body @{ definitionId = 15 } `
    -CollectionUrl $collectionUrl `
    -AllowConditionalArea `
    -DryRun
Assert-Equal $releaseCreatePreview.RequiresAllowWrite $true "Release creation must still require AllowWrite even after conditional access is allowed."

$testResultsPreview = Invoke-AzureDevOpsServerRequest `
    -Method GET `
    -Area testresults `
    -Project Fabrikam `
    -Resource resultsummarybybuild `
    -Query @{ buildId = 1 } `
    -CollectionUrl $collectionUrl `
    -AllowConditionalArea `
    -DryRun
Assert-Equal $testResultsPreview.RequiresAllowWrite $false "Conditional GET routes should remain read-only when allowed."

$wikiUri = New-AzureDevOpsServerApiUri `
    -CollectionUrl $collectionUrl `
    -Project Fabrikam `
    -Area wiki `
    -Resource "wikis/Fabrikam.wiki/pages" `
    -ApiVersion 6.0
Assert-True ($wikiUri -match "/Fabrikam/_apis/wiki/wikis/Fabrikam\.wiki/pages\?api-version=6\.0$") "Wiki URI should stay project-scoped."

$collectionWikiPreview = Invoke-AzureDevOpsServerRequest `
    -Method GET `
    -Area wiki `
    -Project Fabrikam `
    -Resource wikis `
    -CollectionUrl $collectionUrl `
    -DryRun
Assert-True ($collectionWikiPreview.Uri -match "/DefaultCollection/_apis/wiki/wikis\?api-version=6\.0$") "Collection-scoped wiki requests should not inherit the default project."

$testPlanUri = New-AzureDevOpsServerApiUri `
    -CollectionUrl $collectionUrl `
    -Project Fabrikam `
    -Area testplan `
    -Resource plans `
    -ApiVersion 6.0
Assert-True ($testPlanUri -match "/Fabrikam/_apis/testplan/plans\?api-version=6\.0$") "Test plan URI should stay project-scoped."

$bootstrapPreview = Test-AzureDevOpsServerBootstrap `
    -CollectionUrl $collectionUrl `
    -Project Fabrikam `
    -CheckReleaseArea `
    -CheckSearchArea `
    -CheckTestResultsArea `
    -DryRun
Assert-Equal $bootstrapPreview.ReleaseAreaStatus "dry-run" "Bootstrap dry-run should still report release probe dry-run status."
Assert-Equal $bootstrapPreview.SearchAreaStatus "dry-run" "Bootstrap dry-run should expose search probe status."
Assert-Equal $bootstrapPreview.TestResultsAreaStatus "dry-run" "Bootstrap dry-run should expose test results probe status."
Assert-True ($bootstrapPreview.TestResultsProbeUri -match "/_apis/testresults/settings\?api-version=6\.0$") "Test results probe should use a data-independent settings route."

$readme = Get-Content -Raw (Join-Path $repoRoot "README.md")
$readmeZh = Get-Content -Raw (Join-Path $repoRoot "README.zh-CN.md")
$skillDoc = Get-Content -Raw (Join-Path $repoRoot "azure-devops-server/SKILL.md")
$openaiMetadata = Get-Content -Raw (Join-Path $repoRoot "azure-devops-server/agents/openai.yaml")
$workflowRecipes = Get-Content -Raw (Join-Path $repoRoot "azure-devops-server/references/workflow-recipes.md")
$validateWorkflow = Get-Content -Raw (Join-Path $repoRoot ".github/workflows/validate.yml")
$smokeHarnessScript = Get-Content -Raw (Join-Path $repoRoot "tests/Smoke-AzureDevOpsServerSkill.ps1")
$prdPlan = Get-Content -Raw (Join-Path $repoRoot ".omx/plans/prd-azure-devops-server-skill.md")
$testSpecPlan = Get-Content -Raw (Join-Path $repoRoot ".omx/plans/test-spec-azure-devops-server-skill.md")
$wikiSupport = Get-Content -Raw (Join-Path $repoRoot "azure-devops-server/references/wiki-support.md")
$buildSupport = Get-Content -Raw (Join-Path $repoRoot "azure-devops-server/references/build-support.md")
$releaseSupport = Get-Content -Raw (Join-Path $repoRoot "azure-devops-server/references/release-support.md")

foreach ($path in $requiredReferences) {
    Assert-True (Test-Path (Join-Path $repoRoot $path)) "Required reference should exist: $path"
}

foreach ($area in $expectedSupportMatrix.Keys) {
    $englishRow = '| {0} | {1} |' -f $readmeSupportLabelsEn[$area], $englishSupportLabels[$expectedSupportMatrix[$area]]
    $chineseRow = '| {0} | {1} |' -f $readmeSupportLabelsZh[$area], $chineseSupportLabels[$expectedSupportMatrix[$area]]
    Assert-TextContainsLiteral $readme $englishRow "README should include the support-table row '$englishRow'."
    Assert-TextContainsLiteral $readmeZh $chineseRow "Chinese README should include the support-table row '$chineseRow'."
}

Assert-True -Condition ($readme -match '(?m)^\s+-Area wiki `\r?\n\s+-Resource wikis\s*$') -Message "README should show collection-scoped wiki listing."
Assert-True -Condition ($readme -notmatch '(?m)^\s+-Area wiki `\r?\n\s+-Project Fabrikam `\r?\n\s+-Resource wikis\s*$') -Message "README should not reintroduce a project-scoped wiki listing example."
Assert-True -Condition ($readmeZh -match '(?m)^\s+-Area wiki `\r?\n\s+-Resource wikis\s*$') -Message "Chinese README should show collection-scoped wiki listing."
Assert-True -Condition ($readmeZh -notmatch '(?m)^\s+-Area wiki `\r?\n\s+-Project Fabrikam `\r?\n\s+-Resource wikis\s*$') -Message "Chinese README should not reintroduce a project-scoped wiki listing example."

foreach ($path in $readmeIndexEn) {
    Assert-TextContainsLiteral $readme "($path)" "README should link to $path."
}

foreach ($path in $readmeIndexZh) {
    Assert-TextContainsLiteral $readmeZh "($path)" "Chinese README should link to $path."
}

Assert-True -Condition ($skillDoc -match 'Supported: `wiki`, `testplan`, `test`') -Message "SKILL.md should describe the expanded supported areas."
Assert-True -Condition ($skillDoc -match 'Conditional: `release`, `search`, `testresults`') -Message "SKILL.md should describe conditional areas."
Assert-True -Condition ($workflowRecipes -match '## Conditional Areas') -Message "Workflow recipes should describe conditional areas instead of a blanket unsupported list."
Assert-True -Condition ($workflowRecipes -match '(?ms)^## List Wikis\s+```powershell\s+pwsh .*?^\s+-Area wiki `\r?\n\s+-Resource wikis\s*$') -Message "Workflow recipes should show collection-scoped wiki listing."
Assert-True -Condition ($workflowRecipes -notmatch '(?ms)^## List Wikis\s+```powershell\s+pwsh .*?^\s+-Area wiki `\r?\n\s+-Project Fabrikam `\r?\n\s+-Resource wikis\s*$') -Message "Workflow recipes should not reintroduce a project-scoped wiki listing example."
Assert-True -Condition ($skillDoc -match 'build-support\.md') -Message "SKILL.md should link to build support."
Assert-True -Condition ($skillDoc -match 'release-support\.md') -Message "SKILL.md should link to release support."
Assert-True -Condition ($workflowRecipes -match 'build-support\.md') -Message "Workflow recipes should link to build support."
Assert-True -Condition ($workflowRecipes -match 'release-support\.md') -Message "Workflow recipes should link to release support."
Assert-True -Condition ($wikiSupport -match 'Collection-scoped') -Message "Wiki support reference should describe wiki listing as collection-scoped."
Assert-True -Condition ($buildSupport -match 'Preview Queueing A Build') -Message "Build support reference should document preview-first queue requests."
Assert-True -Condition ($releaseSupport -match 'CheckReleaseArea') -Message "Release support reference should document probing before use."

foreach ($term in $requiredMetadataTerms) {
    Assert-TextContainsLiteral $openaiMetadata $term "openai.yaml should mention '$term'."
}

foreach ($term in $forbiddenMetadataTerms) {
    Assert-TextNotContainsLiteral $openaiMetadata $term "openai.yaml should not promote '$term'."
}

Assert-TextContainsLiteral $validateWorkflow "azure-devops-server/support-contract.json" "CI should require the shared support contract."
Assert-TextContainsLiteral $validateWorkflow "ConvertFrom-Json -AsHashtable" "CI should load the shared support contract."
Assert-TextContainsLiteral $validateWorkflow "tests/Smoke-AzureDevOpsServerSkill.ps1" "CI should verify the smoke harness script."

Assert-TextContainsLiteral $smokeHarnessScript '$smokeContract = $contract["smokeHarness"]' "Smoke harness should read the smoke section from the shared contract."
Assert-TextContainsLiteral $smokeHarnessScript '$conditionalSmokeAreas = @($contract["conditionalSmokeAreas"])' "Smoke harness should read conditional smoke areas from the shared contract."
Assert-TextContainsLiteral $smokeHarnessScript '$optInEnv = [string]$smokeContract["optInEnv"]' "Smoke harness should consume the contract opt-in environment key."
Assert-TextContainsLiteral $smokeHarnessScript '$requiredEnv = @($smokeContract["requiredEnv"])' "Smoke harness should consume the contract required environment list."
Assert-TextContainsLiteral $smokeHarnessScript '$conditionalRequiredEnv = @($smokeContract["conditionalRequiredEnv"])' "Smoke harness should consume the contract conditional environment list."
Assert-TextContainsLiteral $smokeHarnessScript "Skipping Azure DevOps Server conditional-area smoke tests" "Smoke harness should document skip semantics."
Assert-TextContainsLiteral $smokeHarnessScript "Test-AzureDevOpsServerBootstrap" "Smoke harness should exercise the bootstrap probe."
foreach ($area in $smokeConditionalAreas) {
    Assert-TextContainsLiteral $smokeHarnessScript $area "Smoke harness should route conditional area '$area' from the contract."
}

Assert-TextContainsLiteral $prdPlan "support-contract.json" "PRD should require the shared support contract."
Assert-TextContainsLiteral $prdPlan "tests/Smoke-AzureDevOpsServerSkill.ps1" "PRD should require the smoke harness scaffold."
Assert-TextContainsLiteral $prdPlan "Deferred or cloud-only domains are not reintroduced" "PRD should keep deferred domains out of supported or conditional status."
Assert-True ($prdPlan -notmatch 'Deferred after v1') "PRD should not retain the legacy deferred-after-v1 block."

Assert-TextContainsLiteral $testSpecPlan "support-contract.json" "Test spec should validate the shared support contract."
Assert-TextContainsLiteral $testSpecPlan "AZURE_DEVOPS_SERVER_SMOKE=1" "Test spec should document smoke-harness opt-in."
Assert-TextContainsLiteral $testSpecPlan "the skip path is treated as success" "Test spec should define default skip semantics."
Assert-True ($testSpecPlan -notmatch 'Deferred after v1') "Test spec should not retain the legacy deferred-after-v1 block."

Assert-TextContainsLiteral $readme $deferredPolicyLines["README.md"] "README should preserve the deferred-domain policy line."
Assert-TextContainsLiteral $readmeZh $deferredPolicyLines["README.zh-CN.md"] "Chinese README should preserve the deferred-domain policy line."
Assert-TextContainsLiteral $skillDoc $deferredPolicyLines["azure-devops-server/SKILL.md"] "SKILL.md should preserve the deferred-domain policy line."

Write-Host "Azure DevOps Server skill validation tests passed."
