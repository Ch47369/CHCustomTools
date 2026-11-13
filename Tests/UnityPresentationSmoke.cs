// Run in the isolated project, with authorized UI source copied into Assets/Source.
using System;
using System.IO;
using System.Linq;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;
using ASEShaderConverter;
using ASEShaderConverter.Editor;

public static class UnityPresentationSmoke
{
    private static int checks;
    private static void Check(bool value, string name) { if (!value) throw new Exception(name); checks++; }
    public static void Run()
    {
        try
        {
            checks = 0;
            if (File.Exists("presentation-smoke-error.txt")) File.Delete("presentation-smoke-error.txt");
            if (File.Exists("presentation-smoke-result.txt")) File.Delete("presentation-smoke-result.txt");
            var env = ShaderConverterApi.Execute(new ShaderAgentRequest { operation = "probe" });
            File.WriteAllText("ui-environment.json", JsonUtility.ToJson(env,true));
            Check(env.success && env.environment.templates.Any(t => t.guid == ReviewedUiProfile.TemplateGuid && t.ready), "Owned UI template must be available");
            var description = ShaderConverterApi.Execute(new ShaderAgentRequest { operation = "describe", templateGuid = ReviewedUiProfile.TemplateGuid, nodeTypes = new[] { "SamplerNode", "RegisterLocalVarNode", "GetLocalVarNode", "CommentaryNode" } });
            File.WriteAllText("ui-template.json", JsonUtility.ToJson(description,true));
            Check(description.success && description.description.masters.Any(m => m.pass == "UI" && m.inputs.Any(p => p.name == "Color" && p.type == "FLOAT4")), "Describe the actual UI Color port");
            var result = ShaderConverterApi.Execute(new ShaderAgentRequest { operation = "generate", sourcePath = "Assets/Source/DeepZoomPageTableUI.shader", outputPath = AssetDatabase.GenerateUniqueAssetPath("Assets/Generated/DeepZoomPageTableUI_ASE.shader") });
            File.WriteAllText("ui-conversion.json", JsonUtility.ToJson(result,true));
            Check(result.success && result.report.aseRoundTripPassed && result.report.shaderCompiled, "UI conversion: " + result.error + " " + string.Join("; ", result.report.blockers.ToArray()));
            Check(result.report.layoutApplied && result.report.commentCount >= 10 && result.report.registerNodeCount > 0 && result.report.getNodeCount >= result.report.registerNodeCount, "Layout, comments and meaningful long-wire routing");
            var generated = AssetDatabase.LoadAssetAtPath<Shader>(result.report.outputPath);
            var source = AssetDatabase.LoadAssetAtPath<Shader>("Assets/Source/DeepZoomPageTableUI.shader");
            Check(source.GetPropertyCount() == 16 && generated.GetPropertyCount() == 16, "Retain all 16 UI properties");
            for (int i = 0; i < source.GetPropertyCount(); i++)
            {
                string name = source.GetPropertyName(i); int j = generated.FindPropertyIndex(name);
                Check(j >= 0 && generated.GetPropertyType(j) == source.GetPropertyType(i) && generated.GetPropertyFlags(j) == source.GetPropertyFlags(i), "UI property type/flags: " + name);
                Check(source.GetPropertyAttributes(i).SequenceEqual(generated.GetPropertyAttributes(j)), "UI property attributes: " + name);
                if (source.GetPropertyType(i) == ShaderPropertyType.Float) Check(source.GetPropertyDefaultFloatValue(i) == generated.GetPropertyDefaultFloatValue(j), "UI float default: " + name);
                if (source.GetPropertyType(i) == ShaderPropertyType.Vector || source.GetPropertyType(i) == ShaderPropertyType.Color) Check(source.GetPropertyDefaultVectorValue(i) == generated.GetPropertyDefaultVectorValue(j), "UI vector default: " + name);
            }
            var changed = File.ReadAllText("Assets/Source/DeepZoomPageTableUI.shader").Replace("color.a - 0.001", "color.a - 0.002");
            Check(!ShaderConversionEngine.Analyze(changed).report.CanGenerate, "Changed UI behavior must leave the reviewed profile and stay blocked");
            Compare(source, generated);
            result.analysis.plan.presentation = new GraphPresentationOptions { autoLayout=false, addComments=false, useRegisters=false };
            result.analysis.plan.shaderName += "_NoPresentation";
            var plain = ShaderConverterApi.Execute(new ShaderAgentRequest { operation="generatePlan", plan=result.analysis.plan, outputPath=AssetDatabase.GenerateUniqueAssetPath("Assets/Generated/UI_NoPresentation.shader") });
            File.WriteAllText("ui-no-presentation.json",JsonUtility.ToJson(plain,true));
            Check(plain.success && plain.report.aseRoundTripPassed && plain.report.shaderCompiled,"Disabled presentation must still generate and reload");
            Check(!plain.report.layoutApplied && plain.report.commentCount==0 && plain.report.registerNodeCount==0 && plain.report.getNodeCount==0,"Honor all presentation switches");
            File.WriteAllText("presentation-smoke-result.txt", "PASS: " + checks + " checks. UI template, native graph, comments/references, properties, 21 rendered material/variant states. Target Canvas scene not compared.");
            Debug.Log("ASE_PRESENTATION_SMOKE_PASS: " + checks);
            EditorApplication.Exit(0);
        }
        catch (Exception e)
        {
            File.WriteAllText("presentation-smoke-error.txt",e.ToString()); Debug.LogException(e); EditorApplication.Exit(1);
        }
    }

    private static void Compare(Shader original, Shader generated)
    {
        // Array/fallback include alpha below the clip threshold. Float targets make this visible.
        var layers = new Texture2DArray(16,16,3,TextureFormat.RGBAFloat,false,true) { filterMode = FilterMode.Point, wrapMode = TextureWrapMode.Clamp };
        for (int layer = 0; layer < 3; layer++)
        {
            var data = new Color[256];
            for (int y = 0; y < 16; y++) for (int x = 0; x < 16; x++) data[y*16+x] = new Color((x+1f)/17,(y+1f)/17,0.2f+layer*0.3f,x < 5 ? 0.0005f : 0.25f+layer*0.2f);
            layers.SetPixels(data,layer);
        }
        layers.Apply();
        var transform = new Texture2D(2,2,TextureFormat.RGBAFloat,false,true) { filterMode = FilterMode.Point };
        transform.SetPixels(new[] { new Color(1.1f,0.9f,-0.1f,0.05f),new Color(0.9f,1,0.07f,0),new Color(1,1,0,0),new Color(0.7f,0.8f,0.15f,0.1f) }); transform.Apply();
        var info = new Texture2D(2,2,TextureFormat.RGBAFloat,false,true) { filterMode = FilterMode.Point };
        info.SetPixels(new[] {new Color(0.49f,0,0,0),new Color(0.51f,0.49f,0,0),new Color(1.49f,0.5f,0,0),new Color(1.51f,1,0,0)}); info.Apply();
        var fallback = new Texture2D(2,2,TextureFormat.RGBAFloat,false,true) { filterMode = FilterMode.Point, wrapMode = TextureWrapMode.Clamp };
        fallback.SetPixels(new[] { new Color(0.8f,0.1f,0.3f,0.0005f),new Color(0.2f,0.7f,0.4f,0.8f),new Color(0.1f,0.4f,0.9f,0.6f),new Color(0.9f,0.6f,0.1f,0.9f) }); fallback.Apply();
        var a = new Material(original); var b = new Material(generated);
        Shader.SetGlobalInt("unity_GUIZTestMode", (int)CompareFunction.Always);
        try
        {
            foreach (var m in new[] {a,b})
            {
                m.SetTexture("_TileArray",layers); m.SetTexture("_PageTableTransform",transform); m.SetTexture("_PageTableLayer",info); m.SetTexture("_FallbackTex",fallback);
                m.SetVector("_PageTableGrid",new Vector4(2,2,0.5f,0.5f)); m.SetVector("_ViewRect",new Vector4(-0.12f,0.07f,1.3f,0.85f));
                m.SetColor("_Color",new Color(0.8f,0.65f,0.9f,0.75f)); m.SetVector("_ClipRect",new Vector4(-1.25f,-0.65f,1.1f,0.8f));
                Check(m.renderQueue == 3000 && string.Equals(m.GetTag("CanUseSpriteAtlas",false),"True",StringComparison.OrdinalIgnoreCase), "UI tags and render queue: " + m.shader.name + ", queue=" + m.renderQueue + ", atlas=" + m.GetTag("CanUseSpriteAtlas",false));
            }
            File.WriteAllText("ui-pixels.txt", "128x64 linear RGBAFloat; straight-alpha blending; max RGBA error per state:\n");
            Color[] plain = null, clipped = null, alphaClipped = null;
            for (int flags = 0; flags < 4; flags++) foreach (float flip in new[] {0f,0.5f,1f})
            {
                foreach (var m in new[] {a,b})
                {
                    m.SetFloat("_FlipHorizontally",flip);
                    Keyword(m,"UNITY_UI_CLIP_RECT",(flags&1)!=0); Keyword(m,"UNITY_UI_ALPHACLIP",(flags&2)!=0);
                }
                var image = CompareState(a,b,"variants"+flags+"-flip"+flip,false);
                Check(image.Any(c => c.a > 0.1f) && image.Select(c => (Color32)c).Distinct().Count() > 100,"Visible nonconstant UI reference");
                if (flip == 0) { if(flags==0) plain=image; if(flags==1) clipped=image; if(flags==2) alphaClipped=image; }
            }
            Check(Difference(plain,clipped) > 0.05f,"Rect clip keyword must alter rendering");
            Check(Difference(plain,alphaClipped) > 0.00001f,"Alpha clip keyword must remove subthreshold fragments");
            foreach(var m in new[]{a,b}) { Keyword(m,"UNITY_UI_CLIP_RECT",false); Keyword(m,"UNITY_UI_ALPHACLIP",false); m.SetFloat("_FlipHorizontally",0); }
            for(int state=0;state<4;state++)
            {
                foreach(var m in new[]{a,b})
                { m.SetFloat("_StencilComp",state < 2 ? (float)CompareFunction.Equal : (float)CompareFunction.NotEqual); m.SetFloat("_Stencil",state%2+1); }
                var image=CompareState(a,b,"stencil"+state,true);
                if(state==1) Check(image.All(c=>c.a==0),"Mismatched stencil reference rejects all pixels");
                else Check(image.Any(c=>c.a>0.1f),"Stencil test must retain some pixels");
            }
            foreach(var m in new[]{a,b}) m.SetFloat("_StencilComp",(float)CompareFunction.Always);
            foreach(int mask in new[]{0,14,1})
            {
                foreach(var m in new[]{a,b}) m.SetFloat("_ColorMask",mask);
                var image=CompareState(a,b,"colormask"+mask,false);
                Check(mask==0 ? image.All(c=>c==Color.clear) : mask==14 ? image.All(c=>c.a==0) : image.All(c=>c.r==0&&c.g==0&&c.b==0),"ColorMask must control channels");
            }
            foreach(var m in new[]{a,b}) m.SetFloat("_ColorMask",15);
            foreach(var depth in new[]{CompareFunction.Never,CompareFunction.Always})
            {
                Shader.SetGlobalInt("unity_GUIZTestMode",(int)depth);
                var image=CompareState(a,b,"ztest"+depth,false);
                Check(depth==CompareFunction.Never ? image.All(c=>c.a==0) : image.Any(c=>c.a>0.1f),"GUI ZTest mode must be preserved");
            }
        }
        finally
        {
            Shader.SetGlobalInt("unity_GUIZTestMode",(int)CompareFunction.LessEqual);
            foreach(var obj in new UnityEngine.Object[]{a,b,layers,transform,info,fallback}) UnityEngine.Object.DestroyImmediate(obj);
        }
    }
    private static void Keyword(Material m,string name,bool enabled) { if(enabled)m.EnableKeyword(name);else m.DisableKeyword(name); }
    private static float Difference(Color[] a, Color[] b)
    {
        float max=0; for(int i=0;i<a.Length;i++)for(int c=0;c<4;c++)max=Mathf.Max(max,Mathf.Abs(a[i][c]-b[i][c])); return max;
    }
    private static Color[] CompareState(Material a,Material b,string name,bool stencil)
    {
        foreach(var m in new[]{a,b}) { ShaderUtil.CompilePass(m,0,true); Check(!ShaderUtil.ShaderHasError(m.shader),"Compile UI variant "+name); }
        var x=Render(a,stencil,name+"-source"); var y=Render(b,stencil,name+"-generated");
        float error=Difference(x,y);
        File.AppendAllText("ui-pixels.txt",name+": "+error.ToString("R",System.Globalization.CultureInfo.InvariantCulture)+"\n");
        Check(error<=0.0001f,"UI pixel mismatch: "+name+" "+error); return x;
    }
    private static Color[] Render(Material material,bool stencil,string imageName)
    {
        var mesh=new Mesh();
        mesh.vertices=new[]{new Vector3(-2,-1,0),new Vector3(2,-1,0),new Vector3(2,1,0),new Vector3(-2,1,0)};
        mesh.uv=new[]{new Vector2(0,0),new Vector2(1,0),new Vector2(1,1),new Vector2(0,1)};
        mesh.colors=new[]{new Color(0.4f,0.8f,0.9f,0.7f),new Color(0.9f,0.3f,0.7f,0.9f),new Color(0.8f,0.9f,0.2f,0.6f),new Color(0.5f,0.6f,0.8f,1)};
        mesh.triangles=new[]{0,1,2,0,2,3}; mesh.RecalculateBounds();
        var quad=new GameObject("UI comparison"){layer=30};quad.AddComponent<MeshFilter>().sharedMesh=mesh;quad.AddComponent<MeshRenderer>().sharedMaterial=material;
        var camObj=new GameObject("UI camera");var cam=camObj.AddComponent<Camera>();cam.transform.position=new Vector3(0,0,-2);cam.orthographic=true;cam.orthographicSize=1;cam.aspect=2;cam.cullingMask=1<<30;cam.clearFlags=CameraClearFlags.SolidColor;cam.backgroundColor=Color.clear;cam.allowHDR=true;cam.allowMSAA=false;
        GameObject writer=null;Material writeMaterial=null;
        if(stencil)
        {
            string path="Assets/Editor/StencilWriter.shader";
            if(!File.Exists(path))
            {
                File.WriteAllText(path,"Shader \"Hidden/ConverterTest/StencilWriter\" { SubShader { Tags { \"Queue\"=\"Geometry\" } Pass { Cull Off ZTest Always ZWrite Off ColorMask 0 Stencil { Ref 1 Comp Always Pass Replace } CGPROGRAM\n#pragma vertex vert\n#pragma fragment frag\n#include \"UnityCG.cginc\"\nfloat4 vert(float4 p:POSITION):SV_POSITION { return UnityObjectToClipPos(p); } float4 frag():SV_Target { return 0; }\nENDCG } } }");
                AssetDatabase.ImportAsset(path,ImportAssetOptions.ForceSynchronousImport);
            }
            writeMaterial=new Material(AssetDatabase.LoadAssetAtPath<Shader>(path));
            writer=new GameObject("Stencil writer"){layer=30};writer.transform.position=new Vector3(-1,0,-0.1f);writer.transform.localScale=new Vector3(0.5f,1,1);writer.AddComponent<MeshFilter>().sharedMesh=mesh;writer.AddComponent<MeshRenderer>().sharedMaterial=writeMaterial;
        }
        var target=RenderTexture.GetTemporary(128,64,24,RenderTextureFormat.ARGBFloat,RenderTextureReadWrite.Linear);
        var previous=RenderTexture.active;Texture2D texture=null;
        try
        {
            cam.targetTexture=target;cam.Render();RenderTexture.active=target;
            texture=new Texture2D(128,64,TextureFormat.RGBAFloat,false,true);texture.ReadPixels(new Rect(0,0,128,64),0,0);texture.Apply();
            if(imageName.StartsWith("variants1-flip0-"))File.WriteAllBytes(imageName+".png",texture.EncodeToPNG());
            return texture.GetPixels();
        }
        finally
        {
            RenderTexture.active=previous;cam.targetTexture=null;RenderTexture.ReleaseTemporary(target);
            foreach(var obj in new UnityEngine.Object[]{mesh,quad,camObj,writer,writeMaterial,texture})if(obj!=null)UnityEngine.Object.DestroyImmediate(obj);
        }
    }
}
