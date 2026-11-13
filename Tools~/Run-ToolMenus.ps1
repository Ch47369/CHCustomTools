param(
    [string]$UnityEditorPath='C:/Program Files/Unity/Hub/Editor/2022.3.10f1/Editor/Unity.exe',
    [ValidateSet('Shader','Audio','Both')][string]$Packages='Shader',
    [switch]$Tarballs,
    [ValidatePattern('^[A-Za-z0-9-]+$')][string]$RunId='CustomTools048',
    [ValidatePattern('^\d+\.\d+\.\d+$')][string]$ShaderVersion='0.4.9',
    [ValidateSet('UnityToolMenusSmoke','UnityInlineUpdateSmoke','UnityGraphInputWindowSmoke','UnityUnifiedWindowSmoke','UnityGitUpdateSmoke','UnityCustomToolsSmoke','UnityGitInstallSmoke','UnityGitHubDownloadSmoke')][string]$TestClass='UnityCustomToolsSmoke',
    [switch]$Preview
)
$ErrorActionPreference='Stop'
$menuRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$active=@(Get-CimInstance Win32_Process -Filter "Name = 'Unity.exe'" | Where-Object { $_.CommandLine -match '(?i)ASEShader[\\/]\.validation[\\/]' -and $_.CommandLine -notmatch '-adb2' })
if($active.Count){throw 'An isolated Unity is active. Finish it before this check or editing shared C#.'}
$engine=if($UnityEditorPath -match '6000'){'Unity6'}else{'2022'}
$source=if($Tarballs){'FinalTarballs'}else{'Source'}
$project=Join-Path $menuRoot ('.validation/'+$RunId+'-'+$Packages+'-'+$engine+'-'+$source)
New-Item -ItemType Directory -Force -Path ($project+'/Packages'),($project+'/ProjectSettings'),($project+'/Assets/Editor')|Out-Null
$dependencies=[ordered]@{
    'com.unity.modules.imgui'='1.0.0';'com.unity.modules.animation'='1.0.0';'com.unity.modules.audio'='1.0.0'
    'com.unity.modules.jsonserialize'='1.0.0';'com.unity.modules.particlesystem'='1.0.0'
}
if($Packages -ne 'Audio'){
    $dependencies['com.aseshader.handwritten-converter']=if($Tarballs){('file:F:/ASEShader/Releases~/com.aseshader.handwritten-converter-'+$ShaderVersion+'.tgz')}else{'file:F:/ASEShader'}
}
if($Packages -ne 'Shader'){
    $dependencies['com.audiorhythmcurves.audio-rhythm-curves']=if($Tarballs){'file:F:/AudioRhythmCurves-Git/Releases/AudioRhythmCurves-1.0.9.tgz'}else{'file:F:/AudioRhythmCurves-Git/Package'}
}
@{dependencies=$dependencies}|ConvertTo-Json -Depth 4|Set-Content -LiteralPath ($project+'/Packages/manifest.json') -Encoding utf8NoBOM
('m_EditorVersion: '+$(if($engine -eq 'Unity6'){'6000.0.80f1'}else{'2022.3.10f1'}))|Set-Content -LiteralPath ($project+'/ProjectSettings/ProjectVersion.txt') -Encoding utf8NoBOM
Copy-Item -LiteralPath ($menuRoot+'/Tests/'+$TestClass+'.cs') -Destination ($project+'/Assets/Editor/'+$TestClass+'.cs') -Force
$attempt=Join-Path $menuRoot ('.build~/'+$RunId+'/Attempts/'+[DateTimeOffset]::UtcNow.ToString('yyyyMMddHHmmssfff'))
New-Item -ItemType Directory -Force -Path $attempt|Out-Null
$log=Join-Path $attempt 'editor.log'
$method=if($Preview){'Preview'}else{'Run'}
$arguments='-projectPath "'+$project+'" -executeMethod '+$TestClass+'.'+$method+' -logFile "'+$log+'" -force-d3d11'
$process=Start-Process -FilePath $UnityEditorPath -ArgumentList $arguments -WorkingDirectory $project -WindowStyle Hidden -PassThru
$reportName=if($TestClass -eq 'UnityGitHubDownloadSmoke'){'github-download.json'}elseif($TestClass -eq 'UnityGitInstallSmoke'){'real-git-install.json'}elseif($TestClass -eq 'UnityCustomToolsSmoke'){'custom-tools.json'}elseif($TestClass -eq 'UnityGitUpdateSmoke'){'git-update.json'}elseif($TestClass -eq 'UnityUnifiedWindowSmoke'){'unified-window.json'}elseif($TestClass -eq 'UnityGraphInputWindowSmoke'){'graph-input-window.json'}else{'tool-menus-verification.json'}
[pscustomobject]@{id=$process.Id;project=$project;log=$log;output=$project+'/Artifacts/'+$reportName;startedUtc=[DateTimeOffset]::UtcNow.ToString('o')}|ConvertTo-Json|Tee-Object -FilePath ($attempt+'/launch.json')
