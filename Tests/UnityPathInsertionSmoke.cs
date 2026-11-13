// Exact subdivision, shared Scene visuals, Ctrl insertion and Shift/direct point dragging in disposable projects.
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
    static GameObject otherSelection;
    static Mesh savedMesh;
    static string original, inserted, errors;
    static Vector2 hit, axis, destination, endpoint, pointScreen;
    static int phase;
    static double next, deadline;
    static bool captured;
    static bool calibrating, receivedMove;
    static Vector2 receivedPosition, inputOffset;
    static Vector2 lastMouse;
    static Vector2 gestureSource, gestureDestination;
    static int gestureIndex;
    static string beforeGesture, afterGesture;
    static Vector3 originalPoint;
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
            Guards(); DuplicationContracts();
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
    static void DuplicationContracts()
    {
        foreach (bool closed in new[] { false, true }) foreach (int source in new[] { 0, 1, 3 })
        {
            var p = PathAuthoring.Create(closed ? PathPreset.Circle : PathPreset.Curve, Vector3.one * 7);
            p.transform.localScale = new Vector3(2, .8f, 3); p.transform.rotation = Quaternion.Euler(20, 30, 10);
            var knot = p.knots[source]; knot.roll = 43; knot.automatic = false;
            knot.incoming = new Vector3(-1, 2, 3); knot.outgoing = new Vector3(4, 5, 6);
            Vector3 originalPosition = knot.position, destination = p.transform.TransformPoint(knot.position) + new Vector3(3, 2, 1);
            string before = JsonUtility.ToJson(p); int count = p.knots.Count;
            int added = PathPointDrag.Duplicate(p, source, destination); Undo.FlushUndoRecordObjects();
            Check(added == (!closed && source == 0 ? 0 : source + 1) && p.knots.Count == count + 1,
                "Shift duplication order: " + (closed ? "closed" : "open") + " source " + source);
            Check(knot.position == originalPosition && Vector3.Distance(p.transform.TransformPoint(p.knots[added].position), destination) < .00002f,
                "Duplication keeps source and places new point in world space under scaled/rotated path");
            Check(!p.knots[added].automatic && p.knots[added].roll == 43 && p.knots[added].incoming == knot.incoming && p.knots[added].outgoing == knot.outgoing,
                "Duplication preserves roll and manual tangent offsets");
            string after = JsonUtility.ToJson(p);
            Undo.PerformUndo(); Check(JsonUtility.ToJson(p) == before, "Duplicate and place uses one Undo");
            Undo.PerformRedo(); Check(JsonUtility.ToJson(p) == after, "Duplicate and place supports Redo");
            Object.DestroyImmediate(p.gameObject);
        }
        var invalid = PathAuthoring.Create(PathPreset.Straight, Vector3.zero); string originalState = JsonUtility.ToJson(invalid);
        Reject(() => PathPointDrag.Duplicate(invalid, -1, Vector3.one), "Reject invalid duplicate source");
        Reject(() => PathPointDrag.Duplicate(invalid, 0, new Vector3(float.NaN, 0, 0)), "Reject nonfinite duplicate destination");
        Reject(() => PathPointDrag.Duplicate(invalid, 0, invalid.transform.position), "Do not duplicate without a drag distance");
        Check(JsonUtility.ToJson(invalid) == originalState, "Rejected duplications leave the path intact");
        invalid.knots.Clear(); for (int i = 0; i < 512; i++) invalid.knots.Add(new PathKnot(Vector3.forward * i));
        Reject(() => PathPointDrag.Duplicate(invalid, 0, Vector3.right), "Shift duplication enforces 512-point limit");
        Object.DestroyImmediate(invalid.gameObject);
    }
    static void Capture(SceneView scene)
    {
        if (scene != view) return;
        if (calibrating && Event.current.type == EventType.MouseMove) { receivedMove = true; receivedPosition = Event.current.mousePosition; }
        if (Event.current.type != EventType.Repaint) return;
        if (gestureIndex >= 0 && gestureIndex < path.knots.Count)
        {
            gestureSource = WindowPoint(path.transform.TransformPoint(path.knots[gestureIndex].position));
            gestureDestination = gestureSource + new Vector2(90, -45);
        }
        hit = WindowPoint(new Vector3(0, -1.2f, 0)); endpoint = WindowPoint(new Vector3(0, -4, 0));
        if (path.knots.Count == 3)
        {
            Vector3 point = path.transform.TransformPoint(path.knots[1].position); float size = HandleUtility.GetHandleSize(point);
            pointScreen = WindowPoint(point);
            axis = WindowPoint(point + Vector3.right * size * .65f); destination = axis + new Vector2(65, 0);
        }
        captured = true;
    }
    // SendEvent uses window coordinates; Scene GUI is below Unity's toolbars/GUI clips.
    static Vector2 WindowPoint(Vector3 world) { return GUIUtility.GUIToScreenPoint(HandleUtility.WorldToGUIPoint(world)) - view.position.position; }
    static void Mouse(EventType type, Vector2 position, bool ctrl = false, bool shift = false, bool alt = false)
    {
        Vector2 sent = position + inputOffset;
        view.SendEvent(new Event { type = type, button = 0, mousePosition = sent, delta = type == EventType.MouseDrag ? sent - lastMouse : Vector2.zero, control = ctrl, shift = shift, alt = alt }); lastMouse = sent; view.Repaint();
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
                    Selection.activeGameObject = path.gameObject;
                    Mouse(EventType.MouseMove, pointScreen); phase = 20; break;
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
                    Check(errors == null, "Scene preview, insertion and drag render without GUI errors");
                    gestureIndex = path.knots.Count - 1; beforeGesture = JsonUtility.ToJson(path); originalPoint = path.knots[gestureIndex].position; break;
                case 6:
                    Mouse(EventType.MouseMove, gestureSource, shift: true); Mouse(EventType.MouseDown, gestureSource, shift: true); Mouse(EventType.MouseUp, gestureSource, shift: true);
                    Check(JsonUtility.ToJson(path) == beforeGesture, "Shift-click without dragging does not add or change a point"); break;
                case 7:
                    Mouse(EventType.MouseMove, gestureSource, shift: true); Mouse(EventType.MouseDown, gestureSource, shift: true);
                    Mouse(EventType.MouseDrag, gestureDestination, shift: true);
                    Mouse(EventType.MouseDrag, gestureDestination + Vector2.right * 20); Mouse(EventType.MouseUp, gestureDestination + Vector2.right * 20);
                    Undo.FlushUndoRecordObjects();
                    Check(path.knots.Count == 4 && path.knots[2].position == originalPoint, "Actual Shift-drag extends final endpoint and keeps source point");
                    Check(Vector3.Distance(path.knots[3].position, originalPoint) > .5f, "New point follows drag even after Shift is released");
                    afterGesture = JsonUtility.ToJson(path); break;
                case 8:
                    Undo.PerformUndo(); Check(JsonUtility.ToJson(path) == beforeGesture, "One Undo reverts the whole Shift-drag gesture");
                    Undo.PerformRedo(); Check(JsonUtility.ToJson(path) == afterGesture, "One Redo restores the final Shift-drag destination");
                    Undo.PerformUndo(); gestureIndex = 0; originalPoint = path.knots[0].position; break;
                case 9:
                    Mouse(EventType.MouseMove, gestureSource, shift: true); Mouse(EventType.MouseDown, gestureSource, shift: true);
                    Mouse(EventType.MouseDrag, gestureDestination, shift: true); Mouse(EventType.MouseUp, gestureDestination, shift: true); Undo.FlushUndoRecordObjects();
                    Check(path.knots.Count == 4 && path.knots[1].position == originalPoint && path.knots[0].position != originalPoint, "Actual Shift-drag extends before the first endpoint");
                    Undo.PerformUndo(); Check(JsonUtility.ToJson(path) == beforeGesture, "First-end extension is undoable"); gestureIndex = 1; break;
                case 10:
                    Mouse(EventType.MouseMove, gestureSource, shift: true); Mouse(EventType.MouseDown, gestureSource, shift: true); Mouse(EventType.MouseDrag, gestureDestination, shift: true);
                    Check(path.knots.Count == 4, "Interior Shift-drag creates a single point");
                    view.SendEvent(new Event { type = EventType.KeyDown, keyCode = KeyCode.Escape });
                    Check(JsonUtility.ToJson(path) == beforeGesture && !PathPointDrag.IsDragging, "Escape removes the draft point and restores the exact original path"); break;
                case 11:
                    originalPoint = path.knots[1].position;
                    Mouse(EventType.MouseMove, gestureSource); Mouse(EventType.MouseDown, gestureSource); Mouse(EventType.MouseDrag, gestureDestination); Mouse(EventType.MouseUp, gestureDestination); Undo.FlushUndoRecordObjects();
                    Check(path.knots.Count == 3 && Vector3.Distance(path.knots[1].position, originalPoint) > .5f, "Direct circular-marker drag moves a point without adding one");
                    Undo.PerformUndo(); Check(JsonUtility.ToJson(path) == beforeGesture, "Direct marker dragging is undoable in one step"); break;
                case 12:
                    Mouse(EventType.MouseMove, gestureSource, shift: true); Mouse(EventType.MouseDown, gestureSource, shift: true); Mouse(EventType.MouseDrag, gestureDestination, shift: true);
                    otherSelection = new GameObject("Selection cancellation"); Selection.activeGameObject = otherSelection; phase = 21; break;
                case 21:
                    // Allow the queued selectionChanged callback to run outside Scene GUI first.
                    Mouse(EventType.MouseMove, gestureDestination);
                    Check(!PathPointDrag.IsDragging, "Changing selection cancels a pending Shift-drag and releases input");
                    Check(JsonUtility.ToJson(path) == beforeGesture, "Selection cancellation restores the exact original path");
                    Object.DestroyImmediate(otherSelection); Selection.activeGameObject = path.gameObject; phase = 13; break;
                case 13:
                    Mouse(EventType.MouseMove, gestureSource, shift: true, alt: true); Mouse(EventType.MouseDown, gestureSource, shift: true, alt: true); Mouse(EventType.MouseUp, gestureSource, shift: true, alt: true);
                    Check(JsonUtility.ToJson(path) == beforeGesture, "Shift-drag yields to Alt camera controls");
                    Check(output.GetComponent<MeshFilter>().sharedMesh == savedMesh, "Shift and direct edits preserve existing output mesh until rebuild");
                    break;
                case 14:
                    Mouse(EventType.MouseMove, gestureSource, shift: true); Mouse(EventType.MouseDown, gestureSource, shift: true); Mouse(EventType.MouseDrag, gestureDestination, shift: true);
                    var measurement = typeof(ASEShaderConverterWindow).Assembly.GetType("CH.CustomTools.Measurement.DmSceneTool", true).GetProperty("Active", System.Reflection.BindingFlags.Public | System.Reflection.BindingFlags.Static);
                    measurement.SetValue(null, true); Mouse(EventType.MouseMove, gestureDestination);
                    Check(JsonUtility.ToJson(path) == beforeGesture && !PathPointDrag.IsDragging, "Measurement activation takes priority and cancels path dragging");
                    measurement.SetValue(null, false);
                    break;
                case 15:
                    Mouse(EventType.MouseMove, gestureSource, shift: true); Mouse(EventType.MouseDown, gestureSource, shift: true);
                    Mouse(EventType.MouseDrag, gestureDestination, shift: true); Mouse(EventType.MouseDrag, gestureSource, shift: true); Mouse(EventType.MouseUp, gestureSource, shift: true);
                    Check(JsonUtility.ToJson(path) == beforeGesture, "Dragging a new point back to its source cancels the empty extension"); break;
                case 16:
                    Mouse(EventType.MouseMove, gestureSource, shift: true); Mouse(EventType.MouseDown, gestureSource, shift: true); Mouse(EventType.MouseDrag, gestureDestination, shift: true);
                    Check(path.knots.Count == 4 && PathPointDrag.IsDragging, "Begin a real active Shift gesture before testing Ctrl+Z");
                    view.SendEvent(new Event { type = EventType.KeyDown, keyCode = KeyCode.Z, control = true }); break;
                case 17:
                    // Test the actual shortcut while the point owns Scene input.
                    Mouse(EventType.MouseMove, gestureSource);
                    Check(JsonUtility.ToJson(path) == beforeGesture && !PathPointDrag.IsDragging,
                        "Ctrl+Z during a drag restores the gesture and releases Scene input; dragging=" + PathPointDrag.IsDragging + "; actual=" + JsonUtility.ToJson(path) + "; expected=" + beforeGesture);
                    Check(errors == null, "Shared Scene markers, labels and all drag gestures render without GUI errors"); Finish(null); return;
                case 20:
                    Mouse(EventType.MouseDown, pointScreen); Mouse(EventType.MouseUp, pointScreen); phase = 3; break;
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
