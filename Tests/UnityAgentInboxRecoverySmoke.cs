// Run only in an isolated, non-batch Editor; uses the actual Unity/Mono IO implementation.
using System;
using System.Collections.Generic;
using System.IO;
using System.Reflection;
using System.Text;
using UnityEditor;
using UnityEngine;
using ASEShaderConverter.Editor;

[InitializeOnLoad]
public static class UnityAgentInboxRecoverySmoke
{
    [Serializable] private sealed class Result
    {
        public bool success;
        public string unityVersion, projectPath, initialReplaceError;
        public List<string> checks = new List<string>();
        public List<string> warnings = new List<string>();
        public ShaderAgentResponse probe;
    }
    private static readonly Type Inbox = typeof(ShaderAgentInbox);
    private static readonly BindingFlags Private = BindingFlags.Static | BindingFlags.NonPublic;
    private static readonly UTF8Encoding Utf8 = new UTF8Encoding(false);
    private static Result result;
    static UnityAgentInboxRecoverySmoke()
    {
        const string marker = "LibraryBuildEvidence/run-inbox-recovery-037";
        if (File.Exists(marker)) { File.Move(marker, marker + "." + Guid.NewGuid().ToString("N") + ".started"); Run(); }
    }
    private static void Check(bool value, string name)
    {
        if (!value) throw new Exception(name);
        result.checks.Add(name);
    }
    private static void Set(string name, object value) { Inbox.GetField(name, Private).SetValue(null, value); }
    private static object Get(string name) { return Inbox.GetField(name, Private).GetValue(null); }
    private static void Invoke(string name, params object[] args)
    {
        try { Inbox.GetMethod(name, Private).Invoke(null, args); }
        catch (TargetInvocationException e) { throw e.InnerException; }
    }
    private static void Poll() { Set("nextPoll", 0d); Invoke("Update"); }
    private static void Write(string path, string json) { File.WriteAllText(path, json, Utf8); }
    private static void Capture(string text, string stack, LogType type)
    {
        if (type == LogType.Warning && text.StartsWith("ASE Shader Converter Agent inbox:")) result.warnings.Add(text);
    }
    private static string PublishRequest(string id)
    {
        string path = Path.Combine(ShaderAgentInbox.Root, "requests", id + ".json");
        Write(path + ".tmp", "{\"schemaVersion\":1,\"operation\":\"probe\"}");
        File.Move(path + ".tmp", path);
        return path;
    }
    private static string Response(string request) { return Path.Combine(ShaderAgentInbox.Root, "responses", Path.GetFileName(request)); }
    private static ShaderAgentResponse ReadResponse(string path)
    {
        return JsonUtility.FromJson<ShaderAgentResponse>(File.ReadAllText(path));
    }

    public static void Run()
    {
        if (Application.isBatchMode) throw new Exception("Use an isolated non-batch Editor for inbox recovery checks.");
        if (result != null) return;
        result = new Result { unityVersion = Application.unityVersion, projectPath = Path.GetFullPath(".") };
        Debug.Log("ASE_AGENT_INBOX_RECOVERY_037_START");
        Application.logMessageReceived += Capture;
        EditorApplication.update += StartWhenReady;
    }

    private static void StartWhenReady()
    {
        if (EditorApplication.isCompiling || EditorApplication.isUpdating) return;
        EditorApplication.update -= StartWhenReady;
        RunChecks();
    }

    private static void RunChecks()
    {
        string root = ShaderAgentInbox.Root;
        var update = (EditorApplication.CallbackFunction)Delegate.CreateDelegate(typeof(EditorApplication.CallbackFunction), Inbox.GetMethod("Update", Private));
        EditorApplication.update -= update;
        string runId = "037-" + Guid.NewGuid().ToString("N");
        try
        {
            Directory.CreateDirectory(Path.Combine(root, "requests"));
            Directory.CreateDirectory(Path.Combine(root, "responses"));
            Check(Get("pending") == null && Directory.GetFiles(Path.Combine(root, "requests"), "*.json").Length == 0,
                "Isolated queue has no pending requests");

            string files = Path.Combine(root, runId);
            Directory.CreateDirectory(files);
            string target = Path.Combine(files, "publication.json");
            Invoke("AtomicWrite", target, "{\"value\":\"首次写入\"}");
            Check(File.ReadAllText(target) == "{\"value\":\"首次写入\"}", "First publication preserves UTF-8 JSON");
            Invoke("AtomicWrite", target, "{\"value\":2}");
            Check(File.ReadAllText(target) == "{\"value\":2}", "Existing file can be replaced");
            byte[] bytes = File.ReadAllBytes(target);
            Check(bytes[0] == (byte)'{', "Published JSON has no UTF-8 BOM");

            // A read-only destination forces ReplaceFile to fail on Windows; rename recovery still works.
            File.SetAttributes(target, File.GetAttributes(target) | FileAttributes.ReadOnly);
            string source = Path.Combine(files, "original-replace.tmp");
            Write(source, "{\"value\":3}");
            try { File.Replace(source, target, null); }
            catch (Exception e) when (e is IOException || e is UnauthorizedAccessException) { result.initialReplaceError = e.ToString(); }
            Check(!string.IsNullOrEmpty(result.initialReplaceError) && File.ReadAllText(target) == "{\"value\":2}",
                "Original File.Replace failure reproduced without losing the destination");
            Invoke("AtomicWrite", target, "{\"value\":3}");
            Check(File.ReadAllText(target) == "{\"value\":3}", "Rename fallback publishes complete JSON after ReplaceFile failure");
            Check(Directory.GetFiles(files, "*.previous").Length == 0, "Successful recovery cleans up the previous file");

            using (var locked = new FileStream(target, FileMode.Open, FileAccess.Read, FileShare.Read))
            {
                bool failed = false;
                try { Invoke("AtomicWrite", target, "{\"value\":4}"); }
                catch (IOException e) { failed = e.Message.Contains(target); }
                Check(failed && File.ReadAllText(target) == "{\"value\":3}", "Locked destination remains intact and error identifies its path");
            }
            Invoke("AtomicWrite", target, "{\"value\":4}");
            Check(File.ReadAllText(target) == "{\"value\":4}", "Publication succeeds after the reader releases the lock");
            Check(Directory.GetFiles(files, "publication.json.*.tmp").Length == 0, "Failed and successful writes clean up their temporary files");
            Write(target + ".tmp", "legacy incomplete data");
            Invoke("AtomicWrite", target, "{\"value\":5}");
            Check(File.ReadAllText(target) == "{\"value\":5}" && File.ReadAllText(target + ".tmp") == "legacy incomplete data",
                "Unique temporary names avoid collisions with stale temporary files");

            // Heartbeat failures must not starve the actual queue.
            string connection = Path.Combine(root, "connection.json");
            Set("nextHeartbeat", 0d);
            Poll();
            string oldConnection = File.ReadAllText(connection);
            string request = PublishRequest(runId + "-heartbeat");
            using (var locked = new FileStream(connection, FileMode.Open, FileAccess.Read, FileShare.Read))
            {
                Set("nextHeartbeat", 0d);
                Poll();
                Check(File.ReadAllText(connection) == oldConnection, "Locked heartbeat preserves the previous connection JSON");
                Check(ReadResponse(Response(request)).success && File.Exists(request + ".processing.done"),
                    "A locked heartbeat does not stop request execution and archival");
            }
            Set("nextHeartbeat", 0d);
            Poll();
            Check(File.ReadAllText(connection) != oldConnection, "Heartbeat recovers after lock release");

            // Retain the exact executed response while its destination is temporarily unavailable.
            request = PublishRequest(runId + "-response");
            string responsePath = Response(request);
            Write(responsePath, "{\"old\":true}");
            string following = null;
            object executed;
            using (var locked = new FileStream(responsePath, FileMode.Open, FileAccess.Read, FileShare.Read))
            {
                Poll();
                executed = Get("pending");
                Check(executed != null && File.Exists(request + ".processing") && !File.Exists(request),
                    "Response failure retains the executed request and its response");
                Check(File.ReadAllText(responsePath) == "{\"old\":true}", "Failed publication preserves an existing response");
                following = PublishRequest(runId + "-following");
                Poll();
                Check(ReferenceEquals(executed, Get("pending")) && File.Exists(following),
                    "Retry retains the same response without executing the request or the next request again");
            }
            Poll();
            result.probe = ReadResponse(responsePath);
            Check(result.probe.success && Get("pending") == null && File.Exists(request + ".processing.done"),
                "Cached response is delivered and request archived after lock release");
            Poll();
            Check(ReadResponse(Response(following)).success && File.Exists(following + ".processing.done"),
                "Queue resumes with the next request");

            // A failed .done rename retries only archival, preserving the already published response.
            request = PublishRequest(runId + "-archive");
            string done = request + ".processing.done";
            Write(done, "existing evidence");
            Poll();
            responsePath = Response(request);
            string published = File.ReadAllText(responsePath);
            Check(Get("pending") != null && ReadResponse(responsePath).success && File.ReadAllText(done) == "existing evidence",
                "Archive collision preserves existing evidence and published response");
            File.Move(done, done + ".saved");
            using (var locked = new FileStream(responsePath, FileMode.Open, FileAccess.Read, FileShare.Read)) { Poll(); }
            Check(Get("pending") == null && File.Exists(done) && File.ReadAllText(responsePath) == published,
                "Archive retry does not rewrite or re-execute the completed response");
            Check(result.warnings.Count >= 4 && result.warnings.Exists(w => w.Contains(connection))
                && result.warnings.Exists(w => w.Contains(responsePath)) && result.warnings.Exists(w => w.Contains("IOException")),
                "Failure diagnostics identify the operation, file path and exception");
            Check(!(bool)Get("processing"), "Polling guard is released after failures");
            result.success = true;
        }
        catch (Exception e)
        {
            Directory.CreateDirectory("LibraryBuildEvidence");
            Write("LibraryBuildEvidence/agent-inbox-recovery-037-error.txt", e.ToString());
            Debug.LogException(e);
        }
        finally
        {
            Application.logMessageReceived -= Capture;
            EditorApplication.update += update;
            Directory.CreateDirectory("LibraryBuildEvidence");
            Write("LibraryBuildEvidence/agent-inbox-recovery-037.json", JsonUtility.ToJson(result, true));
            Debug.Log(result.success ? "ASE_AGENT_INBOX_RECOVERY_037_PASS" : "ASE_AGENT_INBOX_RECOVERY_037_FAIL");
            EditorApplication.Exit(result.success ? 0 : 1);
        }
    }
}
