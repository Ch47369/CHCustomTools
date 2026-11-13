param(
    [string]$UnityEditorPath='C:/Program Files/Unity/Hub/Editor/2022.3.10f1/Editor/Unity.exe'
)
$ErrorActionPreference='Stop'
$upgradeRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$active=@(Get-CimInstance Win32_Process -Filter "Name = 'Unity.exe'" | Where-Object { $_.CommandLine -match '(?i)ASEShader[\\/]\.validation[\\/]' -and $_.CommandLine -notmatch '-adb2' })
if($active.Count){throw 'Finish the active isolated Unity before starting another release check.'}
$engine=if($UnityEditorPath -match '6000'){'Unity6'}else{'2022'}
$targetVersion=(Get-Content -LiteralPath (Join-Path $upgradeRoot 'package.json') -Raw | ConvertFrom-Json).version
$upgradeRun='GitHubReleaseUpgrade'+$targetVersion.Replace('.','')
$fixture=Join-Path $upgradeRoot ('.validation/'+$upgradeRun+'-'+$engine+'-Fixture')
$project=Join-Path $upgradeRoot ('.validation/'+$upgradeRun+'-'+$engine+'-Project')
if(Test-Path -LiteralPath $fixture){throw 'This fixture already exists. Preserve earlier attempts and use a fresh run directory.'}
New-Item -ItemType Directory -Force -Path $fixture,($project+'/Packages'),($project+'/ProjectSettings'),($project+'/Assets/Editor')|Out-Null
$baseline=Join-Path $upgradeRoot 'Releases~/com.aseshader.handwritten-converter-0.4.7.tgz'
if((Get-FileHash -LiteralPath $baseline -Algorithm SHA256).Hash.ToLowerInvariant() -ne '8f95611f89a7c75398a05f46d0ff08b8f86f027885abbecac5a6d795e01cadc9'){throw 'Baseline archive changed.'}
& tar -xzf $baseline -C $fixture
if($LASTEXITCODE -ne 0){throw 'Could not extract the baseline package.'}
$package=Join-Path $fixture 'package'
# Explicit test fixture: preserve real 0.4.7 content/version, backport only the candidate updater.
# The downloaded target is the actual published release. This is not an unmodified old-updater test.
$backport=@('Editor/ShaderPackageUpdater.cs','Editor/ShaderPackageUpdateUI.cs','Editor/ShaderGitClient.cs','Editor/ShaderGitHubClient.cs','Editor/ShaderGitHubClient.cs.meta','Runtime/ShaderPackageUpdatePolicy.cs')
foreach($relative in $backport){Copy-Item -LiteralPath (Join-Path $upgradeRoot $relative) -Destination (Join-Path $package $relative)}
$meta=Get-Content -LiteralPath ($package+'/package.json') -Raw|ConvertFrom-Json
$dependencies=[ordered]@{}
foreach($module in @('imgui','animation','audio','jsonserialize','particlesystem','unitywebrequest')){$dependencies['com.unity.modules.'+$module]='1.0.0'}
$meta|Add-Member -NotePropertyName dependencies -NotePropertyValue $dependencies -Force
$meta|ConvertTo-Json -Depth 5|Set-Content -LiteralPath ($package+'/package.json') -Encoding utf8NoBOM
$dependencies['com.aseshader.handwritten-converter']='file:'+ $package.Replace('\','/')
@{dependencies=$dependencies}|ConvertTo-Json -Depth 5|Set-Content -LiteralPath ($project+'/Packages/manifest.json') -Encoding utf8NoBOM
('m_EditorVersion: '+$(if($engine -eq 'Unity6'){'6000.0.80f1'}else{'2022.3.10f1'}))|Set-Content -LiteralPath ($project+'/ProjectSettings/ProjectVersion.txt') -Encoding utf8NoBOM
Copy-Item -LiteralPath ($upgradeRoot+'/Tests/UnityGitInstallSmoke.cs') -Destination ($project+'/Assets/Editor/UnityGitInstallSmoke.cs')
$attempt=Join-Path $upgradeRoot ('.build~/'+$upgradeRun+'/Attempts/'+[DateTimeOffset]::UtcNow.ToString('yyyyMMddHHmmssfff'))
New-Item -ItemType Directory -Force -Path $attempt|Out-Null
$backport|ForEach-Object {[pscustomobject]@{path=$_;sha256=(Get-FileHash -LiteralPath (Join-Path $package $_) -Algorithm SHA256).Hash.ToLowerInvariant()}}|ConvertTo-Json|Set-Content -LiteralPath ($attempt+'/backported-updater.json') -Encoding utf8NoBOM
$log=Join-Path $attempt 'editor.log'
$arguments='-projectPath "'+$project+'" -executeMethod UnityGitInstallSmoke.Run -logFile "'+$log+'" -force-d3d11'
$process=Start-Process -FilePath $UnityEditorPath -ArgumentList $arguments -WorkingDirectory $project -WindowStyle Hidden -PassThru
[pscustomobject]@{id=$process.Id;project=$project;log=$log;output=$project+'/Artifacts/real-git-install.json';baseline='0.4.7 with explicitly backported candidate updater';startedUtc=[DateTimeOffset]::UtcNow.ToString('o')}|ConvertTo-Json|Tee-Object -FilePath ($attempt+'/launch.json')
