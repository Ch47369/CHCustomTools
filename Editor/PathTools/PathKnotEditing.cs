using System;
using UnityEditor;
using UnityEngine;

namespace CH.CustomTools.Paths.Editor
{
    // Point types use the existing automatic flag and tangent offsets; saved/runtime paths keep their format.
    public static class PathKnotEditing
    {
        public static int Mode(BezierPath path, int index)
        {
            var knot = path.knots[index];
            return knot.automatic ? 1 : knot.incoming.sqrMagnitude < 1e-12f && knot.outgoing.sqrMagnitude < 1e-12f ? 0 : 2;
        }
        static void Set(BezierPath path, int index, int mode)
        {
            var knot = path.knots[index];
            var incoming = path.Handle(index, false) - knot.position; var outgoing = path.Handle(index, true) - knot.position;
            knot.automatic = mode == 1;
            if (mode == 0) { knot.incoming = knot.outgoing = Vector3.zero; }
            else if (mode == 2)
            {
                if (incoming.sqrMagnitude + outgoing.sqrMagnitude < 1e-12f)
                {
                    int previous = index > 0 ? index - 1 : path.closed ? path.knots.Count - 1 : index;
                    int next = index + 1 < path.knots.Count ? index + 1 : path.closed ? 0 : index;
                    incoming = (path.knots[previous].position - knot.position) / 3;
                    outgoing = (path.knots[next].position - knot.position) / 3;
                }
                knot.incoming = incoming; knot.outgoing = outgoing;
            }
        }
        public static void SetMode(BezierPath path, int index, int mode)
        {
            Validate(path, mode); if (index < -1 || index >= path.knots.Count) throw new ArgumentOutOfRangeException("index");
            Undo.RegisterCompleteObjectUndo(path, "Change path point type");
            if (index < 0) for (int i = 0; i < path.knots.Count; i++) Set(path, i, mode); else Set(path, index, mode);
            Changed(path);
        }
        public static void MoveTangent(BezierPath path, int index, bool outgoing, Vector3 worldPosition)
        {
            Validate(path, 2);
            if (index < 0 || index >= path.knots.Count || !BezierPath.Finite(worldPosition)) throw new ArgumentException("Invalid tangent");
            Undo.RecordObject(path, "Move Bezier corner tangent");
            if (path.knots[index].automatic) Set(path, index, 2);
            var offset = path.transform.InverseTransformPoint(worldPosition) - path.knots[index].position;
            if (outgoing) path.knots[index].outgoing = offset; else path.knots[index].incoming = offset;
            Changed(path);
        }
        public static void SetRoll(BezierPath path, int index, float degrees)
        {
            Validate(path, 2);
            if (index < 0 || index >= path.knots.Count || float.IsNaN(degrees) || float.IsInfinity(degrees)) throw new ArgumentException("Invalid point rotation");
            Undo.RecordObject(path, "Rotate path point"); path.knots[index].roll = degrees; Changed(path);
        }
        static void Validate(BezierPath path, int mode)
        {
            if (path == null || EditorUtility.IsPersistent(path) || Application.isPlaying || PathMotionPreview.IsActive || mode < 0 || mode > 2) throw new InvalidOperationException("Select a scene path and stop preview.");
            path.ValidatePath();
        }
        static void Changed(BezierPath path)
        { path.Invalidate(); PrefabUtility.RecordPrefabInstancePropertyModifications(path); EditorUtility.SetDirty(path); SceneView.RepaintAll(); }
        internal static string[] Names { get { return ASEShaderConverter.Editor.CHToolLanguage.IsChinese ? new[] { "直线角点", "自动平滑", "贝兹角点（独立切线）" } : new[] { "Linear corner", "Automatic smooth", "Bezier corner (independent tangents)" }; } }
    }
}
