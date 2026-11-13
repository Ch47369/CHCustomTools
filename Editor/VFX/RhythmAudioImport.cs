using System;
using System.IO;
using UnityEditor;
using UnityEngine;

namespace CH.CustomTools.VFX
{
    public static class RhythmAudioImport
    {
        public static AudioClip CreateAnalysisCopy(AudioClip source)
        {
            if (source == null) throw new ArgumentNullException(nameof(source));
            string original = AssetDatabase.GetAssetPath(source);
            if (string.IsNullOrEmpty(original) || AssetImporter.GetAtPath(original) == null)
                throw new InvalidOperationException(CHToolLanguage.Text("需要已导入的磁盘音频资源。"));
            string parent = RhythmCurveWindow.PluginFolder;
            if (!parent.StartsWith("Assets/", StringComparison.Ordinal)) parent = "Assets/AudioRhythmCurves/Editor";
            string folder = parent + "/AnalysisCopies";
            EnsureFolder(folder);
            string path = AssetDatabase.GenerateUniqueAssetPath(folder + "/" + Path.GetFileNameWithoutExtension(original) + "_Analysis" + Path.GetExtension(original));
            if (!AssetDatabase.CopyAsset(original, path)) throw new InvalidOperationException(CHToolLanguage.Text("无法创建音频分析副本。"));
            var importer = AssetImporter.GetAtPath(path) as AudioImporter;
            if (importer == null) throw new InvalidOperationException(CHToolLanguage.Text("副本未被识别为 AudioImporter：") + path);
            var settings = importer.defaultSampleSettings;
            settings.loadType = AudioClipLoadType.DecompressOnLoad;
            settings.compressionFormat = AudioCompressionFormat.PCM;
            settings.sampleRateSetting = AudioSampleRateSetting.PreserveSampleRate;
            settings.preloadAudioData = true;
            importer.defaultSampleSettings = settings;
            // Only the new copy is changed. Remove the common target-specific load overrides.
            foreach (string platform in new[] { "Standalone", "Android", "iPhone", "WebGL" })
                if (importer.ContainsSampleSettingsOverride(platform)) importer.ClearSampleSettingOverride(platform);
            importer.loadInBackground = false;
            importer.SaveAndReimport();
            var copy = AssetDatabase.LoadAssetAtPath<AudioClip>(path);
            if (copy == null || copy.loadType != AudioClipLoadType.DecompressOnLoad)
                throw new InvalidOperationException(CHToolLanguage.Text("分析副本未能解压，请检查副本的当前平台音频覆盖设置：") + path);
            return copy;
        }

        private static void EnsureFolder(string path)
        {
            if (AssetDatabase.IsValidFolder(path)) return;
            string parent = Path.GetDirectoryName(path).Replace('\\', '/');
            EnsureFolder(parent);
            if (string.IsNullOrEmpty(AssetDatabase.CreateFolder(parent, Path.GetFileName(path))))
                throw new InvalidOperationException(CHToolLanguage.Text("无法创建音频分析目录：") + path);
        }
    }
}
