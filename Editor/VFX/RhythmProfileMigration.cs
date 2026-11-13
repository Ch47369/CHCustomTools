using System;
using System.IO;
using System.Text;
using UnityEditor;
using UnityEngine;

namespace CH.CustomTools.VFX
{
    /// <summary>Copies legacy text profiles without changing the source asset or its GUID.</summary>
    public static class RhythmProfileMigration
    {
        public const string LegacyScriptGuid = "55bb1d826081dee41b0e9307161c9516";
        public static RhythmCurveProfile CreateCopy(string path)
        {
            string full = Path.GetFullPath(path);
            string assets = Path.GetFullPath(Application.dataPath) + Path.DirectorySeparatorChar;
            if (!full.StartsWith(assets, StringComparison.OrdinalIgnoreCase) || !full.EndsWith(".asset", StringComparison.OrdinalIgnoreCase))
                throw new ArgumentException(CHToolLanguage.Pick("请选择当前项目 Assets 内的旧曲线 .asset 文件。", "Select a legacy curve .asset under this project's Assets folder."));
            byte[] original = File.ReadAllBytes(full);
            string text = new UTF8Encoding(false, true).GetString(original).TrimStart('\uFEFF');
            string oldScript = "m_Script: {fileID: 11500000, guid: " + LegacyScriptGuid + ", type: 3}";
            if (!text.StartsWith("%YAML", StringComparison.Ordinal) || !text.Contains(oldScript) ||
                text.IndexOf(oldScript, text.IndexOf(oldScript, StringComparison.Ordinal) + oldScript.Length, StringComparison.Ordinal) >= 0 ||
                !text.Contains("  sourceDependencyHash:") || !text.Contains("  envelope:") || !text.Contains("  pulse:") ||
                text.Split(new[] { "--- !u!" }, StringSplitOptions.None).Length != 2)
                throw new InvalidOperationException(CHToolLanguage.Pick("这不是支持的旧版文本曲线数据。若为二进制，请先在旧插件中重新保存为文本资源。", "This is not a supported legacy text profile. For binary assets, save as text using the standalone plugin first."));
            var probe = ScriptableObject.CreateInstance<RhythmCurveProfile>();
            string guid;
            try { guid = AssetDatabase.AssetPathToGUID(AssetDatabase.GetAssetPath(MonoScript.FromScriptableObject(probe))); }
            finally { UnityEngine.Object.DestroyImmediate(probe); }
            if (string.IsNullOrEmpty(guid)) throw new InvalidOperationException("The bundled profile script has not been imported.");
            string sourcePath = "Assets/" + full.Substring(assets.Length).Replace('\\', '/');
            string destination = AssetDatabase.GenerateUniqueAssetPath(Path.ChangeExtension(sourcePath, null) + "_CH.asset");
            // Replace only the ASCII script GUID, preserving all other bytes (including BOM and line endings).
            string raw = Encoding.UTF8.GetString(original);
            byte[] converted = Encoding.UTF8.GetBytes(raw.Replace(oldScript, oldScript.Replace(LegacyScriptGuid, guid)));
            using (var stream = new FileStream(destination, FileMode.CreateNew, FileAccess.Write, FileShare.None))
                stream.Write(converted, 0, converted.Length);
            AssetDatabase.ImportAsset(destination, ImportAssetOptions.ForceSynchronousImport);
            var result = AssetDatabase.LoadAssetAtPath<RhythmCurveProfile>(destination);
            if (result == null) throw new InvalidOperationException("The converted copy could not be loaded: " + destination + ". The original asset is preserved.");
            return result;
        }
        internal static void ChooseCopy()
        {
            string path = EditorUtility.OpenFilePanel(CHToolLanguage.Pick("选择旧版曲线数据（创建副本）", "Select legacy curve data (create a copy)"), Application.dataPath, "asset");
            if (string.IsNullOrEmpty(path)) return;
            try
            {
                var copy = CreateCopy(path);
                ASEShaderConverter.Editor.ASEShaderConverterWindow.OpenAudio(copy);
                EditorGUIUtility.PingObject(copy);
            }
            catch (Exception error) { EditorUtility.DisplayDialog(CHToolLanguage.Pick("曲线数据迁移", "Curve migration"), error.Message, "OK"); }
        }
    }
}
