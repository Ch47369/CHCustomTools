using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using CH.CustomTools.Paths;
using CH.CustomTools.Paths.Editor;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;

[InitializeOnLoad]
public static class UnityPathMotionAnimationSmoke
{
    static readonly List<string> checks = new List<string>();
    const string RuntimeKey = "CH.PathMotion071.Runtime";
    const string ChecksKey = "CH.PathMotion071.Checks";
    static double started;
    static UnityPathMotionAnimationSmoke()
    {
        if (SessionState.GetBool(RuntimeKey, false))
        {
            checks.AddRange(JsonUtility.FromJson<Report>(SessionState.GetString(ChecksKey, "{}")).passed);
            EditorApplication.update += RuntimeTick;
        }
    }
    static void Check(bool result, string description)
    {
        if (!result) throw new InvalidOperationException(description);
        checks.Add(description);
    }

    static void Sample(AnimationClip clip, GameObject target, float seconds)
    {
        AnimationMode.BeginSampling();
        try { AnimationMode.SampleAnimationClip(target, clip, seconds); }
        finally { AnimationMode.EndSampling(); }
    }

    public static void Run()
    {
        Exception failure = null;
        bool runtimePending = false;
        try
        {
            EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);
            var path = PathAuthoring.Create(PathPreset.Curve, Vector3.zero);
            path.knots[1].position += Vector3.up * 2;
            path.Invalidate();
            var parent = new GameObject("Parent");
            parent.transform.SetPositionAndRotation(new Vector3(2, 3, -5), Quaternion.Euler(14, -28, 8));
            var target = new GameObject("Moving object");
            target.transform.SetParent(parent.transform, false);
            target.transform.localPosition = new Vector3(-2, 4, 5);
            target.transform.localRotation = Quaternion.Euler(23, 46, 17);
            var originalPosition = target.transform.localPosition;
            var originalRotation = target.transform.localRotation;
            var follower = PathAuthoring.Attach(path, target);
            follower.animationDuration = 4;
            follower.maxBank = 0;
            follower.lookAhead = 0;
            foreach (PathModelAxis forward in Enum.GetValues(typeof(PathModelAxis)))
            foreach (PathModelAxis up in Enum.GetValues(typeof(PathModelAxis)))
            {
                var forwardVector = PathFollower.AxisVector(forward);
                var upVector = PathFollower.AxisVector(up);
                if (Mathf.Abs(Vector3.Dot(forwardVector, upVector)) > .5f) continue;
                follower.modelForward = forward;
                follower.modelUp = up;
                var pose = follower.PoseAtProgress(.4f);
                var rot = follower.RotationFor(pose);
                Check(Vector3.Dot(rot * forwardVector, pose.tangent) > .9999f &&
                    Vector3.Dot(rot * upVector, pose.up) > .9999f, "Axis pair " + forward + " / " + up);
            }
            follower.modelForward = PathModelAxis.PositiveX;
            follower.modelUp = PathModelAxis.PositiveY;
            follower.orientation = PathOrientation.Upright;
            var upright = follower.PoseAtProgress(.5f);
            Check(Mathf.Abs(upright.tangent.y) < .0001f && upright.up == Vector3.up, "Ground motion stays upright");
            follower.orientation = PathOrientation.Transported;
            var clip = PathMotionAnimation.CreateProgressClip(follower, AssetDatabase.GenerateUniqueAssetPath("Assets/Progress.anim"));
            var progressBinding = EditorCurveBinding.FloatCurve("", typeof(PathFollower), "progress");
            var keys = new AnimationCurve(new Keyframe(0, 0), new Keyframe(1, .2f), new Keyframe(2, .2f), new Keyframe(4, 1));
            AnimationUtility.SetEditorCurve(clip, progressBinding, keys);
            PathMotionAnimation.AttachProgressController(follower);
            Check(target.GetComponent<Animator>().runtimeAnimatorController != null, "Progress clip has an assigned Animator controller");
            PathMotionPreview.Scrub(follower, .65f);
            Check(Vector3.Distance(target.transform.position, follower.PoseAtProgress(.65f).position) < .0001f, "Scrub sets moving object position");
            PathMotionPreview.Stop();
            Check(target.transform.localPosition == originalPosition && Quaternion.Angle(target.transform.localRotation, originalRotation) < .001f, "Stop restores original pose");
            AnimationMode.StartAnimationMode();
            try
            {
                Sample(clip, target, 1.5f);
                Check(Mathf.Abs(follower.progress - .2f) < .001f, "Unity samples the native Progress property");
                var expected = follower.PoseAtProgress(.2f);
                Check(Vector3.Distance(target.transform.position, expected.position) < .001f,
                    "Unity AnimationMode evaluates live path pose");
                var before = target.transform.position;
                path.knots[1].position += Vector3.up * 4;
                path.Invalidate();
                Sample(clip, target, 1.5f);
                // An editor update also refreshes the pose when the sampled progress value is unchanged.
                typeof(PathMotionAnimation).GetMethod("RefreshAnimationPreview",
                    System.Reflection.BindingFlags.Static | System.Reflection.BindingFlags.NonPublic).Invoke(null, null);
                Check(Vector3.Distance(before, target.transform.position) > .01f &&
                    Vector3.Distance(target.transform.position, follower.PoseAtProgress(.2f).position) < .001f,
                    "Editing the path updates the same native keyframes");
            }
            finally { AnimationMode.StopAnimationMode(); }
            Check(Vector3.Distance(target.transform.localPosition, originalPosition) < .001f &&
                Quaternion.Angle(target.transform.localRotation, originalRotation) < .01f, "Native preview restores transform on exit");
            Check(AnimationUtility.GetEditorCurve(clip, progressBinding).keys.SequenceEqual(keys.keys), "Progress keyframes are unchanged");
            var output = new AnimationClip();
            AssetDatabase.CreateAsset(output, AssetDatabase.GenerateUniqueAssetPath("Assets/Baked.anim"));
            var childCurve = EditorCurveBinding.FloatCurve("Visual", typeof(Transform), "m_LocalScale.x");
            AnimationUtility.SetEditorCurve(output, childCurve, AnimationCurve.Linear(0, 1, 4, 2));
            PathMotionAnimation.BakeTransform(follower, output, 60);
            var bindings = AnimationUtility.GetCurveBindings(output);
            Check(bindings.Count(b => b.path == "" && b.type == typeof(Transform)) == 7, "Baked clip contains position and quaternion curves");
            Check(AnimationUtility.GetEditorCurve(output, childCurve).Evaluate(4) == 2, "Child animation is preserved");
            follower.enabled = false;
            output.SampleAnimation(target, 1.5f);
            Check(Vector3.Distance(target.transform.position, follower.PoseAtProgress(.2f).position) < .001f &&
                Quaternion.Angle(target.transform.rotation, follower.RotationFor(follower.PoseAtProgress(.2f))) < .05f, "Standalone Transform animation matches path position and rotation");
            var previous = target.transform.position;
            path.knots[1].position += Vector3.up * 3;
            path.Invalidate();
            PathMotionAnimation.BakeTransform(follower, output, 60);
            output.SampleAnimation(target, 1.5f);
            Check(Vector3.Distance(previous, target.transform.position) > .01f &&
                Vector3.Distance(target.transform.position, follower.PoseAtProgress(.2f).position) < .001f,
                "Rebake updates the original output asset");
            Check(AnimationUtility.GetEditorCurve(output, childCurve).Evaluate(4) == 2, "Rebake preserves child animation");
            follower.enabled = true;
            follower.progress = 0;
            target.transform.localPosition = originalPosition;
            target.transform.localRotation = originalRotation;
            Check(EditorSceneManager.SaveScene(target.scene, "Assets/MotionRuntime.unity"), "Motion scene saves with generated assets");
            SessionState.SetString(ChecksKey, JsonUtility.ToJson(new Report { passed = checks.ToArray() }));
            SessionState.SetBool(RuntimeKey, true);
            runtimePending = true;
            EditorApplication.EnterPlaymode();
        }
        catch (Exception e) { failure = e; }
        finally
        {
            PathMotionPreview.Stop();
            if (AnimationMode.InAnimationMode()) AnimationMode.StopAnimationMode();
            if (!runtimePending || failure != null) Finish(failure);
        }
    }
    static void RuntimeTick()
    {
        if (!EditorApplication.isPlaying) return;
        if (started == 0) started = EditorApplication.timeSinceStartup;
        try
        {
            if (EditorApplication.timeSinceStartup - started > 10) throw new TimeoutException("Runtime Animator did not advance progress.");
            var target = GameObject.Find("Moving object");
            var follower = target.GetComponent<PathFollower>();
            if (follower.progress < .15f || !Application.IsPlaying(target)) return;
            var expected = follower.PoseAtProgress(follower.progress);
            if (Vector3.Distance(target.transform.position, expected.position) > .001f) return;
            Check(true, "Runtime Animator advances the progress property and LateUpdate follows it");
            Check(Quaternion.Angle(target.transform.rotation, follower.RotationFor(expected)) < .05f,
                "Runtime Animator preserves selected model forward/up axes");
            Finish(null);
        }
        catch (Exception e) { Finish(e); }
    }
    static void Finish(Exception failure)
    {
        EditorApplication.update -= RuntimeTick;
        SessionState.EraseBool(RuntimeKey);
        SessionState.EraseString(ChecksKey);
        Directory.CreateDirectory("Artifacts");
        File.WriteAllText("Artifacts/path-motion.json", JsonUtility.ToJson(new Report
        {
            unity = Application.unityVersion,
            version = UnityEditor.PackageManager.PackageInfo.FindForAssembly(typeof(PathFollower).Assembly).version,
            status = failure == null ? "Passed" : "Failed",
            failure = failure?.ToString(),
            passed = checks.ToArray(),
            count = checks.Count
        }, true));
        EditorApplication.Exit(failure == null ? 0 : 1);
    }

    [Serializable]
    sealed class Report { public string unity, version, status, failure; public string[] passed; public int count; }
}
