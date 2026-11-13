using System;
using System.Reflection;
using UnityEditor;
using UnityEngine;

namespace ASEShaderConverter.Editor
{
    // Both independently installable CH tools use the same key. No package dependency is required.
    [InitializeOnLoad]
    internal static partial class CHToolLanguage
    {
        internal const string PreferenceKey = "CH.CustomTools.Language";
        internal static readonly string[] Choices = { "中文", "English" };
        static readonly Type LocaleType = typeof(EditorWindow).Assembly.GetType("UnityEditor.LocalizationDatabase");
        static readonly PropertyInfo CurrentLanguage = LocaleType == null ? null : LocaleType.GetProperty("currentEditorLanguage", BindingFlags.Static | BindingFlags.Public | BindingFlags.NonPublic);
        static readonly PropertyInfo LocalizationEnabled = LocaleType == null ? null : LocaleType.GetProperty("enableEditorLocalization", BindingFlags.Static | BindingFlags.Public | BindingFlags.NonPublic);
        static bool chinese;
        static double nextPoll;
        internal static bool IsChinese { get { return chinese; } }
        internal static bool HasOverride { get { var value = EditorPrefs.GetString(PreferenceKey, ""); return value == "zh" || value == "en"; } }
        static CHToolLanguage()
        {
            // ScriptableObject field initializers may touch Text during deserialization.
            // Read EditorPrefs only after construction, on the Editor main loop.
            EditorApplication.delayCall += Refresh;
            EditorApplication.update += Poll;
        }
        // Read only these two known locale properties. Never change Unity's language settings.
        internal static bool EditorIsChinese()
        {
            try
            {
                if (CurrentLanguage == null || LocalizationEnabled == null || !(bool)LocalizationEnabled.GetValue(null, null)) return false;
                var language = (SystemLanguage)CurrentLanguage.GetValue(null, null);
                return language == SystemLanguage.Chinese || language == SystemLanguage.ChineseSimplified || language == SystemLanguage.ChineseTraditional;
            }
            catch (Exception) { return false; }
        }
        internal static bool Resolve(string preference, bool editorChinese)
        {
            return preference == "zh" || (preference != "en" && editorChinese);
        }
        static void Poll()
        {
            if (EditorApplication.timeSinceStartup < nextPoll) return;
            nextPoll = EditorApplication.timeSinceStartup + .5;
            Refresh();
        }
        internal static void Refresh()
        {
            bool value = Resolve(EditorPrefs.GetString(PreferenceKey, ""), EditorIsChinese());
            if (value == chinese) return;
            chinese = value;
            foreach (var window in Resources.FindObjectsOfTypeAll<EditorWindow>()) window.Repaint();
        }
        internal static void Set(bool useChinese)
        {
            EditorPrefs.SetString(PreferenceKey, useChinese ? "zh" : "en");
            Refresh();
        }
        internal static void Reset()
        {
            EditorPrefs.DeleteKey(PreferenceKey);
            Refresh();
        }
        // Text lookup is safe in worker tasks: the locale is cached on the main thread.
        internal static string Pick(string zh, string en) { return chinese ? zh : en; }
        internal static string Text(string value)
        {
            string english;
            return !chinese && value != null && English.TryGetValue(value, out english) ? english : value;
        }
        internal static string[] Text(string[] values) { return Array.ConvertAll(values, Text); }
        internal static string Text(bool useChinese, string value)
        {
            string english;
            return !useChinese && value != null && English.TryGetValue(value, out english) ? english : value;
        }
        internal static string[] Text(bool useChinese, string[] values) { return Array.ConvertAll(values, value => Text(useChinese, value)); }

        // Each plugin main window carries its own selector; all features share the saved preference.
        internal static void DrawLanguageSelector()
        {
            EditorGUILayout.BeginHorizontal();
            GUILayout.Label(new GUIContent(Pick("语言", "Language"), Pick("默认跟随 Unity；手动选择后保存。", "Follows Unity by default; manual choices are saved.")), GUILayout.Width(65));
            for (int i = 0; i < Choices.Length; i++)
            {
                bool selected = IsChinese == (i == 0);
                if (GUILayout.Toggle(selected, Choices[i], "Button", GUILayout.Width(75)) != selected) Set(i == 0);
            }
            GUILayout.FlexibleSpace();
            if (HasOverride && GUILayout.Button(Pick("恢复默认语言", "Reset language"), EditorStyles.miniButton, GUILayout.Width(130))) Reset();
            EditorGUILayout.EndHorizontal();
        }
    }

    internal sealed class CHToolMessage
    {
        readonly string zh, en;
        internal CHToolMessage(string zh, string en) { this.zh = zh; this.en = en; }
        public static implicit operator string(CHToolMessage message) { return message == null ? null : CHToolLanguage.Pick(message.zh, message.en); }
        public static implicit operator CHToolMessage(string message) { return new CHToolMessage(message, message); }
    }
}
