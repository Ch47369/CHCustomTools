param(
    [Parameter(Mandatory=$true)][string]$BeforeDirectory,
    [Parameter(Mandatory=$true)][string]$AfterDirectory
)
$ErrorActionPreference='Stop'
$comparisonBefore=Get-Content -LiteralPath (Join-Path $BeforeDirectory 'public-corpus-analysis.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$comparisonAfter=Get-Content -LiteralPath (Join-Path $AfterDirectory 'public-corpus-analysis.json') -Raw -Encoding UTF8 | ConvertFrom-Json
if($comparisonBefore.summary.manifestSha256 -ne $comparisonAfter.summary.manifestSha256){throw 'Before/after must use the same frozen source manifest.'}
$comparisonIndex=@{}
foreach($row in $comparisonBefore.files){$comparisonIndex[$row.repository+':'+$row.path]=$row}
$comparisonChanges=@()
foreach($row in $comparisonAfter.files){
    $old=$comparisonIndex[$row.repository+':'+$row.path]
    if(!$old -or $old.sha256 -ne $row.sha256){throw ('Source changed or missing in comparison: '+$row.path)}
    if($old.status -ne $row.status -or ($old.blockers -join "`n") -ne ($row.blockers -join "`n")){
        $comparisonChanges += [ordered]@{repository=$row.repository;path=$row.path;sha256=$row.sha256;beforeStatus=$old.status;afterStatus=$row.status;beforeBlockers=$old.blockers;afterBlockers=$row.blockers}
    }
}
$comparisonTargets=@(foreach($pipeline in @('BuiltIn','URP','HDRP')){
    $targets=@($comparisonAfter.files | ForEach-Object {$_.targets} | Where-Object {$_.pipeline -eq $pipeline})
    [ordered]@{pipeline=$pipeline;shaderInputs=$targets.Count;planned=@($targets | Where-Object {$_.canPlan}).Count;needsAdaptation=@($targets | Where-Object {!$_.canPlan}).Count;generated=0}
})
$comparisonHoldout=@($comparisonAfter.files | Where-Object {$_.evaluationRole -eq 'Holdout'})
$comparisonUserBefore=Get-Content -LiteralPath (Join-Path $BeforeDirectory 'user-reference-analysis.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$comparisonUserAfter=Get-Content -LiteralPath (Join-Path $AfterDirectory 'user-reference-analysis.json') -Raw -Encoding UTF8 | ConvertFrom-Json
foreach($row in $comparisonUserAfter.files){
    $old=@($comparisonUserBefore.files | Where-Object {$_.path -eq $row.path})
    if($old.Count -ne 1 -or $old[0].sha256 -ne $row.sha256){throw ('User reference changed: '+$row.path)}
}
$comparisonSummary=[ordered]@{
    beforeVersion=$comparisonBefore.summary.libraryVersion;afterVersion=$comparisonAfter.summary.libraryVersion
    manifestSha256=$comparisonAfter.summary.manifestSha256
    repositories=@($comparisonAfter.files.repository | Sort-Object -Unique).Count
    sourceFiles=$comparisonAfter.summary.publicSourceFiles;shaderFiles=$comparisonAfter.summary.publicShaderFiles;includeFiles=$comparisonAfter.summary.publicIncludeFiles
    fullShaderPlannedBefore=@($comparisonBefore.files | Where-Object {$_.canPlan}).Count
    fullShaderPlannedAfter=@($comparisonAfter.files | Where-Object {$_.canPlan}).Count
    unchangedUserReferences=$comparisonUserAfter.files.Count
    analysisErrors=$comparisonAfter.summary.analysisErrors
    targetResults=$comparisonTargets
    holdout=[ordered]@{repositories=@($comparisonHoldout.repository | Sort-Object -Unique);files=$comparisonHoldout.Count;shaderFiles=@($comparisonHoldout | Where-Object {$_.path -match '\.shader$'}).Count;planned=@($comparisonHoldout | Where-Object {$_.canPlan}).Count;note='Repository roles were selected before implementation. This small holdout is not a broad success guarantee.'}
    generatedShaders=0;aseSaveReloadPerformed=$false;unityShaderCompilationPerformed=$false;visualComparisonPerformed=$false
}
$comparisonMathBeforePath=Join-Path $AfterDirectory 'function-probes-before.json'
$comparisonMathAfterPath=Join-Path $AfterDirectory 'function-probes-after.json'
if((Test-Path -LiteralPath $comparisonMathBeforePath) -and (Test-Path -LiteralPath $comparisonMathAfterPath)){
    $mathBefore=Get-Content -LiteralPath $comparisonMathBeforePath -Raw -Encoding UTF8 | ConvertFrom-Json
    $mathAfter=Get-Content -LiteralPath $comparisonMathAfterPath -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach($probe in $mathAfter.probes){
        $old=@($mathBefore.probes | Where-Object {$_.id -eq $probe.id})
        if($old.Count -ne 1 -or $old[0].expression -ne $probe.expression -or ($old[0].sourceFiles.sha256 -join ',') -ne ($probe.sourceFiles.sha256 -join ',')){throw 'Function probe inputs changed.'}
    }
    $comparisonSummary.functionOnlyProbes=[ordered]@{count=$mathAfter.probeCount;plannedBefore=$mathBefore.planned;plannedAfter=$mathAfter.planned;numericalChecksBefore=$mathBefore.numericalChecks;numericalChecksAfter=$mathAfter.numericalChecks;fullShaderConversion=$false}
}
[IO.File]::WriteAllText((Join-Path ([IO.Path]::GetFullPath($AfterDirectory)) 'comparison.json'),([ordered]@{summary=$comparisonSummary;changedFiles=$comparisonChanges} | ConvertTo-Json -Depth 16),(New-Object Text.UTF8Encoding($false)))
$comparisonSummary | ConvertTo-Json -Depth 8
