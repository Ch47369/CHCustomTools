using System;
using UnityEngine;

namespace CH.CustomTools.VFX
{
    public enum RhythmChannel { Envelope, Low, Mid, High, Onset, Pulse }

    [Serializable]
    public sealed class RhythmAnalysisSettings
    {
        public int samplesPerSecond = 100;
        public int fftSize = 2048;
        public float noiseFloorDb = -55;
        public float attack = .015f;
        public float release = .16f;
        public float sensitivity = 1.35f;
        public float minimumOnsetStrength = .15f;
        public float minimumBeatInterval = .18f;
        public float pulseAttack = .012f;
        public float pulseRelease = .25f;
        public float compressionError = .008f;

        public RhythmAnalysisSettings Copy() { return (RhythmAnalysisSettings)MemberwiseClone(); }

        public void Validate()
        {
            samplesPerSecond = Mathf.Clamp(samplesPerSecond, 25, 200);
            if (fftSize != 512 && fftSize != 1024 && fftSize != 2048 && fftSize != 4096) fftSize = 2048;
            noiseFloorDb = Mathf.Clamp(noiseFloorDb, -90, -12);
            attack = Mathf.Clamp(attack, 0, 1);
            release = Mathf.Clamp(release, .005f, 3);
            sensitivity = Mathf.Clamp(sensitivity, .5f, 4);
            minimumOnsetStrength = Mathf.Clamp(minimumOnsetStrength, .01f, 1);
            minimumBeatInterval = Mathf.Clamp(minimumBeatInterval, .04f, 2);
            pulseAttack = Mathf.Clamp(pulseAttack, 0, .3f);
            pulseRelease = Mathf.Clamp(pulseRelease, .02f, 3);
            compressionError = Mathf.Clamp(compressionError, .0001f, .05f);
        }
    }

    [Serializable]
    public struct RhythmBeat
    {
        public float time;
        public float strength;
        public bool accent;

        public RhythmBeat(float time, float strength, bool accent)
        {
            this.time = time;
            this.strength = strength;
            this.accent = accent;
        }
    }

    /// <summary>Editor authoring data. Export native AnimationClips / particle curves for builds.</summary>
    public sealed class RhythmCurveProfile : ScriptableObject
    {
        [SerializeField] private AudioClip source;
        [SerializeField] private RhythmAnalysisSettings settings = new RhythmAnalysisSettings();
        [SerializeField] private float duration;
        [SerializeField] private float estimatedBpm;
        [SerializeField] private float tempoConfidence;
        [SerializeField] private int sourceFrames;
        [SerializeField] private int sourceFrequency;
        [SerializeField] private int sourceChannels;
        [SerializeField] private string sourceDependencyHash;
        [SerializeField] private AnimationCurve envelope = new AnimationCurve();
        [SerializeField] private AnimationCurve low = new AnimationCurve();
        [SerializeField] private AnimationCurve mid = new AnimationCurve();
        [SerializeField] private AnimationCurve high = new AnimationCurve();
        [SerializeField] private AnimationCurve onset = new AnimationCurve();
        [SerializeField] private AnimationCurve pulse = new AnimationCurve();
        [SerializeField] private RhythmBeat[] beats = new RhythmBeat[0];

        public AudioClip Source { get { return source; } }
        public RhythmAnalysisSettings Settings { get { return settings; } }
        public float Duration { get { return duration; } }
        public float EstimatedBpm { get { return estimatedBpm; } }
        public float TempoConfidence { get { return tempoConfidence; } }
        public int SourceFrames { get { return sourceFrames; } }
        public int SourceFrequency { get { return sourceFrequency; } }
        public int SourceChannels { get { return sourceChannels; } }
        public string SourceDependencyHash { get { return sourceDependencyHash; } }
        public RhythmBeat[] Beats { get { return beats; } }

        public AnimationCurve GetCurve(RhythmChannel channel)
        {
            switch (channel)
            {
                case RhythmChannel.Low: return low;
                case RhythmChannel.Mid: return mid;
                case RhythmChannel.High: return high;
                case RhythmChannel.Onset: return onset;
                case RhythmChannel.Pulse: return pulse;
                default: return envelope;
            }
        }

        public void SetCurve(RhythmChannel channel, AnimationCurve curve)
        {
            if (curve == null || curve.length < 2) throw new ArgumentException(CHToolLanguage.Text("曲线至少需要两个关键帧。"));
            switch (channel)
            {
                case RhythmChannel.Low: low = curve; break;
                case RhythmChannel.Mid: mid = curve; break;
                case RhythmChannel.High: high = curve; break;
                case RhythmChannel.Onset: onset = curve; break;
                case RhythmChannel.Pulse: pulse = curve; break;
                default: envelope = curve; break;
            }
        }

        public void Initialize(AudioClip clip, RhythmAnalysisSettings analysisSettings, RhythmAnalysisResult result, string dependencyHash)
        {
            source = clip;
            settings = analysisSettings.Copy();
            duration = result.duration;
            estimatedBpm = result.estimatedBpm;
            tempoConfidence = result.tempoConfidence;
            sourceFrames = clip != null ? clip.samples : 0;
            sourceFrequency = clip != null ? clip.frequency : 0;
            sourceChannels = clip != null ? clip.channels : 0;
            sourceDependencyHash = dependencyHash;
            envelope = result.curves[0]; low = result.curves[1]; mid = result.curves[2];
            high = result.curves[3]; onset = result.curves[4]; pulse = result.curves[5];
            beats = result.beats;
        }
    }
}
