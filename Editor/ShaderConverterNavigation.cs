using System.IO;
using UnityEditor;
using UnityEngine;

namespace ASEShaderConverter.Editor
{
    public sealed partial class ASEShaderConverterWindow
    {
        [SerializeField] private string activePage = "conversion";
        [SerializeField] private int conversionTab, settingsTab, agentTab;
        [SerializeField] private ShaderLibraryPanel library = new ShaderLibraryPanel();
        [SerializeField] private Vector2 settingsScroll, agentScroll;
        private readonly Rect[] navigationAreas = new Rect[4];
        private static readonly string[] PageIds = { "conversion", "library", "agent", "settings" };

        private static ASEShaderConverterWindow ShowMain()
        {
            var window = GetWindow<ASEShaderConverterWindow>();
            window.minSize = new Vector2(800, 500);
            window.titleContent = new GUIContent(CHToolLanguage.Text("Shader转换器"));
            window.Show(); window.Focus();
            return window;
        }
        private void Navigate(string page)
        {
            activePage = page;
            if (Event.current != null) GUI.FocusControl(null);
            Repaint();
        }
        public static void OpenLibrary(string category = null)
        {
            var window = ShowMain();
            if (window.library == null) window.library = new ShaderLibraryPanel();
            if (!string.IsNullOrEmpty(category)) window.library.SelectCategory(category);
            window.Navigate("library");
        }
        public static void OpenAgent() { ShowMain().Navigate("agent"); }
        public static void OpenUpdates()
        {
            var window = ShowMain(); window.settingsTab = 1; window.Navigate("settings");
        }
        private void OnInspectorUpdate() { if (ShaderLibraryBatch.IsRunning) Repaint(); }
        private void OnGUI()
        {
            titleContent.text = CHToolLanguage.Text("Shader转换器");
            if (System.Array.IndexOf(PageIds, activePage) < 0) activePage = "conversion";
            if (library == null) library = new ShaderLibraryPanel();
            EditorGUILayout.BeginHorizontal();
            DrawNavigation();
            EditorGUILayout.BeginVertical(GUILayout.Width(Mathf.Max(400, position.width - 210)), GUILayout.ExpandHeight(true));
            GUILayout.Space(10);
            GUILayout.Label(PageTitle(activePage), EditorStyles.boldLabel);
            GUILayout.Space(6);
            if (activePage == "library") library.DrawPanel();
            else if (activePage == "agent") DrawAgentPage();
            else if (activePage == "settings") DrawSettingsPage();
            else DrawConversionPage();
            EditorGUILayout.EndVertical();
            GUILayout.Space(8);
            EditorGUILayout.EndHorizontal();
        }
        private static string PageTitle(string page)
        {
            if (page == "library") return CHToolLanguage.Pick("着色器库", "Shader library");
            if (page == "agent") return CHToolLanguage.Pick("Agent 接入", "Agent integration");
            if (page == "settings") return CHToolLanguage.Pick("设置", "Settings");
            return CHToolLanguage.Pick("图转换", "Graph conversion");
        }
        private void DrawNavigation()
        {
            EditorGUILayout.BeginVertical(GUILayout.Width(180), GUILayout.ExpandHeight(true));
            GUILayout.Space(12);
            GUILayout.Label(CHToolLanguage.Text("Shader转换器"), EditorStyles.boldLabel);
            GUILayout.Space(12);
            var style = new GUIStyle(EditorStyles.label) { alignment = TextAnchor.MiddleLeft, padding = new RectOffset(16, 8, 0, 0) };
            for (int i = 0; i < PageIds.Length; i++)
            {
                var rect = GUILayoutUtility.GetRect(180, 30, GUILayout.ExpandWidth(true));
                if (Event.current.type == EventType.Repaint)
                    navigationAreas[i] = new Rect(GUIUtility.GUIToScreenPoint(rect.position) - position.position, rect.size);
                bool selected = activePage == PageIds[i];
                if (selected) EditorGUI.DrawRect(rect, EditorGUIUtility.isProSkin ? new Color(.17f, .36f, .53f) : new Color(.24f, .49f, .78f));
                style.normal.textColor = selected ? Color.white : EditorStyles.label.normal.textColor;
                string label = PageTitle(PageIds[i]);
                if (i == 3 && ShaderPackageUpdater.HasNewVersion) label += "  •";
                if (GUI.Button(rect, label, style)) Navigate(PageIds[i]);
            }
            GUILayout.FlexibleSpace();
            GUILayout.Label(CHToolLanguage.Pick("作者：CH", "Author: CH"), EditorStyles.miniLabel);
            var installed = ShaderPackageUpdater.Installed;
            if (installed != null) GUILayout.Label("v" + installed.version, EditorStyles.miniLabel);
            GUILayout.Space(8);
            EditorGUILayout.EndVertical();
            var divider = GUILayoutUtility.GetRect(1, 1, GUILayout.Width(1), GUILayout.ExpandHeight(true));
            EditorGUI.DrawRect(divider, EditorGUIUtility.isProSkin ? new Color(.12f, .12f, .12f) : new Color(.6f, .6f, .6f));
            GUILayout.Space(8);
        }
        private void DrawSettingsPage()
        {
            settingsTab = GUILayout.Toolbar(settingsTab, new[] { CHToolLanguage.Pick("常规", "General"), CHToolLanguage.Pick("插件更新", "Updates"), CHToolLanguage.Pick("关于", "About") });
            settingsScroll = EditorGUILayout.BeginScrollView(settingsScroll);
            GUILayout.Space(10);
            if (settingsTab == 0)
            {
                CHToolLanguage.DrawLanguageSelector();
                EditorGUILayout.HelpBox(CHToolLanguage.Pick("默认跟随 Unity 的语言。手动选择中文或 English 后，插件内所有功能统一使用所选语言；恢复默认即可继续跟随 Unity。", "Follows Unity's language by default. A manual Chinese or English choice applies to every feature in the plugin. Reset language to follow Unity again."), MessageType.None);
            }
            else if (settingsTab == 1)
            {
                ShaderPackageUpdateGUI.Draw();
                EditorGUILayout.LabelField(ShaderPackageUpdater.InstallationNote, EditorStyles.wordWrappedLabel);
            }
            else
            {
                EditorGUILayout.LabelField(CHToolLanguage.Pick("作者", "Author"), "CH");
                EditorGUILayout.LabelField(CHToolLanguage.Pick("工具集", "Tool collection"), "CH自定义工具集");
                EditorGUILayout.LabelField(CHToolLanguage.Pick("插件", "Plugin"), CHToolLanguage.Text("Shader转换器"));
                EditorGUILayout.LabelField(ShaderPackageUpdater.SourceLabel, EditorStyles.wordWrappedLabel);
                EditorGUILayout.Space();
                EditorGUILayout.LabelField(CHToolLanguage.Pick("Git 安装地址", "Git install URL"), EditorStyles.boldLabel);
                EditorGUILayout.SelectableLabel(ShaderPackageUpdatePolicy.Repository, EditorStyles.textField, GUILayout.Height(22));
                if (GUILayout.Button(CHToolLanguage.Pick("复制 Git 地址", "Copy Git URL"))) EditorGUIUtility.systemCopyBuffer = ShaderPackageUpdatePolicy.Repository;
            }
            EditorGUILayout.EndScrollView();
        }
        private void DrawAgentPage()
        {
            agentTab = GUILayout.Toolbar(agentTab, new[] { CHToolLanguage.Pick("连接目录", "Connection"), CHToolLanguage.Pick("使用说明", "Workflow") });
            agentScroll = EditorGUILayout.BeginScrollView(agentScroll);
            GUILayout.Space(10);
            if (agentTab == 0)
            {
                string root = ShaderAgentInbox.Root;
                EditorGUILayout.LabelField(CHToolLanguage.Pick("当前项目的 Agent 连接", "Agent connection for this project"), EditorStyles.boldLabel);
                EditorGUILayout.HelpBox(File.Exists(Path.Combine(root, "connection.json")) ? CHToolLanguage.Pick("连接文件已建立。Agent 可通过此目录提交请求并读取响应。", "The connection file is available. Agents can submit requests and read responses in this directory.") : CHToolLanguage.Pick("正在等待连接文件。Unity 完成导入后会在此项目的 Library 目录自动建立连接。", "Waiting for the connection file. Unity creates it automatically under this project's Library after import."), MessageType.Info);
                DrawAgentPath(CHToolLanguage.Pick("根目录", "Root"), root);
                DrawAgentPath("connection.json", Path.Combine(root, "connection.json"));
                DrawAgentPath("requests", Path.Combine(root, "requests"));
                DrawAgentPath("responses", Path.Combine(root, "responses"));
                if (GUILayout.Button(CHToolLanguage.Pick("在资源管理器中显示目录", "Show folder in file manager"))) EditorUtility.RevealInFinder(root);
            }
            else
            {
                EditorGUILayout.HelpBox(CHToolLanguage.Pick("1. 读取 connection.json 并执行 probe，检查实际 Unity、ASE / ShaderGraph 和目标管线。\n\n2. 使用 describe 获取真实模板与节点端口，然后 analyze 源文件。\n\n3. 通过 generate 或 generatePlan 建图。只有保存重载、Unity 编译通过的结果才标记为 Generated。\n\n4. 在目标场景另外比较材质效果。编译通过不代表画面等价。", "1. Read connection.json and run probe to check Unity, ASE / ShaderGraph and the target pipeline.\n\n2. Use describe for actual template and node ports, then analyze the source file.\n\n3. Build with generate or generatePlan. Only saved, reloaded and compiled results are marked Generated.\n\n4. Compare material appearance separately in the target scene. Compilation does not prove visual equivalence."), MessageType.None);
                EditorGUILayout.LabelField(CHToolLanguage.Pick("完整协议随包提供：Documentation~/AgentProtocol.md", "Full protocol included in the package: Documentation~/AgentProtocol.md"), EditorStyles.wordWrappedLabel);
            }
            EditorGUILayout.EndScrollView();
        }
        private static void DrawAgentPath(string label, string path)
        {
            EditorGUILayout.LabelField(label, EditorStyles.boldLabel);
            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.SelectableLabel(path, EditorStyles.textField, GUILayout.Height(22));
            if (GUILayout.Button(CHToolLanguage.Pick("复制", "Copy"), GUILayout.Width(55))) EditorGUIUtility.systemCopyBuffer = path;
            EditorGUILayout.EndHorizontal();
            GUILayout.Space(6);
        }
    }
}
