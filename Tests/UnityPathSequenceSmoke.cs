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

[InitializeOnLoad]
public static class UnityPathSequenceSmoke
{
    const string StateKey = "CH.Sequence073";
    static List<string> checks = new List<string>();
    static double began;
    static string guiError;
    static double panelReady;
    static ASEShaderConverterWindow window;
    static UnityPathSequenceSmoke()
    {
        if (!SessionState.GetBool(StateKey, false)) return;
        checks = new List<string>(JsonUtility.FromJson<Report>(SessionState.GetString(StateKey + ".checks", "{}")).passed);
        EditorApplication.update += RuntimeCheck;
    }
    static void Check(bool value, string description)
    {
        if (!value) throw new InvalidOperationException(description);
        checks.Add(description);
    }
    static bool Near(Vector3 a, Vector3 b, float tolerance = .001f) => Vector3.Distance(a, b) < tolerance;
    static BezierPath MakePath(string name, Vector3 origin, Vector3 end)
    {
        var path = PathAuthoring.Create(PathPreset.Straight, origin);
        path.name = name;
        path.knots[1].position = end - origin;
        path.Invalidate();
        return path;
    }
    public static void Run()
    {
        try
        {
            EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);
            var a = MakePath("A", Vector3.zero, Vector3.forward * 10);
            var b = MakePath("B", Vector3.forward * 10, new Vector3(10, 4, 10));
            var c = MakePath("C", new Vector3(13, 4, 12), new Vector3(16, 5, 20));
            var root = new GameObject("Bird");
            root.transform.position = new Vector3(3, 4, -2);
            var authoredPosition = root.transform.position;
            var follower = PathAuthoring.Attach(a, root);
            follower.drive = PathMotionDrive.Sequence;
            follower.modelForward = PathModelAxis.PositiveX;
            follower.maxBank = 0;
            follower.lookAhead = 0;
            follower.sequence.Add(new PathSequenceStage { path = a, duration = 5 });
            follower.sequence.Add(new PathSequenceStage { kind = PathSequenceKind.Hold, duration = 10, turnToNext = true });
            follower.sequence.Add(new PathSequenceStage { path = b, duration = 8 });
            var timeline = new PathSequenceTimeline(follower, root.transform.rotation);
            Check(Mathf.Abs(timeline.Duration - 23) < .0001f && timeline.Tracks.Count == 3, "5 s flight + 10 s hover + 8 s flight has exactly 23 s duration");
            Check(Near(timeline.Evaluate(2.5f).position, Vector3.forward * 5), "First stage evaluates at its arc-length midpoint");
            var pause = timeline.Evaluate(5);
            foreach (float time in new[] { 5.1f, 8f, 12f, 14.9f, 15f })
                Check(Near(timeline.Evaluate(time).position, pause.position), "Hover position remains fixed at " + time + " s");
            Check(Quaternion.Angle(timeline.Evaluate(5).rotation, timeline.Evaluate(10).rotation) > 20 &&
                Quaternion.Angle(timeline.Evaluate(14.999f).rotation, timeline.Evaluate(15).rotation) < .05f,
                "Hover smoothly turns to the next path orientation");
            Check(Vector3.Dot(timeline.Evaluate(17).rotation * Vector3.right, (b.knots[1].position).normalized) > .999f,
                "Per-target +X forward axis follows the second path");
            Check(Near(timeline.EndPose.position, new Vector3(10, 4, 10)), "Final path reaches its exact endpoint");
            follower.sequence.Add(new PathSequenceStage { path = c, duration = 4, connection = PathSequenceConnection.Smooth, transitionDuration = 2 });
            timeline = new PathSequenceTimeline(follower, root.transform.rotation);
            Check(Mathf.Abs(timeline.Duration - 29) < .0001f && timeline.Tracks[3].Transition, "Disconnected path adds an explicit 2 s transition");
            Check(Near(timeline.Evaluate(23).position, timeline.Evaluate(22.9999f).position) &&
                Near(timeline.Evaluate(25).position, c.transform.position) &&
                Near(timeline.Evaluate(25.0001f).position, timeline.Evaluate(25).position),
                "Smooth bridge is position-continuous at both joins");
            Check(Quaternion.Angle(timeline.Evaluate(24.999f).rotation, timeline.Evaluate(25).rotation) < .05f,
                "Smooth bridge is orientation-continuous at the next path");
            follower.sequence[3].connection = PathSequenceConnection.Direct;
            bool rejected = false;
            try { new PathSequenceTimeline(follower, root.transform.rotation); }
            catch (ArgumentException) { rejected = true; }
            Check(rejected, "A direct disconnected path reports an explicit validation error");
            follower.sequence[3].connection = PathSequenceConnection.Smooth;
            follower.sequence[3].reverse = true;
            timeline = new PathSequenceTimeline(follower, root.transform.rotation);
            Check(Near(timeline.EndPose.position, c.transform.position), "Reverse stage starts at its far endpoint and returns to the first point");
            follower.sequence[3].reverse = false;
            follower.sequence[2].timing = new AnimationCurve(new Keyframe(0, 0), new Keyframe(.5f, .2f), new Keyframe(1, 1));
            timeline = new PathSequenceTimeline(follower, root.transform.rotation);
            Check(Near(timeline.Evaluate(19).position, Vector3.Lerp(b.transform.position, new Vector3(10, 4, 10), .2f)),
                "Each path uses its own normalized timing curve");
            PathMotionPreview.Scrub(follower, 19 / timeline.Duration);
            Check(Near(root.transform.position, timeline.Evaluate(19).position) && !PathMotionPreview.BlocksPathEditing,
                "Paused sequence preview permits path editing");
            var before = root.transform.position;
            b.knots[1].position += Vector3.up * 3;
            b.Invalidate();
            PathMotionPreview.Refresh(follower);
            timeline = new PathSequenceTimeline(follower, Quaternion.identity);
            Check(!Near(before, root.transform.position) && Near(root.transform.position, timeline.Evaluate(19).position),
                "Paused preview follows a changed source path");
            PathMotionPreview.Stop();
            Check(Near(root.transform.position, authoredPosition), "Stopping sequence restores original authored transform");
            var output = new AnimationClip();
            AssetDatabase.CreateAsset(output, AssetDatabase.GenerateUniqueAssetPath("Assets/BirdSequence.anim"));
            var childBinding = EditorCurveBinding.FloatCurve("Visual", typeof(Transform), "m_LocalScale.x");
            AnimationUtility.SetEditorCurve(output, childBinding, AnimationCurve.Linear(0, 1, 29, 2));
            PathMotionAnimation.BakeTransform(follower, output, 60);
            follower.enabled = false;
            foreach (float time in new[] { 0, 2.5f, 8, 14.5f, 19, 24, 27, 29 })
            {
                output.SampleAnimation(root, time);
                var expected = timeline.Evaluate(time);
                Check(Near(root.transform.position, expected.position, .01f) &&
                    Quaternion.Angle(root.transform.rotation, expected.rotation) < .2f, "Native Transform clip matches sequence at " + time + " s");
            }
            Check(AnimationUtility.GetEditorCurve(output, childBinding).Evaluate(29) == 2, "Baking preserves child animation curves");
            follower.sequence[1].duration = 15;
            PathMotionAnimation.BakeTransform(follower, output, 60);
            Check(Mathf.Abs(output.length - 34) < .001f && follower.bakedClip == output, "Extending hover rebakes the same clip at the new 34 s duration");
            follower.enabled = true;
            root.transform.position = authoredPosition;
            root.transform.rotation = Quaternion.identity;
            follower.sequence[0].duration = .6f;
            follower.sequence[1].duration = .8f;
            follower.sequence[2].duration = .6f;
            follower.sequence[3].duration = .6f;
            follower.sequence[3].transitionDuration = .4f;
            Check(EditorSceneManager.SaveScene(root.scene, "Assets/SequenceRuntime.unity"), "Sequence with multiple scene path references saves");
            ASEShaderConverterWindow.OpenPathTools();
            window = Resources.FindObjectsOfTypeAll<ASEShaderConverterWindow>().Single();
            const BindingFlags fields = BindingFlags.Instance | BindingFlags.NonPublic;
            var panel = typeof(ASEShaderConverterWindow).GetField("paths", fields).GetValue(window);
            panel.GetType().GetField("path", fields).SetValue(panel, a);
            panel.GetType().GetField("motionTarget", fields).SetValue(panel, root);
            panel.GetType().GetField("tab", fields).SetValue(panel, 3);
            window.position = new Rect(35, 50, 850, 650);
            window.Show();
            SceneView.lastActiveSceneView?.Repaint();
            Application.logMessageReceived += Log;
            panelReady = EditorApplication.timeSinceStartup + 2;
            EditorApplication.update += FinishPanelCheck;
        }
        catch (Exception e) { Finish(e); }
    }
    static void Log(string message, string stack, LogType type)
    {
        if (type == LogType.Error || type == LogType.Exception || type == LogType.Assert) guiError = message + "\n" + stack;
    }
    static void FinishPanelCheck()
    {
        if (EditorApplication.timeSinceStartup < panelReady) return;
        EditorApplication.update -= FinishPanelCheck;
        Application.logMessageReceived -= Log;
        try
        {
            Check(guiError == null, "The unified multi-path panel and Scene guides render without errors");
            var editor = typeof(PathFollowerEditor).Assembly.GetType("CH.CustomTools.Paths.Editor.PathSequenceEditor");
            var guide = editor.GetField("guideTarget", BindingFlags.Static | BindingFlags.NonPublic).GetValue(null);
            Check(guide == GameObject.Find("Bird").GetComponent<PathFollower>(), "Motion panel activates its own sequence guides");
            window.Close();
            SessionState.SetString(StateKey + ".checks", JsonUtility.ToJson(new Report { passed = checks.ToArray() }));
            SessionState.SetBool(StateKey, true);
            EditorApplication.EnterPlaymode();
        }
        catch (Exception e) { Finish(e); }
    }
    static bool sawHold;
    static void RuntimeCheck()
    {
        if (!EditorApplication.isPlaying) return;
        try
        {
            if (began == 0) began = EditorApplication.timeSinceStartup;
            if (EditorApplication.timeSinceStartup - began > 12) throw new TimeoutException("Runtime sequence did not finish.");
            var bird = GameObject.Find("Bird").GetComponent<PathFollower>();
            if (bird.IsRunning && Near(bird.transform.position, Vector3.forward * 10, .01f)) sawHold = true;
            if (bird.IsRunning) return;
            Check(sawHold, "Runtime sequence actually pauses at path A endpoint");
            Check(Near(bird.transform.position, new Vector3(16, 5, 20), .01f), "Runtime sequence stops at the final path endpoint");
            Finish(null);
        }
        catch (Exception e) { Finish(e); }
    }
    static void Finish(Exception error)
    {
        EditorApplication.update -= RuntimeCheck;
        SessionState.EraseBool(StateKey);
        SessionState.EraseString(StateKey + ".checks");
        PathMotionPreview.Stop();
        Directory.CreateDirectory("Artifacts");
        File.WriteAllText("Artifacts/path-sequence.json", JsonUtility.ToJson(new Report
        {
            unity = Application.unityVersion,
            version = UnityEditor.PackageManager.PackageInfo.FindForAssembly(typeof(PathFollower).Assembly).version,
            status = error == null ? "Passed" : "Failed",
            failure = error?.ToString(),
            count = checks.Count,
            passed = checks.ToArray()
        }, true));
        EditorApplication.Exit(error == null ? 0 : 1);
    }
    [Serializable]
    sealed class Report { public string unity, version, status, failure; public int count; public string[] passed; }
}
