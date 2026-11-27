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
        static ParticleSystem target;
        static ParticleTrailData path => ParticleTrailStore.Find(target);
        static bool previousToolsHidden, rotating;
        internal static bool Rotating
        {
            get => rotating;
            set { if (rotating == value) return; rotating = value; SceneView.RepaintAll(); }
        }
        static int selected = -1;
        static SceneView dragView;
        static int dragControl;

        internal static ParticleSystem Active => target;
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
            EditorSceneManager.sceneClosing += (scene, _) => { if (target != null && target.gameObject.scene == scene) Stop(); };
            Undo.undoRedoPerformed += () =>
            {
                if (target == null || path == null) Stop();
                else { Selected = Mathf.Min(selected, path.knots.Count - 1); }
            };
            Selection.selectionChanged += () => { if (target != null && Selection.activeGameObject != target.gameObject) Stop(); };
            AssemblyReloadEvents.beforeAssemblyReload += Stop;
            EditorApplication.quitting += Stop;
            EditorApplication.update += () =>
            {
                if (activeTools && (target == null || DmSceneTool.Active || PathSceneTool.Active || PathFenceDraft.Active)) Stop();
            };
        }

        static bool activeTools;
        internal static void Start(ParticleSystem system)
        {
            Stop();
            var data = ParticleTrailStore.GetOrCreate(system);
            DmSceneTool.Active = false;
            PathSceneTool.Active = false;
            PathFenceDraft.Cancel();
            target = system;
            previousToolsHidden = Tools.hidden;
            Tools.hidden = true;
            activeTools = true;
            rotating = false;
            Selected = data.knots.Count - 1;
            Selection.activeGameObject = system.gameObject;
        }

        internal static void Stop()
        {
            if (activeTools)
            {
                Tools.hidden = previousToolsHidden;
                activeTools = false;
            }
            target = null;
            Selected = -1;
        }

        internal static void Change(ParticleSystem system, string label, Action<ParticleTrailData> action)
        {
            ParticleTrailStore.Change(system, label, action);
        }

        static bool Editable(SceneView view)
        {
            if (path == null) return false;
            if (DmSceneTool.Active || PathSceneTool.Active || EditorApplication.isPlayingOrWillChangePlaymode)
            {
                Stop();
                return false;
            }
            return view.camera != null && target.gameObject.scene.isLoaded &&
                !SceneVisibilityManager.instance.IsHidden(target.gameObject) &&
                StageUtility.GetStageHandle(target.gameObject) == StageUtility.GetCurrentStageHandle();
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
            if (plain && (e.keyCode == KeyCode.W || e.keyCode == KeyCode.E))
            {
                if (GUIUtility.hotControl == 0) Rotating = e.keyCode == KeyCode.E;
                e.Use();
                return;
            }
            if ((!delete && !frame) || selected < 0 || selected >= path.knots.Count) return;
            e.Use();
            if (GUIUtility.hotControl != 0) return;
            if (delete)
            {
                Change(target, "Delete trail point", data => data.knots.RemoveAt(selected));
                Selected = Mathf.Min(selected, path.knots.Count - 1);
            }
            else
                view.LookAt(target.transform.TransformPoint(path.knots[selected].position), view.rotation, view.size, view.orthographic);
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
            if (path.knots.Count >= ParticleTrailCurve.MaxPoints)
            {
                view.ShowNotification(new GUIContent(ParticleTrailText.Pick("最多可添加 128 个点。", "The path already has 128 points.")));
                return;
            }
            var root = target.transform;
            var anchor = path.knots.Count == 0 ? root.position : root.TransformPoint(path.knots[path.knots.Count - 1].position);
            var plane = new Plane(view.camera.transform.forward, anchor);
            var ray = HandleUtility.GUIPointToWorldRay(e.mousePosition);
            if (!plane.Raycast(ray, out float distance)) return;
            var local = root.InverseTransformPoint(ray.GetPoint(distance));
            if (!BezierPath.Finite(local)) return;
            Change(target, "Add trail point", data => data.knots.Add(new PathKnot(local)));
            Selected = path.knots.Count - 1;
        }

        static void DrawPoints(SceneView view, Event e)
        {
            var root = target.transform;
            for (int i = 0; i < path.knots.Count; i++)
            {
                Vector3 world = root.TransformPoint(path.knots[i].position);
                if (!BezierPath.Finite(world) || view.camera.WorldToViewportPoint(world).z < view.camera.nearClipPlane) continue;
                bool active = i == selected;
                bool end = i == 0 || i == path.knots.Count - 1;
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
            if (selected >= 0 && selected < path.knots.Count && !e.shift && dragControl == 0)
                DrawSelectedHandles(view, e);
        }

        static void DrawSelectedHandles(SceneView view, Event e)
        {
            var root = target.transform;
            var knot = path.knots[selected];
            Vector3 position = root.TransformPoint(knot.position);
            if (view.camera.WorldToViewportPoint(position).z < view.camera.nearClipPlane) return;
            using (new EditorGUI.DisabledScope(e.alt || e.shift || e.control || e.command))
            {
                if (rotating)
                {
                    var direction = root.TransformVector(path.Handle(selected, true) - knot.position);
                    if (direction.sqrMagnitude < 1e-8f)
                        direction = root.TransformVector(knot.position - path.Handle(selected, false));
                    if (direction.sqrMagnitude < 1e-8f) direction = root.forward;
                    var rotation = Quaternion.LookRotation(direction.normalized, BezierPath.Perpendicular(direction.normalized, root.up));
                    int prior = GUIUtility.hotControl;
                    EditorGUI.BeginChangeCheck();
                    var changed = Handles.RotationHandle(rotation, position);
                    if (prior == 0 && GUIUtility.hotControl != 0) Undo.IncrementCurrentGroup();
                    if (EditorGUI.EndChangeCheck())
                        RotateTangents(changed * Quaternion.Inverse(rotation));
                }
                else
                {
                    int prior = GUIUtility.hotControl;
                    EditorGUI.BeginChangeCheck();
                    var moved = Handles.PositionHandle(position, Tools.pivotRotation == PivotRotation.Local ? root.rotation : Quaternion.identity);
                    if (prior == 0 && GUIUtility.hotControl != 0) Undo.IncrementCurrentGroup();
                    if (EditorGUI.EndChangeCheck()) MovePoint(selected, root.InverseTransformPoint(moved));
                }

                if (selected > 0) DrawTangent(view, false, position);
                if (selected + 1 < path.knots.Count) DrawTangent(view, true, position);
            }
        }

        static void DrawTangent(SceneView view, bool outgoing, Vector3 position)
        {
            var root = target.transform;
            var handle = root.TransformPoint(path.Handle(selected, outgoing));
            var color = outgoing ? DmSkin.Accent : DmSkin.Palette[2];
            if (Event.current.type == EventType.Repaint)
                CHSceneVisuals.FineLine(color, 2, position, handle);
            using (new Handles.DrawingScope(color))
            {
                int prior = GUIUtility.hotControl;
                EditorGUI.BeginChangeCheck();
                var moved = Handles.FreeMoveHandle(handle, HandleUtility.GetHandleSize(handle) * .065f, Vector3.zero, Handles.RectangleHandleCap);
                if (prior == 0 && GUIUtility.hotControl != 0) Undo.IncrementCurrentGroup();
                if (EditorGUI.EndChangeCheck()) MoveTangent(outgoing, root.InverseTransformPoint(moved));
            }
        }

        internal static void MoveTangent(bool outgoing, Vector3 local)
        {
            if (target == null || selected < 0 || selected >= path.knots.Count || !BezierPath.Finite(local)) return;
            Change(target, "Move particle trail tangent", data =>
            {
                data.FreezeTangents(selected);
                var knot = data.knots[selected];
                if (outgoing) knot.outgoing = local - knot.position;
                else knot.incoming = local - knot.position;
            });
        }

        internal static void RotateTangents(Quaternion delta)
        {
            if (target == null || selected < 0 || selected >= path.knots.Count) return;
            var root = target.transform;
            Change(target, "Rotate particle trail tangents", data =>
            {
                data.FreezeTangents(selected);
                var knot = data.knots[selected];
                knot.incoming = root.InverseTransformVector(delta * root.TransformVector(knot.incoming));
                knot.outgoing = root.InverseTransformVector(delta * root.TransformVector(knot.outgoing));
            });
        }

        static void PointCap(int control, Vector3 position, Quaternion rotation, float size, EventType type)
        {
            if (type == EventType.Layout || type == EventType.MouseMove)
                HandleUtility.AddControl(control, HandleUtility.DistanceToCircle(position, size * .5f));
        }

        static void MovePoint(int index, Vector3 local)
        {
            if (BezierPath.Finite(local))
                Change(target, "Move trail point", data => data.knots[index].position = local);
        }

        static void DrawCurve(Camera camera)
        {
            if (path.knots.Count < 2) return;
            var root = target.transform;
            ParticleTrailCurve curve;
            try { curve = new ParticleTrailCurve(path.knots, root.localToWorldMatrix); }
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
