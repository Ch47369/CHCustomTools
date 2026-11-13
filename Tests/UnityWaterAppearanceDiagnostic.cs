// Reproduce direct material assignment without modifying the user's project.
using System;
using System.IO;
using System.Linq;
using UnityEditor;
using UnityEngine;

public static class UnityWaterAppearanceDiagnostic
{
    [Serializable] sealed class Result
    {
        public bool passed;
        public string graphicsApi;
        public float shallowVsDeep, colorAlphaChange, densityChange, missingDepthChange;
        public string scope="Isolated flat water/bed fixture; not the user's live Scene view.";
    }
    static Material water;
    static string directory;
    public static void Run()
    {
        try
        {
            if(Path.GetFullPath(".").IndexOf(Path.DirectorySeparatorChar+".validation"+Path.DirectorySeparatorChar,StringComparison.OrdinalIgnoreCase)<0)throw new Exception("Isolation required");
            directory=Path.GetFullPath("WaterAppearanceDiagnostic");Directory.CreateDirectory(directory);
            water=new Material(AssetDatabase.LoadAssetAtPath<Material>("Assets/Shaders/DeepWater/DeepWater.mat"));
            water.SetFloat("_WaveHeight",0);water.SetFloat("_RippleStrength",0);water.SetFloat("_WaveSpeed",0);water.SetFloat("_CausticSpeed",0);
            foreach(string keyword in new[]{"_WATER_WAVES_ON","_WATER_RIPPLES_ON","_WATER_CAUSTICS_ON","_WATER_FOAM_ON","_WATER_FRESNEL_ON"})water.DisableKeyword(keyword);
            water.EnableKeyword("_SPECULARHIGHLIGHTS_OFF");water.EnableKeyword("_GLOSSYREFLECTIONS_OFF");
            var shallow=Render("shallow-035m-depth-on",.35f,true);
            var deep=Render("deep-3m-depth-on",3,true);
            var shallowColor=water.GetColor("_ShallowColor");var deepColor=water.GetColor("_DeepColor");
            shallowColor.a=0;deepColor.a=0;water.SetColor("_ShallowColor",shallowColor);water.SetColor("_DeepColor",deepColor);
            var alpha=Render("shallow-color-alpha-zero",.35f,true);
            water.SetFloat("_Density",3);
            var density=Render("shallow-density-3",.35f,true);
            water.SetFloat("_Density",.7f);
            // Record this render path's behavior when the camera does not request depth.
            // A previous preview may leave a global binding; this is not a portable fallback guarantee.
            var missing=Render("shallow-camera-depth-off",.35f,false);
            var result=new Result{graphicsApi=SystemInfo.graphicsDeviceType.ToString(),shallowVsDeep=Difference(shallow,deep),colorAlphaChange=Difference(shallow,alpha),densityChange=Difference(shallow,density),missingDepthChange=Difference(shallow,missing)};
            result.passed=result.shallowVsDeep>.01f && result.colorAlphaChange==0 && result.densityChange>.01f;
            File.WriteAllText(Path.Combine(directory,"results.json"),JsonUtility.ToJson(result,true));
            if(!result.passed)throw new Exception("Unexpected fixture response: "+JsonUtility.ToJson(result));
            Debug.Log("ASE_WATER_APPEARANCE_DIAGNOSTIC_PASS");EditorApplication.Exit(0);
        }
        catch(Exception e){Debug.LogException(e);EditorApplication.Exit(1);}
        finally{if(water!=null)UnityEngine.Object.DestroyImmediate(water);}
    }
    static float Difference(Color32[] a,Color32[] b)
    {
        double sum=0;int count=0;
        // Central patch is covered by water and the bed in every fixture.
        for(int y=64;y<192;y++)for(int x=64;x<192;x++){int i=y*256+x;sum+=Math.Abs(a[i].r-b[i].r)+Math.Abs(a[i].g-b[i].g)+Math.Abs(a[i].b-b[i].b);count+=3;}
        return (float)(sum/(count*255.0));
    }
    static Color32[] Render(string name,float depth,bool enableDepth)
    {
        var preview=new PreviewRenderUtility();Material bedMaterial=null;Texture2D image=null;
        try
        {
            preview.camera.nearClipPlane=.1f;preview.camera.farClipPlane=100;
            preview.camera.transform.position=new Vector3(0,8,-2);preview.camera.transform.LookAt(Vector3.zero);
            preview.cameraFieldOfView=40;preview.camera.depthTextureMode=enableDepth?DepthTextureMode.Depth:DepthTextureMode.None;
            preview.camera.allowHDR=false;preview.camera.allowMSAA=false;preview.camera.clearFlags=CameraClearFlags.SolidColor;preview.camera.backgroundColor=Color.gray;
            preview.ambientColor=Color.white;
            var surface=GameObject.CreatePrimitive(PrimitiveType.Plane);surface.GetComponent<Renderer>().sharedMaterial=water;preview.AddSingleGO(surface);
            // Standard contributes a ShadowCaster pass to Built-in depth rendering.
            bedMaterial=new Material(Shader.Find("Standard"));bedMaterial.color=new Color(.7f,.6f,.45f,1);bedMaterial.SetColor("_EmissionColor",new Color(.35f,.3f,.225f));bedMaterial.EnableKeyword("_EMISSION");
            var bed=GameObject.CreatePrimitive(PrimitiveType.Plane);bed.transform.position=new Vector3(0,-depth,0);bed.transform.localScale=Vector3.one*4;bed.GetComponent<Renderer>().sharedMaterial=bedMaterial;preview.AddSingleGO(bed);
            preview.lights[0].intensity=1;preview.lights[0].transform.rotation=Quaternion.Euler(45,0,0);
            preview.BeginStaticPreview(new Rect(0,0,256,256));preview.Render();image=preview.EndStaticPreview();
            File.WriteAllBytes(Path.Combine(directory,name+".png"),image.EncodeToPNG());return image.GetPixels32();
        }
        finally{preview.Cleanup();if(bedMaterial!=null)UnityEngine.Object.DestroyImmediate(bedMaterial);if(image!=null)UnityEngine.Object.DestroyImmediate(image);}
    }
}
