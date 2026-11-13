param([ValidateSet('Recovery','Protocol')][string]$Mode='Recovery',
    [string]$UnityEditorPath='C:/Program Files/Unity/Hub/Editor/2022.3.10f1/Editor/Unity.exe')
$ErrorActionPreference='Stop'
$inboxWorkspace=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$inboxProject=Join-Path $inboxWorkspace '.validation/Unity2022'
$inboxRunning=@(Get-CimInstance Win32_Process -Filter "Name = 'Unity.exe'" | Where-Object { $_.CommandLine -match '(?i)ASEShader[\\/]\.validation[\\/]' -and $_.CommandLine -notmatch '-adb2' })
if($inboxRunning.Count){throw 'An isolated Unity Editor is active. Do not change shared C# or reuse its project until it exits.'}
$inboxAttempt=Join-Path $inboxWorkspace ('.build~/AgentInbox037/Attempts/'+[DateTimeOffset]::UtcNow.ToString('yyyyMMddHHmmssfff')+'-'+$Mode)
New-Item -ItemType Directory -Path $inboxAttempt -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $inboxProject 'LibraryBuildEvidence') -Force | Out-Null
foreach($inboxTest in @('UnityAgentInboxRecoverySmoke.cs','UnityAgentSmoke.cs')){
    Copy-Item -LiteralPath (Join-Path $inboxWorkspace ('Tests/'+$inboxTest)) -Destination (Join-Path $inboxProject ('Assets/Editor/'+$inboxTest)) -Force
}
if($Mode -eq 'Recovery'){
    $inboxMethod='UnityAgentInboxRecoverySmoke.Run'
    [IO.File]::WriteAllText((Join-Path $inboxProject 'LibraryBuildEvidence/run-inbox-recovery-037'),'run')
} else {
    $inboxMethod='UnityAgentSmoke.Run'
    # An explicit per-run marker also starts after a startup domain reload loses -executeMethod callbacks.
    $inboxBootstrap=@'
using System;
using System.IO;
using UnityEditor;
[InitializeOnLoad]
public static class AgentProtocol037Bootstrap
{
    static AgentProtocol037Bootstrap()
    {
        if (File.Exists("LibraryBuildEvidence/run-inbox-protocol-037")) EditorApplication.update += Start;
    }
    static void Start()
    {
        if (EditorApplication.isCompiling || EditorApplication.isUpdating) return;
        EditorApplication.update -= Start;
        string marker = "LibraryBuildEvidence/run-inbox-protocol-037";
        if (!File.Exists(marker)) return;
        File.Move(marker, marker + "." + Guid.NewGuid().ToString("N") + ".started");
        UnityAgentSmoke.Run();
    }
}
'@
    [IO.File]::WriteAllText((Join-Path $inboxProject 'Assets/Editor/AgentProtocol037Bootstrap.cs'),$inboxBootstrap,[Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText((Join-Path $inboxProject 'LibraryBuildEvidence/run-inbox-protocol-037'),'run')
    Copy-Item -LiteralPath (Join-Path $inboxWorkspace 'Samples~/Handwritten/TintedTexture.shader') -Destination (Join-Path $inboxProject 'Assets/TintedTexture.shader') -Force
    foreach($inboxPrior in @('agent-inbox.json','agent-inbox-error.txt')){
        $inboxOld=Join-Path $inboxProject $inboxPrior
        if(Test-Path -LiteralPath $inboxOld){Move-Item -LiteralPath $inboxOld -Destination (Join-Path $inboxAttempt $inboxPrior)}
    }
}
$inboxLog=Join-Path $inboxAttempt 'editor.log'
$inboxArgs='-projectPath "'+$inboxProject+'" -executeMethod '+$inboxMethod+' -logFile "'+$inboxLog+'" -force-d3d11'
$inboxProcess=Start-Process -FilePath $UnityEditorPath -ArgumentList $inboxArgs -WorkingDirectory $inboxProject -WindowStyle Hidden -PassThru
[pscustomobject]@{id=$inboxProcess.Id;mode=$Mode;project=$inboxProject;log=$inboxLog;startedUtc=[DateTimeOffset]::UtcNow.ToString('o')} | ConvertTo-Json | Tee-Object -FilePath (Join-Path $inboxAttempt 'launch.json')
