// Real isolated rendering of the complete glitter source and native ASE conversion.
using System;
using System.IO;
using System.Linq;
using System.Collections.Generic;
using ASEShaderConverter;
using ASEShaderConverter.Editor;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

public static class UnityShowcaseValidation
{
    [Serializable] public sealed class Row { public string state,image;public float meanError,maxError;public int changedPixels,visiblePixels;public bool sourceCompared,compiled; }
    [Serializable] public sealed class Evidence { public string pipeline,error,finishedUtc,colorSpace;public bool success,sourceSceneEquivalence=false;public List<Row> checks=new List<Row>();public int sourcePassCount,asePassCount; }
    static Evidence result;static Camera camera;static Mesh mesh;static Material material,reference;static Texture2D noise,ramp,normal,mask,albedo;static string folder;const int W=160,H=128;
    static Texture2D Texture(Func<float,float,Color> create,bool color=false)
    {
        const int size=128;var t=new Texture2D(size,size,TextureFormat.RGBAFloat,false,true){wrapMode=TextureWrapMode.Repeat,filterMode=FilterMode.Bilinear};
        for(int y=0;y<size;y++)for(int x=0;x<size;x++)t.SetPixel(x,y,create((x+.5f)/size,(y+.5f)/size));t.Apply();return t;
    }
    public static void Run()
    {
        result=new Evidence();try
        {
            if(Path.GetFullPath(".").IndexOf(Path.DirectorySeparatorChar+".validation"+Path.DirectorySeparatorChar,StringComparison.OrdinalIgnoreCase)<0)throw new Exception("Isolation required");
            var probe=ShaderConverterApi.Execute(new ShaderAgentRequest{operation="probe"});if(!probe.success)throw new Exception(probe.error);result.pipeline=probe.environment.activePipeline;result.colorSpace=PlayerSettings.colorSpace.ToString();
            Shader.globalRenderPipeline=result.pipeline=="HDRP"?"HDRenderPipeline":result.pipeline=="URP"?"UniversalPipeline":"";
            var build=JsonUtility.FromJson<UnityLibraryBuild.Results>(File.ReadAllText("LibraryBuildEvidence/results.json"));
            if(!build.completed||build.pipeline!=result.pipeline||build.rows.Count!=1||!build.rows[0].response.success)throw new Exception("Fresh generated shader build failed");
            var shader=AssetDatabase.LoadAssetAtPath<Shader>(build.rows[0].output);if(shader==null||ShaderUtil.ShaderHasError(shader))throw new Exception("Generated shader failed compilation");
            material=new Material(shader);result.asePassCount=material.passCount;
            if(result.pipeline=="URP")
            {
                string root=ShaderLibraryAssets.PackageRoot();var record=JsonUtility.FromJson<SourceRecord>(File.ReadAllText(Path.Combine(root,".build~/Showcase035/reviewed-source.json")));
                File.Copy(record.localPath,"Assets/ShowcaseReference035.shader",true);AssetDatabase.ImportAsset("Assets/ShowcaseReference035.shader",ImportAssetOptions.ForceSynchronousImport);
                var source=AssetDatabase.LoadAssetAtPath<Shader>("Assets/ShowcaseReference035.shader");if(source==null||ShaderUtil.ShaderHasError(source))throw new Exception("Original source shader compilation failed");reference=new Material(source);result.sourcePassCount=reference.passCount;
            }
            folder="LibraryBuildEvidence/Showcase035";Directory.CreateDirectory(folder);
            noise=Texture((u,v)=>{float a=Mathf.Sin((u*7+v*3)*Mathf.PI*2),b=Mathf.Sin((u*13-v*9)*Mathf.PI*2),c=Mathf.Sin((u*23+v*17)*Mathf.PI*2);float n=Mathf.Clamp01(.56f+.24f*a+.15f*b+.1f*c);return new Color(n,n,n,1);});
            ramp=Texture((u,v)=>Color.Lerp(new Color(.08f,.2f,.85f,1),new Color(.95f,.18f,.35f,1),Mathf.Clamp01(u*.5f+v*.5f)));
            normal=Texture((u,v)=>new Color(.5f+Mathf.Sin(u*Mathf.PI*4)*.16f,.5f+Mathf.Cos(v*Mathf.PI*6)*.13f,1,1));
            mask=Texture((u,v)=>{float d=Mathf.Pow(Mathf.Abs(u-.5f)*2,4)+Mathf.Pow(Mathf.Abs(v-.5f)*2,4);float m=d<.8f?1:0;return new Color(m,m,m,1);});
            albedo=Texture((u,v)=>new Color(.04f+u*.025f,.03f+v*.02f,.06f,1));
            var go=new GameObject("Showcase validation camera");camera=go.AddComponent<Camera>();camera.transform.position=new Vector3(0,0,-3);camera.fieldOfView=34;camera.aspect=W/(float)H;camera.nearClipPlane=.1f;camera.farClipPlane=50;
            var quad=GameObject.CreatePrimitive(PrimitiveType.Quad);mesh=quad.GetComponent<MeshFilter>().sharedMesh;UnityEngine.Object.DestroyImmediate(quad);
            foreach(var m in new[]{material,reference}.Where(m=>m!=null))
            {
                m.SetTexture("_NoiseTex",noise);m.SetTexture("_MipMap",ramp);m.SetTexture("_NormalMap",normal);m.SetTexture("_MaskAlpha",mask);m.SetTexture("_MainTex",albedo);
                m.SetColor("_BaseColor",new Color(.5f,.5f,.6f,1));m.SetColor("_SparkleColor",new Color(.12f,.45f,.9f,1));
                m.SetFloat("_Iteration",3);m.SetFloat("_NormalScale",1);m.SetFloat("_DepthStep",30);m.SetFloat("_DepthStep_02",60);m.SetFloat("_DepthStep_03",100);
                m.SetVector("_OffsetSecond",new Vector4(.22f,.38f,0,0));m.SetVector("_OffsetThird",new Vector4(.63f,.12f,0,0));
            }
            Color[] baseline=Check("Default",0,Matrix4x4.identity,null,false);
            foreach(float iteration in new[]{1f,1.5f,6f,15f})SetAndCheck("Iteration"+iteration,"_Iteration",iteration,baseline);
            Set("_Iteration",3);SetAndCheck("NoParallax","_DepthStep",0,baseline);Set("_DepthStep",30);
            SetAndCheck("DeepParallax","_DepthStep_02",220,baseline);Set("_DepthStep_02",60);
            SetAndCheck("FlatNormal","_NormalScale",0,baseline);SetAndCheck("StrongNormal","_NormalScale",1.8f,baseline);Set("_NormalScale",1);
            Check("FlowTime7",7,Matrix4x4.identity,baseline,true);
            Check("ViewAngle",0,Matrix4x4.TRS(Vector3.zero,Quaternion.Euler(0,28,0),Vector3.one),null,false);
            foreach(var m in new[]{material,reference}.Where(m=>m!=null)){m.SetTextureScale("_NoiseTex",new Vector2(1.8f,.7f));m.SetTextureOffset("_NoiseTex",new Vector2(.12f,.25f));m.SetTextureScale("_MipMap",new Vector2(.7f,1.4f));}
            Check("TextureST",0,Matrix4x4.identity,baseline,true);
            foreach(var m in new[]{material,reference}.Where(m=>m!=null))m.SetTexture("_MaskAlpha",Texture2D.whiteTexture);
            Check("CutoutDisabled",0,Matrix4x4.identity,baseline,true);
            if(result.checks.Any(c=>!c.compiled||c.visiblePixels<50))throw new Exception("Empty or failed rendered state");
            result.success=true;Finish(0);
        }catch(Exception e){result.error=e.ToString();Debug.LogException(e);Finish(1);}
    }
    [Serializable] public sealed class SourceRecord {public string localPath;}
    static void Set(string name,float value){material.SetFloat(name,value);if(reference!=null)reference.SetFloat(name,value);}
    static void SetAndCheck(string state,string name,float value,Color[] baseline){Set(name,value);Check(state,0,Matrix4x4.identity,baseline,true);}
    static Color[] Render(Material m,float seconds,Matrix4x4 model)
    {
        var rt=RenderTexture.GetTemporary(W,H,24,RenderTextureFormat.ARGBFloat,RenderTextureReadWrite.Linear);var buffer=new CommandBuffer();
        buffer.SetRenderTarget(rt);buffer.SetViewport(new Rect(0,0,W,H));buffer.ClearRenderTarget(true,true,Color.clear);buffer.SetViewProjectionMatrices(camera.worldToCameraMatrix,GL.GetGPUProjectionMatrix(camera.projectionMatrix,false));
        buffer.SetGlobalVector("_WorldSpaceCameraPos",camera.transform.position);buffer.SetGlobalVector("_Time",new Vector4(seconds/20,seconds,seconds*2,seconds*3));
        buffer.DrawMesh(mesh,model,m,0,0);Graphics.ExecuteCommandBuffer(buffer);buffer.Release();var previous=RenderTexture.active;RenderTexture.active=rt;
        var pixels=new Texture2D(W,H,TextureFormat.RGBAFloat,false,true);pixels.ReadPixels(new Rect(0,0,W,H),0,0);pixels.Apply();var colors=pixels.GetPixels();UnityEngine.Object.DestroyImmediate(pixels);RenderTexture.active=previous;RenderTexture.ReleaseTemporary(rt);return colors;
    }
    static Color[] Check(string state,float time,Matrix4x4 model,Color[] baseline,bool mustChange)
    {
        var colors=Render(material,time,model);var expected=reference==null?null:Render(reference,time,model);float mean=0,max=0;int changed=0,visible=0;
        for(int i=0;i<colors.Length;i++)
        {
            if(float.IsNaN(colors[i].r)||float.IsInfinity(colors[i].r))throw new Exception("Non-finite output "+state);
            if(colors[i].a>.5f)visible++;
            if(baseline!=null&&Distance(colors[i],baseline[i])>.002f)changed++;
            if(expected!=null){float d=Distance(colors[i],expected[i]);mean+=d;max=Mathf.Max(max,d);}
        }
        mean/=colors.Length;if(expected!=null&&mean>.003f)throw new Exception("Source pixel comparison failed "+state+" mean="+mean+" max="+max);
        if(mustChange&&changed<20)throw new Exception("Control had no visible effect "+state+" pixels="+changed);
        string path=folder+"/"+state+".png";var preview=new Texture2D(W,H,TextureFormat.RGBA32,false,true);
        using(var raw=new BinaryWriter(File.Create(folder+"/"+state+".rgba32f")))foreach(var c in colors){raw.Write(c.r);raw.Write(c.g);raw.Write(c.b);raw.Write(c.a);}
        preview.SetPixels(colors.Select(c=>new Color(Mathf.Pow(Mathf.Max(0,c.r)/(1+Mathf.Max(0,c.r)),1/2.2f),Mathf.Pow(Mathf.Max(0,c.g)/(1+Mathf.Max(0,c.g)),1/2.2f),Mathf.Pow(Mathf.Max(0,c.b)/(1+Mathf.Max(0,c.b)),1/2.2f),1)).ToArray());preview.Apply();File.WriteAllBytes(path,preview.EncodeToPNG());UnityEngine.Object.DestroyImmediate(preview);
        result.checks.Add(new Row{state=state,image=path,meanError=mean,maxError=max,changedPixels=changed,visiblePixels=visible,sourceCompared=expected!=null,compiled=!ShaderUtil.ShaderHasError(material.shader)});return colors;
    }
    static float Distance(Color a,Color b){return Mathf.Max(Mathf.Abs(a.r-b.r),Mathf.Abs(a.g-b.g),Mathf.Abs(a.b-b.b),Mathf.Abs(a.a-b.a));}
    [Serializable] public sealed class BatchEvidence
    {
        public string pipeline,error,finishedUtc;public bool success,apiLoaded,windowOpened,editsPreserved,shaderPreserved,sourceHashPreserved;
        public int textureChecks,presetChecks;public ShaderLibraryBatch.Item installed,reused;
    }
    public static void Batch()
    {
        var evidence=new BatchEvidence();int exit=1;
        try
        {
            if(Path.GetFullPath(".").IndexOf(Path.DirectorySeparatorChar+".validation"+Path.DirectorySeparatorChar,StringComparison.OrdinalIgnoreCase)<0)throw new Exception("Isolation required");
            var probe=ShaderConverterApi.Execute(new ShaderAgentRequest{operation="probe"});if(!probe.success)throw new Exception(probe.error);evidence.pipeline=probe.environment.activePipeline;
            Shader.globalRenderPipeline=evidence.pipeline=="HDRP"?"HDRenderPipeline":evidence.pipeline=="URP"?"UniversalPipeline":"";
            var api=ShaderConverterApi.Execute(new ShaderAgentRequest{operation="library"});evidence.apiLoaded=api.success&&api.shaderLibrary.version=="0.3.5";if(!evidence.apiLoaded)throw new Exception("New library API not loaded");
            var e=api.shaderLibrary.entries.Single(x=>x.origin=="ReviewedMaterialAdaptation"&&x.pipeline==evidence.pipeline);
            if(ShaderLibraryQuery.Filter(api.shaderLibrary,"源码适配 流麻 PC 高",pipeline:evidence.pipeline).Single().id!=e.id)throw new Exception("Full effect not searchable");
            if(ShaderLibraryQuery.Filter(api.shaderLibrary,"流麻",device:"Mobile").Length!=0)throw new Exception("High cost PC graph advertised as Mobile");
            var window=EditorWindow.GetWindow<ShaderLibraryWindow>();evidence.windowOpened=window!=null;window.Close();
            string source=ShaderLibraryAssets.VerifiedPath(e);var before=File.ReadAllBytes(source);
            evidence.installed=ShaderLibraryBatch.Generate(e.id);if(!evidence.installed.success)throw new Exception(evidence.installed.error);
            var m=AssetDatabase.LoadAssetAtPath<Material>(evidence.installed.materialPath);
            string[] props={"_NoiseTex","_MipMap","_NormalMap","_MaskAlpha","_MainTex"};bool[] srgb={false,true,false,false,true};
            for(int i=0;i<props.Length;i++)
            {
                var texture=m.GetTexture(props[i]);if(texture==null)throw new Exception("Missing sample resource "+props[i]);
                var importer=(TextureImporter)AssetImporter.GetAtPath(AssetDatabase.GetAssetPath(texture));
                if(importer.textureType!=TextureImporterType.Default||importer.sRGBTexture!=srgb[i]||!importer.mipmapEnabled||importer.textureCompression!=TextureImporterCompression.Uncompressed)throw new Exception("Wrong sample texture data "+props[i]);evidence.textureChecks++;
            }
            if(m.GetFloat("_Iteration")!=3||m.GetFloat("_DepthStep")!=30||m.GetFloat("_DepthStep_02")!=65||m.GetFloat("_DepthStep_03")!=110)throw new Exception("Full effect defaults not initialized");
            var temp=new Material(m);var colors=new List<Color>();
            for(int i=0;i<3;i++){ShowcaseMaterialPresets.Apply(temp,i);colors.Add(temp.GetColor("_SparkleColor"));evidence.presetChecks++;}
            UnityEngine.Object.DestroyImmediate(temp);if(colors.Distinct().Count()!=3)throw new Exception("Presets do not change the color");
            byte[] shaderBefore=File.ReadAllBytes(evidence.installed.shaderPath);var saved=m.GetColor("_SparkleColor");float speed=m.GetFloat("_ShiningSpeed");
            m.SetColor("_SparkleColor",new Color(2,.234f,.345f,1));m.SetFloat("_ShiningSpeed",4.25f);EditorUtility.SetDirty(m);AssetDatabase.SaveAssets();
            evidence.reused=ShaderLibraryBatch.Generate(e.id);evidence.editsPreserved=evidence.reused.success&&evidence.reused.materialReused&&evidence.reused.materialPath==evidence.installed.materialPath&&m.GetColor("_SparkleColor")==new Color(2,.234f,.345f,1)&&m.GetFloat("_ShiningSpeed")==4.25f;
            evidence.shaderPreserved=shaderBefore.SequenceEqual(File.ReadAllBytes(evidence.installed.shaderPath));evidence.sourceHashPreserved=before.SequenceEqual(File.ReadAllBytes(source));
            m.SetColor("_SparkleColor",saved);m.SetFloat("_ShiningSpeed",speed);EditorUtility.SetDirty(m);AssetDatabase.SaveAssets();
            evidence.success=evidence.editsPreserved&&evidence.shaderPreserved&&evidence.sourceHashPreserved&&evidence.windowOpened;exit=evidence.success?0:1;
        }catch(Exception ex){evidence.error=ex.ToString();Debug.LogException(ex);}
        evidence.finishedUtc=DateTime.UtcNow.ToString("o");Directory.CreateDirectory("LibraryBuildEvidence");File.WriteAllText("LibraryBuildEvidence/showcase-batch-035.json",JsonUtility.ToJson(evidence,true));Debug.Log("ASE_SHOWCASE_BATCH "+evidence.pipeline+" "+evidence.success);EditorApplication.Exit(exit);
    }
    [Serializable] public sealed class SceneEvidence
    {
        public string pipeline,error,finishedUtc,colorSpace;public bool success,realPipelineCamera,originalSceneEquivalence=false;
        public int materialChangedPixels;public float translatedCameraMeanError;public List<string> images=new List<string>();
    }
    public static void Scene()
    {
        var evidence=new SceneEvidence();PreviewRenderUtility preview=null;ScriptableObject profile=null;Material m=null;int exit=1;
        try
        {
            if(Path.GetFullPath(".").IndexOf(Path.DirectorySeparatorChar+".validation"+Path.DirectorySeparatorChar,StringComparison.OrdinalIgnoreCase)<0)throw new Exception("Isolation required");
            var probe=ShaderConverterApi.Execute(new ShaderAgentRequest{operation="probe"});if(!probe.success)throw new Exception(probe.error);evidence.pipeline=probe.environment.activePipeline;evidence.colorSpace=PlayerSettings.colorSpace.ToString();
            Shader.globalRenderPipeline=evidence.pipeline=="HDRP"?"HDRenderPipeline":evidence.pipeline=="URP"?"UniversalPipeline":"";
            var build=JsonUtility.FromJson<UnityLibraryBuild.Results>(File.ReadAllText("LibraryBuildEvidence/results.json"));if(!build.completed||!build.rows.Single().response.success)throw new Exception("Build not successful");
            m=new Material(AssetDatabase.LoadAssetAtPath<Shader>(build.rows[0].output));ShowcaseMaterialPresets.Initialize(m);
            preview=new PreviewRenderUtility();preview.cameraFieldOfView=34;preview.camera.cameraType=CameraType.Game;
            preview.camera.transform.position=new Vector3(0,0,-3);preview.camera.transform.rotation=Quaternion.identity;preview.camera.nearClipPlane=.1f;preview.camera.farClipPlane=50;
            preview.camera.clearFlags=CameraClearFlags.SolidColor;preview.camera.backgroundColor=Color.black;preview.camera.allowMSAA=false;preview.camera.allowHDR=true;
            if(evidence.pipeline!="BuiltIn")
            {
                string name=evidence.pipeline=="URP"?"UnityEngine.Rendering.Universal.UniversalAdditionalCameraData":"UnityEngine.Rendering.HighDefinition.HDAdditionalCameraData";
                var type=AppDomain.CurrentDomain.GetAssemblies().Select(a=>a.GetType(name)).First(t=>t!=null);var data=preview.camera.gameObject.GetComponent(type)??preview.camera.gameObject.AddComponent(type);
                if(evidence.pipeline=="HDRP")
                {
                    type.GetField("clearColorMode").SetValue(data,Enum.Parse(type.GetField("clearColorMode").FieldType,"Color"));type.GetField("backgroundColorHDR").SetValue(data,Color.black);type.GetField("volumeLayerMask").SetValue(data,(LayerMask)(1<<30));
                    var exposureType=AppDomain.CurrentDomain.GetAssemblies().Select(a=>a.GetType("UnityEngine.Rendering.HighDefinition.Exposure")).First(t=>t!=null);
                    var profileType=AppDomain.CurrentDomain.GetAssemblies().Select(a=>a.GetType("UnityEngine.Rendering.VolumeProfile")).First(t=>t!=null);profile=ScriptableObject.CreateInstance(profileType);
                    var exposure=profileType.GetMethod("Add",new[]{typeof(Type),typeof(bool)}).Invoke(profile,new object[]{exposureType,true});
                    var mode=exposureType.GetField("mode").GetValue(exposure);var value=mode.GetType().GetProperty("value");value.SetValue(mode,Enum.Parse(value.PropertyType,"Fixed"));
                    var fixedExposure=exposureType.GetField("fixedExposure").GetValue(exposure);fixedExposure.GetType().GetProperty("value").SetValue(fixedExposure,0f);
                    var volumeObject=new GameObject("Glitter fixed exposure");volumeObject.layer=30;
                    var volumeType=AppDomain.CurrentDomain.GetAssemblies().Select(a=>a.GetType("UnityEngine.Rendering.Volume")).First(t=>t!=null);var volume=volumeObject.AddComponent(volumeType);
                    volumeType.GetProperty("isGlobal").SetValue(volume,true);volumeType.GetField("priority").SetValue(volume,10000f);volumeType.GetField("sharedProfile").SetValue(volume,profile);preview.AddSingleGO(volumeObject);
                }
            }
            var obj=GameObject.CreatePrimitive(PrimitiveType.Quad);obj.name="Glitter mesh fixture";obj.GetComponent<MeshRenderer>().sharedMaterial=m;preview.AddSingleGO(obj);
            // SRP editor cameras advance engine time between renders. Remove time's
            // contribution only for the translation invariant, without changing the shader.
            var palette=m.GetTexture("_MipMap");m.SetTexture("_MipMap",Texture2D.whiteTexture);
            m.SetFloat("_ShiningSpeed",0);m.SetFloat("_ShiningSpeed_02",0);m.SetFloat("_ShiningSpeed_03",0);
            evidence.realPipelineCamera=true;var stationary=SceneImage(preview,evidence,"StationaryCamera");
            obj.transform.position=new Vector3(100,40,0);preview.camera.transform.position=new Vector3(100,40,-3);var moved=SceneImage(preview,evidence,"TranslatedCamera");
            double mean=0;for(int i=0;i<stationary.Length;i++)mean+=Distance(stationary[i],moved[i]);evidence.translatedCameraMeanError=(float)(mean/stationary.Length);
            if(evidence.translatedCameraMeanError>.01f)throw new Exception("Camera/object translation changed tangent view: "+evidence.translatedCameraMeanError);
            obj.transform.position=Vector3.zero;preview.camera.transform.position=new Vector3(0,0,-3);
            m.SetTexture("_MipMap",palette);ShowcaseMaterialPresets.Apply(m,0);var baseline=SceneImage(preview,evidence,"BlueCyan");
            ShowcaseMaterialPresets.Apply(m,1);SceneImage(preview,evidence,"GoldOrange");ShowcaseMaterialPresets.Apply(m,2);SceneImage(preview,evidence,"Purple");
            m.SetColor("_SparkleColor",Color.black);m.SetColor("_BaseColor",Color.black);var black=SceneImage(preview,evidence,"BlackControl");
            for(int i=0;i<baseline.Length;i++)if(Distance(baseline[i],black[i])>.02f)evidence.materialChangedPixels++;
            if(evidence.materialChangedPixels<100)throw new Exception("Actual pipeline camera did not render the glitter material");
            if(ShaderUtil.ShaderHasError(m.shader))throw new Exception("Scene variant failed shader compilation");evidence.success=true;exit=0;
        }catch(Exception ex){evidence.error=ex.ToString();Debug.LogException(ex);}
        finally
        {
            if(preview!=null)preview.Cleanup();if(profile!=null){foreach(UnityEngine.Object c in (System.Collections.IEnumerable)profile.GetType().GetField("components").GetValue(profile))UnityEngine.Object.DestroyImmediate(c);UnityEngine.Object.DestroyImmediate(profile);}if(m!=null)UnityEngine.Object.DestroyImmediate(m);
            evidence.finishedUtc=DateTime.UtcNow.ToString("o");Directory.CreateDirectory("LibraryBuildEvidence");File.WriteAllText("LibraryBuildEvidence/showcase-scene-035.json",JsonUtility.ToJson(evidence,true));Debug.Log("ASE_SHOWCASE_SCENE "+evidence.pipeline+" "+evidence.success);EditorApplication.Exit(exit);
        }
    }
    static Color[] SceneImage(PreviewRenderUtility preview,SceneEvidence evidence,string state)
    {
        preview.BeginStaticPreview(new Rect(0,0,480,360));preview.Render(true);if(evidence.pipeline=="HDRP"){preview.Render(true);preview.Render(true);}var image=preview.EndStaticPreview();
        try{string folder="LibraryBuildEvidence/Showcase035/Scene";Directory.CreateDirectory(folder);string path=folder+"/"+state+".png";File.WriteAllBytes(path,image.EncodeToPNG());evidence.images.Add(path);return image.GetPixels();}finally{UnityEngine.Object.DestroyImmediate(image);}
    }
    static void Finish(int code)
    {
        result.finishedUtc=DateTime.UtcNow.ToString("o");Directory.CreateDirectory("LibraryBuildEvidence");File.WriteAllText("LibraryBuildEvidence/showcase-render-035.json",JsonUtility.ToJson(result,true));
        Debug.Log("ASE_SHOWCASE_RENDER "+result.pipeline+" "+result.success+" states="+result.checks.Count);EditorApplication.Exit(code);
    }
}
