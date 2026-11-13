using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine.Networking;
using System.IO;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Security.Cryptography;
using System.Text.RegularExpressions;
using System.Threading;
using System.Threading.Tasks;
using UnityEngine;

namespace ASEShaderConverter.Editor
{
    // GitHub API transport. Public release transport: no credentials, Git executable, clone or local repository lookup.
    [InitializeOnLoad]
    internal static class ShaderGitHubClient
    {
        const string Api = "https://api.github.com/repos/Ch47369/CHCustomTools/";
        internal static int Progress { get; private set; }
        #pragma warning disable 0649 // Unity JsonUtility populates GitHub response fields.
        [Serializable] sealed class Release { public string tag_name; public bool draft, prerelease; public Asset[] assets; }
        [Serializable] sealed class Asset { public long id, size; public string name, digest; }

        #pragma warning restore 0649

        static HttpClient Client()
        {
            var client = new HttpClient(new HttpClientHandler { AllowAutoRedirect = false }) { Timeout = TimeSpan.FromSeconds(20), MaxResponseContentBufferSize = 1024 * 1024 };
            client.DefaultRequestHeaders.UserAgent.ParseAdd("CH-Custom-Tools-Updater");
            client.DefaultRequestHeaders.Add("X-GitHub-Api-Version", "2022-11-28");
            return client;
        }
        static void Check(HttpResponseMessage response)
        {
            if (response.StatusCode == HttpStatusCode.Unauthorized) throw new ShaderGitCheckException(ShaderGitFailure.Network);
            if (response.StatusCode == HttpStatusCode.NotFound) throw new ShaderGitCheckException(ShaderGitFailure.InvalidRelease);
            if (!response.IsSuccessStatusCode) throw new ShaderGitCheckException(ShaderGitFailure.Network);
        }
        static async Task<Release> Read(HttpClient client, string suffix, CancellationToken token)
        {
            using (var request = new HttpRequestMessage(HttpMethod.Get, Api + suffix))
            {
                request.Headers.Accept.Add(new MediaTypeWithQualityHeaderValue("application/vnd.github+json"));
                using (var response = await client.SendAsync(request, HttpCompletionOption.ResponseContentRead, token).ConfigureAwait(false))
                {
                    Check(response);
                    if (response.Content.Headers.ContentLength > 1024 * 1024) throw new ShaderGitCheckException(ShaderGitFailure.InvalidRelease);
                    string json = await response.Content.ReadAsStringAsync().ConfigureAwait(false);
                    if (json.Length > 1024 * 1024) throw new ShaderGitCheckException(ShaderGitFailure.InvalidRelease);
                    var release = JsonUtility.FromJson<Release>(json); Version version;
                    if (release == null || release.draft || release.prerelease || release.tag_name == null || !release.tag_name.StartsWith("v", StringComparison.Ordinal) ||
                        !ShaderPackageUpdatePolicy.TryVersion(release.tag_name.Substring(1), out version)) throw new ShaderGitCheckException(ShaderGitFailure.InvalidRelease);
                    return release;
                }
            }
        }
        internal static async Task<ShaderPackageRelease> Latest(string repository, bool authenticate, CancellationToken token)
        {
            if (!ShaderPackageUpdatePolicy.IsHttpsRepository(repository)) throw new ArgumentException("Unsupported repository.");
            try
            {
                using (var client = Client())
                {
                    var release = await Read(client, "releases/latest", token).ConfigureAwait(false);
                    return new ShaderPackageRelease { tag = release.tag_name, version = new Version(release.tag_name.Substring(1)) };
                }
            }
            catch (HttpRequestException) { throw new ShaderGitCheckException(ShaderGitFailure.Network); }
            catch (TaskCanceledException) { if (token.IsCancellationRequested) throw; throw new ShaderGitCheckException(ShaderGitFailure.Timeout); }
        }
        internal static async Task<string> Download(string repository, string tag, string folder, CancellationToken token)
        {
            ShaderPackageUpdatePolicy.InstallationUrl(repository, tag);
            if (!ShaderPackageUpdatePolicy.IsHttpsRepository(repository)) throw new ArgumentException("Unsupported repository.");
            Progress = 0; string temporary = null;
            try
            {
                using (var client = Client())
                {
                    var release = await Read(client, "releases/tags/" + tag, token).ConfigureAwait(false);
                    if (release.tag_name != tag) throw new ShaderGitCheckException(ShaderGitFailure.InvalidRelease);
                    string filename = ShaderPackageUpdatePolicy.PackageName + "-" + tag.Substring(1) + ".tgz";
                    Asset asset = Array.Find(release.assets ?? new Asset[0], a => a.name == filename);
                    if (asset == null || asset.id <= 0 || asset.size <= 0 || asset.size > 256L * 1024 * 1024 ||
                        !Regex.IsMatch(asset.digest ?? "", "^sha256:[0-9a-f]{64}$")) throw new ShaderGitCheckException(ShaderGitFailure.InvalidRelease);
                    Directory.CreateDirectory(folder); string destination = Path.Combine(folder, filename);
                    if (File.Exists(destination))
                    {
                        if (Valid(destination, asset)) { Progress = 100; return destination; }
                        throw new ShaderGitCheckException(ShaderGitFailure.Integrity); // Preserve an existing cache that does not match this release.
                    }
                    temporary = destination + "." + Guid.NewGuid().ToString("N") + ".download";
                    using (var request = new HttpRequestMessage(HttpMethod.Get, Api + "releases/assets/" + asset.id + "?download=1"))
                    {
                        request.Headers.Accept.Add(new MediaTypeWithQualityHeaderValue("application/octet-stream"));
                        using (var response = await client.SendAsync(request, HttpCompletionOption.ResponseHeadersRead, token).ConfigureAwait(false))
                        {
                            var location = response.Headers.Location;
                            if ((int)response.StatusCode != 302 && (int)response.StatusCode != 307) { Check(response); throw new ShaderGitCheckException(ShaderGitFailure.InvalidRelease); }
                            if (location == null || !location.IsAbsoluteUri || location.Scheme != "https" || location.UserInfo.Length != 0 ||
                                (location.Host != "release-assets.githubusercontent.com" && location.Host != "objects.githubusercontent.com"))
                                throw new ShaderGitCheckException(ShaderGitFailure.InvalidRelease);
                            // The signed CDN URL goes to Unity's native HTTP transport, with no GitHub Authorization header.
                            var transfer = new Transfer { url = location.AbsoluteUri, file = temporary, token = token, size = asset.size };
                            transfers.Enqueue(transfer);
                            await transfer.completion.Task.ConfigureAwait(false);
                        }
                    }
                    if (!Valid(temporary, asset)) throw new ShaderGitCheckException(ShaderGitFailure.Integrity);
                    File.Move(temporary, destination); temporary = null; Progress = 100; return destination;
                }
            }
            catch (HttpRequestException) { throw new ShaderGitCheckException(ShaderGitFailure.Network); }
            catch (OperationCanceledException) { if (token.IsCancellationRequested) throw; throw new ShaderGitCheckException(ShaderGitFailure.Timeout); }
            finally { if (temporary != null && File.Exists(temporary)) File.Delete(temporary); }
        }
        sealed class Transfer
        {
            internal string url, file;
            internal long size, assigned, completed;
            internal double began;
            internal CancellationToken token;
            internal readonly List<RangeDownload> ranges = new List<RangeDownload>();
            internal readonly TaskCompletionSource<bool> completion = new TaskCompletionSource<bool>(TaskCreationOptions.RunContinuationsAsynchronously);
        }
        sealed class RangeDownload
        {
            internal long start, end;
            internal string file;
            internal double began;
            internal int retries;
            internal UnityWebRequest request;
            internal UnityWebRequestAsyncOperation operation;
        }
        const int ChunkSize = 512 * 1024;
        static readonly ConcurrentQueue<Transfer> transfers = new ConcurrentQueue<Transfer>();
        static Transfer active;
        static ShaderGitHubClient()
        {
            EditorApplication.update += Pump;
            EditorApplication.quitting += Stop;
            AssemblyReloadEvents.beforeAssemblyReload += Stop;
        }
        static void Stop()
        {
            if (active != null) Complete(ShaderGitFailure.Cancelled);
            Transfer waiting; while (transfers.TryDequeue(out waiting)) waiting.completion.TrySetCanceled();
        }
        static void Clean(RangeDownload range)
        {
            if (range.request != null) { if (range.operation == null || !range.operation.isDone) range.request.Abort(); range.request.Dispose(); range.request = null; }
            if (File.Exists(range.file)) File.Delete(range.file);
        }
        static void Complete(ShaderGitFailure failure)
        {
            foreach (var range in active.ranges) { try { Clean(range); } catch (IOException) { } catch (UnauthorizedAccessException) { } }
            if (failure == ShaderGitFailure.None) active.completion.TrySetResult(true);
            else if (failure == ShaderGitFailure.Cancelled) active.completion.TrySetCanceled();
            else active.completion.TrySetException(new ShaderGitCheckException(failure));
            active = null;
        }
        static void StartRange(RangeDownload range)
        {
            range.request = new UnityWebRequest(active.url, UnityWebRequest.kHttpVerbGET);
            range.request.SetRequestHeader("Range", "bytes=" + range.start + "-" + range.end);
            range.request.downloadHandler = new DownloadHandlerFile(range.file) { removeFileOnAbort = true };
            range.request.timeout = 30; range.request.redirectLimit = 0;
            range.operation = range.request.SendWebRequest(); range.began = EditorApplication.timeSinceStartup;
        }
        static void Pump()
        {
            try { PumpTransfer(); }
            catch (Exception) { if (active != null) Complete(ShaderGitFailure.Installation); }
        }
        static void PumpTransfer()
        {
            if (active == null)
            {
                if (!transfers.TryDequeue(out active)) return;
                active.began = EditorApplication.timeSinceStartup;
                using (var output = new FileStream(active.file, FileMode.CreateNew, FileAccess.Write, FileShare.None)) output.SetLength(active.size);
            }
            if (active.token.IsCancellationRequested) { Complete(ShaderGitFailure.Cancelled); return; }
            if (EditorApplication.timeSinceStartup - active.began > 600) { Complete(ShaderGitFailure.Timeout); return; }
            long inFlight = 0;
            for (int i = active.ranges.Count - 1; i >= 0; i--)
            {
                var range = active.ranges[i];
                bool timedOut = EditorApplication.timeSinceStartup - range.began > 35;
                if (!range.operation.isDone && !timedOut) { inFlight += (long)range.request.downloadedBytes; continue; }
                bool success = range.operation.isDone && range.request.result == UnityWebRequest.Result.Success && range.request.responseCode == 206 &&
                    range.request.GetResponseHeader("Content-Range") == "bytes " + range.start + "-" + range.end + "/" + active.size;
                if (!success)
                {
                    Clean(range);
                    if (range.retries++ < 1) { StartRange(range); continue; }
                    Complete(timedOut ? ShaderGitFailure.Timeout : ShaderGitFailure.Network); return;
                }
                range.request.Dispose(); range.request = null;
                if (new FileInfo(range.file).Length != range.end - range.start + 1) { Complete(ShaderGitFailure.Integrity); return; }
                using (var output = new FileStream(active.file, FileMode.Open, FileAccess.Write, FileShare.None))
                using (var input = File.OpenRead(range.file)) { output.Position = range.start; input.CopyTo(output); }
                File.Delete(range.file); active.completed += range.end - range.start + 1; active.ranges.RemoveAt(i);
            }
            Progress = Math.Max(0, Math.Min(99, (int)((active.completed + inFlight) * 100 / active.size)));
            while (active.ranges.Count < 4 && active.assigned < active.size)
            {
                var range = new RangeDownload { start = active.assigned, end = Math.Min(active.size - 1, active.assigned + ChunkSize - 1), file = active.file + ".part-" + active.assigned };
                active.assigned = range.end + 1; active.ranges.Add(range); StartRange(range);
            }
            if (active.completed == active.size) Complete(ShaderGitFailure.None);
        }
        static bool Valid(string path, Asset asset)
        {
            if (new FileInfo(path).Length != asset.size) return false;
            using (var file = File.OpenRead(path)) using (var hash = SHA256.Create())
                return "sha256:" + BitConverter.ToString(hash.ComputeHash(file)).Replace("-", "").ToLowerInvariant() == asset.digest;
        }
    }
}
