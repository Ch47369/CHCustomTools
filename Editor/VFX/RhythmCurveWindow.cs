using UnityEditor;
using UnityEngine;
using ASEShaderConverter.Editor;

namespace CH.CustomTools.VFX
{
    // Asset and context entry points always select a panel in the host window.
    public static class RhythmCurveWindow
    {
        public static string PluginFolder
        {
            get
            {
                var package = UnityEditor.PackageManager.PackageInfo.FindForAssembly(typeof(RhythmCurveWindow).Assembly);
                if (package != null) return package.assetPath + "/Editor/VFX";
                foreach (string guid in AssetDatabase.FindAssets("RhythmCurveWindow t:MonoScript"))
                {
                    string path = AssetDatabase.GUIDToAssetPath(guid);
                    if (path.EndsWith("/VFX/RhythmCurveWindow.cs", System.StringComparison.Ordinal))
                        return System.IO.Path.GetDirectoryName(path).Replace('\\', '/');
                }
                throw new System.InvalidOperationException("CH custom tools audio module was not found.");
            }
        }
        public static void Open() { ASEShaderConverterWindow.OpenAudio(); }
        [UnityEditor.Callbacks.OnOpenAsset]
        private static bool OpenProfile(int instanceId, int line)
        {
            var saved = EditorUtility.InstanceIDToObject(instanceId) as RhythmCurveProfile;
            if (saved == null) return false;
            ASEShaderConverterWindow.OpenAudio(saved);
            return true;
        }
        [MenuItem("Assets/CH自定义工具集/VFX/分析音频节奏", true)]
        private static bool CanAnalyzeSelection() { return Selection.activeObject is AudioClip; }
        [MenuItem("Assets/CH自定义工具集/VFX/分析音频节奏")]
        private static void AnalyzeSelection() { ASEShaderConverterWindow.AnalyzeAudio(Selection.activeObject as AudioClip); }
    }
    public static class VfxResourceOrganizerWindow
    {
        public static void Open() { ASEShaderConverterWindow.OpenOrganizer(); }
        [MenuItem("Assets/CH自定义工具集/VFX/特效资源整理")]
        [MenuItem("GameObject/CH自定义工具集/VFX/特效资源整理", false, 30)]
        private static void OpenSelection() { ASEShaderConverterWindow.OpenOrganizer(true); }
    }
}
