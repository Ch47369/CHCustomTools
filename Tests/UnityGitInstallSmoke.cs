// Executes a real authenticated GitHub installation/upgrade in a disposable project, across domain reloads.
using System;
using System.IO;
using System.Linq;
using System.Reflection;
using UnityEditor;
using UnityEngine;

[InitializeOnLoad]
public static class UnityGitInstallSmoke
{
    const string Key = "CH.CustomTools048.RealGitInstall.";
    const BindingFlags S = BindingFlags.Static | BindingFlags.Public | BindingFlags.NonPublic;
    static Type Updater { get { return AppDomain.CurrentDomain.GetAssemblies().Select(a => a.GetType("ASEShaderConverter.Editor.ShaderPackageUpdater")).FirstOrDefault(t => t != null); } }
    static object Get(string name) { return Updater.GetProperty(name, S).GetValue(null); }
    static void Invoke(string name) { Updater.GetMethod(name, S).Invoke(null, null); }
    static UnityEditor.PackageManager.PackageInfo Installed { get { return (UnityEditor.PackageManager.PackageInfo)Get("Installed"); } }
    static UnityGitInstallSmoke() { if (SessionState.GetBool(Key + "active", false)) EditorApplication.update += Tick; }
    public static void Run()
    {
        if (SessionState.GetBool(Key + "active", false)) return;
        SessionState.SetBool(Key + "active", true); SessionState.SetInt(Key + "phase", 0);
        SessionState.SetString(Key + "start", DateTime.UtcNow.ToString("o"));
        var package = Installed; SessionState.SetString(Key + "before", package.version); SessionState.SetString(Key + "beforeSource", package.source.ToString());
        EditorApplication.update -= Tick; EditorApplication.update += Tick;
    }
    static void Tick()
    {
        try
        {
            if (DateTime.UtcNow - DateTime.Parse(SessionState.GetString(Key + "start", ""), null, System.Globalization.DateTimeStyles.RoundtripKind) > TimeSpan.FromMinutes(12))
                throw new TimeoutException("Real GitHub installation timed out; see the preserved UPM log in this isolated project.");
            if (Updater == null || EditorApplication.isCompiling || EditorApplication.isUpdating) return;
            int phase = SessionState.GetInt(Key + "phase", 0);
            if (phase == 0)
            {
                if (!(bool)Get("CanCheck")) return;
                SessionState.SetInt(Key + "phase", 1); Invoke("CheckForUpdates"); return;
            }
            if (phase == 1)
            {
                if ((bool)Get("Busy")) return;
                if ((bool)Get("HasError")) throw new Exception("Remote discovery failed: " + Get("FailureReason"));
                var release = Get("Latest"); if (release == null) throw new Exception("No stable GitHub tag was discovered.");
                string tag = (string)release.GetType().GetField("tag").GetValue(release);
                SessionState.SetString(Key + "target", tag);
                if (!(bool)Get("CanInstall")) throw new Exception("Discovered target cannot be installed from the current source/version.");
                SessionState.SetInt(Key + "phase", 2); Invoke("InstallLatest"); return;
            }
            var installed = Installed; string target = SessionState.GetString(Key + "target", "");
            if (installed != null && installed.source == UnityEditor.PackageManager.PackageSource.LocalTarball && installed.version == target.Substring(1) &&
                installed.packageId.Replace('\\', '/').Contains("CHCustomToolsCache~/") && !(bool)Get("Busy"))
            { Finish(null); return; }
            if (!(bool)Get("Busy") && (bool)Get("HasError")) throw new Exception("GitHub installation failed: " + Get("FailureReason") + "; " + Get("Message"));
        }
        catch (Exception e) { Finish(e); }
    }
    [Serializable] class Report { public bool success; public string unity, beforeVersion, beforeSource, targetTag, installedVersion, installedSource, packageId, failure; }
    static void Finish(Exception error)
    {
        EditorApplication.update -= Tick; var p = Installed; Directory.CreateDirectory("Artifacts");
        File.WriteAllText("Artifacts/real-git-install.json", JsonUtility.ToJson(new Report { success = error == null, unity = Application.unityVersion,
            beforeVersion = SessionState.GetString(Key + "before", ""), beforeSource = SessionState.GetString(Key + "beforeSource", ""),
            targetTag = SessionState.GetString(Key + "target", ""), installedVersion = p == null ? "" : p.version, installedSource = p == null ? "" : p.source.ToString(),
            packageId = p == null ? "" : p.packageId, failure = error == null ? "" : error.ToString() }, true));
        SessionState.SetBool(Key + "active", false); EditorApplication.Exit(error == null ? 0 : 1);
    }
}
