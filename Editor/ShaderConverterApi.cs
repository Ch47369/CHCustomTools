using System;
using System.Collections.Generic;
using System.IO;
using UnityEditor;
using UnityEngine;

namespace ASEShaderConverter.Editor
{
    [Serializable] public sealed class ShaderAgentRequest
    {
        public int schemaVersion = 1;
        public string operation = "analyze";
        public string sourcePath = "", sourceText = "", outputPath = "", templateGuid = "";
        public string[] nodeTypes = new string[0];
        public ShaderConversionOptions options = new ShaderConversionOptions();
        public ShaderGraphPlan plan;
        public ShaderGraphNativePlan shaderGraphPlan;
    }
    [Serializable] public sealed class ShaderAgentResponse
    {
        public int schemaVersion = 1;
        public bool success;
        public string error = "";
        public AseEnvironmentInfo environment;
        public AseTemplateDescription description;
        public ShaderConversionAnalysis analysis;
        public ShaderConversionReport report;
        public ShaderRuleCatalog ruleLibrary;
        public ShaderLibraryCatalog shaderLibrary;
        public List<ShaderConversionAnalysis> targetAnalyses;
        public ShaderGraphEnvironmentInfo shaderGraphEnvironment;
        public List<ShaderGraphNodeInfo> shaderGraphDescription;
        public ShaderGraphNativeAnalysis shaderGraphAnalysis;
    }

    /// <summary>Call on the Unity Editor main thread, after scripts and ASE templates have loaded.</summary>
    public static class ShaderConverterApi
    {
        public static ShaderConversionAnalysis AnalyzeFile(string sourcePath, ShaderConversionOptions options = null)
        {
            if (options != null && options.targetGraph != "ASE") throw new ArgumentException("AnalyzeFile returns the historical ASE plan. Use Execute(analyze) for ShaderGraph native plans.");
            return ShaderConversionEngine.Analyze(File.ReadAllText(sourcePath), Path.GetFullPath(sourcePath), options);
        }

        public static ShaderConversionReport ConvertFile(string sourcePath, string outputPath, ShaderConversionOptions options = null)
        {
            if (options != null && options.targetGraph == "ShaderGraph") return Execute(new ShaderAgentRequest { operation = "generate", sourcePath = sourcePath, outputPath = outputPath, options = options }).report;
            var analysis = AnalyzeFile(sourcePath, options);
            return analysis.report.CanGenerate ? AseEditorBridge.Generate(analysis.plan, outputPath, analysis.report) : analysis.report;
        }

        public static string ExecuteJson(string requestJson)
        {
            return JsonUtility.ToJson(Execute(JsonUtility.FromJson<ShaderAgentRequest>(requestJson)), true);
        }

        public static ShaderAgentResponse Execute(ShaderAgentRequest request)
        {
            var response = new ShaderAgentResponse();
            try
            {
                if (request == null || request.schemaVersion != 1) throw new ArgumentException("Unsupported or missing request schema.");
                if (EditorApplication.isCompiling || EditorApplication.isUpdating) throw new InvalidOperationException("Wait for Unity script compilation and asset import to finish.");
                if (request.options != null && request.options.targetGraph == "ShaderGraph") return ExecuteShaderGraph(request);
                if (request.options != null && request.options.targetGraph != "ASE") throw new ArgumentException("Unknown targetGraph: " + request.options.targetGraph);
                switch (request.operation)
                {
                    case "library":
                        response.shaderLibrary=ShaderLibraryAssets.Load();response.success=true;break;
                    case "rules":
                        response.ruleLibrary = ShaderRuleLibrary.Catalog(); response.success = true; break;
                    case "probe":
                        response.environment = AseEditorBridge.Probe(); response.success = response.environment.errors.Count == 0; break;
                    case "describe":
                        response.description = AseEditorBridge.DescribeTemplate(request.templateGuid, request.nodeTypes); response.success = true; break;
                    case "analyzeTargets":
                        string targetSource = string.IsNullOrEmpty(request.sourceText) ? File.ReadAllText(request.sourcePath) : request.sourceText;
                        response.targetAnalyses = ShaderConversionEngine.AnalyzeTargets(targetSource, request.sourcePath, request.options);
                        response.success = true; break;
                    case "analyze":
                    case "generate":
                        string source = string.IsNullOrEmpty(request.sourceText) ? File.ReadAllText(request.sourcePath) : request.sourceText;
                        response.analysis = ShaderConversionEngine.Analyze(source, request.sourcePath, request.options);
                        response.report = response.analysis.report;
                        if (request.operation == "generate" && response.report.CanGenerate) AseEditorBridge.Generate(response.analysis.plan, request.outputPath, response.report);
                        response.success = request.operation == "analyze" ? response.report.CanGenerate : response.report.status == "Generated";
                        break;
                    case "generatePlan":
                        response.report = AseEditorBridge.Generate(request.plan, request.outputPath);
                        response.success = response.report.status == "Generated"; break;
                    default: throw new ArgumentException("Unknown operation: " + request.operation);
                }
            }
            catch (Exception e) { response.error = e.Message; }
            return response;
        }

        private static ShaderAgentResponse ExecuteShaderGraph(ShaderAgentRequest request)
        {
            var response = new ShaderAgentResponse();
            switch (request.operation)
            {
                case "probe": response.shaderGraphEnvironment = ShaderGraphEditorBridge.Probe(request.options.targetPipeline); response.success = response.shaderGraphEnvironment.errors.Count == 0; break;
                case "describe": response.shaderGraphDescription = ShaderGraphEditorBridge.Describe(request.nodeTypes,request.options.targetPipeline); response.success = true; break;
                case "generatePlan": response.report = ShaderGraphEditorBridge.Generate(request.shaderGraphPlan,request.outputPath); response.success = response.report.status == "Generated"; break;
                case "analyze":
                case "generate":
                    string source = string.IsNullOrEmpty(request.sourceText) ? File.ReadAllText(request.sourcePath) : request.sourceText;
                    response.shaderGraphAnalysis = ShaderGraphNativePlanner.Analyze(source,request.sourcePath,request.options);
                    response.report = response.shaderGraphAnalysis.report;
                    if (request.operation == "generate" && response.report.CanGenerate) ShaderGraphEditorBridge.Generate(response.shaderGraphAnalysis.plan,request.outputPath,response.report);
                    response.success = request.operation == "analyze" ? response.report.CanGenerate : response.report.status == "Generated"; break;
                default: throw new ArgumentException("Unsupported ShaderGraph operation: " + request.operation);
            }
            return response;
        }

        // Pass -aseRequest request.json -aseResponse response.json with Unity -executeMethod.
        public static void ExecuteCommandLine()
        {
            string[] args = Environment.GetCommandLineArgs();
            string requestPath = Argument(args, "-aseRequest"), responsePath = Argument(args, "-aseResponse");
            var response = new ShaderAgentResponse();
            try { response = Execute(JsonUtility.FromJson<ShaderAgentRequest>(File.ReadAllText(requestPath))); }
            catch (Exception e) { response.error = e.ToString(); }
            if (!string.IsNullOrEmpty(responsePath)) File.WriteAllText(responsePath, JsonUtility.ToJson(response, true));
            if (response.success) Debug.Log("ASE conversion request completed: " + responsePath);
            else Debug.LogError("ASE conversion request failed: " + (string.IsNullOrEmpty(response.error) && response.report != null ? string.Join("\n", response.report.blockers.ToArray()) : response.error));
            if (Application.isBatchMode) EditorApplication.Exit(response.success ? 0 : 1);
        }

        private static string Argument(string[] args, string name)
        {
            int index = Array.IndexOf(args, name);
            return index >= 0 && index + 1 < args.Length ? args[index + 1] : "";
        }
    }
}
