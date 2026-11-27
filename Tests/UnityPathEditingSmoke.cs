// Exercises the host selection button, Scene point input and each knot's three-axis rotation.
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

public static class UnityPathEditingSmoke
{
    const BindingFlags F = BindingFlags.Instance | BindingFlags.Static | BindingFlags.Public | BindingFlags.NonPublic;
    [Serializable] sealed class Report { public string unity, version, status, failure; public int count; public string[] passed; }
    static readonly List<string> checks = new List<string>();
    static BezierPath path; static GameObject model; static SceneView view; static ASEShaderConverterWindow host;
    static object panel; static int phase; static double next, deadline; static string errors, before;
    static Vector2 point, inputOffset, received; static bool calibrating, gotMove;
    static float ringRadius;
    static int rotationTrial; static Vector2 rotationStart, rotationEnd;
    static Vector3[] previewBefore;
    static float frameSize;
    static Quaternion frameRotation;
    static string afterDelete;
    static void Check(bool ok, string message) { if (!ok) throw new Exception(message); checks.Add(message); }
    static object Get(object target, string name) { return target.GetType().GetField(name, F).GetValue(target); }
    static void Set(object target, string name, object value) { target.GetType().GetField(name, F).SetValue(target, value); }
    static void Refresh() { typeof(PathAuthoringPreview).GetField("next", F).SetValue(null, 0d); typeof(PathAuthoringPreview).GetMethod("Tick", F).Invoke(null, null); }
    public static void Run()
    {
        CHValidationInput.Install();
        try
        {
            PlayerSettings.runInBackground = true;
            EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);
            path = new GameObject("Editable path").AddComponent<BezierPath>();
            path.knots = new List<PathKnot> { new PathKnot(new Vector3(-4, -2, 0)), new PathKnot(new Vector3(0, 2, 0)), new PathKnot(new Vector3(4, -2, 0)) };
            model = GameObject.CreatePrimitive(PrimitiveType.Cube); model.name = "Placement source"; model.transform.position = new Vector3(30, 0, 0);
            var material = new Material(Shader.Find("Unlit/Color")) { color = Color.red }; model.GetComponent<Renderer>().sharedMaterial = material;
            ASEShaderConverterWindow.OpenPathTools(); host = Resources.FindObjectsOfTypeAll<ASEShaderConverterWindow>().Single(); host.position = new Rect(120, 40, 1140, 900);
            panel = Get(host, "paths"); Set(panel, "path", path); Set(panel, "model", model); Set(panel, "material", material);
            PathSceneTool.Active = false; Selection.activeGameObject = path.gameObject;
            view = EditorWindow.GetWindow<SceneView>(); view.position = new Rect(30, 30, 1000, 780); view.Show(); view.LookAtDirect(Vector3.zero, Quaternion.LookRotation(Vector3.forward), 6); view.orthographic = true; view.Focus();
            SceneView.duringSceneGui += Capture; Application.logMessageReceived += Log;
            next = EditorApplication.timeSinceStartup + 3; deadline = next + 160; EditorApplication.update += Tick;
        }
        catch (Exception e) { Finish(e); }
    }
    static void Capture(SceneView scene)
    {
        if (scene != view) return;
        if (calibrating && Event.current.type == EventType.MouseMove) { received = Event.current.mousePosition; gotMove = true; }
        if (Event.current.type == EventType.Repaint)
        {
            var world = path.transform.TransformPoint(path.knots[1].position);
            point = GUIUtility.GUIToScreenPoint(HandleUtility.WorldToGUIPoint(world)) - view.position.position;
            ringRadius = Vector2.Distance(HandleUtility.WorldToGUIPoint(world), HandleUtility.WorldToGUIPoint(world + view.camera.transform.right * HandleUtility.GetHandleSize(world)));
        }
    }
    static void Mouse(EventType type, Vector2 at, Vector2 delta = default(Vector2)) { CHValidationInput.Send(view, new Event { type = type, button = 0, mousePosition = at + inputOffset, delta = delta }); view.Repaint(); }
    static void ClickSelectionButton()
    {
        Rect screen = (Rect)Get(panel, "useSelectionArea"); Check(screen.width > 100, "Path selection action is rendered in the real host");
        Vector2 at = screen.center - host.position.position;
        host.SendEvent(new Event { type = EventType.MouseDown, button = 0, mousePosition = at });
        host.SendEvent(new Event { type = EventType.MouseUp, button = 0, mousePosition = at }); host.Repaint();
    }
    static void Log(string message, string stack, LogType type) { if (type == LogType.Error || type == LogType.Exception || type == LogType.Assert) errors = message + "\n" + stack; }
    static void Tick()
    {
        try
        {
            if (EditorApplication.timeSinceStartup > deadline) throw new TimeoutException("Path editing regression timed out");
            if (EditorApplication.isCompiling || EditorApplication.timeSinceStartup < next) return;
            if (errors != null) throw new Exception(errors); next = EditorApplication.timeSinceStartup + .8;
            switch (phase++)
            {
                case 0:
                    ClickSelectionButton(); Check(!PathSceneTool.Active, "Choosing a path while disabled does not bypass the explicit editing switch");
                    PathSceneTool.Edit(path); break;
                case 1:
                    ClickSelectionButton(); Check(PathSceneTool.Active && PathSceneTool.EditingPath == path, "Use selected path keeps an already-enabled tool enabled");
                    Selection.activeGameObject = model; break;
                case 2:
                    Check(PathPointInsertion.SelectedPath() == path && PathSceneTool.EditingPath == path, "Selecting the model keeps the current editing path and point handles");
                    Check(PathAuthoringPreview.IsActive && PathAuthoringPreview.ModelDrawCount > 0 && PathAuthoringPreview.PreviewMesh != null, "Actual host displays both model and mesh previews while the model is selected");
                    calibrating = true; Mouse(EventType.MouseMove, point); calibrating = false; Check(gotMove, "Scene input calibration"); inputOffset = point - received;
                    before = JsonUtility.ToJson(path); previewBefore = PathAuthoringPreview.PreviewMesh.vertices;
                    Mouse(EventType.MouseDown, point); Mouse(EventType.MouseDrag, point + new Vector2(60, -35)); Mouse(EventType.MouseUp, point + new Vector2(60, -35)); Undo.FlushUndoRecordObjects();
                    Check(JsonUtility.ToJson(path) != before && !PathPointDrag.IsDragging, "Actual point drag edits the pinned path after choosing a model"); break;
                case 3:
                    Check(!PathAuthoringPreview.PreviewMesh.vertices.SequenceEqual(previewBefore), "Point drag immediately rebuilds the live mesh");
                    Undo.PerformUndo(); Check(JsonUtility.ToJson(path) == before, "One Undo restores the entire point gesture");
                    break;
                case 4:
                    Mouse(EventType.MouseDown, point); Mouse(EventType.MouseUp, point);
                    view.Focus(); CHValidationInput.Send(view, new Event { type = EventType.KeyDown, keyCode = KeyCode.E }); CHValidationInput.Send(view, new Event { type = EventType.KeyUp, keyCode = KeyCode.E });
                    Check(BezierPathEditor.RotatePoints, "E switches the focused path point to its three-axis rotation handle"); break;
                case 5:
                    PrepareRotationTrial(); next = EditorApplication.timeSinceStartup + .2; break;
                case 6:
                    if (!RotateHandle()) { phase = 5; next = EditorApplication.timeSinceStartup + .2; break; }
                    // Undo clears the focused knot. Select the middle marker again before framing.
                    Mouse(EventType.MouseMove, point); Mouse(EventType.MouseDown, point); Mouse(EventType.MouseUp, point);
                    frameSize = view.size;
                    frameRotation = view.rotation;
                    view.Focus();
                    CHValidationInput.Send(view, new Event { type = EventType.KeyDown, keyCode = KeyCode.F });
                    CHValidationInput.Send(view, new Event { type = EventType.KeyUp, keyCode = KeyCode.F });
                    break;
                case 7:
                    Check(Vector3.Distance(view.pivot, path.transform.TransformPoint(path.knots[1].position)) < .01f, "F frames the selected middle knot, away from the path origin");
                    Check(Mathf.Abs(view.size - frameSize) < .01f && Quaternion.Angle(view.rotation, frameRotation) < .05f, "Framing keeps the Scene zoom and viewing direction");
                    view.LookAtDirect(Vector3.zero, frameRotation, frameSize);
                    CHValidationInput.Send(view, EditorGUIUtility.CommandEvent("FrameSelected"));
                    break;
                case 8:
                    Check(Vector3.Distance(view.pivot, path.transform.TransformPoint(path.knots[1].position)) < .01f, "Unity's Frame Selected command frames the focused knot");
                    before = JsonUtility.ToJson(path);
                    previewBefore = PathAuthoringPreview.PreviewMesh.vertices;
                    var endpoints = new[] { path.knots[0].position, path.knots[2].position };
                    view.Focus();
                    CHValidationInput.Send(view, new Event { type = EventType.KeyDown, keyCode = KeyCode.Delete });
                    CHValidationInput.Send(view, new Event { type = EventType.KeyUp, keyCode = KeyCode.Delete });
                    Check(path != null && path.knots.Select(k => k.position).SequenceEqual(endpoints),
                        "Scene Delete removes only the selected middle knot");
                    afterDelete = JsonUtility.ToJson(path);
                    break;
                case 9:
                    Check(!PathAuthoringPreview.PreviewMesh.vertices.SequenceEqual(previewBefore), "Deleting a path point refreshes the live mesh");
                    CHValidationInput.Send(view, EditorGUIUtility.CommandEvent("SoftDelete"));
                    Check(path != null && JsonUtility.ToJson(path) == afterDelete, "The open path minimum consumes Delete without deleting the object");
                    Undo.PerformUndo();
                    Check(JsonUtility.ToJson(path) == before, "One Undo restores the exact deleted knot");
                    Undo.PerformRedo();
                    Check(JsonUtility.ToJson(path) == afterDelete, "One Redo removes the same knot");
                    Undo.PerformUndo();
                    path.closed = true;
                    path.Invalidate();
                    break;
                case 10:
                    Mouse(EventType.MouseMove, point); Mouse(EventType.MouseDown, point); Mouse(EventType.MouseUp, point);
                    string closedPath = JsonUtility.ToJson(path);
                    CHValidationInput.Send(view, EditorGUIUtility.CommandEvent("Delete"));
                    Check(path != null && JsonUtility.ToJson(path) == closedPath, "The closed path minimum consumes Delete without deleting the object");
                    RotateEveryPoint(); Selection.activeObject = null; break;
                case 11:
                    Check(PathPointInsertion.SelectedPath() == path, "Deselecting Hierarchy objects retains the explicitly enabled editing target");
                    PathSceneTool.Active = false; Check(!PathAuthoringPreview.IsActive && PathSceneTool.EditingPath == null, "Explicitly disabling releases the target and all previews");
                    Check(errors == null, "Selection, gestures and three-axis point rotations finish without Editor errors"); Finish(null); return;
            }
            host.Repaint(); view.Repaint();
        }
        catch (Exception e) { Finish(e); }
    }
    static void PrepareRotationTrial()
    {
        if (rotationTrial >= 72) throw new Exception("No rotation ring accepted the Scene drag");
        float radius = new[] { .8f, 1f, .9f, .7f, 1.1f, .6f }[rotationTrial / 12]; int angle = 15 + 30 * (rotationTrial % 12);
        float a = angle * Mathf.Deg2Rad, b = (angle + 35) * Mathf.Deg2Rad;
        rotationStart = point + new Vector2(Mathf.Cos(a), Mathf.Sin(a)) * ringRadius * radius;
        rotationEnd = point + new Vector2(Mathf.Cos(b), Mathf.Sin(b)) * ringRadius * radius;
        Mouse(EventType.MouseMove, rotationStart); rotationTrial++;
    }
    static bool RotateHandle()
    {
        string original = JsonUtility.ToJson(path); var positions = path.knots.Select(k => k.position).ToArray();
        Mouse(EventType.MouseDown, rotationStart); Mouse(EventType.MouseDrag, rotationEnd, rotationEnd - rotationStart); Mouse(EventType.MouseUp, rotationEnd); Undo.FlushUndoRecordObjects();
        if (JsonUtility.ToJson(path) == original) return false;
        Check(path.knots.Select(k => k.position).SequenceEqual(positions), "Actual Scene rotation ring changes point orientation without moving knots");
        Undo.PerformUndo(); Check(JsonUtility.ToJson(path) == original, "Actual three-axis rotation gesture supports one Undo");
        view.Focus(); CHValidationInput.Send(view, new Event { type = EventType.KeyDown, keyCode = KeyCode.W }); CHValidationInput.Send(view, new Event { type = EventType.KeyUp, keyCode = KeyCode.W });
        Check(!BezierPathEditor.RotatePoints, "W returns the point handle to Move");
        return true;
    }
    static void RotateEveryPoint()
    {
        path.transform.rotation = Quaternion.Euler(15, 25, 8); path.transform.localScale = new Vector3(2, .8f, 1.5f); path.Invalidate();
        foreach (bool closed in new[] { false, true })
        {
            path.closed = closed; path.Invalidate();
            for (int i = 0; i < path.knots.Count; i++)
            {
                string original = JsonUtility.ToJson(path); Vector3[] positions = path.knots.Select(k => k.position).ToArray();
                var current = PathKnotEditing.Rotation(path, i);
                var desired = Quaternion.Euler(23, -18, 11) * current * Quaternion.Euler(0, 0, 27);
                Refresh(); Vector3[] vertices = PathAuthoringPreview.PreviewMesh.vertices;
                Undo.IncrementCurrentGroup(); PathKnotEditing.SetRotation(path, i, desired); Undo.FlushUndoRecordObjects(); Refresh();
                Check(Quaternion.Angle(PathKnotEditing.Rotation(path, i), desired) < .05f, "Full XYZ rotation reaches requested orientation: " + closed + "/" + i);
                Check(path.knots.Select(k => k.position).SequenceEqual(positions), "Rotation preserves every knot position: " + closed + "/" + i);
                Check(!path.knots[i].automatic && !PathAuthoringPreview.PreviewMesh.vertices.SequenceEqual(vertices), "Each point changes its tangent and live mesh: " + closed + "/" + i);
                Undo.PerformUndo(); Check(JsonUtility.ToJson(path) == original, "XYZ point rotation supports one Undo: " + closed + "/" + i);
                Undo.PerformRedo(); Check(Quaternion.Angle(PathKnotEditing.Rotation(path, i), desired) < .05f, "XYZ point rotation supports Redo: " + closed + "/" + i);
                Undo.PerformUndo(); Refresh();
            }
        }
        path.closed = false; path.transform.rotation = Quaternion.identity; path.transform.localScale = Vector3.one; path.Invalidate();
        PathKnotEditing.SetMode(path, -1, 0);
        for (int i = 0; i < path.knots.Count; i++)
        {
            var rotation = PathKnotEditing.Rotation(path, i); PathKnotEditing.SetRotation(path, i, rotation * Quaternion.Euler(0, 0, 35));
            Check(PathKnotEditing.Mode(path, i) == 0 && Mathf.Abs(path.knots[i].roll - 35) < .01f, "Bank-only rotation keeps a hard corner linear: " + i);
        }
    }
    static void Finish(Exception error)
    {
        EditorApplication.update -= Tick; SceneView.duringSceneGui -= Capture; Application.logMessageReceived -= Log;
        PathSceneTool.Active = false; if (host != null) host.Close();
        Directory.CreateDirectory("Artifacts"); File.WriteAllText("Artifacts/path-editing.json", JsonUtility.ToJson(new Report { unity = Application.unityVersion, version = UnityEditor.PackageManager.PackageInfo.FindForAssembly(typeof(BezierPath).Assembly).version, status = error == null ? "Passed" : "Failed", failure = error == null ? "" : error.ToString(), count = checks.Count, passed = checks.ToArray() }, true));
        EditorApplication.Exit(error == null ? 0 : 1);
    }
}
