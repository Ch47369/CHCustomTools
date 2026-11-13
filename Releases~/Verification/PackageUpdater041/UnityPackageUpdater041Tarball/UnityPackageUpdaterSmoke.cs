// Copy into Assets/Editor of an authorized isolated project only.
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using ASEShaderConverter;
using ASEShaderConverter.Editor;
using UnityEditor;
using UnityEngine;
using UnityEngine.UIElements;

[InitializeOnLoad]
public static class UnityPackageUpdaterSmoke
{
    const string Resume = "ShaderConverter.UpdaterSmoke.Resume";
    static readonly List<string> checks = new List<string>();
    static string output, mode;
    static double started;
    static bool checking, installing;
    static EditorWindow host;
    static ShaderPackageManagerExtension extension;
    static VisualElement ui;
    [Serializable] public class Result
    {
        public bool success;
        public string unityVersion, mode, version, source, packageId, revision, latest, message, error;
        public string[] checks;
    }
    static UnityPackageUpdaterSmoke()
    {
        if (SessionState.GetBool(Resume, false)) EditorApplication.delayCall += ResumeInstall;
    }
    static string Argument(string name, string fallback)
    {
        var args = Environment.GetCommandLineArgs(); int i = Array.IndexOf(args,name);
        return i >= 0 && i + 1 < args.Length ? args[i + 1] : fallback;
    }
    static void Check(bool ok, string name) { if (!ok) throw new Exception(name); checks.Add(name); }
    public static void Run()
    {
        output = Argument("-updaterOutput", Path.GetFullPath("../../.build~/PackageUpdater041/Attempts/"+DateTime.UtcNow.ToString("yyyyMMddHHmmssfff")));
        mode = Argument("-updaterMode","Check"); Directory.CreateDirectory(output);
        started = EditorApplication.timeSinceStartup;
        EditorApplication.update += BeginWhenReady;
    }
    public static void Preview()
    {
        EditorApplication.delayCall += () => UnityEditor.PackageManager.UI.Window.Open(ShaderPackageUpdatePolicy.PackageName);
    }
    static void BeginWhenReady()
    {
        if (EditorApplication.isCompiling || EditorApplication.isUpdating) return;
        EditorApplication.update -= BeginWhenReady;
        try
        {
            var p = ShaderPackageUpdater.Installed;
            Check(p != null && p.version == "0.4.1", "Updater package 0.4.1 loaded");
            Check(ShaderPackageUpdater.CanCheck, "Installed source permits checking");
            Check(!ShaderPackageUpdater.CanInstall, "Install disabled until a version is discovered");
            extension = new ShaderPackageManagerExtension();
            ui = extension.CreateExtensionUI();
            Check(ui.name == "shader-converter-updates" && ui.style.display.value == DisplayStyle.None, "Unselected extension hidden");
            Check(ui.Q<Button>("shader-converter-install-update").style.display.value == DisplayStyle.None, "Update button hidden before discovery");
            extension.OnPackageSelectionChange(p);
            Check(ui.style.display.value == DisplayStyle.Flex, "Converter selection shows extension");
            Check(ShaderPackageUpdater.Busy, "Selecting converter automatically starts private Git discovery");
            Check(ui.Q<Button>("shader-converter-check-update") != null && ui.Q<Button>("shader-converter-install-update") != null, "Both update controls created");
            extension.OnPackageSelectionChange(null);
            Check(ui.style.display.value == DisplayStyle.None, "Null selection hides extension");
            var other = UnityEditor.PackageManager.PackageInfo.GetAllRegisteredPackages().FirstOrDefault(x=>x.name != p.name);
            Check(other != null, "Other package available to verify selection isolation");
            extension.OnPackageSelectionChange(other);
            Check(ui.style.display.value == DisplayStyle.None, "Other package hides extension");
            extension.OnPackageSelectionChange(p);
            extension.OnPackageRemoved(p);
            Check(ui.style.display.value == DisplayStyle.None, "Removal hides extension");
            extension.OnPackageSelectionChange(p);
            host = ScriptableObject.CreateInstance<EditorWindow>(); host.titleContent = new GUIContent("Updater validation");
            host.rootVisualElement.Add(ui); host.Show();
            ShaderPackageUpdateWindow.Open();
            Check(Resources.FindObjectsOfTypeAll<ShaderPackageUpdateWindow>().Length == 1, "Standalone update window opens");
            checking = true; started = EditorApplication.timeSinceStartup;
            EditorApplication.update += Poll;
        }
        catch (Exception e) { Finish(e); }
    }
    static void Poll()
    {
        try
        {
            if (EditorApplication.timeSinceStartup - started > 210) throw new Exception("Updater smoke timed out");
            if (checking)
            {
                if (ShaderPackageUpdater.Busy) return;
                checking = false;
                Check(!ShaderPackageUpdater.HasError, "Private Git discovery succeeds without prompting");
                Check(ShaderPackageUpdater.Latest != null, "Stable release tag discovered");
                Check(!ShaderPackageUpdater.HasNewVersion, "Actual repository has no version newer than this package");
                extension.OnPackageAddedOrUpdated(ShaderPackageUpdater.Installed);
                Check(ui.Q<Button>("shader-converter-install-update").style.display.value == DisplayStyle.None, "Update button remains hidden when current version is latest or newer");
                ShaderPackageUpdater.EnsureChecked();
                Check(!ShaderPackageUpdater.Busy, "Repeated selection reuses session result instead of querying Git again");
                // A future-tag fixture verifies presentation only; it never installs an unpublished version.
                var latest = ShaderPackageUpdater.Latest;
                var setter = typeof(ShaderPackageUpdater).GetProperty("Latest").GetSetMethod(true);
                try
                {
                    setter.Invoke(null,new object[]{new ShaderPackageRelease{tag="v0.4.2",version=new Version(0,4,2)}});
                    extension.OnPackageAddedOrUpdated(ShaderPackageUpdater.Installed);
                    Check(ShaderPackageUpdater.HasNewVersion, "Simulated future release compares newer");
                    var update = ui.Q<Button>("shader-converter-install-update");
                    Check(update.style.display.value == DisplayStyle.Flex && update.text.Contains("0.4.2") && update.enabledSelf, "Newer release alone reveals the enabled versioned update button");
                }
                finally { setter.Invoke(null,new object[]{latest}); extension.OnPackageAddedOrUpdated(ShaderPackageUpdater.Installed); }
                if (mode == "Install")
                {
                    Check(ShaderPackageUpdater.Latest.tag == "v0.4.1", "Latest published tag is v0.4.1");
                    Check(ShaderPackageUpdater.CanInstall, "Local or Tarball same-version migration enabled");
                    Check(ui.Q<Button>("shader-converter-migrate-git").text.Contains("Git"), "Separate migration button explains Git source switch");
                    Check(ui.Q<Button>("shader-converter-install-update").style.display.value == DisplayStyle.None && ui.Q<Button>("shader-converter-migrate-git").style.display.value == DisplayStyle.Flex, "Equal-version migration is separate from the hidden update button");
                    File.WriteAllLines(output+"/before-reload-checks.txt", checks);
                    SessionState.SetString(Resume+".Output",output);
                    SessionState.SetBool(Resume,true);
                    installing = true;
                    ShaderPackageUpdater.InstallLatest();
                    Check(ShaderPackageUpdater.Busy, "UPM installation started through updater");
                    EditorUtility.RequestScriptReload(); // Force an in-flight reload; identical package code may skip automatic recompilation.
                    File.WriteAllLines(output+"/before-reload-checks.txt", checks);
                    return;
                }
                var p = ShaderPackageUpdater.Installed;
                Check(!ShaderPackageUpdatePolicy.CanInstall(p.version,ShaderPackageUpdater.Latest,false), "No downgrade or equal Git update offered");
                if (p.source == UnityEditor.PackageManager.PackageSource.Git)
                {
                    Check(ShaderPackageUpdater.Repository == ShaderPackageUpdatePolicy.Repository, "Installed Git packageId is recognized");
                    Check(!ShaderPackageUpdater.CanInstall, "Current Git release install button disabled");
                }
                Finish(null);
            }
            if (installing && !ShaderPackageUpdater.Busy) VerifyInstalled();
        }
        catch (Exception e) { Finish(e); }
    }
    static void ResumeInstall()
    {
        output = SessionState.GetString(Resume+".Output", ""); mode = "Install";
        checks.Clear(); checks.AddRange(File.ReadAllLines(output+"/before-reload-checks.txt"));
        checks.Add("Test resumed after UPM assembly reload");
        started = EditorApplication.timeSinceStartup; installing = true;
        EditorApplication.update += Poll;
    }
    static void VerifyInstalled()
    {
        var p = ShaderPackageUpdater.Installed;
        Check(!ShaderPackageUpdater.HasError, "Updater confirms successful installation");
        Check(p.source == UnityEditor.PackageManager.PackageSource.Git && p.version == "0.4.1", "UPM source is Git at 0.4.1");
        Check(p.packageId == ShaderPackageUpdatePolicy.PackageName+"@"+ShaderPackageUpdatePolicy.Repository+"#v0.4.1", "Actual Git packageId matches confirmation guard");
        File.Copy("Packages/packages-lock.json",output+"/packages-lock.json",true);
        Check(File.Exists(p.resolvedPath+"/Editor/ShaderPackageUpdater.cs"), "Updated Git package contains updater source");
        Check(ShaderPackageUpdater.Message.Contains("已安装 0.4.1"), "Updater status survives domain reload and confirms version");
        Finish(null);
    }
    static void Finish(Exception error)
    {
        EditorApplication.update -= Poll; EditorApplication.update -= BeginWhenReady;
        SessionState.EraseBool(Resume); SessionState.EraseString(Resume+".Output");
        var p = ShaderPackageUpdater.Installed;
        var result = new Result { success=error==null, unityVersion=Application.unityVersion,mode=mode,
            version=p==null?null:p.version,source=p==null?null:p.source.ToString(), packageId=p==null?null:p.packageId,
            revision=p==null || p.git==null?null:p.git.revision, latest=ShaderPackageUpdater.Latest==null?null:ShaderPackageUpdater.Latest.tag,
            message=ShaderPackageUpdater.Message,error=error==null?null:error.ToString(), checks=checks.ToArray() };
        File.WriteAllText(output+"/result.json",JsonUtility.ToJson(result,true));
        if (error!=null) Debug.LogException(error);
        EditorApplication.Exit(error==null?0:1);
    }
}
