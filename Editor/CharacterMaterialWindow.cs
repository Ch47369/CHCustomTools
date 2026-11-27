using UnityEditor;

namespace ASEShaderConverter.Editor
{
    // The former character-library window redirects persisted layouts to conversion.
    public sealed class CharacterMaterialWindow : EditorWindow
    {
        public static void Open() { ASEShaderConverterWindow.OpenLibrary(); }
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
