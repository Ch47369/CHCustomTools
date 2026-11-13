// Runs only in an isolated project. Fake future versions are displayed, never installed.
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

public static class UnityInlineUpdateSmoke
{
    [Serializable] sealed class Result
    {
        public bool success;
        public bool privateGitCheckSucceeded;
        public string unityVersion, version, source, discoveredTag, checkMessage, error;
        public string[] checks;
    }
    static readonly List<string> checks = new List<string>();
    static ASEShaderConverterWindow main;
    static ShaderPackageRelease discovered;
    static ShaderPackageManagerExtension extension;
    static VisualElement ui;
    static string uiError;
    static string checkMessage;
    static bool checkFailed;
    static int phase = -1;
    static double deadline, timeout;
    static void Check(bool ok, string message) { if (!ok) throw new Exception(message); checks.Add(message); }
    static void Log(string message, string stack, LogType type)
    {
        if (type == LogType.Error || type == LogType.Exception || type == LogType.Assert) uiError = message + "\n" + stack;
    }
    static void SetLatest(ShaderPackageRelease release)
    {
        typeof(ShaderPackageUpdater).GetProperty("Latest").GetSetMethod(true).Invoke(null, new object[] { release });
        extension.OnPackageAddedOrUpdated(ShaderPackageUpdater.Installed);
        main.Repaint();
        deadline = EditorApplication.timeSinceStartup + 1;
    }
    static void OneWindow()
    {
        var converters = Resources.FindObjectsOfTypeAll<ASEShaderConverterWindow>();
        var updates = Resources.FindObjectsOfTypeAll<ShaderPackageUpdateWindow>();
        Check(converters.Length == 1 && converters[0] == main && updates.Length == 0,
            "Update flow stays in the same converter window at phase " + phase + " (converter=" + converters.Length + ", update=" + updates.Length + ")");
    }
    public static void Run()
    {
        Application.logMessageReceived += Log;
        try
        {
            Check(EditorApplication.ExecuteMenuItem("Tools/Shader"), "Tools/Shader directly opens the converter");
            main = Resources.FindObjectsOfTypeAll<ASEShaderConverterWindow>().Single();
            ShaderPackageUpdateWindow.Open(); ShaderPackageUpdateWindow.Open();
            OneWindow();
            ShaderPackageUpdater.CheckForUpdates();
            Check(ShaderPackageUpdater.Busy, "Checking starts directly without opening another window");
            timeout = EditorApplication.timeSinceStartup + 60;
            EditorApplication.update += Tick;
        }
        catch (Exception e) { Finish(e); }
    }
    static void Tick()
    {
        try
        {
            if (uiError != null) throw new Exception(uiError);
            if (phase == -1)
            {
                if (ShaderPackageUpdater.Busy)
                {
                    if (EditorApplication.timeSinceStartup > timeout) throw new Exception("Private Git check timed out");
                    return;
                }
                checkFailed = ShaderPackageUpdater.HasError;
                checkMessage = ShaderPackageUpdater.Message;
                Check(!string.IsNullOrEmpty(checkMessage), "Actual private Git check reports its result in the main window");
                if (checkFailed) Check(!ShaderPackageUpdater.HasNewVersion, "A failed network check offers no update");
                discovered = ShaderPackageUpdater.Latest;
                OneWindow();
                extension = new ShaderPackageManagerExtension(); ui = extension.CreateExtensionUI();
                extension.OnPackageSelectionChange(ShaderPackageUpdater.Installed);
                phase = 0; SetLatest(null); return;
            }
            if (EditorApplication.timeSinceStartup < deadline) return;
            OneWindow();
            var button = ui.Q<Button>("shader-converter-install-update");
            var version = new Version(ShaderPackageUpdater.Installed.version);
            if (phase == 0)
            {
                Check(!ShaderPackageUpdater.HasNewVersion && button.style.display.value == DisplayStyle.None, "Unknown release hides the update action");
                typeof(ShaderPackageUpdater).GetProperty("HasError").GetSetMethod(true).Invoke(null, new object[] { false });
                phase = 1; SetLatest(new ShaderPackageRelease { tag = "v" + version, version = version }); return;
            }
            if (phase == 1)
            {
                Check(!ShaderPackageUpdater.HasNewVersion && button.style.display.value == DisplayStyle.None, "Equal version hides the update action");
                var future = new Version(version.Major, version.Minor, version.Build + 1);
                phase = 2; SetLatest(new ShaderPackageRelease { tag = "v" + future, version = future }); return;
            }
            if (phase == 2)
            {
                Check(ShaderPackageUpdater.HasNewVersion && ShaderPackageUpdater.CanInstall && button.style.display.value == DisplayStyle.Flex && button.text.Contains(ShaderPackageUpdater.Latest.version.ToString()), "Newer release exposes the versioned update action");
                // Simulate Unity restoring the old saved update-window type.
                EditorWindow.GetWindow<ShaderPackageUpdateWindow>().Show();
                phase = 3; deadline = EditorApplication.timeSinceStartup + 1; return;
            }
            Check(uiError == null, "Inline update states render without GUI errors");
            Finish(null);
        }
        catch (Exception e) { Finish(e); }
    }
    static void Finish(Exception error)
    {
        EditorApplication.update -= Tick;
        Application.logMessageReceived -= Log;
        if (extension != null) SetLatest(discovered);
        typeof(ShaderPackageUpdater).GetProperty("HasError").GetSetMethod(true).Invoke(null, new object[] { checkFailed });
        var package = ShaderPackageUpdater.Installed;
        Directory.CreateDirectory("Artifacts");
        File.WriteAllText("Artifacts/tool-menus-verification.json", JsonUtility.ToJson(new Result { success = error == null, unityVersion = Application.unityVersion,
            version = package == null ? null : package.version, source = package == null ? null : package.source.ToString(), discoveredTag = discovered == null ? null : discovered.tag,
            privateGitCheckSucceeded = !checkFailed && discovered != null, checkMessage = checkMessage,
            error = error == null ? null : error.ToString(), checks = checks.ToArray() }, true));
        if (main != null) main.Close();
        EditorApplication.Exit(error == null ? 0 : 1);
    }
}
