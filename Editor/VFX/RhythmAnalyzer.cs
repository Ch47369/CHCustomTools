using System;
using System.Collections.Generic;
using UnityEngine;

namespace CH.CustomTools.VFX
{
    public sealed class RhythmAnalysisResult
    {
        public float duration;
        public float estimatedBpm;
        public float tempoConfidence;
        public AnimationCurve[] curves;
        public RhythmBeat[] beats;
    }

    /// <summary>Offline channel-safe FFT analysis. All output time coordinates are seconds.</summary>
    public static class RhythmAnalyzer
    {
        public delegate bool Progress(float amount);

        public static RhythmAnalysisResult Analyze(AudioClip clip, RhythmAnalysisSettings settings, Progress progress = null)
        {
            if (clip == null) throw new ArgumentNullException(nameof(clip));
            if (clip.loadType != AudioClipLoadType.DecompressOnLoad)
                throw new InvalidOperationException(CHToolLanguage.Text("此音频使用 Streaming / Compressed In Memory，无法直接读取 PCM。请点击“创建解压分析副本”，原音频保持不变。"));
            if (clip.loadState != AudioDataLoadState.Loaded && !clip.LoadAudioData())
                throw new InvalidOperationException(CHToolLanguage.Text("无法读取音频数据。请将 Load Type 设为 Decompress On Load 后重试。"));
            if (clip.loadState != AudioDataLoadState.Loaded)
                throw new InvalidOperationException(CHToolLanguage.Text("音频数据仍在加载，请稍后重试；Streaming 音频请使用独立的解压分析副本。"));
            var reader = new ClipReader(clip);
            return Analyze(reader.Get, clip.samples, clip.channels, clip.frequency, settings, progress);
        }

        // Also used by the self-check with deterministic synthetic PCM, without creating assets.
        public static RhythmAnalysisResult Analyze(float[] pcm, int channels, int frequency, RhythmAnalysisSettings settings, Progress progress = null)
        {
            if (pcm == null || channels < 1 || frequency < 1000 || pcm.Length == 0 || pcm.Length % channels != 0)
                throw new ArgumentException("Invalid interleaved PCM.");
            int frames = pcm.Length / channels;
            return Analyze((frame, channel) => frame < 0 || frame >= frames ? 0 : pcm[frame * channels + channel],
                frames, channels, frequency, settings, progress);
        }

        private sealed class ClipReader
        {
            private readonly AudioClip clip;
            private readonly float[] block;
            private readonly int blockFrames;
            private int start = -1;

            public ClipReader(AudioClip clip)
            {
                this.clip = clip;
                blockFrames = Math.Min(32768, clip.samples);
                block = new float[blockFrames * clip.channels];
            }

            public float Get(int frame, int channel)
            {
                if (frame < 0 || frame >= clip.samples) return 0;
                if (start < 0 || frame < start || frame >= start + blockFrames)
                {
                    start = Math.Min(frame, clip.samples - blockFrames);
                    if (!clip.GetData(block, start))
                        throw new InvalidOperationException(CHToolLanguage.Text("AudioClip.GetData 失败。请用 Decompress On Load 分析；工具不会修改原音频导入设置。"));
                }
                return block[(frame - start) * clip.channels + channel];
            }
        }

        private static RhythmAnalysisResult Analyze(Func<int, int, float> read, int frames, int channels, int frequency,
            RhythmAnalysisSettings supplied, Progress progress)
        {
            if (supplied == null) throw new ArgumentNullException(nameof(supplied));
            var settings = supplied.Copy();
            settings.Validate();
            float duration = (float)frames / frequency;
            int count = Mathf.CeilToInt(duration * settings.samplesPerSecond) + 1;
            if (count > 240001) throw new InvalidOperationException(CHToolLanguage.Text("曲线采样点超过 240,000，请降低采样率或拆分音频。"));
            int size = settings.fftSize;
            var values = new float[6][];
            for (int c = 0; c < values.Length; c++) values[c] = new float[count];
            var real = new double[size];
            var imag = new double[size];
            var powers = new double[size / 2 + 1];
            var previous = new double[powers.Length];
            var window = new double[size];
            double windowEnergy = 0;
            for (int i = 0; i < size; i++)
            {
                window[i] = .5 - .5 * Math.Cos(2 * Math.PI * i / (size - 1));
                windowEnergy += window[i] * window[i];
            }
            float floor = Mathf.Pow(10, settings.noiseFloorDb / 20);
            for (int step = 0; step < count; step++)
            {
                if (step % 32 == 0 && progress != null && progress((float)step / count)) throw new OperationCanceledException();
                double sum = 0;
                Array.Clear(powers, 0, powers.Length);
                int center = Mathf.RoundToInt(Math.Min(duration, (float)step / settings.samplesPerSecond) * frequency);
                for (int ch = 0; ch < channels; ch++)
                {
                    for (int i = 0; i < size; i++)
                    {
                        float sample = read(center + i - size / 2, ch);
                        if (float.IsNaN(sample) || float.IsInfinity(sample)) sample = 0;
                        real[i] = sample * window[i];
                        imag[i] = 0;
                        sum += real[i] * real[i];
                    }
                    Fourier(real, imag);
                    for (int bin = 1; bin < powers.Length; bin++)
                        powers[bin] += (real[bin] * real[bin] + imag[bin] * imag[bin]) / channels;
                }
                float rms = (float)Math.Sqrt(sum / (channels * windowEnergy));
                values[0][step] = rms > floor ? rms : 0;
                double low = 0, mid = 0, high = 0, flux = 0;
                for (int bin = 1; bin < powers.Length; bin++)
                {
                    double hz = (double)bin * frequency / size;
                    double power = powers[bin] / (size * windowEnergy);
                    if (hz >= 20 && hz < 250) low += power;
                    else if (hz >= 250 && hz < 2000) mid += power;
                    else if (hz >= 2000 && hz <= 16000) high += power;
                    double magnitude = Math.Log(1 + Math.Sqrt(power) * 100);
                    if (hz >= 40 && hz <= 16000) flux += Math.Max(0, magnitude - previous[bin]);
                    previous[bin] = magnitude;
                }
                if (rms > floor)
                {
                    values[1][step] = (float)Math.Sqrt(low);
                    values[2][step] = (float)Math.Sqrt(mid);
                    values[3][step] = (float)Math.Sqrt(high);
                    values[4][step] = (float)flux;
                }
            }
            // Frequency bands share one reference so leakage / tiny noise is never boosted to full scale.
            float energyReference = Math.Max(floor, Percentile(values[0], .98f));
            for (int c = 0; c < 4; c++)
            {
                Normalize(values[c], energyReference, c == 0 ? floor : floor * .5f);
            }
            Normalize(values[4], Math.Max(.00001f, Percentile(values[4], .98f)), 0);
            RhythmBeat[] beats = DetectBeats(values[4], values[0], settings, duration);
            for (int c = 0; c < 4; c++) Smooth(values[c], settings.attack, settings.release, settings.samplesPerSecond);
            Smooth(values[4], 0, .035f, settings.samplesPerSecond);
            // Pulses begin at the detected attack; do not rise before the note.
            foreach (RhythmBeat beat in beats)
            {
                int first = Mathf.CeilToInt(beat.time * settings.samplesPerSecond);
                int last = Math.Min(count - 1, Mathf.CeilToInt((beat.time + settings.pulseAttack + settings.pulseRelease) * settings.samplesPerSecond));
                for (int i = first; i <= last; i++)
                {
                    float age = (float)i / settings.samplesPerSecond - beat.time;
                    float pulse = age < settings.pulseAttack && settings.pulseAttack > 0
                        ? age / settings.pulseAttack
                        : Mathf.Pow(Mathf.Clamp01(1 - (age - settings.pulseAttack) / settings.pulseRelease), 2);
                    values[5][i] = Math.Max(values[5][i], pulse * beat.strength);
                }
            }
            float bpm, confidence;
            EstimateTempo(beats, out bpm, out confidence);
            var curves = new AnimationCurve[6];
            for (int c = 0; c < curves.Length; c++)
            {
                // A one-shot curve always closes at the exact audio end.
                values[c][count - 1] = 0;
                curves[c] = Compress(values[c], settings.samplesPerSecond, duration, settings.compressionError);
            }
            if (progress != null && progress(1)) throw new OperationCanceledException();
            return new RhythmAnalysisResult { duration = duration, curves = curves, beats = beats, estimatedBpm = bpm, tempoConfidence = confidence };
        }

        private static void Fourier(double[] real, double[] imag)
        {
            int n = real.Length;
            for (int i = 1, j = 0; i < n; i++)
            {
                int bit = n >> 1;
                for (; (j & bit) != 0; bit >>= 1) j ^= bit;
                j ^= bit;
                if (i >= j) continue;
                double value = real[i]; real[i] = real[j]; real[j] = value;
            }
            for (int length = 2; length <= n; length <<= 1)
            {
                double angle = -2 * Math.PI / length;
                double wrStep = Math.Cos(angle), wiStep = Math.Sin(angle);
                for (int start = 0; start < n; start += length)
                {
                    double wr = 1, wi = 0;
                    for (int j = 0; j < length / 2; j++)
                    {
                        int a = start + j, b = a + length / 2;
                        double tr = real[b] * wr - imag[b] * wi, ti = real[b] * wi + imag[b] * wr;
                        real[b] = real[a] - tr; imag[b] = imag[a] - ti;
                        real[a] += tr; imag[a] += ti;
                        double next = wr * wrStep - wi * wiStep;
                        wi = wr * wiStep + wi * wrStep; wr = next;
                    }
                }
            }
        }

        private static float Percentile(float[] values, float percentile)
        {
            var nonzero = new List<float>();
            foreach (float value in values) if (value > .0000001f) nonzero.Add(value);
            if (nonzero.Count == 0) return 0;
            nonzero.Sort();
            return nonzero[Mathf.Clamp(Mathf.RoundToInt((nonzero.Count - 1) * percentile), 0, nonzero.Count - 1)];
        }

        private static void Normalize(float[] values, float reference, float floor)
        {
            if (reference < .0000001f) { Array.Clear(values, 0, values.Length); return; }
            for (int i = 0; i < values.Length; i++) values[i] = values[i] <= floor ? 0 : Mathf.Clamp01(values[i] / reference);
        }

        private static void Smooth(float[] values, float attack, float release, int fps)
        {
            float rise = attack <= 0 ? 0 : Mathf.Exp(-1f / (fps * attack));
            float fall = Mathf.Exp(-1f / (fps * release));
            float last = 0;
            for (int i = 0; i < values.Length; i++)
            {
                float coefficient = values[i] > last ? rise : fall;
                last = values[i] * (1 - coefficient) + last * coefficient;
                values[i] = last;
            }
        }

        private static RhythmBeat[] DetectBeats(float[] onset, float[] energy, RhythmAnalysisSettings settings, float duration)
        {
            var candidates = new List<RhythmBeat>();
            int radius = Math.Max(2, Mathf.RoundToInt(.25f * settings.samplesPerSecond));
            for (int i = 0; i < onset.Length - 1; i++)
            {
                if (onset[i] < settings.minimumOnsetStrength || energy[i] < .015f || (i > 0 && onset[i] < onset[i - 1]) || onset[i] <= onset[i + 1]) continue;
                int start = Math.Max(0, i - radius), end = Math.Min(onset.Length - 1, i + radius);
                double mean = 0;
                for (int k = start; k <= end; k++) mean += onset[k];
                mean /= end - start + 1;
                if (onset[i] < Math.Max(.06, mean * settings.sensitivity)) continue;
                float time = (float)i / settings.samplesPerSecond;
                if (time >= duration) continue;
                var beat = new RhythmBeat(time, Mathf.Clamp01(.7f * onset[i] + .3f * energy[i]), false);
                if (candidates.Count > 0 && time - candidates[candidates.Count - 1].time < settings.minimumBeatInterval)
                {
                    if (beat.strength > candidates[candidates.Count - 1].strength) candidates[candidates.Count - 1] = beat;
                }
                else candidates.Add(beat);
            }
            var strengths = new float[candidates.Count];
            for (int i = 0; i < strengths.Length; i++) strengths[i] = candidates[i].strength;
            float accent = Percentile(strengths, .72f);
            for (int i = 0; i < candidates.Count; i++)
            {
                var beat = candidates[i]; beat.accent = beat.strength >= accent; candidates[i] = beat;
            }
            return candidates.ToArray();
        }

        private static void EstimateTempo(RhythmBeat[] beats, out float bpm, out float confidence)
        {
            bpm = 0; confidence = 0;
            if (beats.Length < 4) return;
            var intervals = new List<float>();
            for (int i = 1; i < beats.Length; i++)
            {
                float interval = beats[i].time - beats[i - 1].time;
                while (interval < .333333f) interval *= 2;
                while (interval > 1) interval *= .5f;
                intervals.Add(interval);
            }
            intervals.Sort();
            float median = intervals[intervals.Count / 2];
            int agree = 0;
            foreach (float interval in intervals) if (Mathf.Abs(interval - median) / median < .12f) agree++;
            bpm = 60 / median;
            confidence = (float)agree / intervals.Count;
        }

        public static AnimationCurve Compress(float[] values, int fps, float duration, float tolerance)
        {
            var keep = new bool[values.Length];
            keep[0] = true; keep[values.Length - 1] = true;
            var stack = new Stack<int>();
            stack.Push(0); stack.Push(values.Length - 1);
            while (stack.Count > 0)
            {
                int end = stack.Pop(), start = stack.Pop(), split = -1;
                float largest = tolerance;
                float ta = Math.Min(duration, (float)start / fps), tb = Math.Min(duration, (float)end / fps);
                for (int i = start + 1; i < end; i++)
                {
                    float time = Math.Min(duration, (float)i / fps);
                    float line = Mathf.Lerp(values[start], values[end], (time - ta) / Math.Max(.000001f, tb - ta));
                    float error = Mathf.Abs(values[i] - line);
                    if (error > largest) { largest = error; split = i; }
                }
                if (split < 0) continue;
                keep[split] = true;
                stack.Push(start); stack.Push(split); stack.Push(split); stack.Push(end);
            }
            var keys = new List<Keyframe>();
            for (int i = 0; i < keep.Length; i++) if (keep[i]) keys.Add(new Keyframe(Math.Min(duration, (float)i / fps), values[i]));
            return Linear(keys.ToArray());
        }

        public static AnimationCurve Linear(Keyframe[] keys)
        {
            for (int i = 0; i < keys.Length; i++)
            {
                var key = keys[i];
                key.inTangent = i == 0 ? 0 : (key.value - keys[i - 1].value) / Math.Max(.000001f, key.time - keys[i - 1].time);
                key.outTangent = i == keys.Length - 1 ? 0 : (keys[i + 1].value - key.value) / Math.Max(.000001f, keys[i + 1].time - key.time);
                key.weightedMode = WeightedMode.None;
                keys[i] = key;
            }
            return new AnimationCurve(keys) { preWrapMode = WrapMode.ClampForever, postWrapMode = WrapMode.ClampForever };
        }
    }
}
