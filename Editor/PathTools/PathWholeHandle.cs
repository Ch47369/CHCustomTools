using System;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;

namespace CH.CustomTools.Paths.Editor
{
    internal static class PathWholeHandle
    {
        static BezierPath gesturePath;
        static Vector3 gestureLocalCenter;
        static readonly int PickHint = "CH.Path.Whole".GetHashCode();

        // The path has no renderer. Find the exact cubic extrema in world space.
        internal static Vector3 Center(BezierPath path)
        {
            path.ValidatePath();
            var bounds = new Bounds(path.transform.TransformPoint(path.knots[0].position), Vector3.zero);
            for (int segment = 0; segment < path.SegmentCount; segment++)
            {
                int end = (segment + 1) % path.knots.Count;
                Vector3 a = path.transform.TransformPoint(path.knots[segment].position);
                Vector3 b = path.transform.TransformPoint(path.Handle(segment, true));
                Vector3 c = path.transform.TransformPoint(path.Handle(end, false));
                Vector3 d = path.transform.TransformPoint(path.knots[end].position);
                bounds.Encapsulate(d);
                for (int axis = 0; axis < 3; axis++)
                {
                    float q = -a[axis] + 3 * b[axis] - 3 * c[axis] + d[axis];
                    float r = 2 * (a[axis] - 2 * b[axis] + c[axis]);
                    float t = b[axis] - a[axis];
                    if (Mathf.Abs(q) < 1e-7f)
                    {
                        if (Mathf.Abs(r) > 1e-7f) Include(path, segment, -t / r, ref bounds);
                        continue;
                    }
                    float discriminant = r * r - 4 * q * t;
                    if (discriminant < 0) continue;
                    float root = Mathf.Sqrt(discriminant);
                    Include(path, segment, (-r - root) / (2 * q), ref bounds);
                    Include(path, segment, (-r + root) / (2 * q), ref bounds);
                }
            }
            return bounds.center;
        }

        static void Include(BezierPath path, int segment, float parameter, ref Bounds bounds)
        {
            if (parameter <= 0 || parameter >= 1) return;
            path.Cubic(segment, parameter, out var position, out _);
            bounds.Encapsulate(position);
        }

        static bool NearPointHandle(BezierPath path, SceneView view, Vector2 mouse)
        {
            if (!PathSceneTool.PointEditing) return false;
            int index = PathPointInsertion.FocusedIndex(path);
            if (index < 0 || index >= path.knots.Count) return false;
            var point = path.transform.TransformPoint(path.knots[index].position);
            if (view.camera.WorldToViewportPoint(point).z <= view.camera.nearClipPlane) return false;
            var screen = HandleUtility.WorldToGUIPoint(point);
            float size = Vector2.Distance(screen, HandleUtility.WorldToGUIPoint(point +
                view.camera.transform.right * HandleUtility.GetHandleSize(point)));
            return Vector2.Distance(screen, mouse) <= size * 1.45f;
        }

        internal static void Draw(SceneView view, BezierPath path)
        {
            if (path == null || PathPointDrag.IsDragging || PathMotionPreview.BlocksPathEditing ||
                Event.current.alt || Event.current.shift || PathPointInsertion.InsertionModifier(Event.current) ||
                view.camera == null || SceneVisibilityManager.instance.IsHidden(path.gameObject) ||
                SceneVisibilityManager.instance.IsPickingDisabled(path.gameObject) ||
                (view.camera.cullingMask & (1 << path.gameObject.layer)) == 0 ||
                StageUtility.GetStageHandle(path.gameObject) != StageUtility.GetCurrentStageHandle()) return;
            var ev = Event.current;
            int pick = GUIUtility.GetControlID(PickHint, FocusType.Passive);
            if (!PathSceneTool.WholePathSelected && !NearPointHandle(path, view, ev.mousePosition) && GUIUtility.hotControl == 0 &&
                (ev.type == EventType.Layout || ev.type == EventType.MouseDown) &&
                PathPointInsertion.TryFind(path, view.camera, ev.mousePosition, out var hit, false))
            {
                if (ev.type == EventType.Layout) HandleUtility.AddControl(pick, hit.screenDistance + 1);
                else if (ev.button == 0 && HandleUtility.nearestControl == pick)
                {
                    PathSceneTool.SelectWhole(path);
                    ev.Use();
                    return;
                }
            }
            if (!PathSceneTool.WholePathSelected) return;
            Vector3 center;
            if (GUIUtility.hotControl == 0) gesturePath = null;
            try { center = gesturePath == path ? path.transform.TransformPoint(gestureLocalCenter) : Center(path); }
            catch (InvalidOperationException) { return; }
            var transform = path.transform;
            var localCenter = transform.InverseTransformPoint(center);
            var rotation = transform.rotation;
            var scale = transform.localScale;
            var position = center;
            int prior = GUIUtility.hotControl;
            EditorGUI.BeginChangeCheck();
            switch (Tools.current)
            {
                case Tool.Rotate:
                    rotation = Handles.RotationHandle(rotation, center);
                    break;
                case Tool.Scale:
                    scale = Handles.ScaleHandle(scale, center, rotation, HandleUtility.GetHandleSize(center));
                    break;
                case Tool.Move:
                case Tool.Transform:
                    position = Handles.PositionHandle(center, Tools.pivotRotation == PivotRotation.Local ? rotation : Quaternion.identity);
                    break;
            }
            if (prior == 0 && GUIUtility.hotControl != 0)
            {
                gesturePath = path;
                gestureLocalCenter = localCenter;
                Undo.IncrementCurrentGroup();
            }
            if (!EditorGUI.EndChangeCheck()) return;
            if (!BezierPath.Finite(position) || !BezierPath.Finite(scale) || Mathf.Abs(scale.x * scale.y * scale.z) < 1e-8f) return;
            Undo.RecordObject(transform, "Transform whole path");
            transform.rotation = rotation;
            transform.localScale = scale;
            transform.position += position - transform.TransformPoint(localCenter);
            PrefabUtility.RecordPrefabInstancePropertyModifications(transform);
            path.Invalidate();
            SceneView.RepaintAll();
        }
    }
}
