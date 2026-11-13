param([string]$OutputDirectory='Documentation~/Evidence/FullValidation028')
$ErrorActionPreference='Stop'
$validationWorkspace=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$validationDestination=[IO.Path]::GetFullPath((Join-Path $validationWorkspace $OutputDirectory))
if(!$validationDestination.StartsWith($validationWorkspace+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw 'Evidence output must stay in workspace.'}
New-Item -ItemType Directory -Path $validationDestination -Force | Out-Null
$validationSummaries=@()
foreach($validationProject in @('Unity2022','UnityURP','UnityHDRP')) {
    $validationProjectRoot=Join-Path $validationWorkspace ('.validation/'+$validationProject)
    $validationLatest=Join-Path $validationProjectRoot 'full-validation-latest.txt'
    if(!(Test-Path -LiteralPath $validationLatest)){continue}
    $validationRunRoot=[IO.Path]::GetFullPath((Get-Content -LiteralPath $validationLatest -Raw).Trim())
    if(!$validationRunRoot.StartsWith($validationProjectRoot+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw 'Unexpected run root.'}
    $validationResults=Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $validationRunRoot 'results.json') | ConvertFrom-Json
    if(!$validationResults.completed){throw 'Incomplete run cannot be collected as completed.'}
    $validationCompletedRuns=@()
    $validationRunEvidence=@()
    $validationMerged=@{}
    foreach($validationRunFile in Get-ChildItem -LiteralPath (Join-Path $validationProjectRoot 'ValidationEvidence') -Filter 'results.json' -Recurse -File | Sort-Object LastWriteTime) {
        $validationRun=Get-Content -Raw -Encoding UTF8 -LiteralPath $validationRunFile.FullName | ConvertFrom-Json
        if(!$validationRun.completed){continue}
        $validationCompletedRuns+=$validationRun.runId
        $validationRunEvidence+=@{runId=$validationRun.runId;harnessSha256=$validationRun.harnessSha256;inventorySha256=$validationRun.inventorySha256;finishedUtc=$validationRun.finishedUtc;root=$validationRunFile.DirectoryName}
        foreach($validationRow in $validationRun.rows) {
            $validationRow | Add-Member -NotePropertyName evidenceRunId -NotePropertyValue $validationRun.runId -Force
            $validationMerged[$validationRow.id]=$validationRow
        }
    }
    $validationResults.rows=@($validationMerged.Values | Sort-Object group,id)
    $validationRows=@(foreach($row in $validationResults.rows) {
        [ordered]@{id=$row.id;group=$row.group;sha256=$row.sha256;pipeline=$row.pipeline;status=$row.status;evidenceRunId=$row.evidenceRunId;sourceHashMatched=$row.sourceHashMatched;sourceUnchanged=$row.sourceUnchanged
            graphLoaded=$row.graphLoaded;graphRoundTrip=$row.graphRoundTrip;shaderCompiled=$row.shaderCompiled;fixtureCompared=$row.fixtureCompared;fixtureMaxError=$row.fixtureMaxError;fixtureCases=$row.fixtureCases
            nodes=$row.nodes;passes=$row.passes;outputPath=$row.outputPath;error=$row.error;messages=$row.messages;analysisReport=$row.analysis.report;generationReport=$row.generation.report;generationError=$row.generation.error}
    })
    $validationSummary=[ordered]@{project=$validationProject;runIds=$validationCompletedRuns;pipeline=$validationResults.pipeline;unityVersion=$validationResults.unityVersion;aseVersion=$validationResults.aseVersion;finishedUtc=$validationResults.finishedUtc;inputs=$validationRows.Count
        sourceHashMismatches=@($validationRows | Where-Object {!$_.sourceHashMatched -or !$_.sourceUnchanged}).Count
        results=@($validationResults.rows | Group-Object status | ForEach-Object {[ordered]@{status=$_.Name;count=$_.Count}})
        generated=@($validationResults.rows | Where-Object {$_.status -eq 'Generated' -and $_.graphRoundTrip -and $_.shaderCompiled}).Count
        migratedAndCompiled=@($validationResults.rows | Where-Object {$_.status -eq 'MigrationCompiled' -and $_.graphRoundTrip -and $_.shaderCompiled}).Count
        comparedFixtures=@($validationResults.rows | Where-Object {$_.fixtureCompared}).Count
        errors=@($validationResults.rows | Where-Object {$_.error}).Count
        scope='Default/current material passes on D3D11. Fixture comparisons do not establish source-scene, all-keyword or all-platform equivalence. Blocked inputs have not been generated.'}
    $validationSummaries+=$validationSummary
    $validationTarget=Join-Path $validationDestination $validationResults.pipeline
    New-Item -ItemType Directory -Path $validationTarget -Force | Out-Null
    [IO.File]::WriteAllText((Join-Path $validationTarget 'results.json'),([ordered]@{summary=$validationSummary;rows=$validationRows}|ConvertTo-Json -Depth 24),(New-Object Text.UTF8Encoding($false)))
    Copy-Item -LiteralPath (Join-Path $validationRunRoot 'probe.json') -Destination (Join-Path $validationTarget 'probe.json') -Force
    $validationUsedRuns=@($validationResults.rows.evidenceRunId | Sort-Object -Unique)
    $validationProvenance=@()
    foreach($validationRunEntry in $validationRunEvidence | Where-Object {$_.runId -in $validationUsedRuns}) {
        $validationRunTarget=Join-Path $validationTarget $validationRunEntry.runId
        New-Item -ItemType Directory -Path $validationRunTarget -Force | Out-Null
        Copy-Item -LiteralPath (Join-Path $validationRunEntry.root 'probe.json') -Destination $validationRunTarget -Force
        foreach($validationDescription in Get-ChildItem -LiteralPath $validationRunEntry.root -Filter 'describe-*.json' -File){Copy-Item -LiteralPath $validationDescription.FullName -Destination $validationRunTarget -Force}
        $validationProvenance+=@{runId=$validationRunEntry.runId;harnessSha256=$validationRunEntry.harnessSha256;inventorySha256=$validationRunEntry.inventorySha256;finishedUtc=$validationRunEntry.finishedUtc}
    }
    [IO.File]::WriteAllText((Join-Path $validationTarget 'provenance.json'),($validationProvenance | ConvertTo-Json -Depth 8),(New-Object Text.UTF8Encoding($false)))
}
[IO.File]::WriteAllText((Join-Path $validationDestination 'summary.json'),([ordered]@{checkedUtc=[DateTimeOffset]::UtcNow.ToString('o');targets=$validationSummaries}|ConvertTo-Json -Depth 14),(New-Object Text.UTF8Encoding($false)))
$validationSummaries | ConvertTo-Json -Depth 8
