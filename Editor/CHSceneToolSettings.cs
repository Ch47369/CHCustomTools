using System;
using CH.CustomTools.Measurement;
using CH.CustomTools.Paths.Editor;
using UnityEditor;
using UnityEngine;

namespace ASEShaderConverter.Editor
{
    [InitializeOnLoad]
    internal static class CHSceneToolSettings
    {
        const string Prefix = "CH.CustomTools.SceneShortcut.";
        const EventModifiers Mask = EventModifiers.Alt | EventModifiers.Control | EventModifiers.Shift | EventModifiers.Command;
        static KeyCode held;
        static bool loaded;
        static KeyCode measureKey = KeyCode.D, pathKey = KeyCode.S;
        static EventModifiers measureMods = EventModifiers.Alt, pathMods = EventModifiers.Alt;
        static string message;
        static CHSceneToolSettings()
        {
            SceneView.duringSceneGui += OnSceneGUI;
            EditorApplication.update += () => { if (!(EditorWindow.focusedWindow is SceneView)) held = KeyCode.None; };
        }
        static void Load()
        {
            if (loaded) return; loaded = true;
            measureKey = (KeyCode)EditorPrefs.GetInt(Prefix + "measurement.key", (int)KeyCode.D);
            pathKey = (KeyCode)EditorPrefs.GetInt(Prefix + "path.key", (int)KeyCode.S);
            measureMods = (EventModifiers)EditorPrefs.GetInt(Prefix + "measurement.mods", (int)EventModifiers.Alt) & Mask;
            pathMods = (EventModifiers)EditorPrefs.GetInt(Prefix + "path.mods", (int)EventModifiers.Alt) & Mask;
        }
        static void OnSceneGUI(SceneView view)
        {
            Load(); var e = Event.current;
            if (e.type == EventType.KeyUp && e.keyCode == held) { held = KeyCode.None; return; }
            if (e.type != EventType.KeyDown || EditorWindow.focusedWindow != view || EditorGUIUtility.editingTextField || EditorApplication.isPlayingOrWillChangePlaymode) return;
            var mods = e.modifiers & Mask;
            bool measurement = e.keyCode == measureKey && mods == measureMods;
            bool path = e.keyCode == pathKey && mods == pathMods;
            if (!measurement && !path) return;
            if (held == e.keyCode) { e.Use(); return; }
            held = e.keyCode;
            if (measurement)
            {
                bool enabled = !DmSceneTool.Active;
                if (enabled) ASEShaderConverterWindow.OpenMeasurement();
                DmSceneTool.Active = enabled;
            }
            else
            {
                bool enabled = !PathSceneTool.Active;
                if (enabled) ASEShaderConverterWindow.OpenPathTools();
                PathSceneTool.Active = enabled;
            }
            view.Focus(); e.Use();
        }
        internal static bool SetBinding(bool measurement, KeyCode key, EventModifiers modifiers)
        {
            Load(); modifiers &= Mask;
            if (key < KeyCode.A || key > KeyCode.Z || modifiers == 0)
            { message = CHToolLanguage.Pick("请选择 A–Z 和至少一个修饰键。", "Choose A–Z and at least one modifier."); return false; }
            if (key == (measurement ? pathKey : measureKey) && modifiers == (measurement ? pathMods : measureMods))
            { message = CHToolLanguage.Pick("两个场景工具不能使用相同快捷键。", "The two Scene tools cannot use the same shortcut."); return false; }
            if (measurement) { measureKey = key; measureMods = modifiers; } else { pathKey = key; pathMods = modifiers; }
            string name = measurement ? "measurement" : "path";
            EditorPrefs.SetInt(Prefix + name + ".key", (int)key); EditorPrefs.SetInt(Prefix + name + ".mods", (int)modifiers);
            held = KeyCode.None; message = null; return true;
        }
        internal static void Reset()
        {
            foreach (var name in new[] { "measurement", "path" }) foreach (var suffix in new[] { ".key", ".mods" }) EditorPrefs.DeleteKey(Prefix + name + suffix);
            loaded = false; Load(); held = KeyCode.None; message = null;
        }
        internal static void Draw()
        {
            Load(); EditorGUILayout.Space();
            EditorGUILayout.LabelField(CHToolLanguage.Pick("场景工具快捷键", "Scene tool shortcuts"), EditorStyles.boldLabel);
            DrawBinding(true, CHToolLanguage.Pick("距离 / 角度测量", "Distance / angle measurement"), measureKey, measureMods);
            DrawBinding(false, CHToolLanguage.Pick("路径编辑", "Path editing"), pathKey, pathMods);
            if (!string.IsNullOrEmpty(message)) EditorGUILayout.HelpBox(message, MessageType.Warning);
            EditorGUILayout.HelpBox(CHToolLanguage.Pick("仅在 Scene 视图获得焦点且未输入文字时生效。快捷键切换启用状态；启用一个工具会停用另一个。设置保存在本机，可与 Unity 快捷键冲突时自行更改。", "Shortcuts work only in a focused Scene view outside text input. They toggle the tool; enabling one disables the other. Bindings are saved on this computer. Change them here if they conflict with Unity shortcuts."), MessageType.None);
            if (GUILayout.Button(CHToolLanguage.Pick("恢复默认快捷键（Alt+D / Alt+S）", "Reset shortcuts (Alt+D / Alt+S)"))) Reset();
        }
        static void DrawBinding(bool measurement, string label, KeyCode key, EventModifiers mods)
        {
            EditorGUILayout.LabelField(label);
            using (new EditorGUILayout.HorizontalScope())
            {
                EditorGUI.BeginChangeCheck();
                bool alt = GUILayout.Toggle((mods & EventModifiers.Alt) != 0, "Alt", "Button");
                bool ctrl = GUILayout.Toggle((mods & EventModifiers.Control) != 0, "Ctrl", "Button");
                bool shift = GUILayout.Toggle((mods & EventModifiers.Shift) != 0, "Shift", "Button");
                bool cmd = GUILayout.Toggle((mods & EventModifiers.Command) != 0, "Cmd", "Button");
                var letters = new string[26]; for (int i = 0; i < 26; i++) letters[i] = ((char)('A' + i)).ToString();
                int next = EditorGUILayout.Popup(Mathf.Clamp((int)key - (int)KeyCode.A, 0, 25), letters, GUILayout.Width(70));
                if (EditorGUI.EndChangeCheck()) SetBinding(measurement, (KeyCode)((int)KeyCode.A + next), (alt ? EventModifiers.Alt : 0) | (ctrl ? EventModifiers.Control : 0) | (shift ? EventModifiers.Shift : 0) | (cmd ? EventModifiers.Command : 0));
            }
        }
    }
}
