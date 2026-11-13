using UnityEditor;
using UnityEngine;

namespace ASEShaderConverter.Editor
{
    /// <summary>Shared title treatment for every page in the tool collection.</summary>
    internal static class CHFeatureHeader
    {
        static GUIStyle title;
        static bool darkSkin;

        internal static void Draw(string section, string feature)
        {
            if (title == null || darkSkin != EditorGUIUtility.isProSkin)
            {
                darkSkin = EditorGUIUtility.isProSkin;
                title = new GUIStyle(EditorStyles.boldLabel)
                {
                    fontSize = 20,
                    richText = true,
                    wordWrap = true,
                    alignment = TextAnchor.MiddleLeft,
                    padding = new RectOffset(0, 0, 2, 2)
                };
            }
            var color = GUI.color;
            var contentColor = GUI.contentColor;
            try
            {
                GUI.color = Color.white;
                GUI.contentColor = Color.white;
                GUILayout.Space(8);
                GUILayout.Label("<color=#FFFFFF>" + section + "  /  </color><color=#FF7711>" + feature + "</color>",
                    title, GUILayout.MinHeight(28), GUILayout.ExpandWidth(true));
                GUILayout.Space(4);
            }
            finally
            {
                GUI.color = color;
                GUI.contentColor = contentColor;
            }
        }
    }
}
