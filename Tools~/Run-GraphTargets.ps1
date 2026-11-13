param(
    [ValidateSet('BuiltIn','URP','HDRP')][string]$Pipeline='URP',
    [string]$UnityEditorPath='C:/Program Files/Unity/Hub/Editor/2022.3.10f1/Editor/Unity.exe',
    [switch]$Tarball,
    [string]$Version='0.4.6'
)
$ErrorActionPreference='Stop'
$graphRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$active=@(Get-CimInstance Win32_Process -Filter "Name = 'Unity.exe'" | Where-Object { $_.CommandLine -match '(?i)ASEShader[\\/]\.validation[\\/]' -and $_.CommandLine -notmatch '-adb2' })
if($active.Count){throw 'An isolated Unity Editor is active. Finish it before changing shared C# or launching another check.'}
$graphProject=if($Tarball -or $Pipeline -eq 'BuiltIn'){Join-Path $graphRoot ('.validation/GraphTargets046-'+$Pipeline+$(if($Tarball){'-Tarball'}else{'-Source'}))}else{Join-Path $graphRoot ('.validation/Unity'+$Pipeline)}
New-Item -ItemType Directory -Force -Path ($graphProject+'/Packages'),($graphProject+'/ProjectSettings'),($graphProject+'/Assets/Editor')|Out-Null
$graphArchive=$null
if($Tarball){
    $graphOriginal=Join-Path $graphRoot ('Releases~/com.aseshader.handwritten-converter-'+$Version+'.tgz')
    $graphHash=(Get-FileHash -LiteralPath $graphOriginal -Algorithm SHA256).Hash.ToLowerInvariant()
    $graphArchive=Join-Path $graphRoot ('.build~/GraphTargets046/Tarballs/'+$graphHash+'.tgz')
    New-Item -ItemType Directory -Force -Path (Split-Path $graphArchive)|Out-Null
    if(!(Test-Path -LiteralPath $graphArchive)){Copy-Item -LiteralPath $graphOriginal -Destination $graphArchive}
}
if($Tarball -or $Pipeline -eq 'BuiltIn'){
    $dependencies=[ordered]@{'com.aseshader.handwritten-converter'=$(if($Tarball){'file:'+($graphArchive.Replace('\','/'))}else{'file:F:/ASEShader'});'com.unity.shadergraph'='14.0.8'}
    if($Pipeline -ne 'BuiltIn'){
        $dependencies[$(if($Pipeline -eq 'URP'){'com.unity.render-pipelines.universal'}else{'com.unity.render-pipelines.high-definition'})]='14.0.8'
        # Reuse only task-owned isolated settings and pipeline configuration assets.
        Copy-Item -LiteralPath ($graphRoot+'/.validation/Unity'+$Pipeline+'/ProjectSettings/GraphicsSettings.asset') -Destination ($graphProject+'/ProjectSettings/GraphicsSettings.asset') -Force
        Copy-Item -LiteralPath ($graphRoot+'/.validation/Unity'+$Pipeline+'/ProjectSettings/QualitySettings.asset') -Destination ($graphProject+'/ProjectSettings/QualitySettings.asset') -Force
        Get-ChildItem -LiteralPath ($graphRoot+'/.validation/Unity'+$Pipeline+'/Assets') -File | Where-Object { $_.Name -like '*.asset' -or $_.Name -like '*.asset.meta' } | Copy-Item -Destination ($graphProject+'/Assets') -Force
        if($Pipeline -eq 'HDRP'){
            Copy-Item -LiteralPath ($graphRoot+'/.validation/UnityHDRP/Assets/HDRPDefaultResources') -Destination ($graphProject+'/Assets') -Recurse -Force
            Copy-Item -LiteralPath ($graphRoot+'/.validation/UnityHDRP/Assets/HDRPDefaultResources.meta') -Destination ($graphProject+'/Assets') -Force
        }
    }
    @{dependencies=$dependencies}|ConvertTo-Json -Depth 4|Set-Content -LiteralPath ($graphProject+'/Packages/manifest.json') -Encoding utf8NoBOM
    'm_EditorVersion: 2022.3.10f1'|Set-Content -LiteralPath ($graphProject+'/ProjectSettings/ProjectVersion.txt') -Encoding utf8NoBOM
}
Copy-Item -LiteralPath ($graphRoot+'/Tests/UnityGraphTargetsSmoke.cs') -Destination ($graphProject+'/Assets/Editor/UnityGraphTargetsSmoke.cs') -Force
$graphAttempt=Join-Path $graphRoot ('.build~/GraphTargets046/Launches/'+[DateTimeOffset]::UtcNow.ToString('yyyyMMddHHmmssfff'))
New-Item -ItemType Directory -Force -Path $graphAttempt|Out-Null
$graphLog=Join-Path $graphAttempt 'editor.log'
$graphArguments='-batchmode -projectPath "'+$graphProject+'" -executeMethod UnityGraphTargetsSmoke.Run -logFile "'+$graphLog+'" -force-d3d11'
$graphProcess=Start-Process -FilePath $UnityEditorPath -ArgumentList $graphArguments -WorkingDirectory $graphProject -WindowStyle Hidden -PassThru
[pscustomobject]@{id=$graphProcess.Id;project=$graphProject;log=$graphLog;tarballSha256=$graphHash;startedUtc=[DateTimeOffset]::UtcNow.ToString('o')}|ConvertTo-Json|Tee-Object -FilePath ($graphAttempt+'/launch.json')
