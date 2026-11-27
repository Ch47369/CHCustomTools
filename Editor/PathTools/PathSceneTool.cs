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
        static bool wholePath, ownsHiddenTools, originalHidden;
        public static bool PointEditing => Active && !wholePath;
        internal static bool WholePath
        {
            get => wholePath;
            set
            {
                if (wholePath == value) return;
                wholePath = value;
                var path = EditingPath;
                int focused = PathPointInsertion.FocusedIndex(path);
                PathPointDrag.CancelActive();
                PathPointInsertion.CancelActive();
                if (path != null && focused >= 0 && focused < path.knots.Count)
                    PathPointInsertion.Focus(path, focused);
                UpdateToolVisibility();
                if (active && wholePath && EditingPath != null) Selection.activeGameObject = EditingPath.gameObject;
                SceneView.RepaintAll();
            }
        }
        static void UpdateToolVisibility()
        {
            if (PointEditing && !ownsHiddenTools)
            {
                originalHidden = Tools.hidden;
                Tools.hidden = true;
                ownsHiddenTools = true;
            }
            else if (!PointEditing && ownsHiddenTools)
            {
                Tools.hidden = originalHidden;
                ownsHiddenTools = false;
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
            Active = true; WholePath = false; SetTarget(path); Selection.activeGameObject = path.gameObject;
        }
        public static bool Active
        {
            get { return active; }
            set
            {
                value &= !EditorApplication.isPlayingOrWillChangePlaymode;
                if (active == value) return;
                active = value;
                if (value) { DmSceneTool.Active = false; CH.CustomTools.VFX.ParticleTrailSceneTool.Stop(); PathFenceDraft.Cancel(); wholePath = false; SetTarget(PathPointInsertion.SelectionPath()); }
                else { PathAuthoringPreview.Stop(); SetTarget(null); PathPointDrag.CancelActive(); PathPointInsertion.CancelActive(); }
                UpdateToolVisibility();
                SceneView.RepaintAll();
                foreach (var window in Resources.FindObjectsOfTypeAll<EditorWindow>()) window.Repaint();
            }
        }
        static PathSceneTool()
        {
            EditorApplication.hierarchyChanged += () => { dirty = true; };
            Selection.selectionChanged += () => { var path = PathPointInsertion.SelectionPath(); if (Active && path != null) SetTarget(path); };
            AssemblyReloadEvents.beforeAssemblyReload += () => Active = false;
            EditorApplication.quitting += () => Active = false;
            EditorApplication.playModeStateChanged += state => Active = false;
            EditorSceneManager.activeSceneChangedInEditMode += (a, b) => Active = false;
            EditorSceneManager.sceneClosing += (scene, removing) => Active = false;
        }
        internal static void Draw(SceneView view)
        {
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
                if (enabled && path != null) Edit(path); else Active = enabled;
            }
            if (Active && EditingPath == null && path != null) SetTarget(path);
            if (Active)
            {
                int mode = GUILayout.Toolbar(wholePath ? 1 : 0,
                    new[] { PathText.T("编辑控制点", "Edit points"), PathText.T("整体移动 / 旋转", "Transform whole path") });
                WholePath = mode == 1;
            }
        }
    }
}
