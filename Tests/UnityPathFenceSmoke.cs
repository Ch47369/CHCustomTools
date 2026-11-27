using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using CH.CustomTools.Paths;
using CH.CustomTools.Paths.Editor;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.Rendering;
using Object = UnityEngine.Object;

public static class UnityPathFenceSmoke
{
    const BindingFlags StaticMethods = BindingFlags.Static | BindingFlags.NonPublic;
    static readonly List<string> checks = new List<string>();
    static SceneView view;
    static BezierPath path;
    static Vector2 center, received, offset;
    static bool calibrating, receivedMove;
    static double next, deadline;
    static int phase;
    static string errorLog;

    public static void Run()
    {
        try
        {
            CHValidationInput.Install();
            PlayerSettings.runInBackground = true;
            EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);
            view = EditorWindow.GetWindow<SceneView>();
            view.position = new Rect(25, 40, 960, 730);
            view.Show();
            view.LookAtDirect(Vector3.zero, Quaternion.LookRotation(Vector3.down, Vector3.forward), 8);
            view.orthographic = true;
            view.Focus();
            SceneView.duringSceneGui += Capture;
            Application.logMessageReceived += Log;
            BeginDraft();
            next = EditorApplication.timeSinceStartup + 3;
            deadline = next + 55;
            EditorApplication.update += Tick;
        }
        catch (Exception e) { Finish(e); }
    }

    static void BeginDraft()
    {
        var type = typeof(PathSceneTool).Assembly.GetType("CH.CustomTools.Paths.Editor.PathFenceDraft", true);
        type.GetMethod("Begin", StaticMethods).Invoke(null, new object[] { view, PathFenceAxis.Y, (Action<BezierPath>)(result => path = result) });
    }

    static void Capture(SceneView scene)
    {
        if (scene != view) return;
        if (calibrating && Event.current.type == EventType.MouseMove)
        {
            received = Event.current.mousePosition;
            receivedMove = true;
        }
        if (Event.current.type == EventType.Repaint)
            center = GUIUtility.GUIToScreenPoint(HandleUtility.WorldToGUIPoint(Vector3.zero)) - view.position.position;
    }

    static void Log(string message, string stack, LogType type)
    {
        if (type == LogType.Error || type == LogType.Exception || type == LogType.Assert) errorLog = message + "\n" + stack;
    }

    static void Check(bool condition, string message)
    {
        if (!condition) throw new InvalidOperationException(message);
        checks.Add(message);
    }

    static void Click(float x, float y, bool shift = false)
    {
        var point = center + new Vector2(x, y) + offset;
        foreach (var kind in new[] { EventType.MouseDown, EventType.MouseUp })
            CHValidationInput.Send(view, new Event { type = kind, mousePosition = point, button = 0, shift = shift });
    }

    static void Key(KeyCode key)
    {
        view.Focus();
        CHValidationInput.Send(view, new Event { type = EventType.KeyDown, keyCode = key });
        CHValidationInput.Send(view, new Event { type = EventType.KeyUp, keyCode = key });
    }

    static void Tick()
    {
        try
        {
            if (EditorApplication.timeSinceStartup > deadline) throw new TimeoutException("Fence test timed out");
            if (EditorApplication.timeSinceStartup < next || center == Vector2.zero) return;
            if (errorLog != null) throw new InvalidOperationException(errorLog);
            next = EditorApplication.timeSinceStartup + .7;
            switch (phase++)
            {
                case 0:
                    calibrating = true;
                    CHValidationInput.Send(view, new Event { type = EventType.MouseMove, mousePosition = center });
                    calibrating = false;
                    Check(receivedMove, "Scene receives calibrated input");
                    offset = center - received;
                    Click(-160, -105);
                    Click(120, -79, true);
                    Click(126, 103, true);
                    Click(-160, 103, true);
                    Key(KeyCode.Backspace);
                    Click(-160, 103, true);
                    Click(-160, -105);
                    Check(path != null && path.closed && path.knots.Count == 4, "Scene clicks, Backspace and first-point close produce the closed polygon");
                    Check(path.knots.All(k => !k.automatic && k.incoming == Vector3.zero && k.outgoing == Vector3.zero),
                        "Every corner is an editable linear knot");
                    var a = path.knots[1].position - path.knots[0].position;
                    var b = path.knots[2].position - path.knots[1].position;
                    Check(Mathf.Abs(a.x) > 1 && Mathf.Abs(a.z) < 1e-5f && Mathf.Abs(b.x) < 1e-5f &&
                        Mathf.Abs(b.z) > 1 && path.knots.All(k => Mathf.Abs(k.position.y) < 1e-5f),
                        "Shift constrains the two drawn edges to perpendicular X and Z axes");
                    break;
                case 1:
                    Undo.PerformUndo();
                    Check(path == null, "One Undo removes the completed draft");
                    Undo.PerformRedo();
                    path = Object.FindObjectsByType<BezierPath>(FindObjectsSortMode.None).Single();
                    Check(path.closed && path.knots.Count == 4, "Redo restores the closed boundary");
                    VerifyMeshes();
                    break;
                case 2:
                    Check(errorLog == null, "Scene drawing and rendering completed without errors");
                    Finish(null);
                    return;
            }
        }
        catch (Exception e) { Finish(e); }
    }

    static void VerifyMeshes()
    {
        var settings = new PathMeshSettings { kind = PathMeshKind.ElectronicFence, fenceHeight = 2.5f,
            fenceBaseOffset = .3f, step = 1.37f, metersPerTile = 2f };
        var mesh = PathMeshBuilder.Build(path, settings);
        try
        {
            var vertices = mesh.vertices;
            var normals = mesh.normals;
            var triangles = mesh.triangles;
            bool upright = true;
            for (int i = 0; i < vertices.Length; i += 2)
                upright &= ((vertices[i + 1] - vertices[i]) - Vector3.up * settings.fenceHeight).sqrMagnitude < 1e-8f;
            Check(upright && vertices.Where((_, i) => i % 2 == 0).All(p => Mathf.Abs(p.y - .3f) < .001f),
                "XZ floor produces exact +Y wall height and base offset");
            foreach (var knot in path.knots)
            {
                var corner = path.transform.TransformPoint(knot.position) + Vector3.up * .3f;
                Check(vertices.Any(p => Vector3.Distance(p, corner) < .0001f), "Mesh keeps an exact polygon corner");
            }
            Check(Vector3.Distance(vertices[0], vertices[vertices.Length - 2]) < 1e-5f &&
                Mathf.Abs(mesh.uv.Last().x - path.Length * .5f) < .0001f && mesh.uv2.First().x == 0 && mesh.uv2.Last() == Vector2.one,
                "The closed seam meets geometrically with tiled UV0 and normalized UV1");
            for (int i = 0; i < triangles.Length; i += 3)
            {
                int u = triangles[i], v = triangles[i + 1], w = triangles[i + 2];
                if (Vector3.Dot(Vector3.Cross(vertices[v] - vertices[u], vertices[w] - vertices[u]), normals[u]) <= 0)
                    throw new InvalidOperationException("Fence contains reversed or degenerate triangles");
            }
            Check(normals.All(n => Mathf.Abs(n.y) < .001f), "Vertical wall normals match the face winding");
            settings.fenceDoubleSided = true;
            var doubled = PathMeshBuilder.Build(path, settings);
            Check(doubled.GetIndexCount(0) == mesh.GetIndexCount(0) * 2, "Optional back faces provide two-sided geometry for culled custom materials");
            Object.DestroyImmediate(doubled);
            settings.fenceDoubleSided = false;
        }
        finally { Object.DestroyImmediate(mesh); }

        foreach (var axis in new[] { PathFenceAxis.X, PathFenceAxis.Z })
        {
            path.transform.rotation = Quaternion.FromToRotation(Vector3.up, PathMeshBuilder.FenceAxis(axis));
            settings.fenceAxis = axis;
            var rotated = PathMeshBuilder.Build(path, settings);
            Check(Vector3.Distance(rotated.vertices[1] - rotated.vertices[0], PathMeshBuilder.FenceAxis(axis) * settings.fenceHeight) < .0001f,
                axis + " axis produces equivalent perpendicular wall geometry");
            Object.DestroyImmediate(rotated);
        }
        settings.fenceLocalAxis = true;
        settings.fenceAxis = PathFenceAxis.Y;
        var local = PathMeshBuilder.Build(path, settings);
        Check(Vector3.Distance(local.vertices[1] - local.vertices[0], path.transform.up * settings.fenceHeight) < .0001f,
            "The local-axis option follows a rotated path");
        Object.DestroyImmediate(local);
        path.transform.rotation = Quaternion.identity;
        settings.fenceLocalAxis = false;

        PathSceneTool.Edit(path);
        Refresh(settings, null);
        var temporary = PathAuthoringPreview.PreviewMesh;
        Check(temporary != null && !EditorUtility.IsPersistent(temporary), "Live fence uses an unsaved preview mesh");
        var defaultOutput = PathAuthoring.Generate(path, settings, null, null, "Assets");
        var outputRenderer = defaultOutput.GetComponent<MeshRenderer>();
        var material = outputRenderer.sharedMaterial;
        Check(material.shader.name == "CH/Paths/Electronic Fence" && EditorUtility.IsPersistent(material),
            "Default fence gets an independent persistent scan material");
        Check(temporary.vertices.SequenceEqual(defaultOutput.GetComponent<MeshFilter>().sharedMesh.vertices),
            "The generated fence matches the preview geometry");
        PathAuthoringPreview.Stop();
        CaptureFence("electronic-fence.png", c => c.g > .15f && c.b > .2f && c.r < c.b * .6f);

        var custom = new Material(material);
        custom.SetColor("_FenceColor", new Color(1.4f, .23f, .04f, 1));
        AssetDatabase.CreateAsset(custom, "Assets/CustomFence06010.mat");
        path.knots[2].position += new Vector3(.6f, .3f, .76f);
        Refresh(settings, custom);
        Check(!PathAuthoringPreview.PreviewMesh.vertices.SequenceEqual(defaultOutput.GetComponent<MeshFilter>().sharedMesh.vertices),
            "Moving a knot rebuilds the fence preview");
        var replaced = PathAuthoring.Generate(path, settings, custom, null, "Assets");
        Check(defaultOutput == null && replaced.GetComponent<MeshRenderer>().sharedMaterial == custom,
            "Regenerate commits the original custom material and replaces the old fence");
        PathAuthoringPreview.Stop();
        CaptureFence("electronic-fence-custom.png", c => c.r > .2f && c.g > .04f && c.r > c.g * 2f);
        Check(Mathf.Abs(custom.GetColor("_FenceColor").r - 1.4f) < .001f, "The assigned custom material remains editable and unmodified");
    }

    static void Refresh(PathMeshSettings settings, Material material)
    {
        PathAuthoringPreview.Configure(path, null, new PathPlacementSettings(), settings, material, null, false, true);
        var type = typeof(PathAuthoringPreview);
        type.GetField("next", StaticMethods).SetValue(null, 0d);
        type.GetMethod("Tick", StaticMethods).Invoke(null, null);
    }

    static void CaptureFence(string file, Func<Color, bool> matches)
    {
        var camera = new GameObject("Fence evidence camera").AddComponent<Camera>();
        var centerWorld = path.transform.TransformPoint(path.knots.Aggregate(Vector3.zero, (sum, knot) => sum + knot.position) / path.knots.Count);
        camera.transform.position = centerWorld + new Vector3(8, 10, -12);
        camera.transform.LookAt(centerWorld + Vector3.up);
        camera.clearFlags = CameraClearFlags.SolidColor;
        camera.backgroundColor = new Color(.025f, .04f, .07f, 1);
        camera.orthographic = true;
        camera.orthographicSize = 6.5f;
        var target = RenderTexture.GetTemporary(960, 680, 24, RenderTextureFormat.ARGB32);
        var result = new Texture2D(target.width, target.height, TextureFormat.RGB24, false);
        var previous = RenderTexture.active;
        try
        {
            camera.targetTexture = target;
            camera.Render();
            RenderTexture.active = target;
            result.ReadPixels(new Rect(0, 0, target.width, target.height), 0, 0);
            result.Apply();
            Directory.CreateDirectory("Artifacts");
            File.WriteAllBytes("Artifacts/" + file, result.EncodeToPNG());
            int colored = result.GetPixels().Count(matches);
            Check(colored > 750, file + " rendered " + colored + " fence pixels");
        }
        finally
        {
            camera.targetTexture = null;
            RenderTexture.active = previous;
            RenderTexture.ReleaseTemporary(target);
            Object.DestroyImmediate(result);
            Object.DestroyImmediate(camera.gameObject);
        }
    }

    [Serializable]
    sealed class Report { public string unity, version, pipeline, status, failure; public int count; public string[] passed; }

    static void Finish(Exception error)
    {
        EditorApplication.update -= Tick;
        SceneView.duringSceneGui -= Capture;
        Application.logMessageReceived -= Log;
        Directory.CreateDirectory("Artifacts");
        File.WriteAllText("Artifacts/path-fence.json", JsonUtility.ToJson(new Report
        {
            unity = Application.unityVersion,
            version = UnityEditor.PackageManager.PackageInfo.FindForAssembly(typeof(BezierPath).Assembly)?.version,
            pipeline = GraphicsSettings.currentRenderPipeline == null ? "Built-in" : GraphicsSettings.currentRenderPipeline.GetType().Name,
            status = error == null ? "Passed" : "Failed",
            failure = error?.ToString(),
            count = checks.Count,
            passed = checks.ToArray()
        }, true));
        EditorApplication.Exit(error == null ? 0 : 1);
    }
}
