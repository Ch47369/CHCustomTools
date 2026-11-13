using System;
using System.Linq;
using System.IO;
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
        static Task<string> download;
        const string PendingFile = "CH.CustomTools.Update.PendingFile";
        const string DownloadFolder = "CHCustomToolsCache~";
        static double nextPoll;
        static bool restored;
        public static event Action Changed;
        public static ShaderPackageRelease Latest { get; private set; }
        static CHToolMessage message = new CHToolMessage(CHToolLanguage.Text(true, "等待检查仓库版本…"), CHToolLanguage.Text(false, "等待检查仓库版本…"));
        public static string Message { get { return message; } }
        public static bool HasError { get; private set; }
        internal static ShaderGitFailure LastFailure { get; private set; }
        public static string FailureReason { get { return LastFailure.ToString(); } }
        public static bool CanAuthenticate { get { return false; } } // Public GitHub releases do not require sign-in.
        public static bool Busy { get { return check != null || download != null || installation != null || SessionState.GetString(Pending, "").Length > 0; } }
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
                if (p == null) return CHToolLanguage.Pick("未找到已安装的 CH自定义工具集", "Installed CH Custom Tools package was not found");
                string source = IsGitHubRelease(p) ? "GitHub Release" : p.source == PackageSource.Git ? "GitHub" : p.source == PackageSource.LocalTarball ? CHToolLanguage.Text("本地 Tarball") : p.source == PackageSource.Local ? CHToolLanguage.Text("本地目录") : p.source == PackageSource.Embedded ? CHToolLanguage.Text("嵌入式目录") : p.source.ToString();
                return CHToolLanguage.Text("当前版本 ") + p.version + " · " + source;
            }
        }
        public static string InstallationNote
        {
            get
            {
                var p = Installed;
                if (p != null && p.source == PackageSource.Embedded) return CHToolLanguage.Text("嵌入式包不能直接更新。请先备份并移出项目 Packages 中的源码目录，再通过 Git URL 安装。");
                if (p != null && p.source == PackageSource.Git && Repository == null) return CHToolLanguage.Pick("此包来自其他 Git 地址，请在其来源仓库管理版本。", "Manage this package in its originating Git repository.");
                if (p != null && IsGitHubRelease(p)) return CHToolLanguage.Pick("安装包来自 GitHub Release，已校验大小和 SHA-256；后续继续从 GitHub 检查和下载更新。", "Installed from GitHub Release after size/SHA-256 verification. Future updates continue to come from GitHub.");
                return CHToolLanguage.Pick("从公开 GitHub Release 下载正式包并校验 SHA-256，无需 GitHub 登录。", "Downloads stable packages from public GitHub Releases and verifies SHA-256. GitHub sign-in is not required.");
            }
        }
        static bool SupportedSource(PackageInfo p) { return p != null && (p.source == PackageSource.Git || p.source == PackageSource.Local || p.source == PackageSource.LocalTarball) && Repository != null; }
        public static bool CanCheck { get { return !Busy && !EditorApplication.isCompiling && !EditorApplication.isUpdating && SupportedSource(Installed); } }
        public static bool HasNewVersion
        {
            get { var p = Installed; return SupportedSource(p) && ShaderPackageUpdatePolicy.CanInstall(p.version, Latest, false); }
        }
        public static bool CanMigrate { get { return CanInstall && !HasNewVersion && Installed != null && !IsGitHubRelease(Installed); } }
        public static bool CanInstall
        {
            get { var p = Installed; return CanCheck && ShaderPackageUpdatePolicy.CanInstall(p.version, Latest, p.source != PackageSource.Git && !IsGitHubRelease(p)); }
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
            check = ShaderPackageUpdatePolicy.IsHttpsRepository(Repository)
                ? ShaderGitHubClient.Latest(Repository, authenticate, cancellation.Token)
                : ShaderGitClient.ReadTags(Repository, authenticate, cancellation.Token);
            SetMessage(new CHToolMessage("正在检查 GitHub 正式版本…", "Checking GitHub releases…"));
        }
        internal static CHToolMessage FailureMessage(ShaderGitFailure failure)
        {
            switch (failure)
            {
                case ShaderGitFailure.GitUnavailable: return new CHToolMessage("Unity 未找到 Git。请安装 Git；若已安装，可重试或重启 Unity 后再检查。", "Unity could not find Git. Install Git; if it is already installed, retry or restart Unity.");
                case ShaderGitFailure.Authentication: return new CHToolMessage("GitHub 的 SSH / Git 认证未通过。公开更新建议使用 HTTPS 安装地址。", "GitHub SSH / Git authentication failed. Use the HTTPS install URL for public updates.");
                case ShaderGitFailure.AccessDenied: return new CHToolMessage("GitHub 拒绝了当前传输方式。请改用公开 HTTPS 安装地址，或检查 SSH 密钥。", "GitHub denied this transport. Use the public HTTPS install URL or check your SSH key.");
                case ShaderGitFailure.Network: return new CHToolMessage("连接 GitHub 失败，请检查网络、VPN / 代理及 DNS 后重试。公开更新无需登录。", "Could not connect to GitHub. Check the network, VPN / proxy and DNS, then retry. Public updates do not require sign-in.");
                case ShaderGitFailure.Timeout: return new CHToolMessage("连接 GitHub 超时，请检查网络或代理后重试。", "The GitHub connection timed out. Check the network or proxy and retry.");
                case ShaderGitFailure.Cancelled: return new CHToolMessage("版本检查已取消，可以重新检查。", "The version check was cancelled. You can check again.");
                case ShaderGitFailure.InvalidRelease: return new CHToolMessage("GitHub 正式版缺少有效安装包或 SHA-256 信息，请联系作者修复该发布。", "The GitHub release is missing a valid package or SHA-256 digest. Contact the author to repair that release.");
                case ShaderGitFailure.Integrity: return new CHToolMessage("GitHub 安装包的大小或 SHA-256 校验失败，已停止安装并保留原版本。若项目缓存已有同名文件，请先备份并移走该文件后重试。", "GitHub package size or SHA-256 verification failed. Installation stopped and the current version is preserved. Back up and move aside any existing cache with that filename before retrying.");
                case ShaderGitFailure.Installation: return new CHToolMessage("GitHub 安装包已经下载，但 Unity Package Manager 安装失败，请查看当前项目的包解析错误后重试。", "The GitHub package was downloaded, but Unity Package Manager could not install it. Check this project's package resolution error and retry.");
                default: return new CHToolMessage("GitHub 更新操作未完成，请重试并查看当前项目的包解析状态。", "The GitHub update did not complete. Retry and check this project's package resolution status.");
            }
        }
        public static void InstallLatest()
        {
            if (!CanInstall) return;
            string url = ShaderPackageUpdatePolicy.InstallationUrl(Repository, Latest.tag);
            SessionState.SetString(Pending, url);
            SessionState.SetString(Started, DateTime.UtcNow.ToString("o"));
            try
            {
                if (ShaderPackageUpdatePolicy.IsHttpsRepository(Repository))
                {
                    cancellation = new CancellationTokenSource();
                    string folder = Path.GetFullPath(Path.Combine(UnityEngine.Application.dataPath, "../Packages", DownloadFolder));
                    download = ShaderGitHubClient.Download(Repository, Latest.tag, folder, cancellation.Token);
                    SetMessage(new CHToolMessage("正在从 GitHub Release 下载并校验安装包…", "Downloading and verifying the package from GitHub Release…"));
                    return;
                }
                installation = Client.Add(url); SetMessage(new CHToolMessage(CHToolLanguage.Text(true, "Unity Package Manager 正在安装 ") + Latest.version + CHToolLanguage.Text(true, "，请等待包解析和脚本重载…"), CHToolLanguage.Text(false, "Unity Package Manager 正在安装 ") + Latest.version + CHToolLanguage.Text(false, "，请等待包解析和脚本重载…"))); }
            catch (Exception) { SessionState.EraseString(Pending); SessionState.EraseString(Started); SetMessage(new CHToolMessage(CHToolLanguage.Text(true, "无法启动更新，请在 Package Manager 中检查正在进行的操作。"), CHToolLanguage.Text(false, "无法启动更新，请在 Package Manager 中检查正在进行的操作。")), true); }
        }
        static bool IsDownloadedRelease(PackageInfo package, string expectedFile)
        {
            const string prefix = ShaderPackageUpdatePolicy.PackageName + "@file:";
            if (package.source != PackageSource.LocalTarball || string.IsNullOrEmpty(expectedFile) || !package.packageId.StartsWith(prefix, StringComparison.Ordinal)) return false;
            string actual = package.packageId.Substring(prefix.Length);
            try
            {
                if (!Path.IsPathRooted(actual)) actual = Path.Combine(UnityEngine.Application.dataPath, "../Packages", actual);
                return string.Equals(Path.GetFullPath(actual), Path.GetFullPath(expectedFile), StringComparison.OrdinalIgnoreCase);
            }
            catch (Exception) { return false; }
        }
        static bool IsGitHubRelease(PackageInfo package)
        {
            string file = Path.GetFullPath(Path.Combine(UnityEngine.Application.dataPath, "../Packages", DownloadFolder, ShaderPackageUpdatePolicy.PackageName + "-" + package.version + ".tgz"));
            return IsDownloadedRelease(package, file);
        }
        static void CancelCheck()
        {
            if (cancellation != null) cancellation.Cancel();
            if (download != null) { SessionState.EraseString(Pending); SessionState.EraseString(Started); SessionState.EraseString(PendingFile); }
        }
        static void Poll()
        {
            if (download != null && download.IsCompleted)
            {
                var completed = download; download = null;
                if (cancellation != null) { cancellation.Dispose(); cancellation = null; }
                if (completed.IsFaulted || completed.IsCanceled)
                {
                    var failure = completed.Exception == null ? null : completed.Exception.GetBaseException() as ShaderGitCheckException;
                    LastFailure = completed.IsCanceled ? ShaderGitFailure.Cancelled : failure == null ? ShaderGitFailure.Unknown : failure.Kind;
                    SessionState.EraseString(Pending); SessionState.EraseString(Started); SessionState.EraseString(PendingFile);
                    SetMessage(FailureMessage(LastFailure), true); return;
                }
                string file = completed.Result;
                SessionState.SetString(PendingFile, file);
                try { installation = Client.Add("file:" + DownloadFolder + "/" + Path.GetFileName(file)); }
                catch (Exception)
                {
                    SessionState.EraseString(Pending); SessionState.EraseString(Started); SessionState.EraseString(PendingFile);
                    SetMessage(new CHToolMessage("GitHub 安装包已下载并通过校验，但 Unity 未能开始安装。可以重试。", "The GitHub package was downloaded and verified, but Unity could not start installation. Retry the update."), true); return;
                }
                SetMessage(new CHToolMessage("GitHub 安装包校验通过，Unity 正在安装并重载脚本…", "GitHub package verified. Unity is installing it and reloading scripts…"));
            }
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
            if (download != null)
            {
                SetMessage(new CHToolMessage("正在从 GitHub Release 下载并校验安装包… " + ShaderGitHubClient.Progress + "%", "Downloading and verifying the package from GitHub Release… " + ShaderGitHubClient.Progress + "%"));
                return;
            }
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
                    if (LastFailure == ShaderGitFailure.Unknown) LastFailure = ShaderGitFailure.Installation;
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
            bool gitMatches = installed != null && installed.source == PackageSource.Git && installed.packageId == ShaderPackageUpdatePolicy.PackageName + "@" + pending;
            bool releaseMatches = installed != null && IsDownloadedRelease(installed, SessionState.GetString(PendingFile, ""));
            if (installed != null && installed.version == tag.Substring(1) && (gitMatches || releaseMatches))
            {
                SessionState.EraseString(Pending); SessionState.EraseString(Started); SessionState.EraseString(PendingFile);
                SetMessage(new CHToolMessage("已从 GitHub 安装 " + installed.version + "。", "Installed " + installed.version + " from GitHub."));
            }
            else
            {
                DateTime started;
                if (DateTime.TryParse(SessionState.GetString(Started, ""), null, System.Globalization.DateTimeStyles.RoundtripKind, out started) && DateTime.UtcNow - started > TimeSpan.FromMinutes(10))
                { SessionState.EraseString(Pending); SessionState.EraseString(Started); SetMessage(new CHToolMessage(CHToolLanguage.Text(true, "尚未确认安装结果。请查看 Package Manager 的包版本和错误信息，包解析仍可能继续完成。"), CHToolLanguage.Text(false, "尚未确认安装结果。请查看 Package Manager 的包版本和错误信息，包解析仍可能继续完成。")), true); }
            }
        }
    }
}
