using System;
using CH.CustomTools.Measurement;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;

namespace CH.CustomTools.Paths.Editor
{
    /// <summary>Direct point dragging and Shift-drag duplication, with one Undo transaction per gesture.</summary>
    [InitializeOnLoad]
    public static class PathPointDrag
    {
        const float Radius = 10;
        static readonly int Hint = "CH.Path.PointDrag".GetHashCode();
        static readonly GUIContent Label = new GUIContent();
        static BezierPath dragging;
        static SceneView owner;
        static SceneView releaseView;
        static int releaseControl;
        static int control, index, undoGroup = -1;
        static bool duplicate, changed;
        static Plane plane;
        static Vector2 mouseStart;
        static Vector3 offset;
        static Vector3 sourcePosition, dragAxis;
        static readonly Vector3[] Axes = { Vector3.right, Vector3.up, Vector3.forward };
        public static bool IsDragging { get { return control != 0; } }
        static PathPointDrag()
        {
            Selection.selectionChanged += () => { if (dragging != null && PathPointInsertion.SelectionPath() != dragging) Cancel(); };
            AssemblyReloadEvents.beforeAssemblyReload += Cancel;
            Undo.undoRedoPerformed += () => { if (control != 0) { var path = dragging; Clear(); if (path != null) path.Invalidate(); } };
            EditorApplication.playModeStateChanged += state => Cancel();
            EditorSceneManager.sceneClosing += (scene, removing) => { if (dragging != null && dragging.gameObject.scene == scene) Cancel(); };
            EditorApplication.update += () => { if (control != 0 && (owner == null || dragging == null)) Cancel(); };
        }
        public static int Duplicate(BezierPath path, int source, Vector3 worldPosition)
        {
            if (path == null || EditorUtility.IsPersistent(path) || Application.isPlaying || PathMotionPreview.BlocksPathEditing)
                throw new InvalidOperationException("Select a scene path and stop motion preview. / 请选择场景路径并停止运动预览。");
            path.ValidatePath();
            if (path.knots.Count >= 512) throw new InvalidOperationException("The path already has 512 points. / 路径已达到512个点。");
            if (source < 0 || source >= path.knots.Count || !BezierPath.Finite(worldPosition)) throw new ArgumentException("Invalid path point. / 路径点无效。");
            var original = path.knots[source];
            Vector3 local = path.transform.InverseTransformPoint(worldPosition);
            if (!BezierPath.Finite(local) || (local - original.position).sqrMagnitude < 1e-12f) throw new ArgumentException("Drag away from the original point. / 请从原点拖开再新增。");
            Undo.IncrementCurrentGroup(); Undo.SetCurrentGroupName("Duplicate and move path point");
            Undo.RegisterCompleteObjectUndo(path, "Duplicate and move path point");
            var knot = new PathKnot(local) { automatic = original.automatic, incoming = original.incoming, outgoing = original.outgoing, roll = original.roll,
                fenceHeightOverride = original.fenceHeightOverride, fenceHeightScale = original.fenceHeightScale };
            int added = !path.closed && source == 0 ? 0 : source + 1;
            path.knots.Insert(added, knot); Changed(path); PathPointInsertion.Focus(path, added);
            return added;
        }
        static void Changed(BezierPath path)
        {
            path.Invalidate(); PrefabUtility.RecordPrefabInstancePropertyModifications(path); EditorUtility.SetDirty(path); SceneView.RepaintAll();
        }
        internal static int FindPoint(BezierPath path, Camera camera, Vector2 mouse)
        {
            float best = Radius * Radius; int result = -1;
            if (path == null || camera == null || path.knots == null) return -1;
            int focused = PathPointInsertion.FocusedIndex(path);
            for (int i = 0; i < path.knots.Count; i++)
            {
                var point = path.transform.TransformPoint(path.knots[i].position);
                if (camera.WorldToViewportPoint(point).z <= camera.nearClipPlane) continue;
                float distance = (HandleUtility.WorldToGUIPoint(point) - mouse).sqrMagnitude;
                if (distance < best || (distance == best && (result < 0 || i == focused)))
                { best = distance; result = i; }
            }
            return result;
        }
        internal static void SceneGUI(SceneView view, BezierPath path, bool inserting)
        {
            Event e = Event.current;
            if (releaseView == view)
            {
                if (GUIUtility.hotControl == releaseControl) GUIUtility.hotControl = 0;
                releaseView = null; releaseControl = 0;
            }
            int id = GUIUtility.GetControlID(Hint, FocusType.Passive);
            if (control != 0)
            {
                if (owner != view) return;
                if (dragging == null || path != dragging || PathPointInsertion.SelectionPath() != dragging || Application.isPlaying || PathMotionPreview.BlocksPathEditing || DmSceneTool.Active || GUIUtility.hotControl != control || e.alt)
                { Cancel(); return; }
                if (e.type == EventType.KeyDown && (e.keyCode == KeyCode.Escape || ((e.control || e.command) && e.keyCode == KeyCode.Z)))
                { Cancel(); e.Use(); return; }
                if (e.type == EventType.MouseDrag && e.button == 0)
                {
                    try { dragging.ValidatePath(); Move(e); }
                    catch (Exception exception) { Cancel(); Debug.LogWarning(exception.Message); }
                    e.Use();
                }
                else if (e.type == EventType.MouseUp && e.button == 0) { Complete(); e.Use(); }
            }
            if (!PathSceneTool.Active || path == null || inserting || Application.isPlaying || PathMotionPreview.BlocksPathEditing || DmSceneTool.Active ||
                view.camera == null || SceneVisibilityManager.instance.IsHidden(path.gameObject) ||
                SceneVisibilityManager.instance.IsPickingDisabled(path.gameObject) ||
                (view.camera.cullingMask & (1 << path.gameObject.layer)) == 0 ||
                StageUtility.GetStageHandle(path.gameObject) != StageUtility.GetCurrentStageHandle()) return;
            try { path.ValidatePath(); } catch (Exception) { return; }
            int hover = FindPoint(path, view.camera, e.mousePosition);
            Vector3 pickedAxis = Vector3.zero;
            bool shiftAxes = e.shift && !e.alt && PathSceneTool.PointEditing;
            if (shiftAxes && hover < 0)
            {
                int focused = PathPointInsertion.FocusedIndex(path);
                if (focused >= 0 && TryPickAxis(view, path, focused, e.mousePosition, out pickedAxis))
                    hover = focused;
            }
            bool canPick = !e.alt && !PathPointInsertion.InsertionModifier(e) && GUIUtility.hotControl == 0;
            if (canPick && hover >= 0 && e.type == EventType.Layout) HandleUtility.AddControl(id, 0);
            if (e.type == EventType.MouseMove || e.type == EventType.KeyDown || e.type == EventType.KeyUp) view.Repaint();
            if (e.type == EventType.Repaint)
            {
                Draw(view, path, hover);
                if ((shiftAxes && !IsDragging) || (dragging == path && duplicate && owner == view))
                    DrawShiftAxes(view, path);
                if (canPick && hover >= 0) EditorGUIUtility.AddCursorRect(new Rect(e.mousePosition - Vector2.one * Radius, Vector2.one * Radius * 2), e.shift ? MouseCursor.ArrowPlus : MouseCursor.MoveArrow);
            }
            // The last Layout can still name the previous gizmo when Shift is first held on MouseDown.
            if (canPick && hover >= 0 && e.type == EventType.MouseDown && e.button == 0 && (e.shift || HandleUtility.nearestControl == id))
            {
                if (e.shift && path.knots.Count >= 512) { Debug.LogWarning(PathText.T("路径已达到512个点。", "The path already has 512 points.")); e.Use(); return; }
                Vector3 point = path.transform.TransformPoint(path.knots[hover].position);
                plane = new Plane(view.camera.transform.forward, point);
                float enter; Ray ray = HandleUtility.GUIPointToWorldRay(e.mousePosition);
                if (!plane.Raycast(ray, out enter)) return;
                PathSceneTool.SelectPoint(path, hover);
                dragging = path; owner = view; index = hover; duplicate = e.shift; changed = false; undoGroup = -1;
                sourcePosition = point; dragAxis = pickedAxis;
                offset = point - ray.GetPoint(enter); mouseStart = e.mousePosition;
                GUIUtility.hotControl = control = id; e.Use();
            }
        }
        static void Move(Event e)
        {
            if (!changed && (e.mousePosition - mouseStart).sqrMagnitude < 16) return;
            Vector3 position;
            if (dragAxis != Vector3.zero)
            {
                float translation = HandleUtility.CalcLineTranslation(mouseStart, e.mousePosition, sourcePosition, dragAxis);
                position = sourcePosition + dragAxis * translation;
            }
            else
            {
                Ray ray = HandleUtility.GUIPointToWorldRay(e.mousePosition);
                if (!plane.Raycast(ray, out float enter)) return;
                position = ray.GetPoint(enter) + offset;
            }
            if (dragAxis == Vector3.zero && BezierPathEditor.SnapToSurface)
            {
                Vector3 surface;
                if (DmSceneTool.TrySurface(new Ray(position + Vector3.up * 1000, Vector3.down), ~0, out surface)) position = surface;
            }
            if (!BezierPath.Finite(position) || (!changed && (position - sourcePosition).sqrMagnitude < 1e-8f)) return;
            if (!changed)
            {
                if (duplicate) { index = Duplicate(dragging, index, position); undoGroup = Undo.GetCurrentGroup(); }
                else
                {
                    Undo.IncrementCurrentGroup(); undoGroup = Undo.GetCurrentGroup(); Undo.SetCurrentGroupName("Move path point");
                    Undo.RegisterCompleteObjectUndo(dragging, "Move path point");
                }
                changed = true;
            }
            Undo.RecordObject(dragging, duplicate ? "Duplicate and move path point" : "Move path point");
            dragging.knots[index].position = dragging.transform.InverseTransformPoint(position); Changed(dragging);
        }
        static void Complete()
        {
            if (changed && duplicate && Vector3.Distance(dragging.transform.TransformPoint(dragging.knots[index].position), sourcePosition) < .001f)
            { Cancel(); return; }
            if (changed) { Undo.FlushUndoRecordObjects(); Undo.CollapseUndoOperations(undoGroup); }
            Clear();
        }
        static void Clear()
        {
            if (control != 0)
            {
                if (SceneView.currentDrawingSceneView == owner && GUIUtility.hotControl == control) GUIUtility.hotControl = 0;
                else { releaseView = owner; releaseControl = control; }
            }
            dragging = null; owner = null; control = 0; undoGroup = -1; changed = false; dragAxis = Vector3.zero; SceneView.RepaintAll();
        }
        internal static void CancelActive() { Cancel(); }
        static void Cancel()
        {
            var path = dragging; int group = undoGroup; bool restore = changed;
            Clear();
            if (restore && path != null) { Undo.FlushUndoRecordObjects(); Undo.RevertAllDownToGroup(group); path.Invalidate(); }
        }
        static Quaternion AxisRotation(BezierPath path)
        {
            return Tools.pivotRotation == PivotRotation.Local ? path.transform.rotation : Quaternion.identity;
        }
        static bool TryPickAxis(SceneView view, BezierPath path, int knot, Vector2 mouse, out Vector3 axis)
        {
            axis = Vector3.zero;
            var position = path.transform.TransformPoint(path.knots[knot].position);
            if (view.camera.WorldToViewportPoint(position).z <= view.camera.nearClipPlane) return false;
            float size = HandleUtility.GetHandleSize(position);
            var start = HandleUtility.WorldToGUIPoint(position);
            float best = 10;
            foreach (var localAxis in Axes)
            {
                Vector3 direction = AxisRotation(path) * localAxis;
                Vector2 delta = HandleUtility.WorldToGUIPoint(position + direction * size) - start;
                if (delta.sqrMagnitude < 144) continue;
                float t = Vector2.Dot(mouse - start, delta) / delta.sqrMagnitude;
                if (t < .2f || t > 1.2f) continue;
                float distance = Vector2.Distance(mouse, start + delta * Mathf.Clamp01(t));
                if (distance < best) { best = distance; axis = direction; }
            }
            return axis != Vector3.zero;
        }
        static void DrawShiftAxes(SceneView view, BezierPath path)
        {
            int knot = PathPointInsertion.FocusedIndex(path);
            if (knot < 0 || knot >= path.knots.Count) return;
            var position = path.transform.TransformPoint(path.knots[knot].position);
            if (view.camera.WorldToViewportPoint(position).z <= view.camera.nearClipPlane) return;
            float size = HandleUtility.GetHandleSize(position);
            var rotation = AxisRotation(path);
            for (int i = 0; i < Axes.Length; i++)
            {
                var axis = rotation * Axes[i];
                Color color = i == 0 ? Handles.xAxisColor : i == 1 ? Handles.yAxisColor : Handles.zAxisColor;
                if (dragAxis != Vector3.zero && Vector3.Dot(dragAxis, axis) > .999f) color = Handles.selectedColor;
                using (new Handles.DrawingScope(color))
                    Handles.ArrowHandleCap(0, position, Quaternion.LookRotation(axis), size, EventType.Repaint);
            }
        }
        static void Draw(SceneView view, BezierPath path, int hover)
        {
            for (int i = 0; i < path.knots.Count; i++)
            {
                Vector3 point = path.transform.TransformPoint(path.knots[i].position);
                if (view.camera.WorldToViewportPoint(point).z <= view.camera.nearClipPlane) continue;
                bool hot = i == hover || (PathSceneTool.PointEditing && PathPointInsertion.IsFocused(path, i));
                Color color = hot ? DmSkin.Accent : DmSkin.Palette[1];
                CHSceneVisuals.Anchor(view.camera, point, color, CHSceneVisuals.PixelToWorld(view.camera, point, hot ? 4.8f : 3.2f), true, hot);
                if (!hot) continue;
                Vector2 screen = HandleUtility.WorldToGUIPoint(point);
                Label.text = PathText.T("点 ", "Point ") + (i + 1) + (i == hover ? PathText.T("  ·  Shift + 拖拽新增", "  ·  Shift + drag to add") : "");
                CHSceneVisuals.Pill(screen + new Vector2(0, -26), Label, color, true, DmSkin.SceneMetaStyle, DmSkin.TextPrimary);
            }
        }
    }
}
