using System;
using System.IO;
using System.Reflection;
using System.Security.Cryptography;
using System.Threading;
using System.Threading.Tasks;
using ASEShaderConverter;
using ASEShaderConverter.Editor;
using UnityEditor;
using UnityEngine;

public static class UnityGitHubDownloadSmoke
{
    const string Filename = "com.aseshader.handwritten-converter-0.4.7.tgz";
    const string Expected = "8f95611f89a7c75398a05f46d0ff08b8f86f027885abbecac5a6d795e01cadc9";
    static Task<string> download;
    static string folder;
    static int phase;
    static double timeout;
    static CancellationTokenSource cancellation;
    static Task<string> Download()
    {
        var type = typeof(ShaderPackageUpdater).Assembly.GetType("ASEShaderConverter.Editor.ShaderGitHubClient", true);
        return (Task<string>)type.GetMethod("Download", BindingFlags.Static | BindingFlags.NonPublic).Invoke(null,
            new object[] { ShaderPackageUpdatePolicy.Repository, "v0.4.7", folder, cancellation.Token });
    }
    public static void Run()
    {
        folder = Path.GetFullPath("Artifacts/GitHubDownload048"); Directory.CreateDirectory(folder);
        File.WriteAllText(Path.Combine(folder, Filename), "invalid existing fixture; preserve this file");
        cancellation = new CancellationTokenSource(); download = Download(); timeout = EditorApplication.timeSinceStartup + 660;
        EditorApplication.update += Tick;
    }
    static void Tick()
    {
        try
        {
            if (EditorApplication.timeSinceStartup > timeout) throw new TimeoutException("GitHub Release download exceeded its bound.");
            if (!download.IsCompleted) return;
            if (phase == 0)
            {
                if (!download.IsFaulted || File.ReadAllText(Path.Combine(folder, Filename)) != "invalid existing fixture; preserve this file")
                    throw new Exception("An invalid pre-existing cache must be rejected and preserved.");
                var observed = download.Exception;
                File.Delete(Path.Combine(folder, Filename)); phase = 1; download = Download(); return;
            }
            string path = download.GetAwaiter().GetResult();
            string digest;
            using (var hash = SHA256.Create()) using (var input = File.OpenRead(path)) digest = BitConverter.ToString(hash.ComputeHash(input)).Replace("-", "").ToLowerInvariant();
            if (digest != Expected || Directory.GetFiles(folder, "*.download").Length != 0) throw new Exception("Downloaded release bytes do not match the immutable published archive.");
            Finish(null, digest);
        }
        catch (Exception e) { Finish(e, ""); }
    }
    [Serializable] class Report { public bool success, invalidCachePreserved; public string unity, downloadedTag, sha256, failure; public long bytes; }
    static void Finish(Exception error, string digest)
    {
        EditorApplication.update -= Tick; cancellation.Cancel(); cancellation.Dispose(); Directory.CreateDirectory("Artifacts");
        File.WriteAllText("Artifacts/github-download.json", JsonUtility.ToJson(new Report { success = error == null, invalidCachePreserved = phase == 1,
            unity = Application.unityVersion, downloadedTag = "v0.4.7", sha256 = digest, bytes = error == null ? new FileInfo(Path.Combine(folder, Filename)).Length : 0,
            failure = error == null ? "" : error.ToString() }, true));
        EditorApplication.Exit(error == null ? 0 : 1);
    }
}
