using System;
using System.Collections.Generic;
using UnityEngine;

namespace CH.CustomTools.Paths
{
    public enum PathSequenceKind { Path, Hold }
    public enum PathSequenceConnection { Direct, Smooth }
    public enum PathSequenceOrientation { Inherit, Transported, WorldUp, PositionOnly, Upright }

    [Serializable]
    public sealed class PathSequenceStage
    {
        public PathSequenceKind kind;
        public BezierPath path;
        [Min(.01f)] public float duration = 5;
        public bool reverse;
        public AnimationCurve timing = AnimationCurve.Linear(0, 0, 1, 1);
        public PathSequenceOrientation orientation;
        public PathSequenceConnection connection;
        [Min(.01f)] public float transitionDuration = 1;
        public bool turnToNext;
    }

    public struct PathSequencePose
    {
        public Vector3 position, tangent;
        public Quaternion rotation;
    }

    /// <summary>A deterministic world-space schedule, shared by playback, preview and baking.</summary>
    public sealed class PathSequenceTimeline
    {
        public sealed class Track
        {
            public int StageIndex { get; internal set; }
            public float Start { get; internal set; }
            public float Duration { get; internal set; }
            public bool Transition { get; internal set; }
            public bool Hold { get; internal set; }
            internal PathSequenceStage stage;
            internal PathSequencePose first, last;
            public float End => Start + Duration;
        }

        readonly PathFollower follower;
        readonly List<Track> tracks = new List<Track>();
        public IReadOnlyList<Track> Tracks => tracks;
        public float Duration { get; private set; }
        public bool HasRotation { get; private set; }
        public PathSequencePose StartPose => tracks[0].first;
        public PathSequencePose EndPose => tracks[tracks.Count - 1].last;

        public PathSequenceTimeline(PathFollower follower, Quaternion initialRotation)
        {
            this.follower = follower;
            if (follower == null || follower.sequence == null || follower.sequence.Count == 0 || follower.sequence.Count > 128)
                throw new ArgumentException("Add 1–128 motion stages. / 请添加 1–128 个运动阶段。");
            if (follower.sequence[0] == null || follower.sequence[0].kind != PathSequenceKind.Path)
                throw new ArgumentException("The sequence must begin with a path. / 序列首段须为路径。");
            for (int i = 0; i < follower.sequence.Count; i++)
            {
                var stage = follower.sequence[i];
                if (stage == null || !ValidDuration(stage.duration))
                    throw StageError(i, "Invalid duration. / 时长无效。");
                if (stage.kind == PathSequenceKind.Hold) continue;
                if (stage.path == null || stage.path.transform.IsChildOf(follower.transform))
                    throw StageError(i, "Choose a separate path. / 请指定独立路径。");
                if (stage.path.gameObject.scene != follower.gameObject.scene)
                    throw StageError(i, "The path and target must be in the same scene. / 路径与目标需在同一场景。");
                if (stage.timing == null || Mathf.Abs(stage.timing.Evaluate(0)) > .0001f ||
                    Mathf.Abs(stage.timing.Evaluate(1) - 1) > .0001f)
                    throw StageError(i, "Timing curve must start at (0, 0) and end at (1, 1). / 进度曲线首尾须为 (0, 0) 与 (1, 1)。");
                stage.path.ValidatePath();
            }

            PathSequencePose previous = new PathSequencePose { rotation = initialRotation };
            for (int i = 0; i < follower.sequence.Count; i++)
            {
                var stage = follower.sequence[i];
                if (stage.kind == PathSequenceKind.Hold)
                {
                    var end = previous;
                    if (stage.turnToNext)
                    {
                        for (int j = i + 1; j < follower.sequence.Count; j++)
                        {
                            var next = follower.sequence[j];
                            if (next.kind != PathSequenceKind.Path) continue;
                            end.rotation = PathPose(next, 0, previous.rotation).rotation;
                            HasRotation |= Orientation(next) != PathOrientation.PositionOnly;
                            break;
                        }
                    }
                    Add(i, stage.duration, previous, end, stage, true, false);
                    previous = end;
                    continue;
                }
                var first = PathPose(stage, 0, previous.rotation);
                var last = PathPose(stage, 1, first.rotation);
                HasRotation |= Orientation(stage) != PathOrientation.PositionOnly;
                if (i > 0)
                {
                    if (stage.connection == PathSequenceConnection.Smooth)
                    {
                        if (!ValidDuration(stage.transitionDuration)) throw StageError(i, "Invalid transition time. / 过渡时长无效。");
                        Add(i, stage.transitionDuration, previous, first, stage, false, true);
                    }
                    else if (Vector3.Distance(previous.position, first.position) > .001f)
                        throw StageError(i, "Path endpoints are separated. Connect them or choose Smooth transition. / 路径端点未连接，请连接端点或选择平滑过渡。");
                }
                Add(i, stage.duration, first, last, stage, false, false);
                previous = last;
            }
        }

        static bool ValidDuration(float value) => float.IsFinite(value) && value >= .01f && value <= 3600;
        static Exception StageError(int index, string message) => new ArgumentException("[" + (index + 1) + "] " + message);
        PathOrientation Orientation(PathSequenceStage stage) => stage.orientation == PathSequenceOrientation.Inherit
            ? follower.orientation : (PathOrientation)((int)stage.orientation - 1);

        PathSequencePose PathPose(PathSequenceStage stage, float progress, Quaternion heldRotation)
        {
            var orientation = Orientation(stage);
            float length = stage.path.Length;
            float distance = (stage.reverse ? 1 - progress : progress) * length;
            var sample = follower.PoseOnPath(stage.path, distance, stage.reverse, length / stage.duration, orientation);
            return new PathSequencePose
            {
                position = sample.position,
                tangent = stage.path.Evaluate(distance).tangent * (stage.reverse ? -1 : 1),
                rotation = orientation == PathOrientation.PositionOnly ? heldRotation : follower.RotationFor(sample)
            };
        }

        void Add(int index, float duration, PathSequencePose first, PathSequencePose last,
            PathSequenceStage stage, bool hold, bool transition)
        {
            tracks.Add(new Track { StageIndex = index, Start = Duration, Duration = duration,
                first = first, last = last, stage = stage, Hold = hold, Transition = transition });
            Duration += duration;
        }

        public PathSequencePose Evaluate(float time)
        {
            if (!float.IsFinite(time)) throw new ArgumentException("Invalid sequence time.");
            if (time <= 0) return StartPose;
            if (time >= Duration) return EndPose;
            int low = 0, high = tracks.Count - 1;
            while (low < high)
            {
                int middle = (low + high) / 2;
                if (time < tracks[middle].End) high = middle;
                else low = middle + 1;
            }
            var track = tracks[low];
            float u = Mathf.Clamp01((time - track.Start) / track.Duration);
            if (!track.Hold && !track.Transition)
                return PathPose(track.stage, Mathf.Clamp01(track.stage.timing.Evaluate(u)), track.first.rotation);
            if (track.Hold)
                return new PathSequencePose { position = track.first.position, tangent = track.first.tangent,
                    rotation = Quaternion.Slerp(track.first.rotation, track.last.rotation, Mathf.SmoothStep(0, 1, u)) };
            return Bridge(track, u);
        }

        static PathSequencePose Bridge(Track track, float u)
        {
            var a = track.first;
            var b = track.last;
            float length = Vector3.Distance(a.position, b.position) / 3;
            Vector3 h1 = a.position + a.tangent.normalized * length;
            Vector3 h2 = b.position - b.tangent.normalized * length;
            Vector3 p = Vector3.Lerp(a.position, h1, u);
            Vector3 q = Vector3.Lerp(h1, h2, u);
            Vector3 r = Vector3.Lerp(h2, b.position, u);
            Vector3 x = Vector3.Lerp(p, q, u), y = Vector3.Lerp(q, r, u);
            Vector3 tangent = y - x;
            return new PathSequencePose
            {
                position = Vector3.Lerp(x, y, u),
                tangent = tangent.sqrMagnitude > 1e-8f ? tangent.normalized : Vector3.Slerp(a.tangent, b.tangent, u),
                rotation = Quaternion.Slerp(a.rotation, b.rotation, Mathf.SmoothStep(0, 1, u))
            };
        }
    }
}
