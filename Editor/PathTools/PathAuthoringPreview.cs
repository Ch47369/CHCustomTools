using System;
using System.Collections.Generic;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.Rendering;
using Object = UnityEngine.Object;

namespace CH.CustomTools.Paths.Editor
{
    // Draw only into Scene cameras. No prefab instances, scripts, colliders or asset writes.
    [InitializeOnLoad]
    public static class PathAuthoringPreview
    {
        struct Draw { public Mesh mesh; public Matrix4x4 matrix; public Material material; public int submesh, layer; }
        static readonly List<Draw> models = new List<Draw>(), surface = new List<Draw>();
        static readonly List<Mesh> baked = new List<Mesh>();
        static readonly Dictionary<Renderer, bool> hidden = new Dictionary<Renderer, bool>();
        static BezierPath path;
        static GameObject source;
        static PathPlacementSettings placement;
        static PathMeshSettings settings;
        static Material material, posts, fallback;
        static Mesh mesh;
        static bool showModels, showMesh;
        static string signature, modelError, meshError;
        static int revision;
        static double next;
        public static bool IsActive { get { return path != null; } }
        public static string Status { get { return string.Join("\n", new[] { modelError, meshError }).Trim(); } }
        public static int ModelDrawCount { get { return models.Count; } }
        public static Mesh PreviewMesh { get { return mesh; } }
        static PathAuthoringPreview()
        {
            EditorApplication.update += Tick;
            Camera.onPreCull += BeforeCamera; Camera.onPostRender += AfterCamera;
            RenderPipelineManager.beginCameraRendering += BeginCamera; RenderPipelineManager.endCameraRendering += EndCamera;
            AssemblyReloadEvents.beforeAssemblyReload += Stop; EditorApplication.quitting += Stop;
            EditorApplication.playModeStateChanged += _ => Stop();
            EditorSceneManager.sceneClosing += (_, __) => Stop();
            EditorSceneManager.activeSceneChangedInEditMode += (_, __) => Stop();
            Undo.undoRedoPerformed += Invalidate; EditorApplication.projectChanged += Invalidate;
        }
        static void Invalidate() { revision++; next = 0; }
        public static void Configure(BezierPath target, GameObject model, PathPlacementSettings modelSettings, PathMeshSettings meshSettings, Material main, Material post, bool previewModels, bool previewMesh)
        {
            if ((!previewModels && !previewMesh) || target == null || EditorUtility.IsPersistent(target) || EditorApplication.isPlayingOrWillChangePlaymode || !PathSceneTool.Active || PathMotionPreview.IsActive) { Stop(); return; }
            path = target; source = model; placement = modelSettings; settings = meshSettings; material = main; posts = post;
            showModels = previewModels; showMesh = previewMesh;
        }
        static void Tick()
        {
            if (path == null) { if (signature != null || fallback != null) Stop(); return; }
            if (!PathSceneTool.Active || EditorApplication.isPlayingOrWillChangePlaymode || PathMotionPreview.IsActive || !path.gameObject.scene.isLoaded) { Stop(); return; }
            if (EditorApplication.timeSinceStartup < next) return;
            next = EditorApplication.timeSinceStartup + 1.0 / 20;
            string key = path.GetInstanceID() + EditorJsonUtility.ToJson(path) + path.transform.localToWorldMatrix.ToString("R") + JsonUtility.ToJson(placement) + JsonUtility.ToJson(settings)
                + showModels + showMesh + (material == null ? 0 : material.GetInstanceID()) + ":" + (posts == null ? 0 : posts.GetInstanceID()) + ":" + revision;
            if (source != null)
            {
                key += source.GetInstanceID() + source.transform.localScale.ToString("R");
                foreach (var renderer in source.GetComponentsInChildren<Renderer>(true))
                {
                    key += renderer.GetInstanceID() + renderer.localToWorldMatrix.ToString("R") + renderer.enabled + renderer.gameObject.activeInHierarchy;
                    var filter = renderer.GetComponent<MeshFilter>(); var skinned = renderer as SkinnedMeshRenderer;
                    key += filter != null && filter.sharedMesh != null ? filter.sharedMesh.GetInstanceID() : skinned != null && skinned.sharedMesh != null ? skinned.sharedMesh.GetInstanceID() : 0;
                    foreach (var mat in renderer.sharedMaterials) key += ":" + (mat == null ? 0 : mat.GetInstanceID());
                }
            }
            if (signature == key) return;
            signature = key; ClearGeometry(); modelError = meshError = null;
            if (showModels && source != null) try { BuildModels(); } catch (Exception e) { ClearModels(); modelError = e.Message; }
            if (showMesh) try
            {
                mesh = PathMeshBuilder.Build(path, settings); mesh.hideFlags = HideFlags.HideAndDontSave;
                for (int i = 0; i < mesh.subMeshCount; i++) surface.Add(new Draw { mesh = mesh, matrix = Matrix4x4.identity, material = i == 1 && posts != null ? posts : material != null ? material : Default(), submesh = i, layer = path.gameObject.layer });
            }
            catch (Exception e) { if (mesh != null) Object.DestroyImmediate(mesh); mesh = null; surface.Clear(); meshError = e.Message; }
            SceneView.RepaintAll();
        }
        static Material Default() { if (fallback == null) { fallback = PathAuthoring.DefaultMaterial(); fallback.hideFlags = HideFlags.HideAndDontSave; } return fallback; }
        static void BuildModels()
        {
            if (placement == null || source.GetComponentInChildren<BezierPath>(true) != null || source.GetComponentInChildren<PathGeneratedOutput>(true) != null) throw new ArgumentException(PathText.T("预览请选择模型或预制体。", "Choose a model or prefab for preview."));
            if (!BezierPath.Finite(placement.offset) || !BezierPath.Finite(placement.rotation) || !BezierPath.Finite(placement.scale) || placement.scale.x <= 0 || placement.scale.y <= 0 || placement.scale.z <= 0) throw new ArgumentException(PathText.T("模型偏移或缩放无效。", "Invalid model offset or scale."));
            var parts = new List<Draw>();
            foreach (var renderer in source.GetComponentsInChildren<Renderer>(true))
            {
                if (!renderer.enabled || !renderer.gameObject.activeSelf) continue;
                bool active = true; for (var t = renderer.transform.parent; t != null && t != source.transform.parent; t = t.parent) if (!t.gameObject.activeSelf) active = false;
                if (!active) continue;
                Mesh part = null; var filter = renderer.GetComponent<MeshFilter>(); var skinned = renderer as SkinnedMeshRenderer;
                if (renderer is MeshRenderer && filter != null) part = filter.sharedMesh;
                else if (skinned != null && skinned.sharedMesh != null) { part = new Mesh { hideFlags = HideFlags.HideAndDontSave }; baked.Add(part); skinned.BakeMesh(part); }
                if (part == null) continue;
                var materials = renderer.sharedMaterials;
                // Unity repeats the last submesh when a renderer has extra material slots.
                for (int s = 0; s < materials.Length && part.subMeshCount > 0; s++) if (materials[s] != null)
                    parts.Add(new Draw { mesh = part, matrix = source.transform.worldToLocalMatrix * renderer.localToWorldMatrix, material = materials[s], submesh = Mathf.Min(s, part.subMeshCount - 1), layer = renderer.gameObject.layer });
            }
            if (parts.Count == 0) throw new InvalidOperationException(PathText.T("模型没有可预览的 MeshRenderer / SkinnedMeshRenderer 和材质。", "The model needs a MeshRenderer or SkinnedMeshRenderer with a mesh and material."));
            var distances = PathMeshBuilder.PlacementDistances(path.Length, placement.spacing, path.closed, placement.includeEnd);
            if ((long)distances.Count * parts.Count > 20000) throw new InvalidOperationException(PathText.T("模型预览超过20000次绘制，请增大间距或简化模型。", "Model preview exceeds 20,000 draws. Increase spacing or simplify the model."));
            foreach (float distance in distances)
            {
                var p = path.Evaluate(distance);
                var tangent = placement.orientation == PlacementOrientation.Upright ? Vector3.ProjectOnPlane(p.tangent, Vector3.up) : p.tangent;
                if (tangent.sqrMagnitude < 1e-8f) tangent = Vector3.ProjectOnPlane(p.up, Vector3.up);
                if (tangent.sqrMagnitude < 1e-8f) tangent = Vector3.forward;
                var rotation = placement.orientation == PlacementOrientation.Fixed ? Quaternion.identity : Quaternion.LookRotation(tangent, placement.orientation == PlacementOrientation.Upright ? Vector3.up : p.up);
                var transform = Matrix4x4.TRS(p.position + rotation * placement.offset, rotation * Quaternion.Euler(placement.rotation), Vector3.Scale(source.transform.localScale, placement.scale));
                foreach (var part in parts) { var draw = part; draw.matrix = transform * part.matrix; models.Add(draw); }
            }
        }
        static void BeginCamera(ScriptableRenderContext context, Camera camera) { BeforeCamera(camera); }
        static void EndCamera(ScriptableRenderContext context, Camera camera) { AfterCamera(camera); }
        static bool Visible(Camera camera)
        {
            if (!IsActive || camera == null || camera.cameraType != CameraType.SceneView || !PathSceneTool.Active || PathMotionPreview.IsActive) return false;
            if (StageUtility.GetStageHandle(path.gameObject) != StageUtility.GetCurrentStageHandle() || SceneVisibilityManager.instance.IsHidden(path.gameObject)) return false;
            foreach (SceneView view in SceneView.sceneViews) if (view.camera == camera) return view.cameraMode.drawMode == DrawCameraMode.Textured || view.cameraMode.drawMode == DrawCameraMode.TexturedWire || view.cameraMode.drawMode == DrawCameraMode.Wireframe;
            return false;
        }
        static void BeforeCamera(Camera camera)
        {
            if (!Visible(camera)) return;
            RestoreRenderers();
            // Hide only the matching committed group during this Scene camera render.
            foreach (var output in Object.FindObjectsByType<PathGeneratedOutput>(FindObjectsInactive.Include, FindObjectsSortMode.None))
                if (output != null && output.owner == path && ((output.kind == "Models" && models.Count > 0) || (output.kind == "Mesh" && surface.Count > 0)))
                    foreach (var renderer in output.GetComponentsInChildren<Renderer>(true)) { hidden[renderer] = renderer.forceRenderingOff; renderer.forceRenderingOff = true; }
            DrawAll(models, camera); DrawAll(surface, camera);
        }
        static void DrawAll(List<Draw> draws, Camera camera)
        {
            foreach (var d in draws) if (d.mesh != null && d.material != null && (camera.cullingMask & (1 << d.layer)) != 0)
                Graphics.DrawMesh(d.mesh, d.matrix, d.material, d.layer, camera, d.submesh, null, ShadowCastingMode.Off, false, null, LightProbeUsage.Off);
        }
        static void AfterCamera(Camera camera) { if (camera != null && camera.cameraType == CameraType.SceneView) RestoreRenderers(); }
        static void RestoreRenderers() { foreach (var pair in hidden) if (pair.Key != null) pair.Key.forceRenderingOff = pair.Value; hidden.Clear(); }
        static void ClearModels() { models.Clear(); foreach (var m in baked) if (m != null) Object.DestroyImmediate(m); baked.Clear(); }
        static void ClearGeometry() { RestoreRenderers(); ClearModels(); surface.Clear(); if (mesh != null) Object.DestroyImmediate(mesh); mesh = null; }
        public static void Stop()
        {
            bool changed = path != null || mesh != null || models.Count > 0;
            path = null; source = null; placement = null; settings = null; material = posts = null; signature = null; ClearGeometry();
            if (fallback != null) Object.DestroyImmediate(fallback); fallback = null; modelError = meshError = null;
            if (changed) SceneView.RepaintAll();
        }
    }
}

