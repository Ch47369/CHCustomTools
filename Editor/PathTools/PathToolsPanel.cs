using System;
using ASEShaderConverter.Editor;
using UnityEditor;
using UnityEngine;

namespace CH.CustomTools.Paths.Editor
{
    [Serializable]
    internal sealed class PathToolsPanel
    {
        [SerializeField] BezierPath path;
        [SerializeField] GameObject model, motionTarget;
        [SerializeField] PathFollower follower;
        [SerializeField] Material material, posts;
        [SerializeField] PathMeshSettings mesh = new PathMeshSettings();
        [SerializeField] PathPlacementSettings placement = new PathPlacementSettings();
        [SerializeField] string folder = "Assets";
        [SerializeField] Vector2 scroll;
        [SerializeField] int tab, preset = 1;
        [NonSerialized] string message;
        static string T(string zh, string en) { return PathText.T(zh, en); }
        public void Deactivate() { PathMotionPreview.Stop(); }
        void Action(Action action) { try { PathMotionPreview.Stop(); action(); message = T("已完成。生成与路径编辑支持撤销。", "Done. Generation and path edits support Undo."); } catch (Exception e) { message = e.Message; } }
        public void DrawPanel()
        {
            scroll = EditorGUILayout.BeginScrollView(scroll);
            EditorGUILayout.HelpBox(T("1 创建或选择路径 → 2 在 Scene 拖动路径点 → 3 生成模型 / 网格，或设置路径运动。1世界单位按1米处理。", "1 Create/select a path → 2 Drag points in Scene → 3 Generate models/meshes or set up motion. One world unit is treated as one metre."), MessageType.None);
            EditorGUILayout.BeginHorizontal();
            preset = EditorGUILayout.Popup(preset, CHToolLanguage.IsChinese ? new[] { "直线", "S形曲线", "圆形", "空间飞行" } : new[] { "Straight", "S curve", "Circle", "3D flight" });
            if (GUILayout.Button(T("创建路径", "Create path"))) Action(() => { var view = SceneView.lastActiveSceneView; path = PathAuthoring.Create((PathPreset)preset, view == null ? Vector3.zero : view.pivot); });
            EditorGUILayout.EndHorizontal();
            EditorGUI.BeginChangeCheck(); var next = (BezierPath)EditorGUILayout.ObjectField(T("当前路径", "Current path"), path, typeof(BezierPath), true);
            if (EditorGUI.EndChangeCheck()) { Deactivate(); path = next; }
            if (GUILayout.Button(T("使用当前选择的路径", "Use selected path"))) { var selected = Selection.activeGameObject; if (selected != null) { var p = selected.GetComponentInParent<BezierPath>(); var output = selected.GetComponentInParent<PathGeneratedOutput>(); Deactivate(); path = p != null ? p : output != null ? output.owner : null; } }
            if (path == null) { EditorGUILayout.EndScrollView(); return; }
            try { EditorGUILayout.LabelField(T("路径长度", "Path length"), path.Length.ToString("0.###") + " m"); } catch (Exception e) { EditorGUILayout.HelpBox(e.Message, MessageType.Error); }
            int newTab = GUILayout.Toolbar(tab, CHToolLanguage.IsChinese ? new[] { "编辑路径", "沿线放模型", "生成网格", "路径运动" } : new[] { "Edit path", "Place models", "Build mesh", "Motion" });
            if (newTab != tab) { Deactivate(); tab = newTab; }
            GUILayout.Space(8);
            using (new EditorGUI.DisabledScope(EditorApplication.isPlayingOrWillChangePlaymode))
            {
                if (tab == 0) BezierPathEditor.DrawPath(path);
                else if (tab == 1) DrawPlacement(); else if (tab == 2) DrawMesh(); else DrawMotion();
            }
            if (!string.IsNullOrEmpty(message)) EditorGUILayout.HelpBox(message, MessageType.Info);
            EditorGUILayout.EndScrollView();
        }
        void DrawPlacement()
        {
            model = (GameObject)EditorGUILayout.ObjectField(T("模型 / 预制体", "Model / prefab"), model, typeof(GameObject), true);
            placement.spacing = EditorGUILayout.FloatField(T("放置间距（米）", "Spacing (m)"), placement.spacing);
            placement.includeEnd = EditorGUILayout.Toggle(T("开放路径补上终点", "Include open-path endpoint"), placement.includeEnd);
            placement.orientation = (PlacementOrientation)PathText.Choice("模型朝向", "Orientation", (int)placement.orientation, new[] { "跟随路径", "竖直放置", "固定世界朝向" }, new[] { "Follow path", "Upright", "Fixed world rotation" });
            placement.offset = EditorGUILayout.Vector3Field(T("路径局部偏移（米）", "Path frame offset (m)"), placement.offset);
            placement.rotation = EditorGUILayout.Vector3Field(T("模型旋转修正（度）", "Model rotation offset (degrees)"), placement.rotation);
            placement.scale = EditorGUILayout.Vector3Field(T("模型缩放倍率", "Model scale multiplier"), placement.scale);
            EditorGUILayout.HelpBox(T("按实际距离放置，保留预制体关联；模型保持刚体形状，不沿曲线弯曲。默认模型朝前 +Z，朝上 +Y。补终点时最后一段可能短于间距。", "Uses world-distance spacing and preserves prefab links. Models keep their rigid shape. Default forward is +Z, up is +Y. Including the endpoint can shorten the final interval."), MessageType.None);
            GenerationNote(); if (GUILayout.Button(T("生成 / 重新生成模型", "Generate / rebuild models"), GUILayout.Height(28))) Action(() => PathAuthoring.Place(path, model, placement));
        }
        void DrawMesh()
        {
            mesh.kind = (PathMeshKind)PathText.Choice("网格类型", "Mesh type", (int)mesh.kind, new[] { "连续标线 / 面片", "虚线", "方向箭头", "圆管", "栏杆" }, new[] { "Continuous ribbon", "Dashed line", "Direction arrows", "Tube", "Railing" });
            bool round = mesh.kind == PathMeshKind.Tube || mesh.kind == PathMeshKind.Railing;
            if (round) { mesh.radius = EditorGUILayout.FloatField(T("圆管半径（米）", "Tube radius (m)"), mesh.radius); mesh.sides = EditorGUILayout.IntSlider(T("圆周边数", "Radial sides"), mesh.sides, 3, 32); mesh.caps = EditorGUILayout.Toggle(T("封闭端面", "Cap open ends"), mesh.caps); }
            else { mesh.width = EditorGUILayout.FloatField(T("标线宽度（米）", "Width (m)"), mesh.width); mesh.surfaceOffset = EditorGUILayout.FloatField(T("离路径表面高度（米）", "Surface offset (m)"), mesh.surfaceOffset); mesh.twoSided = EditorGUILayout.Toggle(T("生成双面", "Generate two sides"), mesh.twoSided); }
            if (mesh.kind == PathMeshKind.DashedLine || mesh.kind == PathMeshKind.Arrows) { mesh.dashLength = EditorGUILayout.FloatField(T("每段长度（米）", "Mark length (m)"), mesh.dashLength); mesh.gap = EditorGUILayout.FloatField(T("空白间隔（米）", "Gap (m)"), mesh.gap); }
            if (mesh.kind == PathMeshKind.Railing) { mesh.height = EditorGUILayout.FloatField(T("栏杆高度（米）", "Railing height (m)"), mesh.height); mesh.postSpacing = EditorGUILayout.FloatField(T("立柱间距（米）", "Post spacing (m)"), mesh.postSpacing); mesh.railCount = EditorGUILayout.IntSlider(T("横杆数量", "Rail count"), mesh.railCount, 1, 4); }
            mesh.step = EditorGUILayout.FloatField(T("网格分段间距（米）", "Mesh segment step (m)"), mesh.step);
            mesh.metersPerTile = EditorGUILayout.FloatField(T("贴图每次重复长度（米）", "Metres per texture repeat"), mesh.metersPerTile);
            mesh.uvScale = EditorGUILayout.Vector2Field(T("UV平铺倍率", "UV tiling multiplier"), mesh.uvScale); mesh.uvOffset = EditorGUILayout.Vector2Field(T("UV偏移", "UV offset"), mesh.uvOffset);
            material = (Material)EditorGUILayout.ObjectField(T("材质 / 横杆材质", "Material / rail material"), material, typeof(Material), false);
            if (mesh.kind == PathMeshKind.Railing) posts = (Material)EditorGUILayout.ObjectField(T("立柱材质（可选）", "Post material (optional)"), posts, typeof(Material), false);
            EditorGUILayout.HelpBox(T("UV0：X横向，Y按距离平铺；UV1：X横向，Y为0到1路径进度（立柱为底到顶）。可直接赋予特效材质。空材质自动创建当前管线默认材质。急弯处宽网格可能相交，请减小宽度或调整曲线。UV1用于特效，烘焙光照前需另做光照UV。", "UV0: X across, Y tiled by distance. UV1: X across, Y normalized path progress (posts: bottom to top). Assign an effect material directly. Empty material creates a default for the active pipeline. Wide meshes can overlap at tight bends. UV1 is for effects; generate separate lightmap UVs before baking."), MessageType.None);
            EditorGUILayout.BeginHorizontal(); folder = EditorGUILayout.TextField(T("网格保存目录", "Mesh asset folder"), folder);
            if (GUILayout.Button(T("使用选择目录", "Use selected folder"), GUILayout.Width(135))) { string p = AssetDatabase.GetAssetPath(Selection.activeObject); if (AssetDatabase.IsValidFolder(p)) folder = p; }
            EditorGUILayout.EndHorizontal();
            var area = GUILayoutUtility.GetLastRect(); var ev = Event.current;
            if (area.Contains(ev.mousePosition) && (ev.type == EventType.DragUpdated || ev.type == EventType.DragPerform))
            { foreach (var item in DragAndDrop.objectReferences) { string p = AssetDatabase.GetAssetPath(item); if (!AssetDatabase.IsValidFolder(p) || !(p == "Assets" || p.StartsWith("Assets/", StringComparison.Ordinal))) continue; DragAndDrop.visualMode = DragAndDropVisualMode.Copy; if (ev.type == EventType.DragPerform) { DragAndDrop.AcceptDrag(); folder = p; } ev.Use(); break; } }
            GenerationNote(); if (GUILayout.Button(T("生成 / 重新生成网格", "Generate / rebuild mesh"), GUILayout.Height(28))) Action(() => PathAuthoring.Generate(path, mesh, material, posts, folder));
        }
        void GenerationNote() { EditorGUILayout.HelpBox(T("重新生成会替换此路径对应的生成组；组内手动编辑也会替换。其他场景物体保留。网格另存唯一资源，撤销场景生成后资源仍保留，便于重做。修改路径后需要重新生成。", "Rebuild replaces this path's generated group, including manual edits inside it. Other scene objects are preserved. Meshes use unique assets; scene Undo retains assets for Redo. Rebuild after editing the path."), MessageType.None); }
        void DrawMotion()
        {
            motionTarget = (GameObject)EditorGUILayout.ObjectField(T("运动根物体", "Moving root object"), motionTarget, typeof(GameObject), true);
            EditorGUILayout.BeginHorizontal();
            if (GUILayout.Button(T("给物体设置路径运动", "Attach path motion"))) Action(() => follower = PathAuthoring.Attach(path, motionTarget));
            if (GUILayout.Button(T("创建飞行演示", "Create flight demo"))) Action(() => { follower = PathAuthoring.FlightDemo(path); motionTarget = follower.gameObject; });
            EditorGUILayout.EndHorizontal();
            EditorGUILayout.HelpBox(T("飞行演示使用几何占位模型，可把鸟的模型或预制体放到根物体下替换外观。翅膀动画由自己的 Animator 控制。预览在停止、切页、关窗、重载或进入运行模式时恢复原姿态。", "Flight demo uses a geometric placeholder. Replace its visual child with your bird model/prefab and use its own Animator for wings. Preview restores the original pose on stop, page change, window close, reload or entering Play mode."), MessageType.None);
            if (motionTarget != null) follower = motionTarget.GetComponent<PathFollower>();
            if (follower != null) PathFollowerEditor.DrawFollower(follower);
        }
    }
}
