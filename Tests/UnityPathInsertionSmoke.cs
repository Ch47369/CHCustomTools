// Exact subdivision plus actual SceneView Ctrl-click and handle drag in disposable projects.
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using ASEShaderConverter.Editor;
using CH.CustomTools.Paths;
using CH.CustomTools.Paths.Editor;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using Object = UnityEngine.Object;

public static class UnityPathInsertionSmoke
{
    [Serializable] sealed class Report { public string unity, version, status, failure; public int count; public string[] passed; }
    static readonly List<string> checks = new List<string>();
    static SceneView view;
    static ASEShaderConverterWindow window;
    static BezierPath path;
    static GameObject output;
    static Mesh savedMesh;
    static string original, inserted, errors;
    static Vector2 hit, axis, destination, endpoint;
    static int phase;
    static double next, deadline;
    static bool captured;
    static bool calibrating, receivedMove;
    static Vector2 receivedPosition, inputOffset;
    static Vector2 lastMouse;
    static void Check(bool value, string message) { if (!value) throw new Exception(message); checks.Add(message); }
    static void Reject(Action action, string message) { bool rejected = false; try { action(); } catch (Exception) { rejected = true; } Check(rejected, message); }
    public static void Run()
    {
        try
        {
            PlayerSettings.runInBackground = true;
            EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);
            foreach (var preset in new[] { PathPreset.Curve, PathPreset.Circle, PathPreset.Flight })
            {
                Shape(preset, 0, .27f);
                Shape(preset, preset == PathPreset.Curve ? 2 : 3, .73f);
            }
            Guards();
            path = new GameObject("Ctrl insertion path").AddComponent<BezierPath>();
            path.knots = new List<PathKnot> { new PathKnot(new Vector3(0, -4, 0)), new PathKnot(new Vector3(0, 4, 0)) };
            path.Invalidate(); original = JsonUtility.ToJson(path);
            output = PathAuthoring.Generate(path, new PathMeshSettings { twoSided = true }, null, null, "Assets"); savedMesh = output.GetComponent<MeshFilter>().sharedMesh;
            var child = new GameObject("Generated child selection"); child.transform.SetParent(output.transform, false); Selection.activeGameObject = child;
            Check(PathPointInsertion.SelectedPath() == path, "Generated child selection resolves its owning path");
            ASEShaderConverterWindow.OpenPathTools(); window = Resources.FindObjectsOfTypeAll<ASEShaderConverterWindow>().Single();
            view = EditorWindow.GetWindow<SceneView>(); view.position = new Rect(30, 30, 1000, 780); view.Show(); view.LookAtDirect(Vector3.zero, Quaternion.LookRotation(Vector3.forward), 6); view.orthographic = true; view.Focus();
            BezierPathEditor.SnapToSurface = false;
            SceneView.duringSceneGui += Capture; Application.logMessageReceived += Log;
            phase = 0; next = EditorApplication.timeSinceStartup + 2; deadline = next + 100; EditorApplication.update += Tick;
        }
        catch (Exception e) { Finish(e); }
    }
    static void Shape(PathPreset preset, int segment, float t)
    {
        var p = PathAuthoring.Create(preset, new Vector3(7, 8, 9));
        p.transform.localScale = new Vector3(2, .8f, 3); p.transform.rotation = Quaternion.Euler(25, 35, 5);
        p.knots[segment].roll = 30; p.knots[(segment + 1) % p.knots.Count].roll = 100;
        p.Invalidate(); float length = p.Length; string before = JsonUtility.ToJson(p); int segments = p.SegmentCount, count = p.knots.Count;
        var positions = new List<Vector3>();
        for (int s = 0; s < segments; s++) for (int j = 0; j <= 64; j++) { Vector3 point, tangent; p.Cubic(s, j / 64f, out point, out tangent); positions.Add(point); }
        int added = PathPointInsertion.Insert(p, segment, t); Undo.FlushUndoRecordObjects();
        Check(added == segment + 1 && p.knots.Count == count + 1, preset + " segment " + segment + ": point inserted in curve order");
        Check(!p.knots[segment].automatic && !p.knots[added].automatic && !p.knots[(added + 1) % p.knots.Count].automatic, preset + ": split neighbours use preserved manual handles");
        float error = 0; int index = 0;
        for (int s = 0; s < segments; s++) for (int j = 0; j <= 64; j++)
        {
            float parameter = j / 64f; int target = s < segment ? s : s > segment ? s + 1 : parameter <= t ? segment : segment + 1;
            if (s == segment) parameter = parameter <= t ? parameter / t : (parameter - t) / (1 - t);
            Vector3 actual, tangent; p.Cubic(target, parameter, out actual, out tangent); error = Mathf.Max(error, Vector3.Distance(actual, positions[index++]));
        }
        Check(error < .00006f, preset + " segment " + segment + ": every segment retains shape under nonuniform world transform; max " + error);
        Check(Mathf.Abs(p.Length - length) < .005f, preset + ": arc length retained within sampling tolerance");
        Check(Mathf.Abs(Mathf.DeltaAngle(p.knots[added].roll, Mathf.LerpAngle(30, 100, t))) < .0001f, preset + ": inserted point interpolates roll");
        string after = JsonUtility.ToJson(p);
        Undo.PerformUndo(); Check(JsonUtility.ToJson(p) == before, preset + ": one Undo restores exact original knots, handles, roll and modes");
        Undo.PerformRedo(); Check(JsonUtility.ToJson(p) == after, preset + ": Redo restores insertion");
        Object.DestroyImmediate(p.gameObject);
    }
    static void Guards()
    {
        var p = PathAuthoring.Create(PathPreset.Straight, Vector3.zero); string before = JsonUtility.ToJson(p);
        Reject(() => PathPointInsertion.Insert(p, 0, 0), "Reject insertion on first endpoint");
        Reject(() => PathPointInsertion.Insert(p, 0, 1), "Reject insertion on final endpoint");
        Reject(() => PathPointInsertion.Insert(p, -1, .5f), "Reject invalid segment");
        Reject(() => PathPointInsertion.Insert(p, 0, float.NaN), "Reject NaN parameter");
        Check(JsonUtility.ToJson(p) == before, "Rejected insertions preserve original path bytes");
        p.knots.Clear(); for (int i = 0; i < 512; i++) p.knots.Add(new PathKnot(Vector3.forward * i));
        Reject(() => PathPointInsertion.Insert(p, 0, .5f), "Enforce 512-point limit");
        Check(PathPointInsertion.InsertionModifier(new Event { control = true }) && !PathPointInsertion.InsertionModifier(new Event { control = true, alt = true }), "Ctrl insertion yields to Alt camera orbit");
        Object.DestroyImmediate(p.gameObject);
    }
    static void Capture(SceneView scene)
    {
        if (scene != view) return;
        if (calibrating && Event.current.type == EventType.MouseMove) { receivedMove = true; receivedPosition = Event.current.mousePosition; }
        if (Event.current.type != EventType.Repaint) return;
        hit = WindowPoint(new Vector3(0, -1.2f, 0)); endpoint = WindowPoint(new Vector3(0, -4, 0));
        if (path.knots.Count == 3)
        {
            Vector3 point = path.transform.TransformPoint(path.knots[1].position); float size = HandleUtility.GetHandleSize(point);
            axis = WindowPoint(point + Vector3.right * size * .65f); destination = axis + new Vector2(65, 0);
        }
        captured = true;
    }
    // SendEvent uses window coordinates; Scene GUI is below Unity's toolbars/GUI clips.
    static Vector2 WindowPoint(Vector3 world) { return GUIUtility.GUIToScreenPoint(HandleUtility.WorldToGUIPoint(world)) - view.position.position; }
    static void Mouse(EventType type, Vector2 position, bool ctrl = false)
    {
        Vector2 sent = position + inputOffset;
        view.SendEvent(new Event { type = type, button = 0, mousePosition = sent, delta = type == EventType.MouseDrag ? sent - lastMouse : Vector2.zero, control = ctrl }); lastMouse = sent; view.Repaint();
    }
    static void Log(string message, string stack, LogType type) { if (type == LogType.Exception || type == LogType.Error || type == LogType.Assert) errors = message + "\n" + stack; }
    static void Tick()
    {
        try
        {
            if (EditorApplication.timeSinceStartup > deadline) throw new TimeoutException("Scene insertion input test timed out");
            if (EditorApplication.isCompiling || EditorApplication.timeSinceStartup < next || !captured) return;
            if (errors != null) throw new Exception(errors);
            next = EditorApplication.timeSinceStartup + .6;
            switch (phase++)
            {
                case 0:
                    // Unity routes SendEvent through UI Toolkit toolbars before Scene GUI.
                    // Calibrate that public event coordinate translation instead of hardcoding pixels.
                    calibrating = true; Mouse(EventType.MouseMove, hit); calibrating = false;
                    if (!receivedMove) throw new Exception("SceneView did not receive calibration input");
                    inputOffset = hit - receivedPosition;
                    Mouse(EventType.MouseMove, hit, true); Check(path.knots.Count == 2, "Holding Ctrl and hovering does not add a point"); break;
                case 1:
                    Mouse(EventType.MouseDown, hit, true); Mouse(EventType.MouseUp, hit, true); Undo.FlushUndoRecordObjects();
                    Check(path.knots.Count == 3, "Actual Scene Ctrl-click inserts exactly one point from generated child selection");
                    Check(Selection.activeGameObject == path.gameObject, "Insertion selects the editable path");
                    Check(Vector3.Distance(path.knots[1].position, new Vector3(0, -1.2f, 0)) < .02f, "Screen picking inserts on the visible curve within one pixel; actual " + path.knots[1].position.ToString("F5"));
                    inserted = JsonUtility.ToJson(path); Check(output.GetComponent<MeshFilter>().sharedMesh == savedMesh, "Insertion retains existing generated mesh until explicit rebuild"); break;
                case 2:
                    Undo.PerformUndo(); Check(JsonUtility.ToJson(path) == original, "Actual Ctrl-click insertion is undoable in one step");
                    Undo.PerformRedo(); Check(JsonUtility.ToJson(path) == inserted, "Actual Ctrl-click insertion is redoable");
                    Selection.activeGameObject = path.gameObject; break;
                case 3:
                    Mouse(EventType.MouseMove, axis); Mouse(EventType.MouseDown, axis); Mouse(EventType.MouseDrag, destination); Mouse(EventType.MouseUp, destination); Undo.FlushUndoRecordObjects();
                    Check(Mathf.Abs(path.knots[1].position.x) > .1f, "New point moves through a real Scene position-handle drag; actual " + path.knots[1].position + "; editors " + string.Join(",", ActiveEditorTracker.sharedTracker.activeEditors.Select(e => e.GetType().Name)));
                    Check(path.knots.Count == 3, "Normal dragging does not insert additional points"); break;
                case 4:
                    Undo.PerformUndo(); Check(JsonUtility.ToJson(path) == inserted, "Dragging the inserted point is independently undoable");
                    Mouse(EventType.MouseMove, endpoint, true); Mouse(EventType.MouseDown, endpoint, true); Mouse(EventType.MouseUp, endpoint, true);
                    Check(path.knots.Count == 3, "Ctrl-click near an existing endpoint does not duplicate it");
                    Selection.activeGameObject = path.gameObject; break;
                case 5:
                    Mouse(EventType.MouseMove, new Vector2(16, 16), true); Mouse(EventType.MouseDown, new Vector2(16, 16), true); Mouse(EventType.MouseUp, new Vector2(16, 16), true);
                    Check(path.knots.Count == 3, "Ctrl-click away from the curve does not insert");
                    Check(errors == null, "Scene preview, insertion and drag render without GUI errors"); Finish(null); return;
            }
        }
        catch (Exception e) { Finish(e); }
    }
    static void Finish(Exception failure)
    {
        EditorApplication.update -= Tick; SceneView.duringSceneGui -= Capture; Application.logMessageReceived -= Log;
        if (window != null) window.Close();
        Directory.CreateDirectory("Artifacts"); File.WriteAllText("Artifacts/path-insertion.json", JsonUtility.ToJson(new Report { unity = Application.unityVersion, version = UnityEditor.PackageManager.PackageInfo.FindForAssembly(typeof(BezierPath).Assembly).version, status = failure == null ? "Passed" : "Failed", failure = failure == null ? null : failure.ToString(), count = checks.Count, passed = checks.ToArray() }, true));
        EditorApplication.Exit(failure == null ? 0 : 1);
    }
}
