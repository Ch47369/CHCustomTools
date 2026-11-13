using UnityEditor;
using UnityEditor.PackageManager;
using UnityEditor.PackageManager.UI;
using UnityEngine;
using UnityEngine.UIElements;
using PackageInfo = UnityEditor.PackageManager.PackageInfo;

namespace ASEShaderConverter.Editor
{
    [InitializeOnLoad]
    public sealed class ShaderPackageManagerExtension : IPackageManagerExtension
    {
        VisualElement root;
        Label version, note, status, heading;
        Button check, install, migrate, notes;
        bool selected;
        static ShaderPackageManagerExtension() { PackageManagerExtensions.RegisterExtension(new ShaderPackageManagerExtension()); }
        public VisualElement CreateExtensionUI()
        {
            if (root != null) return root;
            root = new VisualElement { name = "shader-converter-updates" };
            root.style.marginTop = 8; root.style.marginBottom = 8;
            heading = new Label(CHToolLanguage.Text("Shader转换器 · 插件更新")); heading.style.unityFontStyleAndWeight = FontStyle.Bold; root.Add(heading);
            version = new Label(); root.Add(version);
            note = new Label(); note.style.whiteSpace = WhiteSpace.Normal; root.Add(note);
            status = new Label(); status.style.whiteSpace = WhiteSpace.Normal; status.style.marginTop = 6; root.Add(status);
            var actions = new VisualElement(); actions.style.flexDirection = FlexDirection.Row;
            check = new Button(ShaderPackageUpdater.CheckForUpdates) { name = "shader-converter-check-update", text = CHToolLanguage.Text("检查更新") }; actions.Add(check);
            install = new Button(ShaderPackageUpdater.InstallLatest) { name = "shader-converter-install-update" }; actions.Add(install);
            migrate = new Button(ShaderPackageUpdater.InstallLatest) { name = "shader-converter-migrate-git", text = CHToolLanguage.Text("改用 Git 安装当前版本") }; actions.Add(migrate);
            notes = new Button(() => Application.OpenURL(ShaderPackageUpdatePolicy.ReleasesUrl)) { text = CHToolLanguage.Text("版本说明") }; actions.Add(notes); root.Add(actions);
            root.RegisterCallback<AttachToPanelEvent>(e => { ShaderPackageUpdater.Changed -= Refresh; ShaderPackageUpdater.Changed += Refresh; Refresh(); });
            root.RegisterCallback<DetachFromPanelEvent>(e => ShaderPackageUpdater.Changed -= Refresh);
            root.schedule.Execute(Refresh).Every(500);
            Refresh(); return root;
        }
        void Refresh()
        {
            if (root == null) return;
            heading.text = CHToolLanguage.Text("Shader转换器 · 插件更新"); check.text = CHToolLanguage.Text("检查更新"); migrate.text = CHToolLanguage.Text("改用 Git 安装当前版本"); notes.text = CHToolLanguage.Text("版本说明");
            root.style.display = selected ? DisplayStyle.Flex : DisplayStyle.None;
            version.text = ShaderPackageUpdater.SourceLabel; note.text = ShaderPackageUpdater.InstallationNote; status.text = ShaderPackageUpdater.Message;
            check.SetEnabled(ShaderPackageUpdater.CanCheck); install.text = ShaderPackageUpdater.InstallLabel; install.SetEnabled(ShaderPackageUpdater.CanInstall);
            install.style.display = ShaderPackageUpdater.HasNewVersion ? DisplayStyle.Flex : DisplayStyle.None;
            migrate.style.display = ShaderPackageUpdater.CanMigrate ? DisplayStyle.Flex : DisplayStyle.None;
        }
        public void OnPackageSelectionChange(PackageInfo packageInfo) { selected = packageInfo != null && packageInfo.name == ShaderPackageUpdatePolicy.PackageName; if (selected) ShaderPackageUpdater.EnsureChecked(); Refresh(); }
        public void OnPackageAddedOrUpdated(PackageInfo packageInfo) { if (packageInfo != null && packageInfo.name == ShaderPackageUpdatePolicy.PackageName) Refresh(); }
        public void OnPackageRemoved(PackageInfo packageInfo) { if (packageInfo != null && packageInfo.name == ShaderPackageUpdatePolicy.PackageName) { selected = false; Refresh(); } }
    }
    internal static class ShaderPackageUpdateGUI
    {
        internal static void Draw()
        {
            EditorGUILayout.BeginHorizontal();
            GUILayout.Label(ShaderPackageUpdater.SourceLabel, EditorStyles.miniLabel);
            GUILayout.FlexibleSpace();
            using (new EditorGUI.DisabledScope(!ShaderPackageUpdater.CanCheck))
                if (GUILayout.Button(CHToolLanguage.Text("检查更新"), GUILayout.Width(110))) ShaderPackageUpdater.CheckForUpdates();
            if (ShaderPackageUpdater.HasNewVersion)
                using (new EditorGUI.DisabledScope(!ShaderPackageUpdater.CanInstall)) if (GUILayout.Button(ShaderPackageUpdater.InstallLabel)) ShaderPackageUpdater.InstallLatest();
            if (ShaderPackageUpdater.CanMigrate && GUILayout.Button(CHToolLanguage.Text("改用 Git 安装当前版本"))) ShaderPackageUpdater.InstallLatest();
            EditorGUILayout.EndHorizontal();
            EditorGUILayout.HelpBox(ShaderPackageUpdater.Message, ShaderPackageUpdater.HasError ? MessageType.Error : MessageType.None);
        }
    }
    // Keep the old public entry point and saved-layout type compatible, routing both to the main window.
    public sealed class ShaderPackageUpdateWindow : EditorWindow
    {
        public static void Open() { ASEShaderConverterWindow.Open(); ShaderPackageUpdater.EnsureChecked(); }
        void OnEnable() { EditorApplication.update += Redirect; }
        void OnDisable() { EditorApplication.update -= Redirect; }
        void Redirect() { if (this == null) return; Open(); Close(); }
    }
}
