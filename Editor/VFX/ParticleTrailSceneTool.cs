using System;
using CH.CustomTools.Measurement;
using CH.CustomTools.Paths;
using CH.CustomTools.Paths.Editor;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.Rendering;

namespace CH.CustomTools.VFX
{
    [InitializeOnLoad]
    internal static class ParticleTrailSceneTool
    {
        static readonly int PointHint = "CH.ParticleTrail.Point".GetHashCode();
        static ParticleTrailPath path;
        static int selected = -1;
        static SceneView dragView;
        static int dragControl;

        internal static ParticleTrailPath Active => path;
        internal static int Selected
        {
            get => selected;
            set { selected = value; SceneView.RepaintAll(); }
        }

        static ParticleTrailSceneTool()
        {
            SceneView.beforeSceneGui += Commands;
            SceneView.duringSceneGui += Draw;
            EditorApplication.playModeStateChanged += _ => Stop();
            EditorSceneManager.activeSceneChangedInEditMode += (_, __) => Stop();
            EditorSceneManager.sceneClosing += (scene, _) => { if (path != null && path.gameObject.scene == scene) Stop(); };
            Undo.undoRedoPerformed += () => { if (path != null) SceneView.RepaintAll(); };
        }

        internal static void Start(ParticleTrailPath target)
        {
            Stop();
            DmSceneTool.Active = false;
            PathSceneTool.Active = false;
            path = target;
            Selected = target.Points.Count - 1;
            Selection.activeGameObject = target.gameObject;
        }

        internal static void Stop()
        {
            if (path == null) return;
            path = null;
            Selected = -1;
        }

        internal static void Change(ParticleTrailPath target, string label, Action action)
        {
            Undo.RecordObject(target, label);
            action();
            PrefabUtility.RecordPrefabInstancePropertyModifications(target);
            EditorUtility.SetDirty(target);
            SceneView.RepaintAll();
        }

        static bool Editable(SceneView view)
        {
            if (path == null) return false;
            if (DmSceneTool.Active || PathSceneTool.Active || EditorApplication.isPlayingOrWillChangePlaymode)
            {
                Stop();
                return false;
            }
            return view.camera != null && path.gameObject.scene.isLoaded &&
                !SceneVisibilityManager.instance.IsHidden(path.gameObject) &&
                StageUtility.GetStageHandle(path.gameObject) == StageUtility.GetCurrentStageHandle();
        }

        static void Commands(SceneView view)
        {
            var e = Event.current;
            if (e.type != EventType.KeyDown && e.type != EventType.ExecuteCommand) return;
            if (!Editable(view) || EditorWindow.focusedWindow != view || EditorGUIUtility.editingTextField) return;
            bool plain = e.type == EventType.KeyDown && !e.alt && !e.shift && !e.control && !e.command;
            bool command = e.type == EventType.ExecuteCommand;
            bool delete = (plain && e.keyCode == KeyCode.Delete) ||
                (command && (e.commandName == "Delete" || e.commandName == "SoftDelete"));
            bool frame = (plain && e.keyCode == KeyCode.F) || (command && e.commandName == "FrameSelected");
            if ((!delete && !frame) || selected < 0 || selected >= path.Points.Count) return;
            e.Use();
            if (GUIUtility.hotControl != 0) return;
            if (delete)
            {
                Change(path, "Delete trail point", () => path.Points.RemoveAt(selected));
                Selected = Mathf.Min(selected, path.Points.Count - 1);
            }
            else
                view.LookAt(path.transform.TransformPoint(path.Points[selected]), view.rotation, view.size, view.orthographic);
        }

        static void Draw(SceneView view)
        {
            var e = Event.current;
            if (view == dragView && (path == null || GUIUtility.hotControl != dragControl || e.rawType == EventType.MouseUp))
            {
                if (path == null && GUIUtility.hotControl == dragControl) GUIUtility.hotControl = 0;
                dragView = null;
                dragControl = 0;
            }
            if (!Editable(view)) return;
            using (new Handles.DrawingScope(Color.white, Matrix4x4.identity))
            {
                HandleAdd(view, e);
                if (e.type == EventType.Repaint) DrawCurve(view.camera);
                DrawPoints(view, e);
            }
        }

        static void HandleAdd(SceneView view, Event e)
        {
            if (!e.shift || e.alt || e.control || e.command || GUIUtility.hotControl != 0) return;
            if (e.type == EventType.Layout) HandleUtility.AddDefaultControl(GUIUtility.GetControlID(PointHint, FocusType.Passive));
            if (e.type != EventType.MouseDown || e.button != 0) return;
            e.Use();
            if (path.Points.Count >= ParticleTrailCurve.MaxPoints)
            {
                view.ShowNotification(new GUIContent(ParticleTrailText.Pick("最多可添加 128 个点。", "The path already has 128 points.")));
                return;
            }
            var root = path.transform;
            var anchor = path.Points.Count == 0 ? root.position : root.TransformPoint(path.Points[path.Points.Count - 1]);
            var plane = new Plane(view.camera.transform.forward, anchor);
            var ray = HandleUtility.GUIPointToWorldRay(e.mousePosition);
            if (!plane.Raycast(ray, out float distance)) return;
            var local = root.InverseTransformPoint(ray.GetPoint(distance));
            if (!BezierPath.Finite(local)) return;
            Change(path, "Add trail point", () => path.Points.Add(local));
            Selected = path.Points.Count - 1;
        }

        static void DrawPoints(SceneView view, Event e)
        {
            var root = path.transform;
            for (int i = 0; i < path.Points.Count; i++)
            {
                Vector3 world = root.TransformPoint(path.Points[i]);
                if (!BezierPath.Finite(world) || view.camera.WorldToViewportPoint(world).z < view.camera.nearClipPlane) continue;
                bool active = i == selected;
                bool end = i == 0 || i == path.Points.Count - 1;
                Color color = active ? DmSkin.Accent : end ? DmSkin.Palette[2] : DmSkin.Palette[1];
                float size = CHSceneVisuals.PixelToWorld(view.camera, world, active ? 6 : 5);
                int id = GUIUtility.GetControlID(PointHint + i, FocusType.Passive);
                if (e.type == EventType.MouseDown && e.button == 0 && !e.alt && !e.shift &&
                    GUIUtility.hotControl == 0 && HandleUtility.nearestControl == id)
                    Selected = i;
                if (e.type == EventType.Repaint)
                {
                    CHSceneVisuals.Anchor(view.camera, world, color, size, true, active);
                    if (end)
                    {
                        string label = i == 0 ? ParticleTrailText.Pick("起点", "Start") : ParticleTrailText.Pick("终点", "End");
                        CHSceneVisuals.Pill(HandleUtility.WorldToGUIPoint(world) + Vector2.up * 24,
                            new GUIContent(label), color, active, DmSkin.SceneMetaStyle, DmSkin.TextPrimary);
                    }
                }
                using (new EditorGUI.DisabledScope(e.alt || e.shift || e.control || e.command))
                {
                    int previous = GUIUtility.hotControl;
                    EditorGUI.BeginChangeCheck();
                    var moved = Handles.FreeMoveHandle(id, world, size * 2, Vector3.zero, PointCap);
                    if (previous == 0 && GUIUtility.hotControl == id)
                    {
                        Undo.IncrementCurrentGroup();
                        dragControl = id;
                        dragView = view;
                    }
                    if (EditorGUI.EndChangeCheck())
                        MovePoint(i, root.InverseTransformPoint(moved));
                }
            }
            if (selected >= 0 && selected < path.Points.Count && !e.shift && dragControl == 0)
            {
                Vector3 position = root.TransformPoint(path.Points[selected]);
                EditorGUI.BeginChangeCheck();
                var moved = Handles.PositionHandle(position, Tools.pivotRotation == PivotRotation.Local ? root.rotation : Quaternion.identity);
                if (EditorGUI.EndChangeCheck()) MovePoint(selected, root.InverseTransformPoint(moved));
            }
        }

        static void PointCap(int control, Vector3 position, Quaternion rotation, float size, EventType type)
        {
            if (type == EventType.Layout || type == EventType.MouseMove)
                HandleUtility.AddControl(control, HandleUtility.DistanceToCircle(position, size * .5f));
        }

        static void MovePoint(int index, Vector3 local)
        {
            if (BezierPath.Finite(local))
                Change(path, "Move trail point", () => path.Points[index] = local);
        }

        static void DrawCurve(Camera camera)
        {
            if (path.Points.Count < 2) return;
            var root = path.transform;
            ParticleTrailCurve curve;
            try { curve = new ParticleTrailCurve(path.Points, root.localToWorldMatrix); }
            catch (ArgumentException) { return; }

            var color = DmSkin.Palette[1];
            var line = new Vector3[129];
            for (int i = 0; i < line.Length; i++)
                line[i] = root.TransformPoint(curve.Evaluate(i / (float)(line.Length - 1)));
            var previous = Handles.zTest;
            try
            {
                Handles.zTest = CompareFunction.Always;
                CHSceneVisuals.Line(color, true, line);
                for (int i = 1; i <= 3; i++)
                {
                    int idx = i * 32;
                    Vector3 direction = (line[idx + 1] - line[idx - 1]).normalized;
                    Vector3 side = Vector3.Cross(camera.transform.forward, direction).normalized;
                    float scale = CHSceneVisuals.PixelToWorld(camera, line[idx], 12);
                    var tail = line[idx] - direction * scale;
                    CHSceneVisuals.FineLine(color, 2f, tail + side * scale * .55f, line[idx], tail - side * scale * .55f);
                }
            }
            finally { Handles.zTest = previous; }
        }
    }
}
