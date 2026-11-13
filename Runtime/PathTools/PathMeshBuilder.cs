using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

namespace CH.CustomTools.Paths
{
    public enum PathMeshKind { Ribbon, DashedLine, Arrows, Tube, Railing }
    [Serializable]
    public sealed class PathMeshSettings
    {
        public PathMeshKind kind = PathMeshKind.Ribbon;
        public float width = .25f, radius = .05f, step = .2f, metersPerTile = 1;
        public float height = 1, postSpacing = 2, dashLength = 1, gap = .5f;
        public float surfaceOffset = .02f;
        public Vector2 uvScale = Vector2.one, uvOffset;
        [Range(3, 32)] public int sides = 8;
        public int railCount = 2;
        public bool caps = true, twoSided;
    }
    /// <summary>World-space mesh. UV0: across / metres per repeat. UV1: across / normalized path distance.</summary>
    public static class PathMeshBuilder
    {
        sealed class Builder
        {
            public readonly List<Vector3> v = new List<Vector3>(), n = new List<Vector3>();
            public readonly List<Vector2> uv = new List<Vector2>(), uv1 = new List<Vector2>();
            public readonly List<int>[] indices = { new List<int>(), new List<int>() };
            public readonly PathMeshSettings settings;
            public readonly float length;
            public Builder(PathMeshSettings s, float l) { settings = s; length = l; }
            public int Vertex(Vector3 point, Vector3 normal, float across, float distance, float effectV = -1)
            {
                if (v.Count >= 200000) throw new InvalidOperationException("Mesh exceeds 200,000 vertices. Increase spacing. / 网格超过20万顶点，请增大间距。");
                int index = v.Count; v.Add(point); n.Add(normal);
                uv.Add(Vector2.Scale(new Vector2(across, distance / settings.metersPerTile), settings.uvScale) + settings.uvOffset);
                uv1.Add(new Vector2(across, effectV >= 0 ? effectV : distance / length)); return index;
            }
            public void Tri(int a, int b, int c, int sub = 0) { indices[sub].Add(a); indices[sub].Add(b); indices[sub].Add(c); }
            public Mesh Finish()
            {
                if (v.Count == 0) throw new InvalidOperationException("No mesh generated. / 未生成网格。");
                var mesh = new Mesh { name = "CH Path " + settings.kind, indexFormat = v.Count > 65535 ? IndexFormat.UInt32 : IndexFormat.UInt16 };
                mesh.SetVertices(v); mesh.SetNormals(n); mesh.SetUVs(0, uv); mesh.SetUVs(1, uv1);
                mesh.subMeshCount = settings.kind == PathMeshKind.Railing ? 2 : 1;
                for (int i = 0; i < mesh.subMeshCount; i++) mesh.SetTriangles(indices[i], i);
                mesh.RecalculateBounds(); mesh.RecalculateTangents(); return mesh;
            }
        }
        static void Positive(float value, string name) { if (float.IsNaN(value) || float.IsInfinity(value) || value < .001f || value > 100000) throw new ArgumentException(name + " must be 0.001–100000. / 参数超出范围：" + name); }
        public static Mesh Build(BezierPath path, PathMeshSettings settings)
        {
            if (path == null || settings == null) throw new ArgumentNullException();
            Positive(settings.step, "Step"); Positive(settings.metersPerTile, "Meters per tile"); Positive(settings.width, "Width"); Positive(settings.radius, "Radius");
            if (settings.sides < 3 || settings.sides > 32 || settings.railCount < 1 || settings.railCount > 4 || !BezierPath.Finite(new Vector3(settings.uvScale.x, settings.uvScale.y, settings.surfaceOffset)) || !BezierPath.Finite(new Vector3(settings.uvOffset.x, settings.uvOffset.y, 0))) throw new ArgumentException("Invalid mesh parameters. / 网格参数无效。");
            float length = path.Length; var builder = new Builder(settings, length);
            if (length / settings.step > 20000) throw new InvalidOperationException("Too many path divisions. / 路径分段过多。");
            if (settings.kind == PathMeshKind.Tube) Tube(builder, path, 0, length, 0, 0, 0, settings.caps && !path.closed);
            else if (settings.kind == PathMeshKind.Railing)
            {
                Positive(settings.height, "Height"); Positive(settings.postSpacing, "Post spacing");
                for (int i = 0; i < settings.railCount; i++) Tube(builder, path, 0, length, 0, settings.height * (i + 1) / settings.railCount, 0, settings.caps && !path.closed);
                foreach (float distance in PlacementDistances(length, settings.postSpacing, path.closed, true))
                {
                    var p = path.Evaluate(distance); Cylinder(builder, p.position, p.position + p.up * settings.height, p.Right, distance);
                }
            }
            else if (settings.kind == PathMeshKind.Ribbon) Ribbon(builder, path, 0, length, false);
            else
            {
                Positive(settings.dashLength, "Mark length"); Positive(settings.gap, "Gap");
                int count = Mathf.CeilToInt(length / (settings.dashLength + settings.gap));
                if (count > 10000) throw new InvalidOperationException("Too many markings. / 标线数量过多。");
                for (int i = 0; i < count; i++) { float start = i * (settings.dashLength + settings.gap); Ribbon(builder, path, start, Mathf.Min(length, start + settings.dashLength), settings.kind == PathMeshKind.Arrows); }
            }
            return builder.Finish();
        }
        public static List<float> PlacementDistances(float length, float spacing, bool closed, bool includeEnd)
        {
            Positive(length, "Length"); Positive(spacing, "Spacing");
            if (length / spacing > 10000) throw new InvalidOperationException("More than 10,000 objects. / 模型超过10000个。");
            var result = new List<float>();
            for (int i = 0; i * spacing < length - .0001f; i++) result.Add(i * spacing);
            if (!closed && includeEnd) result.Add(length);
            return result;
        }
        static void Ribbon(Builder b, BezierPath path, float start, float end, bool arrow)
        {
            var distances = new List<float>(); int count = Mathf.Max(1, Mathf.CeilToInt((end - start) / b.settings.step));
            for (int i = 0; i <= count; i++) distances.Add(Mathf.Lerp(start, end, i / (float)count));
            float shoulder = Mathf.Lerp(start, end, .65f);
            if (arrow) { distances.Add(shoulder); distances.Sort(); }
            for (int face = 0; face < (b.settings.twoSided ? 2 : 1); face++)
            {
                int first = b.v.Count;
                for (int i = 0; i < distances.Count; i++)
                {
                    float distance = distances[i]; var p = path.Evaluate(distance);
                    float factor = !arrow ? 1 : distance < shoulder ? .38f : (end - distance) / (end - shoulder);
                    Vector3 center = p.position + p.up * b.settings.surfaceOffset;
                    b.Vertex(center - p.Right * b.settings.width * .5f * factor, p.up * (face == 0 ? 1 : -1), 0, distance);
                    b.Vertex(center + p.Right * b.settings.width * .5f * factor, p.up * (face == 0 ? 1 : -1), 1, distance);
                    if (i == 0) continue;
                    int a = first + (i - 1) * 2, c = a + 2;
                    if (face == 0) { b.Tri(a, c, a + 1); b.Tri(a + 1, c, c + 1); }
                    else { b.Tri(a, a + 1, c); b.Tri(a + 1, c + 1, c); }
                }
            }
        }
        static void Tube(Builder b, BezierPath path, float start, float end, float x, float y, int sub, bool caps)
        {
            int count = Mathf.Max(1, Mathf.CeilToInt((end - start) / b.settings.step)); int sides = b.settings.sides, first = b.v.Count;
            for (int i = 0; i <= count; i++)
            {
                var p = path.Evaluate(Mathf.Lerp(start, end, i / (float)count)); Vector3 center = p.position + p.Right * x + p.up * y;
                Ring(b, center, p.Right, p.up, p.distance, sub, first, i);
            }
            if (caps)
            {
                var a = path.Evaluate(start); var d = path.Evaluate(end);
                Cap(b, a.position + a.Right * x + a.up * y, a.Right, a.up, -a.tangent, start, sub);
                Cap(b, d.position + d.Right * x + d.up * y, d.Right, d.up, d.tangent, end, sub);
            }
        }
        static void Cylinder(Builder b, Vector3 a, Vector3 c, Vector3 right, float distance)
        {
            Vector3 direction = (c - a).normalized, up = Vector3.Cross(direction, right).normalized; int first = b.v.Count;
            Ring(b, a, right, up, distance, 1, first, 0, 0); Ring(b, c, right, up, distance + Vector3.Distance(a, c), 1, first, 1, 1);
            if (b.settings.caps) { Cap(b, a, right, up, -direction, distance, 1, 0); Cap(b, c, right, up, direction, distance, 1, 1); }
        }
        static void Ring(Builder b, Vector3 center, Vector3 right, Vector3 up, float distance, int sub, int first, int row, float effectV = -1)
        {
            int sides = b.settings.sides;
            for (int j = 0; j <= sides; j++)
            {
                float angle = j * Mathf.PI * 2 / sides; Vector3 normal = right * Mathf.Cos(angle) + up * Mathf.Sin(angle);
                b.Vertex(center + normal * b.settings.radius, normal, j / (float)sides, distance, effectV);
                if (row == 0 || j == sides) continue;
                int a = first + (row - 1) * (sides + 1) + j, c = a + sides + 1;
                b.Tri(a, a + 1, c, sub); b.Tri(a + 1, c + 1, c, sub);
            }
        }
        static void Cap(Builder b, Vector3 center, Vector3 right, Vector3 up, Vector3 normal, float distance, int sub, float effectV = -1)
        {
            int first = b.Vertex(center, normal, .5f, distance, effectV), sides = b.settings.sides;
            for (int j = 0; j <= sides; j++)
            {
                float angle = j * Mathf.PI * 2 / sides; b.Vertex(center + b.settings.radius * (right * Mathf.Cos(angle) + up * Mathf.Sin(angle)), normal, j / (float)sides, distance, effectV);
                if (j == 0) continue;
                int a = first + j, c = first + j + 1;
                if (Vector3.Dot(Vector3.Cross(b.v[a] - center, b.v[c] - center), normal) > 0) b.Tri(first, a, c, sub); else b.Tri(first, c, a, sub);
            }
        }
    }
}
