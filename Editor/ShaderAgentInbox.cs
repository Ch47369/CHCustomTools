using System;
using System.IO;
using System.Text;
using UnityEditor;
using UnityEngine;

namespace ASEShaderConverter.Editor
{
    /// <summary>Local file protocol for agents that cannot invoke Unity Editor C# directly.</summary>
    [InitializeOnLoad]
    public static class ShaderAgentInbox
    {
        [Serializable] private sealed class Connection
        {
            public int schemaVersion = 1;
            public string protocol = "ase-converter-files-v1", unityVersion, projectPath, sessionId;
            public string requests, responses, updatedUtc;
            public string instructionsPath = "";
            public string[] operations = { "probe", "describe", "rules", "analyze", "analyzeTargets", "generate", "generatePlan" };
        }

        private static readonly string Session = Guid.NewGuid().ToString("N");
        private static double nextPoll, nextHeartbeat;
        private static bool processing;
        private sealed class PendingResponse
        {
            public string claimed, destination, json;
            public bool published;
        }
        private static PendingResponse pending;
        public static string Root { get { return Path.GetFullPath("Library/ASEShaderConverter/Agent"); } }

        static ShaderAgentInbox() { EditorApplication.update += Update; }

        public static void OpenInbox() { EnsureDirectories(); ASEShaderConverterWindow.OpenAgent(); }

        private static void EnsureDirectories()
        {
            Directory.CreateDirectory(Path.Combine(Root, "requests"));
            Directory.CreateDirectory(Path.Combine(Root, "responses"));
        }

        private static void Update()
        {
            if (processing || Application.isBatchMode || EditorApplication.isCompiling || EditorApplication.isUpdating || EditorApplication.isPlayingOrWillChangePlaymode || EditorApplication.timeSinceStartup < nextPoll) return;
            nextPoll = EditorApplication.timeSinceStartup + 1;
            processing = true;
            string operation = "准备接入目录 " + Root;
            try
            {
                EnsureDirectories();
                if (EditorApplication.timeSinceStartup >= nextHeartbeat)
                {
                    nextHeartbeat = EditorApplication.timeSinceStartup + 15;
                    string connectionPath = Path.Combine(Root, "connection.json");
                    try
                    {
                        var connection = new Connection { unityVersion = Application.unityVersion, projectPath = Path.GetFullPath("."), sessionId = Session,
                            requests = Path.Combine(Root, "requests"), responses = Path.Combine(Root, "responses"), updatedUtc = DateTime.UtcNow.ToString("O") };
                        var package = UnityEditor.PackageManager.PackageInfo.FindForAssembly(typeof(ShaderConverterApi).Assembly);
                        if (package != null) connection.instructionsPath = Path.Combine(package.resolvedPath, "Documentation~/AgentProtocol.md");
                        AtomicWrite(connectionPath, JsonUtility.ToJson(connection, true));
                    }
                    catch (Exception e)
                    {
                        // A locked heartbeat must not stop requests or pending response delivery.
                        nextHeartbeat = EditorApplication.timeSinceStartup + 30;
                        Warn("更新连接信息 " + connectionPath, e);
                    }
                }
                if (pending != null) { operation = "提交响应/归档请求 " + pending.destination + " / " + pending.claimed; CompletePending(); return; }
                string[] requests = Directory.GetFiles(Path.Combine(Root, "requests"), "*.json");
                Array.Sort(requests, StringComparer.Ordinal);
                if (requests.Length == 0) return;
                string request = requests[0], claimed = request + ".processing";
                // Agents publish a complete request by atomically renaming .tmp to .json.
                operation = "认领请求 " + request;
                File.Move(request, claimed);
                ShaderAgentResponse response;
                try { response = ShaderConverterApi.Execute(JsonUtility.FromJson<ShaderAgentRequest>(File.ReadAllText(claimed))); }
                catch (Exception e) { response = new ShaderAgentResponse { error = e.Message }; }
                pending = new PendingResponse { claimed = claimed, destination = Path.Combine(Root, "responses", Path.GetFileName(request)), json = JsonUtility.ToJson(response, true) };
                operation = "提交响应/归档请求 " + pending.destination + " / " + claimed;
                CompletePending();
            }
            catch (Exception e)
            {
                // Back off on disk failures instead of logging every editor frame.
                nextPoll = EditorApplication.timeSinceStartup + 30;
                Warn(operation, e);
            }
            finally { processing = false; }
        }

        private static void CompletePending()
        {
            // Retry only publication/archival after an IO failure, never Execute again.
            if (!pending.published) { AtomicWrite(pending.destination, pending.json); pending.published = true; }
            File.Move(pending.claimed, pending.claimed + ".done");
            pending = null;
        }

        private static void Warn(string operation, Exception error)
        {
            Debug.LogWarning("ASE Shader Converter Agent inbox: " + operation + "\n" + error);
        }

        private static void AtomicWrite(string path, string text)
        {
            string temporary = path + "." + Guid.NewGuid().ToString("N") + ".tmp";
            try
            {
                File.WriteAllText(temporary, text, new UTF8Encoding(false));
                if (!File.Exists(path)) { File.Move(temporary, path); return; }
                try { File.Replace(temporary, path, null); }
                catch (Exception e) when (e is IOException || e is UnauthorizedAccessException || e is PlatformNotSupportedException)
                {
                    // Some Unity/Mono file systems reject ReplaceFile even though renames work.
                    // Keep the complete old file until the new file is published; never delete it first.
                    if (!File.Exists(temporary) || !File.Exists(path)) throw;
                    string previous = path + "." + Guid.NewGuid().ToString("N") + ".previous";
                    File.Move(path, previous);
                    try { File.Move(temporary, path); }
                    catch (Exception publishError)
                    {
                        try { File.Move(previous, path); }
                        catch (Exception restoreError)
                        {
                            throw new IOException("无法恢复 Agent 文件，原文件保留在 " + previous,
                                new AggregateException(e, publishError, restoreError));
                        }
                        throw;
                    }
                    DeleteTemporary(previous);
                }
            }
            catch (Exception e) { throw new IOException("无法写入 Agent 文件 " + path + ": " + e.Message, e); }
            finally { DeleteTemporary(temporary); }
        }

        private static void DeleteTemporary(string path)
        {
            try
            {
                if (!File.Exists(path)) return;
                File.SetAttributes(path, File.GetAttributes(path) & ~FileAttributes.ReadOnly);
                File.Delete(path);
            }
            catch (IOException) { }
            catch (UnauthorizedAccessException) { }
        }
    }
}
