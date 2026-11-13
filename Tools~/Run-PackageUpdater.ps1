param(
    [string]$UnityEditorPath='C:/Program Files/Unity/Hub/Editor/2022.3.10f1/Editor/Unity.exe',
    [string]$ProjectName='UnityPackageUpdater041',
    [ValidateSet('Check','Install')][string]$Mode='Check'
)
$ErrorActionPreference='Stop'
$updaterWorkspace=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
if($ProjectName -notmatch '^UnityPackageUpdater041[A-Za-z0-9]*$'){throw 'Only dedicated updater validation projects are allowed.'}
$updaterProject=Join-Path $updaterWorkspace ('.validation/'+$ProjectName)
$updaterRunning=@(Get-CimInstance Win32_Process -Filter "Name = 'Unity.exe'" | Where-Object { $_.CommandLine -match '(?i)ASEShader[\\/]\.validation[\\/]' -and $_.CommandLine -notmatch '-adb2' })
if($updaterRunning.Count){throw 'An isolated Unity Editor is active. Do not change shared C# or reuse its project until it exits.'}
if(!(Test-Path -LiteralPath ($updaterProject+'/Packages/manifest.json'))){
    New-Item -ItemType Directory -Force -Path ($updaterProject+'/Packages'),($updaterProject+'/ProjectSettings') | Out-Null
    '{"dependencies":{"com.aseshader.handwritten-converter":"file:F:/ASEShader","com.unity.modules.imgui":"1.0.0"}}' | Set-Content -LiteralPath ($updaterProject+'/Packages/manifest.json') -Encoding UTF8
    'm_EditorVersion: 2022.3.10f1' | Set-Content -LiteralPath ($updaterProject+'/ProjectSettings/ProjectVersion.txt') -Encoding UTF8
}
New-Item -ItemType Directory -Force -Path ($updaterProject+'/Assets/Editor') | Out-Null
Copy-Item -LiteralPath ($updaterWorkspace+'/Tests/UnityPackageUpdaterSmoke.cs') -Destination ($updaterProject+'/Assets/Editor/UnityPackageUpdaterSmoke.cs') -Force
$updaterAttempt=Join-Path $updaterWorkspace ('.build~/PackageUpdater041/Attempts/'+[DateTimeOffset]::UtcNow.ToString('yyyyMMddHHmmssfff'))
New-Item -ItemType Directory -Path $updaterAttempt -Force | Out-Null
$updaterLog=Join-Path $updaterAttempt 'editor.log'
$updaterArgs='-batchmode -projectPath "'+$updaterProject+'" -executeMethod UnityPackageUpdaterSmoke.Run -updaterMode '+$Mode+' -updaterOutput "'+$updaterAttempt+'" -logFile "'+$updaterLog+'" -force-d3d11'
$updaterProcess=Start-Process -FilePath $UnityEditorPath -ArgumentList $updaterArgs -WorkingDirectory $updaterProject -WindowStyle Hidden -PassThru
[pscustomobject]@{id=$updaterProcess.Id;project=$updaterProject;mode=$Mode;log=$updaterLog;output=$updaterAttempt;startedUtc=[DateTimeOffset]::UtcNow.ToString('o')} | ConvertTo-Json | Tee-Object -FilePath ($updaterAttempt+'/launch.json')
