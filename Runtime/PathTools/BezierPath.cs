using System;
using System.Collections.Generic;
using UnityEngine;

namespace CH.CustomTools.Paths
{
    [Serializable]
    public sealed class PathKnot
    {
        public Vector3 position;
        public bool automatic = true;
        public Vector3 incoming = Vector3.back, outgoing = Vector3.forward;
        public float roll;
        public PathKnot(Vector3 point) { position = point; }
    }

    public struct PathSample
    {
        public Vector3 position, tangent, up;
        public float distance;
        public Quaternion Rotation { get { return Quaternion.LookRotation(tangent, up); } }
        public Vector3 Right { get { return Vector3.Cross(up, tangent).normalized; } }
    }

    /// <summary>Cubic Bezier path with a bounded, world-distance lookup and transported frames.</summary>
    [AddComponentMenu("CH/Paths/Bezier Path")]
    [DisallowMultipleComponent]
    public sealed class BezierPath : MonoBehaviour
    {
        public List<PathKnot> knots = new List<PathKnot> { new PathKnot(Vector3.zero), new PathKnot(Vector3.forward * 10) };
        public bool closed;
        public Vector3 initialUp = Vector3.up;
        [Range(.02f, 2)] public float sampleStep = .2f;
        [Range(.0001f, .02f)] public float chordTolerance = .001f;
        [NonSerialized] PathSample[] table;
        [NonSerialized] int signature;
        public int SegmentCount { get { return knots == null ? 0 : closed ? knots.Count : knots.Count - 1; } }
        public float Length { get { EnsureCache(); return table[table.Length - 1].distance; } }
        public int SampleCount { get { EnsureCache(); return table.Length; } }
        public void Invalidate() { table = null; }
        void OnValidate() { Invalidate(); }
        static bool Finite(float v) { return !float.IsNaN(v) && !float.IsInfinity(v); }
        public static bool Finite(Vector3 v) { return Finite(v.x) && Finite(v.y) && Finite(v.z); }
        public void ValidatePath()
        {
            if (knots == null || knots.Count < (closed ? 3 : 2) || knots.Count > 512) throw new InvalidOperationException("Path needs 2–512 points (closed: at least 3). / 路径需要2–512个点，闭合至少3个。");
            if (!Finite(sampleStep) || sampleStep < .02f || !Finite(chordTolerance) || chordTolerance < .0001f) throw new InvalidOperationException("Invalid sampling accuracy. / 采样精度无效。");
            if (!Finite(initialUp) || initialUp.sqrMagnitude < .00001f) throw new InvalidOperationException("Path up vector is invalid. / 路径上方向无效。");
            var m = transform.localToWorldMatrix;
            if (!Finite(m.determinant) || Mathf.Abs(m.determinant) < 1e-8f) throw new InvalidOperationException("Path transform has zero or invalid scale. / 路径缩放不能为零。");
            foreach (var k in knots)
                if (k == null || !Finite(k.position) || !Finite(k.incoming) || !Finite(k.outgoing) || !Finite(k.roll)) throw new InvalidOperationException("Path contains invalid point values. / 路径点数值无效。");
        }
        int Signature()
        {
            unchecked
            {
                int h = transform.localToWorldMatrix.GetHashCode(); h = h * 31 + closed.GetHashCode(); h = h * 31 + initialUp.GetHashCode(); h = h * 31 + sampleStep.GetHashCode(); h = h * 31 + chordTolerance.GetHashCode();
                if (knots != null) foreach (var k in knots) { if (k == null) continue; h = h * 31 + k.position.GetHashCode(); h = h * 31 + k.incoming.GetHashCode(); h = h * 31 + k.outgoing.GetHashCode(); h = h * 31 + k.automatic.GetHashCode(); h = h * 31 + k.roll.GetHashCode(); }
                return h;
            }
        }
        public Vector3 Handle(int index, bool outgoing)
        {
            var k = knots[index];
            if (!k.automatic) return k.position + (outgoing ? k.outgoing : k.incoming);
            var previous = knots[index == 0 ? closed ? knots.Count - 1 : 0 : index - 1].position;
            var next = knots[index == knots.Count - 1 ? closed ? 0 : index : index + 1].position;
            var direction = (next - previous).normalized;
            float length = (outgoing ? next - k.position : k.position - previous).magnitude / 3;
            return k.position + direction * (outgoing ? length : -length);
        }
        public void Cubic(int segment, float t, out Vector3 position, out Vector3 tangent)
        {
            int end = (segment + 1) % knots.Count;
            Vector3 a = transform.TransformPoint(knots[segment].position), b = transform.TransformPoint(Handle(segment, true)), c = transform.TransformPoint(Handle(end, false)), d = transform.TransformPoint(knots[end].position);
            float u = 1 - t;
            position = u * u * u * a + 3 * u * u * t * b + 3 * u * t * t * c + t * t * t * d;
            tangent = 3 * u * u * (b - a) + 6 * u * t * (c - b) + 3 * t * t * (d - c);
        }
        void EnsureCache()
        {
            int hash = Signature(); if (table != null && hash == signature) return;
            ValidatePath();
            var points = new List<PathSample>(); var angles = new List<float>();
            for (int segment = 0; segment < SegmentCount; segment++)
            {
                Vector3 start, tangent; Cubic(segment, 0, out start, out tangent);
                if (segment == 0) Add(points, angles, segment, 0, start, tangent);
                for (int j = 0; j < 8; j++) Subdivide(points, angles, segment, j / 8f, (j + 1) / 8f, 0);
            }
            if (points.Count < 2 || points[points.Count - 1].distance < .001f) throw new InvalidOperationException("Path length must exceed 1 mm. / 路径长度须大于1毫米。");
            for (int i = 0; i < points.Count; i++)
            {
                var p = points[i];
                if (p.tangent.sqrMagnitude < 1e-10f) p.tangent = i + 1 < points.Count ? points[i + 1].position - p.position : p.position - points[i - 1].position;
                if (p.tangent.sqrMagnitude < 1e-10f) p.tangent = i > 0 ? points[i - 1].tangent : Vector3.forward;
                p.tangent.Normalize();
                p.up = i == 0 ? Perpendicular(p.tangent, transform.TransformDirection(initialUp)) : Transport(points[i - 1].tangent, p.tangent, points[i - 1].up);
                points[i] = p;
            }
            float length = points[points.Count - 1].distance;
            float seam = closed ? Vector3.SignedAngle(points[points.Count - 1].up, points[0].up, points[0].tangent) : 0;
            for (int i = 0; i < points.Count; i++)
            {
                var p = points[i]; p.up = Quaternion.AngleAxis(seam * p.distance / length + angles[i], p.tangent) * p.up; points[i] = p;
            }
            table = points.ToArray(); signature = hash;
        }
        void Subdivide(List<PathSample> points, List<float> angles, int s, float a, float b, int depth)
        {
            Vector3 p0, p1, pm, t0, t1, tm; float mid = (a + b) * .5f;
            Cubic(s, a, out p0, out t0); Cubic(s, b, out p1, out t1); Cubic(s, mid, out pm, out tm);
            float poly = Vector3.Distance(p0, pm) + Vector3.Distance(pm, p1), chord = Vector3.Distance(p0, p1);
            if (depth < 14 && (poly > sampleStep || poly - chord > chordTolerance || Vector3.Distance(pm, (p0 + p1) * .5f) > chordTolerance))
            { Subdivide(points, angles, s, a, mid, depth + 1); Subdivide(points, angles, s, mid, b, depth + 1); }
            else Add(points, angles, s, b, p1, t1);
        }
        void Add(List<PathSample> points, List<float> angles, int segment, float t, Vector3 p, Vector3 tangent)
        {
            if (points.Count >= 24000) throw new InvalidOperationException("Path exceeds 24,000 samples. Increase sample step or shorten it. / 路径采样超过24000，请增大采样间距或缩短路径。");
            float d = points.Count == 0 ? 0 : points[points.Count - 1].distance + Vector3.Distance(points[points.Count - 1].position, p);
            if (!Finite(p) || !Finite(d)) throw new InvalidOperationException("Path exceeds numeric limits. / 路径超出数值范围。");
            points.Add(new PathSample { position = p, tangent = tangent, distance = d });
            angles.Add(Mathf.LerpAngle(knots[segment].roll, knots[(segment + 1) % knots.Count].roll, t));
        }
        public static Vector3 Perpendicular(Vector3 tangent, Vector3 preferred)
        {
            var up = Vector3.ProjectOnPlane(preferred, tangent);
            if (up.sqrMagnitude < 1e-8f) up = Vector3.ProjectOnPlane(Mathf.Abs(tangent.y) < .9f ? Vector3.up : Vector3.forward, tangent);
            return up.normalized;
        }
        public static Vector3 Transport(Vector3 from, Vector3 to, Vector3 normal)
        {
            var rotation = Vector3.Dot(from, to) < -.9999f ? Quaternion.AngleAxis(180, normal) : Quaternion.FromToRotation(from, to);
            return Perpendicular(to, rotation * normal);
        }
        public PathSample Evaluate(float distance)
        {
            if (!Finite(distance)) throw new ArgumentException("Distance must be finite.");
            EnsureCache(); distance = Mathf.Clamp(distance, 0, table[table.Length - 1].distance);
            int lo = 0, hi = table.Length - 1;
            while (lo + 1 < hi) { int mid = (lo + hi) / 2; if (table[mid].distance < distance) lo = mid; else hi = mid; }
            var a = table[lo]; var b = table[hi]; float t = Mathf.InverseLerp(a.distance, b.distance, distance);
            var tangent = Vector3.Slerp(a.tangent, b.tangent, t).normalized;
            return new PathSample { position = Vector3.Lerp(a.position, b.position, t), tangent = tangent, up = Perpendicular(tangent, Vector3.Slerp(a.up, b.up, t)), distance = distance };
        }
    }
}
