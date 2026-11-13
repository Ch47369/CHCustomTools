// Runs only in task-owned isolated projects. Exercises imported audio/VFX behavior and the actual host UI.
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Security.Cryptography;
using CH.CustomTools.VFX;
using ASEShaderConverter.Editor;
using UnityEditor;
using UnityEngine;
using Object = UnityEngine.Object;

public static class UnityCustomToolsSmoke
{
    const BindingFlags I = BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic;
    const BindingFlags S = BindingFlags.Static | BindingFlags.Public | BindingFlags.NonPublic;
    const string LanguageKey = "CH.CustomTools.Language";
    static readonly List<string> checks = new List<string>();
    static ASEShaderConverterWindow main;
    static RhythmCurveProfile profile;
    static string folder, error, oldLanguage;
    static bool hadLanguage;
    static Type language;
    static int phase;
    static double next, timeout;
    static object Get(object obj, string name) { return obj.GetType().GetField(name, I).GetValue(obj); }
    static void Set(object obj, string name, object value) { obj.GetType().GetField(name, I).SetValue(obj, value); }
    static object Call(object obj, string name, params object[] args) { return obj.GetType().GetMethod(name, I).Invoke(obj, args); }
    static void Check(bool ok, string name) { if (!ok) throw new Exception(name); checks.Add(name); }
    static string Hash(string path) { using (var h = SHA256.Create()) return BitConverter.ToString(h.ComputeHash(File.ReadAllBytes(path))); }
    static void Throws(Action action, string name) { bool threw = false; try { action(); } catch { threw = true; } Check(threw, name); }
    static void Log(string message, string stack, LogType type) { if (type == LogType.Error || type == LogType.Exception || type == LogType.Assert) error = message + "\n" + stack; }
    static void One(string page)
    {
        var windows = Resources.FindObjectsOfTypeAll<EditorWindow>().Where(w => w.GetType().Assembly == typeof(ASEShaderConverterWindow).Assembly).ToArray();
        Check(windows.Length == 1 && windows[0] == main && (string)Get(main, "activePage") == page, "One host window displays " + page);
    }
    static void Click(int row)
    {
        var rect = ((Rect[])Get(main, "navigationAreas"))[row];
        Check(rect.width >= 150 && rect.height >= 24, "Clickable category row " + row);
        main.SendEvent(new Event { type = EventType.MouseDown, button = 0, mousePosition = rect.center });
        main.SendEvent(new Event { type = EventType.MouseUp, button = 0, mousePosition = rect.center });
    }
    static void WriteAudio(string path)
    {
        const int hz = 22050, frames = hz * 4;
        using (var w = new BinaryWriter(File.Create(path)))
        {
            w.Write(System.Text.Encoding.ASCII.GetBytes("RIFF")); w.Write(36 + frames * 4); w.Write(System.Text.Encoding.ASCII.GetBytes("WAVEfmt "));
            w.Write(16); w.Write((short)1); w.Write((short)2); w.Write(hz); w.Write(hz * 4); w.Write((short)4); w.Write((short)16);
            w.Write(System.Text.Encoding.ASCII.GetBytes("data")); w.Write(frames * 4);
            for (int i = 0; i < frames; i++)
            {
                double time = (double)i / hz, pulse = Math.Exp(-((time % .5) * 35));
                short v = (short)(Math.Sin(2 * Math.PI * 220 * time) * pulse * 25000); w.Write(v); w.Write((short)-v);
            }
        }
    }
    static void AudioChecks()
    {
        string path = folder + "/Source.wav"; WriteAudio(path); AssetDatabase.ImportAsset(path, ImportAssetOptions.ForceSynchronousImport);
        var importer = (AudioImporter)AssetImporter.GetAtPath(path); var sample = importer.defaultSampleSettings;
        sample.loadType = AudioClipLoadType.CompressedInMemory; sample.compressionFormat = AudioCompressionFormat.Vorbis;
        importer.defaultSampleSettings = sample; importer.SaveAndReimport();
        string sourceHash = Hash(path), metaHash = Hash(path + ".meta");
        var source = AssetDatabase.LoadAssetAtPath<AudioClip>(path); var copy = RhythmAudioImport.CreateAnalysisCopy(source);
        Check(copy != source && copy.loadType == AudioClipLoadType.DecompressOnLoad && Hash(path) == sourceHash && Hash(path + ".meta") == metaHash,
            "Decompressed analysis copy leaves original audio bytes and import settings intact");
        var settings = new RhythmAnalysisSettings(); var result = RhythmAnalyzer.Analyze(copy, settings);
        Check(result.curves.Length == 6 && result.curves.All(c => c.length >= 2) && result.beats.Length >= 4, "Imported antiphase stereo audio produces six curves and detected onsets");
        Check(result.curves[0].keys.Max(k => k.value) > .5f, "Opposite stereo phase does not cancel the audio envelope");
        var silence = RhythmAnalyzer.Analyze(new float[22050], 1, 22050, settings);
        Check(silence.curves.All(c => c.keys.All(k => Math.Abs(k.value) < .0001f)) && silence.beats.Length == 0, "Silence produces zero-valued channels and no beats");
        profile = ScriptableObject.CreateInstance<RhythmCurveProfile>();
        profile.Initialize(copy, settings, result, AssetDatabase.GetAssetDependencyHash(AssetDatabase.GetAssetPath(copy)).ToString());
        RhythmCurveExport.SaveNewAsset(profile, folder + "/Profile.asset");
        string saved = EditorJsonUtility.ToJson(profile); AssetDatabase.ImportAsset(folder + "/Profile.asset", ImportAssetOptions.ForceSynchronousImport);
        profile = AssetDatabase.LoadAssetAtPath<RhythmCurveProfile>(folder + "/Profile.asset");
        Check(EditorJsonUtility.ToJson(profile) == saved && profile.Source == copy, "Saved profile reloads all six curves, source reference, settings and beats");
        var mapping = new RhythmCurveMapping { minimum = 2, maximum = 6, exponent = 1.4f, timeOffset = .1f };
        var mapped = RhythmCurveExport.Map(profile, RhythmChannel.Envelope, mapping, false);
        Check(Math.Abs(mapped.Evaluate(0) - 2) < .001f && mapped.keys.All(k => k.value >= 1.999f && k.value <= 6.001f), "Curve mapping retains range, exponent and time offset");
        foreach (RhythmAnimationTarget target in Enum.GetValues(typeof(RhythmAnimationTarget)))
        {
            var clip = RhythmCurveExport.CreateAnimation(profile, RhythmChannel.Envelope, mapping, target, "Child", "_Intensity", typeof(MeshRenderer), true);
            int expected = target == RhythmAnimationTarget.UniformScale ? 3 : 1;
            Check(AnimationUtility.GetCurveBindings(clip).Length == expected && AnimationUtility.GetAnimationClipSettings(clip).loopTime,
                "Native animation exports correct bindings and loop state for " + target);
            RhythmCurveExport.SaveNewAsset(clip, folder + "/Export.anim");
        }
        Check(AssetDatabase.FindAssets("t:AnimationClip", new[] { folder }).Length == 4, "Repeated exports keep existing clips and create unique filenames");
        var root = new GameObject("AudioFixture"); var child = new GameObject("Child"); child.transform.SetParent(root.transform);
        try
        {
            var ps = root.AddComponent<ParticleSystem>(); ps.Stop(true, ParticleSystemStopBehavior.StopEmittingAndClear);
            var nested = child.AddComponent<ParticleSystem>(); nested.Stop(true, ParticleSystemStopBehavior.StopEmittingAndClear);
            foreach (RhythmParticleProperty prop in Enum.GetValues(typeof(RhythmParticleProperty)))
            {
                float before = ps.main.duration;
                Check(RhythmCurveExport.ApplyParticles(root, true, profile, RhythmChannel.Pulse, mapping, prop, true, false) == 2 && Math.Abs(ps.main.duration - profile.Duration) < .001f,
                    "Particle curve and duration applied to root and child for " + prop);
                Undo.PerformUndo(); Check(Math.Abs(ps.main.duration - before) < .001f, "Particle authoring supports Undo for " + prop);
            }
            var tracks = new List<RhythmEffectTrack> { new RhythmEffectTrack { target = child, initiallyVisible = false,
                cues = new List<RhythmEffectCue> { new RhythmEffectCue { time = .5f, duration = .25f, action = RhythmEffectCueAction.ShowForDuration } } } };
            var timing = RhythmEffectTiming.CreateAnimation(root, tracks, profile.Duration, .1f);
            var binding = AnimationUtility.GetCurveBindings(timing).Single(); var active = AnimationUtility.GetEditorCurve(timing, binding);
            Check(binding.path == "Child" && binding.propertyName == "m_IsActive" && active.Evaluate(.59f) == 0 && active.Evaluate(.61f) == 1 && active.Evaluate(.86f) == 0,
                "Child effect timing exports native active-state steps with time offset");
            Object.DestroyImmediate(timing);
            tracks[0].cues.Add(new RhythmEffectCue { time = .6f, duration = .2f });
            Throws(() => RhythmEffectTiming.CreateAnimation(root, tracks, profile.Duration, 0), "Overlapping effect activation intervals are rejected");
        }
        finally { Object.DestroyImmediate(root); }
        // A legacy YAML fixture is byte-identical to a standalone saved profile apart from its script reference.
        string newGuid = AssetDatabase.AssetPathToGUID(AssetDatabase.GetAssetPath(MonoScript.FromScriptableObject(profile)));
        string legacy = folder + "/Legacy.asset";
        File.WriteAllText(legacy, File.ReadAllText(folder + "/Profile.asset").Replace(newGuid, RhythmProfileMigration.LegacyScriptGuid));
        var oldType = AppDomain.CurrentDomain.GetAssemblies().Select(a => a.GetType("AudioRhythmCurves.RhythmCurveProfile")).FirstOrDefault(t => t != null);
        if (oldType != null)
        {
            File.Delete(legacy);
            var oldSettingsType = oldType.Assembly.GetType("AudioRhythmCurves.RhythmAnalysisSettings");
            var oldAnalyzer = oldType.Assembly.GetType("AudioRhythmCurves.RhythmAnalyzer");
            var oldResult = oldAnalyzer.GetMethods(S).Single(m => m.Name == "Analyze" && m.GetParameters()[0].ParameterType == typeof(AudioClip)).Invoke(null, new object[] { copy, Activator.CreateInstance(oldSettingsType), null });
            var oldProfile = ScriptableObject.CreateInstance(oldType);
            oldType.GetMethod("Initialize").Invoke(oldProfile, new object[] { copy, Activator.CreateInstance(oldSettingsType), oldResult, profile.SourceDependencyHash });
            AssetDatabase.CreateAsset(oldProfile, legacy); AssetDatabase.SaveAssets();
            Check(File.ReadAllText(legacy).Contains(RhythmProfileMigration.LegacyScriptGuid), "Actual installed standalone plugin saves its original profile script identity");
        }
        AssetDatabase.ImportAsset(legacy, ImportAssetOptions.ForceSynchronousImport);
        string legacyHash = Hash(legacy); var migrated = RhythmProfileMigration.CreateCopy(legacy);
        Check(Hash(legacy) == legacyHash && migrated.Source == profile.Source && migrated.Beats.Length == profile.Beats.Length &&
            migrated.GetCurve(RhythmChannel.Envelope).keys.SequenceEqual(profile.GetCurve(RhythmChannel.Envelope).keys), "Legacy profile migration preserves original bytes and restores curve/source data in a separate asset");
        string newPath = AssetDatabase.GetAssetPath(migrated);
        Check(AssetDatabase.AssetPathToGUID(newPath) != AssetDatabase.AssetPathToGUID(legacy), "Migrated profile copy has its own asset GUID");
        Throws(() => RhythmProfileMigration.CreateCopy(folder + "/Profile.asset"), "Migration rejects profiles already belonging to the collection");
    }
    static void OrganizerChecks()
    {
        NamingChecks();
        string assets = folder + "/SourceAssets"; Directory.CreateDirectory(assets); AssetDatabase.Refresh();
        var texture = new Texture2D(2, 2); texture.SetPixel(0, 0, Color.magenta); texture.Apply(); AssetDatabase.CreateAsset(texture, assets + "/Texture.asset");
        var material = new Material(Shader.Find("Unlit/Texture")); material.mainTexture = texture; AssetDatabase.CreateAsset(material, assets + "/Material.mat");
        var go = GameObject.CreatePrimitive(PrimitiveType.Quad); go.GetComponent<Renderer>().sharedMaterial = material;
        var prefab = PrefabUtility.SaveAsPrefabAsset(go, assets + "/Effect.prefab"); Object.DestroyImmediate(go); AssetDatabase.SaveAssets();
        string textureGuid = AssetDatabase.AssetPathToGUID(assets + "/Texture.asset"), materialGuid = AssetDatabase.AssetPathToGUID(assets + "/Material.mat");
        var settings = new VfxOrganizerSettings { destination = folder + "/Organized", effectName = "Fixture" };
        foreach (var rule in settings.rules) rule.enabled = rule.kind == VfxResourceKind.Texture || rule.kind == VfxResourceKind.Material;
        var restored = VfxOrganizerPresets.Deserialize(VfxOrganizerPresets.Serialize(settings));
        Check(restored.rules.Count == settings.rules.Count && restored.destination == settings.destination, "Organizer presets round-trip all naming and folder rules");
        var scan = VfxResourceOrganizer.Scan(new[] { prefab }); var plan = VfxResourceOrganizer.BuildPlan(scan, settings);
        Check(plan.moves.Count == 2, "Recursive prefab scan builds a preview of its material and texture dependencies: " + string.Join(";", scan.entries.Select(x => x.path + ":" + x.protection + ":" + x.externalUsers.Count)));
        var excluded = VfxResourceOrganizer.BuildPlan(scan, settings, new HashSet<string> { textureGuid });
        Check(excluded.moves.Count == 1 && excluded.moves[0].resource.guid == materialGuid, "Manual resource exclusion is honored by the preview");
        string journal = VfxResourceOrganizer.Execute(plan);
        string textureMoved = AssetDatabase.GUIDToAssetPath(textureGuid), materialMoved = AssetDatabase.GUIDToAssetPath(materialGuid);
        Check(File.Exists(journal) && textureMoved.StartsWith(settings.destination) && materialMoved.StartsWith(settings.destination), "Execute moves assets to previewed paths and writes a recovery journal");
        Check(AssetDatabase.LoadAssetAtPath<Material>(materialMoved).mainTexture == AssetDatabase.LoadAssetAtPath<Texture>(textureMoved) &&
            prefab.GetComponent<Renderer>().sharedMaterial == AssetDatabase.LoadAssetAtPath<Material>(materialMoved), "GUID-preserving moves retain prefab, material and texture references");
        var movedMaterial = AssetDatabase.LoadAssetAtPath<Material>(materialMoved); movedMaterial.renderQueue = 2451; EditorUtility.SetDirty(movedMaterial); AssetDatabase.SaveAssets();
        VfxResourceOrganizer.Restore(journal);
        Check(AssetDatabase.GUIDToAssetPath(textureGuid) == assets + "/Texture.asset" && AssetDatabase.GUIDToAssetPath(materialGuid) == assets + "/Material.mat" &&
            AssetDatabase.LoadAssetAtPath<Material>(assets + "/Material.mat").renderQueue == 2451, "Journal restoration restores original paths/GUIDs and retains edits made after organization");
        var shared = new Material(Shader.Find("Unlit/Texture")); shared.mainTexture = texture; AssetDatabase.CreateAsset(shared, assets + "/External.mat"); AssetDatabase.SaveAssets();
        scan = VfxResourceOrganizer.Scan(new[] { prefab }); plan = VfxResourceOrganizer.BuildPlan(scan, settings);
        Check(plan.moves.All(x => x.resource.guid != textureGuid), "Default organizer rules keep a texture referenced outside the selected effect");
    }
    static void NamingChecks()
    {
        var builder=typeof(VfxResourceOrganizer).Assembly.GetType("CH.CustomTools.VFX.VfxNameBuilder",true);
        var parse=builder.GetMethod("TryParse",S);var compose=builder.GetMethod("Compose",S);
        foreach(string pattern in new[]{"{prefix}_{effect}_{index:000}","{name}","VFX-{effect}__{prefix}.{index:00000000}","自定义文字_{index}_{name}_end","{index:00}{index:0000}"})
        {
            object[] args={pattern,null};Check((bool)parse.Invoke(null,args),"Readable name builder imports existing pattern: "+pattern);
            string roundtrip=(string)compose.Invoke(null,new[]{args[1]});
            Check(VfxResourceOrganizer.ExpandName(pattern,"T","Fire","Spark",12)==VfxResourceOrganizer.ExpandName(roundtrip,"T","Fire","Spark",12),"Readable name builder preserves existing filename output");
        }
        object[] unknown={"{unsupported}",null};Check(!(bool)parse.Invoke(null,unknown),"Unknown legacy pattern is preserved without automatic replacement");
        object[] edit={"{prefix}_{effect}_{index:000}",null};parse.Invoke(null,edit);
        var list=(System.Collections.IList)edit[1];var number=list[2];number.GetType().GetField("digits").SetValue(number,4);number.GetType().GetField("after").SetValue(number,"-");
        list.RemoveAt(2);list.Insert(0,number);list[2].GetType().GetField("after").SetValue(list[2],"");
        string changed=(string)compose.Invoke(null,new[]{edit[1]});
        Check(VfxResourceOrganizer.ExpandName(changed,"T","Fire","Spark",2)=="0002-T_Fire","Reordering parts and changing digits or separator changes the real output");
        var settings=new VfxOrganizerSettings();settings.rules[0].customNaming=true;settings.rules[0].pattern=changed;
        var loaded=VfxOrganizerPresets.Deserialize(VfxOrganizerPresets.Serialize(settings));
        Check(loaded.rules[0].customNaming && loaded.rules[0].pattern==changed,"Readable custom naming survives saved-preset reload");
    }
    public static void Preview()
    {
        language=typeof(ASEShaderConverterWindow).Assembly.GetType("ASEShaderConverter.Editor.CHToolLanguage",true);
        language.GetMethod("Set",S).Invoke(null,new object[]{true});
        ASEShaderConverterWindow.OpenOrganizer();main=Resources.FindObjectsOfTypeAll<ASEShaderConverterWindow>().Single();
        main.position=new Rect(180,100,1120,820);
        var settings=(VfxOrganizerSettings)Get(Get(main,"organizer"),"settings");settings.rules[0].customNaming=true;main.Repaint();
    }
    public static void Run()
    {
        hadLanguage = EditorPrefs.HasKey(LanguageKey); oldLanguage = EditorPrefs.GetString(LanguageKey, "");
        try
        {
            folder = "Assets/CustomTools048/" + DateTime.UtcNow.ToString("yyyyMMddHHmmssfff"); Directory.CreateDirectory(folder); AssetDatabase.Refresh();
            AudioChecks(); OrganizerChecks(); Application.logMessageReceived += Log;
            language = typeof(ASEShaderConverterWindow).Assembly.GetType("ASEShaderConverter.Editor.CHToolLanguage", true);
            language.GetMethod("Set", S).Invoke(null, new object[] { true });
            Check(EditorApplication.ExecuteMenuItem("Tools/CH自定义工具集"), "Unified Tools menu opens the collection");
            var menus = typeof(ASEShaderConverterWindow).Assembly.GetTypes().SelectMany(t => t.GetMethods(S | I))
                .SelectMany(m => m.GetCustomAttributes(typeof(MenuItem), false).Cast<MenuItem>()).Where(m => m.menuItem.StartsWith("Tools/")).Select(m => m.menuItem).Distinct().ToArray();
            Check(menus.Length == 1 && menus[0] == "Tools/CH自定义工具集", "Bundled assembly contributes exactly one Tools menu entry");
            main = Resources.FindObjectsOfTypeAll<ASEShaderConverterWindow>().Single(); main.position = new Rect(180, 150, 1120, 760);
            Set(main, "inputPath", "Assets/Retained.shader"); Set(main, "outputPath", "Assets/RetainedOutput.shader");
            next = EditorApplication.timeSinceStartup + 2; timeout = next + 90; EditorApplication.update += Tick;
        }
        catch (Exception e) { Finish(e); }
    }
    static void Tick()
    {
        try
        {
            if (error != null) throw new Exception(error);
            if (EditorApplication.timeSinceStartup > timeout) throw new TimeoutException();
            if (EditorApplication.timeSinceStartup < next) return;
            switch (phase++)
            {
                case 0:
                    One("conversion"); Check(main.titleContent.text == "CH自定义工具集", "Chinese collection title is correct");
                    Check(((Rect)Get(main, "inputPathArea")).width > 500, "Shader content expands across the host window");
                    var area = (Rect)Get(main, "inputPathArea");
                    DragAndDrop.PrepareStartDrag(); DragAndDrop.paths = new[] { Application.dataPath }; DragAndDrop.objectReferences = new Object[0];
                    main.SendEvent(new Event { type = EventType.DragPerform, mousePosition = area.center });
                    Check((string)Get(main, "inputPath") == "Assets" && Get(main, "analysis") == null, "Input folder drag selects a directory without conversion");
                    area = (Rect)Get(main, "outputPathArea");
                    main.SendEvent(new Event { type = EventType.DragPerform, mousePosition = area.center });
                    Check((string)Get(main, "outputPath") == "Assets/RetainedOutput.shader", "Output folder drag retains its filename inside the unified window");
                    DragAndDrop.PrepareStartDrag(); Set(main, "inputPath", "Assets/Retained.shader"); Click(1); break;
                case 1: One("audio"); Check(AssetDatabase.OpenAsset(profile), "Double-clicking a curve profile routes into the host audio panel"); break;
                case 2:
                    One("audio"); Check((RhythmCurveProfile)Get(Get(main, "audio"), "profile") != profile, "Audio panel edits a working copy of a saved profile");
                    Set(Get(main, "audio"), "cursor", .75f); ASEShaderConverterWindow.OpenOrganizer(); break;
                case 3:
                    One("organizer"); Set(Get(main, "organizer"), "filter", "RetainedFilter");
                    ((VfxOrganizerSettings)Get(Get(main,"organizer"),"settings")).rules[0].customNaming=true;Click(0); break;
                case 4: One("conversion"); Check((string)Get(main, "inputPath") == "Assets/Retained.shader", "Shader input is retained across VFX navigation"); ASEShaderConverterWindow.OpenLibrary(); break;
                case 5:
                    One("library"); var library = Get(main, "library");
                    var actions=(Rect)Get(library,"actionRow");var selectors=(Rect)Get(library,"selectorRow");
                    Check(actions.width>500 && Math.Abs(actions.x-selectors.x)<.1f && Math.Abs(actions.width-selectors.width)<.1f,"Library action and selector rows have matching edges and equal columns");
                    Check(((ASEShaderConverter.ShaderLibraryCatalog)Get(library, "catalog")).entries.Count == 293, "Unified window retains the full 293-shader catalog");
                    Set(library, "search", "玉石"); ASEShaderConverterWindow.OpenAgent(); break;
                case 6: One("agent"); Check(File.Exists(Path.Combine(ShaderAgentInbox.Root, "connection.json")), "Agent connection stays available"); ASEShaderConverterWindow.OpenAudio(); break;
                case 7: One("audio"); Check(Math.Abs((float)Get(Get(main, "audio"), "cursor") - .75f) < .001f, "Audio cursor/profile state survives category changes"); Click(3); break;
                case 8: One("settings"); language.GetMethod("Set", S).Invoke(null, new object[] { false }); break;
                case 9:
                    Check(main.titleContent.text == "CH Custom Tools", "One settings choice updates the host to English");
                    var audioLang = typeof(RhythmAnalyzer).Assembly.GetType("CH.CustomTools.VFX.CHToolLanguage");
                    Check(!(bool)audioLang.GetProperty("IsChinese", S).GetValue(null), "Audio/VFX panels share the host language cache");
                    language.GetMethod("Reset", S).Invoke(null, null);
                    Check(!EditorPrefs.HasKey(LanguageKey), "Reset restores Unity language following"); ASEShaderConverterWindow.OpenUpdates(); break;
                case 10:
                    One("settings"); Check((int)Get(main, "settingsTab") == 1, "Updates remain inside collection Settings");
                    ASEShaderConverterWindow.OpenOrganizer(); break;
                case 11:
                    One("organizer"); Check((string)Get(Get(main, "organizer"), "filter") == "RetainedFilter", "Organizer state survives language and category changes");
                    main.position = new Rect(180, 150, 800, 500); break;
                case 12: ASEShaderConverterWindow.OpenAudio(profile); break;
                case 13: One("audio"); Check(error == null, "Audio results and VFX panels render at minimum size without GUI errors");ASEShaderConverterWindow.OpenOrganizer();language.GetMethod("Set", S).Invoke(null,new object[]{false});break;
                case 14: One("organizer");Check(error==null,"Readable custom naming renders at minimum width in English");Finish(null);return;
            }
            main.Repaint(); next = EditorApplication.timeSinceStartup + .45;
        }
        catch (Exception e) { Finish(e); }
    }
    [Serializable] class Report { public string unity, version, status, failure; public string[] passed; public int count; }
    static void Finish(Exception failure)
    {
        EditorApplication.update -= Tick; Application.logMessageReceived -= Log;
        if (hadLanguage) EditorPrefs.SetString(LanguageKey, oldLanguage); else EditorPrefs.DeleteKey(LanguageKey);
        if (language != null) language.GetMethod("Refresh", S).Invoke(null, null);
        if (main != null) main.Close();
        var package = UnityEditor.PackageManager.PackageInfo.FindForAssembly(typeof(ASEShaderConverterWindow).Assembly);
        Directory.CreateDirectory("Artifacts"); File.WriteAllText("Artifacts/custom-tools.json", JsonUtility.ToJson(new Report { unity = Application.unityVersion, version = package.version,
            status = failure == null ? "Passed" : "Failed", failure = failure == null ? null : failure.ToString(), passed = checks.ToArray(), count = checks.Count }, true));
        EditorApplication.Exit(failure == null ? 0 : 1);
    }
}
