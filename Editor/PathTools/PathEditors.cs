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
        public override void OnInspectorGUI()
        {
            EditorGUILayout.LabelField("CH · " + PathText.T("路径", "Path"), EditorStyles.boldLabel);
            if (GUILayout.Button(PathText.T("在工具集中打开", "Open in CH Custom Tools"))) { ASEShaderConverterWindow.OpenPathTools(); Selection.activeObject = target; }
            DrawPath((BezierPath)target);
        }
        internal static void DrawPath(BezierPath path)
        {
            EditorGUILayout.HelpBox(PathText.T("直接拖动圆点调整路径；按住 Shift 从圆点拖出新点（首尾延长，中间插在后面）。Ctrl+点击曲线保形插点。松开鼠标完成，Esc取消拖拽，Ctrl+Z撤销整次操作。选中点显示控制柄；修改后重新生成模型或网格。", "Drag a point to move it; hold Shift and drag a point to add one (extend endpoints, insert after an interior point). Ctrl+click the curve inserts without changing its shape. Release to finish, Esc to cancel, Ctrl+Z to undo the gesture. Select a point for its handles. Rebuild models/meshes after editing."), MessageType.None);
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
                EditorGUILayout.PropertyField(k.FindPropertyRelative("automatic"), new GUIContent(PathText.T("自动平滑", "Automatic handles")));
                if (!k.FindPropertyRelative("automatic").boolValue)
                {
                    EditorGUILayout.PropertyField(k.FindPropertyRelative("incoming"), new GUIContent(PathText.T("进入控制柄", "Incoming handle")));
                    EditorGUILayout.PropertyField(k.FindPropertyRelative("outgoing"), new GUIContent(PathText.T("离开控制柄", "Outgoing handle")));
                }
                EditorGUILayout.PropertyField(k.FindPropertyRelative("roll"), new GUIContent(PathText.T("扭转角度", "Roll (degrees)")));
                using (new EditorGUI.DisabledScope(knots.arraySize <= (path.closed ? 3 : 2)))
                    if (GUILayout.Button(PathText.T("删除此点", "Remove point"))) { knots.DeleteArrayElementAtIndex(i); EditorGUI.indentLevel--; break; }
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
            if (GUILayout.Button(PathText.T("在场景中编辑", "Edit in Scene"))) { Selection.activeGameObject = path.gameObject; if (SceneView.lastActiveSceneView != null) SceneView.lastActiveSceneView.FrameSelected(); }
            EditorGUILayout.EndHorizontal();
            SnapToSurface = EditorGUILayout.Toggle(PathText.T("拖点时贴合下方表面", "Snap moved points to surface"), SnapToSurface);
            ShowOrientation = EditorGUILayout.Toggle(PathText.T("显示路径朝向辅助线", "Show path orientation guides"), ShowOrientation);
        }
        internal static void DrawSceneHandles(BezierPath path)
        {
            if (Application.isPlaying || PathMotionPreview.IsActive || path.knots == null || PathPointDrag.IsDragging) return;
            try { path.ValidatePath(); } catch (System.Exception) { return; }
            if (PathPointInsertion.InsertionModifier(Event.current) && GUIUtility.hotControl == 0) return;
            if (Event.current.shift && GUIUtility.hotControl == 0) return;
            for (int i = 0; i < path.knots.Count; i++)
            {
                var k = path.knots[i]; if (k == null) continue; var position = path.transform.TransformPoint(k.position);
                if (!PathPointInsertion.IsFocused(path, i)) continue;
                Handles.color = PathPointInsertion.IsFocused(path, i) ? Color.green : Color.white;
                EditorGUI.BeginChangeCheck(); var moved = Handles.PositionHandle(position, Tools.pivotRotation == PivotRotation.Local ? path.transform.rotation : Quaternion.identity);
                if (EditorGUI.EndChangeCheck())
                {
                    if (SnapToSurface)
                    {
                        Vector3 hit; if (Measurement.DmSceneTool.TrySurface(new Ray(moved + Vector3.up * 1000, Vector3.down), ~0, out hit)) moved = hit;
                    }
                    Undo.RecordObject(path, "Move path point"); k.position = path.transform.InverseTransformPoint(moved); path.Invalidate(); EditorUtility.SetDirty(path);
                }
                if (k.automatic) continue;
                for (int h = 0; h < 2; h++)
                {
                    Vector3 point = path.transform.TransformPoint(path.Handle(i, h == 1)); Handles.color = Color.gray; Handles.DrawLine(position, point);
                    EditorGUI.BeginChangeCheck(); Vector3 handle = Handles.PositionHandle(point, path.transform.rotation);
                    if (EditorGUI.EndChangeCheck())
                    { Undo.RecordObject(path, "Move path handle"); if (h == 0) k.incoming = path.transform.InverseTransformPoint(handle) - k.position; else k.outgoing = path.transform.InverseTransformPoint(handle) - k.position; path.Invalidate(); EditorUtility.SetDirty(path); }
                }
            }
        }
        [DrawGizmo(GizmoType.Selected | GizmoType.NonSelected)]
        static void DrawCurve(BezierPath path, GizmoType type)
        {
            if (path.knots == null || path.knots.Count < 2 || path.knots.Count > 512) return;
            try
            {
                path.ValidatePath(); bool selected = (type & GizmoType.Selected) != 0 || PathPointInsertion.SelectedPath() == path;
                Color color = Measurement.DmSkin.Palette[1]; if (!selected) color.a = .4f;
                using (new Handles.DrawingScope(Handles.color, Matrix4x4.identity))
                {
                    for (int i = 0; i < path.SegmentCount; i++) { int end = (i + 1) % path.knots.Count; CHSceneVisuals.Curve(path.transform.TransformPoint(path.knots[i].position), path.transform.TransformPoint(path.Handle(i, true)), path.transform.TransformPoint(path.Handle(end, false)), path.transform.TransformPoint(path.knots[end].position), color, selected); }
                    if (!selected || !ShowOrientation) return;
                    float length = path.Length; int count = Mathf.Min(80, Mathf.CeilToInt(length));
                    for (int i = 0; i <= count; i++) { var p = path.Evaluate(length * i / count); Handles.color = Color.green; Handles.DrawLine(p.position, p.position + p.up * .3f); Handles.color = Color.red; Handles.DrawLine(p.position, p.position + p.tangent * .3f); }
                }
            }
            catch (System.Exception) { /* Inspector shows invalid path details; gizmos must not spam logs. */ }
        }
    }
    [CustomEditor(typeof(PathFollower))]
    public sealed class PathFollowerEditor : UnityEditor.Editor
    {
        public override void OnInspectorGUI() { DrawFollower((PathFollower)target); }
        internal static void DrawFollower(PathFollower follower)
        {
            var so = new SerializedObject(follower); so.Update(); EditorGUI.BeginChangeCheck();
            Field(so, "path", "运动路径", "Path"); Field(so, "speed", "速度（米/秒）", "Speed (m/s)"); Field(so, "startDistance", "起始距离（米）", "Start distance (m)");
            Field(so, "reverse", "反向行进", "Reverse"); Field(so, "playOnEnable", "运行时自动播放", "Play on enable");
            var travel = so.FindProperty("travel"); travel.enumValueIndex = PathText.Choice("到达终点", "End behavior", travel.enumValueIndex, new[] { "停在终点", "循环", "往返" }, new[] { "Once", "Loop", "Ping-pong" });
            var orientation = so.FindProperty("orientation"); orientation.enumValueIndex = PathText.Choice("朝向方式", "Orientation", orientation.enumValueIndex, new[] { "跟随路径（含俯仰）", "保持世界上方向", "只移动位置" }, new[] { "Path frame (with pitch)", "World up", "Position only" });
            Field(so, "rotationOffset", "模型旋转修正（度）", "Model rotation offset (degrees)"); Field(so, "positionOffset", "路径局部偏移（米）", "Path frame offset (m)");
            Field(so, "lookAhead", "朝向前视距离（米）", "Look-ahead distance (m)"); Field(so, "turnSmoothing", "运行时转向平滑", "Runtime turn smoothing");
            Field(so, "maxBank", "最大侧倾角度", "Maximum bank (degrees)"); Field(so, "bankStrength", "转弯侧倾强度", "Bank strength");
            if (EditorGUI.EndChangeCheck()) { PathMotionPreview.Stop(); so.ApplyModifiedProperties(); }
            if (follower.path != null && !follower.path.closed && follower.travel == PathTravel.Loop) EditorGUILayout.HelpBox(PathText.T("开放路径使用循环会从终点跳回起点；连续飞行建议闭合路径，或选择往返。", "Looping an open path jumps from end to start. Use a closed path or ping-pong for continuous motion."), MessageType.Warning);
            EditorGUILayout.HelpBox(PathText.T("模型默认朝向 +Z、上方 +Y。鸟的 Animator 放在外观子物体上；根物体负责路径运动。侧倾设为0可关闭。", "Model forward is +Z and up is +Y. Put a bird's Animator on its visual child; the root handles path motion. Set maximum bank to 0 to disable banking."), MessageType.None);
            using (new EditorGUI.DisabledScope(Application.isPlaying))
                if (GUILayout.Button(PathMotionPreview.IsActive ? PathText.T("停止预览并恢复姿态", "Stop preview and restore pose") : PathText.T("预览路径运动", "Preview motion")))
                { if (PathMotionPreview.IsActive) PathMotionPreview.Stop(); else { try { PathMotionPreview.Start(follower); } catch (System.Exception e) { Debug.LogWarning(e.Message); } } }
        }
        internal static void Field(SerializedObject so, string property, string zh, string en) { EditorGUILayout.PropertyField(so.FindProperty(property), new GUIContent(PathText.T(zh, en)), true); }
    }
}
