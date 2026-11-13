using System;
using System.Collections.Generic;
using System.IO;
using UnityEditor;
using UnityEngine;
using Object = UnityEngine.Object;

namespace CH.CustomTools.VFX
{
    [Serializable]
    internal sealed class RhythmCurvePanel
    {
        internal static string PluginFolder { get { return RhythmCurveWindow.PluginFolder; } }
        [NonSerialized] private Action repaint;
        private void Repaint() { if (repaint != null) repaint(); }
        private static readonly string[] ChannelNames = { "音量包络", "低频", "中频", "高频", "起音强度", "节奏脉冲" };
        private static readonly string[] ParticleNames = { "发射率 / 秒", "初始大小", "初始速度" };
        private static readonly string[] AnimationNames = { "Transform 等比缩放", "Transform 位移 Y", "Light 亮度", "Shader 浮点属性" };
        private static readonly Color[] Colors = { new Color(.32f, .83f, .79f), new Color(.98f, .59f, .28f),
            new Color(.88f, .72f, .35f), new Color(.45f, .68f, 1), new Color(.93f, .48f, .57f), new Color(.70f, .57f, 1) };

        [SerializeField] private AudioClip source;
        [SerializeField] private RhythmAnalysisSettings settings = new RhythmAnalysisSettings();
        [SerializeField] private RhythmCurveMapping mapping = new RhythmCurveMapping { minimum = 1, maximum = 1.18f };
        [SerializeField] private RhythmChannel channel = RhythmChannel.Pulse;
        [SerializeField] private GameObject target;
        [SerializeField] private bool includeChildren;
        [SerializeField] private bool alignDuration = true;
        [SerializeField] private bool loop;
        [SerializeField] private RhythmParticleProperty particleProperty;
        [SerializeField] private RhythmAnimationTarget animationTarget;
        [SerializeField] private string bindingPath = "";
        [SerializeField] private string shaderProperty = "_MainTexIntensity";
        [SerializeField] private int rendererType = 2;
        [SerializeField] private int outputTab;
        [SerializeField] private Vector2 scroll;
        [SerializeField] private RhythmCurveProfile profile;
        private RhythmCurveProfile loadProfile;
        [SerializeField] private string analysisStamp;
        private CHToolMessage status;
        private MessageType statusType = MessageType.Info;
        [SerializeField] private float cursor;
        [SerializeField] private RhythmEffectTimingEditor effectTiming = new RhythmEffectTimingEditor();
        [SerializeField] private bool includeEffectTiming = true;
        private bool advanced;
        private GUIStyle titleStyle;
        private GUIStyle hintStyle;

        internal void Enable(Action repaintHost)
        {
            repaint = repaintHost;
            EditorApplication.update -= Tick;
            EditorApplication.update += Tick;
        }

        internal void Disable()
        {
            EditorApplication.update -= Tick;
            RhythmAudioPreview.StopOwn();
        }

        internal void Dispose()
        {
            if (profile != null) Object.DestroyImmediate(profile);
        }

        internal void ValidateSource()
        {
            if (profile == null || profile.Source == null) return;
            string hash = AssetDatabase.GetAssetDependencyHash(AssetDatabase.GetAssetPath(profile.Source)).ToString();
            if (hash != profile.SourceDependencyHash)
            {
                analysisStamp = null;
                Notify(new CHToolMessage(CHToolLanguage.Text(true, "源音频或导入设置已变化，请重新分析。"), CHToolLanguage.Text(false, "源音频或导入设置已变化，请重新分析。")), MessageType.Warning);
            }
        }

        private void Tick()
        {
            if (source == null || !RhythmAudioPreview.Playing) return;
            float time = RhythmAudioPreview.Time(source);
            if (time >= 0) cursor = time;
            Repaint();
        }

        private string Stamp() { return (source == null ? "none" : source.GetInstanceID().ToString()) + JsonUtility.ToJson(settings); }
        private bool Ready { get { return profile != null && source == profile.Source && analysisStamp == Stamp(); } }

        internal void DrawPanel()
        {
            if (titleStyle == null) titleStyle = new GUIStyle(EditorStyles.boldLabel) { fontSize = 20 };
            if (hintStyle == null) hintStyle = new GUIStyle(EditorStyles.wordWrappedMiniLabel) { padding = new RectOffset(0, 0, 3, 5) };
            float oldLabelWidth = EditorGUIUtility.labelWidth;
            EditorGUIUtility.labelWidth = 145;
            scroll = EditorGUILayout.BeginScrollView(scroll);
            try
            {
                GUILayout.Space(12);
                GUILayout.Label("AUDIO  /  RHYTHM CURVES", titleStyle);
                GUILayout.Label(CHToolLanguage.Text("把声音的强弱、频段与起音，转成可编辑的特效曲线。"), hintStyle);
                GUILayout.Space(8);
                DrawSource();
                if (GUILayout.Button(CHToolLanguage.Pick("迁移旧版曲线数据（创建副本）", "Migrate legacy curve data (create a copy)"))) RhythmProfileMigration.ChooseCopy();
                GUILayout.Space(8);
                DrawAnalysis();
                if (profile != null)
                {
                    GUILayout.Space(10);
                    DrawPreview();
                    GUILayout.Space(8);
                    DrawMapping();
                    GUILayout.Space(8);
                    using (new EditorGUI.DisabledScope(!Ready)) effectTiming.Draw(profile, mapping.timeOffset, cursor, Seek, Notify);
                    GUILayout.Space(8);
                    using (new EditorGUI.DisabledScope(!Ready)) DrawOutput();
                    if (!Ready) EditorGUILayout.HelpBox(CHToolLanguage.Text("音频或分析参数已更改。重新分析后再保存 / 导出 / 应用。"), MessageType.Warning);
                }
                if (!string.IsNullOrEmpty(status)) EditorGUILayout.HelpBox(status, statusType);
                GUILayout.Space(8);
                using (new EditorGUILayout.HorizontalScope())
                {
                    if (GUILayout.Button(CHToolLanguage.Text("使用说明"), EditorStyles.miniButton)) AssetDatabase.OpenAsset(AssetDatabase.LoadMainAssetAtPath(PluginFolder + "/README.md"));
                }
                GUILayout.Space(12);
            }
            finally
            {
                EditorGUILayout.EndScrollView();
                EditorGUIUtility.labelWidth = oldLabelWidth;
            }
        }

        internal void SetSource(AudioClip clip) { source = clip; }

        private void DrawSource()
        {
            using (new EditorGUILayout.VerticalScope(EditorStyles.helpBox))
            {
                EditorGUI.BeginChangeCheck();
                source = (AudioClip)EditorGUILayout.ObjectField(CHToolLanguage.Text("源音频"), source, typeof(AudioClip), false);
                if (EditorGUI.EndChangeCheck()) { RhythmAudioPreview.StopOwn(); cursor = 0; }
                if (source != null) GUILayout.Label(source.length.ToString("F2") + CHToolLanguage.Text(" 秒   ·   ") + source.frequency + " Hz   ·   " + source.channels + CHToolLanguage.Text(" 声道"), hintStyle);
                if (source != null && source.loadType != AudioClipLoadType.DecompressOnLoad)
                {
                    EditorGUILayout.HelpBox(CHToolLanguage.Text("源音频使用 ") + source.loadType + CHToolLanguage.Text("，需要解压副本才能读取采样；原音频不做改动。"), MessageType.Info);
                    if (GUILayout.Button(CHToolLanguage.Text("创建解压分析副本（保留源音频）"))) Run(() =>
                    {
                        RhythmAudioPreview.StopOwn();
                        source = RhythmAudioImport.CreateAnalysisCopy(source);
                        cursor = 0;
                        Notify(new CHToolMessage(CHToolLanguage.Text(true, "解压分析副本已创建，现在可以分析。原音频及导入设置保持不变。"), CHToolLanguage.Text(false, "解压分析副本已创建，现在可以分析。原音频及导入设置保持不变。")), MessageType.Info);
                    });
                }
                using (new EditorGUILayout.HorizontalScope())
                {
                    loadProfile = (RhythmCurveProfile)EditorGUILayout.ObjectField(CHToolLanguage.Text("已有曲线数据"), loadProfile, typeof(RhythmCurveProfile), false);
                    using (new EditorGUI.DisabledScope(loadProfile == null))
                        if (GUILayout.Button(CHToolLanguage.Text("载入副本"), GUILayout.Width(82))) Load(loadProfile);
                }
            }
        }

        private void DrawAnalysis()
        {
            GUILayout.Label(CHToolLanguage.Text("01   分析与节奏"), EditorStyles.boldLabel);
            settings.attack = EditorGUILayout.Slider(new GUIContent(CHToolLanguage.Text("包络响应 / 秒"), CHToolLanguage.Text("越短越贴近起音，越长越柔和。")), settings.attack, 0, .3f);
            settings.release = EditorGUILayout.Slider(new GUIContent(CHToolLanguage.Text("包络拖尾 / 秒"), CHToolLanguage.Text("控制音量与频段曲线的回落速度。")), settings.release, .005f, 1);
            settings.minimumBeatInterval = EditorGUILayout.Slider(new GUIContent(CHToolLanguage.Text("最小起音间隔 / 秒"), CHToolLanguage.Text("降低数值会保留更密集的音符。")), settings.minimumBeatInterval, .04f, 1);
            settings.sensitivity = EditorGUILayout.Slider(new GUIContent(CHToolLanguage.Text("起音筛选阈值"), CHToolLanguage.Text("越高保留的起音越少；不是固定 BPM 网格。")), settings.sensitivity, .5f, 4);
            settings.minimumOnsetStrength = EditorGUILayout.Slider(new GUIContent(CHToolLanguage.Text("弱起音过滤"), CHToolLanguage.Text("提高数值可减少混响与很弱的次级起音。降低数值会保留更轻的拨弦。")), settings.minimumOnsetStrength, .01f, 1);
            settings.pulseAttack = EditorGUILayout.Slider(CHToolLanguage.Text("脉冲上升 / 秒"), settings.pulseAttack, 0, .15f);
            settings.pulseRelease = EditorGUILayout.Slider(CHToolLanguage.Text("脉冲拖尾 / 秒"), settings.pulseRelease, .02f, 1.5f);
            advanced = EditorGUILayout.Foldout(advanced, CHToolLanguage.Text("高级分析设置"), true);
            if (advanced)
            {
                settings.samplesPerSecond = EditorGUILayout.IntSlider(CHToolLanguage.Text("每秒采样数"), settings.samplesPerSecond, 25, 200);
                int[] sizes = { 512, 1024, 2048, 4096 };
                int index = Math.Max(0, Array.IndexOf(sizes, settings.fftSize));
                index = EditorGUILayout.Popup(CHToolLanguage.Text("FFT 窗口"), index, new[] { CHToolLanguage.Text("512 · 更快瞬态"), "1024", CHToolLanguage.Text("2048 · 均衡"), CHToolLanguage.Text("4096 · 更细频段") });
                settings.fftSize = sizes[index];
                settings.noiseFloorDb = EditorGUILayout.Slider(CHToolLanguage.Text("静音门限 / dBFS"), settings.noiseFloorDb, -90, -12);
                settings.compressionError = EditorGUILayout.Slider(CHToolLanguage.Text("关键帧压缩误差"), settings.compressionError, .001f, .03f);
            }
            using (new EditorGUI.DisabledScope(source == null || source.loadType != AudioClipLoadType.DecompressOnLoad || EditorApplication.isPlayingOrWillChangePlaymode))
                if (GUILayout.Button(profile == null ? CHToolLanguage.Text("分析音频 → 生成六条曲线") : CHToolLanguage.Text("重新分析音频"), GUILayout.Height(30))) Analyze();
        }

        internal void Analyze()
        {
            Run(() =>
            {
                RhythmAudioPreview.StopOwn();
                settings.Validate();
                RhythmAnalysisResult result;
                try { result = RhythmAnalyzer.Analyze(source, settings, t => EditorUtility.DisplayCancelableProgressBar(CHToolLanguage.Text("音频节奏分析"), CHToolLanguage.Text("FFT 频段 · 起音检测 · 包络平滑 · 关键帧压缩"), t)); }
                finally { EditorUtility.ClearProgressBar(); }
                var next = ScriptableObject.CreateInstance<RhythmCurveProfile>();
                next.hideFlags = HideFlags.HideAndDontSave;
                next.Initialize(source, settings, result, AssetDatabase.GetAssetDependencyHash(AssetDatabase.GetAssetPath(source)).ToString());
                if (profile != null) Object.DestroyImmediate(profile);
                profile = next;
                analysisStamp = Stamp(); cursor = 0;
                Notify(new CHToolMessage(CHToolLanguage.Text(true, "分析完成：") + result.beats.Length + CHToolLanguage.Text(true, " 个起音。曲线保存在窗口副本中，可试听、编辑后导出。"), CHToolLanguage.Text(false, "分析完成：") + result.beats.Length + CHToolLanguage.Text(false, " 个起音。曲线保存在窗口副本中，可试听、编辑后导出。")), MessageType.Info);
            });
        }

        internal void Load(RhythmCurveProfile saved)
        {
            RhythmAudioPreview.StopOwn();
            if (profile != null) Object.DestroyImmediate(profile);
            profile = Object.Instantiate(saved);
            profile.hideFlags = HideFlags.HideAndDontSave;
            source = saved.Source;
            settings = saved.Settings.Copy();
            loadProfile = saved;
            analysisStamp = Stamp(); cursor = 0;
            ValidateSource();
            Notify(new CHToolMessage(CHToolLanguage.Text(true, "已载入可编辑副本。保存会创建新资源，不覆盖原曲线。"), CHToolLanguage.Text(false, "已载入可编辑副本。保存会创建新资源，不覆盖原曲线。")), MessageType.Info);
        }

        private void DrawPreview()
        {
            GUILayout.Label(CHToolLanguage.Text("02   试听与曲线"), EditorStyles.boldLabel);
            if (!Ready) EditorGUILayout.HelpBox(CHToolLanguage.Text("分析参数已改变，当前曲线尚未刷新。点击“重新分析音频”后可继续导出。"), MessageType.Warning);
            channel = (RhythmChannel)GUILayout.Toolbar((int)channel, CHToolLanguage.Text(ChannelNames));
            Rect graph = GUILayoutUtility.GetRect(100, 155, GUILayout.ExpandWidth(true));
            DrawGraph(graph);
            using (new EditorGUILayout.HorizontalScope())
            {
                using (new EditorGUI.DisabledScope(!RhythmAudioPreview.Available || source == null))
                {
                    if (GUILayout.Button(RhythmAudioPreview.Playing ? CHToolLanguage.Text("暂停") : CHToolLanguage.Text("试听"), GUILayout.Width(55)))
                        Run(() => { if (RhythmAudioPreview.Playing) RhythmAudioPreview.StopOwn(); else RhythmAudioPreview.Start(source, cursor); });
                    if (GUILayout.Button(CHToolLanguage.Text("归零"), GUILayout.Width(45))) { RhythmAudioPreview.StopOwn(); cursor = 0; }
                }
                EditorGUI.BeginChangeCheck();
                cursor = GUILayout.HorizontalSlider(cursor, 0, profile.Duration);
                if (EditorGUI.EndChangeCheck() && RhythmAudioPreview.Playing) Run(() => RhythmAudioPreview.Start(source, cursor));
                GUILayout.Label(cursor.ToString("F2") + " / " + profile.Duration.ToString("F2") + " s", GUILayout.Width(115));
            }
            string tempo = profile.EstimatedBpm > 0 ? CHToolLanguage.Text("参考 BPM ") + profile.EstimatedBpm.ToString("F1") + CHToolLanguage.Text("（稳定度 ") + profile.TempoConfidence.ToString("P0") + "）" : CHToolLanguage.Text("起音不足，未估计 BPM");
            GUILayout.Label(profile.Beats.Length + CHToolLanguage.Text(" 个起音   ·   ") + tempo + "   ·   " + profile.GetCurve(channel).length + CHToolLanguage.Text(" 个关键帧"), hintStyle);
            if (profile.TempoConfidence < .65f && profile.Beats.Length >= 4) GUILayout.Label(CHToolLanguage.Text("节奏较自由，按实际起音生成脉冲；BPM 仅供参考。"), hintStyle);
            EditorGUI.BeginChangeCheck();
            AnimationCurve edited = EditorGUILayout.CurveField(CHToolLanguage.Text("手动修饰当前曲线"), profile.GetCurve(channel), Colors[(int)channel], new Rect(0, 0, profile.Duration, 1));
            if (EditorGUI.EndChangeCheck()) profile.SetCurve(channel, edited);
            using (new EditorGUILayout.HorizontalScope())
            {
                using (new EditorGUI.DisabledScope(profile.Beats.Length == 0))
                {
                    if (GUILayout.Button(CHToolLanguage.Text("上个起音"))) Seek(RhythmEffectTiming.Neighbor(profile.Beats, cursor, false));
                    if (GUILayout.Button(CHToolLanguage.Text("下个起音"))) Seek(RhythmEffectTiming.Neighbor(profile.Beats, cursor, true));
                }
                EditorGUI.BeginChangeCheck();
                float position = EditorGUILayout.FloatField(CHToolLanguage.Text("定位 / 秒"), cursor);
                if (EditorGUI.EndChangeCheck() && !float.IsNaN(position) && !float.IsInfinity(position)) Seek(Mathf.Clamp(position, 0, profile.Duration));
            }
        }

        private void Seek(float time)
        {
            cursor = time;
            if (RhythmAudioPreview.Playing) Run(() => RhythmAudioPreview.Start(source, cursor));
            Repaint();
        }

        private void DrawGraph(Rect rect)
        {
            // GUILayout returns a dummy / negative-width rect during Layout. Draw only after layout.
            if (Event.current.type == EventType.Layout || rect.width < 32 || rect.height < 32 ||
                float.IsNaN(rect.width) || float.IsInfinity(rect.width)) return;
            Rect plot = new Rect(rect.x + 8, rect.y + 10, rect.width - 16, rect.height - 30);
            Event evt = Event.current;
            if ((evt.type == EventType.MouseDown || evt.type == EventType.MouseDrag) && rect.Contains(evt.mousePosition) && evt.button == 0)
            {
                cursor = Mathf.Clamp01((evt.mousePosition.x - plot.x) / plot.width) * profile.Duration;
                if (RhythmAudioPreview.Playing) Run(() => RhythmAudioPreview.Start(source, cursor));
                evt.Use(); Repaint();
            }
            if (evt.type != EventType.Repaint) return;
            EditorGUI.DrawRect(rect, new Color(.075f, .09f, .11f));
            Handles.BeginGUI();
            Color oldColor = Handles.color;
            Handles.color = new Color(1, 1, 1, .08f);
            for (int i = 0; i <= 4; i++)
            {
                float y = plot.yMax - plot.height * i / 4;
                Handles.DrawLine(new Vector3(plot.x, y), new Vector3(plot.xMax, y));
            }
            foreach (var beat in profile.Beats)
            {
                float x = plot.x + beat.time / profile.Duration * plot.width;
                Handles.color = beat.accent ? new Color(1, .65f, .35f, .32f) : new Color(1, 1, 1, .12f);
                Handles.DrawLine(new Vector3(x, plot.y), new Vector3(x, plot.yMax));
            }
            if (channel != RhythmChannel.Envelope) DrawCurve(plot, profile.GetCurve(RhythmChannel.Envelope), new Color(.32f, .83f, .79f, .22f));
            DrawCurve(plot, profile.GetCurve(channel), Colors[(int)channel]);
            float playhead = plot.x + cursor / profile.Duration * plot.width;
            Handles.color = Color.white;
            Handles.DrawLine(new Vector3(playhead, plot.y), new Vector3(playhead, plot.yMax));
            Handles.color = oldColor;
            Handles.EndGUI();
            GUI.Label(new Rect(plot.x, rect.yMax - 19, 90, 18), "0 s", EditorStyles.miniLabel);
            GUI.Label(new Rect(plot.xMax - 70, rect.yMax - 19, 70, 18), profile.Duration.ToString("F2") + " s", EditorStyles.miniLabel);
        }

        private void DrawCurve(Rect plot, AnimationCurve curve, Color color)
        {
            int count = Mathf.Clamp(Mathf.CeilToInt(plot.width), 2, 1200);
            var points = new Vector3[count];
            for (int i = 0; i < count; i++)
            {
                float u = (float)i / (count - 1);
                points[i] = new Vector3(plot.x + u * plot.width, plot.yMax - Mathf.Clamp01(curve.Evaluate(u * profile.Duration)) * plot.height);
            }
            Handles.color = color;
            Handles.DrawAAPolyLine(1.7f, points);
        }

        private void DrawMapping()
        {
            GUILayout.Label(CHToolLanguage.Text("03   输出映射"), EditorStyles.boldLabel);
            using (new EditorGUILayout.HorizontalScope())
            {
                GUILayout.Label(CHToolLanguage.Text("常用范围"), GUILayout.Width(65));
                if (GUILayout.Button(CHToolLanguage.Text("发射 0–50"), EditorStyles.miniButton)) { mapping.minimum = 0; mapping.maximum = 50; }
                if (GUILayout.Button(CHToolLanguage.Text("缩放 1–1.18"), EditorStyles.miniButton)) { mapping.minimum = 1; mapping.maximum = 1.18f; }
                if (GUILayout.Button(CHToolLanguage.Text("强度 0.7–2.2"), EditorStyles.miniButton)) { mapping.minimum = .7f; mapping.maximum = 2.2f; }
            }
            using (new EditorGUILayout.HorizontalScope())
            {
                mapping.minimum = EditorGUILayout.FloatField(CHToolLanguage.Text("静止值"), mapping.minimum);
                mapping.maximum = EditorGUILayout.FloatField(CHToolLanguage.Text("峰值"), mapping.maximum);
            }
            mapping.exponent = EditorGUILayout.Slider(new GUIContent(CHToolLanguage.Text("强弱对比"), CHToolLanguage.Text("大于 1 只突出强音；小于 1 会抬高弱音。")), mapping.exponent, .1f, 5);
            mapping.timeOffset = EditorGUILayout.Slider(new GUIContent(CHToolLanguage.Text("时间偏移 / 秒"), CHToolLanguage.Text("正数让特效晚于声音；负数提前。超出音频末尾的内容会被裁掉。")), mapping.timeOffset, -1, 1);
            mapping.invert = EditorGUILayout.Toggle(CHToolLanguage.Text("反向响应"), mapping.invert);
            float time = cursor - mapping.timeOffset;
            float input = time < 0 || time > profile.Duration ? 0 : profile.GetCurve(channel).Evaluate(time);
            GUILayout.Label(CHToolLanguage.Text("当前位置输出：") + mapping.Evaluate(input).ToString("F3"), hintStyle);
            using (new EditorGUI.DisabledScope(!Ready || !RhythmCurveClipboard.Available))
                using (new EditorGUILayout.HorizontalScope())
                {
                    if (GUILayout.Button(CHToolLanguage.Text("复制当前曲线（秒）"))) Run(() => CopyCurve(false));
                    if (GUILayout.Button(CHToolLanguage.Text("复制当前曲线（粒子 0–1）"))) Run(() => CopyCurve(true));
                }
            GUILayout.Label(CHToolLanguage.Text("复制包含当前静止值、峰值和时间偏移。右键目标曲线字段 → Paste；粒子先选 Curve 模式。Animation 窗口关键帧请用下方 .anim 导出。"), hintStyle);
            GUILayout.Label(CHToolLanguage.Text("粒子 0–1 对应整个 Duration，需与音频长度相同、Start Delay 为 0。Size over Lifetime 等按单个粒子寿命计算，不能据此对齐整段音频。"), hintStyle);
        }

        private void CopyCurve(bool normalized)
        {
            RhythmCurveClipboard.Copy(RhythmCurveExport.Map(profile, channel, mapping, normalized));
            Notify(new CHToolMessage(CHToolLanguage.Text(true, "已复制“") + CHToolLanguage.Text(true, ChannelNames)[(int)channel] + CHToolLanguage.Text(true, "”及当前输出映射。") + (normalized ? CHToolLanguage.Text(true, "粒子曲线横轴为 0–1，右键曲线选择 Paste。") : CHToolLanguage.Text(true, "横轴为音频秒数，右键原生曲线字段选择 Paste。")), CHToolLanguage.Text(false, "已复制“") + CHToolLanguage.Text(false, ChannelNames)[(int)channel] + CHToolLanguage.Text(false, "”及当前输出映射。") + (normalized ? CHToolLanguage.Text(false, "粒子曲线横轴为 0–1，右键曲线选择 Paste。") : CHToolLanguage.Text(false, "横轴为音频秒数，右键原生曲线字段选择 Paste。"))), MessageType.Info);
        }

        private void DrawOutput()
        {
            GUILayout.Label(CHToolLanguage.Text("05   输出与应用"), EditorStyles.boldLabel);
            outputTab = GUILayout.Toolbar(outputTab, new[] { CHToolLanguage.Text("保存 / 动画片段"), CHToolLanguage.Text("应用到粒子") });
            using (new EditorGUILayout.VerticalScope(EditorStyles.helpBox))
            {
                if (outputTab == 0)
                {
                    if (GUILayout.Button(CHToolLanguage.Text("保存六条原始曲线数据 .asset"))) Run(SaveProfile);
                    animationTarget = (RhythmAnimationTarget)EditorGUILayout.Popup(CHToolLanguage.Text("动画目标"), (int)animationTarget, CHToolLanguage.Text(AnimationNames));
                    bindingPath = EditorGUILayout.TextField(new GUIContent(CHToolLanguage.Text("相对层级路径"), CHToolLanguage.Text("相对于 Animator；根节点为空，例如 Wave/Core。")), bindingPath);
                    if (animationTarget == RhythmAnimationTarget.ShaderFloat)
                    {
                        rendererType = EditorGUILayout.Popup(CHToolLanguage.Text("渲染组件"), rendererType, new[] { "MeshRenderer", "SkinnedMeshRenderer", "ParticleSystemRenderer" });
                        shaderProperty = EditorGUILayout.TextField(CHToolLanguage.Text("Float / Range 属性"), shaderProperty);
                        GUILayout.Label(CHToolLanguage.Text("Custom2TexV2 的主贴图强度可用 _MainTexIntensity。属性必须存在且可动画化。"), hintStyle);
                    }
                    loop = EditorGUILayout.Toggle(CHToolLanguage.Text("AnimationClip 循环"), loop);
                    if (effectTiming.HasTracks)
                    {
                        includeEffectTiming = EditorGUILayout.Toggle(CHToolLanguage.Text("合并子特效开关时间轴"), includeEffectTiming);
                        if (includeEffectTiming) GUILayout.Label(CHToolLanguage.Text("整份动画的 Animator 根物体：") + effectTiming.RootName + CHToolLanguage.Text("。上方的相对层级路径也以它为根。"), hintStyle);
                    }
                    if (GUILayout.Button(CHToolLanguage.Text("导出当前映射 .anim"), GUILayout.Height(26))) Run(SaveAnimation);
                    GUILayout.Label(CHToolLanguage.Text(".anim 使用秒轴。添加到 Animator / Timeline，并让音频与动画同一时刻播放。"), hintStyle);
                }
                else
                {
                    target = (GameObject)EditorGUILayout.ObjectField(CHToolLanguage.Text("目标场景物体"), target, typeof(GameObject), true);
                    if (GUILayout.Button(CHToolLanguage.Text("使用当前选中物体"), EditorStyles.miniButton)) target = Selection.activeGameObject;
                    includeChildren = EditorGUILayout.Toggle(CHToolLanguage.Text("包括子级粒子"), includeChildren);
                    particleProperty = (RhythmParticleProperty)EditorGUILayout.Popup(CHToolLanguage.Text("目标参数"), (int)particleProperty, CHToolLanguage.Text(ParticleNames));
                    alignDuration = EditorGUILayout.Toggle(CHToolLanguage.Text("Duration 对齐音频"), alignDuration);
                    using (new EditorGUI.DisabledScope(!alignDuration)) loop = EditorGUILayout.Toggle(CHToolLanguage.Text("粒子循环"), loop);
                    int targetCount = 0;
                    string targetError = null;
                    try { targetCount = RhythmCurveExport.Targets(target, includeChildren).Length; }
                    catch (Exception error) { targetError = error.Message; }
                    GUILayout.Label(targetError ?? (CHToolLanguage.Text("将影响 ") + targetCount + CHToolLanguage.Text(" 个 ParticleSystem，可用 Ctrl+Z 撤销。")), hintStyle);
                    EditorGUILayout.HelpBox(CHToolLanguage.Text("应用会停止并清空目标粒子，再替换所选参数曲线。对齐时长时会清零 Start Delay 并设置 Loop；已有 Burst 和其他模块保留。场景不自动保存。"), MessageType.Info);
                    using (new EditorGUI.DisabledScope(targetCount == 0 || EditorApplication.isPlayingOrWillChangePlaymode))
                        if (GUILayout.Button(CHToolLanguage.Text("应用当前曲线到 ") + targetCount + CHToolLanguage.Text(" 个粒子"), GUILayout.Height(28))) Run(() =>
                        {
                            int changed = RhythmCurveExport.ApplyParticles(target, includeChildren, profile, channel, mapping, particleProperty, alignDuration, loop);
                            Notify(new CHToolMessage(CHToolLanguage.Text(true, "已应用到 ") + changed + CHToolLanguage.Text(true, " 个粒子。场景尚未保存，可用 Ctrl+Z 撤销。"), CHToolLanguage.Text(false, "已应用到 ") + changed + CHToolLanguage.Text(false, " 个粒子。场景尚未保存，可用 Ctrl+Z 撤销。")), MessageType.Info);
                        });
                    GUILayout.Label(CHToolLanguage.Text("初始大小 / 速度只影响新生成粒子。整团缩放或材质亮度请导出 .anim。"), hintStyle);
                }
            }
        }

        private void SaveProfile()
        {
            string path = EditorUtility.SaveFilePanelInProject(CHToolLanguage.Text("保存节奏曲线"), source.name + "_Rhythm", "asset", CHToolLanguage.Text("保存六条曲线和分析参数。"));
            if (string.IsNullOrEmpty(path)) return;
            var copy = Object.Instantiate(profile); copy.hideFlags = HideFlags.None;
            RhythmCurveExport.SaveNewAsset(copy, path);
            Notify(new CHToolMessage(CHToolLanguage.Text(true, "已保存 ") + AssetDatabase.GetAssetPath(copy) + CHToolLanguage.Text(true, "；同名文件会自动编号。"), CHToolLanguage.Text(false, "已保存 ") + AssetDatabase.GetAssetPath(copy) + CHToolLanguage.Text(false, "；同名文件会自动编号。")), MessageType.Info);
        }

        private void SaveAnimation()
        {
            string path = EditorUtility.SaveFilePanelInProject(CHToolLanguage.Text("导出动画片段"), source.name + "_" + channel, "anim", CHToolLanguage.Text("导出当前通道与输出映射。"));
            if (string.IsNullOrEmpty(path)) return;
            Type type = rendererType == 0 ? typeof(MeshRenderer) : rendererType == 1 ? typeof(SkinnedMeshRenderer) : typeof(ParticleSystemRenderer);
            var clip = RhythmCurveExport.CreateAnimation(profile, channel, mapping, animationTarget, bindingPath, shaderProperty, type, loop);
            try
            {
                if (includeEffectTiming && effectTiming.HasTracks) effectTiming.AppendTo(clip, profile.Duration, mapping.timeOffset);
                RhythmCurveExport.SaveNewAsset(clip, path);
            }
            catch
            {
                if (!EditorUtility.IsPersistent(clip)) Object.DestroyImmediate(clip);
                throw;
            }
            Notify(new CHToolMessage(CHToolLanguage.Text(true, "已导出 ") + AssetDatabase.GetAssetPath(clip) + "。", CHToolLanguage.Text(false, "已导出 ") + AssetDatabase.GetAssetPath(clip) + "。"), MessageType.Info);
        }

        private void Run(Action action)
        {
            try { action(); }
            catch (ExitGUIException) { throw; }
            catch (OperationCanceledException) { Notify(new CHToolMessage(CHToolLanguage.Text(true, "已取消分析，保留上一份曲线。"), CHToolLanguage.Text(false, "已取消分析，保留上一份曲线。")), MessageType.Info); }
            catch (Exception error) { Notify(error.GetBaseException().Message, MessageType.Error); }
        }

        private void Notify(string text, MessageType type) { Notify(new CHToolMessage(text, text), type); }
        private void Notify(CHToolMessage text, MessageType type) { status = text; statusType = type; Repaint(); }
    }
}
