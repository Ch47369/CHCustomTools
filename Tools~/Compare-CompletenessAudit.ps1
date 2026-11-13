param(
    [Parameter(Mandatory=$true)][string]$BeforeDirectory,
    [Parameter(Mandatory=$true)][string]$AfterDirectory,
    [Parameter(Mandatory=$true)][string]$SemanticBeforePath,
    [Parameter(Mandatory=$true)][string]$SemanticAfterPath,
    [Parameter(Mandatory=$true)][string]$OutputDirectory
)
$ErrorActionPreference='Stop'
function Read-Json([string]$Path) { Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json }
function Write-Json([string]$Name, $Value) {
    [IO.File]::WriteAllText((Join-Path $auditOutput $Name), ($Value | ConvertTo-Json -Depth 32), (New-Object Text.UTF8Encoding($false)))
}
$before=Read-Json (Join-Path $BeforeDirectory 'public-corpus-analysis.json')
$after=Read-Json (Join-Path $AfterDirectory 'public-corpus-analysis.json')
$semanticBefore=Read-Json $SemanticBeforePath
$semanticAfter=Read-Json $SemanticAfterPath
if($before.summary.manifestSha256 -ne $after.summary.manifestSha256) { throw 'Source manifests differ.' }
if($before.files.Count -ne $after.files.Count) { throw 'Source inventories differ.' }
$beforeIndex=@{}
foreach($row in $before.files) {
    $key=$row.repository+':'+$row.path
    if($beforeIndex.ContainsKey($key)) { throw ('Duplicate input: '+$key) }
    $beforeIndex[$key]=$row
}
$changed=@()
$rows=@(foreach($row in $after.files) {
    $key=$row.repository+':'+$row.path
    $old=$beforeIndex[$key]
    if(!$old -or $old.sha256 -ne $row.sha256 -or $old.commit -ne $row.commit) { throw ('Source changed: '+$key) }
    $targets=@(foreach($target in $row.targets) {
        $oldTarget=@($old.targets | Where-Object {$_.pipeline -eq $target.pipeline})
        if($oldTarget.Count -ne 1) { throw ('Target inventory changed: '+$key) }
        if($oldTarget[0].canPlan -ne $target.canPlan -or ($oldTarget[0].blockers -join "`n") -ne ($target.blockers -join "`n")) {
            $changed += [ordered]@{repository=$row.repository;path=$row.path;pipeline=$target.pipeline;beforeCanPlan=$oldTarget[0].canPlan;afterCanPlan=$target.canPlan;beforeBlockers=$oldTarget[0].blockers;afterBlockers=$target.blockers}
        }
        [ordered]@{pipeline=$target.pipeline;status=$target.status;canPlan=$target.canPlan;blockers=$target.blockers;planErrors=$target.planErrors}
    })
    [ordered]@{repository=$row.repository;path=$row.path;commit=$row.commit;sha256=$row.sha256;sourcePipeline=$row.sourcePipeline;evaluationRole=$row.evaluationRole;categories=$row.knowledge.materialCategories;status=$row.status;targets=$targets}
})
if($semanticBefore.probes.Count -ne $semanticAfter.probes.Count -or $semanticBefore.results.Count -ne $semanticAfter.results.Count) { throw 'Semantic probe inventories differ.' }
foreach($probe in $semanticAfter.probes) {
    $old=@($semanticBefore.probes | Where-Object {$_.id -eq $probe.id})
    if($old.Count -ne 1 -or $old[0].source -cne $probe.source -or $old[0].portable -ne $probe.portable -or $old[0].blocker -cne $probe.blocker) { throw ('Semantic probe changed: '+$probe.id) }
}
$targetSummary=@(foreach($pipeline in @('BuiltIn','URP','HDRP')) {
    $oldTargets=@($before.files | ForEach-Object {$_.targets} | Where-Object {$_.pipeline -eq $pipeline})
    $newTargets=@($after.files | ForEach-Object {$_.targets} | Where-Object {$_.pipeline -eq $pipeline})
    [ordered]@{pipeline=$pipeline;shaderInputs=$newTargets.Count;beforePlanned=@($oldTargets | Where-Object {$_.canPlan}).Count;afterPlanned=@($newTargets | Where-Object {$_.canPlan}).Count;generated=0}
})
$categorySummary=@(foreach($category in @('Water','Skin','Hair','Fabric','Metal','Stone','Jade','UI','UIEffects','VFX','UVAnimation','VertexAnimation')) {
    $categoryRows=@($after.files | Where-Object {$_.path -match '\.shader$' -and $_.knowledge.materialCategories -contains $category})
    [ordered]@{category=$category;shaderFiles=$categoryRows.Count;targets=@(foreach($pipeline in @('BuiltIn','URP','HDRP')) {
        $matches=@($categoryRows | ForEach-Object {$_.targets} | Where-Object {$_.pipeline -eq $pipeline})
        [ordered]@{pipeline=$pipeline;planned=@($matches | Where-Object {$_.canPlan}).Count;blocked=@($matches | Where-Object {!$_.canPlan}).Count}
    });classification='Heuristic, overlapping research hints; not a verified material classification.'}
})
$holdout=@($after.files | Where-Object {$_.evaluationRole -eq 'Holdout' -and $_.path -match '\.shader$'})
$summary=[ordered]@{
    checkedUtc=[DateTimeOffset]::UtcNow.ToString('o');libraryVersion=$after.summary.libraryVersion
    manifestSha256=$after.summary.manifestSha256;sourceFiles=$after.files.Count;shaderFiles=$after.summary.publicShaderFiles;includeFiles=$after.summary.publicIncludeFiles
    analysisErrors=$after.summary.analysisErrors;sourceHashesMatched=$true;targetResults=$targetSummary
    holdoutShaderFiles=$holdout.Count;holdoutPlanned=@($holdout | Where-Object {$_.canPlan}).Count
    semanticProbeCount=$semanticAfter.summary.probeCount;semanticTargetEvaluations=$semanticAfter.summary.targetEvaluations
    semanticPassedBefore=$semanticBefore.summary.passed;semanticPassedAfter=$semanticAfter.summary.passed
    falseReadyBefore=@($semanticBefore.results | Where-Object {!$_.expectedCanPlan -and $_.actualCanPlan}).Count
    falseReadyAfter=@($semanticAfter.results | Where-Object {!$_.expectedCanPlan -and $_.actualCanPlan}).Count
    legitimatePortableRejectedBefore=@($semanticBefore.results | Where-Object {$_.expectedCanPlan -and !$_.actualCanPlan}).Count
    legitimatePortableRejectedAfter=@($semanticAfter.results | Where-Object {$_.expectedCanPlan -and !$_.actualCanPlan}).Count
    changedTargetDiagnostics=$changed.Count;generatedShaders=0;aseSaveReloadPerformed=$false;unityShaderCompilationPerformed=$false;visualComparisonPerformed=$false
    note='Synthetic contract probes test planning/rejection only. Public corpus source hashes are frozen. Includes are inventoried, not preprocessed or compiled. Baseline and after use the same final test harness with different core assemblies.'
}
if($summary.analysisErrors -ne 0 -or $semanticAfter.summary.failed -ne 0) { throw 'Audit has unresolved failures.' }
$auditOutput=[IO.Path]::GetFullPath($OutputDirectory)
New-Item -ItemType Directory -Path $auditOutput -Force | Out-Null
Write-Json 'comparison.json' ([ordered]@{summary=$summary;categoryCoverage=$categorySummary;changedTargets=$changed})
Write-Json 'public-corpus-results.json' ([ordered]@{summary=$summary;files=$rows})
Copy-Item -LiteralPath $SemanticBeforePath -Destination (Join-Path $auditOutput 'semantic-before.json') -Force
Copy-Item -LiteralPath $SemanticAfterPath -Destination (Join-Path $auditOutput 'semantic-after.json') -Force
Copy-Item -LiteralPath (Join-Path $AfterDirectory 'rule-catalog.json') -Destination (Join-Path $auditOutput 'rule-catalog.json') -Force
$summary | ConvertTo-Json -Depth 8
