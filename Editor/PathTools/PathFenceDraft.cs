using System;
using System.Collections.Generic;
using CH.CustomTools.Measurement;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.Rendering;

namespace CH.CustomTools.Paths.Editor
{
    [InitializeOnLoad]
    internal static class PathFenceDraft
    {
        static readonly List<Vector3> points = new List<Vector3>();
        static readonly List<Vector3> tangents = new List<Vector3>();
        static readonly List<Vector3> incoming = new List<Vector3>();
        static readonly List<Vector3> previousHandles = new List<Vector3>();
        static Vector3 previousOutgoing;
        static int dragControl, releaseControl;
        static SceneView releaseView;
        static Vector2 dragStart;
        static readonly int DrawHint = "CH.PathDraft".GetHashCode();
        static Action<BezierPath> completed;
        static SceneView owner;
        static Vector3 normal;
        static float planeOffset;
        static bool rightPending, rightMoved;
        static Vector2 rightDown;

        internal static bool Active => completed != null;

        static PathFenceDraft()
        {
            SceneView.beforeSceneGui += Shortcuts;
            SceneView.duringSceneGui += Draw;
            EditorSceneManager.activeSceneChangedInEditMode += (_, __) => Cancel();
            EditorApplication.playModeStateChanged += _ => Cancel();
            EditorApplication.update += () => { if (Active && owner == null) Cancel(); };
        }

        internal static void Begin(SceneView scene, PathFenceAxis axis, Action<BezierPath> onComplete)
        {
            Cancel();
            CH.CustomTools.VFX.ParticleTrailSceneTool.Stop();
            DmSceneTool.Active = false;
            PathSceneTool.Active = false;
            normal = PathMeshBuilder.FenceAxis(axis);
            owner = scene;
            planeOffset = Vector3.Dot(scene.pivot, normal);
            completed = onComplete;
            scene.Focus();
            scene.Repaint();
        }

        internal static void Cancel()
        {
            if (!Active) return;
            completed = null;
            rightPending = rightMoved = false;
            if (dragControl != 0)
            {
                if (SceneView.currentDrawingSceneView == owner && GUIUtility.hotControl == dragControl) GUIUtility.hotControl = 0;
                else { releaseView = owner; releaseControl = dragControl; }
                dragControl = 0;
            }
            points.Clear();
            tangents.Clear();
            incoming.Clear();
            previousHandles.Clear();
            owner = null;
            SceneView.RepaintAll();
        }

        static void Shortcuts(SceneView view)
        {
            if (!Active || view != owner) return;
            if (PathSceneTool.Active || DmSceneTool.Active)
            {
                Cancel();
                return;
            }
            var input = Event.current;
            if (input.rawType == EventType.MouseDown && input.button == 1 && !input.alt)
            {
                rightPending = true;
                rightMoved = false;
                rightDown = input.mousePosition;
            }
            if (rightPending && input.rawType == EventType.MouseDrag && input.button == 1 &&
                (input.mousePosition - rightDown).sqrMagnitude > 36) rightMoved = true;
            if (rightPending && input.rawType == EventType.MouseUp && input.button == 1)
            {
                bool complete = !rightMoved && !input.alt;
                rightPending = rightMoved = false;
                // Leave the event available to Unity so its navigation control is released.
                if (complete && points.Count >= 2) Finish(view, false);
                else if (complete && points.Count < 2) Cancel();
                return;
            }
            if (input.type != EventType.KeyDown || EditorWindow.focusedWindow != view || EditorGUIUtility.editingTextField) return;
            switch (input.keyCode)
            {
                case KeyCode.Escape:
                    input.Use();
                    Cancel();
                    break;
                case KeyCode.Backspace:
                    input.Use();
                    if (points.Count > 0 && dragControl == 0)
                    {
                        int last = points.Count - 1;
                        if (last > 0) tangents[last - 1] = previousHandles[last];
                        points.RemoveAt(last);
                        tangents.RemoveAt(last);
                        incoming.RemoveAt(last);
                        previousHandles.RemoveAt(last);
                    }
                    view.Repaint();
                    break;
                case KeyCode.KeypadEnter:
                case KeyCode.Return:
                    input.Use();
                    Finish(view, false);
                    break;
            }
        }

        static void Draw(SceneView view)
        {
            if (releaseView == view)
            {
                if (GUIUtility.hotControl == releaseControl) GUIUtility.hotControl = 0;
                releaseView = null; releaseControl = 0;
            }
            if (!Active || view != owner) return;
            var input = Event.current;
            int control = GUIUtility.GetControlID(DrawHint, FocusType.Passive);
            if (input.type == EventType.Layout && !input.alt) HandleUtility.AddDefaultControl(control);
            if (input.type == EventType.MouseMove || input.type == EventType.KeyUp || input.type == EventType.KeyDown)
                view.Repaint();

            using (new Handles.DrawingScope(Color.white, Matrix4x4.identity))
            {
                var ray = HandleUtility.GUIPointToWorldRay(input.mousePosition);
                var plane = new Plane(normal, normal * planeOffset);
                bool hasCursor = plane.Raycast(ray, out var distance);
                Vector3 cursor = hasCursor ? ray.GetPoint(distance) : Vector3.zero;
                if (hasCursor && input.shift && points.Count > 0 && dragControl == 0)
                    cursor = Orthogonal(points[points.Count - 1], cursor);

                if (dragControl != 0 && GUIUtility.hotControl != dragControl)
                    dragControl = 0;
                if (dragControl != 0)
                {
                    if (input.type == EventType.MouseDrag && input.button == 0 && hasCursor)
                    {
                        bool straight = input.control || input.command || (input.mousePosition - dragStart).sqrMagnitude < 16;
                        int last = tangents.Count - 1;
                        tangents[last] = straight ? Vector3.zero : cursor - points[last];
                        incoming[last] = -tangents[last];
                        if (last > 0) tangents[last - 1] = straight && (input.control || input.command) ? Vector3.zero : previousOutgoing;
                        input.Use(); view.Repaint();
                    }
                    if (input.rawType == EventType.MouseUp && input.button == 0)
                    {
                        if (input.control || input.command)
                        {
                            int last = tangents.Count - 1;
                            tangents[last] = incoming[last] = Vector3.zero;
                            if (last > 0) tangents[last - 1] = Vector3.zero;
                        }
                        GUIUtility.hotControl = 0; dragControl = 0; input.Use(); view.Repaint();
                    }
                }
                if (!input.alt && GUIUtility.hotControl == 0 &&
                    input.type == EventType.MouseDown && input.button == 0)
                {
                    if (points.Count >= 3 && (HandleUtility.WorldToGUIPoint(points[0]) - input.mousePosition).sqrMagnitude <= 12 * 12)
                    {
                        input.Use();
                        Finish(view, true);
                        return;
                    }
                    if (points.Count == 0 && DmSceneTool.TrySurface(ray, view.camera.cullingMask, out var hit))
                    {
                        cursor = hit;
                        hasCursor = true;
                        planeOffset = Vector3.Dot(hit, normal);
                    }
                    input.Use();
                    if (!hasCursor)
                    {
                        view.ShowNotification(new GUIContent(PathText.T("请转动视角，让它朝向绘制平面。", "Orbit the view to face the drawing plane.")));
                        return;
                    }
                    if (points.Count >= 512)
                    {
                        view.ShowNotification(new GUIContent(PathText.T("已达到 512 个点，按 Enter 完成。", "The path has 512 points. Press Enter to finish.")));
                        return;
                    }
                    foreach (var point in points)
                        if ((point - cursor).sqrMagnitude < 1e-6f) return;
                    previousOutgoing = tangents.Count == 0 ? Vector3.zero : tangents[tangents.Count - 1];
                    previousHandles.Add(previousOutgoing);
                    points.Add(cursor);
                    tangents.Add(Vector3.zero);
                    incoming.Add(Vector3.zero);
                    dragStart = input.mousePosition;
                    GUIUtility.hotControl = dragControl = control;
                    view.Repaint();
                }
                if (input.type == EventType.Repaint) DrawOverlay(view, hasCursor, cursor);
            }
        }

        static Vector3 Orthogonal(Vector3 start, Vector3 target)
        {
            Vector3 delta = Vector3.ProjectOnPlane(target - start, normal);
            var magnitudes = new Vector3(Mathf.Abs(delta.x), Mathf.Abs(delta.y), Mathf.Abs(delta.z));
            int axis = magnitudes.x >= magnitudes.y && magnitudes.x >= magnitudes.z ? 0 : magnitudes.y >= magnitudes.z ? 1 : 2;
            start[axis] += delta[axis];
            return start;
        }

        static void DrawOverlay(SceneView view, bool hasCursor, Vector3 cursor)
        {
            var original = Handles.zTest;
            var accent = DmSkin.Palette[1];
            try
            {
                Handles.zTest = CompareFunction.Always;
                for (int i = 0; i + 1 < points.Count; i++)
                    CHSceneVisuals.Curve(points[i], points[i] + tangents[i], points[i + 1] + incoming[i + 1], points[i + 1], accent, true);
                for (int i = 0; i < points.Count; i++)
                {
                    var p = points[i];
                    CHSceneVisuals.Anchor(view.camera, p, i == 0 ? DmSkin.Accent : accent,
                        CHSceneVisuals.PixelToWorld(view.camera, p, 4), true, i == 0);
                    if (i == points.Count - 1 && tangents[i].sqrMagnitude > 1e-8f)
                    {
                        CHSceneVisuals.FineLine(DmSkin.Accent, 2, p + incoming[i], p + tangents[i]);
                        CHSceneVisuals.Anchor(view.camera, p + tangents[i], DmSkin.Accent,
                            CHSceneVisuals.PixelToWorld(view.camera, p, 4), true, false);
                    }
                }
                if (points.Count > 0 && hasCursor && dragControl == 0)
                {
                    CHSceneVisuals.Curve(points[points.Count - 1], points[points.Count - 1] + tangents[tangents.Count - 1], cursor, cursor, accent, true);
                    CHSceneVisuals.Anchor(view.camera, cursor, accent, CHSceneVisuals.PixelToWorld(view.camera, cursor, 4), false, false);
                }
            }
            finally { Handles.zTest = original; }
        }

        static void Finish(SceneView view, bool closed)
        {
            Vector3 origin = points.Count == 0 ? Vector3.zero : points[0];
            float doubledArea = 0;
            for (int i = 1; i + 1 < points.Count; i++)
                doubledArea += Vector3.Dot(Vector3.Cross(points[i] - origin, points[i + 1] - origin), normal);
            if (points.Count < (closed ? 3 : 2) || (closed && Mathf.Abs(doubledArea) < 1e-5f))
            {
                view.ShowNotification(new GUIContent(closed ? PathText.T("闭合路径需要至少三个不共线的点。", "A closed path needs at least three non-collinear points.")
                    : PathText.T("开放路径至少需要两个点。", "An open path needs at least two points.")));
                return;
            }
            var callback = completed;
            var boundary = points.ToArray();
            var handles = tangents.ToArray();
            var entering = incoming.ToArray();
            Cancel();
            callback(PathAuthoring.CreateFenceBoundary(boundary, closed, handles, entering));
        }
    }
}
