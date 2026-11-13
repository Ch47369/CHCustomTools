using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using UnityEditor;
using UnityEditor.PackageManager;
using UnityEditor.PackageManager.Requests;
using PackageInfo = UnityEditor.PackageManager.PackageInfo;

namespace ASEShaderConverter.Editor
{
    [InitializeOnLoad]
    public static class ShaderPackageUpdater
    {
        const string Pending = "ShaderConverter.Update.PendingUrl";
        const string Started = "ShaderConverter.Update.StartedUtc";
        const string LastAttempt = "ShaderConverter.Update.LastAttempt";
        const string LastFailed = "ShaderConverter.Update.LastFailed";
        const string CachedRepository = "ShaderConverter.Update.Repository";
        const string CachedTag = "ShaderConverter.Update.Tag";
        static Task<ShaderPackageRelease> check;
        static CancellationTokenSource cancellation;
        static AddRequest installation;
        static double nextPoll;
        static bool restored;
        public static event Action Changed;
        public static ShaderPackageRelease Latest { get; private set; }
        static CHToolMessage message = new CHToolMessage(CHToolLanguage.Text(true, "等待检查仓库版本…"), CHToolLanguage.Text(false, "等待检查仓库版本…"));
        public static string Message { get { return message; } }
        public static bool HasError { get; private set; }
        internal static ShaderGitFailure LastFailure { get; private set; }
        public static string FailureReason { get { return LastFailure.ToString(); } }
        public static bool CanAuthenticate { get { return CanCheck && Repository == ShaderPackageUpdatePolicy.Repository && (LastFailure == ShaderGitFailure.Authentication || LastFailure == ShaderGitFailure.AccessDenied); } }
        public static bool Busy { get { return check != null || installation != null || SessionState.GetString(Pending, "").Length > 0; } }
        static ShaderPackageUpdater()
        {
            EditorApplication.update += Poll;
            AssemblyReloadEvents.beforeAssemblyReload += CancelCheck;
            EditorApplication.quitting += CancelCheck;
        }
        public static PackageInfo Installed { get { return PackageInfo.GetAllRegisteredPackages().FirstOrDefault(p => p.name == ShaderPackageUpdatePolicy.PackageName); } }
        public static string Repository
        {
            get { var p = Installed; return p != null && p.source == PackageSource.Git ? ShaderPackageUpdatePolicy.InstalledRepository(p.packageId) : ShaderPackageUpdatePolicy.Repository; }
        }
        public static string SourceLabel
        {
            get
            {
                var p = Installed;
                if (p == null) return CHToolLanguage.Text("未找到已安装的 Shader转换器");
                string source = p.source == PackageSource.Git ? "Git" : p.source == PackageSource.LocalTarball ? CHToolLanguage.Text("本地 Tarball") : p.source == PackageSource.Local ? CHToolLanguage.Text("本地目录") : p.source == PackageSource.Embedded ? CHToolLanguage.Text("嵌入式目录") : p.source.ToString();
                return CHToolLanguage.Text("当前版本 ") + p.version + " · " + source;
            }
        }
        public static string InstallationNote
        {
            get
            {
                var p = Installed;
                if (p != null && p.source == PackageSource.Embedded) return CHToolLanguage.Text("嵌入式包不能直接更新。请先备份并移出项目 Packages 中的源码目录，再通过 Git URL 安装。");
                if (p != null && p.source == PackageSource.Git && Repository == null) return CHToolLanguage.Text("此包来自其他 Git 地址。请在其来源仓库管理版本；本更新器只处理 ShaderConverter 官方私有仓库。");
                if (p != null && (p.source == PackageSource.Local || p.source == PackageSource.LocalTarball)) return CHToolLanguage.Text("当前为本地安装。切换为 Git 安装会更改当前项目的包引用，本地源码目录和 Tarball 文件会保留。");
                return CHToolLanguage.Pick("更新会复用本机 Git 凭据，并锁定选定的正式版本。", "Updates reuse your saved Git credentials and pin the selected stable release.");
            }
        }
        static bool SupportedSource(PackageInfo p) { return p != null && (p.source == PackageSource.Git || p.source == PackageSource.Local || p.source == PackageSource.LocalTarball) && Repository != null; }
        public static bool CanCheck { get { return !Busy && !EditorApplication.isCompiling && !EditorApplication.isUpdating && SupportedSource(Installed); } }
        public static bool HasNewVersion
        {
            get { var p = Installed; return SupportedSource(p) && ShaderPackageUpdatePolicy.CanInstall(p.version, Latest, false); }
        }
        public static bool CanMigrate { get { return CanInstall && !HasNewVersion; } }
        public static bool CanInstall
        {
            get { var p = Installed; return CanCheck && ShaderPackageUpdatePolicy.CanInstall(p.version, Latest, p.source != PackageSource.Git); }
        }
        public static string InstallLabel
        {
            get { return CHToolLanguage.Text("更新到 ") + (Latest == null ? CHToolLanguage.Text("新版本") : Latest.version.ToString()); }
        }
        static void SetMessage(CHToolMessage text, bool error = false) { message = text; HasError = error; if (Changed != null) Changed(); }
        // Session cache survives script reloads, while each new Editor session checks again.
        public static void EnsureChecked()
        {
            if (!CanCheck || EditorApplication.isPlayingOrWillChangePlaymode) return;
            RestoreCache();
            DateTime attempted;
            double interval = SessionState.GetBool(LastFailed, false) ? 5 : 60;
            if (DateTime.TryParse(SessionState.GetString(LastAttempt, ""), null, System.Globalization.DateTimeStyles.RoundtripKind, out attempted)
                && DateTime.UtcNow - attempted < TimeSpan.FromMinutes(interval)) return;
            CheckForUpdates();
        }
        static void RestoreCache()
        {
            if (restored) return;
            restored = true;
            string tag = SessionState.GetString(CachedTag, "");
            Version version;
            if (SessionState.GetString(CachedRepository, "") == Repository && tag.StartsWith("v", StringComparison.Ordinal)
                && ShaderPackageUpdatePolicy.TryVersion(tag.Substring(1), out version))
            {
                Latest = new ShaderPackageRelease { tag = tag, version = version };
                if (!Busy) SetVersionMessage();
            }
        }
        static void SetVersionMessage()
        {
            var p = Installed;
            SetMessage(new CHToolMessage(Latest == null ? CHToolLanguage.Text(true, "仓库中没有 vX.Y.Z 格式的正式版本。") : HasNewVersion ? CHToolLanguage.Text(true, "发现新版本 ") + Latest.version + "。"
                : p != null && p.version == Latest.version.ToString() ? CHToolLanguage.Text(true, "当前已是最新版本（") + Latest.version + "）。" : CHToolLanguage.Text(true, "当前版本高于仓库最新正式版 ") + Latest.version + "。", Latest == null ? CHToolLanguage.Text(false, "仓库中没有 vX.Y.Z 格式的正式版本。") : HasNewVersion ? CHToolLanguage.Text(false, "发现新版本 ") + Latest.version + "。"
                : p != null && p.version == Latest.version.ToString() ? CHToolLanguage.Text(false, "当前已是最新版本（") + Latest.version + "）。" : CHToolLanguage.Text(false, "当前版本高于仓库最新正式版 ") + Latest.version + "。"));
        }
        public static void CheckForUpdates() { StartCheck(false); }
        public static void AuthenticateAndCheck() { if (CanAuthenticate) StartCheck(true); }
        static void StartCheck(bool authenticate)
        {
            if (!CanCheck) return;
            LastFailure = ShaderGitFailure.None;
            Latest = null;
            restored = true;
            SessionState.SetString(LastAttempt, DateTime.UtcNow.ToString("o"));
            SessionState.EraseString(CachedTag);
            SessionState.SetString(CachedRepository, Repository);
            cancellation = new CancellationTokenSource();
            check = ShaderGitClient.ReadTags(Repository, authenticate, cancellation.Token);
            SetMessage(new CHToolMessage(CHToolLanguage.Text(true, "正在检查正式版本…"), CHToolLanguage.Text(false, "正在检查正式版本…")));
        }
        internal static CHToolMessage FailureMessage(ShaderGitFailure failure)
        {
            switch (failure)
            {
                case ShaderGitFailure.GitUnavailable: return new CHToolMessage("Unity 未找到 Git。请安装 Git；若已安装，可重试或重启 Unity 后再检查。", "Unity could not find Git. Install Git; if it is already installed, retry or restart Unity.");
                case ShaderGitFailure.Authentication: return new CHToolMessage("GitHub 登录凭据不可用或已过期。请点击“GitHub 登录并重试”，使用有此私有仓库访问权限的账号登录。", "GitHub credentials are missing or expired. Click Sign in to GitHub and retry, using an account with access to this private repository.");
                case ShaderGitFailure.AccessDenied: return new CHToolMessage("GitHub 拒绝访问此私有仓库。请确认已接受仓库邀请并使用有权限的账号；HTTPS 安装可点击“GitHub 登录并重试”，SSH 安装请检查密钥。", "GitHub denied access to this private repository. Accept its invitation and use an authorized account. HTTPS users can sign in and retry; SSH users should check their key.");
                case ShaderGitFailure.Network: return new CHToolMessage("连接 GitHub 失败。Git 已找到，请检查网络、VPN / 代理及 DNS 后重试。", "Could not connect to GitHub. Git was found; check the network, VPN / proxy and DNS, then retry.");
                case ShaderGitFailure.Timeout: return new CHToolMessage("连接 GitHub 超时。请检查网络或代理后重试；若正在登录，请完成 GitHub 授权。", "The GitHub connection timed out. Check the network or proxy and retry; complete GitHub authorization if signing in.");
                case ShaderGitFailure.Cancelled: return new CHToolMessage("版本检查已取消，可以重新检查。", "The version check was cancelled. You can check again.");
                default: return new CHToolMessage("Git 无法完成版本检查。请检查本机 Git 配置后重试。", "Git could not complete the version check. Check your local Git configuration and retry.");
            }
        }
        public static void InstallLatest()
        {
            if (!CanInstall) return;
            string url = ShaderPackageUpdatePolicy.InstallationUrl(Repository, Latest.tag);
            SessionState.SetString(Pending, url);
            SessionState.SetString(Started, DateTime.UtcNow.ToString("o"));
            try { installation = Client.Add(url); SetMessage(new CHToolMessage(CHToolLanguage.Text(true, "Unity Package Manager 正在安装 ") + Latest.version + CHToolLanguage.Text(true, "，请等待包解析和脚本重载…"), CHToolLanguage.Text(false, "Unity Package Manager 正在安装 ") + Latest.version + CHToolLanguage.Text(false, "，请等待包解析和脚本重载…"))); }
            catch (Exception) { SessionState.EraseString(Pending); SessionState.EraseString(Started); SetMessage(new CHToolMessage(CHToolLanguage.Text(true, "无法启动更新，请在 Package Manager 中检查正在进行的操作。"), CHToolLanguage.Text(false, "无法启动更新，请在 Package Manager 中检查正在进行的操作。")), true); }
        }
        static void CancelCheck() { if (cancellation != null) cancellation.Cancel(); }
        static void Poll()
        {
            if (check != null && check.IsCompleted)
            {
                var completed = check; check = null;
                if (cancellation != null) { cancellation.Dispose(); cancellation = null; }
                if (completed.IsFaulted || completed.IsCanceled)
                {
                    var failure = completed.Exception == null ? null : completed.Exception.GetBaseException() as ShaderGitCheckException;
                    LastFailure = completed.IsCanceled ? ShaderGitFailure.Cancelled : failure == null ? ShaderGitFailure.Unknown : failure.Kind;
                    SessionState.SetBool(LastFailed, true);
                    SetMessage(FailureMessage(LastFailure), true);
                }
                else
                {
                    Latest = completed.Result;
                    SessionState.SetBool(LastFailed, false);
                    if (Latest != null) SessionState.SetString(CachedTag, Latest.tag);
                    SetVersionMessage();
                }
            }
            if (EditorApplication.timeSinceStartup < nextPoll) return;
            nextPoll = EditorApplication.timeSinceStartup + 0.5;
            string pending = SessionState.GetString(Pending, "");
            if (pending.Length == 0)
            {
                if (!UnityEngine.Application.isBatchMode && EditorApplication.timeSinceStartup > 10) EnsureChecked();
                return;
            }
            if (installation != null)
            {
                if (!installation.IsCompleted) return;
                if (installation.Status == StatusCode.Failure)
                {
                    LastFailure = ShaderGitClient.Classify(installation.Error == null ? "" : installation.Error.message);
                    installation = null; SessionState.EraseString(Pending); SessionState.EraseString(Started);
                    var reason = FailureMessage(LastFailure);
                    // Keep Package Manager diagnostics private; expose only the classified reason.
                    SetMessage(reason, true); return;
                }
                installation = null;
            }
            if (EditorApplication.isCompiling || EditorApplication.isUpdating) return;
            var installed = Installed;
            string tag = pending.Substring(pending.LastIndexOf('#') + 1);
            // GetAllRegisteredPackages can omit GitInfo on Unity 2022.3. The exact
            // packageId contains the requested repository and tag even in that case.
            if (installed != null && installed.source == PackageSource.Git && installed.packageId == ShaderPackageUpdatePolicy.PackageName + "@" + pending && installed.version == tag.Substring(1))
            {
                SessionState.EraseString(Pending); SessionState.EraseString(Started); SetMessage(new CHToolMessage(CHToolLanguage.Text(true, "已安装 ") + installed.version + CHToolLanguage.Text(true, "。Git 版本已锁定到 ") + tag + "。", CHToolLanguage.Text(false, "已安装 ") + installed.version + CHToolLanguage.Text(false, "。Git 版本已锁定到 ") + tag + "。"));
            }
            else
            {
                DateTime started;
                if (DateTime.TryParse(SessionState.GetString(Started, ""), null, System.Globalization.DateTimeStyles.RoundtripKind, out started) && DateTime.UtcNow - started > TimeSpan.FromMinutes(3))
                { SessionState.EraseString(Pending); SessionState.EraseString(Started); SetMessage(new CHToolMessage(CHToolLanguage.Text(true, "尚未确认安装结果。请查看 Package Manager 的包版本和错误信息，包解析仍可能继续完成。"), CHToolLanguage.Text(false, "尚未确认安装结果。请查看 Package Manager 的包版本和错误信息，包解析仍可能继续完成。")), true); }
            }
        }
    }
}
