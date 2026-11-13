// Run in the isolated URP/HDRP validation projects. Uses the real SRP camera,
// opaque scene copy and depth; a fullscreen Blit cannot validate water depth.
using System;
using System.IO;
using System.Linq;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;
using ASEShaderConverter;
using ASEShaderConverter.Editor;
using Object=UnityEngine.Object;

public static class UnityCrossPipelineWaterSmoke
{
    [Serializable] public sealed class Check {public string name,image;public bool compiled;public int changedPixels;public float meanDifference;}
    [Serializable] public sealed class Evidence {public string pipeline,error,graphicsApi;public bool success,visualEquivalence;public Check[] checks;}
    static string directory;static Evidence result;
    public static void Run()
    {
        result=new Evidence{graphicsApi=SystemInfo.graphicsDeviceType.ToString()};
        PreviewRenderUtility preview=null;Material water=null,bed=null;Mesh mesh=null,ground=null;Texture2D checker=null;VolumeProfile profile=null;
        try
        {
            if(Path.GetFullPath(".").IndexOf(Path.DirectorySeparatorChar+".validation"+Path.DirectorySeparatorChar,StringComparison.OrdinalIgnoreCase)<0)throw new Exception("Isolation required");
            var probe=ShaderConverterApi.Execute(new ShaderAgentRequest{operation="probe"});if(!probe.success)throw new Exception(probe.error);
            result.pipeline=probe.environment.activePipeline;
            directory="LibraryBuildEvidence/Water032";Directory.CreateDirectory(directory);
            string[] args=Environment.GetCommandLineArgs();int at=Array.IndexOf(args,"-waterShader");if(at<0)throw new Exception("Missing shader path");
            var shader=AssetDatabase.LoadAssetAtPath<Shader>(args[at+1]);if(shader==null)throw new Exception("Shader missing");
            Shader.globalRenderPipeline=result.pipeline=="HDRP"?"HDRenderPipeline":"UniversalPipeline";
            water=new Material(shader);
            ShaderLibraryMaterialDefaults.Initialize(new ShaderLibraryEntry{origin="OriginalValidatedWater",pipeline=result.pipeline},water);
            water.SetFloat("_WaveSpeed",0);water.SetFloat("_CausticSpeed",0);
            if(PlayerSettings.colorSpace!=ColorSpace.Linear)throw new Exception("SRP water evidence requires a Linear validation host");
            preview=new PreviewRenderUtility();preview.cameraFieldOfView=43;
            // URP deliberately disables CopyColor for Preview cameras. Exercise
            // the real Game-camera path so refraction cannot sample a fallback.
            preview.camera.cameraType=CameraType.Game;
            preview.camera.nearClipPlane=.1f;preview.camera.farClipPlane=100;preview.camera.depthTextureMode=DepthTextureMode.Depth;
            preview.camera.allowMSAA=false;preview.camera.allowHDR=true;
            preview.camera.transform.position=new Vector3(-7,6,-10);preview.camera.transform.LookAt(new Vector3(0,-.4f,0));
            preview.camera.clearFlags=CameraClearFlags.SolidColor;preview.camera.backgroundColor=new Color(.12f,.2f,.3f,1);
            string dataName=result.pipeline=="URP"?"UnityEngine.Rendering.Universal.UniversalAdditionalCameraData":"UnityEngine.Rendering.HighDefinition.HDAdditionalCameraData";
            var dataType=AppDomain.CurrentDomain.GetAssemblies().Select(a=>a.GetType(dataName)).First(t=>t!=null);
            var data=preview.camera.gameObject.GetComponent(dataType)??preview.camera.gameObject.AddComponent(dataType);
            if(result.pipeline=="URP")foreach(string name in new[]{"requiresColorTexture","requiresDepthTexture"})dataType.GetProperty(name).SetValue(data,true);
            if(result.pipeline=="HDRP")
            {
                dataType.GetField("clearColorMode").SetValue(data,Enum.Parse(dataType.GetField("clearColorMode").FieldType,"Color"));
                dataType.GetField("backgroundColorHDR").SetValue(data,new Color(.12f,.2f,.3f,1));
                dataType.GetField("volumeLayerMask").SetValue(data,(LayerMask)(1<<30));
                var exposureType=AppDomain.CurrentDomain.GetAssemblies().Select(a=>a.GetType("UnityEngine.Rendering.HighDefinition.Exposure")).First(t=>t!=null);
                profile=ScriptableObject.CreateInstance<VolumeProfile>();var exposure=profile.Add(exposureType,true);
                var mode=exposureType.GetField("mode").GetValue(exposure);var modeValue=mode.GetType().GetProperty("value");modeValue.SetValue(mode,Enum.Parse(modeValue.PropertyType,"Fixed"));
                var fixedExposure=exposureType.GetField("fixedExposure").GetValue(exposure);fixedExposure.GetType().GetProperty("value").SetValue(fixedExposure,0f);
                var volumeObject=new GameObject("Fixed exposure fixture");volumeObject.layer=30;var volume=volumeObject.AddComponent<Volume>();volume.isGlobal=true;volume.priority=10000;volume.sharedProfile=profile;preview.AddSingleGO(volumeObject);
            }
            preview.lights[0].intensity=1;preview.lights[0].transform.rotation=Quaternion.Euler(45,-35,0);
            mesh=Grid(false);ground=Grid(true);
            var waterObject=Add(preview,mesh,water,"Water");
            bed=new Material(Shader.Find(result.pipeline=="URP"?"Universal Render Pipeline/Unlit":"HDRP/Unlit"));
            checker=new Texture2D(16,16,TextureFormat.RGBA32,false,true){wrapMode=TextureWrapMode.Repeat,filterMode=FilterMode.Point};
            var colors=new Color[256];for(int y=0;y<16;y++)for(int x=0;x<16;x++)colors[y*16+x]=((x+y)%2==0)?new Color(.8f,.48f,.15f):new Color(.2f,.35f,.62f);checker.SetPixels(colors);checker.Apply();
            foreach(string p in new[]{"_BaseColor","_UnlitColor"})if(bed.HasProperty(p))bed.SetColor(p,Color.white);
            foreach(string p in new[]{"_BaseMap","_UnlitColorMap"})if(bed.HasProperty(p))bed.SetTexture(p,checker);
            Add(preview,ground,bed,"Sloping opaque checker bed");
            var checks=new System.Collections.Generic.List<Check>();
            Color32[] reference=Render(preview,water,"AllOn",checks,null);
            foreach(string feature in new[]{"WAVES","RIPPLES","FRESNEL","DEPTH","FOAM","CAUSTICS","SCATTER","REFRACTION"})
            {
                string keyword="_WATER_"+feature+"_ON";water.DisableKeyword(keyword);
                Render(preview,water,"Without_"+feature,checks,reference);water.EnableKeyword(keyword);
            }
            water.SetFloat("_Density",.05f);var thin=Render(preview,water,"DensityLow",checks,null);
            water.SetFloat("_Density",2);Render(preview,water,"DensityHigh",checks,thin);
            result.checks=checks.ToArray();
            if(checks.Any(c=>!c.compiled))throw new Exception("A feature keyword variant failed compilation");
            if(checks.First(c=>c.name=="DensityHigh").changedPixels<32)throw new Exception("Density did not affect the opaque-bed fixture; scene depth/color host requires investigation");
            if(checks.First(c=>c.name=="Without_DEPTH").changedPixels<32)throw new Exception("Depth absorption toggle had no visible fixture effect");
            if(checks.First(c=>c.name=="Without_CAUSTICS").changedPixels<32)throw new Exception("Caustics did not affect the opaque scene-color fixture");
            water.SetFloat("_Density",.7f);
            foreach(string f in new[]{"WAVES","RIPPLES","FRESNEL","DEPTH","FOAM","CAUSTICS","SCATTER"})water.DisableKeyword("_WATER_"+f+"_ON");
            water.SetFloat("_ReflectionStrength",0);water.SetFloat("_RefractionStrength",0);
            if(result.pipeline=="URP")
            {
                // Specular F0=0 still has a grazing environment Fresnel lobe in
                // URP. Disable the actual lighting variants for a copy test.
                water.SetFloat("_SpecularHighlights",0);water.SetFloat("_EnvironmentReflections",0);
                water.EnableKeyword("_SPECULARHIGHLIGHTS_OFF");water.EnableKeyword("_ENVIRONMENTREFLECTIONS_OFF");
            }
            var transmission=Render(preview,water,"ClearTransmission",checks,null);
            waterObject.GetComponent<Renderer>().enabled=false;
            Render(preview,water,"OpaqueBedReference",checks,transmission);
            result.checks=checks.ToArray();
            if(checks.Last().meanDifference>.015f)throw new Exception("Unabsorbed scene-color transmission differs from opaque bed; color copy or exposure mapping is invalid");
            result.success=true;
        }
        catch(Exception e){result.error=e.ToString();Debug.LogException(e);}
        finally
        {
            if(preview!=null)preview.Cleanup();if(profile!=null){foreach(var c in profile.components)Object.DestroyImmediate(c);Object.DestroyImmediate(profile);}foreach(var o in new Object[]{water,bed,mesh,ground,checker})if(o!=null)Object.DestroyImmediate(o);
            Directory.CreateDirectory("LibraryBuildEvidence");File.WriteAllText("LibraryBuildEvidence/water-smoke-032.json",JsonUtility.ToJson(result,true));
            Debug.Log("ASE_WATER_SRP_SMOKE "+result.pipeline+" "+result.success);EditorApplication.Exit(result.success?0:1);
        }
    }
    static Color32[] Render(PreviewRenderUtility preview,Material material,string name,System.Collections.Generic.List<Check> checks,Color32[] reference)
    {
        // Warm camera history/pyramid and compile each variant before comparison.
        preview.BeginStaticPreview(new Rect(0,0,480,300));preview.Render(true);if(result.pipeline=="HDRP"){preview.Render(true);preview.Render(true);}var image=preview.EndStaticPreview();
        try
        {
            var pixels=image.GetPixels32();int changed=0;double difference=0;
            if(reference!=null)for(int i=0;i<pixels.Length;i++){int d=Math.Abs(pixels[i].r-reference[i].r)+Math.Abs(pixels[i].g-reference[i].g)+Math.Abs(pixels[i].b-reference[i].b);difference+=d;if(d>6)changed++;}
            string path=directory+"/"+name+".png";File.WriteAllBytes(path,image.EncodeToPNG());
            int pass=material.FindPass(result.pipeline=="URP"?"ForwardLit":"Forward");
            checks.Add(new Check{name=name,image=path,compiled=pass>=0&&material.SetPass(pass)&&!ShaderUtil.ShaderHasError(material.shader),changedPixels=changed,meanDifference=(float)(difference/(pixels.Length*3*255))});return pixels;
        }finally{Object.DestroyImmediate(image);}
    }
    static GameObject Add(PreviewRenderUtility p,Mesh mesh,Material material,string name)
    {
        var go=new GameObject(name);go.AddComponent<MeshFilter>().sharedMesh=mesh;go.AddComponent<MeshRenderer>().sharedMaterial=material;p.AddSingleGO(go);return go;
    }
    static Mesh Grid(bool bed)
    {
        const int n=48;var vertices=new Vector3[(n+1)*(n+1)];var normals=new Vector3[vertices.Length];var tangents=new Vector4[vertices.Length];var uv=new Vector2[vertices.Length];var triangles=new int[n*n*6];int t=0;
        for(int z=0;z<=n;z++)for(int x=0;x<=n;x++){int i=z*(n+1)+x;float px=(x/(float)n-.5f)*16,pz=(z/(float)n-.5f)*16;vertices[i]=new Vector3(px,bed?-.8f-px*.23f:0,pz);normals[i]=Vector3.up;tangents[i]=new Vector4(1,0,0,-1);uv[i]=new Vector2(x/(float)n,z/(float)n);}
        for(int z=0;z<n;z++)for(int x=0;x<n;x++){int i=z*(n+1)+x;triangles[t++]=i;triangles[t++]=i+n+1;triangles[t++]=i+1;triangles[t++]=i+1;triangles[t++]=i+n+1;triangles[t++]=i+n+2;}
        var mesh=new Mesh{vertices=vertices,normals=normals,tangents=tangents,uv=uv,triangles=triangles};mesh.RecalculateBounds();return mesh;
    }
}
