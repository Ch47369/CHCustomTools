// Local .validation only. Tests the published formula independently of the added Lit surface.
using System;
using System.IO;
using System.Linq;
using System.Collections.Generic;
using ASEShaderConverter;
using ASEShaderConverter.Editor;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

public static class UnityJadeArticleValidation
{
    [Serializable] public sealed class Row {public string state;public float maxError,meanError;public int checkedPixels,changedPixels;}
    [Serializable] public sealed class Evidence {public string pipeline,error,colorSpace,finishedUtc;public bool success,originalSceneEquivalent=false,realCamera;public int sceneChangedPixels,sceneLightChangedPixels,sceneVisiblePixels;public List<Row> formula=new List<Row>();public List<string> images=new List<string>();}
    static Evidence result;static Material fixture,material;static Camera camera;static Mesh quad;static string folder;
    const int W=96,H=80;
    static void Require(bool b,string message){if(!b)throw new Exception(message);}
    static void Isolated(){Require(Path.GetFullPath(".").IndexOf(Path.DirectorySeparatorChar+".validation"+Path.DirectorySeparatorChar,StringComparison.OrdinalIgnoreCase)>=0,"Isolation required");}
    public static void Run()
    {
        result=new Evidence();try
        {
            Isolated();var probe=ShaderConverterApi.Execute(new ShaderAgentRequest{operation="probe"});Require(probe.success,probe.error);result.pipeline=probe.environment.activePipeline;result.colorSpace=PlayerSettings.colorSpace.ToString();
            Shader.globalRenderPipeline=result.pipeline=="HDRP"?"HDRenderPipeline":result.pipeline=="URP"?"UniversalPipeline":"";
            var build=JsonUtility.FromJson<UnityLibraryBuild.Results>(File.ReadAllText("LibraryBuildEvidence/results.json"));Require(build.completed&&build.rows.Count==2&&build.rows.All(r=>r.response.success),"Two fresh generated graphs required");
            fixture=new Material(AssetDatabase.LoadAssetAtPath<Shader>(build.rows.Single(r=>r.id.EndsWith("-fixture")).output));material=new Material(AssetDatabase.LoadAssetAtPath<Shader>(build.rows.Single(r=>!r.id.EndsWith("-fixture")).output));
            folder="LibraryBuildEvidence/JadeArticle036";Directory.CreateDirectory(folder);
            camera=new GameObject("Jade formula camera").AddComponent<Camera>();camera.transform.position=new Vector3(0,0,-3);camera.orthographic=true;camera.orthographicSize=.7f;camera.aspect=W/(float)H;camera.nearClipPlane=.1f;camera.farClipPlane=30;
            var q=GameObject.CreatePrimitive(PrimitiveType.Quad);quad=q.GetComponent<MeshFilter>().sharedMesh;UnityEngine.Object.DestroyImmediate(q);
            var baseline=Check("Default",Matrix4x4.identity,null,false);
            FloatState("DepthThin","_JadeDepthDistance",.15f,baseline);FloatState("DepthThick","_JadeDepthDistance",1.8f,baseline);
            FloatState("LightNear","_JadeLightDistance",.2f,baseline);FloatState("LightFar","_JadeLightDistance",2.5f,baseline);
            FloatState("ExponentLow","_JadePow",.5f,baseline);FloatState("ExponentHigh","_JadePow",5,baseline);
            FloatState("RampMinimum","_JadeMinDist",.45f,baseline);FloatState("RampMaximum","_JadeMaxDist",.6f,baseline);
            // RGB>1 with remapped weight>1 detects incorrectly saturating the weight first.
            var old=fixture.GetColor("_JadeColor");fixture.SetColor("_JadeColor",new Color(.3f,1.3f,2.1f,1));fixture.SetFloat("_JadeMaxDist",.25f);Check("ChannelSaturateAfterMultiply",Matrix4x4.identity,baseline,true);fixture.SetFloat("_JadeMaxDist",.9f);fixture.SetColor("_JadeColor",old);
            fixture.SetVector("_JadeOffset",new Vector4(.2f,-.16f,.12f,0));Check("Offset",Matrix4x4.identity,baseline,true);fixture.SetVector("_JadeOffset",Vector4.zero);
            fixture.SetVector("_JadeMainLightWS",new Vector4(-.8f,.25f,-.4f,0));Check("LightDirection",Matrix4x4.identity,baseline,true);fixture.SetVector("_JadeMainLightWS",new Vector4(.6f,.5f,-.6f,0));
            Check("RotateNonUniformScale",Matrix4x4.TRS(new Vector3(.04f,-.03f,.2f),Quaternion.Euler(12,24,31),new Vector3(1.1f,.7f,1.5f)),null,false);
            camera.transform.position+=new Vector3(30,20,10);Check("TranslatedModelAndCamera",Matrix4x4.Translate(new Vector3(30,20,10)),null,false);camera.transform.position=new Vector3(0,0,-3);
            Scene();result.success=true;Finish(0);
        }catch(Exception e){result.error=e.ToString();Debug.LogException(e);Finish(1);}
    }
    static void FloatState(string state,string name,float value,Color[] baseline){float old=fixture.GetFloat(name);fixture.SetFloat(name,value);Check(state,Matrix4x4.identity,baseline,true);fixture.SetFloat(name,old);}
    static Color Reference(Vector3 p,Matrix4x4 model)
    {
        Vector3 dir=model.inverse.MultiplyVector(fixture.GetVector("_JadeMainLightWS")).normalized;
        Vector3 origin=(Vector3)fixture.GetVector("_JadeOffset")-dir*fixture.GetFloat("_JadeLightDistance");
        float travel=Mathf.Clamp01(Mathf.Pow(Vector3.Distance(origin,p)/(fixture.GetFloat("_JadeDepthDistance")+fixture.GetFloat("_JadeLightDistance")),fixture.GetFloat("_JadePow")));
        float weight=(travel-fixture.GetFloat("_JadeMinDist"))/(fixture.GetFloat("_JadeMaxDist")-fixture.GetFloat("_JadeMinDist"));var c=fixture.GetColor("_JadeColor");
        // ShaderLab Color properties upload sRGB inspector values as linear GPU
        // uniforms in a Linear project. The formula consumes those uniform values.
        if(PlayerSettings.colorSpace==ColorSpace.Linear)c=c.linear;
        return new Color(Mathf.Clamp01(weight*c.r),Mathf.Clamp01(weight*c.g),Mathf.Clamp01(weight*c.b),1);
    }
    static Color[] Render(Matrix4x4 model)
    {
        var rt=RenderTexture.GetTemporary(W,H,24,RenderTextureFormat.ARGBFloat,RenderTextureReadWrite.Linear);var cb=new CommandBuffer();cb.SetRenderTarget(rt);cb.ClearRenderTarget(true,true,Color.clear);cb.SetViewport(new Rect(0,0,W,H));cb.SetViewProjectionMatrices(camera.worldToCameraMatrix,GL.GetGPUProjectionMatrix(camera.projectionMatrix,false));cb.SetGlobalVector("_WorldSpaceCameraPos",camera.transform.position);cb.DrawMesh(quad,model,fixture,0,0);Graphics.ExecuteCommandBuffer(cb);cb.Release();
        var previous=RenderTexture.active;RenderTexture.active=rt;var t=new Texture2D(W,H,TextureFormat.RGBAFloat,false,true);t.ReadPixels(new Rect(0,0,W,H),0,0);t.Apply();var colors=t.GetPixels();UnityEngine.Object.DestroyImmediate(t);RenderTexture.active=previous;RenderTexture.ReleaseTemporary(rt);return colors;
    }
    static float Delta(Color a,Color b){return Mathf.Max(Mathf.Abs(a.r-b.r),Mathf.Abs(a.g-b.g),Mathf.Abs(a.b-b.b));}
    static Color[] Check(string state,Matrix4x4 model,Color[] baseline,bool mustChange)
    {
        var colors=Render(model);var row=new Row{state=state};var plane=new Plane(model.MultiplyVector(Vector3.forward).normalized,model.MultiplyPoint(Vector3.zero));
        for(int y=0;y<H;y++)for(int x=0;x<W;x++)
        {
            int i=y*W+x;if(colors[i].a<.5f)continue;Require(!float.IsNaN(colors[i].r)&&!float.IsInfinity(colors[i].r),"Nonfinite "+state);
            var ray=camera.ScreenPointToRay(new Vector3((x+.5f)*camera.pixelWidth/W,(y+.5f)*camera.pixelHeight/H));float hit;Require(plane.Raycast(ray,out hit),"No intersection");var pos=model.inverse.MultiplyPoint(ray.GetPoint(hit));
            if(Mathf.Abs(pos.x)>.49f||Mathf.Abs(pos.y)>.49f)continue;
            var expected=Reference(pos,model);float d=Delta(colors[i],expected);row.maxError=Mathf.Max(row.maxError,d);row.meanError+=d;row.checkedPixels++;
            if(state=="Default" && x==W/2 && (y==H/2||y==H/2+15))Debug.Log("JADE_FORMULA_SAMPLE pos="+pos.ToString("F6")+" gpu="+colors[i].ToString("F6")+" cpu="+expected.ToString("F6")+" color="+fixture.GetColor("_JadeColor").ToString("F6"));
            if(baseline!=null&&Delta(colors[i],baseline[i])>.002f)row.changedPixels++;
        }
        Require(row.checkedPixels>100,"Empty fixture "+state);row.meanError/=row.checkedPixels;result.formula.Add(row);
        Require(row.maxError<.0001f,"Formula error "+state+": "+row.maxError);Require(!mustChange||row.changedPixels>20,"No visible control change "+state);
        using(var raw=new BinaryWriter(File.Create(folder+"/"+state+".rgba32f")))foreach(var c in colors){raw.Write(c.r);raw.Write(c.g);raw.Write(c.b);raw.Write(c.a);}
        return colors;
    }
    static Type Find(string name){return AppDomain.CurrentDomain.GetAssemblies().Select(a=>a.GetType(name)).First(t=>t!=null);}
    static void Scene()
    {
        var preview=new PreviewRenderUtility();UnityEngine.Object profile=null;
        try
        {
            preview.cameraFieldOfView=35;preview.camera.cameraType=CameraType.Game;preview.camera.transform.position=new Vector3(0,.05f,-3.2f);preview.camera.transform.rotation=Quaternion.identity;preview.camera.nearClipPlane=.1f;preview.camera.farClipPlane=30;preview.camera.clearFlags=CameraClearFlags.SolidColor;preview.camera.backgroundColor=new Color(.018f,.022f,.028f,1);preview.camera.allowMSAA=false;preview.camera.allowHDR=true;
            if(result.pipeline!="BuiltIn")
            {
                var type=Find(result.pipeline=="URP"?"UnityEngine.Rendering.Universal.UniversalAdditionalCameraData":"UnityEngine.Rendering.HighDefinition.HDAdditionalCameraData");var data=preview.camera.gameObject.GetComponent(type)??preview.camera.gameObject.AddComponent(type);
                if(result.pipeline=="HDRP")
                {
                    type.GetField("clearColorMode").SetValue(data,Enum.Parse(type.GetField("clearColorMode").FieldType,"Color"));type.GetField("backgroundColorHDR").SetValue(data,preview.camera.backgroundColor);type.GetField("volumeLayerMask").SetValue(data,(LayerMask)(1<<30));
                    var et=Find("UnityEngine.Rendering.HighDefinition.Exposure");var pt=Find("UnityEngine.Rendering.VolumeProfile");profile=ScriptableObject.CreateInstance(pt);var e=pt.GetMethod("Add",new[]{typeof(Type),typeof(bool)}).Invoke(profile,new object[]{et,true});var mode=et.GetField("mode").GetValue(e);var value=mode.GetType().GetProperty("value");value.SetValue(mode,Enum.Parse(value.PropertyType,"Fixed"));var fixedValue=et.GetField("fixedExposure").GetValue(e);fixedValue.GetType().GetProperty("value").SetValue(fixedValue,0f);
                    var vo=new GameObject("Jade fixed exposure");vo.layer=30;var vt=Find("UnityEngine.Rendering.Volume");var volume=vo.AddComponent(vt);vt.GetProperty("isGlobal").SetValue(volume,true);vt.GetField("priority").SetValue(volume,10000f);vt.GetField("sharedProfile").SetValue(volume,profile);preview.AddSingleGO(vo);
                }
            }
            preview.lights[0].type=LightType.Directional;preview.lights[0].intensity=1.2f;preview.lights[0].transform.rotation=Quaternion.Euler(35,-35,0);preview.lights[1].intensity=.15f;
            var sphere=GameObject.CreatePrimitive(PrimitiveType.Sphere);sphere.name="Jade sphere";sphere.transform.localScale=Vector3.one*1.3f;sphere.GetComponent<Renderer>().sharedMaterial=material;preview.AddSingleGO(sphere);
            material.SetFloat("_JADE_SCENE_LIGHT",0);material.DisableKeyword("_JADE_SCENE_LIGHT_ON");
            var baseline=SceneImage(preview,"GreenManual");result.realCamera=true;
            material.SetColor("_JadeColor",new Color(.4f,.09f,.22f,1));SceneImage(preview,"PurpleManual");material.SetColor("_JadeColor",new Color(.09f,.65f,.3f,1));
            material.SetFloat("_JadeStrength",0);var dark=SceneImage(preview,"ScatteringOff");material.SetFloat("_JadeStrength",.8f);
            for(int i=0;i<baseline.Length;i++){if(Delta(baseline[i],dark[i])>.02f)result.sceneChangedPixels++;if(Delta(baseline[i],preview.camera.backgroundColor)>.04f)result.sceneVisiblePixels++;}
            Require(result.sceneChangedPixels>100,"Real camera did not show jade scattering");
            material.SetFloat("_JADE_SCENE_LIGHT",1);material.EnableKeyword("_JADE_SCENE_LIGHT_ON");material.SetColor("_SurfaceColor",Color.black);material.SetFloat("_Smoothness",0);
            var sceneLight=SceneImage(preview,"SceneLight");preview.lights[0].transform.rotation=Quaternion.Euler(35,125,0);var moved=SceneImage(preview,"SceneLightRotated");
            for(int i=0;i<sceneLight.Length;i++)if(Delta(sceneLight[i],moved[i])>.02f)result.sceneLightChangedPixels++;
            Require(result.sceneLightChangedPixels>100,"Scene main-light direction did not affect scattering");
        }finally{preview.Cleanup();if(profile!=null)UnityEngine.Object.DestroyImmediate(profile);}
    }
    static Color[] SceneImage(PreviewRenderUtility preview,string state)
    {
        preview.BeginStaticPreview(new Rect(0,0,480,400));preview.camera.aspect=1.2f;preview.Render(true);var image=preview.EndStaticPreview();
        try{string path=folder+"/"+state+".png";File.WriteAllBytes(path,image.EncodeToPNG());result.images.Add(path);return image.GetPixels();}finally{UnityEngine.Object.DestroyImmediate(image);}
    }
    static void Finish(int code)
    {
        result.finishedUtc=DateTime.UtcNow.ToString("o");Directory.CreateDirectory("LibraryBuildEvidence");File.WriteAllText("LibraryBuildEvidence/jade-validation-036.json",JsonUtility.ToJson(result,true));Debug.Log("ASE_JADE_VALIDATION "+result.pipeline+" "+result.success);EditorApplication.Exit(code);
    }
    [Serializable] public sealed class BatchEvidence {public string pipeline,error,finishedUtc;public bool success,apiLoaded,windowOpened,editsPreserved,keywordInitialized;public ShaderLibraryBatch.Item installed,reused;}
    public static void Batch()
    {
        var e=new BatchEvidence();int exit=1;try
        {
            Isolated();var probe=ShaderConverterApi.Execute(new ShaderAgentRequest{operation="probe"});Require(probe.success,probe.error);e.pipeline=probe.environment.activePipeline;
            var api=ShaderConverterApi.Execute(new ShaderAgentRequest{operation="library"});e.apiLoaded=api.success;Require(e.apiLoaded,"Library API failed");
            var entry=api.shaderLibrary.entries.Single(x=>x.id=="jade-article-"+e.pipeline);
            Require(ShaderLibraryQuery.Filter(api.shaderLibrary,"方木君 逻辑 玉石",pipeline:e.pipeline).Any(x=>x.id==entry.id),"Article jade is not searchable");
            var window=EditorWindow.GetWindow<ShaderLibraryWindow>();e.windowOpened=window!=null;window.Close();
            e.installed=ShaderLibraryBatch.Generate(entry.id);Require(e.installed.success,e.installed.error);var m=AssetDatabase.LoadAssetAtPath<Material>(e.installed.materialPath);
            if(!e.installed.materialReused){e.keywordInitialized=m.GetFloat("_JADE_SCENE_LIGHT")==1&&m.IsKeywordEnabled("_JADE_SCENE_LIGHT_ON");Require(e.keywordInitialized,"New jade material did not enable scene main-light keyword");}else e.keywordInitialized=true;
            m.SetFloat("_JadePow",3.17f);m.SetColor("_JadeColor",new Color(.22f,.35f,.14f,1));m.SetFloat("_JADE_SCENE_LIGHT",0);m.DisableKeyword("_JADE_SCENE_LIGHT_ON");EditorUtility.SetDirty(m);AssetDatabase.SaveAssets();
            e.reused=ShaderLibraryBatch.Generate(entry.id);Require(e.reused.success&&e.reused.materialReused,e.reused.error??"Material not reused");
            e.editsPreserved=Mathf.Abs(m.GetFloat("_JadePow")-3.17f)<.0001f&&m.GetColor("_JadeColor")==new Color(.22f,.35f,.14f,1)&&!m.IsKeywordEnabled("_JADE_SCENE_LIGHT_ON")&&e.reused.shaderPath==e.installed.shaderPath;
            Require(e.editsPreserved,"Reused jade material edits lost");e.success=true;exit=0;
        }catch(Exception ex){e.error=ex.ToString();Debug.LogException(ex);}
        e.finishedUtc=DateTime.UtcNow.ToString("o");Directory.CreateDirectory("LibraryBuildEvidence");File.WriteAllText("LibraryBuildEvidence/jade-batch-036.json",JsonUtility.ToJson(e,true));EditorApplication.Exit(exit);
    }
}
