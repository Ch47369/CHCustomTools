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
using UnityEngine.SceneManagement;
using Object = UnityEngine.Object;

[InitializeOnLoad]
public static class UnityPathToolsSmoke
{
    const string Key = "CH.Path060.Smoke";
    const BindingFlags Flags = BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public | BindingFlags.Static;
    [Serializable] sealed class State { public List<string> checks = new List<string>(); public int phase; public Vector3 original; public Quaternion rotation; public Vector3 scale; public double deadline; public bool hadLanguage; public string language; }
    [Serializable] sealed class Report { public string unity, version, status, failure; public int count; public string[] passed; }
    static State state;
    static ASEShaderConverterWindow window;
    static double next;
    static string errors;
    static UnityPathToolsSmoke() { if (!string.IsNullOrEmpty(SessionState.GetString(Key, ""))) EditorApplication.update += ResumeOnce; }
    static void ResumeOnce() { EditorApplication.update -= ResumeOnce; Resume(); }
    static void ExitOnce() { EditorApplication.update -= ExitOnce; EditorApplication.ExitPlaymode(); }
    static void Check(bool value, string name) { if (!value) throw new Exception(name); state.checks.Add(name); }
    static void Near(float actual, float expected, float tolerance, string name) { Check(Mathf.Abs(actual - expected) <= tolerance, name + " (" + actual + ")"); }
    static void Reject(Action action, string name) { bool failed = false; try { action(); } catch (Exception) { failed = true; } Check(failed, name); }
    static BezierPath Straight(float length = 10) { var p = new GameObject("Test path").AddComponent<BezierPath>(); p.knots = new List<PathKnot> { new PathKnot(Vector3.zero), new PathKnot(Vector3.forward * length) }; return p; }
    public static void Run()
    {
        state = new State { hadLanguage = EditorPrefs.HasKey("CH.CustomTools.Language"), language = EditorPrefs.GetString("CH.CustomTools.Language", "") };
        try
        {
            EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);
            PlayerSettings.runInBackground = true; Application.runInBackground = true;
            Geometry(); Meshes(); Models(); Motion();
            var path = PathAuthoring.Create(PathPreset.Flight, Vector3.zero); path.name = "Persisted flight path";
            var follower = PathAuthoring.FlightDemo(path); follower.name = "Runtime follower"; follower.speed = 4;
            follower.transform.position = new Vector3(31, 32, 33); follower.transform.rotation = Quaternion.Euler(10, 20, 30); follower.transform.localScale = new Vector3(1, 2, 3);
            state.original = follower.transform.position; state.rotation = follower.transform.rotation; state.scale = follower.transform.localScale;
            ASEShaderConverterWindow.OpenPathTools(); window = Resources.FindObjectsOfTypeAll<ASEShaderConverterWindow>().Single(); window.position = new Rect(50, 50, 900, 740);
            var panel = typeof(ASEShaderConverterWindow).GetField("paths", Flags).GetValue(window); panel.GetType().GetField("path", Flags).SetValue(panel, path); panel.GetType().GetField("motionTarget", Flags).SetValue(panel, follower.gameObject);
            state.phase = 0; next = EditorApplication.timeSinceStartup + 2; state.deadline = EditorApplication.timeSinceStartup + 240;
            Application.logMessageReceived += Log; EditorApplication.update += Tick;
        }
        catch (Exception e) { Finish(e); }
    }
    static void Geometry()
    {
        var line = Straight(); Near(line.Length, 10, .0001f, "Straight path world length"); Near(line.Evaluate(3).position.z, 3, .0001f, "Distance lookup on straight path");
        line.transform.localScale = new Vector3(2, 3, 4); Near(line.Length, 40, .001f, "Nonuniform transform scale invalidates world-distance cache");
        line.transform.rotation = Quaternion.Euler(0, 90, 0); Near(line.Evaluate(8).position.x, 8, .001f, "Rotation invalidates world-space samples");
        line.transform.position = new Vector3(5, 4, 3); Near(line.Evaluate(8).position.x, 13, .001f, "Translation invalidates world-space samples");
        line.knots[1].position = Vector3.forward * 5; Near(line.Length, 20, .001f, "Direct runtime knot edits invalidate cache");
        line.transform.localScale = Vector3.zero; Reject(() => { var l = line.Length; }, "Zero scale rejected"); Object.DestroyImmediate(line.gameObject);
        var vertical = Straight(); vertical.knots[1].position = Vector3.up * 10;
        Check(BezierPath.Finite(vertical.Evaluate(5).up) && Mathf.Abs(Vector3.Dot(vertical.Evaluate(5).up, Vector3.up)) < .0001f, "Vertical path has a finite perpendicular frame");
        Object.DestroyImmediate(vertical.gameObject);
        foreach (var preset in new[] { PathPreset.Curve, PathPreset.Circle, PathPreset.Flight })
        {
            var path = PathAuthoring.Create(preset, Vector3.zero); float length = path.Length;
            var previous = path.Evaluate(0); float minSpeed = 100, maxSpeed = 0; bool frame = true;
            for (int i = 1; i <= 500; i++) { var p = path.Evaluate(length * i / 500); float ratio = Vector3.Distance(previous.position, p.position) / (length / 500); minSpeed = Mathf.Min(minSpeed, ratio); maxSpeed = Mathf.Max(maxSpeed, ratio); frame &= BezierPath.Finite(p.up) && Mathf.Abs(Vector3.Dot(p.up, p.tangent)) < .0001f && Vector3.Dot(previous.up, p.up) > .5f; previous = p; }
            Check(minSpeed > .97f && maxSpeed < 1.01f, preset + ": equal distances give near-uniform speed"); Check(frame, preset + ": frames are finite, perpendicular and continuous");
            if (path.closed) { Check(Vector3.Distance(path.Evaluate(0).position, path.Evaluate(length).position) < .0001f, preset + ": closed positions meet"); Check(Quaternion.Angle(path.Evaluate(0).Rotation, path.Evaluate(length).Rotation) < .03f, preset + ": closed frame twist is corrected"); }
            if (preset == PathPreset.Circle) Near(length, 2 * Mathf.PI * 5, .02f, "Cubic circle length");
            var originalUp = path.Evaluate(0).up; path.knots[0].roll = 45; path.Invalidate(); Near(Vector3.Angle(path.Evaluate(0).up, originalUp), 45, .1f, preset + ": point roll applied");
            Object.DestroyImmediate(path.gameObject);
        }
        var degenerate = Straight(0); Reject(() => { var l = degenerate.Length; }, "Zero-length path rejected"); degenerate.knots[0].position.x = float.NaN; Reject(() => degenerate.Evaluate(0), "NaN knot rejected"); Object.DestroyImmediate(degenerate.gameObject);
    }
    static void Meshes()
    {
        var path = Straight(); path.transform.position = new Vector3(8, 2, 3); path.transform.localScale = new Vector3(2, 1, 2);
        foreach (PathMeshKind kind in Enum.GetValues(typeof(PathMeshKind)))
        {
            var settings = new PathMeshSettings { kind = kind, metersPerTile = 2, width = 2, sides = 8, twoSided = true };
            var mesh = PathMeshBuilder.Build(path, settings); var vertices = mesh.vertices; var normals = mesh.normals; var uv = mesh.uv; var uv1 = mesh.uv2;
            Check(vertices.Length > 0 && vertices.All(BezierPath.Finite), kind + ": finite world vertices");
            Check(normals.All(n => Mathf.Abs(n.magnitude - 1) < .001f) && mesh.tangents.Length == vertices.Length && mesh.tangents.All(t => BezierPath.Finite(new Vector3(t.x, t.y, t.z))), kind + ": finite unit normals and tangents");
            Check(uv.Length == vertices.Length && uv1.Length == vertices.Length && uv1.All(u => u.x >= 0 && u.x <= 1 && u.y >= 0 && u.y <= 1.0001f), kind + ": shader UV coordinates populated and normalized");
            bool winding = true; for (int sub = 0; sub < mesh.subMeshCount; sub++) { var tri = mesh.GetTriangles(sub); for (int i = 0; i < tri.Length; i += 3) { int a = tri[i], b = tri[i + 1], c = tri[i + 2]; var cross = Vector3.Cross(vertices[b] - vertices[a], vertices[c] - vertices[a]); if (cross.sqrMagnitude > 1e-12f) winding &= Vector3.Dot(cross, normals[a] + normals[b] + normals[c]) > 0; } }
            Check(winding, kind + ": triangle winding matches outward normals");
            if (kind == PathMeshKind.Ribbon) { Near(uv.Max(u => u.y), 10, .0001f, "UV repeat measured in world metres"); Near((vertices[1] - vertices[0]).magnitude, 2, .0001f, "Ribbon width ignores path scale"); Near(vertices[0].y, 2.02f, .0001f, "Ribbon surface offset"); }
            if (kind == PathMeshKind.Tube) Check(Vector3.Distance(vertices[0], vertices[8]) < .0001f && uv[0].x == 0 && uv[8].x == 1, "Tube seam duplicates vertices with separate U coordinates");
            if (kind == PathMeshKind.Railing) Check(mesh.subMeshCount == 2 && mesh.GetIndexCount(0) > 0 && mesh.GetIndexCount(1) > 0, "Rails and posts use separate material slots");
            Object.DestroyImmediate(mesh);
        }
        Reject(() => PathMeshBuilder.Build(path, new PathMeshSettings { step = 0 }), "Invalid segment spacing rejected");
        Reject(() => PathMeshBuilder.Build(path, new PathMeshSettings { metersPerTile = float.NaN }), "Invalid UV tiling rejected");
        Reject(() => PathMeshBuilder.Build(path, new PathMeshSettings { kind = PathMeshKind.Railing, postSpacing = .001f }), "Excessive object count rejected");
        if (!AssetDatabase.IsValidFolder("Assets/Path060")) AssetDatabase.CreateFolder("Assets", "Path060");
        var material = PathAuthoring.DefaultMaterial(); AssetDatabase.CreateAsset(material, "Assets/Path060/TestMaterial.mat");
        var root = PathAuthoring.Generate(path, new PathMeshSettings { kind = PathMeshKind.Railing }, material, material, "Assets/Path060");
        root.name = "Persisted mesh"; string asset = AssetDatabase.GetAssetPath(root.GetComponent<MeshFilter>().sharedMesh);
        Check(asset.StartsWith("Assets/Path060/CHPath_Railing") && root.GetComponent<MeshRenderer>().sharedMaterials.All(m => m == material), "Generated mesh persisted and custom material preserved");
        Reject(() => PathAuthoring.Generate(path, new PathMeshSettings(), material, null, "Packages"), "Mesh output rejects package directories");
        var nextRoot = PathAuthoring.Generate(path, new PathMeshSettings(), null, null, "Assets/Path060");
        Check(root == null && nextRoot != null && AssetDatabase.LoadAssetAtPath<Mesh>(asset) != null, "Rebuild replaces only the owned group and retains old mesh assets");
        Undo.PerformUndo(); Check(nextRoot == null && GameObject.Find("Persisted mesh") != null, "Mesh rebuild Undo restores old hierarchy");
        Undo.PerformRedo(); Check(GameObject.Find("Persisted mesh") == null, "Mesh rebuild Redo");
        nextRoot = Object.FindObjectsByType<PathGeneratedOutput>(FindObjectsSortMode.None).Single(o => o.owner == path).gameObject; nextRoot.name = "Persisted mesh";
        Check(EditorUtility.IsPersistent(nextRoot.GetComponent<MeshRenderer>().sharedMaterial), "Default material saved as asset subobject");
        path.name = "Persisted mesh path";
    }
    static void Models()
    {
        var path = Straight(); var model = GameObject.CreatePrimitive(PrimitiveType.Cube); var prefab = PrefabUtility.SaveAsPrefabAsset(model, "Assets/Path060/Model.prefab"); Object.DestroyImmediate(model);
        var root = PathAuthoring.Place(path, prefab, new PathPlacementSettings { spacing = 3 });
        Check(root.transform.childCount == 4, "Spacing places 0, 3, 6, 9 without a short final interval");
        Check(root.GetComponentsInChildren<Transform>().Where(t => t != root.transform).All(t => PrefabUtility.IsPartOfPrefabInstance(t.gameObject)), "Placed models retain prefab links");
        Near(root.transform.GetChild(2).position.z, 6, .0001f, "Model placement uses world distance");
        var unrelated = new GameObject("Unrelated object"); unrelated.transform.SetParent(path.transform);
        root = PathAuthoring.Place(path, prefab, new PathPlacementSettings { spacing = 3, includeEnd = true, offset = Vector3.up, rotation = new Vector3(0, 90, 0), scale = Vector3.one * 2 });
        Check(root.transform.childCount == 5 && unrelated != null, "Endpoint option and unrelated hierarchy preservation"); Near(root.transform.GetChild(4).position.z, 10, .0001f, "Included endpoint exact position"); Near(root.transform.GetChild(0).position.y, 1, .0001f, "Placement frame offset"); Near(root.transform.GetChild(0).localScale.x, 2, .0001f, "Placement scale multiplier");
        Check(Vector3.Dot(root.transform.GetChild(0).forward, Vector3.right) > .999f, "Model axis correction");
        Check(PathMeshBuilder.PlacementDistances(10, 2, true, true).SequenceEqual(new[] { 0f, 2f, 4f, 6f, 8f }), "Closed placement excludes duplicate seam endpoint");
        Reject(() => PathAuthoring.Place(path, path.gameObject, new PathPlacementSettings()), "Path cannot be cloned into its generated group");
        Reject(() => PathAuthoring.Place(path, prefab, new PathPlacementSettings { spacing = .0001f }), "Invalid model spacing rejected");
        Object.DestroyImmediate(root); Object.DestroyImmediate(path.gameObject);
    }
    static void Motion()
    {
        var path = Straight(); var target = new GameObject("Motion checks"); var f = PathAuthoring.Attach(path, target); f.speed = 2; f.maxBank = 0; f.lookAhead = 0;
        bool back; f.travel = PathTravel.Once; Near(f.DistanceAt(8, out back), 10, .0001f, "Once clamps overshoot");
        f.travel = PathTravel.Loop; Near(f.DistanceAt(16, out back), 2, .0001f, "Loop handles multiple cycles");
        Near(f.DistanceAt(-1, out back), 8, .0001f, "Loop handles negative time");
        f.travel = PathTravel.PingPong; Near(f.DistanceAt(6, out back), 8, .0001f, "Ping-pong return distance"); Check(back, "Ping-pong return faces travel direction");
        Check(Vector3.Dot(f.PoseAt(6).tangent, Vector3.back) > .999f, "Return orientation reverses tangent");
        Near(f.DistanceAt(26, out back), 8, .0001f, "Ping-pong handles many cycles");
        f.reverse = true; f.startDistance = 10; Near(f.DistanceAt(2, out back), 6, .0001f, "Reverse starts from selected distance"); Check(back, "Reverse orientation");
        f.reverse = false; f.startDistance = 0; f.speed = 0; Near(f.DistanceAt(99, out back), 0, .0001f, "Zero speed remains stationary");
        f.speed = 2; f.positionOffset = Vector3.up; f.Apply(2); Near(target.transform.position.z, 4, .0001f, "Deterministic pose evaluation"); Near(target.transform.position.y, 1, .0001f, "Motion frame position offset");
        f.orientation = PathOrientation.PositionOnly; var rotation = Quaternion.Euler(30, 40, 50); target.transform.rotation = rotation; f.Apply(3); Check(Quaternion.Angle(target.transform.rotation, rotation) < .001f, "Position-only mode preserves rotation");
        Reject(() => PathAuthoring.Attach(path, path.gameObject), "Follower cannot move its own path");
        f.speed = float.NaN; Reject(() => f.PoseAt(0), "NaN motion speed rejected");
        var flight = PathAuthoring.Create(PathPreset.Flight, Vector3.zero); f.path = flight; f.speed = 4; f.orientation = PathOrientation.Transported; f.maxBank = 20; f.bankStrength = 3; f.lookAhead = .4f;
        bool finite = true, bank = false; for (int i = 0; i < 100; i++) { var p = f.PoseAt(i * .05); finite &= BezierPath.Finite(p.tangent) && BezierPath.Finite(p.up); float angle = Vector3.Angle(BezierPath.Perpendicular(p.tangent, flight.Evaluate(p.distance).up), p.up); finite &= angle <= 20.01f; bank |= angle > .2f; }
        Check(finite && bank, "3D flight has finite pitched orientation and bounded turn banking");
        Object.DestroyImmediate(target); Object.DestroyImmediate(path.gameObject); Object.DestroyImmediate(flight.gameObject);
    }
    static PathFollower Follower { get { return GameObject.Find("Runtime follower").GetComponent<PathFollower>(); } }
    static void Resume()
    {
        try { state = JsonUtility.FromJson<State>(SessionState.GetString(Key, "")); Application.logMessageReceived += Log; EditorApplication.update += Tick; next = EditorApplication.timeSinceStartup + 1; }
        catch (Exception e) { Finish(e); }
    }
    static void Save() { SessionState.SetString(Key, JsonUtility.ToJson(state)); }
    static void Log(string condition, string stack, LogType type) { if (type == LogType.Exception || type == LogType.Error || type == LogType.Assert) errors = condition + "\n" + stack; }
    static void Tick()
    {
        try
        {
            if (EditorApplication.timeSinceStartup > state.deadline) throw new TimeoutException("Path tool smoke timed out");
            if (EditorApplication.timeSinceStartup < next || EditorApplication.isCompiling) return;
            if (errors != null) throw new Exception(errors);
            next = EditorApplication.timeSinceStartup + .7;
            Directory.CreateDirectory("Artifacts"); File.WriteAllText("Artifacts/progress.json", "{\"phase\":" + state.phase + ",\"playing\":" + EditorApplication.isPlaying.ToString().ToLowerInvariant() + ",\"changing\":" + EditorApplication.isPlayingOrWillChangePlaymode.ToString().ToLowerInvariant() + "}");
            switch (state.phase)
            {
                case 0:
                    Check((string)typeof(ASEShaderConverterWindow).GetProperty("ActiveCategory", Flags).GetValue(window) == "scene", "Path tools are embedded in Scene category");
                    Check(Resources.FindObjectsOfTypeAll<ASEShaderConverterWindow>().Length == 1, "Only one host window");
                    PathMotionPreview.Start(Follower); state.phase++; break;
                case 1:
                    Check(Vector3.Distance(Follower.transform.position, state.original) > 1, "Editor preview moves target"); ASEShaderConverterWindow.OpenUpdates();
                    Check(Vector3.Distance(Follower.transform.position, state.original) < .0001f && Quaternion.Angle(Follower.transform.rotation, state.rotation) < .001f && Follower.transform.localScale == state.scale, "Leaving path page restores exact transform");
                    ASEShaderConverterWindow.OpenPathTools(); state.phase++; break;
                case 2:
                    var panel = typeof(ASEShaderConverterWindow).GetField("paths", Flags).GetValue(window); panel.GetType().GetField("tab", Flags).SetValue(panel, 1); state.phase++; break;
                case 3: typeof(ASEShaderConverterWindow).GetField("paths", Flags).GetValue(window).GetType().GetField("tab", Flags).SetValue(typeof(ASEShaderConverterWindow).GetField("paths", Flags).GetValue(window), 2); state.phase++; break;
                case 4: typeof(ASEShaderConverterWindow).GetField("paths", Flags).GetValue(window).GetType().GetField("tab", Flags).SetValue(typeof(ASEShaderConverterWindow).GetField("paths", Flags).GetValue(window), 3); state.phase++; break;
                case 5:
                    Check(errors == null, "All four tool tabs render without GUI errors");
                    var lang = typeof(ASEShaderConverterWindow).Assembly.GetType("ASEShaderConverter.Editor.CHToolLanguage"); lang.GetMethod("Set", Flags).Invoke(null, new object[] { true }); window.position = new Rect(50, 50, 800, 500); state.phase++; break;
                case 6:
                    Check(errors == null, "Chinese panel renders at minimum host size");
                    PathMotionPreview.Start(Follower); state.phase++; break;
                case 7:
                    window.Close(); Check(Vector3.Distance(Follower.transform.position, state.original) < .0001f, "Closing host restores preview pose");
                    EditorSceneManager.SaveScene(SceneManager.GetActiveScene(), "Assets/Path060/Test.unity");
                    PathMotionPreview.Start(Follower); state.phase = 8; Save(); EditorUtility.RequestScriptReload(); break;
                case 8:
                    Check(!PathMotionPreview.IsActive && Vector3.Distance(Follower.transform.position, state.original) < .0001f, "Assembly reload stops preview and restores original pose");
                    state.phase = 9; Save(); EditorApplication.EnterPlaymode(); next = EditorApplication.timeSinceStartup + 3; break;
                case 9:
                    if (!EditorApplication.isPlaying) return;
                    Check(Follower.IsRunning && Vector3.Distance(Follower.transform.position, state.original) > 5, "Runtime Update actually moves follower in Play mode");
                    Check(BezierPath.Finite(Follower.transform.forward) && Mathf.Abs(Follower.transform.forward.y) > .01f, "Runtime flight updates orientation with pitch");
                    state.phase = 10; Save(); EditorApplication.update += ExitOnce; break;
                case 10:
                    if (EditorApplication.isPlayingOrWillChangePlaymode) return;
                    Check(Vector3.Distance(Follower.transform.position, state.original) < .0001f, "Exiting Play mode restores authored pose");
                    EditorSceneManager.OpenScene("Assets/Path060/Test.unity");
                    var mf = GameObject.Find("Persisted mesh").GetComponent<MeshFilter>(); Check(mf.sharedMesh != null && EditorUtility.IsPersistent(mf.sharedMesh), "Mesh survives scene save/reopen and domain reload");
                    Check(GameObject.Find("Persisted mesh").GetComponent<MeshRenderer>().sharedMaterial != null, "Default material survives scene save/reopen");
                    Check(Follower.path != null && Follower.path.knots.Count == 4, "Runtime component and curve data serialize across reload"); Finish(null); return;
            }
            if (window != null) window.Repaint();
        }
        catch (Exception e) { Finish(e); }
    }
    static void Finish(Exception failure)
    {
        EditorApplication.update -= Tick; Application.logMessageReceived -= Log; SessionState.EraseString(Key); PathMotionPreview.Stop();
        if (state != null) { if (state.hadLanguage) EditorPrefs.SetString("CH.CustomTools.Language", state.language); else EditorPrefs.DeleteKey("CH.CustomTools.Language"); }
        Directory.CreateDirectory("Artifacts");
        File.WriteAllText("Artifacts/path-tools.json", JsonUtility.ToJson(new Report { unity = Application.unityVersion, version = UnityEditor.PackageManager.PackageInfo.FindForAssembly(typeof(BezierPath).Assembly).version, status = failure == null ? "Passed" : "Failed", failure = failure == null ? null : failure.ToString(), count = state == null ? 0 : state.checks.Count, passed = state == null ? new string[0] : state.checks.ToArray() }, true));
        EditorApplication.Exit(failure == null ? 0 : 1);
    }
}
