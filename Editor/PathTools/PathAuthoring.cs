using System;
using System.Collections.Generic;
using ASEShaderConverter.Editor;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.SceneManagement;
using Object = UnityEngine.Object;

namespace CH.CustomTools.Paths.Editor
{
    public enum PathPreset { Straight, Curve, Circle, Flight }
    public enum PlacementOrientation { FollowPath, Upright, Fixed }
    [Serializable]
    public sealed class PathPlacementSettings
    {
        public float spacing = 1;
        public bool includeEnd;
        public PlacementOrientation orientation;
        public Vector3 offset, rotation, scale = Vector3.one;
    }
    public static class PathAuthoring
    {
        public static BezierPath Create(PathPreset preset, Vector3 origin)
        {
            var go = new GameObject("CH " + preset + " Path"); Undo.RegisterCreatedObjectUndo(go, "Create CH path");
            var path = Undo.AddComponent<BezierPath>(go); go.transform.position = origin;
            var points = preset == PathPreset.Straight ? new[] { Vector3.zero, Vector3.forward * 10 } :
                preset == PathPreset.Circle ? new[] { new Vector3(0, 0, 5), new Vector3(5, 0, 0), new Vector3(0, 0, -5), new Vector3(-5, 0, 0) } :
                preset == PathPreset.Flight ? new[] { new Vector3(0, 2, 0), new Vector3(5, 5, 5), new Vector3(0, 8, 12), new Vector3(-6, 4, 6) } :
                new[] { Vector3.zero, new Vector3(2, 0, 5), new Vector3(-2, 0, 10), new Vector3(0, 0, 15) };
            path.knots = new List<PathKnot>(); foreach (var p in points) path.knots.Add(new PathKnot(p));
            path.closed = preset == PathPreset.Circle || preset == PathPreset.Flight;
            if (preset == PathPreset.Circle)
            {
                // Exact cubic approximation to a circle; automatic tangents would pull it inward.
                float handle = 5 * .55228475f;
                for (int i = 0; i < 4; i++) { var k = path.knots[i]; k.automatic = false; var direction = Vector3.Cross(Vector3.up, k.position).normalized; k.outgoing = direction * handle; k.incoming = -k.outgoing; }
            }
            path.Invalidate(); Selection.activeGameObject = go; EditorSceneManager.MarkSceneDirty(go.scene); return path;
        }
        static void ValidateScene(BezierPath path)
        {
            if (path == null || EditorUtility.IsPersistent(path) || !path.gameObject.scene.IsValid() || EditorSceneManager.IsPreviewScene(path.gameObject.scene)) throw new InvalidOperationException("Select a path in an open scene. / 请选择已打开场景中的路径。");
            if (EditorApplication.isPlayingOrWillChangePlaymode) throw new InvalidOperationException("Stop Play mode before generating. / 请退出运行模式后再生成。");
            path.ValidatePath();
        }
        static GameObject Root(BezierPath path, string kind)
        {
            var root = new GameObject("CH " + kind + " · " + path.name); SceneManager.MoveGameObjectToScene(root, path.gameObject.scene);
            var marker = root.AddComponent<PathGeneratedOutput>(); marker.owner = path; marker.kind = kind; return root;
        }
        static void Commit(GameObject root, BezierPath path, string kind)
        {
            Undo.IncrementCurrentGroup(); int group = Undo.GetCurrentGroup(); Undo.SetCurrentGroupName("Generate CH " + kind);
            Undo.RegisterCreatedObjectUndo(root, "Generate CH " + kind);
            foreach (var old in Object.FindObjectsByType<PathGeneratedOutput>(FindObjectsInactive.Include, FindObjectsSortMode.None))
                if (old != null && old.gameObject != root && old.owner == path && old.kind == kind && old.gameObject.scene == path.gameObject.scene) Undo.DestroyObjectImmediate(old.gameObject);
            Undo.CollapseUndoOperations(group); EditorSceneManager.MarkSceneDirty(path.gameObject.scene); Selection.activeGameObject = root;
        }
        public static GameObject Place(BezierPath path, GameObject source, PathPlacementSettings settings)
        {
            ValidateScene(path);
            if (source == null || settings == null || source.GetComponentInChildren<BezierPath>(true) != null || source.GetComponentInChildren<PathGeneratedOutput>(true) != null) throw new ArgumentException("Choose a model or prefab, not a path or generated group. / 请选择模型或预制体，不要选择路径或生成组。");
            if (!BezierPath.Finite(settings.offset) || !BezierPath.Finite(settings.rotation) || !BezierPath.Finite(settings.scale) || settings.scale.x <= 0 || settings.scale.y <= 0 || settings.scale.z <= 0) throw new ArgumentException("Invalid placement offsets/scale. / 模型偏移或缩放无效。");
            var distances = PathMeshBuilder.PlacementDistances(path.Length, settings.spacing, path.closed, settings.includeEnd);
            var root = Root(path, "Models");
            try
            {
                foreach (float distance in distances)
                {
                    var p = path.Evaluate(distance);
                    var instance = PrefabUtility.IsPartOfPrefabAsset(source) ? (GameObject)PrefabUtility.InstantiatePrefab(source, path.gameObject.scene) : Object.Instantiate(source);
                    instance.transform.SetParent(root.transform, false);
                    var tangent = settings.orientation == PlacementOrientation.Upright ? Vector3.ProjectOnPlane(p.tangent, Vector3.up) : p.tangent;
                    if (tangent.sqrMagnitude < 1e-8f) tangent = Vector3.ProjectOnPlane(p.up, Vector3.up);
                    if (tangent.sqrMagnitude < 1e-8f) tangent = Vector3.forward;
                    var rotation = settings.orientation == PlacementOrientation.Fixed ? Quaternion.identity : Quaternion.LookRotation(tangent, settings.orientation == PlacementOrientation.Upright ? Vector3.up : p.up);
                    instance.transform.position = p.position + rotation * settings.offset;
                    instance.transform.rotation = rotation * Quaternion.Euler(settings.rotation);
                    instance.transform.localScale = Vector3.Scale(source.transform.localScale, settings.scale);
                    instance.name = source.name + " " + distance.ToString("0.00", System.Globalization.CultureInfo.InvariantCulture) + "m";
                }
                Commit(root, path, "Models"); return root;
            }
            catch { Object.DestroyImmediate(root); throw; }
        }
        public static Material DefaultMaterial()
        {
            var pipeline = GraphicsSettings.currentRenderPipeline; string type = pipeline == null ? "" : pipeline.GetType().Name;
            string shaderName = type.Contains("HDRender") ? "HDRP/Lit" : pipeline != null ? "Universal Render Pipeline/Lit" : "Standard";
            var shader = Shader.Find(shaderName);
            if (shader == null) throw new InvalidOperationException("Choose a material compatible with the active render pipeline. / 请指定适合当前渲染管线的材质。");
            return new Material(shader) { name = "CH Path default", color = new Color(.8f, .65f, .12f, 1) };
        }
        public static GameObject Generate(BezierPath path, PathMeshSettings settings, Material material, Material posts, string folder)
        {
            ValidateScene(path);
            folder = (folder ?? "").Replace('\\', '/').TrimEnd('/');
            if (!(folder == "Assets" || folder.StartsWith("Assets/", StringComparison.Ordinal)) || !AssetDatabase.IsValidFolder(folder)) throw new ArgumentException("Choose an existing Assets folder. / 请选择Assets中的现有目录。");
            Mesh mesh = PathMeshBuilder.Build(path, settings); GameObject root = null; string asset = null; Material created = null;
            try
            {
                if (material == null) material = created = DefaultMaterial();
                asset = AssetDatabase.GenerateUniqueAssetPath(folder + "/CHPath_" + settings.kind + ".asset");
                AssetDatabase.CreateAsset(mesh, asset); if (created != null) AssetDatabase.AddObjectToAsset(created, mesh);
                AssetDatabase.SaveAssets();
                root = Root(path, "Mesh"); root.AddComponent<MeshFilter>().sharedMesh = mesh;
                root.AddComponent<MeshRenderer>().sharedMaterials = settings.kind == PathMeshKind.Railing ? new[] { material, posts == null ? material : posts } : new[] { material };
                Commit(root, path, "Mesh"); return root;
            }
            catch
            {
                if (root != null) Object.DestroyImmediate(root);
                if (asset != null && AssetDatabase.LoadAssetAtPath<Mesh>(asset) == mesh) AssetDatabase.DeleteAsset(asset);
                else if (mesh != null && !EditorUtility.IsPersistent(mesh)) Object.DestroyImmediate(mesh);
                if (created != null && !EditorUtility.IsPersistent(created)) Object.DestroyImmediate(created);
                throw;
            }
        }
        public static PathFollower Attach(BezierPath path, GameObject target)
        {
            ValidateScene(path);
            if (target == null || EditorUtility.IsPersistent(target) || target.scene != path.gameObject.scene || path.transform.IsChildOf(target.transform)) throw new ArgumentException("Choose a separate scene object in the path's scene. / 请选择同场景中的独立运动物体，不能是路径的父级。");
            var follower = target.GetComponent<PathFollower>(); if (follower == null) follower = Undo.AddComponent<PathFollower>(target);
            Undo.RecordObject(follower, "Assign CH path"); follower.path = path; follower.travel = path.closed ? PathTravel.Loop : PathTravel.PingPong;
            EditorUtility.SetDirty(follower); return follower;
        }
        public static PathFollower FlightDemo(BezierPath path)
        {
            ValidateScene(path); var root = new GameObject("CH Flight demo · replace visual child"); SceneManager.MoveGameObjectToScene(root, path.gameObject.scene);
            Undo.RegisterCreatedObjectUndo(root, "Create flight demo");
            // An original arrow-shaped placeholder made from primitives; no outside models.
            var body = GameObject.CreatePrimitive(PrimitiveType.Capsule); body.name = "Visual (replace with your bird)"; body.transform.SetParent(root.transform, false); body.transform.localRotation = Quaternion.Euler(90, 0, 0); body.transform.localScale = new Vector3(.2f, .5f, .2f); Object.DestroyImmediate(body.GetComponent<Collider>());
            var wings = GameObject.CreatePrimitive(PrimitiveType.Cube); wings.name = "Wings placeholder"; wings.transform.SetParent(root.transform, false); wings.transform.localScale = new Vector3(1.8f, .04f, .3f); Object.DestroyImmediate(wings.GetComponent<Collider>());
            var pipeline = GraphicsSettings.currentRenderPipeline;
            if (pipeline != null && pipeline.defaultMaterial != null) foreach (var renderer in root.GetComponentsInChildren<Renderer>()) renderer.sharedMaterial = pipeline.defaultMaterial;
            var follower = Attach(path, root); follower.Apply(0); Selection.activeGameObject = root; return follower;
        }
    }
    [InitializeOnLoad]
    public static class PathMotionPreview
    {
        static PathFollower follower;
        static Transform parent;
        static Vector3 localPosition, localScale, worldPosition;
        static Quaternion localRotation, worldRotation;
        static double started;
        public static bool IsActive { get { return follower != null; } }
        static PathMotionPreview()
        {
            AssemblyReloadEvents.beforeAssemblyReload += Stop; EditorApplication.quitting += Stop;
            EditorApplication.playModeStateChanged += _ => Stop(); EditorSceneManager.sceneClosing += (_, __) => Stop();
        }
        public static void Start(PathFollower target)
        {
            Stop(); if (target == null || target.path == null || EditorUtility.IsPersistent(target) || EditorApplication.isPlayingOrWillChangePlaymode || target.path.transform.IsChildOf(target.transform)) throw new InvalidOperationException("Choose a separate scene follower with a path, outside Play mode. / 请在非运行模式选择独立的路径运动对象。");
            target.path.ValidatePath(); var t = target.transform;
            follower = target; parent = t.parent; localPosition = t.localPosition; localRotation = t.localRotation; localScale = t.localScale; worldPosition = t.position; worldRotation = t.rotation;
            started = EditorApplication.timeSinceStartup; EditorApplication.update += Tick;
        }
        static void Tick()
        {
            if (follower == null) { Stop(); return; }
            try { follower.Apply(EditorApplication.timeSinceStartup - started); SceneView.RepaintAll(); }
            catch (Exception e) { Stop(); Debug.LogWarning(e.Message); }
        }
        public static void Stop()
        {
            EditorApplication.update -= Tick;
            if (follower != null)
            {
                var t = follower.transform;
                if (t.parent == parent) { t.localPosition = localPosition; t.localRotation = localRotation; }
                else { t.position = worldPosition; t.rotation = worldRotation; }
                t.localScale = localScale;
            }
            follower = null; SceneView.RepaintAll();
        }
    }
}
