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
            points.Clear();
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
                    if (points.Count > 0) points.RemoveAt(points.Count - 1);
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
            if (!Active || view != owner) return;
            var input = Event.current;
            if (input.type == EventType.Layout && !input.alt)
                HandleUtility.AddDefaultControl(GUIUtility.GetControlID("CH.FenceDraft".GetHashCode(), FocusType.Passive));
            if (input.type == EventType.MouseMove || input.type == EventType.KeyUp || input.type == EventType.KeyDown)
                view.Repaint();

            using (new Handles.DrawingScope(Color.white, Matrix4x4.identity))
            {
                var ray = HandleUtility.GUIPointToWorldRay(input.mousePosition);
                var plane = new Plane(normal, normal * planeOffset);
                bool hasCursor = plane.Raycast(ray, out var distance);
                Vector3 cursor = hasCursor ? ray.GetPoint(distance) : Vector3.zero;
                if (hasCursor && input.shift && points.Count > 0)
                    cursor = Orthogonal(points[points.Count - 1], cursor);

                if (!input.alt && !input.control && !input.command && GUIUtility.hotControl == 0 &&
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
                    points.Add(cursor);
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
                if (points.Count > 1) CHSceneVisuals.Line(accent, true, points.ToArray());
                for (int i = 0; i < points.Count; i++)
                {
                    var p = points[i];
                    CHSceneVisuals.Anchor(view.camera, p, i == 0 ? DmSkin.Accent : accent,
                        CHSceneVisuals.PixelToWorld(view.camera, p, 4), true, i == 0);
                }
                if (points.Count > 0 && hasCursor)
                {
                    CHSceneVisuals.FineLine(accent, 2, points[points.Count - 1], cursor);
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
                view.ShowNotification(new GUIContent(closed ? PathText.T("闭合围栏需要至少三个不共线的点。", "A closed fence needs at least three non-collinear points.")
                    : PathText.T("开放围栏至少需要两个点。", "An open fence needs at least two points.")));
                return;
            }
            var callback = completed;
            var boundary = points.ToArray();
            Cancel();
            callback(PathAuthoring.CreateFenceBoundary(boundary, closed));
        }
    }
}
