using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

namespace CH.CustomTools.Paths
{
    public enum PathMeshKind { Ribbon, DashedLine, Arrows, Tube, Railing, ElectronicFence }
    public enum PathFenceAxis { Y, X, Z }
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
        public float fenceHeight = 2f, fenceBaseOffset;
        public bool fenceDoubleSided;
        public PathFenceAxis fenceAxis;
        public bool fenceLocalAxis;
        public Vector3 dimensionsScale = Vector3.one;
        public float sheetThickness;
    }
    /// <summary>World-space path meshes with tiling UV0 and normalized effect UV1.</summary>
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
            public void FenceVertex(Vector3 point, Vector3 normal, float distance, float height)
            {
                Vertex(point, normal, height, distance);
                int index = v.Count - 1;
                uv[index] = Vector2.Scale(new Vector2(distance / settings.metersPerTile, height), settings.uvScale) + settings.uvOffset;
                uv1[index] = new Vector2(distance / length, height);
            }
            void AddSheetVertex(int source, Vector3 position, Vector3 normal)
            {
                if (v.Count >= 200000) throw new InvalidOperationException("Mesh exceeds 200,000 vertices. / 网格超过20万顶点。");
                v.Add(position); n.Add(normal); uv.Add(uv[source]); uv1.Add(uv1[source]);
            }

            void ExtrudeSheet()
            {
                int count = v.Count;
                int[] front = indices[0].ToArray();
                var boundary = new Dictionary<long, (int start, int end)>();
                void Edge(int a, int b)
                {
                    long key = ((long)Math.Min(a, b) << 32) | (uint)Math.Max(a, b);
                    if (!boundary.Remove(key)) boundary.Add(key, (a, b));
                }
                for (int i = 0; i < front.Length; i += 3)
                {
                    Edge(front[i], front[i + 1]);
                    Edge(front[i + 1], front[i + 2]);
                    Edge(front[i + 2], front[i]);
                }
                float half = settings.sheetThickness * .5f;
                for (int i = 0; i < count; i++)
                {
                    AddSheetVertex(i, v[i] - n[i] * half, -n[i]);
                    v[i] += n[i] * half;
                }
                for (int i = 0; i < front.Length; i += 3)
                    Tri(front[i] + count, front[i + 2] + count, front[i + 1] + count);
                foreach (var edge in boundary.Values)
                {
                    int a = edge.start, b = edge.end;
                    var normal = Vector3.Cross(v[a + count] - v[a], v[b] - v[a]).normalized;
                    if (normal.sqrMagnitude < .5f) continue;
                    int first = v.Count;
                    AddSheetVertex(a, v[a], normal);
                    AddSheetVertex(b, v[b], normal);
                    AddSheetVertex(a, v[a + count], normal);
                    AddSheetVertex(b, v[b + count], normal);
                    Tri(first, first + 2, first + 1);
                    Tri(first + 1, first + 2, first + 3);
                }
            }

            void ScaleDimensions()
            {
                var scale = DimensionScale(settings);
                if (scale == Vector3.one) return;
                var bounds = new Bounds(v[0], Vector3.zero);
                for (int i = 1; i < v.Count; i++) bounds.Encapsulate(v[i]);
                Vector3 center = bounds.center;
                var normalScale = new Vector3(1 / scale.x, 1 / scale.y, 1 / scale.z);
                for (int i = 0; i < v.Count; i++)
                {
                    v[i] = center + Vector3.Scale(v[i] - center, scale);
                    n[i] = Vector3.Scale(n[i], normalScale).normalized;
                }
            }

            public Mesh Finish()
            {
                if (v.Count == 0) throw new InvalidOperationException("No mesh generated. / 未生成网格。");
                if (IsSheet(settings.kind) && settings.sheetThickness > 0) ExtrudeSheet();
                ScaleDimensions();
                var mesh = new Mesh { name = "CH Path " + settings.kind, indexFormat = v.Count > 65535 ? IndexFormat.UInt32 : IndexFormat.UInt16 };
                mesh.SetVertices(v); mesh.SetNormals(n); mesh.SetUVs(0, uv); mesh.SetUVs(1, uv1);
                if (settings.kind == PathMeshKind.ElectronicFence)
                {
                    var colors = new Color32[v.Count];
                    for (int i = 0; i < colors.Length; i++) colors[i] = new Color32(255, 255, 255, 255);
                    mesh.colors32 = colors;
                }
                mesh.subMeshCount = settings.kind == PathMeshKind.Railing ? 2 : 1;
                for (int i = 0; i < mesh.subMeshCount; i++) mesh.SetTriangles(indices[i], i);
                mesh.RecalculateBounds(); mesh.RecalculateTangents(); return mesh;
            }
        }
        static void Positive(float value, string name) { if (float.IsNaN(value) || float.IsInfinity(value) || value < .001f || value > 100000) throw new ArgumentException(name + " must be 0.001–100000. / 参数超出范围：" + name); }
        public static bool IsSheet(PathMeshKind kind)
        {
            return kind == PathMeshKind.Ribbon || kind == PathMeshKind.DashedLine ||
                kind == PathMeshKind.Arrows || kind == PathMeshKind.ElectronicFence;
        }
        public static Vector3 DimensionScale(PathMeshSettings settings)
        {
            // Unity instances serialized before this field existed can contain all zeros.
            return settings.dimensionsScale == Vector3.zero ? Vector3.one : settings.dimensionsScale;
        }
        public static Mesh Build(BezierPath path, PathMeshSettings settings)
        {
            if (path == null || settings == null) throw new ArgumentNullException();
            var scale = DimensionScale(settings);
            Positive(scale.x, "Width multiplier"); Positive(scale.y, "Height multiplier"); Positive(scale.z, "Length multiplier");
            if (IsSheet(settings.kind) && (!float.IsFinite(settings.sheetThickness) || settings.sheetThickness < 0 || settings.sheetThickness > 100000))
                throw new ArgumentException("Invalid sheet thickness. / 面片厚度无效。");
            Positive(settings.step, "Step");
            Positive(settings.metersPerTile, "Meters per tile");
            if (!BezierPath.Finite(new Vector3(settings.uvScale.x, settings.uvScale.y, 0)) ||
                !BezierPath.Finite(new Vector3(settings.uvOffset.x, settings.uvOffset.y, 0)))
                throw new ArgumentException("Invalid mesh UV parameters. / 网格 UV 参数无效。");
            if (settings.kind != PathMeshKind.ElectronicFence)
            {
                Positive(settings.width, "Width");
                Positive(settings.radius, "Radius");
                if (settings.sides < 3 || settings.sides > 32 || settings.railCount < 1 ||
                    settings.railCount > 4 || !BezierPath.Finite(new Vector3(0, settings.surfaceOffset, 0)))
                    throw new ArgumentException("Invalid mesh parameters. / 网格参数无效。");
            }
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
            else if (settings.kind == PathMeshKind.ElectronicFence) Fence(builder, path);
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
        static void Fence(Builder builder, BezierPath path)
        {
            var settings = builder.settings;
            Positive(settings.fenceHeight, "Fence height");
            if (!BezierPath.Finite(new Vector3(0, settings.fenceBaseOffset, 0)))
                throw new ArgumentException("Invalid fence base offset. / 围栏底部偏移无效。");
            var up = FenceAxis(settings.fenceAxis);
            if (settings.fenceLocalAxis) up = path.transform.TransformDirection(up);

            for (int segment = 0; segment < path.SegmentCount; segment++)
            {
                float start = path.KnotDistance(segment);
                float end = segment + 1 < path.knots.Count ? path.KnotDistance(segment + 1) : builder.length;
                if (end - start < .00001f) continue;
                int rows = Mathf.Max(1, Mathf.CeilToInt((end - start) / settings.step));
                var bottoms = new Vector3[rows + 1];
                var distances = new float[rows + 1];
                var heights = new float[rows + 1];
                float firstHeight = FenceHeight(settings, path.knots[segment]);
                float lastHeight = FenceHeight(settings, path.knots[(segment + 1) % path.knots.Count]);
                for (int i = 0; i <= rows; i++)
                {
                    distances[i] = Mathf.Lerp(start, end, i / (float)rows);
                    Vector3 position = i == 0 || i == rows
                        ? path.transform.TransformPoint(path.knots[(segment + (i == rows ? 1 : 0)) % path.knots.Count].position)
                        : path.Evaluate(distances[i]).position;
                    bottoms[i] = position + up * settings.fenceBaseOffset;
                    heights[i] = Mathf.Lerp(firstHeight, lastHeight, i / (float)rows);
                }
                AddFenceFace(builder, bottoms, distances, heights, up, false);
                if (settings.fenceDoubleSided && settings.sheetThickness == 0) AddFenceFace(builder, bottoms, distances, heights, up, true);
            }
        }
        public static float FenceHeight(PathMeshSettings settings, PathKnot knot)
        {
            float height = settings.fenceHeight * (knot.fenceHeightOverride ? knot.fenceHeightScale : 1);
            Positive(height, "Point fence height");
            return height;
        }

        public static Vector3 FenceAxis(PathFenceAxis axis)
        {
            switch (axis)
            {
                case PathFenceAxis.X: return Vector3.right;
                case PathFenceAxis.Y: return Vector3.up;
                case PathFenceAxis.Z: return Vector3.forward;
                default: throw new ArgumentOutOfRangeException(nameof(axis));
            }
        }

        static void AddFenceFace(Builder builder, Vector3[] bottoms, float[] distances, float[] heights, Vector3 up, bool reverse)
        {
            int first = builder.v.Count;
            for (int i = 0; i < bottoms.Length; i++)
            {
                var delta = bottoms[Mathf.Min(i + 1, bottoms.Length - 1)] - bottoms[Mathf.Max(i - 1, 0)];
                var normal = Vector3.Cross(delta, up).normalized;
                if (normal.sqrMagnitude < .5f) normal = BezierPath.Perpendicular(up, Vector3.right);
                if (reverse) normal = -normal;
                builder.FenceVertex(bottoms[i], normal, distances[i], 0f);
                builder.FenceVertex(bottoms[i] + up * heights[i], normal, distances[i], 1f);
                if (i == 0) continue;
                int a = first + (i - 1) * 2, c = a + 2;
                if (reverse) { builder.Tri(a, a + 1, c); builder.Tri(a + 1, c + 1, c); }
                else { builder.Tri(a, c, a + 1); builder.Tri(a + 1, c, c + 1); }
            }
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
            for (int face = 0; face < (b.settings.twoSided && b.settings.sheetThickness == 0 ? 2 : 1); face++)
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
