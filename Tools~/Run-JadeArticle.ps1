param([ValidateSet('Build','Validate','Batch')][string]$Stage='Build',[ValidateSet('BuiltIn','URP','HDRP')][string[]]$Pipelines=@('BuiltIn','URP','HDRP'))
$ErrorActionPreference='Stop'
$jadeRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'));$jadeCache=Join-Path $jadeRoot '.build~/JadeReference036'
$jadeHosts=@{BuiltIn='Unity2022';URP='UnityURP';HDRP='UnityHDRP'}
$jadeRunning=@(Get-CimInstance Win32_Process -Filter "Name='Unity.exe'" | Where-Object {$_.CommandLine -match 'ASEShader[\\/]\.validation[\\/](Unity2022|UnityURP|UnityHDRP)(\s|\")' -and $_.CommandLine -notmatch '-adb2'})
if($jadeRunning.Count){throw 'Wait until isolated Unity hosts exit before modifying scripts or reusing projects.'}
$jadeAttempt=Join-Path $jadeCache ('Attempts/'+$Stage+'-'+[DateTimeOffset]::UtcNow.ToString('yyyyMMddHHmmssfff'));New-Item -ItemType Directory -Path $jadeAttempt -Force | Out-Null
foreach($jadePipeline in $Pipelines){
    $jadeProject=Join-Path $jadeRoot ('.validation/'+$jadeHosts[$jadePipeline])
    foreach($jadeScript in @('UnityLibraryBuild.cs','UnityJadeArticleValidation.cs')){Copy-Item -LiteralPath (Join-Path $jadeRoot ('Tests/'+$jadeScript)) -Destination ($jadeProject+'/Assets/Editor') -Force}
}
$jadeLaunches=@()
foreach($jadePipeline in $Pipelines){
    $jadeProject=Join-Path $jadeRoot ('.validation/'+$jadeHosts[$jadePipeline]);$jadeLog=Join-Path $jadeAttempt ($jadePipeline+'.log')
    $jadeMethod=if($Stage -eq 'Build'){'UnityLibraryBuild.Run'}elseif($Stage -eq 'Batch'){'UnityJadeArticleValidation.Batch'}else{'UnityJadeArticleValidation.Run'}
    $jadeName=if($Stage -eq 'Build'){'results.json'}elseif($Stage -eq 'Batch'){'jade-batch-036.json'}else{'jade-validation-036.json'}
    $jadeResult=$jadeProject+'/LibraryBuildEvidence/'+$jadeName
    if(Test-Path -LiteralPath $jadeResult){Move-Item -LiteralPath $jadeResult -Destination ($jadeAttempt+'/'+$jadePipeline+'-previous.json')}
    if($Stage -eq 'Build' -and (Test-Path -LiteralPath ($jadeProject+'/LibraryBuildEvidence/probe.json'))){Copy-Item -LiteralPath ($jadeProject+'/LibraryBuildEvidence/probe.json') -Destination ($jadeAttempt+'/'+$jadePipeline+'-previous-probe.json')}
    $jadeArgs=@('-batchmode','-projectPath',$jadeProject,'-executeMethod',$jadeMethod,'-logFile',$jadeLog,'-force-d3d11')
    if($Stage -eq 'Build'){$jadeArgs+=@('-libraryJobs',($jadeCache+'/jobs-'+$jadePipeline+'.json'))}
    $jadeProcess=Start-Process -FilePath 'C:/Program Files/Unity/Hub/Editor/2022.3.10f1/Editor/Unity.exe' -ArgumentList $jadeArgs -WindowStyle Hidden -PassThru
    $jadeLaunches+=[pscustomobject]@{stage=$Stage;pipeline=$jadePipeline;id=$jadeProcess.Id;log=$jadeLog;result=$jadeResult;startedUtc=[DateTimeOffset]::UtcNow.ToString('o')}
}
$jadeLaunches | ConvertTo-Json | Set-Content -LiteralPath ($jadeAttempt+'/launches.json') -Encoding UTF8
$jadeLaunches | Format-List
