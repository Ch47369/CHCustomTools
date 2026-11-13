using System;
using System.Collections.Generic;
using UnityEngine;
namespace CH.CustomTools.Measurement
{
    /// <summary>测量类型：直线 / 折线（未闭合，kind=Length）或闭合面积（kind=Area）。具体是两点还是多段由点数决定，闭合与否由是否回到起点决定。</summary>
    internal enum MeasureKind { Length = 0, Area = 1 }

    /// <summary>单条测量记录。两点为直线距离；三点及以上未闭合为折线（逐段 + 总长）；回到起点闭合则为面积（每段 + 周长 + 面积）。</summary>
    [Serializable]
    internal class MeasureEntry
    {
        public string id = "";
        public string title = "";
        public List<Vector3> points = new List<Vector3>();
        public Color color = new Color(1f, 0.714f, 0.282f, 1f);
        public bool visible = true;
        public MeasureKind kind = MeasureKind.Length;

        public bool IsChain { get { return points != null && points.Count > 2; } }

        /// <summary>折线总长（每段累加）。两点时等于直线距离。</summary>
        public float TotalLength()
        {
            if (points == null || points.Count < 2) return 0f;
            float sum = 0f;
            for (int i = 0; i < points.Count - 1; i++)
                sum += Vector3.Distance(points[i], points[i + 1]);
            if (kind == MeasureKind.Area) sum += Vector3.Distance(points[points.Count - 1], points[0]);
            return sum;
        }

        /// <summary>首尾直线距离。</summary>
        public float DirectLength()
        {
            if (points == null || points.Count < 2) return 0f;
            return Vector3.Distance(points[0], points[points.Count - 1]);
        }

        /// <summary>
        /// 闭合多边形面积（m²）。用 Newell 法：对任意平面多边形（含凹多边形）都精确；
        /// 非共面、自交或退化多边形不返回有效面积。比「首点扇心三角扇」可靠——后者对凹多边形会偏大。
        /// </summary>
        public float Area()
        {
            if (kind != MeasureKind.Area) return 0f;
            double value; string error;
            return DmGeometry.TryArea(points, out value, out error) ? (float)value : float.NaN;
        }

        public Bounds GetBounds()
        {
            if (points == null || points.Count == 0)
                return new Bounds(Vector3.zero, Vector3.one);

            Bounds b = new Bounds(points[0], Vector3.zero);
            for (int i = 1; i < points.Count; i++) b.Encapsulate(points[i]);
            if (b.size.sqrMagnitude < 0.0001f) b.size = Vector3.one * 0.5f;
            return b;
        }

        /// <summary>按弧长取折线的中点，用于放置总量标签。</summary>
        public Vector3 ArcMidpoint()
        {
            if (points == null || points.Count == 0) return Vector3.zero;
            if (points.Count == 1) return points[0];

            float half = TotalLength() * 0.5f;
            if (half <= 0.0001f) return points[0];

            float walked = 0f;
            for (int i = 0; i < points.Count - 1; i++)
            {
                float seg = Vector3.Distance(points[i], points[i + 1]);
                if (walked + seg >= half)
                {
                    float t = seg <= 0.0001f ? 0f : (half - walked) / seg;
                    return Vector3.Lerp(points[i], points[i + 1], t);
                }
                walked += seg;
            }
            return points[points.Count - 1];
        }

        /// <summary>去掉与前一点几乎重合的冗余点（双击结束时的补点会制造这种点）。</summary>
        public void Dedupe(float eps = 0.001f)
        {
            if (points == null) return;
            for (int i = points.Count - 1; i > 0; i--)
            {
                if (Vector3.Distance(points[i], points[i - 1]) < eps) points.RemoveAt(i);
            }
        }
    }

    /// <summary>JsonUtility 需要非泛型顶层容器。</summary>
    [Serializable]
    internal class DmPayload
    {
        public List<MeasureEntry> entries = new List<MeasureEntry>();
        public int nextIndex = 1;
    }

}
