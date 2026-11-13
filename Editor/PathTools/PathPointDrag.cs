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
        static Vector3 sourcePosition;
        public static bool IsDragging { get { return control != 0; } }
        static PathPointDrag()
        {
            Selection.selectionChanged += () => { if (dragging != null && PathPointInsertion.SelectedPath() != dragging) Cancel(); };
            AssemblyReloadEvents.beforeAssemblyReload += Cancel;
            Undo.undoRedoPerformed += () => { if (control != 0) { var path = dragging; Clear(); if (path != null) path.Invalidate(); } };
            EditorApplication.playModeStateChanged += state => Cancel();
            EditorSceneManager.sceneClosing += (scene, removing) => { if (dragging != null && dragging.gameObject.scene == scene) Cancel(); };
            EditorApplication.update += () => { if (control != 0 && (owner == null || dragging == null)) Cancel(); };
        }
        public static int Duplicate(BezierPath path, int source, Vector3 worldPosition)
        {
            if (path == null || EditorUtility.IsPersistent(path) || Application.isPlaying || PathMotionPreview.IsActive)
                throw new InvalidOperationException("Select a scene path and stop motion preview. / 请选择场景路径并停止运动预览。");
            path.ValidatePath();
            if (path.knots.Count >= 512) throw new InvalidOperationException("The path already has 512 points. / 路径已达到512个点。");
            if (source < 0 || source >= path.knots.Count || !BezierPath.Finite(worldPosition)) throw new ArgumentException("Invalid path point. / 路径点无效。");
            var original = path.knots[source];
            Vector3 local = path.transform.InverseTransformPoint(worldPosition);
            if (!BezierPath.Finite(local) || (local - original.position).sqrMagnitude < 1e-12f) throw new ArgumentException("Drag away from the original point. / 请从原点拖开再新增。");
            Undo.IncrementCurrentGroup(); Undo.SetCurrentGroupName("Duplicate and move path point");
            Undo.RegisterCompleteObjectUndo(path, "Duplicate and move path point");
            var knot = new PathKnot(local) { automatic = original.automatic, incoming = original.incoming, outgoing = original.outgoing, roll = original.roll };
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
            for (int i = 0; i < path.knots.Count; i++)
            {
                var point = path.transform.TransformPoint(path.knots[i].position);
                if (camera.WorldToViewportPoint(point).z <= camera.nearClipPlane) continue;
                float distance = (HandleUtility.WorldToGUIPoint(point) - mouse).sqrMagnitude;
                if (distance <= best) { best = distance; result = i; }
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
                if (dragging == null || path != dragging || Application.isPlaying || PathMotionPreview.IsActive || DmSceneTool.Active || GUIUtility.hotControl != control || e.alt)
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
            if (path == null || inserting || Application.isPlaying || PathMotionPreview.IsActive || DmSceneTool.Active) return;
            try { path.ValidatePath(); } catch (Exception) { return; }
            int hover = FindPoint(path, view.camera, e.mousePosition);
            bool canPick = !e.alt && !PathPointInsertion.InsertionModifier(e) && GUIUtility.hotControl == 0;
            if (canPick && hover >= 0 && e.type == EventType.Layout) HandleUtility.AddControl(id, 0);
            if (e.type == EventType.MouseMove || e.type == EventType.KeyDown || e.type == EventType.KeyUp) view.Repaint();
            if (e.type == EventType.Repaint)
            {
                Draw(view, path, hover);
                if (canPick && hover >= 0) EditorGUIUtility.AddCursorRect(new Rect(e.mousePosition - Vector2.one * Radius, Vector2.one * Radius * 2), e.shift ? MouseCursor.ArrowPlus : MouseCursor.MoveArrow);
            }
            if (canPick && hover >= 0 && e.type == EventType.MouseDown && e.button == 0 && HandleUtility.nearestControl == id)
            {
                if (e.shift && path.knots.Count >= 512) { Debug.LogWarning(PathText.T("路径已达到512个点。", "The path already has 512 points.")); e.Use(); return; }
                Vector3 point = path.transform.TransformPoint(path.knots[hover].position);
                plane = new Plane(view.camera.transform.forward, point);
                float enter; Ray ray = HandleUtility.GUIPointToWorldRay(e.mousePosition);
                if (!plane.Raycast(ray, out enter)) return;
                dragging = path; owner = view; index = hover; duplicate = e.shift; changed = false; undoGroup = -1;
                sourcePosition = point;
                offset = point - ray.GetPoint(enter); mouseStart = e.mousePosition;
                PathPointInsertion.Focus(path, hover); Selection.activeGameObject = path.gameObject;
                GUIUtility.hotControl = control = id; e.Use();
            }
        }
        static void Move(Event e)
        {
            if (!changed && (e.mousePosition - mouseStart).sqrMagnitude < 16) return;
            float enter; Ray ray = HandleUtility.GUIPointToWorldRay(e.mousePosition);
            if (!plane.Raycast(ray, out enter)) return;
            Vector3 position = ray.GetPoint(enter) + offset;
            if (BezierPathEditor.SnapToSurface)
            {
                Vector3 surface;
                if (DmSceneTool.TrySurface(new Ray(position + Vector3.up * 1000, Vector3.down), ~0, out surface)) position = surface;
            }
            if (!BezierPath.Finite(position)) return;
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
            dragging = null; owner = null; control = 0; undoGroup = -1; changed = false; SceneView.RepaintAll();
        }
        static void Cancel()
        {
            var path = dragging; int group = undoGroup; bool restore = changed;
            Clear();
            if (restore && path != null) { Undo.FlushUndoRecordObjects(); Undo.RevertAllDownToGroup(group); path.Invalidate(); }
        }
        static void Draw(SceneView view, BezierPath path, int hover)
        {
            for (int i = 0; i < path.knots.Count; i++)
            {
                Vector3 point = path.transform.TransformPoint(path.knots[i].position);
                if (view.camera.WorldToViewportPoint(point).z <= view.camera.nearClipPlane) continue;
                bool hot = i == hover || PathPointInsertion.IsFocused(path, i);
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
