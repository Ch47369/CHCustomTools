// Run only in the authorized isolated URP project. Evidence is per attempt.
using System;
using System.IO;
using System.Linq;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;
using ASEShaderConverter;
using ASEShaderConverter.Editor;

public static class UnityShaderGraphNativeSmoke
{
    static string root;
    static int checks;
    static int renderStates;
    static float maxError;
    static void Check(bool ok,string name) { if(!ok) throw new Exception(name); checks++; }
    public static void Run()
    {
        root = Path.GetFullPath("../../.build~/GraphInterop040/Attempts/"+DateTime.UtcNow.ToString("yyyyMMddHHmmssfff"));
        Directory.CreateDirectory(root);
        try
        {
            Shader.globalRenderPipeline = "UniversalPipeline";
            var env = ShaderGraphEditorBridge.Probe(); File.WriteAllText(root+"/environment.json",JsonUtility.ToJson(env,true));
            Check(env.errors.Count==0,string.Join(";",env.errors));
            var request = new ShaderAgentRequest { operation="describe", options=new ShaderConversionOptions{targetGraph="ShaderGraph"} };
            var described = ShaderConverterApi.Execute(request); File.WriteAllText(root+"/description.json",JsonUtility.ToJson(described,true));
            Check(described.success,described.error);
            string dir="Assets/GraphInterop040/"+DateTime.UtcNow.ToString("yyyyMMddHHmmssfff"); Directory.CreateDirectory(dir);
            string source= "Shader \"Checks/NativeSG\" { Properties { _Strength (\"Strength\", Range(0,2)) = 0.5 } SubShader { Pass { CGPROGRAM\n#pragma vertex vert\n#pragma fragment frag\n#include \"UnityCG.cginc\"\nfloat _Strength; struct appdata { float4 vertex:POSITION; float2 uv:TEXCOORD0; }; struct v2f { float4 pos:SV_POSITION; float2 uv:TEXCOORD0; }; v2f vert(appdata v) { v2f o; o.pos=UnityObjectToClipPos(v.vertex); o.uv=v.uv; return o; } float4 frag(v2f i):SV_Target { return float4(saturate(_Strength*2.0),0.25,0.75,1.0); } ENDCG } } }";
            request=new ShaderAgentRequest { operation="generate",sourceText=source,sourcePath="synthetic.shader",outputPath=dir+"/Handwritten.shadergraph",options=new ShaderConversionOptions{targetGraph="ShaderGraph",targetPipeline="URP",acceptStandardUrpUnlitTarget=true} };
            var generated=ShaderConverterApi.Execute(request); File.WriteAllText(root+"/handwritten.json",JsonUtility.ToJson(generated,true));
            Check(generated.success,generated.error+" "+(generated.report==null?"":string.Join(";",generated.report.blockers)));
            Check(generated.report.shaderGraphRoundTripPassed && generated.report.shaderCompiled && !generated.report.visualComparisonPassed,"Generation evidence flags");
            Shader shader=AssetDatabase.LoadAssetAtPath<Shader>(request.outputPath);
            var material=new Material(shader);
            try {
                foreach(float strength in new[]{0f,0.2f,0.5f,1.2f}) {
                    material.SetFloat("_Strength",strength);
                    var color=Render(material);
                    Check(Mathf.Abs(color.r-Mathf.Clamp01(strength*2))<0.001f && Mathf.Abs(color.g-0.25f)<0.001f && Mathf.Abs(color.b-0.75f)<0.001f && Mathf.Abs(color.a-1)<0.001f,"Float render "+strength+": "+color);
                }
            } finally { UnityEngine.Object.DestroyImmediate(material); }
            // An explicitly declared ShaderLab enum is represented by a Shader
            // Graph Enum KeywordNode.  The two branch values are connected to
            // the keyword node; the original continuous Float property is not
            // emitted as a second graph property.
            string enumSource = source.Replace("_Strength (\"Strength\", Range(0,2)) = 0.5", "[KeywordEnum(Base,Detail)] _Mode (\"模式\", Float) = 0").Replace("float _Strength;", "float _Strength; float _Mode;").Replace("saturate(_Strength*2.0),0.25,0.75", "lerp(float4(1,0,0,1),float4(0,1,0,1),_Mode).xyz");
            request.sourceText=enumSource; request.sourcePath="enum.shader"; request.outputPath=dir+"/Enum.shadergraph";
            var enumGenerated=ShaderConverterApi.Execute(request); File.WriteAllText(root+"/enum-keyword.json",JsonUtility.ToJson(enumGenerated,true));
            if (!enumGenerated.success && File.Exists(request.outputPath))
            {
                var importerType=AppDomain.CurrentDomain.GetAssemblies().Select(a=>a.GetType("UnityEditor.ShaderGraph.ShaderGraphImporter",false)).First(t=>t!=null);
                var method=importerType.GetMethods(System.Reflection.BindingFlags.NonPublic|System.Reflection.BindingFlags.Static).Single(m=>m.Name=="GetShaderText" && m.GetParameters().Length==4);
                File.WriteAllText(root+"/enum-generated-diagnostic.shader",(string)method.Invoke(null,new object[]{request.outputPath,null,null,null}));
            }
            Check(enumGenerated.success,enumGenerated.error+" "+(enumGenerated.report==null?"":string.Join(";",enumGenerated.report.blockers)));
            Check(enumGenerated.report.shaderGraphRoundTripPassed && enumGenerated.report.shaderCompiled,"Enum KeywordNode round-trip and compile");
            string enumJson=File.ReadAllText(request.outputPath);
            Check(enumJson.IndexOf("_Mode",StringComparison.OrdinalIgnoreCase)>=0 && enumJson.IndexOf("Base",StringComparison.OrdinalIgnoreCase)>=0 && enumJson.IndexOf("Detail",StringComparison.OrdinalIgnoreCase)>=0,"Enum keyword reference and entries serialized");
            Shader enumShader=AssetDatabase.LoadAssetAtPath<Shader>(request.outputPath);
            Check(enumShader!=null && enumShader.keywordSpace.keywordCount>=2,"Enum keyword variants compiled");
            var enumNames=enumShader.keywordSpace.keywords.Select(k=>k.name).Where(n=>n.IndexOf("BASE",StringComparison.OrdinalIgnoreCase)>=0 || n.IndexOf("DETAIL",StringComparison.OrdinalIgnoreCase)>=0).ToArray();
            Check(enumNames.Length>=2,"Enum keyword entry variants are discoverable");
            var enumMaterial=new Material(enumShader);
            try {
                Check(enumMaterial.HasProperty("_MODE"),"Enum material property uses the reviewed uppercase keyword reference");
                enumMaterial.SetFloat("_MODE",0); MaterialEditor.ApplyMaterialPropertyDrawers(enumMaterial);
                Check(enumMaterial.IsKeywordEnabled("_MODE_BASE"),"Material enum drawer initializes first keyword");
                enumMaterial.SetFloat("_MODE",1); MaterialEditor.ApplyMaterialPropertyDrawers(enumMaterial);
                Check(enumMaterial.IsKeywordEnabled("_MODE_DETAIL") && !enumMaterial.IsKeywordEnabled("_MODE_BASE"),"Material enum drawer switches keyword entries");
                foreach(string keyword in enumNames) enumMaterial.DisableKeyword(keyword);
                enumMaterial.EnableKeyword(enumNames.First(n=>n.IndexOf("BASE",StringComparison.OrdinalIgnoreCase)>=0));
                var baseColor=Render(enumMaterial);
                Check(baseColor.r>baseColor.g && baseColor.r>0.5f,"Enum Base keyword selects first branch: "+baseColor);
                foreach(string keyword in enumNames) enumMaterial.DisableKeyword(keyword);
                enumMaterial.EnableKeyword(enumNames.First(n=>n.IndexOf("DETAIL",StringComparison.OrdinalIgnoreCase)>=0));
                var detailColor=Render(enumMaterial);
                Check(detailColor.g>detailColor.r && detailColor.g>0.5f,"Enum Detail keyword selects second branch: "+detailColor);
            } finally { UnityEngine.Object.DestroyImmediate(enumMaterial); }
            // No-overwrite and re-entry checks use the same path.
            Check(!ShaderConverterApi.Execute(request).success,"Existing graph is preserved");
            var native=new ShaderGraphNativePlan{acceptStandardUrpUnlitTarget=true,colorNode="rgb",colorSlot=0};
            native.nodes.Add(new ShaderGraphNativeNode{id="rgb",type="Vector3Node",value=new[]{0.2f,0.4f,0.8f}});
            var agent=ShaderConverterApi.Execute(new ShaderAgentRequest{operation="generatePlan",outputPath=dir+"/Agent.shadergraph",shaderGraphPlan=native,options=new ShaderConversionOptions{targetGraph="ShaderGraph"}});
            File.WriteAllText(root+"/agent-plan.json",JsonUtility.ToJson(agent,true)); Check(agent.success,agent.error+" "+string.Join(";",agent.report.blockers));
            string package=UnityEditor.PackageManager.PackageInfo.GetAllRegisteredPackages().Single(p=>p.name=="com.aseshader.handwritten-converter").resolvedPath;
            var sample=JsonUtility.FromJson<ShaderAgentRequest>(File.ReadAllText(package+"/Samples~/AgentShaderGraphNativePlan.json")); sample.outputPath=dir+"/PackagedSample.shadergraph";
            var sampleResponse=ShaderConverterApi.Execute(sample); File.WriteAllText(root+"/packaged-sample.json",JsonUtility.ToJson(sampleResponse,true)); Check(sampleResponse.success,sampleResponse.error+" "+string.Join(";",sampleResponse.report.blockers));
            string[] expressions = {
                "float4(i.uv,0.25,1.0)",
                "float4(abs(sin(_Strength)),cos(_Strength),frac(_Strength),1.0)",
                "float4(floor(_Strength),ceil(_Strength),sqrt(abs(_Strength)),1.0)",
                "float4(min(_Strength,0.4),max(_Strength,0.2),pow(abs(_Strength),2.0),1.0)",
                "float4(lerp(0.2,0.8,_Strength),-_Strength,(_Strength+0.25)/2.0,1.0)",
                "float4(_Strength-0.125,0.25,0.75,1.0)",
                "float4(tex2D(_MainTex,i.uv).rgb*_Strength,1.0)"
            };
            for(int fixture=0;fixture<expressions.Length;fixture++) {
                string variant=source.Replace("saturate(_Strength*2.0),0.25,0.75,1.0",expressions[fixture].Substring(7,expressions[fixture].Length-8));
                bool textured=fixture==expressions.Length-1;
                if(textured) variant=variant.Replace("Properties {","Properties { _MainTex (\"Texture\", 2D) = \"gray\" {} ").Replace("float _Strength;","sampler2D _MainTex; float _Strength;");
                variant=variant.Replace("Checks/NativeSG","Checks/NativeSG"+fixture);
                string originalPath=dir+"/Original"+fixture+".shader"; File.WriteAllText(originalPath,variant); AssetDatabase.ImportAsset(originalPath,ImportAssetOptions.ForceSynchronousImport);
                request.sourceText=variant; request.outputPath=dir+"/Fixture"+fixture+".shadergraph";
                var mapped=ShaderConverterApi.Execute(request); File.WriteAllText(root+"/fixture-"+fixture+".json",JsonUtility.ToJson(mapped,true));
                Check(mapped.success,mapped.error+" "+string.Join(";",mapped.report.blockers));
                var original=new Material(AssetDatabase.LoadAssetAtPath<Shader>(originalPath)); var converted=new Material(AssetDatabase.LoadAssetAtPath<Shader>(request.outputPath));
                Texture2D texture=new Texture2D(2,2,TextureFormat.RGBAFloat,false,true); texture.SetPixels(new[]{new Color(0.2f,0.4f,0.8f,0.3f),new Color(0.8f,0.1f,0.3f,1),new Color(0.1f,0.7f,0.6f,0.6f),new Color(1,0.8f,0.2f,1)}); texture.Apply();
                try {
                    if(textured) {
                        var referenceDefault=Render(original); var actualDefault=Render(converted);
                        Check(Mathf.Abs(referenceDefault.r-actualDefault.r)<0.001f && Mathf.Abs(referenceDefault.g-actualDefault.g)<0.001f && Mathf.Abs(referenceDefault.b-actualDefault.b)<0.001f,"Unassigned gray default preserved");
                    }
                    foreach(float state in new[]{0f,0.15f,0.45f,0.8f,1.3f}) {
                        original.SetFloat("_Strength",state); converted.SetFloat("_Strength",state);
                        if(textured) { original.SetTexture("_MainTex",texture); converted.SetTexture("_MainTex",texture); }
                        var reference=Render(original); var actual=Render(converted);
                        float error=Mathf.Max(Mathf.Abs(reference.r-actual.r),Mathf.Abs(reference.g-actual.g),Mathf.Abs(reference.b-actual.b),Mathf.Abs(reference.a-actual.a)); maxError=Mathf.Max(maxError,error); renderStates++;
                        Check(error<0.001f,"Native float fixture "+fixture+" / "+state+": "+reference+" vs "+actual);
                    }
                } finally { UnityEngine.Object.DestroyImmediate(original); UnityEngine.Object.DestroyImmediate(converted); UnityEngine.Object.DestroyImmediate(texture); }
            }
            var invalid=new ShaderGraphNativePlan{acceptStandardUrpUnlitTarget=true,colorNode="bad"}; invalid.nodes.Add(new ShaderGraphNativeNode{id="bad",type="CustomFunctionNode"});
            Check(ShaderGraphEditorBridge.Generate(invalid,dir+"/Invalid.shadergraph").status=="Blocked" && !File.Exists(dir+"/Invalid.shadergraph"),"Custom code rejected before file creation");
            // Unity JsonUtility with numeric fields avoids locale-specific decimal formatting.
            File.WriteAllText(root+"/result.json",JsonUtility.ToJson(new Result{checks=checks,renderStates=renderStates,maxError=maxError,outputDirectory=dir},true));
            EditorApplication.Exit(0);
        }
        catch(Exception e) { File.WriteAllText(root+"/error.txt",e.ToString()); Debug.LogException(e); EditorApplication.Exit(1); }
    }
    [Serializable] public class Result { public bool success=true,visualComparisonPassed=false; public int checks,renderStates; public float maxError; public string outputDirectory; public string scope="URP standard Unlit native subset; synthetic float fixtures only"; }
    static Color Render(Material material)
    {
        var rt=RenderTexture.GetTemporary(8,8,0,RenderTextureFormat.ARGBFloat,RenderTextureReadWrite.Linear);
        var previous=RenderTexture.active; var tex=new Texture2D(8,8,TextureFormat.RGBAFloat,false,true);
        try { int pass=material.FindPass("Universal Forward"); Graphics.Blit(Texture2D.whiteTexture,rt,material,pass<0?0:pass); RenderTexture.active=rt; tex.ReadPixels(new Rect(0,0,8,8),0,0); tex.Apply(); return tex.GetPixel(4,4); }
        finally { RenderTexture.active=previous; UnityEngine.Object.DestroyImmediate(tex); RenderTexture.ReleaseTemporary(rt); }
    }
}
