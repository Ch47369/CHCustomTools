param([ValidateSet('BuiltIn','URP','HDRP')][string[]]$Pipelines=@('BuiltIn','URP','HDRP'))
$ErrorActionPreference='Stop'
$browserRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$browserCache=Join-Path $browserRoot '.build~/LibraryUI034'
$browserHosts=@{BuiltIn='Unity2022';URP='UnityURP';HDRP='UnityHDRP'}
$browserPattern='(?i)ASEShader[\\/]\.validation[\\/]('+(($browserHosts.Values | ForEach-Object {[Regex]::Escape($_)}) -join '|')+')(\s|\")'
$browserRunning=@(Get-CimInstance Win32_Process -Filter "Name = 'Unity.exe'" | Where-Object { $_.CommandLine -match $browserPattern -and $_.CommandLine -notmatch '-adb2' })
if($browserRunning.Count){throw 'An isolated Unity host is active. Do not modify shared C# or reuse its project until it exits.'}
$browserAttempt=Join-Path $browserCache ('Attempts/'+[DateTimeOffset]::UtcNow.ToString('yyyyMMddHHmmssfff'))
New-Item -ItemType Directory -Path $browserAttempt -Force | Out-Null
# Finish copying test code to every selected host before launching any Unity batch.
foreach($browserPipeline in $Pipelines){
    Copy-Item -LiteralPath (Join-Path $browserRoot 'Tests/UnityLibraryBrowserSmoke.cs') -Destination (Join-Path $browserRoot ('.validation/'+$browserHosts[$browserPipeline]+'/Assets/Editor/UnityLibraryBrowserSmoke.cs')) -Force
}
$browserLaunches=@()
foreach($browserPipeline in $Pipelines){
    $browserProject=Join-Path $browserRoot ('.validation/'+$browserHosts[$browserPipeline])
    $browserLog=Join-Path $browserCache ($browserPipeline+'.log')
    $browserResult=Join-Path $browserProject 'LibraryBuildEvidence/browser-smoke-034.json'
    if(Test-Path -LiteralPath $browserLog){Move-Item -LiteralPath $browserLog -Destination ($browserAttempt+'/'+$browserPipeline+'.log')}
    if(Test-Path -LiteralPath $browserResult){Move-Item -LiteralPath $browserResult -Destination ($browserAttempt+'/'+$browserPipeline+'.json')}
    $browserArgs='-batchmode -projectPath '+$browserProject+' -executeMethod UnityLibraryBrowserSmoke.Run -logFile '+$browserLog+' -force-d3d11'
    $browserProcess=Start-Process -FilePath 'C:/Program Files/Unity/Hub/Editor/2022.3.10f1/Editor/Unity.exe' -ArgumentList $browserArgs -WindowStyle Hidden -PassThru
    $browserLaunches+=[pscustomobject]@{pipeline=$browserPipeline;id=$browserProcess.Id;startedUtc=[DateTimeOffset]::UtcNow.ToString('o');log=$browserLog;result=$browserResult}
}
$browserLaunches | ConvertTo-Json | Set-Content ($browserAttempt+'/launches.json') -Encoding UTF8
$browserLaunches | Select-Object pipeline,id
