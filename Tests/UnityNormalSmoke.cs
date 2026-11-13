// Run only in an isolated project with authorized source shaders in Assets/Source.
using System;
using System.IO;
using System.Linq;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;
using ASEShaderConverter;
using ASEShaderConverter.Editor;

public static class UnityNormalSmoke
{
    private static int checks, cases;
    private static void Check(bool value, string message) { if (!value) throw new Exception(message); checks++; }
    public static void Run()
    {
        try
        {
            checks = cases = 0;
            foreach (string file in new[] { "normal-smoke-error.txt", "normal-smoke-result.txt" }) if (File.Exists(file)) File.Delete(file);
            File.WriteAllText("normal-pixels.txt", "128x64 Linear RGBAFloat; maximum absolute error across all RGBA components.\n");
            var environment = ShaderConverterApi.Execute(new ShaderAgentRequest { operation="probe" });
            Save("normal-environment.json", environment);
            Check(environment.success && environment.environment.activePipeline == "BuiltIn", "Probe Built-in environment");
            foreach (string guid in new[] { ReviewedNormal360Profile.TemplateGuid, ReviewedUiProfile.PanZoomTemplateGuid })
            {
                Check(environment.environment.templates.Any(t => t.guid == guid && t.ready), "Reviewed template must load: " + guid);
                var description = ShaderConverterApi.Execute(new ShaderAgentRequest { operation="describe", templateGuid=guid, nodeTypes=new[] { "ConditionalIfNode", "SamplerNode", "TextureCoordinatesNode" } });
                Save("normal-template-" + guid + ".json", description);
                Check(description.success && description.description.masters.Any(m => m.inputs.Any(p => p.name=="Color" && p.type=="FLOAT4")), "Describe real Float4 Color port");
            }
            var normal = Generate("Normal360",2);
            var pan = Generate("NormalImagePanZoom",11);
            string normalText = File.ReadAllText("Assets/Source/Normal360.shader");
            string panText = File.ReadAllText("Assets/Source/NormalImagePanZoom.shader");
            Check(!ShaderConversionEngine.Analyze(normalText.Replace("Cull off", "Cull Back")).report.CanGenerate, "Changed cull must leave the reviewed profile");
            Check(!ShaderConversionEngine.Analyze(normalText.Replace("_FlipHorizontally > 0.5", "_FlipHorizontally >= 0.5")).report.CanGenerate, "Changed flip boundary must leave the profile");
            Check(!ShaderConversionEngine.Analyze(panText.Replace("color.a - 0.001", "color.a - 0.002")).report.CanGenerate, "Changed UI alpha threshold must leave the profile");
            Check(ShaderConversionEngine.Analyze(normalText.Replace("Unlit/Normal360", "Checks/Renamed") + "/* comment */").report.CanGenerate, "Reviewed profile accepts cosmetic name/comment changes");
            CompareNormal(AssetDatabase.LoadAssetAtPath<Shader>("Assets/Source/Normal360.shader"),normal);
            CompareUi(AssetDatabase.LoadAssetAtPath<Shader>("Assets/Source/NormalImagePanZoom.shader"),pan);
            File.WriteAllText("normal-smoke-result.txt", "PASS: " + checks + " checks; " + cases + " rendered states. ASE reload, native graph, properties, fog, double-sided ST/flip, UI clipping/stencil/depth/masks. Original user scenes not compared.");
            Debug.Log("ASE_NORMAL_SMOKE_PASS: " + checks + "; cases=" + cases);
            EditorApplication.Exit(0);
        }
        catch (Exception e) { File.WriteAllText("normal-smoke-error.txt", e.ToString()); Debug.LogException(e); EditorApplication.Exit(1); }
    }
    private static void Save(string path, object value) { File.WriteAllText(path,JsonUtility.ToJson(value,true)); }
    private static Shader Generate(string name,int properties)
    {
        var response = ShaderConverterApi.Execute(new ShaderAgentRequest { operation="generate", sourcePath="Assets/Source/"+name+".shader", outputPath=AssetDatabase.GenerateUniqueAssetPath("Assets/Generated/"+name+"_ASE.shader") });
        Save("normal-"+name+"-conversion.json",response);
        Check(response.success && response.report.aseRoundTripPassed && response.report.shaderCompiled, name+": "+response.error+" "+string.Join("; ",response.report.blockers.ToArray()));
        Check(response.report.customExpressionCount==0 && response.report.layoutApplied && response.report.commentCount>=3, "Native readable graph: "+name);
        var source=AssetDatabase.LoadAssetAtPath<Shader>("Assets/Source/"+name+".shader");
        var generated=AssetDatabase.LoadAssetAtPath<Shader>(response.report.outputPath);
        Check(source.GetPropertyCount()==properties && generated.GetPropertyCount()==properties, "Property count: "+name);
        for(int i=0;i<source.GetPropertyCount();i++)
        {
            string property=source.GetPropertyName(i); int j=generated.FindPropertyIndex(property);
            Check(j>=0 && source.GetPropertyType(i)==generated.GetPropertyType(j) && source.GetPropertyFlags(i)==generated.GetPropertyFlags(j),"Property type/flags: "+property);
            Check(source.GetPropertyAttributes(i).SequenceEqual(generated.GetPropertyAttributes(j)),"Property attributes: "+property);
            var kind=source.GetPropertyType(i);
            if(kind==ShaderPropertyType.Float) Check(source.GetPropertyDefaultFloatValue(i)==generated.GetPropertyDefaultFloatValue(j),"Float default: "+property);
            if(kind==ShaderPropertyType.Color || kind==ShaderPropertyType.Vector) Check(source.GetPropertyDefaultVectorValue(i)==generated.GetPropertyDefaultVectorValue(j),"Vector default: "+property);
        }
        return generated;
    }
    private static Texture2D Texture()
    {
        var texture=new Texture2D(64,32,TextureFormat.RGBAFloat,false,true){filterMode=FilterMode.Point,wrapMode=TextureWrapMode.Clamp};
        var pixels=new Color[64*32];
        for(int y=0;y<32;y++)for(int x=0;x<64;x++)pixels[y*64+x]=new Color((x+1f)/65,(y+1f)/33,0.2f+0.6f*((x+y)%11)/11f,x<8 ? 0.0005f : 0.2f+0.7f*y/32);
        texture.SetPixels(pixels);texture.Apply();return texture;
    }
    private static void CompareNormal(Shader source,Shader generated)
    {
        var a=new Material(source);var b=new Material(generated);var texture=Texture();
        bool fog=RenderSettings.fog;var mode=RenderSettings.fogMode;var color=RenderSettings.fogColor;
        float start=RenderSettings.fogStartDistance,end=RenderSettings.fogEndDistance,density=RenderSettings.fogDensity;
        try
        {
            foreach(var material in new[]{a,b}){material.SetTexture("_MainTex",texture);material.SetTextureScale("_MainTex",new Vector2(0.7f,1.2f));material.SetTextureOffset("_MainTex",new Vector2(0.1f,-0.15f));Check(material.passCount==1 && material.renderQueue==2000,"One opaque pass");}
            RenderSettings.fogColor=new Color(0.17f,0.35f,0.56f,1);RenderSettings.fogStartDistance=0;RenderSettings.fogEndDistance=8;RenderSettings.fogDensity=0.25f;
            Color[] noFog=null,linear=null,offFlip=null,thresholdFlip=null,onFlip=null;
            for(int fogState=0;fogState<4;fogState++)
            {
                RenderSettings.fog=fogState!=0;RenderSettings.fogMode=fogState==2?FogMode.Exponential:fogState==3?FogMode.ExponentialSquared:FogMode.Linear;
                foreach(var m in new[]{a,b}){Keyword(m,"FOG_LINEAR",fogState==1);Keyword(m,"FOG_EXP",fogState==2);Keyword(m,"FOG_EXP2",fogState==3);}
                foreach(float flip in new[]{0f,0.5f,1f}) foreach(bool reverse in new[]{false,true})
                {
                    foreach(var m in new[]{a,b})m.SetFloat("_FlipHorizontally",flip);
                    var image=Compare(a,b,"normal-fog"+fogState+"-flip"+flip+"-reverse"+reverse,false,reverse,false);
                    Check(image.Select(c=>(Color32)c).Distinct().Count()>100,"Visible nonconstant two-sided reference");
                    if(!reverse && flip==0){if(fogState==0)noFog=image;if(fogState==1)linear=image;}
                    if(fogState==0 && !reverse){if(flip==0)offFlip=image;if(flip==0.5f)thresholdFlip=image;if(flip==1)onFlip=image;}
                }
            }
            File.AppendAllText("normal-pixels.txt","reference-fog-difference: "+Difference(noFog,linear)+"\n");
            Check(Difference(noFog,linear)>0.05f,"Fog must change reference rendering");
            Check(Difference(offFlip,thresholdFlip)==0 && Difference(offFlip,onFlip)>0.1f,"Strict flip threshold preserves equality");
            RenderSettings.fog=false;
            foreach(var m in new[]{a,b}){foreach(string keyword in new[]{"FOG_LINEAR","FOG_EXP","FOG_EXP2"})Keyword(m,keyword,false);m.SetFloat("_FlipHorizontally",0.5001f);}
            Check(Difference(Compare(a,b,"normal-flip-boundary",false,false,false),onFlip)==0,"Values just above threshold flip");
            foreach(var m in new[]{a,b}){m.SetTextureScale("_MainTex",Vector2.one);m.SetTextureOffset("_MainTex",Vector2.zero);}
            var identity=Compare(a,b,"normal-identity-ST",false,false,false);
            Check(Difference(identity,onFlip)>0.05f,"Texture ST must affect sampling");
            string text=File.ReadAllText(AssetDatabase.GetAssetPath(generated));
            Check(text.Contains("LOD 100") && text.Contains("#pragma target 2.5") && text.Contains("#pragma multi_compile_fog"),"Retain source LOD, implicit target and fog variants");
        }
        finally{RenderSettings.fog=fog;RenderSettings.fogMode=mode;RenderSettings.fogColor=color;RenderSettings.fogStartDistance=start;RenderSettings.fogEndDistance=end;RenderSettings.fogDensity=density;foreach(var obj in new UnityEngine.Object[]{a,b,texture})UnityEngine.Object.DestroyImmediate(obj);}
    }
    private static void CompareUi(Shader source,Shader generated)
    {
        var a=new Material(source);var b=new Material(generated);var texture=Texture();
        Shader.SetGlobalInt("unity_GUIZTestMode",(int)CompareFunction.Always);
        try
        {
            foreach(var m in new[]{a,b}){m.SetTexture("_MainTex",texture);m.SetColor("_Color",new Color(0.8f,0.65f,0.9f,0.75f));m.SetVector("_ViewRect",new Vector4(-0.12f,0.07f,1.3f,0.85f));m.SetVector("_ClipRect",new Vector4(-1.25f,-0.65f,1.1f,0.8f));Check(m.renderQueue==3000,"UI transparent queue");}
            Color[] plain=null,clipped=null,alphaClipped=null;
            for(int flags=0;flags<4;flags++)foreach(float flip in new[]{0f,0.5f,1f})
            {
                foreach(var m in new[]{a,b}){m.SetFloat("_FlipHorizontally",flip);Keyword(m,"UNITY_UI_CLIP_RECT",(flags&1)!=0);Keyword(m,"UNITY_UI_ALPHACLIP",(flags&2)!=0);}
                var image=Compare(a,b,"pan-variants"+flags+"-flip"+flip,true,false,false);
                Check(image.Any(c=>c.a>0.1f) && image.Select(c=>(Color32)c).Distinct().Count()>100,"Visible nonconstant UI reference");
                if(flip==0){if(flags==0)plain=image;if(flags==1)clipped=image;if(flags==2)alphaClipped=image;}
            }
            Check(Difference(plain,clipped)>0.05f,"Rect clipping must change rendering");
            Check(Difference(plain,alphaClipped)>0.00001f,"Alpha clipping must change rendering");
            foreach(var m in new[]{a,b}){Keyword(m,"UNITY_UI_CLIP_RECT",false);Keyword(m,"UNITY_UI_ALPHACLIP",false);m.SetFloat("_FlipHorizontally",0);}
            foreach(var rect in new[]{new Vector4(0,0,1,1),new Vector4(0.2f,0.3f,0.4f,0.5f)})
            {foreach(var m in new[]{a,b})m.SetVector("_ViewRect",rect);var image=Compare(a,b,"pan-view-"+rect.x,true,false,false);Check(Difference(plain,image)>0.05f,"Pan/zoom and outside-alpha mask must affect rendering");}
            for(int state=0;state<4;state++)
            {
                foreach(var m in new[]{a,b}){m.SetFloat("_StencilComp",state<2?(float)CompareFunction.Equal:(float)CompareFunction.NotEqual);m.SetFloat("_Stencil",state%2+1);}
                var image=Compare(a,b,"pan-stencil"+state,true,false,true);
                Check(state==1?image.All(c=>c.a==0):image.Any(c=>c.a>0.1f),"Stencil reference and comparison");
            }
            foreach(var m in new[]{a,b})m.SetFloat("_StencilComp",(float)CompareFunction.Always);
            foreach(int mask in new[]{0,14,1})
            {foreach(var m in new[]{a,b})m.SetFloat("_ColorMask",mask);var image=Compare(a,b,"pan-colormask"+mask,true,false,false);Check(mask==0?image.All(c=>c==Color.clear):mask==14?image.All(c=>c.a==0):image.All(c=>c.r==0&&c.g==0&&c.b==0),"ColorMask channels");}
            foreach(var m in new[]{a,b})m.SetFloat("_ColorMask",15);
            foreach(var depth in new[]{CompareFunction.Never,CompareFunction.Always})
            {Shader.SetGlobalInt("unity_GUIZTestMode",(int)depth);var image=Compare(a,b,"pan-ztest"+depth,true,false,false);Check(depth==CompareFunction.Never?image.All(c=>c.a==0):image.Any(c=>c.a>0.1f),"GUI depth test");}
            Check(File.ReadAllText(AssetDatabase.GetAssetPath(generated)).Contains("#pragma target 2.0"),"Keep UI Shader Model 2.0");
        }
        finally{Shader.SetGlobalInt("unity_GUIZTestMode",(int)CompareFunction.LessEqual);foreach(var obj in new UnityEngine.Object[]{a,b,texture})UnityEngine.Object.DestroyImmediate(obj);}
    }
    private static void Keyword(Material material,string name,bool enabled){if(enabled)material.EnableKeyword(name);else material.DisableKeyword(name);}
    private static float Difference(Color[] a,Color[] b){float max=0;for(int i=0;i<a.Length;i++)for(int c=0;c<4;c++)max=Mathf.Max(max,Mathf.Abs(a[i][c]-b[i][c]));return max;}
    private static Color[] Compare(Material a,Material b,string name,bool ui,bool reverse,bool stencil)
    {
        foreach(var m in new[]{a,b}){ShaderUtil.CompilePass(m,0,true);Check(!ShaderUtil.ShaderHasError(m.shader),"Compile state "+name);}
        var x=Render(a,ui,reverse,stencil);var y=Render(b,ui,reverse,stencil);float error=Difference(x,y);
        File.AppendAllText("normal-pixels.txt",name+": "+error.ToString("R",System.Globalization.CultureInfo.InvariantCulture)+"\n");
        Check(error<=0.0001f,"RGBA mismatch: "+name+" error="+error);cases++;return x;
    }
    private static Color[] Render(Material material,bool ui,bool reverse,bool stencil)
    {
        var mesh=new Mesh();mesh.vertices=new[]{new Vector3(-2,-1,0),new Vector3(2,-1,0),new Vector3(2,1,ui?0:1),new Vector3(-2,1,ui?0:1)};
        mesh.uv=new[]{new Vector2(0,0),new Vector2(1,0),new Vector2(1,1),new Vector2(0,1)};
        mesh.colors=new[]{new Color(0.4f,0.8f,0.9f,0.7f),new Color(0.9f,0.3f,0.7f,0.9f),new Color(0.8f,0.9f,0.2f,0.6f),new Color(0.5f,0.6f,0.8f,1)};
        mesh.triangles=reverse?new[]{0,2,1,0,3,2}:new[]{0,1,2,0,2,3};mesh.RecalculateBounds();
        var quad=new GameObject("Normal fixture"){layer=29};quad.AddComponent<MeshFilter>().sharedMesh=mesh;quad.AddComponent<MeshRenderer>().sharedMaterial=material;
        var cameraObject=new GameObject("Normal fixture camera");var camera=cameraObject.AddComponent<Camera>();camera.transform.position=new Vector3(0,0,ui?-2:-3);camera.orthographic=ui;camera.orthographicSize=1;camera.fieldOfView=60;camera.aspect=2;camera.nearClipPlane=0.1f;camera.farClipPlane=20;camera.cullingMask=1<<29;camera.clearFlags=CameraClearFlags.SolidColor;camera.backgroundColor=Color.clear;camera.allowHDR=true;camera.allowMSAA=false;
        GameObject writer=null;Material writeMaterial=null;
        if(stencil)
        {
            string path="Assets/Editor/StencilWriter.shader";
            if(!File.Exists(path)){File.WriteAllText(path,"Shader \"Hidden/ConverterTest/StencilWriter\" { SubShader { Tags { \"Queue\"=\"Geometry\" } Pass { Cull Off ZTest Always ZWrite Off ColorMask 0 Stencil { Ref 1 Comp Always Pass Replace } CGPROGRAM\n#pragma vertex vert\n#pragma fragment frag\n#include \"UnityCG.cginc\"\nfloat4 vert(float4 p:POSITION):SV_POSITION{return UnityObjectToClipPos(p);} float4 frag():SV_Target{return 0;}\nENDCG } } }");AssetDatabase.ImportAsset(path,ImportAssetOptions.ForceSynchronousImport);}
            writeMaterial=new Material(AssetDatabase.LoadAssetAtPath<Shader>(path));writer=new GameObject("Normal stencil fixture"){layer=29};writer.transform.position=new Vector3(-1,0,-0.1f);writer.transform.localScale=new Vector3(0.5f,1,1);writer.AddComponent<MeshFilter>().sharedMesh=mesh;writer.AddComponent<MeshRenderer>().sharedMaterial=writeMaterial;
        }
        var target=RenderTexture.GetTemporary(128,64,24,RenderTextureFormat.ARGBFloat,RenderTextureReadWrite.Linear);var previous=RenderTexture.active;Texture2D texture=null;
        try{camera.targetTexture=target;camera.Render();RenderTexture.active=target;texture=new Texture2D(128,64,TextureFormat.RGBAFloat,false,true);texture.ReadPixels(new Rect(0,0,128,64),0,0);texture.Apply();return texture.GetPixels();}
        finally{RenderTexture.active=previous;camera.targetTexture=null;RenderTexture.ReleaseTemporary(target);foreach(var obj in new UnityEngine.Object[]{mesh,quad,cameraObject,writer,writeMaterial,texture})if(obj!=null)UnityEngine.Object.DestroyImmediate(obj);}
    }
}
