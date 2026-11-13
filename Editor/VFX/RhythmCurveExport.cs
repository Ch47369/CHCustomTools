using System;
using System.Collections.Generic;
using System.IO;
using UnityEditor;
using UnityEngine;
using Object = UnityEngine.Object;

namespace CH.CustomTools.VFX
{
    public enum RhythmParticleProperty { EmissionRate, StartSize, StartSpeed }
    public enum RhythmAnimationTarget { UniformScale, PositionY, LightIntensity, ShaderFloat }

    [Serializable]
    public sealed class RhythmCurveMapping
    {
        public float minimum;
        public float maximum = 50;
        public float exponent = 1;
        public float timeOffset;
        public bool invert;

        public float Evaluate(float value)
        {
            value = Mathf.Clamp01(value);
            if (invert) value = 1 - value;
            return Mathf.Lerp(minimum, maximum, Mathf.Pow(value, Mathf.Clamp(exponent, .1f, 5)));
        }
    }

    public static class RhythmCurveExport
    {
        public static AnimationCurve Map(RhythmCurveProfile profile, RhythmChannel channel, RhythmCurveMapping mapping, bool normalized)
        {
            if (profile == null || profile.Duration <= 0) throw new ArgumentException(CHToolLanguage.Text("请先分析音频。"));
            if (mapping == null || !Finite(mapping.minimum) || !Finite(mapping.maximum) || !Finite(mapping.exponent) || !Finite(mapping.timeOffset))
                throw new ArgumentException(CHToolLanguage.Text("输出映射参数必须是有限数值。"));
            int fps = profile.Settings.samplesPerSecond;
            int count = Mathf.CeilToInt(profile.Duration * fps) + 1;
            var values = new float[count];
            var source = profile.GetCurve(channel);
            for (int i = 0; i < count; i++)
            {
                float time = Math.Min(profile.Duration, (float)i / fps) - mapping.timeOffset;
                float value = time < 0 || time > profile.Duration ? 0 : source.Evaluate(time);
                values[i] = mapping.Evaluate(value);
            }
            var curve = RhythmAnalyzer.Compress(values, fps, profile.Duration,
                profile.Settings.compressionError * Math.Max(.001f, Mathf.Abs(mapping.maximum - mapping.minimum)));
            if (!normalized) return curve;
            Keyframe[] keys = curve.keys;
            for (int i = 0; i < keys.Length; i++)
            {
                var key = keys[i]; key.time /= profile.Duration; keys[i] = key;
            }
            return RhythmAnalyzer.Linear(keys);
        }

        public static AnimationClip CreateAnimation(RhythmCurveProfile profile, RhythmChannel channel, RhythmCurveMapping mapping,
            RhythmAnimationTarget target, string relativePath, string shaderProperty, Type rendererType, bool loop)
        {
            if (relativePath == null) relativePath = "";
            if (relativePath.StartsWith("/") || relativePath.EndsWith("/") || relativePath.Contains("//") || relativePath.Contains(".."))
                throw new ArgumentException(CHToolLanguage.Text("层级路径必须相对于 Animator 根节点，例如 Wave/Core；根节点使用空路径。"));
            var curve = Map(profile, channel, mapping, false);
            var clip = new AnimationClip { name = profile.Source != null ? profile.Source.name + "_" + channel : "RhythmCurve", frameRate = profile.Settings.samplesPerSecond };
            switch (target)
            {
                case RhythmAnimationTarget.UniformScale:
                    foreach (string axis in new[] { "x", "y", "z" }) Bind(clip, relativePath, typeof(Transform), "m_LocalScale." + axis, curve);
                    break;
                case RhythmAnimationTarget.PositionY:
                    Bind(clip, relativePath, typeof(Transform), "m_LocalPosition.y", curve);
                    break;
                case RhythmAnimationTarget.LightIntensity:
                    Bind(clip, relativePath, typeof(Light), "m_Intensity", curve);
                    break;
                case RhythmAnimationTarget.ShaderFloat:
                    if (string.IsNullOrWhiteSpace(shaderProperty) || !shaderProperty.StartsWith("_"))
                    {
                        Object.DestroyImmediate(clip);
                        throw new ArgumentException(CHToolLanguage.Text("请输入 Shader 的 Float / Range 属性名，例如 _MainTexIntensity。"));
                    }
                    if (rendererType != typeof(MeshRenderer) && rendererType != typeof(SkinnedMeshRenderer) && rendererType != typeof(ParticleSystemRenderer))
                    {
                        Object.DestroyImmediate(clip);
                        throw new ArgumentException(CHToolLanguage.Text("请选择有效的 Renderer 类型。"));
                    }
                    Bind(clip, relativePath, rendererType, "material." + shaderProperty.Trim(), curve);
                    break;
            }
            var settings = AnimationUtility.GetAnimationClipSettings(clip);
            settings.loopTime = loop;
            AnimationUtility.SetAnimationClipSettings(clip, settings);
            return clip;
        }

        private static void Bind(AnimationClip clip, string path, Type type, string property, AnimationCurve curve)
        {
            AnimationUtility.SetEditorCurve(clip, EditorCurveBinding.FloatCurve(path, type, property), curve);
        }

        public static ParticleSystem[] Targets(GameObject root, bool includeChildren)
        {
            if (root == null) throw new ArgumentException(CHToolLanguage.Text("请指定场景中的目标物体。"));
            if (EditorUtility.IsPersistent(root) || !root.scene.IsValid())
                throw new ArgumentException(CHToolLanguage.Text("请选择场景实例或 Prefab Mode 内的实例；不直接覆盖 Project 中的预制体。"));
            ParticleSystem[] systems = includeChildren ? root.GetComponentsInChildren<ParticleSystem>(true) : root.GetComponents<ParticleSystem>();
            if (systems.Length == 0) throw new ArgumentException(CHToolLanguage.Text("选定范围内没有 ParticleSystem。"));
            return systems;
        }

        public static int ApplyParticles(GameObject root, bool includeChildren, RhythmCurveProfile profile, RhythmChannel channel,
            RhythmCurveMapping mapping, RhythmParticleProperty property, bool alignDuration, bool loop)
        {
            if (EditorApplication.isPlayingOrWillChangePlaymode) throw new InvalidOperationException(CHToolLanguage.Text("请在编辑模式下应用曲线。"));
            var targets = Targets(root, includeChildren);
            var curve = Map(profile, channel, mapping, true);
            if (mapping.minimum < 0 || mapping.maximum < 0) throw new ArgumentException(CHToolLanguage.Text("粒子输出范围不能为负数。"));
            foreach (var ps in targets)
            {
                if (property == RhythmParticleProperty.StartSize && ps.main.startSize3D)
                    throw new InvalidOperationException(ps.name + CHToolLanguage.Text(" 已启用 3D Start Size。请手动选择轴向方案，工具不会替换其三轴设计。"));
                if (!alignDuration && Mathf.Abs(ps.main.duration - profile.Duration) > .001f)
                    throw new InvalidOperationException(ps.name + CHToolLanguage.Text(" 的 Duration 与音频长度不同，请启用时长对齐以保持节奏同步。"));
            }
            Undo.IncrementCurrentGroup();
            int group = Undo.GetCurrentGroup();
            Undo.SetCurrentGroupName("Apply audio rhythm curve");
            Undo.RecordObjects(targets, "Apply audio rhythm curve");
            foreach (var ps in targets)
            {
                ps.Stop(false, ParticleSystemStopBehavior.StopEmittingAndClear);
                var main = ps.main;
                if (alignDuration)
                {
                    main.duration = profile.Duration;
                    main.startDelay = 0;
                    main.loop = loop;
                }
                switch (property)
                {
                    case RhythmParticleProperty.StartSize: main.startSize = new ParticleSystem.MinMaxCurve(1, curve); break;
                    case RhythmParticleProperty.StartSpeed: main.startSpeed = new ParticleSystem.MinMaxCurve(1, curve); break;
                    default:
                        var emission = ps.emission;
                        emission.enabled = true;
                        emission.rateOverTime = new ParticleSystem.MinMaxCurve(1, curve);
                        break;
                }
                EditorUtility.SetDirty(ps);
                PrefabUtility.RecordPrefabInstancePropertyModifications(ps);
            }
            Undo.FlushUndoRecordObjects();
            Undo.CollapseUndoOperations(group);
            return targets.Length;
        }

        public static void SaveNewAsset(Object asset, string path)
        {
            if (asset == null) throw new ArgumentNullException(nameof(asset));
            if (string.IsNullOrEmpty(path) || !path.StartsWith("Assets/", StringComparison.Ordinal) || path.Contains(".."))
                throw new ArgumentException(CHToolLanguage.Text("输出位置必须在 Assets 文件夹内。"));
            // A unique filename also protects an existing asset with unsaved edits.
            string unique = AssetDatabase.GenerateUniqueAssetPath(path);
            if (string.IsNullOrEmpty(asset.name)) asset.name = Path.GetFileNameWithoutExtension(unique);
            AssetDatabase.CreateAsset(asset, unique);
            AssetDatabase.SaveAssetIfDirty(asset);
            EditorGUIUtility.PingObject(asset);
        }

        private static bool Finite(float value) { return !float.IsNaN(value) && !float.IsInfinity(value); }
    }
}
