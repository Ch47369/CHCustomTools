// Isolated-project integration check. SRP packages and ASE must be installed there.
using System;
using System.IO;
using System.Linq;
using System.Collections.Concurrent;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;
using ASEShaderConverter;
using ASEShaderConverter.Editor;

public static class UnitySrpSmoke
{
    public static void Run()
    {
        string[] args = Environment.GetCommandLineArgs();
        int index = Array.IndexOf(args, "-asePipeline");
        string pipeline = index >= 0 && index + 1 < args.Length ? args[index + 1] : "URP";
        string typeName = pipeline == "URP" ? "UnityEngine.Rendering.Universal.UniversalRenderPipelineAsset" : "UnityEngine.Rendering.HighDefinition.HDRenderPipelineAsset";
        Type type = AppDomain.CurrentDomain.GetAssemblies().Select(a => a.GetType(typeName, false)).FirstOrDefault(t => t != null);
        if (type == null) throw new Exception("Install the matching SRP package before running this check.");
        string assetPath = "Assets/SmokePipelineConfigured.asset";
        var asset = AssetDatabase.LoadAssetAtPath<RenderPipelineAsset>(assetPath);
        if (asset == null)
        {
            asset = pipeline == "URP"
                ? (RenderPipelineAsset)type.GetMethod("Create").Invoke(null, new object[] { null })
                : (RenderPipelineAsset)ScriptableObject.CreateInstance(type);
            AssetDatabase.CreateAsset(asset, assetPath);
            if (pipeline == "URP")
            {
                // The factory creates a renderer in memory; persist it with its pipeline asset.
                var serialized = new SerializedObject(asset);
                var renderer = serialized.FindProperty("m_RendererDataList").GetArrayElementAtIndex(0).objectReferenceValue;
                if (renderer == null) throw new Exception("URP factory did not create renderer data.");
                AssetDatabase.AddObjectToAsset(renderer, asset);
                AssetDatabase.SaveAssets();
            }
        }
        // This checks template generation and pass compilation, not a configured SRP scene.
        GraphicsSettings.renderPipelineAsset = asset;
        QualitySettings.renderPipeline = asset;
        // -executeMethod runs before a camera/frame initializes the pipeline. Select the
        // real pipeline shader tag explicitly for this pass-compilation fixture.
        Shader.globalRenderPipeline = pipeline == "URP" ? "UniversalPipeline" : "HDRenderPipeline";
        // Batch execution may precede ASE's deferred package update. Use ASE's own
        // manifest/version selection, never copy or edit template text ourselves.
        AmplifyShaderEditor.TemplateTracker.ScanTemplateManifests();
        var updated = new ConcurrentBag<string>();
        AmplifyShaderEditor.ASEPackageManagerHelper.CheckActivePackages(UnityEditor.PackageManager.PackageInfo.GetAllRegisteredPackages(), updated);
        foreach (string path in updated) AssetDatabase.ImportAsset(path, ImportAssetOptions.ForceSynchronousImport | ImportAssetOptions.ForceUpdate);
        AmplifyShaderEditor.TemplatesManager.Instance.RefreshAvailableTemplates();
        var env = AseEditorBridge.Probe();
        File.WriteAllText("environment.json", JsonUtility.ToJson(env, true));
        if (env.errors.Count > 0 || env.activePipeline != pipeline) throw new Exception(JsonUtility.ToJson(env, true));
        string guid = pipeline == "URP" ? AseEditorBridge.UrpUnlitGuid : AseEditorBridge.HdrpUnlitGuid;
        if (!env.templates.Any(t => t.guid == guid && t.ready)) throw new Exception("ASE has not activated the SRP template. Let ASE's package/template update finish and retry.");
        File.WriteAllText("template.json", JsonUtility.ToJson(AseEditorBridge.DescribeTemplate(guid, "SwizzleNode", "CustomExpressionNode"), true));

        var plan = new ShaderGraphPlan { shaderName = "Smoke/Native" + pipeline, pipeline = pipeline, templateGuid = guid };
        plan.nodes.Add(new ShaderNodePlan { id = "color", type = "Vector4Node", value = "(0.4,0.6,0.8,1)" });
        plan.nodes.Add(new ShaderNodePlan { id = "rgb", type = "SwizzleNode", swizzle = "xyz", outputType = "FLOAT3" });
        plan.nodes.Add(new ShaderNodePlan { id = "alpha", type = "SwizzleNode", swizzle = "w", outputType = "FLOAT" });
        plan.wires.Add(new ShaderWirePlan { from = "color", to = "rgb" });
        plan.wires.Add(new ShaderWirePlan { from = "color", to = "alpha" });
        plan.outputs.Add(new ShaderOutputPlan { node = "rgb", masterPort = "Color" });
        plan.outputs.Add(new ShaderOutputPlan { node = "alpha", masterPort = "Alpha" });
        if (pipeline == "URP")
        {
            plan.masterSettings.Add(new NodeSetting("option:  Keep Alpha", "true"));
            plan.masterSettings.Add(new NodeSetting("option:Cast Shadows", "false"));
        }
        var report = AseEditorBridge.Generate(plan, AssetDatabase.GenerateUniqueAssetPath("Assets/NativePipeline_ASE.shader"));
        File.WriteAllText("conversion.json", JsonUtility.ToJson(report, true));
        if (report.status != "Generated") throw new Exception(JsonUtility.ToJson(report, true));
        if (pipeline == "URP")
        {
            string root = UnityEditor.PackageManager.PackageInfo.FindForAssembly(typeof(ShaderConverterApi).Assembly).resolvedPath;
            string sourcePath = "Assets/UniversalTexture_Source.shader";
            File.Copy(Path.Combine(root, "Samples~/Handwritten/UniversalTexture.shader"), sourcePath, true);
            AssetDatabase.ImportAsset(sourcePath, ImportAssetOptions.ForceSynchronousImport | ImportAssetOptions.ForceUpdate);
            var automatic = ShaderConverterApi.ConvertFile(sourcePath, AssetDatabase.GenerateUniqueAssetPath("Assets/UniversalTexture_ASE.shader"));
            File.WriteAllText("automatic.json", JsonUtility.ToJson(automatic, true));
            if (automatic.status != "Generated") throw new Exception(JsonUtility.ToJson(automatic, true));
            UnitySmoke.CompareImages(AssetDatabase.LoadAssetAtPath<Shader>(sourcePath), AssetDatabase.LoadAssetAtPath<Shader>(automatic.outputPath), "urp-texture");
            automatic.visualComparisonPassed = true;
            automatic.warnings.Add("Pixel comparison passed for this fixture; this is not an SRP scene test.");
            File.WriteAllText("automatic.json", JsonUtility.ToJson(automatic, true));
        }
        Debug.Log("ASE_CONVERTER_SRP_SMOKE_PASS: " + pipeline);
        EditorApplication.Exit(0);
    }
}
