// Runs only in an authorized isolated project. Restores the shared user preference before exiting.
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using UnityEditor;
using UnityEngine;
using UnityEngine.UIElements;
using ASEShaderConverter.Editor;
using AudioRhythmCurves;

[InitializeOnLoad]
public static class UnityLocalizationSmoke
{
    const BindingFlags Static = BindingFlags.Static | BindingFlags.Public | BindingFlags.NonPublic;
    const string Key = "CH.CustomTools.Language";
    const string Resume = "CH.LocalizationSmoke.Resume";
    static readonly List<string> checks = new List<string>();
    static readonly List<EditorWindow> windows = new List<EditorWindow>();
    static Type shader, audio;
    static bool savedKey;
    static string savedValue, output;
    static int stage;
    static double deadline;
    static ShaderPackageManagerExtension extension;
    static VisualElement ui;
    [Serializable] sealed class Result { public bool success; public string unityVersion, error; public string[] checks; }
    static UnityLocalizationSmoke()
    {
        if(SessionState.GetBool(Resume,false))EditorApplication.delayCall+=AfterReload;
    }
    static void AfterReload()
    {
        output=SessionState.GetString(Resume+".Output","");
        var backup=JsonUtility.FromJson<Backup>(File.ReadAllText(Path.ChangeExtension(output,"preference-backup.json")));
        savedKey=backup.existed;savedValue=backup.value;
        var before=JsonUtility.FromJson<Result>(File.ReadAllText(output));checks.AddRange(before.checks);
        shader=typeof(ASEShaderConverterWindow).Assembly.GetType("ASEShaderConverter.Editor.CHToolLanguage",true);
        audio=typeof(RhythmCurveWindow).Assembly.GetType("AudioRhythmCurves.CHToolLanguage",true);
        try
        {
            Call(shader,"Refresh");Call(audio,"Refresh");
            Check(EditorPrefs.GetString(Key)=="en"&&!Chinese(shader)&&!Chinese(audio),"Both packages restore English preference after actual assembly reload");
            Finish(null);
        }
        catch(Exception e){Finish(e);}
    }
    static object Call(Type type, string name, params object[] args)
    {
        var method = type.GetMethods(Static).Single(m => m.Name == name && m.GetParameters().Select(p => p.ParameterType).SequenceEqual(args.Select(a => a.GetType())));
        return method.Invoke(null, args);
    }
    static bool Chinese(Type type) { return (bool)type.GetProperty("IsChinese", Static).GetValue(null); }
    static void Check(bool ok, string name) { if (!ok) throw new Exception(name); checks.Add(name); }
    public static void Run()
    {
        output = Path.GetFullPath("Artifacts/localization-verification.json");
        savedKey = EditorPrefs.HasKey(Key); savedValue = EditorPrefs.GetString(Key, "");
        Directory.CreateDirectory(Path.GetDirectoryName(output));
        File.WriteAllText(Path.ChangeExtension(output,"preference-backup.json"), JsonUtility.ToJson(new Backup { existed=savedKey, value=savedValue }));
        shader = typeof(ASEShaderConverterWindow).Assembly.GetType("ASEShaderConverter.Editor.CHToolLanguage", true);
        audio = typeof(RhythmCurveWindow).Assembly.GetType("AudioRhythmCurves.CHToolLanguage", true);
        try
        {
            foreach (var type in new[] { shader, audio })
            {
                var choices = (string[])type.GetField("Choices", Static).GetValue(null);
                Check(choices.SequenceEqual(new[] { "中文", "English" }), type.Namespace + ": exactly two language choices");
                Check((bool)Call(type,"Resolve","",true) && !(bool)Call(type,"Resolve","",false), type.Namespace + ": unset follows either Unity language");
                Check((bool)Call(type,"Resolve","zh",false) && !(bool)Call(type,"Resolve","en",true), type.Namespace + ": explicit language overrides either locale");
            }
            Call(shader,"Reset"); Call(audio,"Refresh");
            Check(!EditorPrefs.HasKey(Key) && Chinese(shader) == (bool)Call(shader,"EditorIsChinese"), "Default reads actual Editor locale without storing an override");
            Call(shader,"Set",false); Call(audio,"Refresh");
            Check(!Chinese(shader) && !Chinese(audio) && EditorPrefs.GetString(Key)=="en", "One English preference applies to both independent packages");
            ASEShaderConverterWindow.Open(); ShaderLibraryWindow.Open();
            RhythmCurveWindow.Open(); VfxResourceOrganizerWindow.Open();
            var updateType=typeof(RhythmCurveWindow).Assembly.GetType("AudioRhythmCurves.AudioRhythmCurvesUpdateWindow",true);
            updateType.GetMethod("Open",Static).Invoke(null,null);
            // Opening the shader update window would start a network query; its extension can be tested locally.
            windows.AddRange(Resources.FindObjectsOfTypeAll<EditorWindow>().Where(w=>new[]{typeof(ASEShaderConverterWindow),typeof(ShaderLibraryWindow),typeof(RhythmCurveWindow),typeof(VfxResourceOrganizerWindow),updateType}.Contains(w.GetType())));
            extension = new ShaderPackageManagerExtension(); ui = extension.CreateExtensionUI();
            Call(audio,"OpenSettings"); Call(shader,"OpenSettings");
            Check(Resources.FindObjectsOfTypeAll<EditorWindow>().Count(w=>w.GetType().Name=="CHToolSettingsWindow")==1,"All entry points open a single tool settings window");
            stage=0; deadline=EditorApplication.timeSinceStartup+2; EditorApplication.update+=Tick;
        }
        catch(Exception e) { Finish(e); }
    }
    [Serializable] sealed class Backup { public bool existed; public string value; }
    static void Tick()
    {
        if(EditorApplication.timeSinceStartup<deadline)return;
        try
        {
            string[] expected = stage==0
                ? new[]{"Shader Converter","ASE Shader Library","Audio Rhythm · Curves","VFX Resource Organizer","Audio Rhythm Curves · Updates"}
                : new[]{"Shader转换器","ASE 着色器库","音频节奏 · 曲线","特效资源整理","音频节奏曲线 · 更新"};
            foreach(var title in expected)Check(windows.Any(w=>w.titleContent.text==title),"Open window title refreshed: "+title);
            typeof(ShaderPackageManagerExtension).GetMethod("Refresh",BindingFlags.Instance|BindingFlags.NonPublic).Invoke(extension,null);
            Check(ui.Q<Button>("shader-converter-check-update").text==(stage==0?"Check for updates":"检查更新"),"Existing Package Manager control refreshes language");
            Check(ui.Q<Button>("shader-converter-install-update").style.display.value==DisplayStyle.None,"No update button appears without a newer release");
            if(stage++==0)
            {
                Call(audio,"Set",true);Call(shader,"Refresh");
                Check(Chinese(shader)&&Chinese(audio)&&EditorPrefs.GetString(Key)=="zh","Audio setting changes both packages to Chinese");
                foreach(var window in windows)window.Repaint();deadline=EditorApplication.timeSinceStartup+2;return;
            }
            var naming=new VfxResourceRule();var pattern=naming.pattern;
            Call(shader,"Set",false);Call(audio,"Refresh");
            Check(naming.pattern==pattern && VfxResourceNaming.Choices[0]=="前缀 + 特效名 + 序号（推荐）","Language preserves naming patterns and canonical public choices");
            foreach(var name in new[]{"com.aseshader.handwritten-converter","com.audiorhythmcurves.audio-rhythm-curves"})
            {
                var p=UnityEditor.PackageManager.PackageInfo.GetAllRegisteredPackages().Single(x=>x.name==name);
                var json=File.ReadAllText(Path.Combine(p.resolvedPath,"package.json"));
                Check(json.Contains("CH自定义工具集"),name+": Package Manager author grouping");
            }
            Call(shader,"Reset"); Call(audio,"Refresh");
            Check(!EditorPrefs.HasKey(Key)&&Chinese(shader)==Chinese(audio),"Reset clears override and both tools return to Unity default");
            Call(shader,"Set",false);Call(audio,"Refresh");
            File.WriteAllText(output,JsonUtility.ToJson(new Result{unityVersion=Application.unityVersion,checks=checks.ToArray()},true));
            SessionState.SetString(Resume+".Output",output);SessionState.SetBool(Resume,true);
            EditorUtility.RequestScriptReload();
            EditorApplication.update-=Tick;
        }
        catch(Exception e){Finish(e);}
    }
    static void Finish(Exception error)
    {
        EditorApplication.update-=Tick;
        SessionState.EraseBool(Resume);
        if(savedKey)EditorPrefs.SetString(Key,savedValue);else EditorPrefs.DeleteKey(Key);
        foreach(var window in windows)if(window!=null)window.Close();
        foreach(var window in Resources.FindObjectsOfTypeAll<EditorWindow>().Where(w=>w.GetType().Name=="CHToolSettingsWindow"))window.Close();
        File.WriteAllText(output,JsonUtility.ToJson(new Result{success=error==null,unityVersion=Application.unityVersion,error=error==null?null:error.ToString(),checks=checks.ToArray()},true));
        EditorApplication.Exit(error==null?0:1);
    }
}
