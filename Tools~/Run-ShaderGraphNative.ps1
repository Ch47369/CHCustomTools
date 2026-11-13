param([string]$UnityEditorPath='C:/Program Files/Unity/Hub/Editor/2022.3.10f1/Editor/Unity.exe')
$ErrorActionPreference='Stop'
$graphWorkspace=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$graphProject=Join-Path $graphWorkspace '.validation/UnityURP'
$graphRunning=@(Get-CimInstance Win32_Process -Filter "Name = 'Unity.exe'" | Where-Object { $_.CommandLine -match '(?i)ASEShader[\\/]\.validation[\\/]' -and $_.CommandLine -notmatch '-adb2' })
if($graphRunning.Count){throw 'An isolated Unity Editor is active. Do not change shared C# or reuse its project until it exits.'}
$graphAttempt=Join-Path $graphWorkspace ('.build~/GraphInterop040/Launches/'+[DateTimeOffset]::UtcNow.ToString('yyyyMMddHHmmssfff'))
New-Item -ItemType Directory -Path $graphAttempt -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $graphWorkspace 'Tests/UnityShaderGraphNativeSmoke.cs') -Destination (Join-Path $graphProject 'Assets/Editor/UnityShaderGraphNativeSmoke.cs') -Force
$graphLog=Join-Path $graphAttempt 'editor.log'
$graphArgs='-batchmode -projectPath "'+$graphProject+'" -executeMethod UnityShaderGraphNativeSmoke.Run -logFile "'+$graphLog+'" -force-d3d11'
$graphProcess=Start-Process -FilePath $UnityEditorPath -ArgumentList $graphArgs -WorkingDirectory $graphProject -WindowStyle Hidden -PassThru
[pscustomobject]@{id=$graphProcess.Id;project=$graphProject;log=$graphLog;startedUtc=[DateTimeOffset]::UtcNow.ToString('o')} | ConvertTo-Json | Tee-Object -FilePath (Join-Path $graphAttempt 'launch.json')
