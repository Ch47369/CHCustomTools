using System;
using System.Reflection;
using UnityEditor;
using UnityEngine;

namespace CH.CustomTools.VFX
{
    /// <summary>Uses Unity's two native curve clipboards, matching Inspector and particle context menus.</summary>
    internal static class RhythmCurveClipboard
    {
        private const BindingFlags Flags = BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Static;
        private static readonly Type ClipboardType = typeof(EditorGUI).Assembly.GetType("UnityEditor.Clipboard");
        private static readonly Type ParticleType = typeof(EditorGUI).Assembly.GetType("UnityEditor.ParticleSystemClipboard");
        private static readonly PropertyInfo Curve = ClipboardType == null ? null : ClipboardType.GetProperty("animationCurveValue", Flags);
        private static readonly MethodInfo CopyParticles = ParticleType == null ? null : ParticleType.GetMethod("CopyAnimationCurves", Flags, null,
            new[] { typeof(AnimationCurve), typeof(AnimationCurve), typeof(float) }, null);

        public static bool Available { get { return Curve != null && Curve.CanWrite && CopyParticles != null; } }

        public static void Copy(AnimationCurve curve)
        {
            if (!Available) throw new NotSupportedException(CHToolLanguage.Text("此 Unity 版本没有兼容的原生曲线剪贴板，请使用 .anim 导出。"));
            if (curve == null || curve.length < 2) throw new ArgumentException(CHToolLanguage.Text("请先生成有效曲线。"));
            var copy = new AnimationCurve(curve.keys) { preWrapMode = curve.preWrapMode, postWrapMode = curve.postWrapMode };
            Curve.SetValue(null, copy);
            CopyParticles.Invoke(null, new object[] { copy, null, 1f });
        }
    }
}
