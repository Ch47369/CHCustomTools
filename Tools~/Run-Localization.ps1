param(
    [string]$UnityEditorPath='C:/Program Files/Unity/Hub/Editor/2022.3.10f1/Editor/Unity.exe',
    [ValidateSet('UnityLocalization042','UnityLocalization042Unity6','UnityLocalization042Tarballs')][string]$ProjectName='UnityLocalization042',
    [switch]$Tarballs
)
$ErrorActionPreference='Stop'
$localizationRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$localizationProject=Join-Path $localizationRoot ('.validation/'+$ProjectName)
$localizationActive=@(Get-CimInstance Win32_Process -Filter "Name = 'Unity.exe'" | Where-Object { $_.CommandLine -match '(?i)ASEShader[\\/]\.validation[\\/]' -and $_.CommandLine -notmatch '-adb2' })
if($localizationActive.Count){throw 'An isolated Unity is active; finish it before starting this check or editing shared C#.'}
New-Item -ItemType Directory -Force -Path ($localizationProject+'/Packages'),($localizationProject+'/ProjectSettings'),($localizationProject+'/Assets/Editor') | Out-Null
$shaderDependency='file:F:/ASEShader'
$audioDependency='file:F:/AudioRhythmCurves-Git/Package'
if($Tarballs){
    $shaderDependency='file:F:/ASEShader/Releases~/com.aseshader.handwritten-converter-0.4.2.tgz'
    $audioDependency='file:F:/AudioRhythmCurves-Git/Releases/AudioRhythmCurves-1.0.7.tgz'
}
$dependencies=[ordered]@{
    'com.aseshader.handwritten-converter'=$shaderDependency
    'com.audiorhythmcurves.audio-rhythm-curves'=$audioDependency
    'com.unity.modules.imgui'='1.0.0'
    'com.unity.modules.animation'='1.0.0'
    'com.unity.modules.audio'='1.0.0'
    'com.unity.modules.jsonserialize'='1.0.0'
    'com.unity.modules.particlesystem'='1.0.0'
}
@{dependencies=$dependencies}|ConvertTo-Json -Depth 4|Set-Content -LiteralPath ($localizationProject+'/Packages/manifest.json') -Encoding utf8NoBOM
$version=if($UnityEditorPath -match '6000'){ '6000.0.80f1' }else{ '2022.3.10f1' }
('m_EditorVersion: '+$version)|Set-Content -LiteralPath ($localizationProject+'/ProjectSettings/ProjectVersion.txt') -Encoding utf8NoBOM
Copy-Item -LiteralPath ($localizationRoot+'/Tests/UnityLocalizationSmoke.cs') -Destination ($localizationProject+'/Assets/Editor/UnityLocalizationSmoke.cs') -Force
$localizationAttempt=Join-Path $localizationRoot ('.build~/Localization042/Attempts/'+[DateTimeOffset]::UtcNow.ToString('yyyyMMddHHmmssfff'))
New-Item -ItemType Directory -Force -Path $localizationAttempt|Out-Null
$localizationLog=Join-Path $localizationAttempt 'editor.log'
$localizationArgs='-projectPath "'+$localizationProject+'" -executeMethod UnityLocalizationSmoke.Run -logFile "'+$localizationLog+'" -force-d3d11'
$localizationProcess=Start-Process -FilePath $UnityEditorPath -ArgumentList $localizationArgs -WorkingDirectory $localizationProject -WindowStyle Hidden -PassThru
[pscustomobject]@{id=$localizationProcess.Id;project=$localizationProject;log=$localizationLog;output=$localizationProject+'/Artifacts/localization-verification.json';startedUtc=[DateTimeOffset]::UtcNow.ToString('o')}|ConvertTo-Json|Tee-Object -FilePath ($localizationAttempt+'/launch.json')
