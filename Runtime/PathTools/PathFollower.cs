using System;
using System.Collections.Generic;
using UnityEngine;

namespace CH.CustomTools.Paths
{
    public enum PathTravel { Once, Loop, PingPong }
    public enum PathOrientation { Transported, WorldUp, PositionOnly, Upright }
    public enum PathMotionDrive { Speed, AnimationProgress, Sequence }
    public enum PathModelAxis { PositiveZ, PositiveY, PositiveX, NegativeZ, NegativeY, NegativeX }
    [AddComponentMenu("CH/Paths/Path Follower")]
    [DisallowMultipleComponent]
    [ExecuteAlways]
    public sealed class PathFollower : MonoBehaviour
    {
        public BezierPath path;
        [Min(0)] public float speed = 3;
        public float startDistance;
        public bool reverse, playOnEnable = true;
        public PathTravel travel = PathTravel.Loop;
        public PathOrientation orientation = PathOrientation.Transported;
        public PathMotionDrive drive;
        [Range(0f, 1f)] public float progress;
        public PathModelAxis modelForward = PathModelAxis.PositiveZ;
        public PathModelAxis modelUp = PathModelAxis.PositiveY;
        [HideInInspector] public AnimationClip progressClip, bakedClip;
        [HideInInspector] public float animationDuration = 3;
        public List<PathSequenceStage> sequence = new List<PathSequenceStage>();
        public bool loopSequence;
        public Vector3 rotationOffset;
        public Vector3 positionOffset;
        [Min(0)] public float lookAhead = .4f;
        [Min(0)] public float turnSmoothing = 8;
        [Range(0, 80)] public float maxBank = 25;
        [Min(0)] public float bankStrength = 3;
        double elapsed;
        bool running;
        PathSequenceTimeline runtimeSequence;
        public bool IsRunning { get { return running; } }
        public void Restart() { elapsed = 0; running = true; runtimeSequence = null; }
        public void Pause() { running = false; }
        void OnEnable() { elapsed = 0; running = playOnEnable; runtimeSequence = null; }
        public static event Action<PathFollower> EditorAnimationApplied;
        void OnDidApplyAnimationProperties()
        {
            if (!Application.IsPlaying(gameObject) && drive == PathMotionDrive.AnimationProgress)
                EditorAnimationApplied?.Invoke(this);
        }
        void LateUpdate()
        {
            if (!Application.IsPlaying(gameObject) || drive != PathMotionDrive.AnimationProgress || path == null) return;
            try { ApplyProgress(progress); }
            catch (Exception e)
            {
                enabled = false;
                Debug.LogError("CH Path follower stopped: " + e.Message, this);
            }
        }
        void Update()
        {
            if (!Application.IsPlaying(gameObject) || !running || drive == PathMotionDrive.AnimationProgress) return;
            if (drive == PathMotionDrive.Speed && path == null) return;
            elapsed += Time.deltaTime;
            try
            {
                if (drive == PathMotionDrive.Sequence)
                {
                    if (runtimeSequence == null) runtimeSequence = new PathSequenceTimeline(this, transform.rotation);
                    float time = loopSequence ? (float)(elapsed % runtimeSequence.Duration) : Mathf.Min((float)elapsed, runtimeSequence.Duration);
                    ApplySequencePose(runtimeSequence.Evaluate(time), runtimeSequence.HasRotation);
                    if (!loopSequence && elapsed >= runtimeSequence.Duration) running = false;
                }
                else Apply(elapsed, Time.deltaTime);
            }
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
            bool backwards;
            float distance = DistanceAt(seconds, out backwards);
            return PoseOnPath(path, distance, backwards, speed, orientation);
        }
        public PathSample PoseAtProgress(float value)
        {
            float duration = progressClip != null && progressClip.length > 0 ? progressClip.length : animationDuration;
            if (path == null || path.transform.IsChildOf(transform) || float.IsNaN(value) || float.IsInfinity(value) ||
                float.IsNaN(duration) || float.IsInfinity(duration) || duration <= 0)
                throw new InvalidOperationException("Invalid path or animation progress. / 路径或动画进度无效。");
            return PoseOnPath(path, Mathf.Clamp01(value) * path.Length, reverse, path.Length / duration, orientation);
        }
        internal PathSample PoseOnPath(BezierPath path, float distance, bool backwards, float motionSpeed, PathOrientation orientation)
        {
            if (!BezierPath.Finite(rotationOffset) || !BezierPath.Finite(positionOffset) || !BezierPath.Finite(new Vector3(lookAhead, maxBank, bankStrength)) || lookAhead < 0 || maxBank < 0 || bankStrength < 0 || !BezierPath.Finite(new Vector3(turnSmoothing, 0, 0)) || turnSmoothing < 0) throw new InvalidOperationException("Invalid orientation parameters. / 朝向参数无效。");
            var p = path.Evaluate(distance); float sign = backwards ? -1 : 1;
            var aheadDistance = distance + sign * Mathf.Max(.001f, lookAhead);
            if (path.closed) aheadDistance = Mathf.Repeat(aheadDistance, path.Length);
            var ahead = path.Evaluate(aheadDistance);
            Vector3 direction = ahead.position - p.position;
            if (direction.sqrMagnitude < 1e-8f || lookAhead <= 0) direction = p.tangent * sign;
            p.position += p.Right * positionOffset.x + p.up * positionOffset.y + p.tangent * positionOffset.z;
            if (orientation == PathOrientation.Upright)
            {
                direction = Vector3.ProjectOnPlane(direction, Vector3.up);
                if (direction.sqrMagnitude < 1e-8f) direction = Vector3.ProjectOnPlane(p.up, Vector3.up);
                if (direction.sqrMagnitude < 1e-8f) direction = Vector3.forward;
                p.tangent = direction.normalized;
                p.up = Vector3.up;
                return p;
            }
            p.tangent = direction.normalized;
            p.up = BezierPath.Perpendicular(p.tangent, orientation == PathOrientation.WorldUp ? Vector3.up : p.up);
            float bank = -Vector3.SignedAngle(path.Evaluate(distance).tangent * sign, ahead.tangent * sign, p.up) * motionSpeed * bankStrength;
            p.up = Quaternion.AngleAxis(Mathf.Clamp(bank, -maxBank, maxBank), p.tangent) * p.up;
            return p;
        }
        public static Vector3 AxisVector(PathModelAxis axis)
        {
            switch (axis)
            {
                case PathModelAxis.PositiveZ: return Vector3.forward;
                case PathModelAxis.PositiveY: return Vector3.up;
                case PathModelAxis.PositiveX: return Vector3.right;
                case PathModelAxis.NegativeZ: return Vector3.back;
                case PathModelAxis.NegativeY: return Vector3.down;
                case PathModelAxis.NegativeX: return Vector3.left;
                default: throw new ArgumentOutOfRangeException(nameof(axis));
            }
        }
        public Quaternion RotationFor(PathSample sample)
        {
            Vector3 forward = AxisVector(modelForward), up = AxisVector(modelUp);
            if (Mathf.Abs(Vector3.Dot(forward, up)) > .5f)
                throw new InvalidOperationException("Model forward and up axes must be perpendicular. / 模型前向与上方向需垂直。");
            return sample.Rotation * Quaternion.Euler(rotationOffset) * Quaternion.Inverse(Quaternion.LookRotation(forward, up));
        }
        public void ApplyProgress(float value) { ApplyPose(PoseAtProgress(value), 0); }
        public void Apply(double seconds, float deltaTime = 0) { ApplyPose(PoseAt(seconds), deltaTime); }
        public void ApplySequencePose(PathSequencePose pose, bool rotation = true)
        {
            transform.position = pose.position;
            if (rotation) transform.rotation = pose.rotation;
        }
        void ApplyPose(PathSample p, float deltaTime)
        {
            if (orientation != PathOrientation.PositionOnly)
            {
                var rotation = RotationFor(p);
                transform.rotation = deltaTime > 0 && turnSmoothing > 0 ? Quaternion.Slerp(transform.rotation, rotation, 1 - Mathf.Exp(-turnSmoothing * deltaTime)) : rotation;
            }
            transform.position = p.position;
        }
    }
}
