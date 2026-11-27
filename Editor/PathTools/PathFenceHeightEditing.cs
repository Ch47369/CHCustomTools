using System;
using ASEShaderConverter.Editor;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;

namespace CH.CustomTools.Paths.Editor
{
    internal static class PathFenceHeightEditing
    {
        static BezierPath path;
        static PathMeshSettings settings;
        internal static void Configure(BezierPath target, PathMeshSettings mesh) { path = target; settings = mesh; }
        internal static void Clear() { path = null; settings = null; }

        internal static void SetHeight(BezierPath target, PathMeshSettings mesh, int index, float height)
        {
            if (target == null || mesh == null || index < 0 || index >= target.knots.Count ||
                !float.IsFinite(height) || !float.IsFinite(mesh.fenceHeight) || mesh.fenceHeight <= 0) return;
            Undo.RecordObject(target, "Change fence point height");
            target.knots[index].fenceHeightOverride = true;
            target.knots[index].fenceHeightScale = Mathf.Clamp(height, .001f, 100000f) / mesh.fenceHeight;
            PrefabUtility.RecordPrefabInstancePropertyModifications(target);
            EditorUtility.SetDirty(target);
            SceneView.RepaintAll();
        }
        // The height cone shares the vertical axis with the point's position handle.
        // Register it last and give the visible cone's center first pick priority.
        static void HeightCap(int id, Vector3 position, Quaternion rotation, float size, EventType type)
        {
            Handles.ConeHandleCap(id, position, rotation, size, type);
            if (type == EventType.Layout && Event.current != null &&
                Vector2.Distance(HandleUtility.WorldToGUIPoint(position), Event.current.mousePosition) <= 10)
                HandleUtility.AddControl(id, 0);
        }
        internal static void Draw(SceneView view)
        {
            if (path == null || settings == null || !PathSceneTool.PointEditing || PathSceneTool.EditingPath != path ||
                PathPointDrag.IsDragging || PathMotionPreview.BlocksPathEditing || Event.current.alt ||
                Event.current.shift || PathPointInsertion.InsertionModifier(Event.current) || view.camera == null ||
                SceneVisibilityManager.instance.IsHidden(path.gameObject) ||
                SceneVisibilityManager.instance.IsPickingDisabled(path.gameObject) ||
                (view.camera.cullingMask & (1 << path.gameObject.layer)) == 0 ||
                StageUtility.GetStageHandle(path.gameObject) != StageUtility.GetCurrentStageHandle()) return;
            int index = PathPointInsertion.FocusedIndex(path);
            if (index < 0 || index >= path.knots.Count) return;
            try
            {
                var up = PathMeshBuilder.FenceAxis(settings.fenceAxis);
                if (settings.fenceLocalAxis) up = path.transform.TransformDirection(up);
                var bottom = path.transform.TransformPoint(path.knots[index].position) + up * settings.fenceBaseOffset;
                var top = bottom + up * PathMeshBuilder.FenceHeight(settings, path.knots[index]);
                if (view.camera.WorldToViewportPoint(top).z <= view.camera.nearClipPlane) return;
                using (new Handles.DrawingScope(new Color(1, .47f, .067f), Matrix4x4.identity))
                {
                    if (Event.current.type == EventType.Repaint)
                        CHSceneVisuals.FineLine(Handles.color, 2, bottom, top);
                    int prior = GUIUtility.hotControl;
                    EditorGUI.BeginChangeCheck();
                    var moved = Handles.Slider(top, up, HandleUtility.GetHandleSize(top) * .12f, HeightCap, 0);
                    if (prior == 0 && GUIUtility.hotControl != 0) Undo.IncrementCurrentGroup();
                    if (EditorGUI.EndChangeCheck()) SetHeight(path, settings, index, Vector3.Dot(moved - bottom, up));
                }
            }
            catch (ArgumentException) { /* The panel displays invalid mesh settings. */ }
        }
    }
}
