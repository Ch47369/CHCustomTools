using ASEShaderConverter.Editor;
using UnityEditor;
using UnityEngine;

namespace CH.CustomTools.Paths.Editor
{
    internal static class PathText
    {
        public static string T(string zh, string en) { return CHToolLanguage.Pick(zh, en); }
        public static int Choice(string zh, string en, int selected, string[] chinese, string[] english) { return EditorGUILayout.Popup(T(zh, en), selected, CHToolLanguage.IsChinese ? chinese : english); }
    }
    [CustomEditor(typeof(BezierPath))]
    public sealed class BezierPathEditor : UnityEditor.Editor
    {
        public static bool SnapToSurface;
        public static bool ShowOrientation;
        public static bool RotatePoints;
        public override void OnInspectorGUI()
        {
            EditorGUILayout.LabelField("CH · " + PathText.T("路径", "Path"), EditorStyles.boldLabel);
            if (GUILayout.Button(PathText.T("在工具集中打开", "Open in CH Custom Tools"))) { ASEShaderConverterWindow.OpenPathTools(); Selection.activeObject = target; }
            PathSceneTool.DrawEnable((BezierPath)target);
            DrawPath((BezierPath)target);
        }
        internal static void DrawPath(BezierPath path)
        {
            try { path.ValidatePath(); } catch (System.Exception error) { EditorGUILayout.HelpBox(error.Message, MessageType.Error); return; }
            EditorGUILayout.HelpBox(PathText.T("直接拖动圆点调整路径；按住 Shift 从圆点拖出新点（首尾延长，中间插在后面）。Ctrl+点击曲线保形插点。松开鼠标完成，Esc取消拖拽，Ctrl+Z撤销整次操作。选中点显示控制柄；可切换移动 / 旋转，旋转圆环调整横向倾斜。高低起伏需配合点高度和切线。实时预览在工具集里开启，最后点生成确认。", "Drag a point to move it; hold Shift and drag a point to add one (extend endpoints, insert after an interior point). Ctrl+click the curve inserts without changing its shape. Release to finish, Esc to cancel, Ctrl+Z to undo the gesture. Select a point for its handles. Switch Move / Rotate to tilt around the tangent; adjust height and tangents for slopes. Enable live preview in the tool panel, then Generate to commit."), MessageType.None);
            var pointNames = new string[path.knots.Count]; for (int i = 0; i < pointNames.Length; i++) pointNames[i] = PathText.T("路径点 ", "Point ") + (i + 1);
            int focused = PathPointInsertion.FocusedIndex(path), nextPoint = EditorGUILayout.Popup(PathText.T("当前编辑点", "Editing point"), Mathf.Clamp(focused, 0, pointNames.Length - 1), pointNames);
            if (focused != nextPoint) PathPointInsertion.Focus(path, nextPoint);
            RotatePoints = EditorGUILayout.Popup(PathText.T("选中点操作（W / E）", "Point handle (W / E)"), RotatePoints ? 1 : 0,
                ASEShaderConverter.Editor.CHToolLanguage.IsChinese ? new[] { "移动", "旋转 / 倾斜" } : new[] { "Move", "Rotate / tilt" }) == 1;
            EditorGUILayout.HelpBox(PathText.T("每个点都可选中后用三轴旋转。X/Y 转动切线，改变局部曲线和网格方向；绕路径方向旋转调整横向倾斜。点的位置保持不动。", "Select any point for three-axis rotation. X/Y turn its tangents and local curve/mesh direction; rotation around the path banks the mesh. The point position stays fixed."), MessageType.None);
            int mode = PathKnotEditing.Mode(path, 0);
            bool mixed = false; for (int i = 1; i < path.knots.Count; i++) if (PathKnotEditing.Mode(path, i) != mode) mixed = true;
            var choices = new string[4]; choices[0] = PathText.T("混合（逐点设置）", "Mixed (per point)"); System.Array.Copy(PathKnotEditing.Names, 0, choices, 1, 3);
            int whole = EditorGUILayout.Popup(PathText.T("整条路径类型", "Whole path type"), mixed ? 0 : mode + 1, choices);
            if (whole > 0 && (mixed || whole != mode + 1)) PathKnotEditing.SetMode(path, -1, whole - 1);
            int selected = PathPointInsertion.FocusedIndex(path);
            if (selected >= 0 && selected < path.knots.Count)
            {
                int old = PathKnotEditing.Mode(path, selected);
                int next = EditorGUILayout.Popup(PathText.T("选中点类型 ", "Selected point type ") + (selected + 1), old, PathKnotEditing.Names);
                if (next != old) PathKnotEditing.SetMode(path, selected, next);
                EditorGUI.BeginChangeCheck();
                Vector3 rotation = EditorGUILayout.Vector3Field(PathText.T("选中点旋转（世界 XYZ 度）", "Point rotation (world XYZ degrees)"), PathKnotEditing.Rotation(path, selected).eulerAngles);
                if (EditorGUI.EndChangeCheck()) PathKnotEditing.SetRotation(path, selected, Quaternion.Euler(rotation));
            }
            var so = new SerializedObject(path); so.Update();
            EditorGUI.BeginChangeCheck();
            EditorGUILayout.PropertyField(so.FindProperty("closed"), new GUIContent(PathText.T("闭合路径", "Closed path")));
            EditorGUILayout.PropertyField(so.FindProperty("initialUp"), new GUIContent(PathText.T("初始上方向", "Initial up")));
            EditorGUILayout.PropertyField(so.FindProperty("sampleStep"), new GUIContent(PathText.T("最大采样间距（米）", "Max sample step (m)")));
            EditorGUILayout.PropertyField(so.FindProperty("chordTolerance"), new GUIContent(PathText.T("曲线误差（米）", "Curve tolerance (m)")));
            var knots = so.FindProperty("knots");
            for (int i = 0; i < knots.arraySize; i++)
            {
                var k = knots.GetArrayElementAtIndex(i);
                k.isExpanded = EditorGUILayout.Foldout(k.isExpanded, PathText.T("路径点 ", "Point ") + (i + 1), true);
                if (!k.isExpanded) continue;
                EditorGUI.indentLevel++;
                EditorGUILayout.PropertyField(k.FindPropertyRelative("position"), new GUIContent(PathText.T("位置（路径局部）", "Position (path local)")));
                int pointMode = PathKnotEditing.Mode(path, i);
                int pointNext = EditorGUILayout.Popup(PathText.T("点类型", "Point type"), pointMode, PathKnotEditing.Names);
                if (pointNext != pointMode) { so.ApplyModifiedProperties(); PathKnotEditing.SetMode(path, i, pointNext); so.Update(); }

                if (PathKnotEditing.Mode(path, i) == 2)
                {
                    EditorGUILayout.PropertyField(k.FindPropertyRelative("incoming"), new GUIContent(PathText.T("进入控制柄", "Incoming handle")));
                    EditorGUILayout.PropertyField(k.FindPropertyRelative("outgoing"), new GUIContent(PathText.T("离开控制柄", "Outgoing handle")));
                }
                EditorGUILayout.PropertyField(k.FindPropertyRelative("roll"), new GUIContent(PathText.T("旋转 / 横向倾斜（度）", "Rotation / bank (degrees)")));
                using (new EditorGUI.DisabledScope(knots.arraySize <= (path.closed ? 3 : 2)))
                    if (GUILayout.Button(PathText.T("删除此点", "Remove point")))
                    {
                        so.ApplyModifiedProperties();
                        PathKnotEditing.TryRemovePoint(path, i);
                        so.Update();
                        EditorGUI.indentLevel--;
                        break;
                    }
                EditorGUI.indentLevel--;
            }
            if (EditorGUI.EndChangeCheck()) { so.ApplyModifiedProperties(); path.Invalidate(); SceneView.RepaintAll(); }
            EditorGUILayout.BeginHorizontal();
            if (GUILayout.Button(PathText.T("末尾加点", "Append point")))
            {
                Undo.RecordObject(path, "Append path point"); int count = path.knots.Count;
                var position = count > 1 ? path.knots[count - 1].position * 2 - path.knots[count - 2].position : Vector3.forward * 5;
                path.knots.Add(new PathKnot(position)); path.Invalidate(); EditorUtility.SetDirty(path);
            }
            if (GUILayout.Button(PathText.T("在场景中编辑", "Edit in Scene"))) { PathSceneTool.Edit(path); if (SceneView.lastActiveSceneView != null) SceneView.lastActiveSceneView.FrameSelected(); }
            EditorGUILayout.EndHorizontal();
            SnapToSurface = EditorGUILayout.Toggle(PathText.T("拖点时贴合下方表面", "Snap moved points to surface"), SnapToSurface);
            ShowOrientation = EditorGUILayout.Toggle(PathText.T("显示路径朝向辅助线", "Show path orientation guides"), ShowOrientation);
        }
        internal static void DrawSceneHandles(BezierPath path)
        {
            if (!PathSceneTool.Active || Application.isPlaying || PathMotionPreview.IsActive || path.knots == null || PathPointDrag.IsDragging) return;
            try { path.ValidatePath(); } catch (System.Exception) { return; }
            if (PathPointInsertion.InsertionModifier(Event.current) && GUIUtility.hotControl == 0) return;
            if (Event.current.shift && GUIUtility.hotControl == 0) return;
            for (int i = 0; i < path.knots.Count; i++)
            {
                var k = path.knots[i]; if (k == null) continue; var position = path.transform.TransformPoint(k.position);
                if (!PathPointInsertion.IsFocused(path, i)) continue;
                Handles.color = PathPointInsertion.IsFocused(path, i) ? Color.green : Color.white;
                if (RotatePoints)
                {
                    var rotation = PathKnotEditing.Rotation(path, i);
                    int previousControl = GUIUtility.hotControl;
                    EditorGUI.BeginChangeCheck(); var rotated = Handles.RotationHandle(rotation, position);
                    if (previousControl == 0 && GUIUtility.hotControl != 0) Undo.IncrementCurrentGroup();
                    if (EditorGUI.EndChangeCheck()) PathKnotEditing.SetRotation(path, i, rotated);
                }
                else
                {
                int previousControl = GUIUtility.hotControl;
                EditorGUI.BeginChangeCheck(); var moved = Handles.PositionHandle(position, Tools.pivotRotation == PivotRotation.Local ? path.transform.rotation : Quaternion.identity);
                if (previousControl == 0 && GUIUtility.hotControl != 0) Undo.IncrementCurrentGroup();
                if (EditorGUI.EndChangeCheck())
                {
                    if (SnapToSurface)
                    {
                        Vector3 hit; if (Measurement.DmSceneTool.TrySurface(new Ray(moved + Vector3.up * 1000, Vector3.down), ~0, out hit)) moved = hit;
                    }
                    Undo.RecordObject(path, "Move path point"); k.position = path.transform.InverseTransformPoint(moved); path.Invalidate(); EditorUtility.SetDirty(path);
                }
                }
                if (k.automatic) continue;
                for (int h = 0; h < 2; h++)
                {
                    if (PathKnotEditing.Mode(path, i) == 0) continue;
                    Vector3 point = path.transform.TransformPoint(path.Handle(i, h == 1)); Handles.color = Measurement.DmSkin.Accent; Handles.DrawLine(position, point);
                    int previousControl = GUIUtility.hotControl;
                    EditorGUI.BeginChangeCheck(); Vector3 handle = Handles.FreeMoveHandle(point, HandleUtility.GetHandleSize(point) * .065f, Vector3.zero, Handles.RectangleHandleCap);
                    if (previousControl == 0 && GUIUtility.hotControl != 0) Undo.IncrementCurrentGroup();
                    if (EditorGUI.EndChangeCheck()) PathKnotEditing.MoveTangent(path, i, h == 1, handle);
                }
            }
        }
        // Handles belong to the Scene GUI pass. A DrawGizmo callback can omit them even
        // when Gizmos is enabled; selected-path editing must also work with Gizmos off.
        internal static void DrawSceneCurve(BezierPath path, bool selected)
        {
            if (path == null || Event.current.type != EventType.Repaint) return;
            var depth = Handles.zTest;
            try
            {
                path.ValidatePath();
                using (new Handles.DrawingScope(Measurement.DmSkin.Palette[1], Matrix4x4.identity))
                {
                    Handles.zTest = selected ? UnityEngine.Rendering.CompareFunction.Always : UnityEngine.Rendering.CompareFunction.LessEqual;
                    for (int i = 0; i < path.SegmentCount; i++)
                    {
                        int end = (i + 1) % path.knots.Count;
                        CHSceneVisuals.Curve(path.transform.TransformPoint(path.knots[i].position),
                            path.transform.TransformPoint(path.Handle(i, true)), path.transform.TransformPoint(path.Handle(end, false)),
                            path.transform.TransformPoint(path.knots[end].position), Measurement.DmSkin.Palette[1], selected);
                    }
                    if (!selected || !ShowOrientation) return;
                    float length = path.Length; int count = Mathf.Max(1, Mathf.Min(80, Mathf.CeilToInt(length)));
                    for (int i = 0; i <= count; i++) { var p = path.Evaluate(length * i / count); Handles.color = Color.green; Handles.DrawLine(p.position, p.position + p.up * .3f); Handles.color = Color.red; Handles.DrawLine(p.position, p.position + p.tangent * .3f); }
                }
            }
            catch (System.Exception) { /* Invalid paths are reported by authoring actions. */ }
            finally { Handles.zTest = depth; }
        }
    }
    [CustomEditor(typeof(PathFollower))]
    public sealed class PathFollowerEditor : UnityEditor.Editor
    {
        public override void OnInspectorGUI() { DrawFollower((PathFollower)target); }
        static readonly string[] AxisNames = { "+Z", "+Y", "+X", "-Z", "-Y", "-X" };
        static bool advanced;
        static int bakeFrameRate = 60;
        static string motionMessage;
        internal static void DrawFollower(PathFollower follower)
        {
            var so = new SerializedObject(follower);
            so.Update();
            EditorGUI.BeginChangeCheck();
            Field(so, "path", "运动路径", "Path");
            var drive = so.FindProperty("drive");
            drive.enumValueIndex = PathText.Choice("运动方式", "Motion driver", drive.enumValueIndex,
                new[] { "自动运动", "动画进度 K 帧" }, new[] { "Automatic motion", "Animation progress keys" });
            bool animation = drive.enumValueIndex == (int)PathMotionDrive.AnimationProgress;
            if (animation)
            {
                Field(so, "animationDuration", "默认动画用时（秒）", "Default clip duration (s)");
                Field(so, "progressClip", "进度动画片段", "Progress animation clip");
                Field(so, "progress", "路径进度（0–1）", "Path progress (0–1)");
                Field(so, "reverse", "反向朝向", "Face backwards");
            }
            else
            {
                Field(so, "speed", "速度（米/秒）", "Speed (m/s)");
                if (follower.path != null)
                {
                    try
                    {
                        var length = follower.path.Length;
                        var speed = so.FindProperty("speed");
                        EditorGUI.BeginChangeCheck();
                        float duration = EditorGUILayout.FloatField(PathText.T("走完整条路径（秒）", "Full path duration (s)"),
                            speed.floatValue > 0 ? length / speed.floatValue : 0);
                        if (EditorGUI.EndChangeCheck() && duration > 0 && float.IsFinite(duration))
                            speed.floatValue = length / duration;
                    }
                    catch (System.Exception e) { EditorGUILayout.HelpBox(e.Message, MessageType.Warning); }
                }
                Field(so, "startDistance", "起始距离（米）", "Start distance (m)");
                Field(so, "reverse", "反向行进", "Reverse");
                Field(so, "playOnEnable", "运行时自动播放", "Play on enable");
                var travel = so.FindProperty("travel");
                travel.enumValueIndex = PathText.Choice("到达终点", "End behavior", travel.enumValueIndex,
                    new[] { "停在终点", "循环", "往返" }, new[] { "Once", "Loop", "Ping-pong" });
            }

            EditorGUILayout.Space(6);
            EditorGUILayout.LabelField(PathText.T("模型朝向", "Model orientation"), EditorStyles.boldLabel);
            var orientation = so.FindProperty("orientation");
            orientation.enumValueIndex = PathText.Choice("朝向方式", "Orientation", orientation.enumValueIndex,
                new[] { "空间飞行（沿路径俯仰、倾斜）", "沿路径，世界上方向", "保持原旋转", "地面运动（仅水平转向）" },
                new[] { "3D flight (pitch and bank)", "Follow path, world up", "Keep rotation", "Ground motion (yaw only)" });
            if (orientation.enumValueIndex != (int)PathOrientation.PositionOnly)
            {
                var forward = so.FindProperty("modelForward");
                var up = so.FindProperty("modelUp");
                forward.enumValueIndex = EditorGUILayout.Popup(PathText.T("模型正前方", "Model forward"), forward.enumValueIndex, AxisNames);
                var forwardVector = PathFollower.AxisVector((PathModelAxis)forward.enumValueIndex);
                var validUp = new System.Collections.Generic.List<int>();
                var upNames = new System.Collections.Generic.List<string>();
                for (int i = 0; i < AxisNames.Length; i++)
                    if (Mathf.Abs(Vector3.Dot(forwardVector, PathFollower.AxisVector((PathModelAxis)i))) < .5f)
                    { validUp.Add(i); upNames.Add(AxisNames[i]); }
                int current = validUp.IndexOf(up.enumValueIndex);
                up.enumValueIndex = validUp[EditorGUILayout.Popup(PathText.T("模型上方向", "Model up"), Mathf.Max(current, 0), upNames.ToArray())];
                Field(so, "rotationOffset", "额外旋转修正（度）", "Additional rotation offset (degrees)");
                if (GUILayout.Button(PathText.T("重置旋转修正", "Reset rotation offset")))
                    so.FindProperty("rotationOffset").vector3Value = Vector3.zero;
            }
            advanced = EditorGUILayout.Foldout(advanced, PathText.T("偏移、前视与侧倾", "Offset, look-ahead and banking"), true);
            if (advanced)
            {
                Field(so, "positionOffset", "路径局部偏移（米）", "Path frame offset (m)");
                Field(so, "lookAhead", "朝向前视距离（米）", "Look-ahead distance (m)");
                if (!animation) Field(so, "turnSmoothing", "运行时转向平滑", "Runtime turn smoothing");
                Field(so, "maxBank", "最大侧倾角度", "Maximum bank (degrees)");
                Field(so, "bankStrength", "转弯侧倾强度", "Bank strength");
            }
            if (EditorGUI.EndChangeCheck())
            {
                so.ApplyModifiedProperties();
                RunMotionAction(() => { if (PathMotionPreview.IsFor(follower)) PathMotionPreview.Refresh(follower); });
            }
            if (!animation && follower.path != null && !follower.path.closed && follower.travel == PathTravel.Loop)
                EditorGUILayout.HelpBox(PathText.T("开放路径循环会从终点跳回起点。", "Looping an open path jumps from end to start."), MessageType.Warning);
            using (new EditorGUI.DisabledScope(Application.isPlaying || AnimationMode.InAnimationMode() || follower.path == null))
            {
                EditorGUILayout.Space(6);
                EditorGUILayout.LabelField(PathText.T("运动预览", "Motion preview"), EditorStyles.boldLabel);
                float current = PathMotionPreview.IsFor(follower) ? PathMotionPreview.Progress : follower.progress;
                EditorGUI.BeginChangeCheck();
                float previewProgress = EditorGUILayout.Slider(PathText.T("预览位置 (%)", "Preview position (%)"), current * 100, 0, 100) / 100;
                if (EditorGUI.EndChangeCheck()) RunMotionAction(() => PathMotionPreview.Scrub(follower, previewProgress));
                using (new EditorGUILayout.HorizontalScope())
                {
                    if (GUILayout.Button(PathText.T("播放预览", "Play preview"))) RunMotionAction(() => PathMotionPreview.Start(follower));
                    if (GUILayout.Button(PathText.T("停在当前位置", "Pause at current"))) RunMotionAction(() => PathMotionPreview.Scrub(follower, current));
                    if (GUILayout.Button(PathText.T("停止并恢复", "Stop and restore"))) PathMotionPreview.Stop();
                }
                DrawAnimationTools(follower);
            }
            if (!string.IsNullOrEmpty(motionMessage)) EditorGUILayout.HelpBox(motionMessage, MessageType.Warning);
        }
        static void RunMotionAction(System.Action action)
        {
            try { action(); motionMessage = null; }
            catch (System.Exception error) { motionMessage = error.Message; }
        }
        static void DrawAnimationTools(PathFollower follower)
        {
            EditorGUILayout.Space(8);
            EditorGUILayout.LabelField(PathText.T("动画片段", "Animation clips"), EditorStyles.boldLabel);
            if (follower.drive != PathMotionDrive.AnimationProgress)
            {
                var durationSettings = new SerializedObject(follower);
                durationSettings.Update();
                Field(durationSettings, "animationDuration", "动画用时（秒）", "Clip duration (s)");
                durationSettings.ApplyModifiedProperties();
            }
            if (GUILayout.Button(PathText.T("创建进度 K 帧片段", "Create progress keyframe clip")))
                RunMotionAction(() =>
                {
                    PathMotionPreview.Stop();
                    string path = EditorUtility.SaveFilePanelInProject(PathText.T("保存进度动画", "Save progress clip"), follower.name + "_Progress", "anim", "");
                    if (!string.IsNullOrEmpty(path)) PathMotionAnimation.CreateProgressClip(follower, path);
                });
            if (follower.progressClip != null)
            {
                if (PathMotionAnimation.Timing(follower) == null)
                    EditorGUILayout.HelpBox(PathText.T("此片段中缺少 Path Follower / Progress 曲线。", "This clip has no Path Follower / Progress curve."), MessageType.Warning);
                var animator = follower.GetComponent<Animator>();
                using (new EditorGUI.DisabledScope(animator != null && animator.runtimeAnimatorController != null))
                    if (GUILayout.Button(PathText.T("创建并绑定 Animator 控制器", "Create and assign Animator controller")))
                        RunMotionAction(() => PathMotionAnimation.AttachProgressController(follower));
                if (GUILayout.Button(PathText.T("打开 Unity Animation 编辑 K 帧", "Open Unity Animation to edit keys")))
                    RunMotionAction(() =>
                    {
                        PathMotionPreview.Stop();
                        Selection.activeGameObject = follower.gameObject;
                        var window = EditorWindow.GetWindow<AnimationWindow>();
                        window.animationClip = follower.progressClip;
                        window.Show();
                    });
                EditorGUILayout.HelpBox(PathText.T("进度曲线的 0 和 1 对应路径首尾。修改路径后，原 K 帧会沿新路径计算位置与朝向。外观动画可以在子物体上独立播放。",
                    "Progress 0 and 1 correspond to the path endpoints. Editing the path keeps the timing keys and updates the pose. Animate visual children independently."), MessageType.None);
                EditorGUILayout.LabelField(PathText.T("倒着运动时，可勾选反向朝向。", "Enable Face backwards for reverse motion."), EditorStyles.wordWrappedMiniLabel);
            }
            var so = new SerializedObject(follower);
            Field(so, "bakedClip", "位置 / 旋转输出片段", "Position / rotation clip");
            so.ApplyModifiedProperties();
            bakeFrameRate = EditorGUILayout.IntSlider(PathText.T("烘焙帧率", "Bake frame rate"), bakeFrameRate, 1, 120);
            if (GUILayout.Button(follower.bakedClip == null ? PathText.T("烘焙 Transform 动画", "Bake Transform animation") :
                PathText.T("重新烘焙已有片段", "Rebake existing clip")))
                RunMotionAction(() =>
                {
                    PathMotionPreview.Stop();
                    var output = follower.bakedClip;
                    bool create = output == null;
                    if (create)
                    {
                        string path = EditorUtility.SaveFilePanelInProject(PathText.T("保存位置旋转动画", "Save transform animation"), follower.name + "_Motion", "anim", "");
                        if (string.IsNullOrEmpty(path)) return;
                        if (AssetDatabase.LoadMainAssetAtPath(path) != null)
                            throw new System.InvalidOperationException(PathText.T("请选择新的资源路径或指定已有输出片段。", "Choose a new asset path or assign the existing output clip."));
                        output = new AnimationClip();
                        AssetDatabase.CreateAsset(output, path);
                    }
                    try { PathMotionAnimation.BakeTransform(follower, output, bakeFrameRate); }
                    catch
                    {
                        if (create) AssetDatabase.DeleteAsset(AssetDatabase.GetAssetPath(output));
                        throw;
                    }
                });
            if (follower.bakedClip != null)
                EditorGUILayout.HelpBox(PathText.T("输出位置和旋转曲线可用于普通 Animator。播放输出片段时请停用 Path Follower，避免重复控制根物体。重新烘焙会更新根位置和旋转曲线。",
                    "Play the baked Transform clip with Path Follower disabled to avoid driving the same root twice. Rebake updates the root position and rotation curves."), MessageType.None);
        }
        internal static void Field(SerializedObject so, string property, string zh, string en) { EditorGUILayout.PropertyField(so.FindProperty(property), new GUIContent(PathText.T(zh, en)), true); }
    }
}
