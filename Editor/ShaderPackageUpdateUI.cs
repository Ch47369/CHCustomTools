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
        Button check, install, migrate, notes, authenticate;
        bool selected;
        static ShaderPackageManagerExtension() { PackageManagerExtensions.RegisterExtension(new ShaderPackageManagerExtension()); }
        public VisualElement CreateExtensionUI()
        {
            if (root != null) return root;
            root = new VisualElement { name = "shader-converter-updates" };
            root.style.marginTop = 8; root.style.marginBottom = 8;
            heading = new Label(CHToolLanguage.Pick("CH自定义工具集 · 插件更新", "CH Custom Tools · Updates")); heading.style.unityFontStyleAndWeight = FontStyle.Bold; root.Add(heading);
            version = new Label(); root.Add(version);
            note = new Label(); note.style.whiteSpace = WhiteSpace.Normal; root.Add(note);
            status = new Label(); status.style.whiteSpace = WhiteSpace.Normal; status.style.marginTop = 6; root.Add(status);
            var actions = new VisualElement(); actions.style.flexDirection = FlexDirection.Row;
            check = new Button(ShaderPackageUpdater.CheckForUpdates) { name = "shader-converter-check-update", text = CHToolLanguage.Text("检查更新") }; actions.Add(check);
            authenticate = new Button(ShaderPackageUpdater.AuthenticateAndCheck) { name = "shader-converter-authenticate" }; actions.Add(authenticate);
            install = new Button(ShaderPackageUpdater.InstallLatest) { name = "shader-converter-install-update" }; actions.Add(install);
            migrate = new Button(ShaderPackageUpdater.InstallLatest) { name = "shader-converter-migrate-git", text = CHToolLanguage.Pick("从 GitHub 安装当前版本", "Install current version from GitHub") }; actions.Add(migrate);
            notes = new Button(() => Application.OpenURL(ShaderPackageUpdatePolicy.ReleasesUrl)) { text = CHToolLanguage.Text("版本说明") }; actions.Add(notes); root.Add(actions);
            root.RegisterCallback<AttachToPanelEvent>(e => { ShaderPackageUpdater.Changed -= Refresh; ShaderPackageUpdater.Changed += Refresh; Refresh(); });
            root.RegisterCallback<DetachFromPanelEvent>(e => ShaderPackageUpdater.Changed -= Refresh);
            root.schedule.Execute(Refresh).Every(500);
            Refresh(); return root;
        }
        void Refresh()
        {
            if (root == null) return;
            heading.text = CHToolLanguage.Pick("CH自定义工具集 · 插件更新", "CH Custom Tools · Updates"); check.text = CHToolLanguage.Text("检查更新"); migrate.text = CHToolLanguage.Pick("从 GitHub 安装当前版本", "Install current version from GitHub"); notes.text = CHToolLanguage.Text("版本说明");
            root.style.display = selected ? DisplayStyle.Flex : DisplayStyle.None;
            version.text = ShaderPackageUpdater.SourceLabel; note.text = ShaderPackageUpdater.InstallationNote; status.text = ShaderPackageUpdater.Message;
            check.SetEnabled(ShaderPackageUpdater.CanCheck); install.text = ShaderPackageUpdater.InstallLabel; install.SetEnabled(ShaderPackageUpdater.CanInstall);
            authenticate.text = CHToolLanguage.Pick("GitHub 登录并重试", "Sign in to GitHub and retry");
            authenticate.tooltip = CHToolLanguage.Pick("调用本机 Git 凭据管理器，可能打开 GitHub 登录页。", "Uses the local Git credential manager and may open the GitHub sign-in page.");
            authenticate.style.display = ShaderPackageUpdater.CanAuthenticate ? DisplayStyle.Flex : DisplayStyle.None;
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
            if (ShaderPackageUpdater.CanMigrate && GUILayout.Button(CHToolLanguage.Pick("从 GitHub 安装当前版本", "Install current version from GitHub"))) ShaderPackageUpdater.InstallLatest();
            EditorGUILayout.EndHorizontal();
            EditorGUILayout.HelpBox(ShaderPackageUpdater.Message, ShaderPackageUpdater.HasError ? MessageType.Error : MessageType.None);
            if (ShaderPackageUpdater.CanAuthenticate)
            {
                EditorGUILayout.LabelField(CHToolLanguage.Pick("通过本机 Git 凭据管理器登录，可能打开 GitHub 登录页。", "Sign in through your local Git credential manager; this may open the GitHub sign-in page."), EditorStyles.wordWrappedLabel);
                if (GUILayout.Button(CHToolLanguage.Pick("GitHub 登录并重试", "Sign in to GitHub and retry"))) ShaderPackageUpdater.AuthenticateAndCheck();
            }
        }
    }
    // Keep the old public entry point and saved-layout type compatible, routing both to the main window.
    public sealed class ShaderPackageUpdateWindow : EditorWindow
    {
        public static void Open() { ASEShaderConverterWindow.OpenUpdates(); ShaderPackageUpdater.EnsureChecked(); }
        void OnEnable() { EditorApplication.update += Redirect; }
        void OnDisable() { EditorApplication.update -= Redirect; }
        void Redirect() { if (this == null) return; Open(); Close(); }
    }
}
