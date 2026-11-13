param([ValidateSet('Build','Filters','Batch')][string]$Stage='Build',[ValidateSet('BuiltIn','URP','HDRP')][string[]]$Pipelines=@('BuiltIn','URP','HDRP'))
$ErrorActionPreference='Stop'
$filterRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$filterCache=Join-Path $filterRoot '.build~/PublicLibrary033'
$filterUnity='C:/Program Files/Unity/Hub/Editor/2022.3.10f1/Editor/Unity.exe'
$filterHosts=@{BuiltIn='Unity2022';URP='UnityURP';HDRP='UnityHDRP'}
$filterSelectedHosts=($Pipelines | ForEach-Object {[Regex]::Escape($filterHosts[$_])}) -join '|'
$filterProjectPattern='(?i)ASEShader[\\/]\.validation[\\/]('+$filterSelectedHosts+')(\s|\")'
$filterRunning=@(Get-CimInstance Win32_Process -Filter "Name = 'Unity.exe'" | Where-Object { $_.CommandLine -match $filterProjectPattern -and $_.CommandLine -notmatch '-adb2' })
if($filterRunning.Count){throw 'An isolated host is still active. Wait for its exit before reusing the project.'}
$filterStamp=[DateTimeOffset]::UtcNow.ToString('yyyyMMddHHmmssfff')
$filterArchive=Join-Path $filterCache ('Attempts/'+$Stage+'-'+$filterStamp)
New-Item -ItemType Directory -Path $filterArchive -Force | Out-Null
$filterProcesses=@()
foreach($filterPipeline in $Pipelines){
    $filterProject=Join-Path $filterRoot ('.validation/'+$filterHosts[$filterPipeline])
    if($Stage -eq 'Build'){
        Copy-Item (Join-Path $filterRoot 'Tests/UnityLibraryBuild.cs'),(Join-Path $filterRoot 'Tests/UnityLibraryBatchSmoke.cs'),(Join-Path $filterRoot 'Tests/UnityPublicFilterSmoke.cs') -Destination ($filterProject+'/Assets/Editor') -Force
        $filterMethod='UnityLibraryBuild.Run';$filterExtra=' -libraryJobs '+$filterCache+'/jobs-'+$filterPipeline+'.json';$filterOutput='results.json'
    }elseif($Stage -eq 'Filters'){
        $filterMethod='UnityPublicFilterSmoke.Run';$filterExtra=' -filterResults '+$filterProject+'/LibraryBuildEvidence/results.json';$filterOutput='public-filters-033.json'
    }else{
        $filterMethod='UnityLibraryBatchSmoke.Run';$filterExtra=' -expectedFamilies 109 -expectedMappedFamilies 64';$filterOutput='batch-smoke-031.json'
    }
    $filterLog=Join-Path $filterCache ($Stage.ToLowerInvariant()+'-'+$filterPipeline+'.log')
    if(Test-Path -LiteralPath $filterLog){Move-Item -LiteralPath $filterLog -Destination ($filterArchive+'/'+$filterPipeline+'.log')}
    $filterResult=Join-Path $filterProject ('LibraryBuildEvidence/'+$filterOutput)
    if(Test-Path -LiteralPath $filterResult){Move-Item -LiteralPath $filterResult -Destination ($filterArchive+'/'+$filterPipeline+'-'+$filterOutput)}
    $filterArgs='-batchmode -projectPath '+$filterProject+' -executeMethod '+$filterMethod+$filterExtra+' -logFile '+$filterLog+' -force-d3d11'
    $filterProcess=Start-Process -FilePath $filterUnity -ArgumentList $filterArgs -WindowStyle Hidden -PassThru
    $filterProcesses+=[pscustomobject]@{stage=$Stage;pipeline=$filterPipeline;id=$filterProcess.Id;startedUtc=[DateTimeOffset]::UtcNow.ToString('o');log=$filterLog;result=$filterResult}
}
$filterProcesses | ConvertTo-Json | Set-Content ($filterArchive+'/launches.json') -Encoding UTF8
$filterProcesses | Select-Object stage,pipeline,id
