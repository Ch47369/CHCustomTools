using CH.CustomTools.Measurement;
using UnityEditor;
using UnityEngine;

namespace CH.CustomTools
{
    /// <summary>Scene strokes, anchors and labels shared by measurement and path authoring.</summary>
    [InitializeOnLoad]
    internal static class CHSceneVisuals
    {
        struct Label { public Rect rect; public string text; public Color accent, textColor; public bool strong; public GUIStyle style; }
        static readonly System.Collections.Generic.List<Label> labels = new System.Collections.Generic.List<Label>();
        static SceneView labelView;
        static CHSceneVisuals()
        {
            AssemblyReloadEvents.beforeAssemblyReload += () => { if (strokeMaterial != null) Object.DestroyImmediate(strokeMaterial); if (strokeMesh != null) Object.DestroyImmediate(strokeMesh); };
            SceneView.beforeSceneGui += view =>
            {
                labelView = view; labels.Clear();
                // All world geometry first, then one GUI pass. Never reset the camera
                // between the geometry of separate measurements or path segments.
                SceneView.duringSceneGui -= FlushLabels;
                SceneView.duringSceneGui += FlushLabels;
            };
        }
        static Material strokeMaterial;
        static Mesh strokeMesh;
        static readonly System.Collections.Generic.List<Vector3> vertices = new System.Collections.Generic.List<Vector3>();
        static readonly System.Collections.Generic.List<Color> colors = new System.Collections.Generic.List<Color>();
        static readonly System.Collections.Generic.List<int> indices = new System.Collections.Generic.List<int>();
        static bool Begin(Camera camera)
        {
            if (camera == null || Event.current == null || Event.current.type != EventType.Repaint) return false;
            if (strokeMaterial == null)
            {
                var shader = Shader.Find("Hidden/CHCustomTools/SceneStroke");
                if (shader == null) return false;
                strokeMaterial = new Material(shader) { hideFlags = HideFlags.HideAndDontSave };
            }
            if (strokeMesh == null) { strokeMesh = new Mesh { name = "CH Scene strokes", hideFlags = HideFlags.HideAndDontSave }; strokeMesh.MarkDynamic(); }
            vertices.Clear(); colors.Clear(); indices.Clear();
            strokeMaterial.SetInt("_ZTest", (int)Handles.zTest);
            strokeMaterial.SetMatrix("_CHSceneProjection", GL.GetGPUProjectionMatrix(camera.projectionMatrix, true));
            return true;
        }
        static void End()
        {
            if (vertices.Count == 0) return;
            strokeMesh.Clear(); strokeMesh.SetVertices(vertices); strokeMesh.SetColors(colors); strokeMesh.SetTriangles(indices, 0, false);
            if (strokeMaterial.SetPass(0)) Graphics.DrawMeshNow(strokeMesh, Matrix4x4.identity);
        }
        static Camera CurrentCamera { get { return SceneView.currentDrawingSceneView == null ? Camera.current : SceneView.currentDrawingSceneView.camera; } }
        static Vector3 Eye(Camera camera, Vector3 p) { return camera.worldToCameraMatrix.MultiplyVector(p - camera.transform.position); }
        static void Vertex(Vector3 p, Color color) { indices.Add(vertices.Count); vertices.Add(p); colors.Add(color); }
        static void Band(Vector3 a, Vector3 b, Vector3 oa, Vector3 ob, Color color, float inner, float outer, float alphaInner, float alphaOuter)
        {
            var ci = new Color(color.r, color.g, color.b, color.a * alphaInner); var co = new Color(color.r, color.g, color.b, color.a * alphaOuter);
            Vertex(a + oa * inner, ci); Vertex(b + ob * inner, ci); Vertex(b + ob * outer, co);
            Vertex(a + oa * inner, ci); Vertex(b + ob * outer, co); Vertex(a + oa * outer, co);
        }
        static void Stroke(Camera camera, Vector3 a, Vector3 b, Color color, float width)
        {
            var projection = camera.projectionMatrix; var ca = projection * new Vector4(a.x, a.y, a.z, 1); var cb = projection * new Vector4(b.x, b.y, b.z, 1);
            var delta = new Vector2((cb.x / cb.w - ca.x / ca.w) * camera.pixelWidth, (cb.y / cb.w - ca.y / ca.w) * camera.pixelHeight);
            if (delta.sqrMagnitude < .01f) return;
            var normal = new Vector2(-delta.y, delta.x).normalized;
            var basis = new Vector3(normal.x / (camera.pixelWidth * projection.m00), normal.y / (camera.pixelHeight * projection.m11), 0) * EditorGUIUtility.pixelsPerPoint;
            var oa = basis * ca.w; var ob = basis * cb.w;
            Band(a, b, oa, ob, color, -width, width, 1, 1);
            Band(a, b, oa, ob, color, width, width + 1.5f, 1, 0);
            Band(a, b, oa, ob, color, -width, -width - 1.5f, 1, 0);
        }
        internal static void Line(Color color, bool hot, params Vector3[] points) { StrokeLine(color, hot ? 2.6f : 2f, true, points); }
        internal static void FineLine(Color color, float width, params Vector3[] points) { StrokeLine(color, width, false, points); }
        static void StrokeLine(Color color, float width, bool outline, Vector3[] points)
        {
            var camera = CurrentCamera;
            if (points == null || !Begin(camera)) return;
            try
            {
                // Extrude in eye space. Native wide world strokes lose subpixel precision
                // far from the origin; eye-space vertices retain both width and scene depth.
                for (int i = 1; i < points.Length; i++)
                {
                    if (!Paths.BezierPath.Finite(points[i - 1]) || !Paths.BezierPath.Finite(points[i])) continue;
                    var a = Eye(camera, points[i - 1]); var b = Eye(camera, points[i]); float near = -camera.nearClipPlane * 1.001f;
                    if (a.z > near && b.z > near) continue;
                    if (a.z > near) a = Vector3.LerpUnclamped(a, b, (near - a.z) / (b.z - a.z));
                    else if (b.z > near) b = Vector3.LerpUnclamped(b, a, (near - b.z) / (a.z - b.z));
                    if (outline) Stroke(camera, a, b, DmSkin.SceneHalo, 4.5f);
                    Stroke(camera, a, b, color, width);
                }
            }
            finally { End(); }
        }
        internal static void Triangle(Vector3 a, Vector3 b, Vector3 c)
        {
            var camera = CurrentCamera; var color = Handles.color;
            if (!Paths.BezierPath.Finite(a) || !Paths.BezierPath.Finite(b) || !Paths.BezierPath.Finite(c) || !Begin(camera)) return;
            try
            {
                var input = new[] { Eye(camera, a), Eye(camera, b), Eye(camera, c) };
                var clipped = new System.Collections.Generic.List<Vector3>(4); float near = -camera.nearClipPlane * 1.001f;
                for (int i = 0; i < 3; i++)
                {
                    var from = input[i]; var to = input[(i + 1) % 3]; bool inside = from.z <= near, nextInside = to.z <= near;
                    if (inside) clipped.Add(from);
                    if (inside != nextInside) clipped.Add(Vector3.LerpUnclamped(from, to, (near - from.z) / (to.z - from.z)));
                }
                for (int i = 1; i + 1 < clipped.Count; i++) { Vertex(clipped[0], color); Vertex(clipped[i], color); Vertex(clipped[i + 1], color); }
            }
            finally { End(); }
        }
        internal static void Arc(Vector3 center, Vector3 normal, Vector3 from, float degrees, float radius, Color color)
        {
            int count = Mathf.Max(2, Mathf.CeilToInt(Mathf.Abs(degrees) / 6)); var points = new Vector3[count + 1];
            for (int i = 0; i <= count; i++) points[i] = center + Quaternion.AngleAxis(degrees * i / count, normal) * from.normalized * radius;
            FineLine(color, 1.5f, points);
        }
        internal static void Curve(Vector3 a, Vector3 b, Vector3 c, Vector3 d, Color color, bool hot)
        {
            var points = new Vector3[65];
            for (int i = 0; i < points.Length; i++)
            { float t = i / 64f, u = 1 - t; points[i] = u * u * u * a + 3 * u * u * t * b + 3 * u * t * t * c + t * t * t * d; }
            Line(color, hot, points);
        }
        internal static void Anchor(Camera camera, Vector3 point, Color color, float radius, bool solid, bool ring)
        {
            if (camera == null || Vector3.Dot(point - camera.transform.position, camera.transform.forward) <= camera.nearClipPlane) return;
            Vector3 normal = -camera.transform.forward;
            Handles.color = new Color(0, 0, 0, .30f);
            Handles.DrawSolidDisc(point, normal, radius * 1.9f);
            Handles.color = color;
            if (solid) Handles.DrawSolidDisc(point, normal, radius);
            else Handles.DrawWireDisc(point, normal, radius, 2f);
            if (ring)
            {
                Handles.color = new Color(color.r, color.g, color.b, .85f);
                Handles.DrawWireDisc(point, normal, radius * 2.7f, 1.5f);
            }
        }
        internal static Rect Pill(Vector2 center, GUIContent content, Color accent, bool strong, GUIStyle style, Color textColor)
        {
            Vector2 size = style.CalcSize(content);
            var rect = new Rect(Mathf.Round(center.x - size.x * .5f), Mathf.Round(center.y - size.y * .5f), size.x, size.y);
            if (Event.current == null || Event.current.type != EventType.Repaint) return rect;
            var origin = rect;
            for (int attempt = 0; attempt < 12; attempt++)
            {
                bool overlap = false;
                foreach (var label in labels) if (rect.Overlaps(new Rect(label.rect.x - 3, label.rect.y - 2, label.rect.width + 6, label.rect.height + 4))) { overlap = true; break; }
                if (!overlap) break;
                int row = attempt / 2 + 1;
                rect.y = origin.y + (attempt % 2 == 0 ? -1 : 1) * row * (size.y + 5);
            }
            labels.Add(new Label { rect = rect, text = content.text, accent = accent, strong = strong, style = style, textColor = textColor });
            return rect;
        }
        static void FlushLabels(SceneView view)
        {
            if (view != labelView || Event.current.type != EventType.Repaint || labels.Count == 0) return;
            Color gui = GUI.color, content = GUI.contentColor; Matrix4x4 matrix = GUI.matrix;
            Handles.BeginGUI();
            try
            {
                GUI.color = GUI.contentColor = Color.white; GUI.matrix = Matrix4x4.identity;
                foreach (var label in labels)
                {
                    var old = label.style.normal.textColor;
                    try
                    {
                        label.style.normal.textColor = label.textColor;
                        Color edge = DmSkin.Pro ? new Color(1, 1, 1, label.strong ? .20f : .12f) : new Color(0, 0, 0, label.strong ? .22f : .14f);
                        DmSkin.DrawPill(label.rect, DmSkin.ScenePillBg, edge, DmSkin.PillRadius);
                        GUI.Label(label.rect, label.text, label.style);
                    }
                    finally { label.style.normal.textColor = old; }
                }
            }
            finally { GUI.color = gui; GUI.contentColor = content; GUI.matrix = matrix; labels.Clear(); Handles.EndGUI(); }
        }
        internal static float PixelToWorld(Camera camera, Vector3 world, float pixels)
        {
            if (camera == null || camera.pixelHeight < 1) return 0;
            float depth = camera.orthographic ? 1 : Mathf.Max(camera.nearClipPlane, Vector3.Dot(world - camera.transform.position, camera.transform.forward));
            return pixels * EditorGUIUtility.pixelsPerPoint * 2 * depth / (camera.pixelHeight * Mathf.Abs(camera.projectionMatrix.m11));
        }
    }
}
