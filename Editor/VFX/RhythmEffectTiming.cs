using System;
using System.Collections.Generic;
using System.Linq;
using UnityEditor;
using UnityEngine;

namespace CH.CustomTools.VFX
{
    public enum RhythmEffectCueAction { Show, Hide, ShowForDuration }

    [Serializable]
    public sealed class RhythmEffectCue
    {
        public float time;
        public RhythmEffectCueAction action = RhythmEffectCueAction.ShowForDuration;
        public float duration = .1f;
    }

    [Serializable]
    public sealed class RhythmEffectTrack
    {
        public GameObject target;
        public bool initiallyVisible;
        public List<RhythmEffectCue> cues = new List<RhythmEffectCue>();
    }

    /// <summary>Authors native GameObject active-state curves; no runtime plugin dependency.</summary>
    public static class RhythmEffectTiming
    {
        public static float Neighbor(RhythmBeat[] beats, float cursor, bool next)
        {
            if (beats == null || beats.Length == 0) return cursor;
            var times = beats.Select(x => x.time).OrderBy(x => x).ToArray();
            if (next)
            {
                foreach (float time in times) if (time > cursor + .0001f) return time;
                return times[times.Length - 1];
            }
            for (int i = times.Length - 1; i >= 0; i--) if (times[i] < cursor - .0001f) return times[i];
            return times[0];
        }

        public static AnimationClip CreateAnimation(GameObject root, IList<RhythmEffectTrack> tracks, float duration, float offset)
        {
            if (root == null) throw new ArgumentException(CHToolLanguage.Text("请选择所有子特效共同的 Animator 根物体。"));
            if (!Finite(duration) || duration <= 0 || !Finite(offset)) throw new ArgumentException(CHToolLanguage.Text("音频长度和时间偏移必须有效。"));
            if (tracks == null || tracks.Count == 0) throw new ArgumentException(CHToolLanguage.Text("请至少添加一条特效轨道。"));
            var clip = new AnimationClip { frameRate = 60 };
            try
            {
                var paths = new HashSet<string>();
                foreach (var track in tracks)
                {
                    if (track.target == null || track.target == root || !track.target.transform.IsChildOf(root.transform))
                        throw new ArgumentException(CHToolLanguage.Text("每条轨道的对象必须是 Animator 根物体下的子特效，不能是根物体自身。"));
                    string path = AnimationUtility.CalculateTransformPath(track.target.transform, root.transform);
                    if (!paths.Add(path)) throw new ArgumentException(CHToolLanguage.Text("同一个子特效请集中在一条轨道内编排：") + path);
                    if (root.GetComponentsInChildren<Transform>(true).Count(x => AnimationUtility.CalculateTransformPath(x, root.transform) == path) != 1)
                        throw new ArgumentException(CHToolLanguage.Text("层级存在同名路径，请先区分子物体名称：") + path);
                    if (track.cues.Count == 0) throw new ArgumentException(track.target.name + CHToolLanguage.Text(" 的轨道没有时间点。"));
                    foreach (var cue in track.cues)
                    {
                        if (!Finite(cue.time) || cue.time < 0 || cue.time > duration || !Enum.IsDefined(typeof(RhythmEffectCueAction), cue.action))
                            throw new ArgumentException(track.target.name + CHToolLanguage.Text(" 的时间点必须位于音频的 0–") + duration.ToString("F3") + CHToolLanguage.Text(" 秒内。"));
                        if (cue.action == RhythmEffectCueAction.ShowForDuration && (!Finite(cue.duration) || cue.duration <= 0))
                            throw new ArgumentException(CHToolLanguage.Text("显示一段时间的持续时长必须大于 0。"));
                    }
                    var pulses = track.cues.Where(x => x.action == RhythmEffectCueAction.ShowForDuration).OrderBy(x => x.time).ToArray();
                    for (int i = 1; i < pulses.Length; i++)
                        if (pulses[i].time <= pulses[i - 1].time + pulses[i - 1].duration + .0001f)
                            throw new ArgumentException(track.target.name + CHToolLanguage.Text(" 的两次定时显示相互重叠或没有关闭间隔，请缩短持续时间或调整时间点。"));
                    foreach (var pulse in pulses)
                        if (track.cues.Any(x => x.action != RhythmEffectCueAction.ShowForDuration && x.time > pulse.time && x.time < pulse.time + pulse.duration))
                            throw new ArgumentException(track.target.name + CHToolLanguage.Text(" 的定时显示期间还有状态切换，请调整成明确的显示 / 隐藏时间点。"));
                    var changes = new SortedDictionary<float, bool>();
                    Action<float, bool> change = (time, visible) =>
                    {
                        if (time > duration) return;
                        bool existing;
                        if (changes.TryGetValue(time, out existing) && existing != visible)
                            throw new ArgumentException(track.target.name + CHToolLanguage.Text(" 在同一秒同时设置了显示和隐藏。"));
                        changes[time] = visible;
                    };
                    foreach (var cue in track.cues)
                    {
                        float time = cue.time + offset;
                        if (cue.action == RhythmEffectCueAction.ShowForDuration && (time >= duration || time + cue.duration <= 0)) continue;
                        change(time, cue.action != RhythmEffectCueAction.Hide);
                        if (cue.action == RhythmEffectCueAction.ShowForDuration)
                            change(Mathf.Min(duration, time + cue.duration), false);
                    }
                    bool initial = track.initiallyVisible;
                    foreach (var entry in changes) if (entry.Key <= 0) initial = entry.Value;
                    var keys = new List<Keyframe> { new Keyframe(0, initial ? 1 : 0) };
                    foreach (var entry in changes)
                        if (entry.Key > 0) keys.Add(new Keyframe(entry.Key, entry.Value ? 1 : 0));
                    if (keys[keys.Count - 1].time < duration) keys.Add(new Keyframe(duration, keys[keys.Count - 1].value));
                    var curve = new AnimationCurve(keys.ToArray());
                    for (int i = 0; i < curve.length; i++)
                    {
                        AnimationUtility.SetKeyLeftTangentMode(curve, i, AnimationUtility.TangentMode.Constant);
                        AnimationUtility.SetKeyRightTangentMode(curve, i, AnimationUtility.TangentMode.Constant);
                    }
                    AnimationUtility.SetEditorCurve(clip, EditorCurveBinding.FloatCurve(path, typeof(GameObject), "m_IsActive"), curve);
                }
                var clipSettings = AnimationUtility.GetAnimationClipSettings(clip);
                clipSettings.loopTime = false;
                AnimationUtility.SetAnimationClipSettings(clip, clipSettings);
                return clip;
            }
            catch { UnityEngine.Object.DestroyImmediate(clip); throw; }
        }

        public static void AppendTo(AnimationClip clip, GameObject root, IList<RhythmEffectTrack> tracks, float duration, float offset)
        {
            if (clip == null) throw new ArgumentNullException(nameof(clip));
            var timing = CreateAnimation(root, tracks, duration, offset);
            try
            {
                foreach (var binding in AnimationUtility.GetCurveBindings(timing))
                    AnimationUtility.SetEditorCurve(clip, binding, AnimationUtility.GetEditorCurve(timing, binding));
            }
            finally { UnityEngine.Object.DestroyImmediate(timing); }
        }

        private static bool Finite(float value) { return !float.IsNaN(value) && !float.IsInfinity(value); }
    }

    [Serializable]
    internal sealed class RhythmEffectTimingEditor
    {
        [SerializeField] private bool expanded;
        [SerializeField] private GameObject root;
        [SerializeField] private List<RhythmEffectTrack> tracks = new List<RhythmEffectTrack>();
        private static readonly string[] Actions = { "显示（保持）", "隐藏", "显示一段时间" };

        public bool HasTracks { get { return tracks.Count > 0; } }
        public string RootName { get { return root == null ? CHToolLanguage.Text("尚未选择") : root.name; } }

        public void AppendTo(AnimationClip clip, float duration, float offset) { RhythmEffectTiming.AppendTo(clip, root, tracks, duration, offset); }

        public void Draw(RhythmCurveProfile profile, float offset, float cursor, Action<float> seek, Action<string, MessageType> notify)
        {
            expanded = EditorGUILayout.Foldout(expanded, CHToolLanguage.Text("04   按节奏点安排不同子特效的显示 / 隐藏"), true);
            if (!expanded) return;
            using (new EditorGUILayout.VerticalScope(EditorStyles.helpBox))
            {
                EditorGUILayout.HelpBox(CHToolLanguage.Text("把多个特效放在同一父物体下，选它作为 Animator 根物体。每条轨道选择一个子特效，再添加要显示 / 隐藏的音频时间点。导出原生 .anim 后，与音频从同一秒播放。"), MessageType.Info);
                root = (GameObject)EditorGUILayout.ObjectField(CHToolLanguage.Text("Animator 根物体"), root, typeof(GameObject), true);
                EditorGUILayout.LabelField(CHToolLanguage.Text("整体时间偏移：") + offset.ToString("+0.000;-0.000;0.000") + CHToolLanguage.Text(" 秒（与上方输出映射共用）"), EditorStyles.wordWrappedMiniLabel);
                for (int i = 0; i < tracks.Count; i++)
                {
                    var track = tracks[i];
                    using (new EditorGUILayout.VerticalScope(EditorStyles.helpBox))
                    {
                        using (new EditorGUILayout.HorizontalScope())
                        {
                            track.target = (GameObject)EditorGUILayout.ObjectField(CHToolLanguage.Text("子特效 ") + (i + 1), track.target, typeof(GameObject), true);
                            if (GUILayout.Button(CHToolLanguage.Text("移除轨道"), GUILayout.Width(70))) { tracks.RemoveAt(i--); continue; }
                        }
                        track.initiallyVisible = EditorGUILayout.Toggle(CHToolLanguage.Text("音频开始时显示"), track.initiallyVisible);
                        using (new EditorGUILayout.HorizontalScope())
                        {
                            if (GUILayout.Button(CHToolLanguage.Text("添加当前时间点"))) track.cues.Add(new RhythmEffectCue { time = cursor });
                            if (GUILayout.Button(CHToolLanguage.Text("添加全部起音"))) AddBeats(track, profile.Beats, false);
                            if (GUILayout.Button(CHToolLanguage.Text("只加较强起音"))) AddBeats(track, profile.Beats, true);
                        }
                        EditorGUILayout.LabelField(track.cues.Count + CHToolLanguage.Text(" 个时间点；时间以音频秒数填写。"), EditorStyles.wordWrappedMiniLabel);
                        for (int c = 0; c < track.cues.Count; c++)
                        {
                            var cue = track.cues[c];
                            using (new EditorGUILayout.HorizontalScope())
                            {
                                cue.time = EditorGUILayout.FloatField(cue.time, GUILayout.Width(65));
                                GUILayout.Label(CHToolLanguage.Text("秒"), GUILayout.Width(18));
                                cue.action = (RhythmEffectCueAction)EditorGUILayout.Popup((int)cue.action, CHToolLanguage.Text(Actions));
                                if (cue.action == RhythmEffectCueAction.ShowForDuration)
                                {
                                    cue.duration = EditorGUILayout.FloatField(cue.duration, GUILayout.Width(55));
                                    GUILayout.Label(CHToolLanguage.Text("秒"), GUILayout.Width(18));
                                }
                                if (GUILayout.Button(CHToolLanguage.Text("定位"), GUILayout.Width(40))) seek(Mathf.Clamp(cue.time, 0, profile.Duration));
                                if (GUILayout.Button(CHToolLanguage.Text("删除"), GUILayout.Width(40))) track.cues.RemoveAt(c--);
                            }
                        }
                    }
                }
                if (GUILayout.Button(CHToolLanguage.Text("添加一条子特效轨道"))) tracks.Add(new RhythmEffectTrack());
                EditorGUILayout.HelpBox(CHToolLanguage.Text("这里编排的是 GameObject 激活状态。粒子若要每次激活时播放，应启用 Play On Awake，且两次显示之间留出关闭间隔。隐藏会立即停掉显示，持续时间需包含粒子拖尾。Animator 状态机切换、任意脚本回调和音频播放仍由你的 Animator / Timeline / 播放逻辑负责。"), MessageType.Info);
                EditorGUILayout.LabelField(CHToolLanguage.Text("需要连续曲线和开关一起播放时，在下方动画导出中勾选“合并子特效开关时间轴”，即可生成同一份 .anim。"), EditorStyles.wordWrappedMiniLabel);
                using (new EditorGUI.DisabledScope(tracks.Count == 0))
                    if (GUILayout.Button(CHToolLanguage.Text("导出特效开关时间轴 .anim")))
                    {
                        AnimationClip clip = null;
                        try
                        {
                            clip = RhythmEffectTiming.CreateAnimation(root, tracks, profile.Duration, offset);
                            string path = EditorUtility.SaveFilePanelInProject(CHToolLanguage.Text("导出特效开关时间轴"), (profile.Source == null ? "Audio" : profile.Source.name) + "_EffectTiming", "anim", CHToolLanguage.Text("导出子特效显示 / 隐藏的秒轴动画，不保存场景。"));
                            if (string.IsNullOrEmpty(path)) { UnityEngine.Object.DestroyImmediate(clip); return; }
                            RhythmCurveExport.SaveNewAsset(clip, path);
                            notify(CHToolLanguage.Text("已保存特效开关动画：") + AssetDatabase.GetAssetPath(clip) + CHToolLanguage.Text("。Animator / Timeline 请绑定到所选根物体，并让音频与动画从同一秒开始。"), MessageType.Info);
                        }
                        catch (ExitGUIException) { throw; }
                        catch (Exception error)
                        {
                            if (clip != null && !EditorUtility.IsPersistent(clip)) UnityEngine.Object.DestroyImmediate(clip);
                            notify(error.Message, MessageType.Error);
                        }
                    }
            }
        }

        private static void AddBeats(RhythmEffectTrack track, RhythmBeat[] beats, bool strongOnly)
        {
            foreach (var beat in beats)
                if ((!strongOnly || beat.accent) && !track.cues.Any(x => Mathf.Abs(x.time - beat.time) < .0001f))
                    track.cues.Add(new RhythmEffectCue { time = beat.time });
            track.cues.Sort((a, b) => a.time.CompareTo(b.time));
        }
    }
}
