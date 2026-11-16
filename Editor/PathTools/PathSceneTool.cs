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
        static BezierPath[] paths = new BezierPath[0];
        public static bool Active
        {
            get { return active; }
            set
            {
                value &= !EditorApplication.isPlayingOrWillChangePlaymode;
                if (active == value) return;
                active = value;
                if (value) DmSceneTool.Active = false;
                else { PathAuthoringPreview.Stop(); PathPointDrag.CancelActive(); PathPointInsertion.CancelActive(); }
                SceneView.RepaintAll();
                foreach (var window in Resources.FindObjectsOfTypeAll<EditorWindow>()) window.Repaint();
            }
        }
        static PathSceneTool()
        {
            EditorApplication.hierarchyChanged += () => { dirty = true; };
            AssemblyReloadEvents.beforeAssemblyReload += () => Active = false;
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
                BezierPathEditor.DrawSceneCurve(path, path == selected);
            }
        }
        internal static void DrawEnable(BezierPath path)
        {
            bool enabled = EditorGUILayout.ToggleLeft(PathText.T("在 Scene 视图中启用路径编辑", "Enable path editing in Scene view"), Active);
            if (enabled != Active)
            {
                Active = enabled;
                if (enabled && path != null) Selection.activeGameObject = path.gameObject;
            }
        }
    }
}
