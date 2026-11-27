using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using ASEShaderConverter.Editor;
using CH.CustomTools.VFX;
using CH.CustomTools.Paths;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.Rendering;
using Object = UnityEngine.Object;

public static class UnityParticleTrailSmoke
{
    [Serializable]
    sealed class Motion
    {
        public string name;
        public float duration, length, midError, endpointError, arrivalAge, speedVariation;
        public int trailVertices;
    }
    [Serializable]
    sealed class Report
    {
        public string version, unity, status, failure;
        public string[] checks;
        public Motion[] samples;
        public int count;
    }
    static readonly List<string> checks = new List<string>();
    static readonly List<Motion> samples = new List<Motion>();
    static GameObject root;
    static ParticleSystem system;
    static ParticleTrailData path => ParticleTrailStore.Find(system);
    static ParticleSystemRenderer renderer;
    static Material trailMaterial;
    static SceneView view;
    static ASEShaderConverterWindow window;
    static Vector2 inputOffset, received, baseScreen, tangentScreen;
    static Vector2[] pointScreens;
    static bool calibrating, receivedInput;
    static int phase;
    static double next, deadline;
    static bool nativePlayRequested;
    static string errors;

    public static void Run()
    {
        try
        {
            CHValidationInput.Install();
            PlayerSettings.runInBackground = true;
            EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);
            root = new GameObject("Trail effect root");
            var target = new GameObject("S curve particle");
            target.transform.SetParent(root.transform, false);
            system = target.AddComponent<ParticleSystem>();
            ParticleTrailStore.GetOrCreate(system);
            renderer = target.GetComponent<ParticleSystemRenderer>();
            var shader = Shader.Find("Sprites/Default");
            Check(shader != null, "Built-in preview shader is available");
            trailMaterial = new Material(shader) { color = new Color(0.15f, 0.85f, 1f, 1f) };
            AssetDatabase.CreateAsset(trailMaterial, "Assets/TrailTest.mat");
            renderer.trailMaterial = trailMaterial;
            renderer.renderMode = ParticleSystemRenderMode.None;
            var main = system.main;
            main.startColor = new Color(.8f, .6f, .2f, 1f);
            main.startSize = .22f;
            main.gravityModifier = 1.25f;
            main.startSpeed = 5;
            var noise = system.noise; noise.enabled = true;
            var trails = system.trails;
            trails.enabled = true;
            trails.widthOverTrail = .75f;
            trails.colorOverTrail = new Color(.5f, .8f, 1f, 1f);
            var shape = system.shape; shape.enabled = true; shape.radius = 4;
            var force = system.forceOverLifetime; force.enabled = true;

            ASEShaderConverterWindow.OpenParticleTrails(system);
            window = Resources.FindObjectsOfTypeAll<ASEShaderConverterWindow>().Single();
            var flags = BindingFlags.Instance | BindingFlags.NonPublic;
            Check((string)typeof(ASEShaderConverterWindow).GetField("activePage", flags).GetValue(window) == "particleTrails",
                "The unified tool window opens the particle trail page");
            var tool = typeof(ParticleTrailBaker).Assembly.GetType("CH.CustomTools.VFX.ParticleTrailSceneTool");
            tool.GetMethod("Start", BindingFlags.Static | BindingFlags.NonPublic).Invoke(null, new object[] { system });
            view = EditorWindow.GetWindow<SceneView>();
            view.Show();
            view.position = new Rect(40, 60, 1000, 760);
            view.LookAtDirect(Vector3.zero, Quaternion.identity, 6.5f);
            view.orthographic = true;
            view.Focus();
            SceneView.duringSceneGui += Capture;
            Application.logMessageReceived += Log;
            next = EditorApplication.timeSinceStartup + 3;
            deadline = next + 85;
            EditorApplication.update += Tick;
        }
        catch (Exception error) { Finish(error); }
    }

    static void Check(bool value, string message)
    {
        if (!value) throw new InvalidOperationException(message);
        checks.Add(message);
    }

    static void Log(string message, string stack, LogType type)
    {
        if (type == LogType.Error || type == LogType.Exception || type == LogType.Assert)
            errors = message + "\n" + stack;
    }

    static Vector2 WindowPoint(Vector3 point) =>
        GUIUtility.GUIToScreenPoint(HandleUtility.WorldToGUIPoint(point)) - view.position.position;

    static void Capture(SceneView scene)
    {
        if (scene != view || path == null) return;
        if (calibrating && Event.current.type == EventType.MouseMove)
        {
            received = Event.current.mousePosition;
            receivedInput = true;
        }
        if (Event.current.type != EventType.Repaint) return;
        baseScreen = WindowPoint(Vector3.zero);
        pointScreens = path.knots.Select(k => WindowPoint(system.transform.TransformPoint(k.position))).ToArray();
        if (path.knots.Count > 2)
            tangentScreen = WindowPoint(system.transform.TransformPoint(path.Handle(1, true)));
    }

    static void Mouse(EventType type, Vector2 at, bool shift = false, Vector2 delta = default)
    {
        CHValidationInput.Send(view, new Event { type = type, button = 0, mousePosition = at + inputOffset, shift = shift, delta = delta });
        view.Repaint();
    }

    static void Tick()
    {
        try
        {
            if (EditorApplication.timeSinceStartup > deadline) throw new TimeoutException("Particle trail UI test timed out.");
            if (EditorApplication.timeSinceStartup < next || pointScreens == null) return;
            if (errors != null) throw new InvalidOperationException(errors);
            next = EditorApplication.timeSinceStartup + .65;
            switch (phase++)
            {
                case 0:
                    calibrating = true;
                    Mouse(EventType.MouseMove, baseScreen);
                    calibrating = false;
                    Check(receivedInput, "SceneView sends calibrated edit events");
                    inputOffset = baseScreen - received;
                    foreach (var offset in new[] { new Vector2(-260, 85), new Vector2(-90, -145), new Vector2(95, 115), new Vector2(250, -65) })
                    {
                        Mouse(EventType.MouseDown, baseScreen + offset, true);
                        Mouse(EventType.MouseUp, baseScreen + offset, true);
                    }
                    Check(path.knots.Count == 4, "Shift-click draws four ordered control points in Scene view");
                    Check(Tools.hidden && system.GetComponent<ParticleTrailPath>() == null,
                        "Editing hides the object's native transform tool and adds no component");
                    break;
                case 1:
                    Mouse(EventType.MouseMove, pointScreens[1]);
                    break;
                case 2:
                    Vector3 before = path.knots[1].position;
                    Vector2 offsetDrag = new Vector2(45, -35);
                    Mouse(EventType.MouseDown, pointScreens[1]);
                    Mouse(EventType.MouseDrag, pointScreens[1] + offsetDrag, delta: offsetDrag);
                    Mouse(EventType.MouseUp, pointScreens[1] + offsetDrag);
                    var moved = path.knots[1].position;
                    Check(Vector3.Distance(before, moved) > .1f, "Dragging a Scene marker moves its control point");
                    view.Focus();
                    CHValidationInput.Send(view, new Event { type = EventType.KeyDown, keyCode = KeyCode.Delete });
                    CHValidationInput.Send(view, new Event { type = EventType.KeyUp, keyCode = KeyCode.Delete });
                    Check(path != null && path.knots.Count == 3, "Delete removes only the selected control point");
                    Undo.FlushUndoRecordObjects();
                    Undo.PerformUndo();
                    Check(path.knots.Count == 4 && path.knots[1].position == moved, "Undo restores the removed control point");
                    break;
                case 3:
                    BeginHandleChecks();
                    break;
                case 4:
                    Mouse(EventType.MouseMove, tangentScreen);
                    break;
                case 5:
                    VerifyHandles();
                    VerifyBake();
                    break;
                case 6:
                    Check(errors == null, "Scene editing and native trail rendering finish without errors");
                    Finish(null);
                    return;
            }
            view.Repaint();
        }
        catch (Exception error) { Finish(error); }
    }

    // Run in a fresh interactive Editor with the saved scene from Run().
    // Observe Unity's real selected-particle playback without advancing the particle manually.
    public static void RunNativePreview()
    {
        try
        {
            EditorSceneManager.OpenScene("Assets/ParticleTrailSmoke.unity");
            system = GameObject.Find("S curve particle").GetComponent<ParticleSystem>();
            Check(path != null, "Editor data resolves after scene reopen");
            renderer = system.GetComponent<ParticleSystemRenderer>();
            view = EditorWindow.GetWindow<SceneView>();
            view.Show();
            view.LookAtDirect(system.transform.TransformPoint(path.knots[1].position), system.transform.rotation, 11f);
            view.orthographic = true;
            Selection.activeGameObject = system.gameObject;
            view.Focus();
            Application.logMessageReceived += Log;
            Check(system.GetComponent<ParticleTrailPath>() == null &&
                path.BakedSignature == ParticleTrailBaker.Signature(path), "Restart restores the saved editor path without a scene script");
            next = EditorApplication.timeSinceStartup + 2;
            deadline = EditorApplication.timeSinceStartup + 120;
            EditorApplication.update += ObserveNativePreview;
        }
        catch (Exception error) { FinishNativePreview(error); }
    }

    static void ObserveNativePreview()
    {
        try
        {
            if (errors != null) throw new InvalidOperationException(errors);
            if (EditorApplication.timeSinceStartup > deadline)
                throw new TimeoutException("Unity's selected particle system did not play in the native preview.");
            if (!nativePlayRequested && EditorApplication.timeSinceStartup >= next)
            {
                nativePlayRequested = true;
                ActiveEditorTracker.sharedTracker.ForceRebuild();
                var inspector = ActiveEditorTracker.sharedTracker.activeEditors.FirstOrDefault(editor => editor.target == system);
                if (inspector != null)
                {
                    const BindingFlags flags = BindingFlags.Instance | BindingFlags.NonPublic;
                    inspector.GetType().GetMethod("Init", flags)?.Invoke(inspector, new object[] { true });
                    var effect = inspector.GetType().GetField("m_ParticleEffectUI", flags)?.GetValue(inspector);
                    effect?.GetType().GetMethod("Play", flags)?.Invoke(effect, null);
                }
                EditorApplication.QueuePlayerLoopUpdate();
                view.Repaint();
            }
            if (!system.isPlaying || system.particleCount != 1 || system.time < path.Duration * .4f)
                return;
            var particle = new ParticleSystem.Particle[2];
            if (system.GetParticles(particle) != 1) return;
            float age = particle[0].startLifetime - particle[0].remainingLifetime;
            if (age < path.Duration * .3f) return;
            var curve = new ParticleTrailCurve(path.knots, system.transform.localToWorldMatrix);
            float error = system.transform.TransformVector(particle[0].position - curve.Evaluate(age / path.Duration)).magnitude;
            var mesh = new Mesh();
            try
            {
                renderer.BakeTrailsMesh(mesh, view.camera, true);
                if (mesh.vertexCount <= 12) return;
                Check(true, "Unity's own Scene particle preview plays the saved bake");
                Check(error < curve.Length * .025f, $"Native Scene playback follows the edited curve at {age:F3} s (error {error:F4} m)");
                Check(Connected(mesh), $"The native Scene preview produces one continuous trail ({mesh.vertexCount} vertices)");
                var camera = new GameObject("Native playback evidence camera").AddComponent<Camera>();
                try
                {
                    var center = system.transform.TransformPoint(curve.Evaluate(.5f));
                    camera.transform.SetPositionAndRotation(center - system.transform.forward * 18, system.transform.rotation);
                    camera.orthographic = true;
                    camera.orthographicSize = 6;
                    camera.clearFlags = CameraClearFlags.SolidColor;
                    camera.backgroundColor = Color.black;
                    CaptureTrail(camera, "particle-trail-native-preview.png");
                }
                finally { Object.DestroyImmediate(camera.gameObject); }
                samples.Add(new Motion { name = "Native Scene Play", duration = path.Duration, length = curve.Length,
                    arrivalAge = age, midError = error, trailVertices = mesh.vertexCount });
                FinishNativePreview(null);
            }
            finally { Object.DestroyImmediate(mesh); }
        }
        catch (Exception error) { FinishNativePreview(error); }
    }

    static void FinishNativePreview(Exception error)
    {
        EditorApplication.update -= ObserveNativePreview;
        Application.logMessageReceived -= Log;
        WriteReport("particle-trail-native.json", error);
        EditorApplication.Exit(error == null ? 0 : 1);
    }

    static void BeginHandleChecks()
    {
        var tool = typeof(ParticleTrailBaker).Assembly.GetType("CH.CustomTools.VFX.ParticleTrailSceneTool");
        const BindingFlags flags = BindingFlags.Static | BindingFlags.NonPublic;
        var rotating = tool.GetProperty("Rotating", flags);
        view.Focus();
        CHValidationInput.Send(view, new Event { type = EventType.KeyDown, keyCode = KeyCode.E });
        CHValidationInput.Send(view, new Event { type = EventType.KeyUp, keyCode = KeyCode.E });
        Check((bool)rotating.GetValue(null) && Tools.hidden, "E activates only the selected point rotation handle");
        tool.GetProperty("Selected", flags).SetValue(null, 1);
        view.Repaint();
    }

    static void VerifyHandles()
    {
        var tool = typeof(ParticleTrailBaker).Assembly.GetType("CH.CustomTools.VFX.ParticleTrailSceneTool");
        const BindingFlags flags = BindingFlags.Static | BindingFlags.NonPublic;
        var rotating = tool.GetProperty("Rotating", flags);
        var knot = path.knots[1];
        var point = knot.position;
        var incoming = path.Handle(1, false);
        var outgoing = path.Handle(1, true);
        var drag = new Vector2(10, -25);
        Mouse(EventType.MouseDown, tangentScreen);
        Mouse(EventType.MouseDrag, tangentScreen + drag, delta: drag);
        Mouse(EventType.MouseUp, tangentScreen + drag);
        Check(!path.knots[1].automatic && Vector3.Distance(path.Handle(1, false), incoming) < .0001f &&
            Vector3.Distance(path.Handle(1, true), outgoing) > .05f,
            "Scene tangent handle drag freezes automatic tangents and moves just one side");
        tool.GetMethod("RotateTangents", flags).Invoke(null, new object[] { Quaternion.AngleAxis(8, Vector3.forward) });
        Check(path.knots[1].position == point && Vector3.Distance(path.Handle(1, false), incoming) > .01f,
            "Point-centred rotation rotates tangents without moving the point");
        CHValidationInput.Send(view, new Event { type = EventType.KeyDown, keyCode = KeyCode.W });
        CHValidationInput.Send(view, new Event { type = EventType.KeyUp, keyCode = KeyCode.W });
        Check(!(bool)rotating.GetValue(null) && Tools.hidden, "W returns to selected point position handle");
        tool.GetMethod("Stop", flags).Invoke(null, null);
        Check(!Tools.hidden, "Stopping editing restores the original transform tool");
        tool.GetMethod("Start", flags).Invoke(null, new object[] { system });
    }

    static void VerifyBake()
    {
        for (int i = 0; i < path.knots.Count; i++)
            path.knots[i].position += Vector3.forward * (i * .8f + .9f);
        path.Duration = 2f;
        // Exercise migration/removal without changing the editor path data.
        var legacy = system.gameObject.AddComponent<ParticleTrailPath>();
        legacy.Points.AddRange(path.knots.Select(k => k.position));
        legacy.Duration = path.Duration;
        string original = EditorJsonUtility.ToJson(system);
        var changes = ParticleTrailBaker.MovementChanges(system);
        Check(changes.Any(c => c.Contains("Start Speed")) && changes.Any(c => c.Contains("Gravity Modifier")) &&
            changes.Contains("Noise") && changes.Contains("Force over Lifetime"), "Preflight names the actual motion conflicts");
        ParticleTrailBaker.Bake(system, path);
        Check(system.GetComponent<ParticleTrailPath>() == null, "Successful bake removes the legacy runtime path component");
        Check(system.main.startSpeed.constant == 0 && system.main.gravityModifier.constant == 0 &&
            !system.noise.enabled && !system.forceOverLifetime.enabled, "Bake removes competing motion modules");
        Check(system.main.startLifetime.constant == 2 && system.main.simulationSpace == ParticleSystemSimulationSpace.Local &&
            system.velocityOverLifetime.space == ParticleSystemSimulationSpace.Local &&
            system.velocityOverLifetime.x.curve.length >= 100 &&
            system.velocityOverLifetime.y.curve.length >= 100 && system.velocityOverLifetime.z.curve.length >= 100,
            "Native Velocity over Lifetime stores three normalized curves with the requested lifetime");
        Check(renderer.trailMaterial == trailMaterial && Mathf.Approximately(system.trails.widthOverTrail.constant, .75f) &&
            renderer.renderMode == ParticleSystemRenderMode.None && Mathf.Approximately(system.main.startSize.constant, .22f),
            "Bake preserves the artist's material, trail width, renderer mode and start size");
        string baked = EditorJsonUtility.ToJson(system);
        Undo.FlushUndoRecordObjects();
        Undo.PerformUndo();
        Check(EditorJsonUtility.ToJson(system) == original && string.IsNullOrEmpty(path.BakedSignature) &&
            system.GetComponent<ParticleTrailPath>() != null,
            "One bake Undo restores the complete original particle settings");
        Undo.PerformRedo();
        string redone = EditorJsonUtility.ToJson(system);
        if (redone != baked)
        {
            Directory.CreateDirectory("Artifacts");
            File.WriteAllText("Artifacts/undo-baked.json", baked);
            File.WriteAllText("Artifacts/undo-redone.json", redone);
        }
        Check(redone == baked && path.BakedSignature == ParticleTrailBaker.Signature(path) &&
            system.GetComponent<ParticleTrailPath>() == null,
            "Redo restores the full native bake");

        Sample("S curve at 2 s", true);
        Sample("S curve at 60 Hz", false, 120);
        var localBefore = path.knots.Select(k => k.position).ToArray();
        root.transform.SetPositionAndRotation(new Vector3(24f, -3, 11), Quaternion.Euler(26, 39, -18));
        Check(path.knots.Select(k => k.position).SequenceEqual(localBefore), "Moving the parent leaves the same saved local control points");
        Sample("Rigid root move and rotation", false);

        path.knots[1].position += new Vector3(-.25f, .65f, .9f);
        path.Duration = 1.35f;
        Check(path.BakedSignature != ParticleTrailBaker.Signature(path), "Changed point and duration are detected before rebake");
        ParticleTrailBaker.Bake(system, path);
        Check(system.main.startLifetime.constant == 1.35f && system.main.duration == 1.35f &&
            renderer.trailMaterial == trailMaterial, "Rebake sets the new duration and retains the assigned trail material");
        Sample("Edited path at 1.35 s", false);

        var snapshot = path.knots.Select(k => k.position).ToArray();
        var scene = system.gameObject.scene;
        Check(EditorSceneManager.SaveScene(scene, "Assets/ParticleTrailSmoke.unity"), "A scene with authored data saves");
        window.Close();
        EditorSceneManager.OpenScene("Assets/ParticleTrailSmoke.unity");
        system = GameObject.Find("S curve particle").GetComponent<ParticleSystem>();
        Check(path != null, "Editor data resolves after scene reopen");
        renderer = system.GetComponent<ParticleSystemRenderer>();
        Check(path.knots.Select(k => k.position).SequenceEqual(snapshot) && path.Duration == 1.35f && path.BakedSignature == ParticleTrailBaker.Signature(path),
            "Closing the tool and reopening the scene preserves authored points and duration");
        Check(system.GetComponents<MonoBehaviour>().Length == 0, "Saved effect contains no MonoBehaviour dependency");
        Check(system.velocityOverLifetime.enabled && system.trails.enabled && renderer.trailMaterial == trailMaterial,
            "The saved particle system plays its native bake after reopening the scene");
        VerifyLegacyAndPrefab();
        VerifySharedPath();
    }

    static void VerifySharedPath()
    {
        var source = new GameObject("Shared model path").AddComponent<CH.CustomTools.Paths.BezierPath>();
        source.transform.SetPositionAndRotation(new Vector3(2, 3, -4), Quaternion.Euler(17, 35, 12));
        source.transform.localScale = new Vector3(2, .7f, 1.3f);
        source.knots = new List<CH.CustomTools.Paths.PathKnot> {
            new CH.CustomTools.Paths.PathKnot(Vector3.zero),
            new CH.CustomTools.Paths.PathKnot(new Vector3(3, 1, 4)),
            new CH.CustomTools.Paths.PathKnot(new Vector3(1, 4, 7))
        };
        var particle = new GameObject("Shared-path particle").AddComponent<ParticleSystem>();
        particle.transform.SetPositionAndRotation(new Vector3(5, -2, 1), Quaternion.Euler(19, -45, 8));
        try
        {
            ParticleTrailData.ImportPath(particle, source, false);
            var data = ParticleTrailStore.Find(particle);
            var curve = new ParticleTrailCurve(data.knots, particle.transform.localToWorldMatrix);
            Check(Vector3.Distance(particle.transform.TransformPoint(curve.Evaluate(0)), source.Evaluate(0).position) < .0001f &&
                Vector3.Distance(particle.transform.TransformPoint(curve.Evaluate(1)), source.Evaluate(source.Length).position) < .0001f,
                "Existing model path imports into transformed particle local space");
            var original = source.knots.Select(k => k.position).ToArray();
            var samples = Enumerable.Range(0, 21).Select(i => curve.Evaluate(i / 20f)).ToArray();
            ParticleTrailData.ReversePath(particle);
            var reversed = new ParticleTrailCurve(data.knots, particle.transform.localToWorldMatrix);
            Check(Enumerable.Range(0, 21).All(i => Vector3.Distance(reversed.Evaluate(i / 20f), samples[20-i]) < .002f) &&
                source.knots.Select(k => k.position).SequenceEqual(original),
                "Reversing the particle path preserves exact curve shape and leaves source path unchanged");
            ParticleTrailBaker.Bake(particle, data);
            Check(particle.velocityOverLifetime.enabled && particle.GetComponent<ParticleTrailPath>() == null,
                "Reversed shared path bakes native particle movement");
        }
        finally { Object.DestroyImmediate(source.gameObject); Object.DestroyImmediate(particle.gameObject); }
    }

    static void VerifyLegacyAndPrefab()
    {
        var go = new GameObject("Legacy prefab");
        var ps = go.AddComponent<ParticleSystem>();
        var legacy = go.AddComponent<ParticleTrailPath>();
        legacy.Points.AddRange(new[] { Vector3.zero, new Vector3(1, 3, 2), new Vector3(5, 4, 3) });
        legacy.Duration = 3.5f;
        var asset = AssetDatabase.GenerateUniqueAssetPath("Assets/LegacyTrail.prefab");
        PrefabUtility.SaveAsPrefabAsset(go, asset);
        Object.DestroyImmediate(go);
        var stage = PrefabStageUtility.OpenPrefab(asset);
        ps = stage.prefabContentsRoot.GetComponent<ParticleSystem>();
        var data = ParticleTrailStore.GetOrCreate(ps);
        Check(data.knots.Count == 3 && data.knots[1].position == new Vector3(1, 3, 2) &&
            data.Duration == 3.5f, "Legacy prefab imports existing curve coordinates and time");
        ParticleTrailBaker.Bake(ps, data);
        Check(ps.GetComponent<ParticleTrailPath>() == null, "Prefab Mode bake removes migrated component");
        var save = typeof(PrefabStage).GetMethod("SavePrefab", BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
        save.Invoke(stage, null);
        StageUtility.GoToMainStage();
        stage = PrefabStageUtility.OpenPrefab(asset);
        ps = stage.prefabContentsRoot.GetComponent<ParticleSystem>();
        data = ParticleTrailStore.Find(ps);
        Check(data != null && data.knots.Count == 3 && data.Duration == 3.5f && ps.GetComponent<ParticleTrailPath>() == null,
            "Prefab record resolves after closing and reopening Prefab Mode");
        StageUtility.GoToMainStage();
    }

    static void Sample(string name, bool capture, int steps = 480)
    {
        var curve = new ParticleTrailCurve(path.knots, system.transform.localToWorldMatrix);
        float delta = path.Duration / steps;
        var particle = new ParticleSystem.Particle[4];
        var result = new Motion { name = name, duration = path.Duration, length = curve.Length };
        float expectedSpeed = curve.Length / path.Duration;
        Vector3 previous = default;
        var rootTransform = system.transform;
        system.Stop(false, ParticleSystemStopBehavior.StopEmittingAndClear);
        for (int i = 1; i < steps; i++)
        {
            system.Simulate(delta, false, i == 1, false);
            if (system.GetParticles(particle) != 1) throw new InvalidOperationException("Expected exactly one live particle at step " + i);
            var p = particle[0];
            float age = p.startLifetime - p.remainingLifetime;
            Vector3 actual = rootTransform.TransformPoint(p.position);
            Vector3 expected = rootTransform.TransformPoint(curve.Evaluate(age / path.Duration));
            result.midError = Mathf.Max(result.midError, Vector3.Distance(actual, expected));
            if (i > 1)
                result.speedVariation = Mathf.Max(result.speedVariation,
                    Mathf.Abs(Vector3.Distance(previous, actual) / delta / expectedSpeed - 1));
            previous = actual;
            result.arrivalAge = age;
        }
        system.Simulate(delta, false, false, false);
        if (system.GetParticles(particle) == 1)
        {
            previous = rootTransform.TransformPoint(particle[0].position);
            result.arrivalAge = particle[0].startLifetime - particle[0].remainingLifetime;
        }
        result.endpointError = Vector3.Distance(previous, rootTransform.TransformPoint(path.knots.Last().position));
        var camera = new GameObject("Trail preview camera").AddComponent<Camera>();
        var mesh = new Mesh();
        try
        {
            var center = rootTransform.TransformPoint(curve.Evaluate(.5f));
            camera.transform.SetPositionAndRotation(center - rootTransform.forward * 18, rootTransform.rotation);
            camera.orthographic = true;
            camera.orthographicSize = 6;
            camera.clearFlags = CameraClearFlags.SolidColor;
            camera.backgroundColor = Color.black;
            renderer.BakeTrailsMesh(mesh, camera, true);
            result.trailVertices = mesh.vertexCount;
            samples.Add(result);
            float midLimit = steps >= 480 ? .004f : .012f;
            float endLimit = steps >= 480 ? .005f : .015f;
            Check(result.midError < curve.Length * midLimit, name + $" stays within {midLimit:P1} of arc length in flight");
            Check(result.endpointError < curve.Length * endLimit && Mathf.Abs(result.arrivalAge - path.Duration) < delta * 1.6f,
                name + " reaches the endpoint within one simulation step of the requested lifetime");
            Check(result.speedVariation < .10f, name + " remains within 10% of the nominal speed");
            Check(result.trailVertices > 40 && mesh.GetIndexCount(0) > 60 && Connected(mesh), name + " creates a single continuous native Trails strip");
            if (capture) CaptureTrail(camera);
        }
        finally
        {
            Object.DestroyImmediate(mesh);
            Object.DestroyImmediate(camera.gameObject);
            system.Stop(false, ParticleSystemStopBehavior.StopEmittingAndClear);
        }
    }

    static bool Connected(Mesh mesh)
    {
        var ids = mesh.GetIndices(0);
        var groups = Enumerable.Range(0, mesh.vertexCount).ToArray();
        int Root(int x) { while (groups[x] != x) x = groups[x]; return x; }
        for (int i = 0; i < ids.Length; i += 3)
        {
            int root = Root(ids[i]);
            groups[Root(ids[i + 1])] = root;
            groups[Root(ids[i + 2])] = root;
        }
        return ids.Select(Root).Distinct().Count() == 1;
    }

    static void CaptureTrail(Camera camera, string filename = "particle-trail-preview.png")
    {
        var target = RenderTexture.GetTemporary(960, 600, 24, RenderTextureFormat.ARGB32);
        var texture = new Texture2D(target.width, target.height, TextureFormat.RGB24, false);
        var prior = RenderTexture.active;
        try
        {
            camera.targetTexture = target;
            camera.Render();
            RenderTexture.active = target;
            texture.ReadPixels(new Rect(0, 0, target.width, target.height), 0, 0);
            texture.Apply();
            Check(texture.GetPixels32().Count(p => p.b > 35) > 250, "Unity renders the native trail material in the camera preview");
            Directory.CreateDirectory("Artifacts");
            File.WriteAllBytes("Artifacts/" + filename, texture.EncodeToPNG());
        }
        finally
        {
            camera.targetTexture = null;
            RenderTexture.active = prior;
            RenderTexture.ReleaseTemporary(target);
            Object.DestroyImmediate(texture);
        }
    }

    static void Finish(Exception error)
    {
        EditorApplication.update -= Tick;
        SceneView.duringSceneGui -= Capture;
        Application.logMessageReceived -= Log;
        WriteReport("particle-trail.json", error);
        EditorApplication.Exit(error == null ? 0 : 1);
    }

    static void WriteReport(string file, Exception error)
    {
        Directory.CreateDirectory("Artifacts");
        File.WriteAllText("Artifacts/" + file, JsonUtility.ToJson(new Report
        {
            unity = Application.unityVersion,
            version = UnityEditor.PackageManager.PackageInfo.FindForAssembly(typeof(ParticleTrailPath).Assembly)?.version,
            status = error == null ? "Passed" : "Failed",
            failure = error?.ToString(),
            checks = checks.ToArray(),
            samples = samples.ToArray(),
            count = checks.Count
        }, true));
    }
}
