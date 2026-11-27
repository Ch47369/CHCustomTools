// Real Scene events, point geometry, persistence and tool activation in isolated projects.
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using ASEShaderConverter.Editor;
using CH.CustomTools.Paths;
using CH.CustomTools.Paths.Editor;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using Object = UnityEngine.Object;

public static class UnitySceneToolsSmoke
{
    const BindingFlags Flags = BindingFlags.Static | BindingFlags.Public | BindingFlags.NonPublic;
    const string Prefix = "CH.CustomTools.SceneShortcut.";
    [Serializable] sealed class Report { public string unity, version, status, failure; public int count; public string[] passed; }
    static readonly List<string> checks = new List<string>();
    static readonly Dictionary<string, int?> preferences = new Dictionary<string, int?>();
    static SceneView view;
    static BezierPath path;
    static Type settings, measurement;
    static Vector2 point, incoming, outgoing, inputOffset, received;
    static bool calibrating, gotMove;
    static int phase;
    static double next, deadline;
    static string before, errors;
    static Vector3 oldOutgoing;
    static void Check(bool value, string message) { if (!value) throw new Exception(message); checks.Add(message); }
    static bool Measure { get { return (bool)measurement.GetProperty("Active", Flags).GetValue(null); } set { measurement.GetProperty("Active", Flags).SetValue(null, value); } }
    static object Call(string name, params object[] args) { return settings.GetMethod(name, Flags).Invoke(null, args); }
    public static void Run()
    {
        CHValidationInput.Install();
        try
        {
            PlayerSettings.runInBackground = true;
            settings = typeof(ASEShaderConverterWindow).Assembly.GetType("ASEShaderConverter.Editor.CHSceneToolSettings", true);
            measurement = typeof(ASEShaderConverterWindow).Assembly.GetType("CH.CustomTools.Measurement.DmSceneTool", true);
            foreach (string name in new[] { "measurement.key", "measurement.mods", "path.key", "path.mods" })
            { string key = Prefix + name; preferences[key] = EditorPrefs.HasKey(key) ? (int?)EditorPrefs.GetInt(key) : null; }
            Call("Reset"); EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);
            path = new GameObject("Scene tool fixture").AddComponent<BezierPath>();
            path.knots = new List<PathKnot> { new PathKnot(new Vector3(-4, -2, 0)), new PathKnot(new Vector3(0, 2, 0)), new PathKnot(new Vector3(4, -2, 0)) };
            Geometry();
            ASEShaderConverterWindow.OpenPathTools(); PathSceneTool.Active = false; Measure = false;
            Selection.activeGameObject = path.gameObject;
            view = EditorWindow.GetWindow<SceneView>(); view.position = new Rect(30, 30, 1000, 780); view.Show(); view.LookAtDirect(Vector3.zero, Quaternion.LookRotation(Vector3.forward), 6); view.orthographic = true; view.Focus();
            SceneView.duringSceneGui += Capture; Application.logMessageReceived += Log;
            next = EditorApplication.timeSinceStartup + 3; deadline = next + 90; EditorApplication.update += Tick;
        }
        catch (Exception e) { Finish(e); }
    }
    static void Geometry()
    {
        string original = JsonUtility.ToJson(path);
        Undo.IncrementCurrentGroup(); PathKnotEditing.SetMode(path, -1, 0); Undo.FlushUndoRecordObjects();
        Check(path.knots.All(k => !k.automatic && k.incoming == Vector3.zero && k.outgoing == Vector3.zero), "Whole-path linear mode creates hard corners");
        for (int segment = 0; segment < path.SegmentCount; segment++)
        {
            Vector3 a = path.knots[segment].position, b = path.knots[segment + 1].position;
            for (int i = 0; i <= 20; i++) { Vector3 p, t; path.Cubic(segment, i / 20f, out p, out t); Check(Vector3.Cross(p - a, b - a).magnitude < .0001f, "Linear segment remains on its line: " + segment + "/" + i); }
        }
        Check(Mathf.Abs(path.Length - 2 * Mathf.Sqrt(32)) < .0001f, "Linear corner arc length is the sum of its edges");
        Undo.PerformUndo(); Check(JsonUtility.ToJson(path) == original, "Point-type conversion is undoable");
        Undo.PerformRedo(); Check(PathKnotEditing.Mode(path, 1) == 0, "Point-type conversion is redoable");
        Undo.IncrementCurrentGroup(); PathKnotEditing.SetMode(path, 1, 2); Undo.FlushUndoRecordObjects();
        Check(!path.knots[1].automatic && path.knots[1].incoming.sqrMagnitude > .01f && path.knots[1].outgoing.sqrMagnitude > .01f, "Bezier corner restores two independent handles from a hard corner");
        var oldIn = path.knots[1].incoming; var oldOut = path.knots[1].outgoing;
        path.transform.localScale = new Vector3(2, .8f, 3); path.transform.rotation = Quaternion.Euler(15, 20, 30);
        var world = path.transform.TransformPoint(path.knots[1].position + new Vector3(-1, .5f, 0));
        Undo.IncrementCurrentGroup(); PathKnotEditing.MoveTangent(path, 1, false, world); Undo.FlushUndoRecordObjects();
        Check(Vector3.Distance(path.knots[1].incoming, new Vector3(-1, .5f, 0)) < .0001f && path.knots[1].outgoing == oldOut, "Moving incoming tangent preserves outgoing under rotated/nonuniform transform");
        Undo.PerformUndo(); Check(path.knots[1].incoming == oldIn && path.knots[1].outgoing == oldOut, "Independent tangent change supports Undo");
        Undo.PerformRedo(); Check(path.knots[1].outgoing == oldOut, "Independent tangent change supports Redo");
        Directory.CreateDirectory("Assets/SceneTools064"); EditorSceneManager.SaveScene(UnityEngine.SceneManagement.SceneManager.GetActiveScene(), "Assets/SceneTools064/Types.unity");
        string saved = JsonUtility.ToJson(path); EditorSceneManager.OpenScene("Assets/SceneTools064/Types.unity"); path = GameObject.Find("Scene tool fixture").GetComponent<BezierPath>();
        Check(JsonUtility.ToJson(path) == saved, "Linear and independent corner tangents survive save/reopen without a new runtime schema");
        path.transform.localScale = Vector3.one; path.transform.rotation = Quaternion.identity;
        PathKnotEditing.SetMode(path, -1, 1); PathKnotEditing.SetMode(path, 1, 2); Undo.FlushUndoRecordObjects();
        Check(path.knots[0].automatic && path.knots[2].automatic && !path.knots[1].automatic, "Smooth and independent corners can coexist on a path");
    }
    static Vector2 WindowPoint(Vector3 world) { return GUIUtility.GUIToScreenPoint(HandleUtility.WorldToGUIPoint(world)) - view.position.position; }
    static void Capture(SceneView scene)
    {
        if (scene != view) return;
        if (calibrating && Event.current.type == EventType.MouseMove) { received = Event.current.mousePosition; gotMove = true; }
        if (Event.current.type != EventType.Repaint) return;
        point = WindowPoint(path.transform.TransformPoint(path.knots[1].position)); incoming = WindowPoint(path.transform.TransformPoint(path.Handle(1, false))); outgoing = WindowPoint(path.transform.TransformPoint(path.Handle(1, true)));
    }
    static void Log(string message, string stack, LogType type) { if (type == LogType.Error || type == LogType.Exception || type == LogType.Assert) errors = message + "\n" + stack; }
    static void Mouse(EventType type, Vector2 position, bool shift = false, bool ctrl = false)
    { CHValidationInput.Send(view, new Event { type = type, button = 0, mousePosition = position + inputOffset, shift = shift, control = ctrl }); view.Repaint(); }
    static void Key(KeyCode key, EventModifiers modifiers, bool release = true)
    {
        view.Focus(); CHValidationInput.Send(view, new Event { type = EventType.KeyDown, keyCode = key, modifiers = modifiers });
        if (release) CHValidationInput.Send(view, new Event { type = EventType.KeyUp, keyCode = key, modifiers = modifiers });
    }
    static bool DraftActive => (bool)typeof(PathSceneTool).Assembly.GetType("CH.CustomTools.Paths.Editor.PathFenceDraft")
        .GetProperty("Active", BindingFlags.Static | BindingFlags.Public | BindingFlags.NonPublic).GetValue(null);
    static void Tick()
    {
        try
        {
            if (EditorApplication.timeSinceStartup > deadline) throw new TimeoutException("Scene activation test timed out");
            if (EditorApplication.isCompiling || EditorApplication.timeSinceStartup < next) return;
            if (errors != null) throw new Exception(errors);
            next = EditorApplication.timeSinceStartup + .7;
            switch (phase++)
            {
                case 0:
                    calibrating = true; Mouse(EventType.MouseMove, point); calibrating = false; Check(gotMove, "Scene input calibration"); inputOffset = point - received;
                    before = JsonUtility.ToJson(path);
                    Mouse(EventType.MouseDown, point, true); Mouse(EventType.MouseDrag, point + new Vector2(90, -40), true); Mouse(EventType.MouseUp, point + new Vector2(90, -40), true);
                    Mouse(EventType.MouseDown, new Vector2(200, 200), ctrl: true); Mouse(EventType.MouseUp, new Vector2(200, 200), ctrl: true);
                    Check(JsonUtility.ToJson(path) == before && !PathPointDrag.IsDragging, "Disabled path mode captures no drag or Ctrl insertion");
                    Key(KeyCode.S, EventModifiers.Alt, false); Check(DraftActive && !Measure, "Alt+S starts drawing and disables measurement");
                    Key(KeyCode.S, EventModifiers.Alt, false); Check(DraftActive, "Held shortcut key does not repeatedly toggle the tool");
                    CHValidationInput.Send(view, new Event { type = EventType.KeyUp, keyCode = KeyCode.S, alt = true }); break;
                case 1:
                    Key(KeyCode.S, EventModifiers.Alt); Check(!DraftActive, "Alt+S stops drawing");
                    Key(KeyCode.D, EventModifiers.Alt); Check(Measure && !PathSceneTool.Active, "Alt+D enables measurement");
                    Key(KeyCode.S, EventModifiers.Alt); Check(!Measure && DraftActive, "Path shortcut switches exclusively from measurement");
                    Key(KeyCode.D, EventModifiers.Alt); Check(Measure && !PathSceneTool.Active && !DraftActive, "Measurement shortcut switches exclusively from path");
                    Key(KeyCode.D, EventModifiers.Alt); Check(!Measure, "Alt+D disables measurement");
                    Check(!(bool)Call("SetBinding", false, KeyCode.D, EventModifiers.Alt), "Duplicate shortcuts are rejected");
                    Check(!(bool)Call("SetBinding", false, KeyCode.K, EventModifiers.None), "Unmodified text keys are rejected");
                    Check((bool)Call("SetBinding", false, KeyCode.K, EventModifiers.Control | EventModifiers.Shift), "Custom path shortcut can be saved");
                    Key(KeyCode.S, EventModifiers.Alt); Check(!DraftActive, "Old default no longer activates after rebinding");
                    Key(KeyCode.K, EventModifiers.Control | EventModifiers.Shift); Check(DraftActive, "Custom shortcut activates the path tool");
                    Check(EditorPrefs.GetInt(Prefix + "path.key") == (int)KeyCode.K, "Custom shortcut is persisted on this computer");
                    Key(KeyCode.K, EventModifiers.Control | EventModifiers.Shift); Check(!DraftActive, "Custom shortcut disables the path tool");
                    Call("Reset"); Key(KeyCode.S, EventModifiers.Alt); Check(DraftActive, "Reset restores Alt+S"); Key(KeyCode.S, EventModifiers.Alt); PathSceneTool.Edit(path); Selection.activeGameObject = path.gameObject;
                    Mouse(EventType.MouseDown, point); Mouse(EventType.MouseUp, point); break;
                case 2:
                    oldOutgoing = path.knots[1].outgoing; before = JsonUtility.ToJson(path);
                    Mouse(EventType.MouseMove, incoming); Mouse(EventType.MouseDown, incoming); Mouse(EventType.MouseDrag, incoming + new Vector2(-40, -45)); Mouse(EventType.MouseUp, incoming + new Vector2(-40, -45)); Undo.FlushUndoRecordObjects();
                    Check(path.knots[1].outgoing == oldOutgoing && JsonUtility.ToJson(path) != before, "Actual square tangent handle drags independently in Scene"); break;
                case 3:
                    Undo.PerformUndo(); Check(JsonUtility.ToJson(path) == before, "Actual square tangent drag is undoable; actual=" + JsonUtility.ToJson(path) + "; expected=" + before);
                    Mouse(EventType.MouseMove, point); Mouse(EventType.MouseDown, point); Mouse(EventType.MouseUp, point);
                    break;
                case 4:
                    Mouse(EventType.MouseMove, incoming, ctrl: true);
                    Mouse(EventType.MouseDown, incoming, ctrl: true);
                    Mouse(EventType.MouseDrag, incoming + new Vector2(-40, -45), ctrl: true);
                    Mouse(EventType.MouseUp, incoming + new Vector2(-40, -45), ctrl: true);
                    Undo.FlushUndoRecordObjects();
                    var chord = path.transform.TransformVector(path.knots[1].position - path.knots[0].position).normalized;
                    var start = path.transform.TransformPoint(path.knots[0].position);
                    for (int i = 1; i < 10; i++)
                    {
                        path.Cubic(0, i / 10f, out var sample, out _);
                        if (Vector3.Cross(sample - start, chord).magnitude > .0001f)
                            throw new Exception("Ctrl-dragged tangent still curves");
                    }
                    Check(path.knots[1].outgoing == oldOutgoing && JsonUtility.ToJson(path) != before,
                        "Ctrl-dragging a tangent straightens exactly one segment");
                    Undo.PerformUndo(); Check(JsonUtility.ToJson(path) == before, "Ctrl tangent adjustment is undoable");
                    Mouse(EventType.MouseMove, point, true); Mouse(EventType.MouseDown, point, true); Mouse(EventType.MouseDrag, point + new Vector2(80, -30), true);
                    Check(PathPointDrag.IsDragging && path.knots.Count == 4, "Begin active Shift gesture before disabling");
                    Key(KeyCode.S, EventModifiers.Alt); break;
                case 5:
                    Mouse(EventType.MouseMove, point);
                    Check(!PathSceneTool.Active && !PathPointDrag.IsDragging && JsonUtility.ToJson(path) == before, "Disabling via shortcut cancels the gesture and releases Scene input");
                    Key(KeyCode.S, EventModifiers.Alt); ASEShaderConverterWindow.OpenUpdates();
                    Check(!PathSceneTool.Active && !DraftActive, "Leaving the path page disables path editing and drawing");
                    Key(KeyCode.D, EventModifiers.Alt);
                    foreach (var window in Resources.FindObjectsOfTypeAll<ASEShaderConverterWindow>()) window.Close();
                    break;
                case 6:
                    // Unity 6 completes closing windows in a later Editor loop.
                    Check(!Measure, "Closing the host disables measurement");
                    Key(KeyCode.S, EventModifiers.Alt);
                    foreach (var window in Resources.FindObjectsOfTypeAll<ASEShaderConverterWindow>()) window.Close();
                    break;
                case 7:
                    Check(!PathSceneTool.Active, "Closing the host disables path editing");
                    Check(errors == null, "Scene settings, types and tool gestures finish without Editor errors"); Finish(null); return;
            }
        }
        catch (Exception e) { Finish(e); }
    }
    static void Finish(Exception failure)
    {
        EditorApplication.update -= Tick; SceneView.duringSceneGui -= Capture; Application.logMessageReceived -= Log;
        PathSceneTool.Active = false; if (measurement != null) Measure = false;
        foreach (var window in Resources.FindObjectsOfTypeAll<ASEShaderConverterWindow>()) window.Close();
        foreach (var pref in preferences) { if (pref.Value.HasValue) EditorPrefs.SetInt(pref.Key, pref.Value.Value); else EditorPrefs.DeleteKey(pref.Key); }
        if (settings != null) settings.GetField("loaded", Flags).SetValue(null, false);
        Directory.CreateDirectory("Artifacts"); File.WriteAllText("Artifacts/scene-tools.json", JsonUtility.ToJson(new Report { unity = Application.unityVersion, version = UnityEditor.PackageManager.PackageInfo.FindForAssembly(typeof(BezierPath).Assembly).version, status = failure == null ? "Passed" : "Failed", failure = failure == null ? "" : failure.ToString(), count = checks.Count, passed = checks.ToArray() }, true));
        EditorApplication.Exit(failure == null ? 0 : 1);
    }
}
