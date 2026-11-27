// Authoring previews must match committed geometry without creating scene objects or assets.
using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using CH.CustomTools.Paths;
using CH.CustomTools.Paths.Editor;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using Object = UnityEngine.Object;

[ExecuteAlways]
public sealed class CHPreviewCallbackProbe : MonoBehaviour
{
    public static int callbacks;
    void OnEnable() { callbacks++; }
}
public static class UnityPathPreviewSmoke
{
    const BindingFlags Flags = BindingFlags.Static | BindingFlags.NonPublic;
    [Serializable] sealed class Report { public string unity, version, status, failure; public int count; public string[] passed; }
    static readonly List<string> checks = new List<string>();
    static BezierPath path; static GameObject model; static Material red, green;
    static PathPlacementSettings placement; static PathMeshSettings settings;
    static SceneView view; static Texture2D captured; static double next, deadline; static int phase;
    static Mesh previous; static string errors; static bool dirty; static int objects; static string[] assets;
    static void Check(bool value, string message) { if (!value) throw new Exception(message); checks.Add(message); }
    static void Refresh()
    {
        typeof(PathAuthoringPreview).GetField("next", Flags).SetValue(null, 0d);
        typeof(PathAuthoringPreview).GetMethod("Tick", Flags).Invoke(null, null);
    }
    static void Configure(bool models = true, bool mesh = true) { PathAuthoringPreview.Configure(path, model, placement, settings, green, red, models, mesh); Refresh(); }
    static Mesh Temporary { get { return PathAuthoringPreview.PreviewMesh; } }
    public static void Run()
    {
        CHValidationInput.Install();
        try
        {
            PlayerSettings.runInBackground = true;
            EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);
            path = new GameObject("Preview path").AddComponent<BezierPath>();
            path.knots = new List<PathKnot> { new PathKnot(new Vector3(0, 0, -4)), new PathKnot(new Vector3(0, 0, 4)) };
            model = GameObject.CreatePrimitive(PrimitiveType.Cube); model.name = "Source model"; model.transform.position = new Vector3(20, 0, 0);
            red = new Material(Shader.Find("Unlit/Color")) { color = Color.red }; green = new Material(red) { color = Color.green };
            model.GetComponent<MeshRenderer>().sharedMaterial = red; model.AddComponent<CHPreviewCallbackProbe>();
            placement = new PathPlacementSettings { spacing = 2, scale = new Vector3(.6f, .7f, .5f), offset = Vector3.right * 1.5f, rotation = new Vector3(5, 15, 25) };
            settings = new PathMeshSettings { width = .8f, step = .25f };
            Directory.CreateDirectory("Assets/Preview064"); AssetDatabase.Refresh();
            EditorSceneManager.SaveScene(path.gameObject.scene, "Assets/Preview064/Preview.unity");
            dirty = path.gameObject.scene.isDirty; objects = Object.FindObjectsByType<Transform>(FindObjectsInactive.Include, FindObjectsSortMode.None).Length;
            assets = Directory.GetFiles("Assets", "*", SearchOption.AllDirectories).OrderBy(x => x).ToArray(); int calls = CHPreviewCallbackProbe.callbacks;
            PathSceneTool.Active = true; Configure();
            Check(Temporary != null && PathAuthoringPreview.ModelDrawCount == 4, "Both mesh and four placed models preview without Generate");
            Check((Temporary.hideFlags & HideFlags.DontSave) != 0 && !EditorUtility.IsPersistent(Temporary), "Preview mesh is temporary and cannot be saved as an asset");
            Check(Object.FindObjectsByType<PathGeneratedOutput>(FindObjectsSortMode.None).Length == 0, "Preview creates no permanent output markers");
            Check(Object.FindObjectsByType<Transform>(FindObjectsInactive.Include, FindObjectsSortMode.None).Where(t => (t.gameObject.hideFlags & HideFlags.DontSave) == 0).Count() == objects, "Preview creates no saved scene objects or prefab instances");
            Check(CHPreviewCallbackProbe.callbacks == calls, "Model preview never executes source prefab behaviours");
            Check(path.gameObject.scene.isDirty == dirty && assets.SequenceEqual(Directory.GetFiles("Assets", "*", SearchOption.AllDirectories).OrderBy(x => x)), "Preview does not dirty the scene or create assets");
            var sceneBytes = File.ReadAllBytes("Assets/Preview064/Preview.unity");
            EditorSceneManager.SaveScene(path.gameObject.scene);
            Check(sceneBytes.SequenceEqual(File.ReadAllBytes("Assets/Preview064/Preview.unity")), "Saving with live preview preserves scene bytes and excludes all temporary helpers");
            previous = Temporary; Refresh(); Check(Temporary == previous, "An unchanged preview reuses its mesh");
            Undo.IncrementCurrentGroup(); PathKnotEditing.SetRoll(path, 0, 45); Undo.FlushUndoRecordObjects(); Refresh();
            Check(previous == null && Temporary != null && Vector3.Dot(Temporary.normals[0], Quaternion.AngleAxis(45, Vector3.forward) * Vector3.up) > .9999f, "Point rotation immediately tilts the preview normals and disposes the prior mesh");
            Check(Vector3.Distance(path.knots[0].position, new Vector3(0, 0, -4)) < .00001f, "Point rotation does not move the path centreline");
            Undo.PerformUndo(); Refresh(); Check(Mathf.Abs(path.knots[0].roll) < .001f && Temporary.normals[0].y > .9999f, "Undo restores the live tilt preview");
            Undo.PerformRedo(); Refresh(); Check(Mathf.Abs(path.knots[0].roll - 45) < .001f, "Redo restores point rotation and preview");
            settings.kind = PathMeshKind.Railing; Configure();
            Check(Temporary.subMeshCount == 2, "Railing preview includes separate rail and post material slots");
            settings.kind = PathMeshKind.Ribbon; path.knots[0].roll = 0; path.knots[1].position.y = 1; Configure();
            Check(Temporary.bounds.max.y > .9f, "Changing point height updates the live mesh");
            settings.width = 1.3f; settings.uvScale = new Vector2(2, 3); Configure();
            var vertices = Temporary.vertices; var normals = Temporary.normals; var uv = Temporary.uv; var uv2 = Temporary.uv2; var triangles = Temporary.triangles;
            var final = PathAuthoring.Generate(path, settings, green, red, "Assets/Preview064"); var committed = final.GetComponent<MeshFilter>().sharedMesh;
            Check(EditorUtility.IsPersistent(committed) && committed != Temporary, "Generate creates a distinct persistent mesh asset");
            Check(vertices.Zip(committed.vertices, (a, b) => Vector3.Distance(a, final.transform.TransformPoint(b))).All(d => d < .0001f) && normals.SequenceEqual(committed.normals) && uv.SequenceEqual(committed.uv) && uv2.SequenceEqual(committed.uv2) && triangles.SequenceEqual(committed.triangles), "Committed world positions, normals, UV0, UV1 and topology match live mesh preview");
            var group = PathAuthoring.Place(path, model, placement);
            var draws = (IList)typeof(PathAuthoringPreview).GetField("models", Flags).GetValue(null);
            Check(group.transform.childCount == draws.Count, "Committed model count matches preview");
            for (int i = 0; i < draws.Count; i++)
            {
                var draw = draws[i]; var matrix = (Matrix4x4)draw.GetType().GetField("matrix").GetValue(draw);
                var actual = group.transform.GetChild(i).localToWorldMatrix;
                Check(Enumerable.Range(0, 16).All(n => Mathf.Abs(matrix[n] - actual[n]) < .0001f), "Committed model transform matches preview at distance index " + i);
            }
            var oldVertices = committed.vertices;
            PathSceneTool.Edit(path);
            path.knots[1].position += new Vector3(2, 1, 0); Configure();
            Check(oldVertices.SequenceEqual(committed.vertices) && !oldVertices.Select(final.transform.TransformPoint).SequenceEqual(Temporary.vertices), "Editing updates temporary mesh while preserving committed output until rebuild");
            var filter = model.GetComponent<MeshFilter>(); var sourceMesh = filter.sharedMesh; filter.sharedMesh = null; Configure();
            Check(PathAuthoringPreview.ModelDrawCount == 0 && !string.IsNullOrEmpty(PathAuthoringPreview.Status) && Temporary != null, "Invalid model clears stale model preview but retains valid mesh preview");
            filter.sharedMesh = sourceMesh; settings.width = -1; Configure();
            Check(Temporary == null && PathAuthoringPreview.ModelDrawCount > 0 && !string.IsNullOrEmpty(PathAuthoringPreview.Status), "Invalid mesh parameters clear stale mesh preview while models remain visible");
            settings.width = 1.3f; path.knots[1].position = new Vector3(0, 0, 4); Configure();
            view = EditorWindow.GetWindow<SceneView>(); view.position = new Rect(20, 20, 1000, 760); view.Show();
            foreach (var output in Object.FindObjectsByType<PathGeneratedOutput>(FindObjectsSortMode.None)) foreach (var renderer in output.GetComponentsInChildren<Renderer>()) renderer.enabled = false;
            view.LookAtDirect(Vector3.zero, Quaternion.LookRotation(Vector3.down, Vector3.forward), 6); view.orthographic = true; view.sceneLighting = false; view.drawGizmos = false; view.showGrid = false; view.cameraMode = SceneView.GetBuiltinCameraMode(DrawCameraMode.Textured); view.Focus();
            Selection.activeObject = null; SceneView.duringSceneGui += Capture; Application.logMessageReceived += Log;
            view.Repaint(); next = EditorApplication.timeSinceStartup + 2; deadline = next + 45; EditorApplication.update += Tick;
        }
        catch (Exception e) { Finish(e); }
    }
    static void Capture(SceneView scene)
    {
        if (scene != view || Event.current.type != EventType.Repaint || RenderTexture.active == null) return;
        var rt = RenderTexture.active;
        if (captured != null) Object.DestroyImmediate(captured);
        captured = new Texture2D(rt.width, rt.height, TextureFormat.RGBA32, false);
        captured.ReadPixels(new Rect(0, 0, rt.width, rt.height), 0, 0); captured.Apply();
    }
    static void Log(string message, string stack, LogType type) { if (type == LogType.Error || type == LogType.Exception || type == LogType.Assert) errors = message + "\n" + stack; }
    static void Tick()
    {
        try
        {
            if (EditorApplication.timeSinceStartup > deadline) throw new TimeoutException("Preview Scene rendering timed out");
            if (EditorApplication.timeSinceStartup < next || captured == null) return;
            if (errors != null) throw new Exception(errors);
            if (phase++ == 0)
            {
                Check((bool)typeof(PathAuthoringPreview).GetMethod("Visible", Flags).Invoke(null, new object[] { view.camera }), "Preview participates in the active Scene camera");
                var target = new RenderTexture(1000, 700, 24); var prior = view.camera.targetTexture; var active = RenderTexture.active;
                Texture2D tex;
                try { view.camera.targetTexture = target; view.camera.Render(); RenderTexture.active = target; tex = new Texture2D(1000, 700, TextureFormat.RGBA32, false); tex.ReadPixels(new Rect(0, 0, 1000, 700), 0, 0); tex.Apply(); }
                finally { view.camera.targetTexture = prior; RenderTexture.active = active; Object.DestroyImmediate(target); }
                try
                {

                    var pixels = tex.GetPixels(); int r = pixels.Count(c => c.r > .6f && c.g < .15f && c.b < .15f), g = pixels.Count(c => c.g > .6f && c.r < .15f && c.b < .15f);
                    Directory.CreateDirectory("Artifacts"); File.WriteAllBytes("Artifacts/live-models-and-mesh.png", tex.EncodeToPNG());
                    Check(r > 100 && g > 500, "Scene renders live model and mesh materials with Gizmos off: red=" + r + ", green=" + g + ", active=" + PathAuthoringPreview.IsActive + ", editing=" + PathSceneTool.Active + ", camera=" + view.camera.transform.position + ", draws=" + PathAuthoringPreview.ModelDrawCount);
                }
                finally { Object.DestroyImmediate(tex); }
                foreach (var output in Object.FindObjectsByType<PathGeneratedOutput>(FindObjectsSortMode.None)) Check(output.GetComponentInChildren<Renderer>().forceRenderingOff == false, "Committed renderer state restored after Scene render: " + output.kind);
                RepeatedCameraRenders();
                PathSceneTool.Active = false; Check(!PathAuthoringPreview.IsActive && Temporary == null, "Disabling Scene editing clears authoring preview");
                PathSceneTool.Active = true; Configure();
                var probe = new GameObject("Motion target").AddComponent<PathFollower>(); probe.path = path;
                PathMotionPreview.Start(probe); Check(!PathAuthoringPreview.IsActive, "Starting motion preview releases authoring geometry"); PathMotionPreview.Stop();
                Configure(); ASEShaderConverter.Editor.ASEShaderConverterWindow.OpenPathTools(); next = EditorApplication.timeSinceStartup + .5;
            }
            else
            {
                foreach (var window in Resources.FindObjectsOfTypeAll<ASEShaderConverter.Editor.ASEShaderConverterWindow>()) window.Close();
                Check(!PathAuthoringPreview.IsActive && Temporary == null, "Closing the tool window releases preview mesh and references");
                Check(Object.FindObjectsByType<PathGeneratedOutput>(FindObjectsSortMode.None).Length == 2, "Closing preview preserves the two explicitly committed output groups");
                Finish(null);
            }
        }
        catch (Exception e) { Finish(e); }
    }
    static Texture2D Render(Camera camera)
    {
        var rt = new RenderTexture(512, 512, 24); var target = camera.targetTexture; var previous = RenderTexture.active;
        try { camera.targetTexture = rt; camera.Render(); RenderTexture.active = rt; var tex = new Texture2D(512, 512, TextureFormat.RGBA32, false); tex.ReadPixels(new Rect(0, 0, 512, 512), 0, 0); tex.Apply(); return tex; }
        finally { camera.targetTexture = target; RenderTexture.active = previous; Object.DestroyImmediate(rt); }
    }
    static void RepeatedCameraRenders()
    {
        var transparent = new Material(Shader.Find("Sprites/Default")) { color = new Color(0, 1, 0, .4f) };
        var group = PathAuthoring.Generate(path, settings, red, null, "Assets/Preview064");
        group.GetComponent<MeshRenderer>().enabled = true;
        PathSceneTool.Edit(path);
        PathAuthoringPreview.Configure(path, null, placement, settings, transparent, null, false, true); Refresh();
        var sample = view.camera.WorldToViewportPoint(path.Evaluate(path.Length * .5f).position);
        view.camera.clearFlags = CameraClearFlags.SolidColor; view.camera.backgroundColor = Color.black;
        Color? first = null;
        for (int i = 0; i < 6; i++)
        {
            var image = Render(view.camera); var color = image.GetPixel(Mathf.RoundToInt(sample.x * 512), Mathf.RoundToInt(sample.y * 512));
            if (first.HasValue) Check(Vector4.Distance(first.Value, color) < .015f, "Repeated Scene camera renders do not accumulate transparent preview draws: " + i + "; first=" + first.Value + "; current=" + color);
            else { first = color; Check(color.g > .2f && color.r < .05f, "Live mesh preview hides committed red geometry only in the Scene camera: " + color); }
            if (i == 5) File.WriteAllBytes("Artifacts/repeated-transparent-preview.png", image.EncodeToPNG()); Object.DestroyImmediate(image);
            Check(!group.GetComponent<MeshRenderer>().forceRenderingOff, "Scene render restores the committed renderer: " + i);
        }
        var cameraObject = new GameObject("Game camera preview isolation"); var game = cameraObject.AddComponent<Camera>();
        game.transform.SetPositionAndRotation(view.camera.transform.position, view.camera.transform.rotation); game.orthographic = true; game.orthographicSize = view.camera.orthographicSize;
        var picture = Render(game); var point = game.WorldToViewportPoint(path.Evaluate(path.Length * .5f).position); var pixel = picture.GetPixel(Mathf.RoundToInt(point.x * 512), Mathf.RoundToInt(point.y * 512));
        Check(pixel.r > .8f && pixel.g < .05f, "Game camera renders committed output and excludes temporary preview: " + pixel);
        Object.DestroyImmediate(picture); Object.DestroyImmediate(cameraObject);
        PathAuthoringPreview.Stop(); Object.DestroyImmediate(transparent);
    }
    static void Finish(Exception failure)
    {
        EditorApplication.update -= Tick; SceneView.duringSceneGui -= Capture; Application.logMessageReceived -= Log; PathAuthoringPreview.Stop();
        Directory.CreateDirectory("Artifacts"); File.WriteAllText("Artifacts/path-preview.json", JsonUtility.ToJson(new Report { unity = Application.unityVersion, version = UnityEditor.PackageManager.PackageInfo.FindForAssembly(typeof(BezierPath).Assembly).version, status = failure == null ? "Passed" : "Failed", failure = failure == null ? "" : failure.ToString(), count = checks.Count, passed = checks.ToArray() }, true));
        EditorApplication.Exit(failure == null ? 0 : 1);
    }
}
