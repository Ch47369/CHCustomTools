using System;
using UnityEditor;
using UnityEngine;
using static CH.CustomTools.VFX.ParticleTrailText;

namespace CH.CustomTools.VFX
{
    [Serializable]
    internal sealed class ParticleTrailPanel
    {
        [SerializeField] private ParticleSystem target;
        [SerializeField] private Paths.BezierPath sourcePath;
        [SerializeField] private bool reverseImport;
        [SerializeField] private Vector2 scroll;
        [NonSerialized] private string failure;

        internal void SetTarget(ParticleSystem system)
        {
            if (target == system) return;
            ParticleTrailSceneTool.Stop();
            target = system;
            failure = null;
        }

        internal void DrawPanel()
        {
            using (var view = new EditorGUILayout.ScrollViewScope(scroll))
            {
                scroll = view.scrollPosition;
                SetTarget((ParticleSystem)EditorGUILayout.ObjectField(Pick("目标粒子系统", "Target particle system"),
                    target, typeof(ParticleSystem), true));
                using (new EditorGUI.DisabledScope(Selection.activeGameObject == null ||
                    Selection.activeGameObject.GetComponent<ParticleSystem>() == null))
                    if (GUILayout.Button(Pick("使用当前选中的粒子系统", "Use selected particle system")))
                        SetTarget(Selection.activeGameObject.GetComponent<ParticleSystem>());
                if (!ParticleTrailBaker.CanEdit(target))
                {
                    EditorGUILayout.HelpBox(Pick("请选择场景中的粒子系统，或进入 Prefab 模式编辑预制体。",
                        "Select a scene particle system, or edit a prefab in Prefab Mode."), MessageType.Info);
                    return;
                }

                EditorGUILayout.LabelField(Pick("复用场景路径", "Reuse scene path"), EditorStyles.boldLabel);
                sourcePath = (Paths.BezierPath)EditorGUILayout.ObjectField(Pick("源路径", "Source path"), sourcePath, typeof(Paths.BezierPath), true);
                using (new EditorGUILayout.HorizontalScope())
                {
                    if (GUILayout.Button(Pick("使用选中的路径或生成物", "Use selected path or output")))
                        sourcePath = Paths.Editor.PathPointInsertion.SelectionPath();
                    using (new EditorGUI.DisabledScope(sourcePath == null))
                        if (GUILayout.Button(Pick("导入路径", "Import path")))
                        {
                            try
                            {
                                ParticleTrailData.ImportPath(target, sourcePath, reverseImport);
                                ParticleTrailSceneTool.Start(target);
                                failure = null;
                            }
                            catch (Exception error) { failure = error.Message; }
                        }
                }
                reverseImport = EditorGUILayout.ToggleLeft(Pick("从终点到起点导入", "Import from end to start"), reverseImport);
                if (!string.IsNullOrEmpty(failure)) EditorGUILayout.HelpBox(failure, MessageType.Error);

                var path = ParticleTrailStore.Find(target);
                if (path == null && target.GetComponent<ParticleTrailPath>() != null)
                    path = ParticleTrailStore.GetOrCreate(target);
                bool active = path != null && ParticleTrailSceneTool.Active == target;
                bool edit = EditorGUILayout.ToggleLeft(Pick("在 Scene 视图中编辑路径", "Edit path in Scene view"), active);
                if (active != edit)
                {
                    if (edit)
                    {
                        ParticleTrailSceneTool.Start(target);
                        path = ParticleTrailStore.Find(target);
                    }
                    else ParticleTrailSceneTool.Stop();
                }
                EditorGUILayout.HelpBox(Pick("Shift + 左键添加点。W 移动点，E 旋转两侧切线，拖动方形控制柄精确调整曲线。Delete 删除，F 聚焦。",
                    "Shift-click to add points. W moves a point, E rotates its tangents. Drag square tangent handles to shape the curve. Delete removes a point, F frames it."),
                    MessageType.None);
                if (path == null) return;

                using (new EditorGUI.DisabledScope(path.knots.Count < 2))
                    if (GUILayout.Button(Pick("反转拖尾方向", "Reverse trail direction")))
                    {
                        ParticleTrailData.ReversePath(target);
                        ParticleTrailSceneTool.Selected = -1;
                    }
                DrawPath(path);
                GUILayout.Space(8);
                DrawBake(path);
            }
        }

        void DrawPath(ParticleTrailData path)
        {
            float duration = EditorGUILayout.FloatField(Pick("路径用时（秒）", "Travel time (seconds)"), path.Duration);
            if (float.IsFinite(duration) && duration != path.Duration)
                ParticleTrailSceneTool.Change(target, "Change trail travel time", data => data.Duration = duration);

            EditorGUILayout.LabelField(Pick("控制点", "Control points"), path.knots.Count.ToString());
            if (ParticleTrailSceneTool.Active != target || path.knots.Count == 0) return;
            int selected = ParticleTrailSceneTool.Selected;
            var names = new string[path.knots.Count];
            for (int i = 0; i < names.Length; i++) names[i] = Pick("点 ", "Point ") + (i + 1);
            int next = EditorGUILayout.Popup(Pick("选中点", "Selected point"), Mathf.Clamp(selected, 0, names.Length - 1), names);
            if (next != selected) ParticleTrailSceneTool.Selected = next;
            ParticleTrailSceneTool.Rotating = EditorGUILayout.Popup(Pick("选中点工具（W / E）", "Point tool (W / E)"),
                ParticleTrailSceneTool.Rotating ? 1 : 0,
                new[] { Pick("移动", "Move"), Pick("旋转切线", "Rotate tangents") }) == 1;
            var knot = path.knots[next];
            Vector3 position = EditorGUILayout.Vector3Field(Pick("位置（本地）", "Local position"), knot.position);
            if (position != knot.position && Paths.BezierPath.Finite(position))
                ParticleTrailSceneTool.Change(target, "Move trail point", data => data.knots[next].position = position);
            bool automatic = EditorGUILayout.Toggle(Pick("自动平滑", "Automatic smooth"), knot.automatic);
            if (automatic != knot.automatic)
                ParticleTrailSceneTool.Change(target, "Set trail point tangents", data =>
                {
                    if (automatic) data.knots[next].automatic = true;
                    else data.FreezeTangents(next);
                });
            if (next > 0) DrawTangent(path, next, false);
            if (next + 1 < path.knots.Count) DrawTangent(path, next, true);
        }

        void DrawTangent(ParticleTrailData path, int index, bool outgoing)
        {
            var old = path.Handle(index, outgoing) - path.knots[index].position;
            var value = EditorGUILayout.Vector3Field(outgoing ? Pick("离开切线（本地）", "Outgoing tangent (local)") :
                Pick("进入切线（本地）", "Incoming tangent (local)"), old);
            if (value == old || !Paths.BezierPath.Finite(value)) return;
            ParticleTrailSceneTool.Change(target, "Set particle trail tangent", data =>
            {
                data.FreezeTangents(index);
                if (outgoing) data.knots[index].outgoing = value;
                else data.knots[index].incoming = value;
            });
        }

        void DrawBake(ParticleTrailData path)
        {
            var changes = ParticleTrailBaker.MovementChanges(target);
            if (changes.Count != 0)
                EditorGUILayout.HelpBox(Pick("烘焙会调整这些运动设置：\n", "Baking will update these motion settings:\n") +
                    string.Join("\n", changes), MessageType.Warning);
            EditorGUILayout.LabelField(Pick("烘焙后仅使用原生粒子模块。路径控制点保存在项目编辑器数据中，可随时重新编辑。",
                "Baked particles use native modules. Path controls are saved in project editor data for future edits."), EditorStyles.wordWrappedMiniLabel);
            string prior = path.BakedSignature;
            if (!string.IsNullOrEmpty(prior) && prior != ParticleTrailBaker.Signature(path))
                EditorGUILayout.HelpBox(Pick("路径或用时已修改，请重新烘焙。", "The path or travel time has changed. Bake again."), MessageType.Info);
            using (new EditorGUI.DisabledScope(path.knots.Count < 2))
            {
                if (GUILayout.Button(string.IsNullOrEmpty(prior) ? Pick("烘焙", "Bake") : Pick("重新烘焙", "Bake again"), GUILayout.Height(28)))
                {
                    try
                    {
                        ParticleTrailBaker.Bake(target, path);
                        failure = null;
                        Selection.activeGameObject = target.gameObject;
                    }
                    catch (Exception error) { failure = error.Message; }
                }
            }
            var renderer = target.GetComponent<ParticleSystemRenderer>();
            if (renderer != null && target.trails.enabled && renderer.trailMaterial == null)
                EditorGUILayout.HelpBox(Pick("请在粒子 Renderer 的 Trail Material 指定与当前渲染管线兼容的材质。",
                    "Assign a Trail Material compatible with your render pipeline in the Particle System Renderer."), MessageType.Warning);
            if (GUILayout.Button(Pick("选中粒子系统进行预览", "Select system for preview")))
            {
                Selection.activeGameObject = target.gameObject;
                var scene = SceneView.lastActiveSceneView;
                if (scene != null && path.knots.Count > 0)
                {
                    var bounds = new Bounds(target.transform.TransformPoint(path.knots[0].position), Vector3.zero);
                    foreach (var knot in path.knots)
                        bounds.Encapsulate(target.transform.TransformPoint(knot.position));
                    bounds.Expand(.2f);
                    scene.Frame(bounds, false);
                    scene.Focus();
                }
            }
            EditorGUILayout.LabelField(Pick("使用 Scene 视图中 Unity 的粒子预览控制播放。",
                "Use Unity's particle preview controls in Scene view."), EditorStyles.wordWrappedMiniLabel);
        }
    }
}
