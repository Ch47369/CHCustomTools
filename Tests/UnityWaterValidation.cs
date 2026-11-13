// Copy with Samples~/Water scripts into an isolated Unity project's Assets.
using System;
using System.IO;
using System.Linq;
using System.Reflection;
using UnityEditor;
using UnityEngine;
using ASEShaderConverter;
using ASEShaderConverter.Editor;
using ASEShaderWater.Editor;

public static class UnityWaterValidation
{
    static void Save(string name,object value) {File.WriteAllText(name,JsonUtility.ToJson(value,true));}
    public static void Run()
    {
        try
        {
            if(Path.GetFullPath(".").IndexOf(Path.DirectorySeparatorChar+".validation"+Path.DirectorySeparatorChar,StringComparison.OrdinalIgnoreCase)<0)throw new Exception("Isolated validation project required");
            var probe=ShaderConverterApi.Execute(new ShaderAgentRequest{operation="probe"});Save("water-environment.json",probe);
            if(!probe.success || probe.environment.activePipeline!="BuiltIn")throw new Exception("Built-in probe failed");
            var request=JsonUtility.FromJson<ShaderAgentRequest>(File.ReadAllText("water-request.json"));
            var description=ShaderConverterApi.Execute(new ShaderAgentRequest{operation="describe",templateGuid=request.plan.templateGuid,nodeTypes=request.plan.nodes.Select(n=>n.type).Distinct().ToArray()});Save("water-template.json",description);
            if(!description.success)throw new Exception("Describe failed: "+description.error);
            Directory.CreateDirectory("Assets/Shaders");
            var generated=ShaderConverterApi.Execute(request);Save("water-conversion.json",generated);
            if(!generated.success || !generated.report.aseRoundTripPassed || !generated.report.shaderCompiled)throw new Exception("Generate failed: "+generated.error);
            var method=typeof(DepthWaterAuthoring).GetMethod("CreateAssets",BindingFlags.Static|BindingFlags.NonPublic);
            var created=method.Invoke(null,null);Save("water-assets.json",created);
            AssertSuccess(created,"Supporting assets");
            var validation=typeof(DepthWaterAuthoring).GetMethod("ValidateVariants",BindingFlags.Static|BindingFlags.NonPublic).Invoke(null,new object[]{request.outputPath});
            Save("water-variants.json",validation);AssertSuccess(validation,"Variant rendering");
            var variants=(Array)validation.GetType().GetField("variants").GetValue(validation);
            if(variants.Length!=22)throw new Exception("Expected 22 keyword combinations");
            File.WriteAllText("water-validation-result.txt","PASS: ASE save/reload/compile; 22 feature keyword combinations compiled and rendered. Original authored plan; no source-shader visual equivalence or GPU benchmark.");
            Debug.Log("ASE_WATER_VALIDATION_PASS: 22");EditorApplication.Exit(0);
        }
        catch(Exception e){File.WriteAllText("water-validation-error.txt",e.ToString());Debug.LogException(e);EditorApplication.Exit(1);}
    }
    static void AssertSuccess(object result,string stage)
    {
        if(!(bool)result.GetType().GetField("success").GetValue(result))throw new Exception(stage+": "+JsonUtility.ToJson(result));
    }
}
