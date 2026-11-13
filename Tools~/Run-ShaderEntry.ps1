param(
    [string]$UnityEditorPath='C:/Program Files/Unity/Hub/Editor/2022.3.10f1/Editor/Unity.exe',
    [switch]$Tarballs
)
& (Join-Path $PSScriptRoot 'Run-ToolMenus.ps1') -Packages Shader -RunId ShaderEntry044 -ShaderVersion 0.4.4 -Tarballs:$Tarballs -UnityEditorPath $UnityEditorPath
