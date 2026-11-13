// Uses only task-owned isolated projects. Each run preserves its own evidence.
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using ASEShaderConverter;
using ASEShaderConverter.Editor;
using UnityEditor;
using UnityEngine;

public static class UnityGraphTargetsSmoke
{
    static string root, dir, pipeline;
    static readonly List<string> checks = new List<string>();
    static void Check(bool ok, string message) { if (!ok) throw new Exception(message); checks.Add(message); }
    static string Source(string expression, string properties = "_Strength (\"Strength\", Range(0,2)) = 0.5")
    {
        return "Shader \"Checks/GraphTargets\" { Properties { "+properties+" } SubShader { Pass { CGPROGRAM\n#pragma vertex vert\n#pragma fragment frag\n#include \"UnityCG.cginc\"\nfloat _Strength; struct appdata { float4 vertex:POSITION; float2 uv:TEXCOORD0; }; struct v2f { float4 pos:SV_POSITION; float2 uv:TEXCOORD0; }; v2f vert(appdata v) { v2f o; o.pos=UnityObjectToClipPos(v.vertex); o.uv=v.uv; return o; } float4 frag(v2f i):SV_Target { return "+expression+"; } ENDCG } } }";
    }
    static ShaderAgentResponse Generate(string name, string source)
    {
        var response = ShaderConverterApi.Execute(new ShaderAgentRequest { operation="generate", sourceText=source, sourcePath=name+".shader", outputPath=dir+"/"+name+".shadergraph", options=new ShaderConversionOptions { targetGraph="ShaderGraph", targetPipeline=pipeline, acceptStandardUnlitTarget=true } });
        File.WriteAllText(root+"/"+name+".json",JsonUtility.ToJson(response,true));
        if (!response.success && File.Exists(dir+"/"+name+".shadergraph"))
        {
            var importer=AppDomain.CurrentDomain.GetAssemblies().Select(a=>a.GetType("UnityEditor.ShaderGraph.ShaderGraphImporter",false)).First(t=>t!=null);
            var getText=importer.GetMethods(BindingFlags.NonPublic|BindingFlags.Static).Single(m=>m.Name=="GetShaderText" && m.GetParameters().Length==4);
            File.WriteAllText(root+"/"+name+"-diagnostic.shader",(string)getText.Invoke(null,new object[]{dir+"/"+name+".shadergraph",null,null,null}));
        }
        Check(response.success, name+": "+response.error+" "+(response.report==null?"":string.Join(";",response.report.blockers)));
        Check(response.report.pipeline==pipeline && response.report.shaderGraphRoundTripPassed && response.report.shaderCompiled && !response.report.visualComparisonPassed, name+" official round-trip and synchronous compile");
        string json=File.ReadAllText(response.report.outputPath);
        Check(json.Contains(pipeline=="BuiltIn" ? "BuiltInUnlitSubTarget" : pipeline=="HDRP" ? "HDUnlitSubTarget" : "UniversalUnlitSubTarget"),name+" uses the actual pipeline target");
        return response;
    }
    public static void Run()
    {
        root=Path.GetFullPath("../../.build~/GraphTargets046/Attempts/"+DateTime.UtcNow.ToString("yyyyMMddHHmmssfff")); Directory.CreateDirectory(root);
        try
        {
            var env=ShaderGraphEditorBridge.Probe(); pipeline=env.activePipeline;
            Shader.globalRenderPipeline=pipeline=="URP" ? "UniversalPipeline" : pipeline=="HDRP" ? "HDRenderPipeline" : "";
            File.WriteAllText(root+"/environment.json",JsonUtility.ToJson(env,true));
            Check(env.errors.Count==0,string.Join(";",env.errors));
            var probe=ShaderConverterApi.Execute(new ShaderAgentRequest { operation="probe", options=new ShaderConversionOptions{targetGraph="ShaderGraph",targetPipeline=pipeline} });
            Check(probe.success && probe.shaderGraphEnvironment.targetPipeline==pipeline,"API pipeline-aware probe");
            string other=pipeline=="URP" ? "BuiltIn" : "URP";
            Check(ShaderGraphEditorBridge.Probe(other).errors.Count>0,"Mismatched active pipeline is blocked");
            var describe=ShaderConverterApi.Execute(new ShaderAgentRequest { operation="describe",options=new ShaderConversionOptions{targetGraph="ShaderGraph",targetPipeline=pipeline} });
            File.WriteAllText(root+"/description.json",JsonUtility.ToJson(describe,true));
            Check(describe.success && describe.shaderGraphDescription.Any(n=>n.type=="KeywordNode"),"Actual native slots and Enum keyword description");
            dir="Assets/GraphTargets046/"+DateTime.UtcNow.ToString("yyyyMMddHHmmssfff"); Directory.CreateDirectory(dir);
            Generate("MathRange",Source("float4(saturate(_Strength*2),0.25,0.75,1)"));
            Generate("UV",Source("float4(i.uv,0.25,1)"));
            Generate("Trigonometry",Source("float4(abs(sin(_Strength)),cos(_Strength),frac(_Strength),1)"));
            Generate("Rounding",Source("float4(floor(_Strength),ceil(_Strength),sqrt(abs(_Strength)),1)"));
            Generate("MinMaxPower",Source("float4(min(_Strength,0.4),max(_Strength,0.2),pow(abs(_Strength),2),1)"));
            Generate("LerpArithmetic",Source("float4(lerp(0.2,0.8,_Strength),-_Strength,(_Strength+0.25)/2,1)"));
            foreach (string fallback in new[]{"white","black","gray"})
                Generate("Texture_"+fallback,Source("float4(tex2D(_MainTex,i.uv).rgb,1)","_MainTex (\"Texture\", 2D) = \""+fallback+"\" {}").Replace("float _Strength;","sampler2D _MainTex;"));
            var enumResult=Generate("Enum",Source("lerp(float4(1,0,0,1),float4(0,1,0,1),_Mode)","[KeywordEnum(Base,Detail)] _Mode (\"Mode\", Float) = 0").Replace("float _Strength;","float _Mode;"));
            var shader=AssetDatabase.LoadAssetAtPath<Shader>(enumResult.report.outputPath);
            var material=new Material(shader);
            try
            {
                Check(material.HasProperty("_MODE") && !material.HasProperty("_Mode"),"Enum uses keyword property without continuous Float duplicate");
                material.SetFloat("_MODE",0); MaterialEditor.ApplyMaterialPropertyDrawers(material);
                Check(material.IsKeywordEnabled("_MODE_BASE") && !material.IsKeywordEnabled("_MODE_DETAIL"),"Enum first branch initializes");
                material.SetFloat("_MODE",1); MaterialEditor.ApplyMaterialPropertyDrawers(material);
                Check(material.IsKeywordEnabled("_MODE_DETAIL") && !material.IsKeywordEnabled("_MODE_BASE"),"Enum switches to second branch");
            }
            finally { UnityEngine.Object.DestroyImmediate(material); }
            var native=new ShaderGraphNativePlan { pipeline=pipeline,acceptStandardUnlitTarget=true,colorNode="rgb" };
            native.nodes.Add(new ShaderGraphNativeNode{id="rgb",type="Vector3Node",value=new[]{0.2f,0.4f,0.8f}});
            var agent=ShaderConverterApi.Execute(new ShaderAgentRequest{operation="generatePlan",outputPath=dir+"/Agent.shadergraph",shaderGraphPlan=native,options=new ShaderConversionOptions{targetGraph="ShaderGraph"}});
            File.WriteAllText(root+"/agent.json",JsonUtility.ToJson(agent,true));
            Check(agent.success && agent.report.shaderGraphRoundTripPassed && agent.report.shaderCompiled,"Agent explicit native plan generation");
            byte[] before=File.ReadAllBytes(dir+"/Agent.shadergraph");
            Check(ShaderGraphEditorBridge.Generate(native,dir+"/Agent.shadergraph").status=="GenerationFailed" && File.ReadAllBytes(dir+"/Agent.shadergraph").SequenceEqual(before),"Existing graph is preserved byte for byte");
            native.nodes[0].type="CustomFunctionNode";
            Check(ShaderGraphEditorBridge.Generate(native,dir+"/Invalid.shadergraph").status=="Blocked" && !File.Exists(dir+"/Invalid.shadergraph"),"Arbitrary code is rejected before file creation");
            CheckFolderSelection();
            var package=UnityEditor.PackageManager.PackageInfo.GetAllRegisteredPackages().Single(p=>p.name=="com.aseshader.handwritten-converter");
            File.WriteAllText(root+"/result.json",JsonUtility.ToJson(new Result{success=true,pipeline=pipeline,unityVersion=Application.unityVersion,packageVersion=package.version,packageSource=package.source.ToString(),outputDirectory=dir,checks=checks.ToArray()},true));
            EditorApplication.Exit(0);
        }
        catch(Exception e) { File.WriteAllText(root+"/error.txt",e.ToString()); Debug.LogException(e); EditorApplication.Exit(1); }
    }
    static object Invoke(string name, object instance, params object[] args)
    {
        return typeof(ASEShaderConverterWindow).GetMethod(name,BindingFlags.NonPublic|BindingFlags.Static|BindingFlags.Instance).Invoke(instance,args);
    }
    static void CheckFolderSelection()
    {
        string folder=dir+"/Folder"; Directory.CreateDirectory(folder); AssetDatabase.Refresh();
        var window=ScriptableObject.CreateInstance<ASEShaderConverterWindow>();
        var field=typeof(ASEShaderConverterWindow).GetField("inputPath",BindingFlags.NonPublic|BindingFlags.Instance);
        try
        {
            Invoke("SetInput",window,Path.GetFullPath(folder));
            Check((string)field.GetValue(window)==folder,"Absolute Assets folder normalizes to a Unity path");
            Invoke("Analyze",window);
            Check(typeof(ASEShaderConverterWindow).GetField("analysis",BindingFlags.NonPublic|BindingFlags.Instance).GetValue(window)==null,"Directory selection never executes conversion");
            DragAndDrop.PrepareStartDrag(); DragAndDrop.objectReferences=new[]{AssetDatabase.LoadAssetAtPath<UnityEngine.Object>(folder)};
            object[] args={""};
            Check((bool)Invoke("TryGetDraggedShader",null,args) && (string)args[0]==folder,"Project folder drag selects directory");
            DragAndDrop.objectReferences=new UnityEngine.Object[0]; DragAndDrop.paths=new[]{Path.GetFullPath(folder)}; args=new object[]{""};
            Check((bool)Invoke("TryGetDraggedShader",null,args),"System folder drag selects directory");
            DragAndDrop.paths=new[]{folder,"Assets"}; args=new object[]{""};
            Check(!(bool)Invoke("TryGetDraggedShader",null,args),"Multiple folder drag is rejected");
            Invoke("SetInput",window,Application.dataPath);
            Check((string)field.GetValue(window)=="Assets" && (bool)Invoke("IsInputDirectory",null,"Assets"),"Assets root folder works");
            string packageRoot="Packages/com.aseshader.handwritten-converter";
            Check((bool)Invoke("IsInputDirectory",null,packageRoot),"Package root folder resolves without substring failure");
            Invoke("SetInput",window,dir+"/Enum.shadergraph");
            Check((bool)Invoke("IsShaderFile",null,(string)field.GetValue(window)),"File selection remains usable after a folder selection");
            Check(Directory.GetFiles(folder).Length==0,"Folder selection does not scan, convert or write files");
        }
        finally { DragAndDrop.PrepareStartDrag(); UnityEngine.Object.DestroyImmediate(window); }
    }
    [Serializable] public class Result
    {
        public bool success, visualComparisonPassed=false;
        public string pipeline, unityVersion, packageVersion, packageSource, outputDirectory;
        public string[] checks;
        public string scope="Native standard opaque Unlit targets, official round-trip and synchronous shader compilation; no scene equivalence claim.";
    }
}
