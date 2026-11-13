using System;
using System.ComponentModel;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;

namespace ASEShaderConverter.Editor
{
    internal enum ShaderGitFailure { None, GitUnavailable, Authentication, AccessDenied, Network, Timeout, Cancelled, InvalidRelease, Integrity, Installation, Unknown }
    internal sealed class ShaderGitCheckException : Exception
    {
        internal readonly ShaderGitFailure Kind;
        internal ShaderGitCheckException(ShaderGitFailure kind) : base(kind.ToString()) { Kind = kind; }
    }
    // No Unity API, shell, embedded credentials or persisted Git diagnostics.
    internal static class ShaderGitClient
    {
        internal static ShaderGitFailure Classify(string diagnostic)
        {
            string text = (diagnostic ?? "").ToLowerInvariant();
            if (Contains(text, "no git executable was found", "git executable not found", "git is not installed")) return ShaderGitFailure.GitUnavailable;
            if (Contains(text, "could not resolve", "failed to connect", "couldn't connect", "unable to connect", "connection timed out", "connection reset", "network is unreachable", "ssl certificate", "schannel:", "gnutls", "tls connection", "http/2 stream", "proxy", "error: 502", "error: 503", "error: 504")) return ShaderGitFailure.Network;
            if (Contains(text, "authentication failed", "could not read username", "could not read password", "terminal prompts disabled", "cannot prompt", "user cancelled", "error: 401")) return ShaderGitFailure.Authentication;
            if (Contains(text, "repository not found", "permission denied", "access denied", "error: 403", "could not read from remote repository")) return ShaderGitFailure.AccessDenied;
            if (Contains(text, "timed out", "timeout")) return ShaderGitFailure.Timeout;
            return ShaderGitFailure.Unknown;
        }
        static bool Contains(string text, params string[] values) { return values.Any(text.Contains); }
        internal static string FindGit(string path, string[] extraCandidates, bool windows)
        {
            foreach (string folder in (path ?? "").Split(windows ? ';' : ':'))
            {
                if (string.IsNullOrWhiteSpace(folder)) continue;
                try
                {
                    string candidate = Path.GetFullPath(Path.Combine(folder.Trim(' ', '"'), windows ? "git.exe" : "git"));
                    if (File.Exists(candidate)) return candidate;
                }
                catch (Exception e) when (e is ArgumentException || e is IOException || e is NotSupportedException) { }
            }
            return (extraCandidates ?? new string[0]).FirstOrDefault(File.Exists);
        }
        internal static string GitExecutable()
        {
            bool windows = Environment.OSVersion.Platform == PlatformID.Win32NT;
            string[] candidates = windows ? new[] {
                Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles), "Git", "cmd", "git.exe"),
                Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFilesX86), "Git", "cmd", "git.exe"),
                Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "Programs", "Git", "cmd", "git.exe")
            } : new[] { "/usr/bin/git", "/usr/local/bin/git", "/opt/homebrew/bin/git" };
            string path = Environment.GetEnvironmentVariable("PATH") ?? "";
            if (windows) path += ";" + Environment.GetEnvironmentVariable("PATH", EnvironmentVariableTarget.Machine) + ";" + Environment.GetEnvironmentVariable("PATH", EnvironmentVariableTarget.User);
            string executable = FindGit(path, candidates, windows);
            if (executable == null) throw new ShaderGitCheckException(ShaderGitFailure.GitUnavailable);
            return executable;
        }
        internal static async Task<ShaderPackageRelease> ReadTags(string repository, bool authenticate, CancellationToken token)
        {
            if (!ShaderPackageUpdatePolicy.IsRepository(repository)) throw new ArgumentException("Unsupported repository.");
            string executable = GitExecutable();
            try { return await Query(executable, repository, authenticate, false, token).ConfigureAwait(false); }
            catch (ShaderGitCheckException e) when (!authenticate && repository == ShaderPackageUpdatePolicy.Repository && (e.Kind == ShaderGitFailure.Network || e.Kind == ShaderGitFailure.Timeout))
            {
                // One transport retry, retaining hostname/TLS verification and the same credentials.
                return await Query(executable, repository, false, true, token).ConfigureAwait(false);
            }
        }
        static async Task<ShaderPackageRelease> Query(string executable, string repository, bool authenticate, bool retry, CancellationToken token)
        {
            using (var process = new Process())
            {
                process.StartInfo = new ProcessStartInfo {
                    FileName = executable,
                    Arguments = "-c credential.interactive=" + (authenticate ? "true" : "never") + (retry ? " -c http.version=HTTP/1.1" : "") + " ls-remote --tags --refs \"" + repository + "\"",
                    UseShellExecute = false, CreateNoWindow = true, RedirectStandardOutput = true, RedirectStandardError = true
                };
                process.StartInfo.EnvironmentVariables["GIT_TERMINAL_PROMPT"] = "0";
                process.StartInfo.EnvironmentVariables["GCM_INTERACTIVE"] = authenticate ? "always" : "never";
                if ((repository == ShaderPackageUpdatePolicy.SshRepository || repository == ShaderPackageUpdatePolicy.LegacySshRepository)) process.StartInfo.EnvironmentVariables["GIT_SSH_COMMAND"] = "ssh -o BatchMode=yes -o ConnectTimeout=10";
                bool started = false;
                Task<string> output = null, diagnostic = null;
                try
                {
                    token.ThrowIfCancellationRequested();
                    process.Start(); started = true;
                    output = process.StandardOutput.ReadToEndAsync(); diagnostic = process.StandardError.ReadToEndAsync();
                    var timer = Stopwatch.StartNew();
                    while (!process.HasExited || !output.IsCompleted || !diagnostic.IsCompleted)
                    {
                        token.ThrowIfCancellationRequested();
                        if (timer.Elapsed.TotalSeconds > (authenticate ? 120 : retry ? 15 : 20)) throw new ShaderGitCheckException(ShaderGitFailure.Timeout);
                        await Task.Delay(50, token).ConfigureAwait(false);
                    }
                    string tags = await output.ConfigureAwait(false), error = await diagnostic.ConfigureAwait(false);
                    if (process.ExitCode != 0) throw new ShaderGitCheckException(Classify(error));
                    return ShaderPackageUpdatePolicy.Latest(tags);
                }
                catch (Win32Exception e) { throw new ShaderGitCheckException(e.NativeErrorCode == 2 || e.NativeErrorCode == 3 ? ShaderGitFailure.GitUnavailable : ShaderGitFailure.Unknown); }
                finally
                {
                    if (started)
                    {
                        try { if (!process.HasExited) process.Kill(); } catch (InvalidOperationException) { } catch (Win32Exception) { }
                        // A helper may retain a pipe after Git exits; never let it defeat the timeout.
                        Observe(output); Observe(diagnostic);
                    }
                }
            }
        }
        static void Observe(Task task)
        {
            if (task != null) task.ContinueWith(t => { var ignored = t.Exception; }, TaskContinuationOptions.OnlyOnFaulted);
        }
    }
}
