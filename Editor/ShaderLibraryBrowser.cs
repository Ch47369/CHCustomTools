using UnityEditor;

namespace ASEShaderConverter.Editor
{
    // Retained only so layouts and callers from older versions recover the tool window.
    public sealed class ShaderLibraryWindow : EditorWindow
    {
        public static void Open() { ASEShaderConverterWindow.OpenLibrary(); }
        public static void OpenCategory(string id) { ASEShaderConverterWindow.OpenLibrary(id); }
        void OnEnable() { EditorApplication.update += Redirect; }
        void OnDisable() { EditorApplication.update -= Redirect; }
        void Redirect()
        {
            if (this == null) return;
            Open();
            Close();
        }
    }
}
