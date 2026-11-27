using System;
using System.Globalization;
using System.Collections.Generic;
using UnityEditor;
using UnityEditor.Animations;
using UnityEngine;

namespace CH.CustomTools.Paths.Editor
{
    [InitializeOnLoad]
    public static class PathMotionAnimation
    {
        static readonly EditorCurveBinding ProgressBinding =
            EditorCurveBinding.FloatCurve("", typeof(PathFollower), "progress");
        static readonly string[] PositionProperties = { "m_LocalPosition.x", "m_LocalPosition.y", "m_LocalPosition.z" };
        static readonly string[] RotationProperties = { "m_LocalRotation.x", "m_LocalRotation.y", "m_LocalRotation.z", "m_LocalRotation.w" };
        static readonly HashSet<PathFollower> PreviewFollowers = new HashSet<PathFollower>();

        static PathMotionAnimation()
        {
            PathFollower.EditorAnimationApplied += ApplyAnimationPreview;
            EditorApplication.update += RefreshAnimationPreview;
        }

        static void RefreshAnimationPreview()
        {
            if (!AnimationMode.InAnimationMode())
            {
                PreviewFollowers.Clear();
                return;
            }
            PreviewFollowers.RemoveWhere(f => f == null || !f.enabled || f.drive != PathMotionDrive.AnimationProgress ||
                !AnimationMode.IsPropertyAnimated(f, "progress"));
            foreach (var follower in PreviewFollowers)
                ApplyAnimationPreview(follower);
        }

        static void ApplyAnimationPreview(PathFollower follower)
        {
            if (!AnimationMode.InAnimationMode() || !AnimationMode.IsPropertyAnimated(follower, "progress") ||
                !follower.enabled || follower.path == null || EditorUtility.IsPersistent(follower)) return;
            PreviewFollowers.Add(follower);
            var transform = follower.transform;
            var position = transform.localPosition;
            var rotation = transform.localRotation;
            try
            {
                var pose = follower.PoseAtProgress(follower.progress);
                if (follower.orientation != PathOrientation.PositionOnly) follower.RotationFor(pose);
                for (int axis = 0; axis < PositionProperties.Length; axis++)
                    Track(transform, PositionProperties[axis], position[axis]);
                if (follower.orientation != PathOrientation.PositionOnly)
                    for (int axis = 0; axis < RotationProperties.Length; axis++)
                        Track(transform, RotationProperties[axis], rotation[axis]);
                follower.ApplyProgress(follower.progress);
            }
            catch (Exception e) { Debug.LogWarning(e.Message, follower); }
        }

        static void Track(Transform transform, string name, float value)
        {
            if (AnimationMode.IsPropertyAnimated(transform, name)) return;
            var modifications = new PropertyModification
            {
                target = transform,
                propertyPath = name,
                value = value.ToString("R", CultureInfo.InvariantCulture)
            };
            AnimationMode.AddPropertyModification(EditorCurveBinding.FloatCurve("", typeof(Transform), name),
                modifications, true);
        }

        public static AnimationCurve Timing(PathFollower follower)
        {
            return follower.progressClip == null ? null : AnimationUtility.GetEditorCurve(follower.progressClip, ProgressBinding);
        }
        public static float Duration(PathFollower follower)
        {
            return follower.progressClip != null && Timing(follower) != null
                ? follower.progressClip.length : follower.animationDuration;
        }
        public static float ProgressAt(PathFollower follower, float time)
        {
            var curve = Timing(follower);
            float duration = Duration(follower);
            if (duration <= 0 || float.IsNaN(duration) || float.IsInfinity(duration))
                throw new InvalidOperationException("Motion duration must be positive. / 动画时长必须大于零。");
            return Mathf.Clamp01(curve == null ? time / duration : curve.Evaluate(time));
        }

        public static AnimationClip CreateProgressClip(PathFollower follower, string assetPath)
        {
            if (follower == null || follower.path == null || follower.animationDuration <= 0 ||
                float.IsNaN(follower.animationDuration) || float.IsInfinity(follower.animationDuration))
                throw new ArgumentException("Choose a valid path and duration. / 请选择有效路径与时长。");
            if (AssetDatabase.LoadMainAssetAtPath(assetPath) != null)
                throw new ArgumentException("Choose a new animation asset. / 请选择新的动画资源路径。");
            var clip = new AnimationClip { name = System.IO.Path.GetFileNameWithoutExtension(assetPath), frameRate = 60 };
            AnimationUtility.SetEditorCurve(clip, ProgressBinding, AnimationCurve.Linear(0, 0, follower.animationDuration, 1));
            AssetDatabase.CreateAsset(clip, assetPath);
            Undo.RecordObject(follower, "Assign path progress animation");
            follower.progressClip = clip;
            follower.drive = PathMotionDrive.AnimationProgress;
            PrefabUtility.RecordPrefabInstancePropertyModifications(follower);
            EditorUtility.SetDirty(follower);
            AssetDatabase.SaveAssets();
            return clip;
        }

        public static void AttachProgressController(PathFollower follower)
        {
            if (follower.progressClip == null || Timing(follower) == null)
                throw new InvalidOperationException("Create or select a progress animation first. / 请先创建或指定进度动画。");
            var animator = follower.GetComponent<Animator>();
            if (animator != null && animator.runtimeAnimatorController != null)
                throw new InvalidOperationException("The target already has an Animator Controller. Add the progress clip to that controller. / 目标已有 Animator Controller，请在该控制器中加入进度动画。");
            string path = AssetDatabase.GetAssetPath(follower.progressClip);
            if (string.IsNullOrEmpty(path))
                throw new InvalidOperationException("Save the progress animation asset first. / 请先保存进度动画资源。");
            string controllerPath = AssetDatabase.GenerateUniqueAssetPath(System.IO.Path.ChangeExtension(path, ".controller"));
            var controller = AnimatorController.CreateAnimatorControllerAtPathWithClip(controllerPath, follower.progressClip);
            if (animator == null) animator = Undo.AddComponent<Animator>(follower.gameObject);
            Undo.RecordObject(animator, "Assign path animation controller");
            animator.runtimeAnimatorController = controller;
            PrefabUtility.RecordPrefabInstancePropertyModifications(animator);
            EditorUtility.SetDirty(animator);
            AssetDatabase.SaveAssets();
        }

        public static void BakeTransform(PathFollower follower, AnimationClip output, int frameRate)
        {
            if (follower == null || follower.path == null || output == null || output == follower.progressClip ||
                output.legacy || frameRate < 1 || frameRate > 120)
                throw new ArgumentException("Choose a separate animation clip and frame rate 1–120. / 请选择独立的动画片段与 1–120 帧率。");
            if (!AssetDatabase.GetAssetPath(output).EndsWith(".anim", StringComparison.OrdinalIgnoreCase) ||
                !AssetDatabase.IsOpenForEdit(output) || AnimationUtility.GetEditorCurve(output, ProgressBinding) != null)
                throw new ArgumentException("Choose an editable Transform .anim asset. / 请选择可编辑的普通 Transform .anim 片段。");
            if (AnimationMode.InAnimationMode())
                throw new InvalidOperationException("Stop Animation Window preview before baking. / 请先退出 Animation 窗口预览。");
            float duration = Duration(follower);
            if (duration <= 0 || !float.IsFinite(duration) || duration * frameRate > 30000)
                throw new ArgumentException("Invalid duration or more than 30,000 samples. / 时长无效或采样超过 30000 帧。");
            int count = Mathf.Max(1, Mathf.CeilToInt(duration * frameRate));
            var parent = follower.transform.parent;
            Quaternion last = Quaternion.identity;
            bool rotate = follower.orientation != PathOrientation.PositionOnly;
            int curveCount = rotate ? 7 : 3;
            var frames = new Keyframe[curveCount][];
            for (int c = 0; c < curveCount; c++) frames[c] = new Keyframe[count + 1];
            var timing = Timing(follower);
            for (int i = 0; i <= count; i++)
            {
                float time = i == count ? duration : Mathf.Min(duration, i / (float)frameRate);
                float progress = Mathf.Clamp01(timing == null ? time / duration : timing.Evaluate(time));
                var pose = follower.PoseAtProgress(progress);
                var position = parent == null ? pose.position : parent.InverseTransformPoint(pose.position);
                var rotation = rotate ? follower.RotationFor(pose) : follower.transform.rotation;
                if (parent != null) rotation = Quaternion.Inverse(parent.rotation) * rotation;
                if (i > 0 && Quaternion.Dot(last, rotation) < 0)
                    rotation = new Quaternion(-rotation.x, -rotation.y, -rotation.z, -rotation.w);
                last = rotation;
                for (int axis = 0; axis < 3; axis++) frames[axis][i] = new Keyframe(time, position[axis]);
                if (rotate)
                    for (int axis = 0; axis < 4; axis++) frames[axis + 3][i] = new Keyframe(time, rotation[axis]);
            }
            var curves = new AnimationCurve[curveCount];
            for (int c = 0; c < curveCount; c++)
            {
                var keys = frames[c];
                for (int i = 1; i < keys.Length; i++)
                {
                    float slope = (keys[i].value - keys[i - 1].value) / (keys[i].time - keys[i - 1].time);
                    keys[i - 1].outTangent = slope;
                    keys[i].inTangent = slope;
                }
                curves[c] = new AnimationCurve(keys);
            }
            Undo.RegisterCompleteObjectUndo(output, "Bake path transform animation");
            output.frameRate = frameRate;
            if (rotate)
            {
                // A previous Euler rotation track cannot coexist with the generated quaternion track.
                foreach (var binding in AnimationUtility.GetCurveBindings(output))
                    if (binding.path == "" && binding.type == typeof(Transform) &&
                        (binding.propertyName.StartsWith("localEulerAngles", StringComparison.Ordinal) ||
                         binding.propertyName.StartsWith("m_LocalEulerAngles", StringComparison.Ordinal)))
                        AnimationUtility.SetEditorCurve(output, binding, null);
            }
            var bindings = new EditorCurveBinding[curveCount];
            var values = new AnimationCurve[curveCount];
            for (int i = 0; i < curveCount; i++)
            {
                bindings[i] = EditorCurveBinding.FloatCurve("", typeof(Transform),
                    i < 3 ? PositionProperties[i] : RotationProperties[i - 3]);
                values[i] = curves[i];
            }
            AnimationUtility.SetEditorCurves(output, bindings, values);
            if (rotate) output.EnsureQuaternionContinuity();
            EditorUtility.SetDirty(output);
            Undo.RecordObject(follower, "Assign baked motion clip");
            follower.bakedClip = output;
            EditorUtility.SetDirty(follower);
            PrefabUtility.RecordPrefabInstancePropertyModifications(follower);
            AssetDatabase.SaveAssets();
        }
    }
}
