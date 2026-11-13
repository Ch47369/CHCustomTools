using System;
using System.Reflection;
using UnityEditor;
using UnityEngine;

namespace CH.CustomTools.VFX
{
    /// <summary>Unity's Project audio preview, without AudioSources or changes to the current scene.</summary>
    internal static class RhythmAudioPreview
    {
        private static readonly Type AudioUtil = typeof(AudioImporter).Assembly.GetType("UnityEditor.AudioUtil");
        private static readonly MethodInfo Play = Find("PlayPreviewClip", new[] { typeof(AudioClip), typeof(int), typeof(bool) });
        private static readonly MethodInfo Stop = Find("StopAllPreviewClips", Type.EmptyTypes);
        private static readonly MethodInfo Position = Find("GetPreviewClipSamplePosition", Type.EmptyTypes);
        private static readonly MethodInfo IsPlaying = Find("IsPreviewClipPlaying", Type.EmptyTypes);
        private static bool ownsPreview;

        private static MethodInfo Find(string name, Type[] parameters)
        {
            return AudioUtil == null ? null : AudioUtil.GetMethod(name, BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Static, null, parameters, null);
        }

        public static bool Available { get { return Play != null && Stop != null && Position != null && IsPlaying != null; } }

        public static void Start(AudioClip clip, float time)
        {
            if (!Available) throw new NotSupportedException(CHToolLanguage.Text("此 Unity 版本没有兼容的编辑器音频试听接口；曲线分析与导出仍可使用。"));
            if (clip == null) throw new ArgumentNullException(nameof(clip));
            StopOwn();
            // Starting a new Project preview intentionally replaces the previous Project audio preview.
            Play.Invoke(null, new object[] { clip, Mathf.Clamp(Mathf.RoundToInt(time * clip.frequency), 0, clip.samples - 1), false });
            ownsPreview = true;
        }

        public static bool Playing
        {
            get
            {
                if (!ownsPreview || !Available) return false;
                bool playing = (bool)IsPlaying.Invoke(null, null);
                if (!playing) ownsPreview = false;
                return playing;
            }
        }

        public static float Time(AudioClip clip)
        {
            return clip == null || !Playing ? -1 : (float)(int)Position.Invoke(null, null) / clip.frequency;
        }

        public static void StopOwn()
        {
            if (ownsPreview && Stop != null) Stop.Invoke(null, null);
            ownsPreview = false;
        }
    }
}
