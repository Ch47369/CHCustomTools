using System;
using System.Diagnostics;
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
                return CHToolLanguage.Text("私有仓库需要本机 Git 已认证。更新会锁定选定的正式版本，不会自动跟随分支。");
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
        public static void CheckForUpdates()
        {
            if (!CanCheck) return;
            Latest = null;
            restored = true;
            SessionState.SetString(LastAttempt, DateTime.UtcNow.ToString("o"));
            SessionState.EraseString(CachedTag);
            SessionState.SetString(CachedRepository, Repository);
            cancellation = new CancellationTokenSource();
            check = ReadTags(Repository, cancellation.Token);
            SetMessage(new CHToolMessage(CHToolLanguage.Text(true, "正在检查正式版本…"), CHToolLanguage.Text(false, "正在检查正式版本…")));
        }
        static async Task<ShaderPackageRelease> ReadTags(string repository, CancellationToken token)
        {
            // Repository is a fixed allowlist; no shell and no token is read or stored.
            if (!ShaderPackageUpdatePolicy.IsRepository(repository)) throw new ArgumentException("Unsupported repository.");
            using (var process = new Process())
            {
                process.StartInfo = new ProcessStartInfo {
                    FileName = "git", Arguments = "-c credential.interactive=never ls-remote --tags --refs \"" + repository + "\"",
                    UseShellExecute = false, CreateNoWindow = true, RedirectStandardOutput = true, RedirectStandardError = true
                };
                process.StartInfo.EnvironmentVariables["GIT_TERMINAL_PROMPT"] = "0";
                process.StartInfo.EnvironmentVariables["GCM_INTERACTIVE"] = "never";
                if (repository == ShaderPackageUpdatePolicy.SshRepository) process.StartInfo.EnvironmentVariables["GIT_SSH_COMMAND"] = "ssh -o BatchMode=yes -o ConnectTimeout=10";
                try
                {
                    process.Start();
                    var output = process.StandardOutput.ReadToEndAsync();
                    var error = process.StandardError.ReadToEndAsync();
                    var timer = Stopwatch.StartNew();
                    while (!process.HasExited)
                    {
                        token.ThrowIfCancellationRequested();
                        if (timer.Elapsed.TotalSeconds > 30) throw new TimeoutException("Git check timed out.");
                        await Task.Delay(50, token).ConfigureAwait(false);
                    }
                    string tags = await output.ConfigureAwait(false);
                    await error.ConfigureAwait(false); // Drain stderr without exposing credential-helper diagnostics.
                    if (process.ExitCode != 0) throw new InvalidOperationException("Git exited with code " + process.ExitCode + ".");
                    return ShaderPackageUpdatePolicy.Latest(tags);
                }
                finally { try { if (!process.HasExited) process.Kill(); } catch (InvalidOperationException) { } }
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
                    // Observe the exception, but never display Git/credential-helper diagnostics.
                    var ignored = completed.Exception;
                    SessionState.SetBool(LastFailed, true);
                    SetMessage(new CHToolMessage(CHToolLanguage.Text(true, "检查更新失败。请确认 Git 已安装、当前账号有私有仓库访问权限及网络可用，然后重试。"), CHToolLanguage.Text(false, "检查更新失败。请确认 Git 已安装、当前账号有私有仓库访问权限及网络可用，然后重试。")), true);
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
                if (installation.Status == StatusCode.Failure) { installation = null; SessionState.EraseString(Pending); SessionState.EraseString(Started); SetMessage(new CHToolMessage(CHToolLanguage.Text(true, "更新未完成。请在 Package Manager 查看错误并检查 Git 认证或网络；当前包引用以 Unity 的解析结果为准。"), CHToolLanguage.Text(false, "更新未完成。请在 Package Manager 查看错误并检查 Git 认证或网络；当前包引用以 Unity 的解析结果为准。")), true); return; }
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
