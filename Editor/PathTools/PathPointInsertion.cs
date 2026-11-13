using System;
using UnityEditor;
using UnityEngine;

namespace CH.CustomTools.Paths.Editor
{
    /// <summary>Scene picking and exact cubic subdivision. Changes only the selected path.</summary>
    [InitializeOnLoad]
    public static class PathPointInsertion
    {
        public struct Hit
        {
            public int segment;
            public float parameter, screenDistance;
            public Vector3 position;
        }
        const float PickRadius = 12;
        static readonly int Hint = "CH.Path.InsertPoint".GetHashCode();
        static int capturedControl;
        static SceneView capturedView;
        static BezierPath focusedPath;
        static int focusedIndex = -1;
        static PathPointInsertion()
        {
            SceneView.duringSceneGui += SceneGUI;
            Undo.undoRedoPerformed += ClearFocus;
            Selection.selectionChanged += SceneView.RepaintAll;
        }
        static void ClearFocus() { focusedPath = null; focusedIndex = -1; SceneView.RepaintAll(); }
        internal static void Focus(BezierPath path, int index) { focusedPath = path; focusedIndex = index; SceneView.RepaintAll(); }
        internal static bool IsFocused(BezierPath path, int index) { return path == focusedPath && index == focusedIndex; }
        public static bool InsertionModifier(Event e) { return e != null && (e.control || e.command) && !e.alt; }
        public static BezierPath SelectedPath()
        {
            var selected = Selection.activeGameObject;
            if (selected == null || EditorUtility.IsPersistent(selected)) return null;
            var path = selected.GetComponentInParent<BezierPath>();
            if (path != null) return path;
            var output = selected.GetComponentInParent<PathGeneratedOutput>();
            return output == null ? null : output.owner;
        }
        public static int Insert(BezierPath path, int segment, float parameter)
        {
            if (path == null || EditorUtility.IsPersistent(path) || Application.isPlaying || PathMotionPreview.IsActive) throw new InvalidOperationException("Stop motion preview and select a scene path. / 请停止运动预览并选择场景路径。");
            path.ValidatePath();
            if (path.knots.Count >= 512) throw new InvalidOperationException("The path already has 512 points. / 路径已达到512个点。");
            if (segment < 0 || segment >= path.SegmentCount || float.IsNaN(parameter) || parameter <= .0001f || parameter >= .9999f) throw new ArgumentException("Choose a position inside a curve segment. / 请在线段内部选择插入位置。");
            int end = (segment + 1) % path.knots.Count;
            var startKnot = path.knots[segment]; var endKnot = path.knots[end];
            Vector3 a = startKnot.position, b = path.Handle(segment, true), c = path.Handle(end, false), d = endKnot.position;
            // Preserve both sides of automatic neighbours: their opposite segments must not move.
            Vector3 incoming = path.Handle(segment, false) - a, outgoing = path.Handle(end, true) - d;
            Vector3 ab = Vector3.Lerp(a, b, parameter), bc = Vector3.Lerp(b, c, parameter), cd = Vector3.Lerp(c, d, parameter);
            Vector3 abc = Vector3.Lerp(ab, bc, parameter), bcd = Vector3.Lerp(bc, cd, parameter), point = Vector3.Lerp(abc, bcd, parameter);
            var knot = new PathKnot(point) { automatic = false, incoming = abc - point, outgoing = bcd - point, roll = Mathf.LerpAngle(startKnot.roll, endKnot.roll, parameter) };
            Undo.IncrementCurrentGroup(); Undo.SetCurrentGroupName("Insert path point"); Undo.RecordObject(path, "Insert path point");
            startKnot.automatic = false; startKnot.incoming = incoming; startKnot.outgoing = ab - a;
            endKnot.automatic = false; endKnot.incoming = cd - d; endKnot.outgoing = outgoing;
            int index = segment + 1; path.knots.Insert(index, knot); path.Invalidate();
            PrefabUtility.RecordPrefabInstancePropertyModifications(path); EditorUtility.SetDirty(path);
            focusedPath = path; focusedIndex = index; SceneView.RepaintAll(); return index;
        }
        static bool Project(Camera camera, Vector3 world, out Vector2 screen)
        {
            screen = Vector2.zero;
            if (camera == null || !BezierPath.Finite(world) || camera.WorldToViewportPoint(world).z <= camera.nearClipPlane) return false;
            screen = HandleUtility.WorldToGUIPoint(world);
            return BezierPath.Finite(new Vector3(screen.x, screen.y, 0));
        }
        static float DistanceSquared(BezierPath path, Camera camera, Vector2 mouse, int segment, float parameter)
        {
            Vector3 point, tangent; Vector2 screen; path.Cubic(segment, parameter, out point, out tangent);
            return Project(camera, point, out screen) ? (screen - mouse).sqrMagnitude : float.PositiveInfinity;
        }
        public static bool TryFind(BezierPath path, Camera camera, Vector2 mouse, out Hit hit)
        {
            hit = default(Hit);
            if (path == null || camera == null || path.knots == null || path.knots.Count >= 512) return false;
            try { path.ValidatePath(); } catch (Exception) { return false; }
            // Do not insert duplicates on an existing point, including the closed seam.
            foreach (var knot in path.knots)
            { Vector2 screen; if (Project(camera, path.transform.TransformPoint(knot.position), out screen) && Vector2.Distance(screen, mouse) <= PickRadius) return false; }
            float best = PickRadius * PickRadius; bool found = false;
            const int divisions = 64;
            for (int s = 0; s < path.SegmentCount; s++)
            {
                Vector3 previous, tangent; Vector2 a; path.Cubic(s, 0, out previous, out tangent); bool visible = Project(camera, previous, out a);
                for (int i = 1; i <= divisions; i++)
                {
                    Vector3 current; Vector2 b; path.Cubic(s, i / (float)divisions, out current, out tangent); bool nextVisible = Project(camera, current, out b);
                    if (visible && nextVisible)
                    {
                        Vector2 delta = b - a; float along = delta.sqrMagnitude < 1e-8f ? 0 : Mathf.Clamp01(Vector2.Dot(mouse - a, delta) / delta.sqrMagnitude);
                        if ((a + delta * along - mouse).sqrMagnitude <= best + 1)
                        {
                            float lo = (i - 1) / (float)divisions, hi = i / (float)divisions;
                            for (int iteration = 0; iteration < 16; iteration++)
                            {
                                float l = Mathf.Lerp(lo, hi, 1f / 3), r = Mathf.Lerp(lo, hi, 2f / 3);
                                if (DistanceSquared(path, camera, mouse, s, l) < DistanceSquared(path, camera, mouse, s, r)) hi = r; else lo = l;
                            }
                            float t = (lo + hi) * .5f, distance = DistanceSquared(path, camera, mouse, s, t);
                            if (distance < best && t > .0001f && t < .9999f)
                            { path.Cubic(s, t, out current, out tangent); hit = new Hit { segment = s, parameter = t, position = current, screenDistance = Mathf.Sqrt(distance) }; best = distance; found = true; }
                        }
                    }
                    previous = current; a = b; visible = nextVisible;
                }
            }
            return found;
        }
        static void SceneGUI(SceneView view)
        {
            using (new Handles.DrawingScope(Handles.color, Matrix4x4.identity))
            {
                HandleInsertion(view);
                var path = SelectedPath();
                PathPointDrag.SceneGUI(view, path, capturedControl != 0);
                if (path != null && capturedControl == 0 && !Measurement.DmSceneTool.Active && (!InsertionModifier(Event.current) || GUIUtility.hotControl != 0)) BezierPathEditor.DrawSceneHandles(path);
            }
        }
        static void HandleInsertion(SceneView view)
        {
            var e = Event.current;
            int control = GUIUtility.GetControlID(Hint, FocusType.Passive);
            if (capturedControl != 0)
            {
                if (capturedView != view) return;
                if (GUIUtility.hotControl != capturedControl) capturedControl = 0;
                else if ((e.type == EventType.MouseUp && e.button == 0) || (e.type == EventType.KeyDown && e.keyCode == KeyCode.Escape))
                { GUIUtility.hotControl = 0; capturedControl = 0; e.Use(); return; }
                else { if (e.type == EventType.MouseDrag) e.Use(); return; }
            }
            if (e.type == EventType.KeyUp && (e.keyCode == KeyCode.LeftControl || e.keyCode == KeyCode.RightControl || e.keyCode == KeyCode.LeftCommand || e.keyCode == KeyCode.RightCommand)) view.Repaint();
            if (!InsertionModifier(e) || Application.isPlaying || PathMotionPreview.IsActive || Measurement.DmSceneTool.Active || GUIUtility.hotControl != 0) return;
            var path = SelectedPath(); if (path == null) return;
            Hit hit; bool found = TryFind(path, view.camera, e.mousePosition, out hit);
            if (e.type == EventType.MouseMove || e.type == EventType.KeyDown) view.Repaint();
            if (!found) return;
            if (e.type == EventType.Layout) HandleUtility.AddControl(control, hit.screenDistance);
            if (e.type == EventType.Repaint)
            {
                using (new Handles.DrawingScope(Color.green))
                {
                    float size = HandleUtility.GetHandleSize(hit.position) * .075f;
                    Handles.SphereHandleCap(0, hit.position, Quaternion.identity, size, EventType.Repaint);
                    Handles.Label(hit.position + view.camera.transform.up * size * 1.5f, PathText.T("Ctrl + 点击：插入路径点", "Ctrl + click: insert point"));
                }
                EditorGUIUtility.AddCursorRect(new Rect(e.mousePosition - Vector2.one * 12, Vector2.one * 24), MouseCursor.ArrowPlus);
            }
            if (e.type == EventType.MouseDown && e.button == 0 && !e.shift && HandleUtility.nearestControl == control)
            {
                try
                {
                    Insert(path, hit.segment, hit.parameter); Selection.activeGameObject = path.gameObject;
                    capturedView = view;
                    GUIUtility.hotControl = capturedControl = control; e.Use();
                }
                catch (Exception exception) { Debug.LogWarning(exception.Message); }
            }
        }
    }
}
