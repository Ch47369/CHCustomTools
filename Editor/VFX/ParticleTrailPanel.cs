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

                var path = target.GetComponent<ParticleTrailPath>();
                bool active = path != null && ParticleTrailSceneTool.Active == path;
                bool edit = EditorGUILayout.ToggleLeft(Pick("在 Scene 视图中编辑路径", "Edit path in Scene view"), active);
                if (active != edit)
                {
                    if (edit)
                    {
                        if (path == null) path = Undo.AddComponent<ParticleTrailPath>(target.gameObject);
                        ParticleTrailSceneTool.Start(path);
                    }
                    else ParticleTrailSceneTool.Stop();
                }
                EditorGUILayout.HelpBox(Pick("Shift + 左键添加点，拖动圆点或移动轴调整位置。点选后按 Delete 删除，按 F 聚焦。",
                    "Shift-click to add a point. Drag dots or the position handle to move them. Select a point and use Delete or F."),
                    MessageType.None);
                if (path == null) return;

                DrawPath(path);
                GUILayout.Space(8);
                DrawBake(path);
            }
        }

        static void DrawPath(ParticleTrailPath path)
        {
            float duration = EditorGUILayout.FloatField(Pick("路径用时（秒）", "Travel time (seconds)"), path.Duration);
            if (float.IsFinite(duration) && duration != path.Duration)
                ParticleTrailSceneTool.Change(path, "Change trail travel time", () => path.Duration = duration);

            EditorGUILayout.LabelField(Pick("控制点", "Control points"), path.Points.Count.ToString());
            if (ParticleTrailSceneTool.Active != path || path.Points.Count == 0) return;
            int selected = ParticleTrailSceneTool.Selected;
            var names = new string[path.Points.Count];
            for (int i = 0; i < names.Length; i++) names[i] = Pick("点 ", "Point ") + (i + 1);
            int next = EditorGUILayout.Popup(Pick("选中点", "Selected point"), Mathf.Clamp(selected, 0, names.Length - 1), names);
            if (next != selected) ParticleTrailSceneTool.Selected = next;
            Vector3 position = EditorGUILayout.Vector3Field(Pick("位置（本地）", "Local position"), path.Points[next]);
            if (position != path.Points[next] && Paths.BezierPath.Finite(position))
                ParticleTrailSceneTool.Change(path, "Move trail point", () => path.Points[next] = position);
        }

        void DrawBake(ParticleTrailPath path)
        {
            var changes = ParticleTrailBaker.MovementChanges(target);
            if (changes.Count != 0)
                EditorGUILayout.HelpBox(Pick("烘焙会调整这些运动设置：\n", "Baking will update these motion settings:\n") +
                    string.Join("\n", changes), MessageType.Warning);
            EditorGUILayout.LabelField(Pick("烘焙写入单粒子发射、Velocity over Lifetime 和 Trails。",
                "Baking sets up single-particle emission, Velocity over Lifetime and Trails."), EditorStyles.wordWrappedMiniLabel);
            string prior = path.BakedSignature;
            if (!string.IsNullOrEmpty(prior) && prior != ParticleTrailBaker.Signature(path))
                EditorGUILayout.HelpBox(Pick("路径或用时已修改，请重新烘焙。", "The path or travel time has changed. Bake again."), MessageType.Info);
            using (new EditorGUI.DisabledScope(path.Points.Count < 2))
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
            if (!string.IsNullOrEmpty(failure)) EditorGUILayout.HelpBox(failure, MessageType.Error);
            var renderer = target.GetComponent<ParticleSystemRenderer>();
            if (renderer != null && target.trails.enabled && renderer.trailMaterial == null)
                EditorGUILayout.HelpBox(Pick("请在粒子 Renderer 的 Trail Material 指定与当前渲染管线兼容的材质。",
                    "Assign a Trail Material compatible with your render pipeline in the Particle System Renderer."), MessageType.Warning);
            if (GUILayout.Button(Pick("选中粒子系统进行预览", "Select system for preview")))
            {
                Selection.activeGameObject = target.gameObject;
                var scene = SceneView.lastActiveSceneView;
                if (scene != null && path.Points.Count > 0)
                {
                    var bounds = new Bounds(path.transform.TransformPoint(path.Points[0]), Vector3.zero);
                    foreach (var point in path.Points)
                        bounds.Encapsulate(path.transform.TransformPoint(point));
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
