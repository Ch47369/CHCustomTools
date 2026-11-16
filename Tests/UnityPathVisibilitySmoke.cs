// Rendered-pixel regression: a curve must exist between the point markers, not merely avoid GUI exceptions.
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using CH.CustomTools.Paths;
using CH.CustomTools.Paths.Editor;
using Object = UnityEngine.Object;

public static class UnityPathVisibilitySmoke
{
    [Serializable] sealed class ImageResult { public string scenario, image; public int samples, visible; public bool gizmos, perspective, generatedChild; }
    [Serializable] sealed class Report { public string unity, version, status, failure; public int count; public string[] passed; public ImageResult[] images; }
    static readonly List<string> checks = new List<string>();
    static readonly List<ImageResult> images = new List<ImageResult>();
    static SceneView view;
    static BezierPath path;
    static GameObject child, blocker;
    static int phase;
    static double next, deadline;
    static RenderTexture captured;
    static string errors;
    static void Check(bool value, string message) { if (!value) throw new Exception(message); checks.Add(message); }
    public static void Run()
    {
        try
        {
            PlayerSettings.runInBackground = true;
            EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);
            path = new GameObject("Visible path").AddComponent<BezierPath>();
            path.knots = new List<PathKnot> { new PathKnot(new Vector3(-4, -2, 0)), new PathKnot(new Vector3(0, 2, 0)), new PathKnot(new Vector3(4, -2, 0)) };
            var output = new GameObject("Generated owner").AddComponent<PathGeneratedOutput>(); output.owner = path;
            child = new GameObject("Generated child"); child.transform.SetParent(output.transform, false);
            blocker = GameObject.CreatePrimitive(PrimitiveType.Cube); blocker.name = "Occluding geometry"; blocker.transform.position = new Vector3(0, 0, -1); blocker.transform.localScale = new Vector3(30, 30, .3f);
            var material = new Material(Shader.Find("Unlit/Color")); material.color = Color.gray; blocker.GetComponent<MeshRenderer>().sharedMaterial = material; blocker.SetActive(false);
            view = EditorWindow.GetWindow<SceneView>(); view.position = new Rect(30, 30, 1000, 780); view.Show(); view.showGrid = false;
            BezierPathEditor.ShowOrientation = false;
            PathSceneTool.Active = true;
            Configure(); view.Focus();
            SceneView.duringSceneGui += Capture; Application.logMessageReceived += Log;
            next = EditorApplication.timeSinceStartup + 3; deadline = next + 60; EditorApplication.update += Tick;
        }
        catch (Exception e) { Finish(e); }
    }
    static void Configure()
    {
        Selection.activeGameObject = phase < 8 && (phase & 2) != 0 ? child : phase == 9 ? null : path.gameObject;
        view.drawGizmos = phase >= 8 || (phase & 1) != 0;
        view.LookAtDirect(Vector3.zero, Quaternion.LookRotation(Vector3.forward), 6); view.orthographic = phase < 4 || phase >= 8;
        blocker.SetActive(phase == 8); captured = null; view.Repaint();
    }
    static void Capture(SceneView scene)
    {
        if (scene == view && Event.current.type == EventType.Repaint) captured = RenderTexture.active;
    }
    static void Log(string message, string stack, LogType type)
    { if (type == LogType.Error || type == LogType.Exception || type == LogType.Assert) errors = message + "\n" + stack; }
    static void Tick()
    {
        try
        {
            if (EditorApplication.timeSinceStartup > deadline) throw new TimeoutException("Path visibility render timed out");
            if (EditorApplication.timeSinceStartup < next || captured == null) return;
            if (errors != null) throw new Exception(errors);
            string scenario = phase == 8 ? "occluded-selected" : phase == 9 ? "unselected-preview" : (view.orthographic ? "ortho" : "perspective") + (Selection.activeGameObject == child ? "-generated-child" : "-path") + (view.drawGizmos ? "-gizmos-on" : "-gizmos-off");
            var previous = RenderTexture.active; Texture2D texture = null;
            try
            {
                RenderTexture.active = captured;
                texture = new Texture2D(captured.width, captured.height, TextureFormat.RGBA32, false);
                texture.ReadPixels(new Rect(0, 0, captured.width, captured.height), 0, 0); texture.Apply();
                int visible = 0, samples = 0;
                for (int segment = 0; segment < path.SegmentCount; segment++) for (int i = 4; i <= 16; i++)
                {
                    Vector3 point, tangent; path.Cubic(segment, i / 20f, out point, out tangent);
                    Vector3 viewport = view.camera.WorldToViewportPoint(point);
                    int x = Mathf.RoundToInt(viewport.x * texture.width), y = Mathf.RoundToInt(viewport.y * texture.height); bool hit = false;
                    for (int dx = -4; dx <= 4 && !hit; dx++) for (int dy = -4; dy <= 4; dy++)
                    {
                        Color c = texture.GetPixel(Mathf.Clamp(x + dx, 0, texture.width - 1), Mathf.Clamp(y + dy, 0, texture.height - 1));
                        if (c.g > .32f && c.b > .32f && c.r < c.g * .72f) { hit = true; break; }
                    }
                    samples++; if (hit) visible++;
                }
                Directory.CreateDirectory("Artifacts"); string image = scenario + ".png"; File.WriteAllBytes("Artifacts/" + image, texture.EncodeToPNG());
                images.Add(new ImageResult { scenario = scenario, image = image, samples = samples, visible = visible, gizmos = view.drawGizmos, perspective = !view.orthographic, generatedChild = Selection.activeGameObject == child });
                Check(visible >= samples * .9f, scenario + ": visible curve between markers " + visible + "/" + samples);
            }
            finally { RenderTexture.active = previous; if (texture != null) Object.DestroyImmediate(texture); }
            if (++phase >= 10) { Check(errors == null, "All curve rendering scenarios finish without Editor errors"); Finish(null); return; }
            Configure(); next = EditorApplication.timeSinceStartup + .7;
        }
        catch (Exception e) { Finish(e); }
    }
    static void Finish(Exception failure)
    {
        EditorApplication.update -= Tick; SceneView.duringSceneGui -= Capture; Application.logMessageReceived -= Log;
        Directory.CreateDirectory("Artifacts");
        File.WriteAllText("Artifacts/path-visibility.json", JsonUtility.ToJson(new Report { unity = Application.unityVersion, version = UnityEditor.PackageManager.PackageInfo.FindForAssembly(typeof(BezierPath).Assembly).version, status = failure == null ? "Passed" : "Failed", failure = failure == null ? "" : failure.ToString(), count = checks.Count, passed = checks.ToArray(), images = images.ToArray() }, true));
        EditorApplication.Exit(failure == null ? 0 : 1);
    }
}
