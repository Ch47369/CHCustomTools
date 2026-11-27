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
    static Vector2 center, received, offset, firstPoint, heightTop, heightEnd, wholeAxis, wholeAxisEnd;
    static Vector3 wholeBefore;
    static Vector3[] wholeKnots;
    static PathMeshSettings heightSettings;
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
            deadline = next + 180;
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
        {
            center = GUIUtility.GUIToScreenPoint(HandleUtility.WorldToGUIPoint(Vector3.zero)) - view.position.position;
            if (path != null)
            {
                var point = path.transform.TransformPoint(path.knots[0].position);
                firstPoint = GUIUtility.GUIToScreenPoint(HandleUtility.WorldToGUIPoint(point)) - view.position.position;
                if (path.knots.Count == 3 && !path.closed)
                {
                    var center = WholeCenter(path);
                    float handleSize = HandleUtility.GetHandleSize(center);
                    wholeAxis = GUIUtility.GUIToScreenPoint(HandleUtility.WorldToGUIPoint(center + Vector3.right * handleSize * .8f)) - view.position.position;
                    wholeAxisEnd = GUIUtility.GUIToScreenPoint(HandleUtility.WorldToGUIPoint(center + Vector3.right * (handleSize * .8f + 1f))) - view.position.position;
                }
                if (heightSettings != null)
                {
                    var top = point + Vector3.up * PathMeshBuilder.FenceHeight(heightSettings, path.knots[0]);
                    heightTop = GUIUtility.GUIToScreenPoint(HandleUtility.WorldToGUIPoint(top)) - view.position.position;
                    heightEnd = GUIUtility.GUIToScreenPoint(HandleUtility.WorldToGUIPoint(top + Vector3.up * 1.5f)) - view.position.position;
                }
            }
        }
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
                    PathSceneTool.Active = false;
                    BeginDraft();
                    view.Repaint();
                    break;
                case 3:
                    Click(-160, -105);
                    Click(120, -79, true);
                    Click(126, 103, true);
                    var draft = typeof(PathSceneTool).Assembly.GetType("CH.CustomTools.Paths.Editor.PathFenceDraft");
                    var draftPoints = (List<Vector3>)draft.GetField("points", StaticMethods).GetValue(null);
                    Check(draftPoints.Count == 3, "Open draft accepts three clicks after entering drawing mode");
                    CHValidationInput.Send(view, new Event { type = EventType.MouseDown, mousePosition = center + offset, button = 1 });
                    break;
                case 4:
                    CHValidationInput.Send(view, new Event { type = EventType.MouseUp, mousePosition = center + offset, button = 1 });
                    break;
                case 5:
                    Check(path != null && !path.closed && path.knots.Count == 3, "Right-click finishes the open fence without adding a closing edge");
                    PathSceneTool.Edit(path);
                    var selectWhole = typeof(PathSceneTool).GetMethod("SelectWhole", StaticMethods);
                    selectWhole.Invoke(null, new object[] { path });
                    Check(Tools.hidden && !PathSceneTool.PointEditing && Tools.pivotMode == PivotMode.Center,
                        "Selecting the path starts whole-path editing with centered handles");
                    Key(KeyCode.W);
                    Tools.current = Tool.Move;
                    Tools.pivotRotation = PivotRotation.Global;
                    wholeBefore = path.transform.position;
                    wholeKnots = path.knots.Select(k => k.position).ToArray();
                    view.Repaint();
                    break;
                case 6:
                    CHValidationInput.Send(view, new Event { type = EventType.MouseMove, mousePosition = wholeAxis + offset });
                    break;
                case 7:
                    var axisDelta = wholeAxisEnd - wholeAxis;
                    foreach (var kind in new[] { EventType.MouseDown, EventType.MouseDrag, EventType.MouseUp })
                        CHValidationInput.Send(view, new Event { type = kind, mousePosition =
                            (kind == EventType.MouseDown ? wholeAxis : wholeAxisEnd) + offset,
                            delta = kind == EventType.MouseDrag ? axisDelta : Vector2.zero, button = 0 });
                    Check(Vector3.Distance(path.transform.position, wholeBefore) > .3f &&
                        path.knots.Select(k => k.position).SequenceEqual(wholeKnots),
                        "Dragging the centered Scene axis moves the entire path without changing individual knots");
                    Undo.FlushUndoRecordObjects();
                    Undo.PerformUndo();
                    Check(Vector3.Distance(path.transform.position, wholeBefore) < .0001f, "Undo restores the whole-path transform");
                    view.Repaint();
                    break;
                case 8:
                    CHValidationInput.Send(view, new Event { type = EventType.MouseMove, mousePosition = firstPoint + offset });
                    break;
                case 9:
                    var root = path.transform.position;
                    var other = path.knots[1].position;
                    var before = path.knots[0].position;
                    var delta = new Vector2(-28, -20);
                    foreach (var kind in new[] { EventType.MouseDown, EventType.MouseDrag, EventType.MouseUp })
                        CHValidationInput.Send(view, new Event { type = kind, mousePosition = firstPoint + offset +
                            (kind == EventType.MouseDown ? Vector2.zero : delta), delta = kind == EventType.MouseDrag ? delta : Vector2.zero, button = 0 });
                    Check(path.transform.position == root && path.knots[1].position == other &&
                        Vector3.Distance(path.knots[0].position, before) > .05f, "Dragging the first point moves only that point");
                    Check(PathSceneTool.PointEditing, "Clicking a point automatically switches to individual point editing");
                    var whole = typeof(PathSceneTool).GetProperty("WholePath", StaticMethods);
                    whole.SetValue(null, true);
                    Check(!PathSceneTool.PointEditing && Tools.hidden && Tools.pivotMode == PivotMode.Center, "Whole-path mode uses a dedicated centered Transform handle");
                    whole.SetValue(null, false);
                    Check(PathSceneTool.PointEditing && Tools.hidden, "Point editing restores exclusive point handles");
                    heightSettings = new PathMeshSettings { kind = PathMeshKind.ElectronicFence };
                    typeof(PathSceneTool).Assembly.GetType("CH.CustomTools.Paths.Editor.PathFenceHeightEditing")
                        .GetMethod("Configure", StaticMethods).Invoke(null, new object[] { path, heightSettings });
                    view.LookAtDirect(path.transform.position, Quaternion.Euler(22, 18, 0), 8);
                    view.Repaint();
                    break;
                case 10:
                    CHValidationInput.Send(view, new Event { type = EventType.MouseMove, mousePosition = heightTop + offset });
                    break;
                case 11:
                    var originalHeight = PathMeshBuilder.FenceHeight(heightSettings, path.knots[0]);
                    var originalPoint = path.knots[0].position;
                    var heightDelta = heightEnd - heightTop;
                    foreach (var kind in new[] { EventType.MouseDown, EventType.MouseDrag, EventType.MouseUp })
                        CHValidationInput.Send(view, new Event { type = kind, mousePosition = (kind == EventType.MouseDown ? heightTop : heightEnd) + offset,
                            delta = kind == EventType.MouseDrag ? heightDelta : Vector2.zero, button = 0 });
                    Check(PathMeshBuilder.FenceHeight(heightSettings, path.knots[0]) > originalHeight + .3f &&
                        path.knots[0].position == originalPoint && !path.knots[1].fenceHeightOverride, "Dragging the orange height handle changes only the selected point height");
                    PathSceneTool.Active = false;
                    Check(!Tools.hidden, "Disabling path editing restores Unity tools");
                    break;
                case 12:
                    Check(errorLog == null, "Scene drawing and rendering completed without errors");
                    view.LookAtDirect(Vector3.zero, Quaternion.LookRotation(Vector3.down, Vector3.forward), 8);
                    BeginDraft();
                    view.Repaint();
                    break;
                case 13:
                    Click(-165, -100);
                    DrawDraggedPoint(0, -85, new Vector2(45, -80), false);
                    DrawDraggedPoint(135, 80, new Vector2(30, 65), true);
                    Key(KeyCode.Return);
                    Check(path != null && !path.closed && path.knots.Count == 3, "Click and drag gesture produces an open three-point path");
                    Check(path.knots[0].outgoing == Vector3.zero && path.knots[1].incoming.sqrMagnitude > .01f,
                        "Dragging the second point sets a real Bezier tangent");
                    Check(path.knots[1].outgoing == Vector3.zero && path.knots[2].incoming == Vector3.zero && path.knots[2].outgoing == Vector3.zero,
                        "Ctrl-drawing a point forces its incoming segment and outgoing tangent straight");
                    path.Cubic(1, .5f, out var middle, out _);
                    Check(Vector3.Distance(middle, path.transform.TransformPoint((path.knots[1].position + path.knots[2].position) * .5f)) < .0001f,
                        "Ctrl-drawn segment has no curvature");
                    VerifyStylePresets();
                    Check(errorLog == null, "All drawing and material checks finish without Console errors");
                    Finish(null);
                    return;
            }
        }
        catch (Exception e) { Finish(e); }
    }

    static void DrawDraggedPoint(float x, float y, Vector2 delta, bool ctrl)
    {
        var point = center + new Vector2(x, y) + offset;
        CHValidationInput.Send(view, new Event { type = EventType.MouseDown, button = 0, mousePosition = point, control = ctrl });
        CHValidationInput.Send(view, new Event { type = EventType.MouseDrag, button = 0, mousePosition = point + delta, delta = delta, control = ctrl });
        CHValidationInput.Send(view, new Event { type = EventType.MouseUp, button = 0, mousePosition = point + delta, control = ctrl });
    }
    static void VerifyStylePresets()
    {
        var method = typeof(PathSceneTool).Assembly.GetType("CH.CustomTools.Paths.Editor.PathFenceMaterial").GetMethod("Create", StaticMethods);
        var seen = new HashSet<Texture>();
        foreach (PathFenceStyle style in Enum.GetValues(typeof(PathFenceStyle)))
        {
            var material = (Material)method.Invoke(null, new object[] { style });
            try
            {
                Check(material.shader.name.Contains("Custom2TexV2") && material.GetTexture("_MainTex") != null &&
                    seen.Add(material.GetTexture("_MainTex")) && material.GetTexture("_AddTex") != null &&
                    material.GetFloat("_TexBlendMode") == 2 && Mathf.Abs(material.GetVector("_AddTexPanner").y) > .1f,
                    style + " uses Custom2TexV2 with a distinct pattern and moving additive scan");
            }
            finally { Object.DestroyImmediate(material); }
        }
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
        string expectedPipeline = GraphicsSettings.currentRenderPipeline == null ? "Built-in" :
            GraphicsSettings.currentRenderPipeline.GetType().Name.Contains("HDRender") ? "HDRP" : "URP";
        Check(material.shader.name == "CH/Paths/Custom2TexV2/" + expectedPipeline && EditorUtility.IsPersistent(material),
            "Default fence uses the matching native ASE Custom2TexV2 shader");
        for (int i = 0; i < material.passCount; i++) ShaderUtil.CompilePass(material, i, true);
        Check(!ShaderUtil.ShaderHasError(material.shader), "All material passes compile synchronously");
        Check(temporary.vertices.Zip(defaultOutput.GetComponent<MeshFilter>().sharedMesh.vertices, (a, b) => Vector3.Distance(a, defaultOutput.transform.TransformPoint(b))).All(d => d < .0001f),
            "The generated fence matches the preview geometry");
        Check(!PathSceneTool.PointEditing && !Tools.hidden && Tools.pivotMode == PivotMode.Center,
            "Selecting the generated mesh automatically exposes its native centered Transform tools");
        Check(defaultOutput.GetComponent<MeshFilter>().sharedMesh.bounds.center.sqrMagnitude < .000001f &&
            Vector3.Distance(defaultOutput.transform.position, temporary.bounds.center) < .0001f,
            "Generated mesh origin is the geometric bounds center");
        PathAuthoringPreview.Stop();
        CaptureFence("electronic-fence.png", c => c.g > .15f && c.b > .2f && c.r < c.b * .6f);
        var styleMethod = typeof(PathSceneTool).Assembly.GetType("CH.CustomTools.Paths.Editor.PathFenceMaterial").GetMethod("Create", StaticMethods);
        foreach (var style in new[] { PathFenceStyle.AmberWarning, PathFenceStyle.VioletEnergy })
        {
            var styled = (Material)styleMethod.Invoke(null, new object[] { style });
            try
            {
                outputRenderer.sharedMaterial = styled;
                CaptureFence(style + ".png", c => style == PathFenceStyle.AmberWarning
                    ? c.r > .2f && c.g > .06f && c.r > c.g * 1.5f
                    : c.b > .2f && c.r > .09f && c.b > c.r * 1.3f);
            }
            finally { outputRenderer.sharedMaterial = material; Object.DestroyImmediate(styled); }
        }


        var custom = new Material(material);
        custom.SetColor("_MainTexColor", new Color(1.4f, .23f, .04f, 1));
        custom.SetFloat("_TexBlendMode", 0);
        AssetDatabase.CreateAsset(custom, "Assets/CustomFence06010.mat");
        path.knots[2].position += new Vector3(.6f, .3f, .76f);
        Refresh(settings, custom);
        Check(!PathAuthoringPreview.PreviewMesh.vertices.SequenceEqual(defaultOutput.GetComponent<MeshFilter>().sharedMesh.vertices.Select(defaultOutput.transform.TransformPoint)),
            "Moving a knot rebuilds the fence preview");
        var replaced = PathAuthoring.Generate(path, settings, custom, null, "Assets");
        Check(defaultOutput == null && replaced.GetComponent<MeshRenderer>().sharedMaterial == custom,
            "Regenerate commits the original custom material and replaces the old fence");
        PathAuthoringPreview.Stop();
        CaptureFence("electronic-fence-custom.png", c => c.r > .2f && c.g > .04f && c.r > c.g * 2f);
        Check(Mathf.Abs(custom.GetColor("_MainTexColor").r - 1.4f) < .001f, "The assigned custom material remains editable and unmodified");
        var controls = typeof(PathSceneTool).Assembly.GetType("CH.CustomTools.Paths.Editor.PathFenceHeightEditing");
        controls.GetMethod("SetHeight", StaticMethods).Invoke(null, new object[] { path, settings, 0, 4.75f });
        var variable = PathMeshBuilder.Build(path, settings);
        Check(Mathf.Abs(Vector3.Distance(variable.vertices[0], variable.vertices[1]) - 4.75f) < .001f &&
            Mathf.Abs(Vector3.Distance(variable.vertices[variable.vertexCount - 2], variable.vertices[variable.vertexCount - 1]) - 4.75f) < .001f,
            "Individual point height controls both sides of the closed seam");
        Check(variable.colors32.All(c => c.r == 255 && c.a == 255), "Generated fence supplies valid white vertex colors to Custom2TexV2");
        Object.DestroyImmediate(variable);
        VerifyDimensions();
    }

    static void VerifyDimensions()
    {
        var testPath = new GameObject("Dimension test path").AddComponent<BezierPath>();
        testPath.knots = new List<PathKnot> { new PathKnot(new Vector3(1, 0, 1)), new PathKnot(new Vector3(4, 1, 4)), new PathKnot(new Vector3(2, 2, 8)) };
        try
        {
            foreach (PathMeshKind kind in Enum.GetValues(typeof(PathMeshKind)))
            {
                var settings = new PathMeshSettings { kind = kind, step = .5f };
                var original = PathMeshBuilder.Build(testPath, settings);
                settings.dimensionsScale = new Vector3(1.7f, .8f, 1.3f);
                var resized = PathMeshBuilder.Build(testPath, settings);
                try
                {
                    Check(Vector3.Distance(resized.bounds.size, Vector3.Scale(original.bounds.size, settings.dimensionsScale)) < .0001f &&
                        Vector3.Distance(resized.bounds.center, original.bounds.center) < .0001f,
                        kind + " supports independent XYZ dimensions around its geometric center");
                    Check(resized.uv.SequenceEqual(original.uv) && resized.uv2.SequenceEqual(original.uv2) &&
                        resized.normals.All(n => Mathf.Abs(n.magnitude - 1) < .001f),
                        kind + " retains UVs and valid normals after resizing");
                }
                finally { Object.DestroyImmediate(original); Object.DestroyImmediate(resized); }
            }
            testPath.knots = new List<PathKnot> { new PathKnot(Vector3.zero), new PathKnot(Vector3.forward * 6) };
            testPath.Invalidate();
            foreach (var kind in new[] { PathMeshKind.Ribbon, PathMeshKind.DashedLine, PathMeshKind.Arrows, PathMeshKind.ElectronicFence })
            {
                var settings = new PathMeshSettings { kind = kind, sheetThickness = .3f, step = .5f };
                var thick = PathMeshBuilder.Build(testPath, settings);
                Check(Mathf.Abs((kind == PathMeshKind.ElectronicFence ? thick.bounds.size.x : thick.bounds.size.y) - .3f) < .001f,
                    kind + " has actual adjustable sheet thickness");
                Object.DestroyImmediate(thick);
            }
            var center = WholeCenter(testPath);
            Check(Vector3.Distance(center, Vector3.forward * 3) < .0001f,
                "Whole-path handle uses the curve bounds center, away from the first knot");
        }
        finally { Object.DestroyImmediate(testPath.gameObject); }
    }

    static Vector3 WholeCenter(BezierPath target)
    {
        return (Vector3)typeof(PathSceneTool).Assembly.GetType("CH.CustomTools.Paths.Editor.PathWholeHandle")
            .GetMethod("Center", StaticMethods).Invoke(null, new object[] { target });
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
