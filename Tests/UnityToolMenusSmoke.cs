// Run in an isolated project with either or both CH packages installed.
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using UnityEditor;
using UnityEditor.PackageManager;
using UnityEngine;

public static class UnityToolMenusSmoke
{
    const string Key = "CH.CustomTools.Language";
    const BindingFlags Static = BindingFlags.Static | BindingFlags.Public | BindingFlags.NonPublic;
    [Serializable] sealed class Author { public string name; }
    [Serializable] sealed class Manifest { public Author author; public string version; }
    [Serializable] sealed class Result
    {
        public bool success;
        public string unityVersion, error;
        public string[] packages, checks;
    }
    public static void Run()
    {
        var checks = new List<string>();
        var packages = new List<string>();
        var languages = new List<Type>();
        bool existed = EditorPrefs.HasKey(Key);
        string saved = EditorPrefs.GetString(Key, "");
        Exception error = null;
        string uiError = null;
        Application.LogCallback log = (message, stack, type) => { if (type == LogType.Exception || type == LogType.Error || type == LogType.Assert) uiError = message + "\n" + stack; };
        Application.logMessageReceived += log;
        Action<bool, string> check = (ok, name) => { if (!ok) throw new Exception(name); checks.Add(name); };
        try
        {
            var assemblies = AppDomain.CurrentDomain.GetAssemblies().Where(a => a.GetName().Name == "ASEShaderConverter.Editor" || a.GetName().Name == "AudioRhythmCurves.Editor").ToArray();
            check(assemblies.Length > 0, "At least one CH package is installed");
            var expected = new List<string>();
            var open = new List<string>();
            foreach (var assembly in assemblies)
            {
                bool shader = assembly.GetName().Name == "ASEShaderConverter.Editor";
                var p = UnityEditor.PackageManager.PackageInfo.FindForAssembly(assembly);
                var manifest = JsonUtility.FromJson<Manifest>(File.ReadAllText(Path.Combine(p.resolvedPath, "package.json")));
                check(manifest.author != null && manifest.author.name == "CH", p.name + ": exact author is CH");
                packages.Add(p.name + "@" + manifest.version + " (" + p.source + ")");
                var language = assembly.GetType((shader ? "ASEShaderConverter.Editor" : "AudioRhythmCurves") + ".CHToolLanguage", true);
                languages.Add(language);
                check(((string[])language.GetField("Choices", Static).GetValue(null)).SequenceEqual(new[] { "中文", "English" }), p.name + ": exactly two language choices");
                if (shader)
                {
                    if (new Version(manifest.version) >= new Version(0, 4, 4))
                    {
                        expected.Add("Tools/Shader");
                        open.Add("Tools/Shader");
                    }
                    else
                    {
                        expected.AddRange(new[] { "Tools/Shader/打开转换器", "Tools/Shader/ASE 着色器库", "Tools/Shader/检查插件更新", "Tools/Shader/打开 Agent 接入目录" });
                        open.AddRange(new[] { "Tools/Shader/打开转换器", "Tools/Shader/ASE 着色器库" });
                    }
                }
                else
                {
                    expected.AddRange(new[] { "Tools/VFX/音频节奏曲线", "Tools/VFX/特效资源整理" });
                    open.AddRange(new[] { "Tools/VFX/音频节奏曲线", "Tools/VFX/特效资源整理" });
                }
            }
            var menus = assemblies.SelectMany(a => a.GetTypes()).SelectMany(t => t.GetMethods(Static))
                .SelectMany(m => m.GetCustomAttributes(typeof(MenuItem), false).Cast<MenuItem>())
                .Where(m => !m.validate && m.menuItem.StartsWith("Tools/", StringComparison.Ordinal)).Select(m => m.menuItem).ToArray();
            check(menus.OrderBy(x => x, StringComparer.Ordinal).SequenceEqual(expected.OrderBy(x => x, StringComparer.Ordinal)), "Every top Tools entry belongs to the exact unified hierarchy");
            check(menus.Distinct().Count() == menus.Length && !menus.Any(x => x.StartsWith("Tools/CH自定义工具集/", StringComparison.Ordinal)), "Only Shader / VFX feature menus are registered; no extra settings branch or duplicate paths");
            foreach (var path in open) check(EditorApplication.ExecuteMenuItem(path), "Native menu opens: " + path);
            check(languages.All(t => t.GetMethod("DrawLanguageSelector", Static) != null) && !Resources.FindObjectsOfTypeAll<EditorWindow>().Any(w => w.GetType().Name == "CHToolSettingsWindow"), "Each plugin has a built-in language selector with no separate settings window");
            foreach (bool chinese in new[] { true, false })
            {
                languages[0].GetMethod("Set", Static).Invoke(null, new object[] { chinese });
                foreach (var language in languages) language.GetMethod("Refresh", Static).Invoke(null, null);
                check(languages.All(t => (bool)t.GetProperty("IsChinese", Static).GetValue(null) == chinese), "All installed tools share " + (chinese ? "Chinese" : "English"));
            }
            languages[0].GetMethod("Reset", Static).Invoke(null, null);
            foreach (var language in languages) language.GetMethod("Refresh", Static).Invoke(null, null);
            check(!EditorPrefs.HasKey(Key) && languages.All(t => (bool)t.GetProperty("IsChinese", Static).GetValue(null) == (bool)t.GetMethod("EditorIsChinese", Static).Invoke(null, null)), "Reset returns all tools to actual Unity Editor language");
        }
        catch (Exception e) { error = e; }
        Action<Exception> finish = failure =>
        {
            Application.logMessageReceived -= log;
            if (failure == null && uiError != null) failure = new Exception("Window reported an error: " + uiError);
            if (existed) EditorPrefs.SetString(Key, saved); else EditorPrefs.DeleteKey(Key);
            foreach (var language in languages) language.GetMethod("Refresh", Static).Invoke(null, null);
            foreach (var window in Resources.FindObjectsOfTypeAll<EditorWindow>().Where(w => w.GetType().Name == "CHToolSettingsWindow" || w.GetType().Assembly.GetName().Name == "ASEShaderConverter.Editor" || w.GetType().Assembly.GetName().Name == "AudioRhythmCurves.Editor")) window.Close();
            Directory.CreateDirectory("Artifacts");
            File.WriteAllText("Artifacts/tool-menus-verification.json", JsonUtility.ToJson(new Result { success = failure == null, unityVersion = Application.unityVersion, packages = packages.ToArray(), checks = checks.ToArray(), error = failure == null ? null : failure.ToString() }, true));
            EditorApplication.Exit(failure == null ? 0 : 1);
        };
        if (error != null) { finish(error); return; }
        int stage = 0;
        double deadline = EditorApplication.timeSinceStartup + 2;
        languages[0].GetMethod("Set", Static).Invoke(null, new object[] { false });
        foreach (var language in languages) language.GetMethod("Refresh", Static).Invoke(null, null);
        EditorApplication.CallbackFunction tick = null;
        tick = () =>
        {
            if (EditorApplication.timeSinceStartup < deadline) return;
            try
            {
                var titles = new Dictionary<string, string[]> {
                    {"ASEShaderConverterWindow", new[]{"Shader Converter", "Shader转换器"}},
                    {"ShaderLibraryWindow", new[]{"ASE Shader Library", "ASE 着色器库"}},
                    {"RhythmCurveWindow", new[]{"Audio Rhythm · Curves", "音频节奏 · 曲线"}},
                    {"VfxResourceOrganizerWindow", new[]{"VFX Resource Organizer", "特效资源整理"}}
                };
                foreach (var window in Resources.FindObjectsOfTypeAll<EditorWindow>().Where(w => titles.ContainsKey(w.GetType().Name)))
                    check(window.titleContent.text == titles[window.GetType().Name][stage], "Rendered window follows language: " + titles[window.GetType().Name][stage]);
                if (stage++ == 0)
                {
                    languages[0].GetMethod("Set", Static).Invoke(null, new object[] { true });
                    foreach (var language in languages) language.GetMethod("Refresh", Static).Invoke(null, null);
                    foreach (var window in Resources.FindObjectsOfTypeAll<EditorWindow>()) window.Repaint();
                    deadline = EditorApplication.timeSinceStartup + 2;
                    return;
                }
                EditorApplication.update -= tick;
                finish(null);
            }
            catch (Exception e) { EditorApplication.update -= tick; finish(e); }
        };
        EditorApplication.update += tick;
    }
}
