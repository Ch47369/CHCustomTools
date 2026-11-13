using CH.CustomTools.Measurement;
using UnityEditor;
using UnityEngine;

namespace CH.CustomTools
{
    /// <summary>Scene strokes, anchors and labels shared by measurement and path authoring.</summary>
    internal static class CHSceneVisuals
    {
        internal static void Line(Color color, bool hot, params Vector3[] points)
        {
            Handles.color = DmSkin.SceneHalo;
            Handles.DrawAAPolyLine(4.5f, points);
            Handles.color = color;
            Handles.DrawAAPolyLine(hot ? 2.6f : 2f, points);
        }
        internal static void Curve(Vector3 a, Vector3 b, Vector3 c, Vector3 d, Color color, bool hot)
        {
            Handles.DrawBezier(a, d, b, c, DmSkin.SceneHalo, null, 4.5f);
            Handles.DrawBezier(a, d, b, c, color, null, hot ? 2.6f : 2f);
        }
        internal static void Anchor(Camera camera, Vector3 point, Color color, float radius, bool solid, bool ring)
        {
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
            Handles.BeginGUI();
            Color old = style.normal.textColor;
            try
            {
                style.normal.textColor = textColor;
                Vector2 size = style.CalcSize(content);
                var rect = new Rect(Mathf.Round(center.x - size.x * .5f), Mathf.Round(center.y - size.y * .5f), size.x, size.y);
                Color edge = DmSkin.Pro ? new Color(1, 1, 1, strong ? .20f : .12f) : new Color(0, 0, 0, strong ? .22f : .14f);
                DmSkin.DrawPill(rect, DmSkin.ScenePillBg, edge, DmSkin.PillRadius);
                GUI.Label(rect, content, style);
                return rect;
            }
            finally { style.normal.textColor = old; Handles.EndGUI(); }
        }
        internal static float PixelToWorld(Camera camera, Vector3 world, float pixels)
        {
            Vector2 screen = HandleUtility.WorldToGUIPoint(world);
            float depth = Mathf.Max(.001f, Vector3.Dot(world - camera.transform.position, camera.transform.forward));
            return Vector3.Distance(HandleUtility.GUIPointToWorldRay(screen).GetPoint(depth),
                HandleUtility.GUIPointToWorldRay(screen + new Vector2(pixels, 0)).GetPoint(depth));
        }
    }
}
