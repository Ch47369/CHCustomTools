using System;
using System.Linq;
using CH.CustomTools.Measurement;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;

namespace CH.CustomTools.Paths.Editor
{
    [InitializeOnLoad]
    public static class PathSceneTool
    {
        static bool active, dirty = true;
        static bool wholePath, ownsHiddenTools, originalHidden, ownsPivot;
        static int expectedSelection;
        static PivotMode originalPivot;
        public static bool PointEditing => Active && !wholePath;
        internal static bool WholePath
        {
            get => wholePath;
            set
            {
                ChangeMode(value);
                if (value && EditingPath != null) SelectObject(EditingPath.gameObject);
            }
        }
        static void ChangeMode(bool whole)
        {
            if (wholePath != whole)
            {
                PathPointDrag.CancelActive();
                wholePath = whole;
                SceneView.RepaintAll();
            }
            UpdateToolVisibility();
        }
        static void SelectObject(GameObject target)
        {
            if (Selection.activeGameObject != target)
            {
                expectedSelection = target.GetInstanceID();
                Selection.activeGameObject = target;
            }
            UpdateToolVisibility();
        }
        internal static void SelectPoint(BezierPath path, int index)
        {
            SetTarget(path);
            ChangeMode(false);
            PathPointInsertion.Focus(path, index);
            SelectObject(path.gameObject);
        }
        internal static void SelectWhole(BezierPath path)
        {
            if (path == null) return;
            Active = true;
            SetTarget(path);
            WholePath = true;
        }
        internal static void SelectGenerated(GameObject output, BezierPath path)
        {
            if (!Active) { Selection.activeGameObject = output; return; }
            SetTarget(path);
            ChangeMode(true);
            SelectObject(output);
        }
        internal static bool WholePathSelected => Active && wholePath && EditingPath != null &&
            Selection.activeGameObject == EditingPath.gameObject && Selection.gameObjects.Length == 1;
        internal static bool OutputSelected => Active && wholePath && Selection.activeGameObject != null &&
            Selection.activeGameObject.GetComponentInParent<PathGeneratedOutput>() != null;
        static void UpdateToolVisibility()
        {
            bool hideNative = PointEditing || WholePathSelected;
            if (hideNative && !ownsHiddenTools)
            {
                originalHidden = Tools.hidden;
                Tools.hidden = true;
                ownsHiddenTools = true;
            }
            else if (!hideNative && ownsHiddenTools)
            {
                Tools.hidden = originalHidden;
                ownsHiddenTools = false;
            }
            if (Active)
            {
                if (!ownsPivot) { originalPivot = Tools.pivotMode; ownsPivot = true; }
                Tools.pivotMode = PivotMode.Center;
            }
            else if (ownsPivot)
            {
                Tools.pivotMode = originalPivot;
                ownsPivot = false;
            }
        }
        static BezierPath[] paths = new BezierPath[0];
        public static BezierPath EditingPath { get; private set; }
        internal static void SetTarget(BezierPath path)
        {
            if (EditingPath == path) return;
            PathPointDrag.CancelActive(); PathPointInsertion.CancelActive();
            EditingPath = path;
            if (path != null && path.knots != null && path.knots.Count > 0) PathPointInsertion.Focus(path, 0);
            SceneView.RepaintAll();
        }
        public static void Edit(BezierPath path)
        {
            if (path == null || EditorUtility.IsPersistent(path) || !path.gameObject.scene.IsValid()) return;
            Active = true; SetTarget(path);
            SelectPoint(path, Mathf.Max(0, PathPointInsertion.FocusedIndex(path)));
        }
        public static bool Active
        {
            get { return active; }
            set
            {
                value &= !EditorApplication.isPlayingOrWillChangePlaymode;
                if (active == value) return;
                active = value;
                if (value) { DmSceneTool.Active = false; CH.CustomTools.VFX.ParticleTrailSceneTool.Stop(); PathFenceDraft.Cancel(); wholePath = true; SetTarget(PathPointInsertion.SelectionPath()); }
                else { expectedSelection = 0; PathAuthoringPreview.Stop(); SetTarget(null); PathPointDrag.CancelActive(); PathPointInsertion.CancelActive(); }
                UpdateToolVisibility();
                SceneView.RepaintAll();
                foreach (var window in Resources.FindObjectsOfTypeAll<EditorWindow>()) window.Repaint();
            }
        }
        static PathSceneTool()
        {
            EditorApplication.hierarchyChanged += () => { dirty = true; };
            Selection.selectionChanged += () =>
            {
                if (!Active) return;
                int expected = expectedSelection;
                expectedSelection = 0;
                if (expected != 0 && Selection.activeGameObject != null &&
                    Selection.activeGameObject.GetInstanceID() == expected) { UpdateToolVisibility(); return; }
                var path = PathPointInsertion.SelectionPath();
                if (path != null)
                {
                    SetTarget(path);
                    ChangeMode(true);
                }
                else if (Selection.activeGameObject != null && !EditorUtility.IsPersistent(Selection.activeGameObject))
                    ChangeMode(true);
                else UpdateToolVisibility();
            };
            AssemblyReloadEvents.beforeAssemblyReload += () => Active = false;
            EditorApplication.quitting += () => Active = false;
            EditorApplication.playModeStateChanged += state => Active = false;
            EditorSceneManager.activeSceneChangedInEditMode += (a, b) => Active = false;
            EditorSceneManager.sceneClosing += (scene, removing) => Active = false;
        }
        internal static void Draw(SceneView view)
        {
            if (Active && Tools.pivotMode != PivotMode.Center) Tools.pivotMode = PivotMode.Center;
            if (Event.current.type != EventType.Repaint) return;
            if (dirty) { paths = UnityEngine.Object.FindObjectsByType<BezierPath>(FindObjectsSortMode.None); dirty = false; }
            var selected = PathPointInsertion.SelectedPath();
            foreach (var path in paths)
            {
                if (path == null || !path.gameObject.scene.IsValid() || !path.gameObject.scene.isLoaded || EditorUtility.IsPersistent(path)) continue;
                if ((view.camera.cullingMask & (1 << path.gameObject.layer)) == 0 || SceneVisibilityManager.instance.IsHidden(path.gameObject)) continue;
                if (StageUtility.GetStageHandle(path.gameObject) != StageUtility.GetCurrentStageHandle()) continue;
                BezierPathEditor.DrawSceneCurve(path, path == selected, PathSequenceEditor.ColorFor(path));
            }
        }
        internal static void DrawEnable(BezierPath path)
        {
            bool enabled = EditorGUILayout.ToggleLeft(PathText.T("在 Scene 视图中启用路径编辑", "Enable path editing in Scene view"), Active);
            if (enabled != Active)
            {
                if (enabled && path != null) SelectWhole(path); else Active = enabled;
            }
            if (Active && EditingPath == null && path != null) SetTarget(path);
            if (Active)
            {
                EditorGUILayout.LabelField(PathText.T("当前操作", "Editing selection"),
                    PointEditing ? PathText.T("控制点", "Control point") : OutputSelected ?
                        PathText.T("生成物", "Generated object") : PathText.T("整体", "Whole object"));
                if (GUILayout.Button(PathText.T("选择整条路径", "Select whole path"))) SelectWhole(path);
                EditorGUILayout.HelpBox(PathText.T("点击圆点编辑单点，点击曲线选择整体，点击生成的模型或 Mesh 编辑该物体。整体操作轴使用中心位置。",
                    "Click a point to edit it, the curve to select the whole path, or a generated model/mesh to transform that object. Whole-object handles use the center."), MessageType.None);
            }
        }
    }
}
