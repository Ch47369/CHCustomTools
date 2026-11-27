using System;
using System.Collections.Generic;
using CH.CustomTools.Paths;
using UnityEngine;

namespace CH.CustomTools.VFX
{
    /// <summary>Arc length in world units, with positions and the resulting velocities in system-local space.</summary>
    public sealed class ParticleTrailCurve
    {
        public const int MaxPoints = 128;
        const int SamplesPerSpan = 96;
        readonly Vector3[] samples;
        readonly float[] distances;

        public float Length => distances[distances.Length - 1];

        public ParticleTrailCurve(IReadOnlyList<Vector3> points, Matrix4x4 localToWorld)
        {
            if (points == null || points.Count < 2 || points.Count > MaxPoints)
                throw new ArgumentException(ParticleTrailText.Pick("请添加 2 至 128 个控制点。", "Add between 2 and 128 points."));
            if (!float.IsFinite(localToWorld.determinant) || Mathf.Abs(localToWorld.determinant) < 1e-10f)
                throw new ArgumentException(ParticleTrailText.Pick("目标粒子系统的缩放必须可逆。", "The target system needs a nonzero scale."));
            samples = new Vector3[(points.Count - 1) * SamplesPerSpan + 1];
            distances = new float[samples.Length];
            samples[0] = points[0];
            for (int span = 0; span < points.Count - 1; span++)
            {
                Vector3 start = points[span], end = points[span + 1];
                Vector3 outgoing = BezierPath.AutomaticHandle(points[Math.Max(span - 1, 0)], start, end, true);
                Vector3 incoming = BezierPath.AutomaticHandle(start, end, points[Math.Min(span + 2, points.Count - 1)], false);
                for (int i = 1; i <= SamplesPerSpan; i++)
                {
                    float t = i / (float)SamplesPerSpan;
                    var a = Vector3.LerpUnclamped(start, outgoing, t);
                    var b = Vector3.LerpUnclamped(outgoing, incoming, t);
                    var c = Vector3.LerpUnclamped(incoming, end, t);
                    int index = span * SamplesPerSpan + i;
                    samples[index] = Vector3.LerpUnclamped(Vector3.LerpUnclamped(a, b, t), Vector3.LerpUnclamped(b, c, t), t);
                    distances[index] = distances[index - 1] + localToWorld.MultiplyVector(samples[index] - samples[index - 1]).magnitude;
                }
            }
            if (!float.IsFinite(Length) || Length < .0001f)
                throw new ArgumentException(ParticleTrailText.Pick("路径长度过短或坐标无效。", "The path is too short or contains invalid coordinates."));
        }

        public Vector3 Evaluate(float progress)
        {
            if (progress <= 0) return samples[0];
            if (progress >= 1) return samples[samples.Length - 1];
            float distance = Length * progress;
            int upper = Array.BinarySearch(distances, distance);
            if (upper >= 0) return samples[upper];
            upper = ~upper;
            int lower = upper - 1;
            return Vector3.LerpUnclamped(samples[lower], samples[upper],
                Mathf.InverseLerp(distances[lower], distances[upper], distance));
        }

        internal AnimationCurve[] VelocityCurves(float duration)
        {
            const int intervals = 256;
            var positions = new Vector3[intervals + 1];
            var velocities = new Vector3[positions.Length];
            for (int i = 0; i <= intervals; i++)
                positions[i] = Evaluate(i / (float)intervals);
            float step = duration / intervals;
            for (int i = 0; i <= intervals; i++)
            {
                int before = Math.Max(0, i - 1), after = Math.Min(intervals, i + 1);
                velocities[i] = (positions[after] - positions[before]) / ((after - before) * step);
            }

            // Match the total displacement of the linearly interpolated velocity curves.
            Vector3 integrated = Vector3.zero;
            for (int i = 1; i <= intervals; i++)
                integrated += (velocities[i - 1] + velocities[i]) * (.5f * step);
            Vector3 correction = (positions[intervals] - positions[0] - integrated) / duration;
            var curves = new AnimationCurve[3];
            for (int axis = 0; axis < 3; axis++)
            {
                var keys = new Keyframe[positions.Length];
                for (int i = 0; i <= intervals; i++)
                {
                    float value = velocities[i][axis] + correction[axis];
                    float incoming = i == 0 ? 0 : (velocities[i][axis] - velocities[i - 1][axis]) * intervals;
                    float outgoing = i == intervals ? 0 : (velocities[i + 1][axis] - velocities[i][axis]) * intervals;
                    keys[i] = new Keyframe(i / (float)intervals, value, incoming, outgoing);
                }
                curves[axis] = new AnimationCurve(keys);
            }
            return curves;
        }
    }
}
