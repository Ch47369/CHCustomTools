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
$baseline=Join-Path $upgradeRoot 'Releases~/com.aseshader.handwritten-converter-0.5.0.tgz'
if((Get-FileHash -LiteralPath $baseline -Algorithm SHA256).Hash.ToLowerInvariant() -ne 'f94c7a874cca9a2c8be0f69b3fe37232aae9a36bf1d1c5f76d39f517b022230d'){throw 'Baseline archive changed.'}
& tar -xzf $baseline -C $fixture
if($LASTEXITCODE -ne 0){throw 'Could not extract the baseline package.'}
$package=Join-Path $fixture 'package'
# The baseline is the exact published 0.5.0 package. No candidate source is backported.
$meta=Get-Content -LiteralPath ($package+'/package.json') -Raw|ConvertFrom-Json
$dependencies=[ordered]@{}
foreach($property in $meta.dependencies.PSObject.Properties){$dependencies[$property.Name]=$property.Value}
$dependencies['com.aseshader.handwritten-converter']='file:'+ $package.Replace('\','/')
@{dependencies=$dependencies}|ConvertTo-Json -Depth 5|Set-Content -LiteralPath ($project+'/Packages/manifest.json') -Encoding utf8NoBOM
('m_EditorVersion: '+$(if($engine -eq 'Unity6'){'6000.0.80f1'}else{'2022.3.10f1'}))|Set-Content -LiteralPath ($project+'/ProjectSettings/ProjectVersion.txt') -Encoding utf8NoBOM
Copy-Item -LiteralPath ($upgradeRoot+'/Tests/UnityGitInstallSmoke.cs') -Destination ($project+'/Assets/Editor/UnityGitInstallSmoke.cs')
$attempt=Join-Path $upgradeRoot ('.build~/'+$upgradeRun+'/Attempts/'+[DateTimeOffset]::UtcNow.ToString('yyyyMMddHHmmssfff'))
New-Item -ItemType Directory -Force -Path $attempt|Out-Null
@{baseline='0.5.0';unmodified=$true;sha256=(Get-FileHash -LiteralPath $baseline -Algorithm SHA256).Hash.ToLowerInvariant()}|ConvertTo-Json|Set-Content -LiteralPath ($attempt+'/baseline.json') -Encoding utf8NoBOM
$log=Join-Path $attempt 'editor.log'
$arguments='-projectPath "'+$project+'" -executeMethod UnityGitInstallSmoke.Run -logFile "'+$log+'" -force-d3d11'
$process=Start-Process -FilePath $UnityEditorPath -ArgumentList $arguments -WorkingDirectory $project -WindowStyle Hidden -PassThru
[pscustomobject]@{id=$process.Id;project=$project;log=$log;output=$project+'/Artifacts/real-git-install.json';baseline='0.5.0 unmodified published package';startedUtc=[DateTimeOffset]::UtcNow.ToString('o')}|ConvertTo-Json|Tee-Object -FilePath ($attempt+'/launch.json')
