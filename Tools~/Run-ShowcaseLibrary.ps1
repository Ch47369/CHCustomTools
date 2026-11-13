param([ValidateSet('Build','Render','Scene','Batch')][string]$Stage='Build',[ValidateSet('BuiltIn','URP','HDRP')][string[]]$Pipelines=@('BuiltIn','URP','HDRP'))
$ErrorActionPreference='Stop'
$showRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'));$showCache=Join-Path $showRoot '.build~/Showcase035'
$showHosts=@{BuiltIn='Unity2022';URP='UnityURP';HDRP='UnityHDRP'}
$showRunning=@(Get-CimInstance Win32_Process -Filter "Name = 'Unity.exe'" | Where-Object { $_.CommandLine -match 'ASEShader[\\/]\.validation[\\/](Unity2022|UnityURP|UnityHDRP)(\s|\")' -and $_.CommandLine -notmatch '-adb2' })
if($showRunning.Count){throw 'An isolated Unity host is active; wait before editing C# or reusing hosts.'}
$showAttempt=Join-Path $showCache ('Attempts/'+$Stage+'-'+[DateTimeOffset]::UtcNow.ToString('yyyyMMddHHmmssfff'));New-Item -ItemType Directory -Path $showAttempt -Force | Out-Null
foreach($showPipeline in $Pipelines){
    $showProject=Join-Path $showRoot ('.validation/'+$showHosts[$showPipeline])
    Copy-Item -LiteralPath (Join-Path $showRoot 'Tests/UnityLibraryBuild.cs') -Destination ($showProject+'/Assets/Editor') -Force
    if(Test-Path -LiteralPath (Join-Path $showRoot 'Tests/UnityShowcaseValidation.cs')){Copy-Item -LiteralPath (Join-Path $showRoot 'Tests/UnityShowcaseValidation.cs') -Destination ($showProject+'/Assets/Editor') -Force}
}
$showLaunches=@()
foreach($showPipeline in $Pipelines){
    $showProject=Join-Path $showRoot ('.validation/'+$showHosts[$showPipeline]);$showLog=Join-Path $showCache ($Stage+'-'+$showPipeline+'.log')
    if($Stage -eq 'Build'){$showMethod='UnityLibraryBuild.Run';$showExtra=' -libraryJobs '+$showCache+'/jobs-'+$showPipeline+'.json';$showName='results.json'}
    elseif($Stage -eq 'Render'){$showMethod='UnityShowcaseValidation.Run';$showExtra='';$showName='showcase-render-035.json'}
    elseif($Stage -eq 'Scene'){$showMethod='UnityShowcaseValidation.Scene';$showExtra='';$showName='showcase-scene-035.json'}
    else{$showMethod='UnityShowcaseValidation.Batch';$showExtra='';$showName='showcase-batch-035.json'}
    $showResult=$showProject+'/LibraryBuildEvidence/'+$showName
    if(Test-Path -LiteralPath $showLog){Move-Item -LiteralPath $showLog -Destination ($showAttempt+'/'+$showPipeline+'.log')}
    if(Test-Path -LiteralPath $showResult){Move-Item -LiteralPath $showResult -Destination ($showAttempt+'/'+$showPipeline+'.json')}
    if($Stage -eq 'Scene' -and (Test-Path -LiteralPath ($showProject+'/LibraryBuildEvidence/Showcase035/Scene'))){Copy-Item -LiteralPath ($showProject+'/LibraryBuildEvidence/Showcase035/Scene') -Destination ($showAttempt+'/'+$showPipeline+'-Scene') -Recurse}
    if($Stage -eq 'Render' -and (Test-Path -LiteralPath ($showProject+'/LibraryBuildEvidence/Showcase035'))){
        $showImages=Join-Path $showAttempt ($showPipeline+'-Render');New-Item -ItemType Directory -Path $showImages -Force | Out-Null
        Get-ChildItem -LiteralPath ($showProject+'/LibraryBuildEvidence/Showcase035') -File | Where-Object { $_.Extension -in @('.png','.rgba32f') } | Copy-Item -Destination $showImages
    }
    $showArgs='-batchmode -projectPath '+$showProject+' -executeMethod '+$showMethod+$showExtra+' -logFile '+$showLog+' -force-d3d11'
    $showProcess=Start-Process -FilePath 'C:/Program Files/Unity/Hub/Editor/2022.3.10f1/Editor/Unity.exe' -ArgumentList $showArgs -WindowStyle Hidden -PassThru
    $showLaunches+=[pscustomobject]@{stage=$Stage;pipeline=$showPipeline;id=$showProcess.Id;startedUtc=[DateTimeOffset]::UtcNow.ToString('o');log=$showLog;result=$showResult}
}
$showLaunches | ConvertTo-Json | Set-Content ($showAttempt+'/launches.json') -Encoding UTF8
$showLaunches | Select-Object stage,pipeline,id
