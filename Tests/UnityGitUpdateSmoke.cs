using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using ASEShaderConverter;
using ASEShaderConverter.Editor;
using UnityEditor;
using UnityEngine;
using UnityEngine.UIElements;

// Actual authenticated tag discovery plus safe synthetic failure states. Never installs a fake version or triggers login.
public static class UnityGitUpdateSmoke
{
    const BindingFlags Static = BindingFlags.Static | BindingFlags.Public | BindingFlags.NonPublic;
    static readonly List<string> checks = new List<string>();
    static ASEShaderConverterWindow main;
    static ShaderPackageManagerExtension extension;
    static VisualElement ui;
    static string guiError, actualMessage, actualFailure, actualTag;
    static bool actualSuccess;
    static double timeout, deadline;
    static int phase = -1;
    static ShaderPackageRelease release;
    static object failure;
    static void Check(bool ok, string name) { if (!ok) throw new Exception(name); checks.Add(name); }
    static void Log(string message, string stack, LogType type) { if (type == LogType.Error || type == LogType.Exception || type == LogType.Assert) guiError = message + "\n" + stack; }
    static void OneWindow()
    {
        var windows = Resources.FindObjectsOfTypeAll<EditorWindow>().Where(w => w.GetType().Assembly == typeof(ASEShaderConverterWindow).Assembly).ToArray();
        Check(windows.Length == 1 && windows[0] == main, "Version discovery and failure states remain in one main window (phase " + phase + ")");
    }
    public static void Run()
    {
        Application.logMessageReceived += Log;
        try
        {
            Check(EditorApplication.ExecuteMenuItem("Tools/Shader"), "Tools/Shader opens the converter");
            main = Resources.FindObjectsOfTypeAll<ASEShaderConverterWindow>().Single(); ASEShaderConverterWindow.OpenUpdates();
            extension = new ShaderPackageManagerExtension(); ui = extension.CreateExtensionUI(); extension.OnPackageSelectionChange(ShaderPackageUpdater.Installed);
            ShaderPackageUpdater.CheckForUpdates(); timeout = EditorApplication.timeSinceStartup + 55;
            EditorApplication.update += Tick;
        }
        catch (Exception e) { Finish(e); }
    }
    static void Tick()
    {
        try
        {
            if (guiError != null) throw new Exception(guiError);
            if (phase == -1)
            {
                if (ShaderPackageUpdater.Busy) { if (EditorApplication.timeSinceStartup > timeout) throw new TimeoutException("Git discovery exceeded its bounded timeout"); return; }
                actualSuccess = !ShaderPackageUpdater.HasError && ShaderPackageUpdater.Latest != null;
                actualMessage = ShaderPackageUpdater.Message; actualFailure = ShaderPackageUpdater.FailureReason;
                release = ShaderPackageUpdater.Latest; actualTag = release == null ? "" : release.tag;
                failure = typeof(ShaderPackageUpdater).GetProperty("LastFailure", Static).GetValue(null);
                Check(actualSuccess || new[] { "Network", "Timeout", "Authentication", "AccessDenied", "GitUnavailable", "Unknown" }.Contains(actualFailure), "Actual private Git result has either a release or a specific safe failure category");
                Check(!string.IsNullOrEmpty(actualMessage), "Actual Git discovery reports its result inside Settings / Updates");
                phase = 0; SetFailure("Network"); return;
            }
            if (EditorApplication.timeSinceStartup < deadline) return;
            OneWindow();
            var auth = ui.Q<Button>("shader-converter-authenticate");
            Check(auth != null, "Package Manager authentication action is available to the UI policy");
            if (phase == 0)
            {
                Check(!ShaderPackageUpdater.CanAuthenticate && auth.style.display.value == DisplayStyle.None, "Network errors do not request GitHub login");
                Check(!ShaderPackageUpdater.HasNewVersion, "Failed discovery does not invent an update");
                phase = 1; SetFailure("Authentication"); return;
            }
            if (phase == 1)
            {
                Check(ShaderPackageUpdater.CanAuthenticate && auth.style.display.value == DisplayStyle.Flex, "An actual credential failure offers explicit GitHub sign-in and retry");
                phase = 2; SetFailure("GitUnavailable"); return;
            }
            if (phase == 2)
            {
                Check(!ShaderPackageUpdater.CanAuthenticate && auth.style.display.value == DisplayStyle.None, "Missing Git is distinct from missing credentials");
                phase = 3; SetFailure("AccessDenied"); return;
            }
            Check(ShaderPackageUpdater.CanAuthenticate, "Private repository permission denial offers account selection for HTTPS");
            Check(guiError == null, "All Git failure states render without errors or extra plugin windows");
            Finish(null);
        }
        catch (Exception e) { Finish(e); }
    }
    static void SetFailure(string name)
    {
        var property = typeof(ShaderPackageUpdater).GetProperty("LastFailure", Static);
        object value = Enum.Parse(property.PropertyType, name); property.GetSetMethod(true).Invoke(null, new[] { value });
        typeof(ShaderPackageUpdater).GetProperty("Latest").GetSetMethod(true).Invoke(null, new object[] { null });
        object message = typeof(ShaderPackageUpdater).GetMethod("FailureMessage", Static).Invoke(null, new[] { value });
        typeof(ShaderPackageUpdater).GetMethod("SetMessage", Static).Invoke(null, new[] { message, (object)true });
        extension.OnPackageAddedOrUpdated(ShaderPackageUpdater.Installed); main.Repaint(); deadline = EditorApplication.timeSinceStartup + .6;
    }
    static void Finish(Exception error)
    {
        EditorApplication.update -= Tick; Application.logMessageReceived -= Log;
        if (failure != null) typeof(ShaderPackageUpdater).GetProperty("LastFailure", Static).GetSetMethod(true).Invoke(null, new[] { failure });
        typeof(ShaderPackageUpdater).GetProperty("Latest").GetSetMethod(true).Invoke(null, new object[] { release });
        var package = ShaderPackageUpdater.Installed; Directory.CreateDirectory("Artifacts");
        File.WriteAllText("Artifacts/git-update.json", JsonUtility.ToJson(new Result { success = error == null, privateGitCheckSucceeded = actualSuccess, unityVersion = Application.unityVersion,
            version = package == null ? "" : package.version, source = package == null ? "" : package.source.ToString(), discoveredTag = actualTag, checkMessage = actualMessage,
            failureReason = actualFailure, checks = checks.ToArray(), error = error == null ? "" : error.ToString() }, true));
        if (main != null) main.Close(); EditorApplication.Exit(error == null ? 0 : 1);
    }
    [Serializable] sealed class Result { public bool success, privateGitCheckSucceeded; public string unityVersion, version, source, discoveredTag, checkMessage, failureReason, error; public string[] checks; }
}
