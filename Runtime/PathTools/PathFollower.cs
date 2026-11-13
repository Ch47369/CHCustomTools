using System;
using UnityEngine;

namespace CH.CustomTools.Paths
{
    public enum PathTravel { Once, Loop, PingPong }
    public enum PathOrientation { Transported, WorldUp, PositionOnly }
    [AddComponentMenu("CH/Paths/Path Follower")]
    [DisallowMultipleComponent]
    public sealed class PathFollower : MonoBehaviour
    {
        public BezierPath path;
        [Min(0)] public float speed = 3;
        public float startDistance;
        public bool reverse, playOnEnable = true;
        public PathTravel travel = PathTravel.Loop;
        public PathOrientation orientation = PathOrientation.Transported;
        public Vector3 rotationOffset;
        public Vector3 positionOffset;
        [Min(0)] public float lookAhead = .4f;
        [Min(0)] public float turnSmoothing = 8;
        [Range(0, 80)] public float maxBank = 25;
        [Min(0)] public float bankStrength = 3;
        double elapsed;
        bool running;
        public bool IsRunning { get { return running; } }
        public void Restart() { elapsed = 0; running = true; }
        public void Pause() { running = false; }
        void OnEnable() { elapsed = 0; running = playOnEnable; }
        void Update()
        {
            if (!running || path == null) return;
            elapsed += Time.deltaTime;
            try { Apply(elapsed, Time.deltaTime); }
            catch (Exception e) { running = false; Debug.LogError("CH Path follower stopped: " + e.Message, this); }
        }
        public float DistanceAt(double seconds, out bool backwards)
        {
            if (path == null || path.transform.IsChildOf(transform) || double.IsNaN(seconds) || double.IsInfinity(seconds) || float.IsNaN(speed) || float.IsInfinity(speed) || speed < 0 || float.IsNaN(startDistance) || float.IsInfinity(startDistance)) throw new InvalidOperationException("Invalid path motion parameters or path is a child of the moving object. / 路径运动参数无效，或路径位于运动物体之下。");
            double length = path.Length, raw = startDistance + (reverse ? -1 : 1) * speed * seconds;
            backwards = reverse;
            if (travel == PathTravel.Once) return (float)Math.Max(0, Math.Min(length, raw));
            if (travel == PathTravel.Loop) return (float)((raw % length + length) % length);
            double phase = (raw % (2 * length) + 2 * length) % (2 * length);
            bool returning = phase >= length;
            backwards = reverse != returning;
            return (float)(returning ? 2 * length - phase : phase);
        }
        public PathSample PoseAt(double seconds)
        {
            if (!BezierPath.Finite(rotationOffset) || !BezierPath.Finite(positionOffset) || !BezierPath.Finite(new Vector3(lookAhead, maxBank, bankStrength)) || lookAhead < 0 || maxBank < 0 || bankStrength < 0 || !BezierPath.Finite(new Vector3(turnSmoothing, 0, 0)) || turnSmoothing < 0) throw new InvalidOperationException("Invalid orientation parameters. / 朝向参数无效。");
            bool backwards; float distance = DistanceAt(seconds, out backwards); var p = path.Evaluate(distance); float sign = backwards ? -1 : 1;
            var aheadDistance = distance + sign * Mathf.Max(.001f, lookAhead);
            if (path.closed) aheadDistance = Mathf.Repeat(aheadDistance, path.Length);
            var ahead = path.Evaluate(aheadDistance);
            Vector3 direction = ahead.position - p.position;
            if (direction.sqrMagnitude < 1e-8f || lookAhead <= 0) direction = p.tangent * sign;
            p.position += p.Right * positionOffset.x + p.up * positionOffset.y + p.tangent * positionOffset.z;
            p.tangent = direction.normalized;
            p.up = BezierPath.Perpendicular(p.tangent, orientation == PathOrientation.WorldUp ? Vector3.up : p.up);
            float bank = -Vector3.SignedAngle(path.Evaluate(distance).tangent * sign, ahead.tangent * sign, p.up) * speed * bankStrength;
            p.up = Quaternion.AngleAxis(Mathf.Clamp(bank, -maxBank, maxBank), p.tangent) * p.up;
            return p;
        }
        public void Apply(double seconds, float deltaTime = 0)
        {
            var p = PoseAt(seconds); transform.position = p.position;
            if (orientation != PathOrientation.PositionOnly)
            {
                var rotation = p.Rotation * Quaternion.Euler(rotationOffset);
                transform.rotation = deltaTime > 0 && turnSmoothing > 0 ? Quaternion.Slerp(transform.rotation, rotation, 1 - Mathf.Exp(-turnSmoothing * deltaTime)) : rotation;
            }
        }
    }
}
