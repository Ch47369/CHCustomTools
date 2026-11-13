// Exercises the real IMGUI window in a task-owned non-batch Editor. No graphs are generated.
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using ASEShaderConverter;
using ASEShaderConverter.Editor;
using UnityEditor;
using UnityEngine;

public static class UnityUnifiedWindowSmoke
{
    const BindingFlags Instance = BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public;
    const BindingFlags Static = BindingFlags.Static | BindingFlags.NonPublic | BindingFlags.Public;
    const string LanguageKey = "CH.CustomTools.Language";
    static readonly List<string> checks = new List<string>();
    static ASEShaderConverterWindow main;
    static object report;
    static Type language;
    static bool preview, savedLanguageExists;
    static string savedLanguage, guiError, outputFolder;
    static int phase;
    static double deadline, timeout;
    static ShaderPackageRelease latest;
    static object Field(string name) { return typeof(ASEShaderConverterWindow).GetField(name, Instance).GetValue(main); }
    static void Set(string name, object value) { typeof(ASEShaderConverterWindow).GetField(name, Instance).SetValue(main, value); }
    static void Invoke(string name) { typeof(ASEShaderConverterWindow).GetMethod(name, Instance).Invoke(main, null); }
    static object Library { get { return Field("library"); } }
    static object LibraryField(string name) { return Library.GetType().GetField(name, Instance).GetValue(Library); }
    static void LibrarySet(string name, object value) { Library.GetType().GetField(name, Instance).SetValue(Library, value); }
    static void Check(bool ok, string message) { if (!ok) throw new Exception(message); checks.Add(message); }
    static void Log(string message, string stack, LogType type)
    {
        if (type == LogType.Error || type == LogType.Exception || type == LogType.Assert) guiError = message + "\n" + stack;
    }
    static void OneWindow(string page)
    {
        var windows = Resources.FindObjectsOfTypeAll<EditorWindow>().Where(w => w.GetType().Assembly == typeof(ASEShaderConverterWindow).Assembly).ToArray();
        Check(windows.Length == 1 && windows[0] == main && (string)Field("activePage") == page, "Only the main plugin window is open on " + page + " (phase " + phase + ", actual=" + Field("activePage") + ", windows=" + string.Join(",", windows.Select(w => w.GetType().Name)) + ")");
    }
    static void ClickPage(int index)
    {
        var area = ((Rect[])Field("navigationAreas"))[index];
        Check(area.width >= 150 && area.height >= 24, "Sidebar has a real clickable navigation row " + index);
        main.Focus();
        main.SendEvent(new Event { type = EventType.MouseDown, button = 0, mousePosition = area.center });
        main.SendEvent(new Event { type = EventType.MouseUp, button = 0, mousePosition = area.center });
    }
    static void DropFolder()
    {
        var area = (Rect)Field("inputPathArea");
        DragAndDrop.PrepareStartDrag(); DragAndDrop.paths = new[] { Application.dataPath }; DragAndDrop.objectReferences = new UnityEngine.Object[0];
        main.SendEvent(new Event { type = EventType.DragUpdated, mousePosition = area.center });
        main.SendEvent(new Event { type = EventType.DragPerform, mousePosition = area.center });
        Check((string)Field("inputPath") == "Assets" && Field("analysis") == null, "Directory drag still selects the folder without analysis in the embedded conversion page (page=" + Field("activePage") + ", input=" + Field("inputPath") + ")");
        DragAndDrop.PrepareStartDrag();
    }
    static void DropOutput(string path, UnityEngine.Object folder)
    {
        var area = (Rect)Field("outputPathArea");
        DragAndDrop.PrepareStartDrag(); DragAndDrop.paths = new[] { path }; DragAndDrop.objectReferences = folder == null ? new UnityEngine.Object[0] : new[] { folder };
        main.SendEvent(new Event { type = EventType.DragUpdated, mousePosition = area.center });
        main.SendEvent(new Event { type = EventType.DragPerform, mousePosition = area.center });
        DragAndDrop.PrepareStartDrag();
    }
    static int outputPhase;
    static bool CheckOutputDrop()
    {
        switch (outputPhase++)
        {
            case 0:
                Set("outputPath", "Assets/RetainedOutput.shader");
                DropOutput(outputFolder, AssetDatabase.LoadAssetAtPath<UnityEngine.Object>(outputFolder));
                Check((string)Field("outputPath") == outputFolder + "/RetainedOutput 1.shader", "Dragging an output Project folder retains the ASE filename and avoids overwriting an existing asset (actual=" + Field("outputPath") + ")");
                return false;
            case 1:
                Set("targetGraph", 1); Set("outputPath", "Assets/RetainedGraph.shadergraph"); return false;
            case 2:
                DropOutput(Application.dataPath, null);
                Check((string)Field("outputPath") == "Assets/RetainedGraph.shadergraph", "Dragging the system Assets root selects a ShaderGraph output directory and retains its filename");
                Check(Field("analysis") == null && (string)Field("inputPath") == "Assets" && Directory.GetFiles(outputFolder).Count(f => !f.EndsWith(".meta")) == 1, "Output directory drops perform no generation and do not change the source selection");
                return false;
            case 3:
                DropOutput(outputFolder, null);
                typeof(ASEShaderConverterWindow).GetMethod("SuggestOutputPath", Instance).Invoke(main, new object[] { "Assets/ChangedSource.shader" });
                Check((string)Field("outputPath") == outputFolder + "/ChangedSource_SG.shadergraph", "The chosen output directory survives subsequent filename suggestions");
                return false;
            default:
                var package = UnityEditor.PackageManager.PackageInfo.FindForAssembly(typeof(ASEShaderConverterWindow).Assembly);
                DropOutput(package.resolvedPath, null);
                Check((string)Field("outputPath") == outputFolder + "/ChangedSource_SG.shadergraph", "A folder outside this project's Assets cannot become the output location");
                Set("targetGraph", 0); Set("error", ""); return true;
        }
    }
    public static void Preview() { preview = true; Run(); }
    public static void Run()
    {
        savedLanguageExists = EditorPrefs.HasKey(LanguageKey); savedLanguage = EditorPrefs.GetString(LanguageKey, "");
        Application.logMessageReceived += Log;
        try
        {
            language = typeof(ASEShaderConverterWindow).Assembly.GetType("ASEShaderConverter.Editor.CHToolLanguage", true);
            outputFolder = "Assets/OutputFolders047/" + DateTime.UtcNow.ToString("yyyyMMddHHmmssfff");
            Directory.CreateDirectory(outputFolder);
            File.WriteAllText(outputFolder + "/RetainedOutput.shader", "Shader \"Hidden/OutputCollision047\" { SubShader { Pass {} } }");
            AssetDatabase.Refresh();
            language.GetMethod("Set", Static).Invoke(null, new object[] { true });
            Check(EditorApplication.ExecuteMenuItem("Tools/Shader"), "Tools/Shader opens the single main window directly");
            main = Resources.FindObjectsOfTypeAll<ASEShaderConverterWindow>().Single(); main.position = new Rect(180, 150, 1100, 720);
            var package = UnityEditor.PackageManager.PackageInfo.FindForAssembly(typeof(ASEShaderConverterWindow).Assembly);
            var manifest = JsonUtility.FromJson<Manifest>(File.ReadAllText(Path.Combine(package.resolvedPath, "package.json")));
            Check(manifest.author != null && manifest.author.name == "CH", "Installed package author is exactly CH");
            Set("inputPath", "Assets/RetainedInput.shader"); Set("outputPath", "Assets/RetainedOutput.shader");
            report = new ShaderConversionAnalysis { report = new ShaderConversionReport() };
            Set("analysis", report);
            phase = 0; deadline = EditorApplication.timeSinceStartup + 2; timeout = EditorApplication.timeSinceStartup + 90;
            EditorApplication.update += Tick;
        }
        catch (Exception e) { Finish(e); }
    }
    static void Tick()
    {
        try
        {
            if (guiError != null) throw new Exception(guiError);
            if (EditorApplication.timeSinceStartup > timeout) throw new TimeoutException("Unified window validation timed out");
            if (EditorApplication.timeSinceStartup < deadline) return;
            switch (phase)
            {
                case 0:
                    OneWindow("conversion");
                    Check(((Rect)Field("inputPathArea")).width > 500, "The content panel expands across the available window width");
                    ClickPage(1); break;
                case 1:
                    OneWindow("library");
                    var catalog = (ShaderLibraryCatalog)LibraryField("catalog");
                    Check(catalog != null && catalog.entries.Count == 293, "Embedded library loads the complete 293-graph catalog");
                    LibrarySet("search", "玉石"); LibrarySet("categoryId", "Jade"); LibrarySet("scope", 1); LibrarySet("pipeline", 0);
                    ClickPage(2); break;
                case 2:
                    OneWindow("agent");
                    Check(File.Exists(Path.Combine(ShaderAgentInbox.Root, "connection.json")), "Embedded Agent page uses the existing live project connection");
                    Set("agentTab", 1); break;
                case 3: ClickPage(3); break;
                case 4:
                    OneWindow("settings");
                    language.GetMethod("Set", Static).Invoke(null, new object[] { false }); break;
                case 5:
                    Check(main.titleContent.text == "Shader Converter", "A single language change refreshes the main window to English");
                    language.GetMethod("Reset", Static).Invoke(null, null);
                    Check(!EditorPrefs.HasKey(LanguageKey) && (bool)language.GetProperty("IsChinese", Static).GetValue(null) == (bool)language.GetMethod("EditorIsChinese", Static).Invoke(null, null), "Default language follows Unity without a separate language plugin");
                    language.GetMethod("Set", Static).Invoke(null, new object[] { true });
                    ShaderLibraryWindow.Open(); break;
                case 6:
                    OneWindow("library");
                    Check((string)LibraryField("search") == "玉石" && (string)LibraryField("categoryId") == "Jade" && (int)LibraryField("scope") == 1, "Switching pages and the legacy library entry retain search, category and scope");
                    // Exercise Unity's serialized window restoration while runtime catalog caches are absent.
                    string serialized = JsonUtility.ToJson(Library); JsonUtility.FromJsonOverwrite(serialized, Library);
                    Library.GetType().GetField("catalog", Instance).SetValue(Library, null);
                    Library.GetType().GetMethod("EnsureLoaded", Instance).Invoke(Library, null);
                    Check((int)LibraryField("pipeline") == 0 && (string)LibraryField("search") == "玉石", "Serialized library filters survive rebuilding the catalog cache");
                    ClickPage(0); break;
                case 7:
                    OneWindow("conversion");
                    Check((string)Field("inputPath") == "Assets/RetainedInput.shader" && (string)Field("outputPath") == "Assets/RetainedOutput.shader" && ReferenceEquals(Field("analysis"), report), "Navigation retains conversion input, output and the current report");
                    Set("conversionTab", 1); break;
                case 8:
                    Check((int)Field("conversionTab") == 1, "The analysis report renders inside its conversion subpage");
                    Set("conversionTab", 0); Set("analysis", null); break;
                case 9: DropFolder(); break;
                case 10:
                    if (!CheckOutputDrop()) { main.Repaint(); deadline = EditorApplication.timeSinceStartup + .65; return; }
                    ShaderLibraryWindow.OpenCategory("Skin"); break;
                case 11:
                    OneWindow("library"); Check((string)LibraryField("categoryId") == "Skin", "Legacy category links open the embedded Skin category");
                    CharacterMaterialWindow.Open(); break;
                case 12:
                    OneWindow("library"); ShaderAgentInbox.OpenInbox(); break;
                case 13:
                    OneWindow("agent"); ShaderPackageUpdateWindow.Open(); break;
                case 14:
                    OneWindow("settings"); Check((int)Field("settingsTab") == 1, "Legacy update entry selects Settings / Updates inline");
                    latest = ShaderPackageUpdater.Latest;
                    SetLatest(null); break;
                case 15:
                    Check(!ShaderPackageUpdater.HasNewVersion, "Unknown remote version does not offer an update");
                    var current = new Version(ShaderPackageUpdater.Installed.version);
                    SetLatest(new ShaderPackageRelease { version = current, tag = "v" + current }); break;
                case 16:
                    Check(!ShaderPackageUpdater.HasNewVersion, "An equal remote version does not offer an update");
                    var next = new Version(ShaderPackageUpdater.Installed.version); next = new Version(next.Major, next.Minor, next.Build + 1);
                    SetLatest(new ShaderPackageRelease { version = next, tag = "v" + next }); break;
                case 17:
                    Check(ShaderPackageUpdater.HasNewVersion, "A higher remote version is shown in the inline update page");
                    SetLatest(latest);
                    EditorWindow.GetWindow<ShaderLibraryWindow>().Show(); break;
                case 18:
                    OneWindow("library"); EditorWindow.GetWindow<CharacterMaterialWindow>().Show(); break;
                case 19:
                    OneWindow("library"); EditorWindow.GetWindow<ShaderPackageUpdateWindow>().Show(); break;
                case 20:
                    OneWindow("settings");
                    main.position = new Rect(180, 150, 800, 500); Set("settingsTab", 2); break;
                case 21: ClickPage(1); break;
                case 22:
                    OneWindow("library"); LibrarySet("tab", 1); break;
                case 23:
                    Check(guiError == null, "Library assets and research pages render at minimum window size without GUI errors");
                    ClickPage(0); Set("conversionTab", 2); break;
                case 24:
                    Check(guiError == null, "All conversion subpages and restored legacy windows render without GUI errors");
                    main.position = new Rect(180, 150, 1100, 720); Set("conversionTab", 0);
                    Finish(null); return;
            }
            phase++; main.Repaint(); deadline = EditorApplication.timeSinceStartup + .65;
        }
        catch (Exception e) { Finish(e); }
    }
    static void SetLatest(ShaderPackageRelease value) { typeof(ShaderPackageUpdater).GetProperty("Latest").GetSetMethod(true).Invoke(null, new object[] { value }); }
    static void Finish(Exception error)
    {
        EditorApplication.update -= Tick; Application.logMessageReceived -= Log;
        if (savedLanguageExists) EditorPrefs.SetString(LanguageKey, savedLanguage); else EditorPrefs.DeleteKey(LanguageKey);
        if (language != null) language.GetMethod("Refresh", Static).Invoke(null, null);
        Directory.CreateDirectory("Artifacts");
        var installed = ShaderPackageUpdater.Installed;
        File.WriteAllText("Artifacts/unified-window.json", JsonUtility.ToJson(new Result { success = error == null, unityVersion = Application.unityVersion,
            version = installed == null ? "" : installed.version, source = installed == null ? "" : installed.source.ToString(), checks = checks.ToArray(), error = error == null ? "" : error.ToString() }, true));
        if (preview && main != null) { main.Show(); main.Focus(); return; }
        if (main != null) main.Close(); EditorApplication.Exit(error == null ? 0 : 1);
    }
    [Serializable] sealed class Result { public bool success; public string unityVersion, version, source, error; public string[] checks; }
    [Serializable] sealed class Manifest { public Author author; }
    [Serializable] sealed class Author { public string name; }
}
