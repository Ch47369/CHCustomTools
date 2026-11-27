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
        [SerializeField] Material material, posts, fenceMaterial;
        [SerializeField] PathFenceAxis fenceDrawingAxis;
        [SerializeField] PathMeshSettings mesh = new PathMeshSettings();
        [SerializeField] PathPlacementSettings placement = new PathPlacementSettings();
        [SerializeField] string folder = "Assets";
        [SerializeField] Vector2 scroll;
        [SerializeField] int tab, preset = 1;
        [SerializeField] bool previewModels = true, previewMesh = true;
        [NonSerialized] string message;
        [NonSerialized] internal Rect useSelectionArea;
        static string T(string zh, string en) { return PathText.T(zh, en); }
        public void Deactivate() { PathFenceDraft.Cancel(); PathAuthoringPreview.Stop(); PathMotionPreview.Stop(); PathSceneTool.Active = false; }
        void Action(Action action) { try { PathMotionPreview.Stop(); action(); message = T("已完成。生成与路径编辑支持撤销。", "Done. Generation and path edits support Undo."); } catch (Exception e) { message = e.Message; } }
        void SelectPath(BezierPath next)
        {
            PathFenceDraft.Cancel();
            PathAuthoringPreview.Stop(); PathMotionPreview.Stop(); path = next;
            if (next == null) PathSceneTool.Active = false;
            else if (PathSceneTool.Active) PathSceneTool.Edit(next);
        }
        public void DrawPanel()
        {
            if (PathSceneTool.Active && PathSceneTool.EditingPath != null) path = PathSceneTool.EditingPath;
            else if (path == null) path = PathPointInsertion.SelectionPath();
            PathSceneTool.DrawEnable(path);
            scroll = EditorGUILayout.BeginScrollView(scroll);
            EditorGUILayout.HelpBox(T("1 创建或选择路径 → 2 在 Scene 拖动路径点 → 3 生成模型 / 网格，或设置路径运动。1世界单位按1米处理。", "1 Create/select a path → 2 Drag points in Scene → 3 Generate models/meshes or set up motion. One world unit is treated as one metre."), MessageType.None);
            EditorGUILayout.BeginHorizontal();
            preset = EditorGUILayout.Popup(preset, CHToolLanguage.IsChinese ? new[] { "直线", "S形曲线", "圆形", "空间飞行" } : new[] { "Straight", "S curve", "Circle", "3D flight" });
            if (GUILayout.Button(T("创建路径", "Create path"))) Action(() => { var view = SceneView.lastActiveSceneView; SelectPath(PathAuthoring.Create((PathPreset)preset, view == null ? Vector3.zero : view.pivot)); });
            EditorGUILayout.EndHorizontal();
            DrawFencePlacement();
            EditorGUI.BeginChangeCheck(); var next = (BezierPath)EditorGUILayout.ObjectField(T("当前路径", "Current path"), path, typeof(BezierPath), true);
            if (EditorGUI.EndChangeCheck()) SelectPath(next);
            if (GUILayout.Button(T("使用当前选择的路径", "Use selected path"))) { var selected = PathPointInsertion.SelectionPath(); if (selected != null) SelectPath(selected); else message = T("请先在层级中选择路径或它的生成组。", "Select a path or its generated group in the Hierarchy."); }
            if (Event.current.type == EventType.Repaint) { var rect = GUILayoutUtility.GetLastRect(); useSelectionArea = new Rect(GUIUtility.GUIToScreenPoint(rect.position), rect.size); }
            if (path == null) { EditorGUILayout.EndScrollView(); return; }
            if (!PathSceneTool.Active) EditorGUILayout.HelpBox(T("路径编辑未启用。勾选上方开关，或点击“在场景中编辑”，即可显示路径点、控制柄与实时预览。", "Path editing is off. Enable it above or click Edit in Scene to show points, handles and live previews."), MessageType.Info);
            try { EditorGUILayout.LabelField(T("路径长度", "Path length"), path.Length.ToString("0.###") + " m"); } catch (Exception e) { EditorGUILayout.HelpBox(e.Message, MessageType.Error); }
            int newTab = GUILayout.Toolbar(tab, CHToolLanguage.IsChinese ? new[] { "编辑路径", "沿线放模型", "生成网格", "路径运动" } : new[] { "Edit path", "Place models", "Build mesh", "Motion" });
            if (newTab != tab) { PathMotionPreview.Stop(); if (newTab == 3) PathAuthoringPreview.Stop(); tab = newTab; }
            if (tab != 3)
            {
                previewModels = EditorGUILayout.ToggleLeft(T("实时预览沿线模型", "Live model preview"), previewModels);
                previewMesh = EditorGUILayout.ToggleLeft(T("实时预览生成网格", "Live mesh preview"), previewMesh);
                if (previewModels || tab == 1) model = (GameObject)EditorGUILayout.ObjectField(T("沿线模型 / 预制体", "Path model / prefab"), model, typeof(GameObject), true);
                if (previewModels && model == null) EditorGUILayout.HelpBox(T("尚未指定模型。将模型或预制体拖到上方栏位，便可沿路径实时预览。", "No model selected. Drop a model or prefab above to preview copies along the path."), MessageType.Info);
                EditorGUILayout.HelpBox(T("勾选上方 Scene 编辑后，修改点、切线、倾斜、模型或网格参数会实时预览。预览不保存；最后点击生成 / 重新生成才确认输出。", "Enable Scene editing above. Points, tangents, tilt and placement/mesh settings update the preview. Click Generate / rebuild to commit the output."), MessageType.None);
            }
            GUILayout.Space(8);
            using (new EditorGUI.DisabledScope(EditorApplication.isPlayingOrWillChangePlaymode))
            {
                if (tab == 0) BezierPathEditor.DrawPath(path);
                else if (tab == 1) DrawPlacement(); else if (tab == 2) DrawMesh(); else DrawMotion();
            }
            if (tab != 3) PathAuthoringPreview.Configure(path, model, placement, mesh, MeshMaterial, posts, previewModels, previewMesh);
            if (!string.IsNullOrEmpty(PathAuthoringPreview.Status)) EditorGUILayout.HelpBox(PathAuthoringPreview.Status, MessageType.Warning);
            if (!string.IsNullOrEmpty(message)) EditorGUILayout.HelpBox(message, MessageType.Info);
            EditorGUILayout.EndScrollView();
        }

        Material MeshMaterial => mesh.kind == PathMeshKind.ElectronicFence ? fenceMaterial : material;

        static int AxisMenu(int selected)
        {
            return EditorGUILayout.Popup(selected, CHToolLanguage.IsChinese
                ? new[] { "XZ 平面 / +Y 高度", "YZ 平面 / +X 高度", "XY 平面 / +Z 高度" }
                : new[] { "XZ plane / +Y height", "YZ plane / +X height", "XY plane / +Z height" });
        }

        void DrawFencePlacement()
        {
            using (new EditorGUILayout.HorizontalScope())
            {
                using (new EditorGUI.DisabledScope(PathFenceDraft.Active))
                    fenceDrawingAxis = (PathFenceAxis)AxisMenu((int)fenceDrawingAxis);
                using (new EditorGUI.DisabledScope(EditorApplication.isPlayingOrWillChangePlaymode))
                {
                    if (PathFenceDraft.Active)
                    {
                        if (GUILayout.Button(T("取消绘制", "Cancel drawing"))) PathFenceDraft.Cancel();
                    }
                    else if (GUILayout.Button(T("在 Scene 绘制电子围栏", "Draw electronic fence in Scene")))
                    {
                        var scene = SceneView.lastActiveSceneView;
                        if (scene == null) scene = EditorWindow.GetWindow<SceneView>();
                        Deactivate();
                        var axis = fenceDrawingAxis;
                        PathFenceDraft.Begin(scene, axis, boundary =>
                        {
                            path = boundary;
                            mesh.kind = PathMeshKind.ElectronicFence;
                            mesh.fenceAxis = axis;
                            mesh.fenceLocalAxis = false;
                            previewMesh = true;
                            tab = 2;
                            scroll = Vector2.zero;
                            PathSceneTool.Edit(path);
                        });
                    }
                }
            }
            if (PathFenceDraft.Active)
                EditorGUILayout.HelpBox(T("左键落点，Shift 锁定轴向。回车或点击首点闭合，Backspace 撤回，Esc 取消。",
                    "Click to add points. Hold Shift to align a segment to an axis. Press Enter or click the first point to close. Backspace removes the last point. Esc cancels."),
                    MessageType.Info);
        }
        void DrawPlacement()
        {
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
            mesh.kind = (PathMeshKind)PathText.Choice("网格类型", "Mesh type", (int)mesh.kind, new[] { "连续标线 / 面片", "虚线", "方向箭头", "圆管", "栏杆", "电子围栏" }, new[] { "Continuous ribbon", "Dashed line", "Direction arrows", "Tube", "Railing", "Electronic fence" });
            bool fence = mesh.kind == PathMeshKind.ElectronicFence;
            bool round = mesh.kind == PathMeshKind.Tube || mesh.kind == PathMeshKind.Railing;
            if (fence) DrawFenceSettings();
            else if (round) { mesh.radius = EditorGUILayout.FloatField(T("圆管半径（米）", "Tube radius (m)"), mesh.radius); mesh.sides = EditorGUILayout.IntSlider(T("圆周边数", "Radial sides"), mesh.sides, 3, 32); mesh.caps = EditorGUILayout.Toggle(T("封闭端面", "Cap open ends"), mesh.caps); }
            else { mesh.width = EditorGUILayout.FloatField(T("标线宽度（米）", "Width (m)"), mesh.width); mesh.surfaceOffset = EditorGUILayout.FloatField(T("离路径表面高度（米）", "Surface offset (m)"), mesh.surfaceOffset); mesh.twoSided = EditorGUILayout.Toggle(T("生成双面", "Generate two sides"), mesh.twoSided); }
            if (mesh.kind == PathMeshKind.DashedLine || mesh.kind == PathMeshKind.Arrows) { mesh.dashLength = EditorGUILayout.FloatField(T("每段长度（米）", "Mark length (m)"), mesh.dashLength); mesh.gap = EditorGUILayout.FloatField(T("空白间隔（米）", "Gap (m)"), mesh.gap); }
            if (mesh.kind == PathMeshKind.Railing) { mesh.height = EditorGUILayout.FloatField(T("栏杆高度（米）", "Railing height (m)"), mesh.height); mesh.postSpacing = EditorGUILayout.FloatField(T("立柱间距（米）", "Post spacing (m)"), mesh.postSpacing); mesh.railCount = EditorGUILayout.IntSlider(T("横杆数量", "Rail count"), mesh.railCount, 1, 4); }
            mesh.step = EditorGUILayout.FloatField(T("网格分段间距（米）", "Mesh segment step (m)"), mesh.step);
            mesh.metersPerTile = EditorGUILayout.FloatField(T("贴图每次重复长度（米）", "Metres per texture repeat"), mesh.metersPerTile);
            mesh.uvScale = EditorGUILayout.Vector2Field(T("UV平铺倍率", "UV tiling multiplier"), mesh.uvScale); mesh.uvOffset = EditorGUILayout.Vector2Field(T("UV偏移", "UV offset"), mesh.uvOffset);
            if (!fence) material = (Material)EditorGUILayout.ObjectField(T("材质 / 横杆材质", "Material / rail material"), material, typeof(Material), false);
            if (mesh.kind == PathMeshKind.Railing) posts = (Material)EditorGUILayout.ObjectField(T("立柱材质（可选）", "Post material (optional)"), posts, typeof(Material), false);
            if (!fence) EditorGUILayout.HelpBox(T("UV0：X横向，Y按距离平铺；UV1：X横向，Y为0到1路径进度（立柱为底到顶）。可直接赋予特效材质。空材质自动创建当前管线默认材质。急弯处宽网格可能相交，请减小宽度或调整曲线。UV1用于特效，烘焙光照前需另做光照UV。", "UV0: X across, Y tiled by distance. UV1: X across, Y normalized path progress (posts: bottom to top). Assign an effect material directly. Empty material creates a default for the active pipeline. Wide meshes can overlap at tight bends. UV1 is for effects; generate separate lightmap UVs before baking."), MessageType.None);
            EditorGUILayout.BeginHorizontal(); folder = EditorGUILayout.TextField(T("网格保存目录", "Mesh asset folder"), folder);
            if (GUILayout.Button(T("使用选择目录", "Use selected folder"), GUILayout.Width(135))) { string p = AssetDatabase.GetAssetPath(Selection.activeObject); if (AssetDatabase.IsValidFolder(p)) folder = p; }
            EditorGUILayout.EndHorizontal();
            var area = GUILayoutUtility.GetLastRect(); var ev = Event.current;
            if (area.Contains(ev.mousePosition) && (ev.type == EventType.DragUpdated || ev.type == EventType.DragPerform))
            { foreach (var item in DragAndDrop.objectReferences) { string p = AssetDatabase.GetAssetPath(item); if (!AssetDatabase.IsValidFolder(p) || !(p == "Assets" || p.StartsWith("Assets/", StringComparison.Ordinal))) continue; DragAndDrop.visualMode = DragAndDropVisualMode.Copy; if (ev.type == EventType.DragPerform) { DragAndDrop.AcceptDrag(); folder = p; } ev.Use(); break; } }
            GenerationNote(); if (GUILayout.Button(T("生成 / 重新生成网格", "Generate / rebuild mesh"), GUILayout.Height(28))) Action(() => PathAuthoring.Generate(path, mesh, MeshMaterial, posts, folder));
        }
        void DrawFenceSettings()
        {
            using (new EditorGUILayout.HorizontalScope())
            {
                EditorGUILayout.PrefixLabel(T("围栏高度方向", "Fence height axis"));
                mesh.fenceAxis = (PathFenceAxis)AxisMenu((int)mesh.fenceAxis);
            }
            mesh.fenceLocalAxis = EditorGUILayout.Toggle(T("使用路径局部轴", "Use path-local axis"), mesh.fenceLocalAxis);
            mesh.fenceHeight = EditorGUILayout.FloatField(T("围栏高度（米）", "Fence height (m)"), mesh.fenceHeight);
            mesh.fenceBaseOffset = EditorGUILayout.FloatField(T("底部偏移（米）", "Base offset (m)"), mesh.fenceBaseOffset);
            fenceMaterial = (Material)EditorGUILayout.ObjectField(T("自定义围栏材质", "Custom fence material"), fenceMaterial, typeof(Material), false);
            using (new EditorGUI.DisabledScope(fenceMaterial == null))
                mesh.fenceDoubleSided = EditorGUILayout.Toggle(T("为单面材质生成背面", "Add back faces for one-sided materials"),
                    fenceMaterial != null && mesh.fenceDoubleSided);
            EditorGUILayout.HelpBox(T("材质留空时使用青色扫描材质。UV0 的 X 沿围栏按米平铺，Y 从底到顶。UV1 的 X 是围栏进度，Y 是高度。",
                "Leave the material empty for the cyan scan effect. UV0 X tiles along the fence and Y runs bottom to top. UV1 X stores path progress and Y stores height."),
                MessageType.None);
        }
        void GenerationNote() { EditorGUILayout.HelpBox(T("预览仅临时显示，点击生成才保存。重新生成会替换此路径对应的生成组；组内手动编辑也会替换。其他场景物体保留。网格另存唯一资源，撤销场景生成后资源仍保留，便于重做。修改路径后需要重新生成。", "Preview is temporary; Generate saves it. Rebuild replaces this path's generated group, including manual edits inside it. Other scene objects are preserved. Meshes use unique assets; scene Undo retains assets for Redo. Rebuild after editing the path."), MessageType.None); }
        void DrawMotion()
        {
            EditorGUI.BeginChangeCheck();
            motionTarget = (GameObject)EditorGUILayout.ObjectField(T("运动物体", "Moving object"), motionTarget, typeof(GameObject), true);
            if (EditorGUI.EndChangeCheck()) PathMotionPreview.Stop();
            using (new EditorGUI.DisabledScope(Selection.activeGameObject == null))
                if (GUILayout.Button(T("使用当前选中的物体", "Use selected object")))
                {
                    PathMotionPreview.Stop();
                    motionTarget = Selection.activeGameObject;
                }
            follower = motionTarget == null ? null : motionTarget.GetComponent<PathFollower>();
            EditorGUILayout.BeginHorizontal();
            using (new EditorGUI.DisabledScope(motionTarget == null || (follower != null && follower.path == path)))
                if (GUILayout.Button(follower == null ? T("绑定当前路径", "Bind current path") : T("改用当前路径", "Use current path")))
                    Action(() => follower = PathAuthoring.Attach(path, motionTarget));
            if (GUILayout.Button(T("创建飞行演示", "Create flight demo"))) Action(() => { follower = PathAuthoring.FlightDemo(path); motionTarget = follower.gameObject; });
            EditorGUILayout.EndHorizontal();
            if (follower == null) EditorGUILayout.HelpBox(T("先选择运动物体并绑定当前路径，再设置朝向、拖动预览进度或制作动画。", "Select the moving object and bind the current path to configure orientation, preview or animation."), MessageType.Info);
            if (follower != null) PathFollowerEditor.DrawFollower(follower);
        }
    }
}
