param(
    [Parameter(Mandatory=$true)][string]$AseSource,
    [ValidatePattern('^[A-Za-z0-9_-]+$')][string]$ProjectName = 'Unity2022',
    [ValidatePattern('^[0-9]+\.[0-9]+\.[0-9]+[a-z][0-9]+$')][string]$UnityVersion = '2022.3.10f1'
)
$ErrorActionPreference = 'Stop'
$workspace = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$project = Join-Path $workspace ('.validation/' + $ProjectName)
$destination = Join-Path $project 'Assets/AmplifyShaderEditor'
New-Item -ItemType Directory -Force -Path (Join-Path $project 'Assets/Editor'),(Join-Path $project 'Packages'),(Join-Path $project 'ProjectSettings') | Out-Null
if (!(Test-Path -LiteralPath $destination)) { Copy-Item -LiteralPath $AseSource -Destination $destination -Recurse }
$manifest = @{ dependencies = @{ 'com.aseshader.handwritten-converter' = ('file:' + $workspace.Replace('\','/')) } }
$utf8 = New-Object Text.UTF8Encoding($false)
[IO.File]::WriteAllText((Join-Path $project 'Packages/manifest.json'), ($manifest | ConvertTo-Json -Depth 4), $utf8)
[IO.File]::WriteAllText((Join-Path $project 'ProjectSettings/ProjectVersion.txt'), "m_EditorVersion: $UnityVersion`n", $utf8)
Copy-Item -LiteralPath (Join-Path $workspace 'Tests/UnitySmoke.cs') -Destination (Join-Path $project 'Assets/Editor/UnitySmoke.cs') -Force
Copy-Item -LiteralPath (Join-Path $workspace 'Tests/UnitySrpSmoke.cs') -Destination (Join-Path $project 'Assets/Editor/UnitySrpSmoke.cs') -Force
Copy-Item -LiteralPath (Join-Path $workspace 'Tests/UnityAgentSmoke.cs') -Destination (Join-Path $project 'Assets/Editor/UnityAgentSmoke.cs') -Force
Copy-Item -LiteralPath (Join-Path $workspace 'Tests/UnityWindowSmoke.cs') -Destination (Join-Path $project 'Assets/Editor/UnityWindowSmoke.cs') -Force
Copy-Item -LiteralPath (Join-Path $workspace 'Tests/UnityPresentationSmoke.cs') -Destination (Join-Path $project 'Assets/Editor/UnityPresentationSmoke.cs') -Force
Copy-Item -LiteralPath (Join-Path $workspace 'Tests/UnityNormalSmoke.cs') -Destination (Join-Path $project 'Assets/Editor/UnityNormalSmoke.cs') -Force
Copy-Item -LiteralPath (Join-Path $workspace 'Samples~/Handwritten/TintedTexture.shader') -Destination (Join-Path $project 'Assets/TintedTexture.shader') -Force
Write-Output $project
