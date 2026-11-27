using System;
using System.Linq;
using CH.CustomTools.Measurement;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.SceneManagement;

namespace CH.CustomTools.Paths.Editor
{
    [InitializeOnLoad]
    internal static class PathSequenceEditor
    {
        static PathFollower selectionOwner, guideTarget;
        static int selected;
        static string T(string zh, string en) => PathText.T(zh, en);

        static PathSequenceEditor()
        {
            SceneView.duringSceneGui += DrawScene;
            EditorApplication.playModeStateChanged += _ => SetGuideTarget(null);
            EditorSceneManager.activeSceneChangedInEditMode += (_, __) => SetGuideTarget(null);
        }
        internal static void SetGuideTarget(PathFollower follower)
        {
            if (guideTarget == follower) return;
            guideTarget = follower;
            SceneView.RepaintAll();
        }
        static Color ColorFor(int index) => DmSkin.Palette[index % DmSkin.Palette.Length];
        internal static Color? ColorFor(BezierPath path)
        {
            if (guideTarget == null || guideTarget.drive != PathMotionDrive.Sequence) return null;
            for (int i = 0; i < guideTarget.sequence.Count; i++)
                if (guideTarget.sequence[i].kind == PathSequenceKind.Path && guideTarget.sequence[i].path == path)
                    return ColorFor(i);
            return null;
        }
        static void DrawScene(SceneView view)
        {
            if (guideTarget == null || guideTarget.drive != PathMotionDrive.Sequence || view.camera == null ||
                Event.current.type != EventType.Repaint) return;
            for (int i = 0; i < guideTarget.sequence.Count; i++)
            {
                var stage = guideTarget.sequence[i];
                var path = stage.path;
                if (stage.kind != PathSequenceKind.Path || path == null || path.knots == null || path.knots.Count == 0 ||
                    (view.camera.cullingMask & (1 << path.gameObject.layer)) == 0 ||
                    SceneVisibilityManager.instance.IsHidden(path.gameObject) ||
                    StageUtility.GetStageHandle(path.gameObject) != StageUtility.GetCurrentStageHandle()) continue;
                var point = path.transform.TransformPoint(path.knots[stage.reverse && !path.closed ? path.knots.Count - 1 : 0].position);
                if (view.camera.WorldToViewportPoint(point).z <= view.camera.nearClipPlane) continue;
                CHSceneVisuals.Pill(HandleUtility.WorldToGUIPoint(point) + Vector2.up * (20 + i % 3 * 17),
                    new GUIContent((i + 1) + " · " + path.name), ColorFor(i), i == selected, DmSkin.SceneMetaStyle, DmSkin.TextPrimary);
            }
            try
            {
                var timeline = new PathSequenceTimeline(guideTarget, guideTarget.transform.rotation);
                foreach (var track in timeline.Tracks)
                {
                    if (!track.Transition) continue;
                    var points = new Vector3[33];
                    for (int i = 0; i < points.Length; i++)
                        points[i] = timeline.Evaluate(track.Start + track.Duration * i / (points.Length - 1)).position;
                    CHSceneVisuals.Line(DmSkin.Accent, true, points);
                }
            }
            catch (Exception) { /* Invalid sequence settings are displayed in the panel. */ }
        }

        static void Change(PathFollower follower, string label, Action operation)
        {
            Undo.RecordObject(follower, label);
            operation();
            PrefabUtility.RecordPrefabInstancePropertyModifications(follower);
            EditorUtility.SetDirty(follower);
            EditorSceneManager.MarkSceneDirty(follower.gameObject.scene);
            if (PathMotionPreview.IsFor(follower))
                try { PathMotionPreview.Refresh(follower); }
                catch { PathMotionPreview.Stop(); }
            SceneView.RepaintAll();
        }

        internal static void AddPath(PathFollower follower, BezierPath path)
        {
            if (path == null || follower.sequence.Count >= 128) return;
            Change(follower, "Append motion path", () =>
            {
                var last = follower.sequence.LastOrDefault(s => s.kind == PathSequenceKind.Path && s.path != null);
                bool connected = last == null;
                if (last != null)
                {
                    try { connected = Vector3.Distance(last.path.Evaluate(last.reverse ? 0 : last.path.Length).position, path.Evaluate(0).position) <= .001f; }
                    catch (Exception) { connected = false; }
                }
                follower.sequence.Add(new PathSequenceStage { path = path, connection = connected ?
                    PathSequenceConnection.Direct : PathSequenceConnection.Smooth });
                selected = follower.sequence.Count - 1;
            });
        }

        static void CreateNext(PathFollower follower)
        {
            var last = follower.sequence.LastOrDefault(s => s.kind == PathSequenceKind.Path && s.path != null);
            var p = last == null ? new PathSample { position = follower.transform.position, tangent = follower.transform.forward, up = Vector3.up } :
                last.path.Evaluate(last.reverse ? 0 : last.path.Length);
            if (last != null && last.reverse) p.tangent = -p.tangent;
            Undo.IncrementCurrentGroup();
            int group = Undo.GetCurrentGroup();
            var path = PathAuthoring.Create(PathPreset.Straight, p.position);
            if (path.gameObject.scene != follower.gameObject.scene)
                SceneManager.MoveGameObjectToScene(path.gameObject, follower.gameObject.scene);
            Undo.RecordObject(path.transform, "Align next motion path");
            path.transform.rotation = Quaternion.LookRotation(p.tangent, BezierPath.Perpendicular(p.tangent, p.up));
            path.Invalidate();
            AddPath(follower, path);
            Undo.CollapseUndoOperations(group);
            PathMotionPreview.Stop();
            PathSceneTool.Edit(path);
        }

        internal static PathSequenceTimeline Draw(PathFollower follower, BezierPath currentPath)
        {
            if (selectionOwner != follower) { selectionOwner = follower; selected = 0; }
            EditorGUILayout.Space(8);
            EditorGUILayout.LabelField(T("运动序列", "Motion sequence"), EditorStyles.boldLabel);
            using (new EditorGUILayout.HorizontalScope())
            {
                using (new EditorGUI.DisabledScope(currentPath == null || follower.sequence.Count >= 128))
                    if (GUILayout.Button(T("添加当前路径", "Add current path"))) AddPath(follower, currentPath);
                using (new EditorGUI.DisabledScope(follower.sequence.Count >= 128))
                {
                    if (GUILayout.Button(T("新建下一段", "Create next path")))
                    {
                        try { CreateNext(follower); }
                        catch (Exception e) { Debug.LogWarning(e.Message, follower); }
                    }
                    using (new EditorGUI.DisabledScope(follower.sequence.Count == 0))
                    if (GUILayout.Button(T("添加停留", "Add hold")))
                        Change(follower, "Append hold", () =>
                        {
                            follower.sequence.Add(new PathSequenceStage { kind = PathSequenceKind.Hold, duration = 10 });
                            selected = follower.sequence.Count - 1;
                        });
                }
            }
            selected = Mathf.Clamp(selected, 0, Mathf.Max(0, follower.sequence.Count - 1));
            for (int i = 0; i < follower.sequence.Count; i++)
            {
                var stage = follower.sequence[i];
                using (new EditorGUILayout.HorizontalScope())
                {
                    var swatch = GUILayoutUtility.GetRect(5, 23, GUILayout.Width(5));
                    EditorGUI.DrawRect(swatch, stage.kind == PathSequenceKind.Hold ? Color.gray : ColorFor(i));
                    string name = stage.kind == PathSequenceKind.Hold ? T("停留", "Hold") :
                        stage.path == null ? T("未指定路径", "Unassigned path") : stage.path.name;
                    if (GUILayout.Toggle(i == selected, (i + 1) + ". " + name, "Button", GUILayout.Height(23))) selected = i;
                    GUILayout.Label(stage.duration.ToString("0.##") + "s", GUILayout.Width(55));
                }
            }
            if (follower.sequence.Count > 0)
            {
                using (new EditorGUILayout.HorizontalScope())
                {
                    using (new EditorGUI.DisabledScope(selected == 0))
                        if (GUILayout.Button("↑")) Change(follower, "Move sequence stage up", () => Swap(follower, -1));
                    using (new EditorGUI.DisabledScope(selected == follower.sequence.Count - 1))
                        if (GUILayout.Button("↓")) Change(follower, "Move sequence stage down", () => Swap(follower, 1));
                    using (new EditorGUI.DisabledScope(follower.sequence.Count >= 128))
                        if (GUILayout.Button(T("复制", "Duplicate"))) Change(follower, "Duplicate sequence stage",
                            () => { var copy = JsonUtility.FromJson<PathSequenceStage>(JsonUtility.ToJson(follower.sequence[selected]));
                                copy.path = follower.sequence[selected].path; follower.sequence.Insert(++selected, copy); });
                    if (GUILayout.Button(T("删除", "Remove"))) Change(follower, "Remove sequence stage",
                        () => { follower.sequence.RemoveAt(selected); selected = Mathf.Max(0, selected - 1); });
                }
                if (follower.sequence.Count > 0) DrawStage(follower);
            }

            try
            {
                var timeline = new PathSequenceTimeline(follower, follower.transform.rotation);
                EditorGUILayout.LabelField(T("总时长", "Total duration"), timeline.Duration.ToString("0.###") + " s");
                var bar = GUILayoutUtility.GetRect(10, 24, GUILayout.ExpandWidth(true));
                foreach (var track in timeline.Tracks)
                {
                    var rect = new Rect(bar.x + bar.width * track.Start / timeline.Duration, bar.y,
                        bar.width * track.Duration / timeline.Duration, bar.height);
                    EditorGUI.DrawRect(rect, track.Transition ? DmSkin.Accent : track.Hold ? Color.gray : ColorFor(track.StageIndex));
                    if (rect.width > 24) GUI.Label(rect, track.Transition ? T("过渡", "Blend") : (track.StageIndex + 1).ToString(), EditorStyles.centeredGreyMiniLabel);
                }
                if (follower.loopSequence && Vector3.Distance(timeline.StartPose.position, timeline.EndPose.position) > .001f)
                    EditorGUILayout.HelpBox(T("循环时终点将跳回起点。", "Looping jumps from the end to the start."), MessageType.Warning);
                return timeline;
            }
            catch (Exception e) { EditorGUILayout.HelpBox(e.Message, MessageType.Warning); return null; }
        }
        static void Swap(PathFollower follower, int direction)
        {
            int next = selected + direction;
            var stage = follower.sequence[selected];
            follower.sequence[selected] = follower.sequence[next];
            follower.sequence[next] = stage;
            selected = next;
        }
        static void DrawStage(PathFollower follower)
        {
            var so = new SerializedObject(follower);
            var stage = so.FindProperty("sequence").GetArrayElementAtIndex(selected);
            var kind = follower.sequence[selected].kind;
            EditorGUI.BeginChangeCheck();
            EditorGUILayout.PropertyField(stage.FindPropertyRelative("duration"), new GUIContent(T("持续时间（秒）", "Duration (s)")));
            if (kind == PathSequenceKind.Hold)
                EditorGUILayout.PropertyField(stage.FindPropertyRelative("turnToNext"), new GUIContent(T("停留时转向下一段", "Turn towards next path")));
            else
            {
                EditorGUILayout.PropertyField(stage.FindPropertyRelative("path"), new GUIContent(T("路径", "Path")));
                EditorGUILayout.PropertyField(stage.FindPropertyRelative("reverse"), new GUIContent(T("反向运动", "Reverse travel")));
                var orient = stage.FindPropertyRelative("orientation");
                orient.enumValueIndex = PathText.Choice("阶段朝向", "Stage orientation", orient.enumValueIndex,
                    new[] { "继承全局", "空间飞行", "世界上方向", "保持旋转", "水平转向" },
                    new[] { "Inherit", "3D flight", "World up", "Keep rotation", "Ground" });
                EditorGUILayout.PropertyField(stage.FindPropertyRelative("timing"), new GUIContent(T("阶段进度曲线", "Stage timing curve")));
                if (selected > 0)
                {
                    var connection = stage.FindPropertyRelative("connection");
                    connection.enumValueIndex = PathText.Choice("衔接方式", "Connection", connection.enumValueIndex,
                        new[] { "直接连接", "平滑过渡" }, new[] { "Direct", "Smooth" });
                    if (connection.enumValueIndex == (int)PathSequenceConnection.Smooth)
                        EditorGUILayout.PropertyField(stage.FindPropertyRelative("transitionDuration"), new GUIContent(T("额外过渡时长（秒）", "Transition duration (s)")));
                }
            }
            if (EditorGUI.EndChangeCheck())
            {
                so.ApplyModifiedProperties();
                if (PathMotionPreview.IsFor(follower))
                    try { PathMotionPreview.Refresh(follower); } catch { PathMotionPreview.Stop(); }
                SceneView.RepaintAll();
            }
            if (kind == PathSequenceKind.Path && follower.sequence[selected].path != null &&
                GUILayout.Button(T("编辑此路径", "Edit this path")))
            {
                if (PathMotionPreview.BlocksPathEditing) PathMotionPreview.Stop();
                PathSceneTool.Edit(follower.sequence[selected].path);
            }
        }
    }
}
