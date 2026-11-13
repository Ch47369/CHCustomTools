// Runs in an isolated, non-batch Editor to exercise the same files an external agent uses.
using System;
using System.IO;
using System.Text;
using UnityEditor;
using UnityEngine;
using ASEShaderConverter.Editor;

public static class UnityAgentSmoke
{
    [Serializable] private sealed class Connection
    {
        public string protocol, projectPath, sessionId, instructionsPath;
        public string requests, responses;
        public string[] operations;
    }
    [Serializable] private sealed class Result
    {
        public bool success;
        public string unityVersion, protocol;
        public string[] operations;
        public ShaderAgentResponse probe, describe, analyze, generate;
    }
    private static readonly UTF8Encoding Utf8 = new UTF8Encoding(false);
    private static readonly string RunId = Guid.NewGuid().ToString("N");
    private static Connection connection;
    private static Result result;
    private static double deadline;
    private static int step;
    private static string pending;

    public static void Run()
    {
        if (Application.isBatchMode) throw new Exception("The file inbox is disabled in batch mode; run this check in a non-batch isolated Editor.");
        result = new Result { unityVersion = Application.unityVersion };
        deadline = EditorApplication.timeSinceStartup + 180;
        EditorApplication.update += Tick;
    }

    private static void Tick()
    {
        try
        {
            if (EditorApplication.timeSinceStartup > deadline) throw new TimeoutException("Agent file protocol did not finish within 180 seconds.");
            if (EditorApplication.isCompiling || EditorApplication.isUpdating) return;
            if (connection == null)
            {
                string path = Path.Combine(ShaderAgentInbox.Root, "connection.json");
                if (!File.Exists(path)) return;
                connection = JsonUtility.FromJson<Connection>(File.ReadAllText(path));
                if (connection.protocol != "ase-converter-files-v1" || string.IsNullOrEmpty(connection.sessionId)
                    || Path.GetFullPath(connection.projectPath) != Path.GetFullPath(".")
                    || !File.Exists(connection.instructionsPath)) throw new Exception("Invalid connection information.");
                result.protocol = connection.protocol;
                result.operations = connection.operations;
            }
            if (pending != null)
            {
                string path = Path.Combine(connection.responses, pending);
                if (!File.Exists(path)) return;
                var response = JsonUtility.FromJson<ShaderAgentResponse>(File.ReadAllText(path));
                if (!response.success) throw new Exception("Inbox request failed: " + JsonUtility.ToJson(response));
                if (step == 1) { result.probe = response; if (response.environment.activePipeline != "BuiltIn") throw new Exception("Use a Built-in isolated project."); }
                if (step == 2) { result.describe = response; if (response.description == null) throw new Exception("Missing template description."); }
                if (step == 3) { result.analyze = response; if (response.report.status != "Planned") throw new Exception("Analysis did not produce a plan."); }
                if (step == 4)
                {
                    result.generate = response;
                    if (response.report.status != "Generated" || !response.report.aseRoundTripPassed || !response.report.shaderCompiled
                        || response.report.customExpressionCount != 0) throw new Exception("Inbox generation was not validated.");
                    result.success = true;
                    File.WriteAllText("agent-inbox.json", JsonUtility.ToJson(result, true), Utf8);
                    Debug.Log("ASE_CONVERTER_AGENT_SMOKE_PASS");
                    EditorApplication.update -= Tick;
                    EditorApplication.Exit(0);
                    return;
                }
                pending = null;
            }
            var request = new ShaderAgentRequest();
            if (step == 0) request.operation = "probe";
            if (step == 1) { request.operation = "describe"; request.templateGuid = "0770190933193b94aaa3065e307002fa"; request.nodeTypes = new[] { "SamplerNode", "SwizzleNode" }; }
            if (step == 2 || step == 3)
            {
                request.operation = step == 2 ? "analyze" : "generate";
                request.sourcePath = "Assets/TintedTexture.shader";
                request.outputPath = "Assets/AgentInbox_" + RunId + ".shader";
            }
            pending = RunId + "-" + step + ".json";
            string destination = Path.Combine(connection.requests, pending);
            File.WriteAllText(destination + ".tmp", JsonUtility.ToJson(request, true), Utf8);
            File.Move(destination + ".tmp", destination);
            step++;
        }
        catch (Exception e)
        {
            File.WriteAllText("agent-inbox-error.txt", e.ToString(), Utf8);
            Debug.LogException(e);
            EditorApplication.update -= Tick;
            EditorApplication.Exit(1);
        }
    }
}
