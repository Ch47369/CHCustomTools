param([string[]]$ExcludeRelativePath = @())
$ErrorActionPreference = 'Stop'
$workspace = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$metadata = Get-Content -LiteralPath (Join-Path $workspace 'package.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$version = $metadata.version
if ($version -notmatch '^\d+\.\d+\.\d+$') { throw 'Package version must be a stable semantic version.' }
$output = Join-Path $workspace 'Releases~'
$staging = Join-Path $workspace ('.build~/delivery-' + [Guid]::NewGuid().ToString('N'))
$package = Join-Path $staging 'package'
New-Item -ItemType Directory -Path $package -Force | Out-Null
New-Item -ItemType Directory -Path $output -Force | Out-Null
# An explicit allowlist keeps local ASE copies, Unity projects, and build caches out.
$include = @('Runtime','Editor','Tests','Documentation~','Samples~','Tools~','README.md','AGENTS.md','package.json','ASEShaderConverter.Core.csproj','Directory.Build.props','.nuget.empty.config')
function Copy-ReleaseItem([string]$Source, [string]$Destination) {
    $item = Get-Item -LiteralPath $Source -Force
    $releaseRelativePath = $item.FullName.Substring($workspace.Length + 1).Replace('\','/')
    if ($ExcludeRelativePath -contains $releaseRelativePath) { return }
    if ($item.Name -match '^(AmplifyShaderEditor|\.validation|\.build~|bin~?|obj~?|__pycache__)(\.meta)?$' -or $item.Extension -eq '.pyc') { return }
    if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw "Release inputs cannot be links: $Source" }
    if ($item.PSIsContainer) {
        $target = Join-Path $Destination $item.Name
        New-Item -ItemType Directory -Path $target -Force | Out-Null
        foreach ($child in Get-ChildItem -LiteralPath $Source -Force) {
            Copy-ReleaseItem $child.FullName $target
        }
    } else {
        Copy-Item -LiteralPath $Source -Destination $Destination
    }
}
foreach ($relative in $include) {
    $source = Join-Path $workspace $relative
    if (!(Test-Path -LiteralPath $source)) { throw "Missing release input: $relative" }
    Copy-ReleaseItem $source $package
    if (Test-Path -LiteralPath ($source + '.meta')) { Copy-Item -LiteralPath ($source + '.meta') -Destination $package }
}
$files = Get-ChildItem -LiteralPath $package -Recurse -File
foreach ($file in $files) {
    $relative = $file.FullName.Substring($package.Length + 1).Replace('\','/')
    if ($relative -match '(^|/)(AmplifyShaderEditor|\.validation|\.build~|bin~?|obj~?|__pycache__)(\.meta)?(/|$)' -or $file.Extension -eq '.pyc') { throw "Forbidden release input: $relative" }
}
$tgz = Join-Path $output ($metadata.name + '-' + $version + '.tgz')
$zipPrefix = if ($metadata.displayName -eq 'CH自定义工具集') { 'CHCustomTools' } elseif ($metadata.displayName -eq 'Shader转换器') { 'ShaderConverter' } else { 'ASEShaderConverter' }
$zip = Join-Path $output ($zipPrefix + '-' + $version + '.zip')
& tar -czf $tgz -C $staging package
if ($LASTEXITCODE -ne 0) { throw 'Could not create Unity Package Manager tarball.' }
Add-Type -AssemblyName System.IO.Compression.FileSystem
if (Test-Path -LiteralPath $zip) { [IO.File]::Delete($zip) }
[IO.Compression.ZipFile]::CreateFromDirectory($staging, $zip)
$checksums = @($tgz,$zip) | ForEach-Object {
    $info = Get-Item -LiteralPath $_
    [pscustomobject]@{file=$info.Name;bytes=$info.Length;sha256=(Get-FileHash -LiteralPath $_ -Algorithm SHA256).Hash.ToLowerInvariant()}
}
$checksums | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $output 'checksums.json') -Encoding UTF8
$checksums | Format-Table -AutoSize
