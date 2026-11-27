using System;
using System.Collections.Generic;
using System.Globalization;
using System.Text;
using ASEShaderConverter.Editor;
using CH.CustomTools.Paths;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

namespace CH.CustomTools.VFX
{
    internal static class ParticleTrailText
    {
        internal static string Pick(string zh, string en) => CHToolLanguage.Pick(zh, en);
    }

    public static class ParticleTrailBaker
    {
        public const float MinDuration = .1f;
        public const float MaxDuration = 120f;

        public static bool CanEdit(ParticleSystem system) =>
            system != null && !EditorUtility.IsPersistent(system) && system.gameObject.scene.IsValid() &&
            system.gameObject.scene.isLoaded && !EditorApplication.isPlayingOrWillChangePlaymode;

        public static string Signature(ParticleTrailPath path)
        {
            var text = new StringBuilder(path.Duration.ToString("R", CultureInfo.InvariantCulture));
            foreach (var p in path.Points) text.Append('|').Append(p.ToString("R", CultureInfo.InvariantCulture));
            return Hash128.Compute(text.ToString()).ToString();
        }
        public static string Signature(ParticleTrailData path)
        {
            var text = new StringBuilder(path.Duration.ToString("R", CultureInfo.InvariantCulture));
            foreach (var knot in path.knots)
            {
                text.Append('|').Append(knot.position.ToString("R", CultureInfo.InvariantCulture));
                if (!knot.automatic)
                    text.Append('|').Append(knot.incoming.ToString("R", CultureInfo.InvariantCulture))
                        .Append('|').Append(knot.outgoing.ToString("R", CultureInfo.InvariantCulture));
            }
            return Hash128.Compute(text.ToString()).ToString();
        }

        static bool IsConstant(ParticleSystem.MinMaxCurve curve, float value) =>
            curve.mode == ParticleSystemCurveMode.Constant && curve.constant == value;

        public static List<string> MovementChanges(ParticleSystem system)
        {
            var changes = new List<string>();
            var main = system.main;
            if (!IsConstant(main.startSpeed, 0)) changes.Add("Main / Start Speed → 0");
            if (!IsConstant(main.gravityModifier, 0)) changes.Add("Main / Gravity Modifier → 0");
            if (!IsConstant(main.startDelay, 0)) changes.Add("Main / Start Delay → 0");
            if (main.simulationSpace != ParticleSystemSimulationSpace.Local) changes.Add("Main / Simulation Space → Local");
            if (main.scalingMode != ParticleSystemScalingMode.Hierarchy) changes.Add("Main / Scaling Mode → Hierarchy");
            if (main.simulationSpeed != 1) changes.Add("Main / Simulation Speed → 1");
            if (main.loop) changes.Add("Main / Looping");
            if (main.prewarm) changes.Add("Main / Prewarm");
            if (main.ringBufferMode != ParticleSystemRingBufferMode.Disabled) changes.Add("Main / Ring Buffer Mode");
            if (main.stopAction != ParticleSystemStopAction.None) changes.Add("Main / Stop Action → None");
            if (system.noise.enabled) changes.Add("Noise");
            if (system.forceOverLifetime.enabled) changes.Add("Force over Lifetime");
            if (system.limitVelocityOverLifetime.enabled) changes.Add("Limit Velocity over Lifetime");
            if (system.inheritVelocity.enabled) changes.Add("Inherit Velocity");
            if (system.externalForces.enabled) changes.Add("External Forces");
            if (system.collision.enabled) changes.Add("Collision");
            if (system.trigger.enabled) changes.Add("Triggers");
            if (system.velocityOverLifetime.enabled) changes.Add("Velocity over Lifetime");
            return changes;
        }

        public static void Bake(ParticleSystem system, ParticleTrailPath path)
        {
            if (!CanEdit(system) || path == null || system.gameObject != path.gameObject)
                throw new ArgumentException(ParticleTrailText.Pick("请选择场景内的目标粒子系统。", "Select a particle system in an open scene."));
            Bake(system, ParticleTrailStore.GetOrCreate(system));
        }

        public static void Bake(ParticleSystem system, ParticleTrailData path)
        {
            if (!CanEdit(system) || path == null || ParticleTrailStore.Find(system) != path)
                throw new ArgumentException(ParticleTrailText.Pick("请选择场景内的目标粒子系统。", "Select a particle system in an open scene."));
            float duration = path.Duration;
            if (!float.IsFinite(duration) || duration < MinDuration || duration > MaxDuration)
                throw new ArgumentException(ParticleTrailText.Pick("路径用时应在 0.1 至 120 秒之间。", "Set a travel time between 0.1 and 120 seconds."));

            var geometry = new ParticleTrailCurve(path.knots, system.transform.localToWorldMatrix);
            var curves = geometry.VelocityCurves(duration);
            var renderer = system.GetComponent<ParticleSystemRenderer>();
            if (renderer == null)
                throw new InvalidOperationException(ParticleTrailText.Pick("目标缺少 Particle System Renderer。", "The target needs a Particle System Renderer."));

            Undo.IncrementCurrentGroup();
            int group = Undo.GetCurrentGroup();
            const string label = "Bake particle trail path";
            Undo.SetCurrentGroupName(label);
            Undo.RegisterCompleteObjectUndo(new UnityEngine.Object[] { system, renderer }, label);
            ParticleTrailStore.Record(label);
            try
            {
                system.Stop(false, ParticleSystemStopBehavior.StopEmittingAndClear);
                ConfigureMotion(system, duration, path.knots[0].position, curves);
                ConfigureTrails(system, renderer, geometry.Length);
                path.BakedSignature = Signature(path);
                foreach (var changed in new UnityEngine.Object[] { system, renderer })
                {
                    PrefabUtility.RecordPrefabInstancePropertyModifications(changed);
                    EditorUtility.SetDirty(changed);
                }
                ParticleTrailStore.Commit();
                var legacy = system.GetComponent<ParticleTrailPath>();
                if (legacy != null) Undo.DestroyObjectImmediate(legacy);
                if (system.GetComponent<ParticleTrailPath>() != null)
                    throw new InvalidOperationException("Could not remove the legacy path component. / 无法移除旧路径组件。");
                UnityEditor.SceneManagement.EditorSceneManager.MarkSceneDirty(system.gameObject.scene);
                Undo.CollapseUndoOperations(group);
            }
            catch
            {
                Undo.RevertAllDownToGroup(group);
                ParticleTrailStore.Commit();
                throw;
            }
        }

        static void ConfigureMotion(ParticleSystem system, float duration, Vector3 start, AnimationCurve[] curves)
        {
            var main = system.main;
            main.loop = false;
            main.prewarm = false;
            main.duration = duration;
            main.startLifetime = duration;
            main.startDelay = 0;
            main.startSpeed = 0;
            main.gravityModifier = 0;
            main.simulationSpace = ParticleSystemSimulationSpace.Local;
            main.scalingMode = ParticleSystemScalingMode.Hierarchy;
            main.simulationSpeed = 1;
            main.stopAction = ParticleSystemStopAction.None;
            main.ringBufferMode = ParticleSystemRingBufferMode.Disabled;

            var emission = system.emission;
            emission.enabled = true;
            emission.rateOverTime = 0;
            emission.rateOverDistance = 0;
            // Use Unity's serialized minimum interval to keep Undo/Redo and reload identical.
            emission.SetBursts(new[] { new ParticleSystem.Burst(0, (short)1, (short)1, 1, .01f) });

            var shape = system.shape;
            shape.enabled = !start.Equals(Vector3.zero);
            shape.shapeType = ParticleSystemShapeType.Sphere;
            shape.radius = 0;
            shape.position = start;
            shape.rotation = Vector3.zero;
            shape.scale = Vector3.one;
            shape.alignToDirection = false;
            shape.randomPositionAmount = 0;
            shape.texture = null;

            var noise = system.noise; noise.enabled = false;
            var force = system.forceOverLifetime; force.enabled = false;
            var limit = system.limitVelocityOverLifetime; limit.enabled = false;
            var inherit = system.inheritVelocity; inherit.enabled = false;
            var external = system.externalForces; external.enabled = false;
            var collision = system.collision; collision.enabled = false;
            var triggers = system.trigger; triggers.enabled = false;

            var velocity = system.velocityOverLifetime;
            velocity.enabled = true;
            velocity.space = ParticleSystemSimulationSpace.Local;
            velocity.orbitalX = 0;
            velocity.orbitalY = 0;
            velocity.orbitalZ = 0;
            velocity.radial = 0;
            velocity.speedModifier = 1;
            velocity.x = new ParticleSystem.MinMaxCurve(1, curves[0]);
            velocity.y = new ParticleSystem.MinMaxCurve(1, curves[1]);
            velocity.z = new ParticleSystem.MinMaxCurve(1, curves[2]);
        }

        static void ConfigureTrails(ParticleSystem system, ParticleSystemRenderer renderer, float length)
        {
            var trails = system.trails;
            trails.enabled = true;
            trails.mode = ParticleSystemTrailMode.PerParticle;
            trails.ratio = 1;
            trails.worldSpace = false;
            trails.dieWithParticles = false;
            // Keep custom widths, colors, lifetime and texture settings.
            trails.minVertexDistance = Mathf.Min(trails.minVertexDistance, length / 64f);
            if (renderer.trailMaterial == null)
            {
                renderer.trailMaterial = renderer.sharedMaterial != null ? renderer.sharedMaterial :
                    GraphicsSettings.currentRenderPipeline == null
                        ? AssetDatabase.GetBuiltinExtraResource<Material>("Default-Particle.mat") : null;
            }
        }
    }
}
