// Explicit-input image filters in isolated hosts. This does not inject a camera effect.
using System;
using System.IO;
using System.Linq;
using System.Collections.Generic;
using ASEShaderConverter;
using ASEShaderConverter.Editor;
using UnityEditor;
using UnityEngine;

public static class UnityPublicFilterSmoke
{
    [Serializable] public sealed class InputRow {public string id,output;}
    [Serializable] public sealed class Input {public bool completed;public string pipeline;public InputRow[] rows;}
    [Serializable] public sealed class Check {public string id,state,image;public float meanError,maxError;public int changedPixels;public bool compiled,oracleCompared;}
    [Serializable] public sealed class Evidence {public string pipeline,error,graphicsApi;public bool success,cameraIntegration=false,crossPipelineVisualEquivalence=false;public List<Check> checks=new List<Check>();}
    // Even dimensions keep identity pixels away from the point-sampled 8x8
    // fixture's exact cell boundaries (where either adjacent texel is valid).
    const int W=48,H=32;static Evidence result;static Texture2D main,trash,noise;static string directory;
    static float Frac(float x){return x-Mathf.Floor(x);}
    static Color Source(Vector2 uv)
    {
        int x=Mathf.Clamp(Mathf.FloorToInt(uv.x*8),0,7),y=Mathf.Clamp(Mathf.FloorToInt(uv.y*8),0,7);
        return new Color(.08f+x*.1f,.06f+y*.11f,.1f+((x+2*y)%7)*.1f,.15f+((x+y)%6)*.12f);
    }
    static Texture2D Texture(Func<int,int,Color> color,int size)
    {
        var t=new Texture2D(size,size,TextureFormat.RGBAFloat,false,true){filterMode=FilterMode.Point,wrapMode=TextureWrapMode.Clamp};
        for(int y=0;y<size;y++)for(int x=0;x<size;x++)t.SetPixel(x,y,color(x,y));t.Apply();return t;
    }
    public static void Run()
    {
        result=new Evidence{graphicsApi=SystemInfo.graphicsDeviceType.ToString()};
        try
        {
            if(Path.GetFullPath(".").IndexOf(Path.DirectorySeparatorChar+".validation"+Path.DirectorySeparatorChar,StringComparison.OrdinalIgnoreCase)<0)throw new Exception("Isolation required");
            var probe=ASEShaderConverter.Editor.ShaderConverterApi.Execute(new ShaderAgentRequest{operation="probe"});if(!probe.success)throw new Exception(probe.error);
            result.pipeline=probe.environment.activePipeline;Shader.globalRenderPipeline=result.pipeline=="HDRP"?"HDRenderPipeline":result.pipeline=="URP"?"UniversalPipeline":"";
            directory="LibraryBuildEvidence/PublicFilters033";Directory.CreateDirectory(directory);
            string[] args=Environment.GetCommandLineArgs();int at=Array.IndexOf(args,"-filterResults");if(at<0)throw new Exception("Missing fresh generation results");
            var input=JsonUtility.FromJson<Input>(File.ReadAllText(args[at+1]));if(!input.completed||input.pipeline!=result.pipeline||input.rows.Length!=4)throw new Exception("Wrong generation batch");
            main=Texture((x,y)=>Source(new Vector2((x+.5f)/8,(y+.5f)/8)),8);trash=Texture((x,y)=>new Color(.9f,.2f,.6f,.8f),1);noise=Texture((x,y)=>new Color(.73f,.21f,.75f,.95f),1);
            foreach(var row in input.rows)
            {
                var shader=AssetDatabase.LoadAssetAtPath<Shader>(row.output);if(shader==null||ShaderUtil.ShaderHasError(shader))throw new Exception("Missing or failed generated shader: "+row.id);
                var material=new Material(shader);material.SetTexture("_MainTex",main);Color[] baseline=null;
                try
                {
                    if(row.id.EndsWith("Vignette"))
                    {
                        material.SetVector("_Aspect",new Vector4(1.7f,.7f,0,0));
                        foreach(float falloff in new[]{0f,.5f,1.2f})
                        {
                            material.SetFloat("_Falloff",falloff);baseline=CheckImage(row.id,"Falloff"+falloff,material,uv=>{var c=Source(uv);float rf=Vector2.Scale((uv-Vector2.one*.5f)*2,new Vector2(1.7f,.7f)).magnitude*falloff;float a=1/(1+rf*rf);a*=a;return new Color(c.r*a,c.g*a,c.b*a,c.a);},baseline,falloff>0);
                        }
                    }
                    else if(row.id.EndsWith("AnalogGlitch"))
                    {
                        material.SetVector("_ScanLineJitter",new Vector4(0,1,0,0));material.SetVector("_VerticalJump",Vector4.zero);material.SetVector("_ColorDrift",Vector4.zero);material.SetFloat("_HorizontalShake",0);
                        baseline=CheckImage(row.id,"Identity",material,uv=>{var c=Source(uv);c.a=1;return c;},null,false);
                        foreach(float amount in new[]{.3f,.7f})
                        {
                            material.SetVector("_VerticalJump",new Vector4(amount,.173f,0,0));material.SetVector("_ColorDrift",new Vector4(.27f,.41f,0,0));
                            CheckImage(row.id,"JumpDrift"+amount,material,uv=>{float jump=Mathf.Lerp(uv.y,Frac(uv.y+.173f),amount);var a=Source(new Vector2(Frac(uv.x),Frac(jump)));var b=Source(new Vector2(Frac(uv.x+Mathf.Sin(jump+.41f)*.27f),Frac(jump)));return new Color(a.r,b.g,a.b,1);},baseline,true);
                        }
                        material.SetVector("_ScanLineJitter",new Vector4(.4f,.1f,0,0));material.SetFloat("_HorizontalShake",.15f);
                        CheckImage(row.id,"ScanlineAndShake",material,null,baseline,true);
                    }
                    else if(row.id.EndsWith("DigitalGlitch"))
                    {
                        material.SetTexture("_NoiseTex",noise);material.SetTexture("_TrashTex",trash);
                        foreach(float intensity in new[]{0f,.3f,.6f,1f})
                        {
                            material.SetFloat("_Intensity",intensity);
                            var frame=CheckImage(row.id,"Intensity"+intensity,material,uv=>{
                                float threshold=1.001f-intensity*1.001f;float wd=Mathf.Pow(.75f,2.5f)>=threshold?1:0,wf=Mathf.Pow(.95f,2.5f)>=threshold?1:0,wc=Mathf.Pow(.75f,3.5f)>=threshold?1:0;
                                var src=Source(new Vector2(Frac(uv.x+.73f*wd),Frac(uv.y+.21f*wd)));var c=Color.Lerp(src,new Color(.9f,.2f,.6f,.8f),wf);float d=(1-c.r-c.g-c.b)*.5f;var neg=new Color(Mathf.Clamp01(c.g+d),Mathf.Clamp01(c.r+d),Mathf.Clamp01(c.b+d),src.a);var dst=Color.Lerp(c,neg,wc);dst.a=src.a;return dst;
                            },baseline,intensity>0);if(baseline==null)baseline=frame;
                        }
                    }
                    else if(row.id.EndsWith("Mirror"))
                    {
                        material.SetFloat("_Divisor",1.731f);material.SetFloat("_Offset",.217f);material.SetFloat("_Roll",.391f);material.DisableKeyword("SYMMETRY_ON");
                        foreach(bool symmetric in new[]{false,true})
                        {
                            if(symmetric)Shader.EnableKeyword("SYMMETRY_ON");else Shader.DisableKeyword("SYMMETRY_ON");
                            var frame=CheckImage(row.id,"GlobalSymmetry"+symmetric,material,uv=>{var sc=uv-Vector2.one*.5f;float phi=Mathf.Atan2(sc.y,sc.x)+.217f;phi-=1.731f*Mathf.Floor(phi/1.731f);if(symmetric)phi=Mathf.Min(phi,1.731f-phi);phi+=.391f-.217f;var v=new Vector2(Mathf.Cos(phi),Mathf.Sin(phi))*sc.magnitude+Vector2.one*.5f;v=new Vector2(Mathf.Max(Mathf.Min(v.x,2-v.x),-v.x),Mathf.Max(Mathf.Min(v.y,2-v.y),-v.y));return Source(v);},baseline,symmetric);if(baseline==null)baseline=frame;
                        }
                        Shader.DisableKeyword("SYMMETRY_ON");
                    }
                    else throw new Exception("Unexpected source family");
                }finally{Shader.DisableKeyword("SYMMETRY_ON");UnityEngine.Object.DestroyImmediate(material);}
            }
            if(result.checks.Count!=13)throw new Exception("Missing filter states");result.success=true;
        }
        catch(Exception e){result.error=e.ToString();Debug.LogException(e);}
        finally
        {
            Shader.DisableKeyword("SYMMETRY_ON");if(main!=null)UnityEngine.Object.DestroyImmediate(main);if(noise!=null)UnityEngine.Object.DestroyImmediate(noise);if(trash!=null)UnityEngine.Object.DestroyImmediate(trash);
            Directory.CreateDirectory("LibraryBuildEvidence");File.WriteAllText("LibraryBuildEvidence/public-filters-033.json",JsonUtility.ToJson(result,true));
        }
        Debug.Log("ASE_PUBLIC_FILTER_SMOKE "+result.pipeline+" "+result.success+" "+result.checks.Count);EditorApplication.Exit(result.success?0:1);
    }
    static Color[] CheckImage(string id,string state,Material material,Func<Vector2,Color> oracle,Color[] baseline,bool requireChange)
    {
        var rt=new RenderTexture(W,H,0,RenderTextureFormat.ARGBFloat,RenderTextureReadWrite.Linear);rt.Create();var previous=RenderTexture.active;var read=new Texture2D(W,H,TextureFormat.RGBAFloat,false,true);bool oldSRGB=GL.sRGBWrite;
        try
        {
            GL.sRGBWrite=false;Shader.SetGlobalVector("_Time",new Vector4(.017f,.34f,.68f,1.02f));
            if(!material.SetPass(0)||ShaderUtil.ShaderHasError(material.shader))throw new Exception("Filter pass compilation failed");
            Graphics.Blit(main,rt,material,0);RenderTexture.active=rt;read.ReadPixels(new Rect(0,0,W,H),0,0);read.Apply();var pixels=read.GetPixels();
            var check=new Check{id=id,state=state,compiled=true,oracleCompared=oracle!=null,image=directory+"/"+id+"-"+state+".png"};
            for(int y=0;y<H;y++)for(int x=0;x<W;x++)
            {
                int i=y*W+x;var got=pixels[i];if(float.IsNaN(got.r)||float.IsInfinity(got.r)||float.IsNaN(got.a))throw new Exception("Nonfinite output");
                if(oracle!=null){var expected=oracle(new Vector2((x+.5f)/W,(y+.5f)/H));float error=Mathf.Max(Mathf.Abs(got.r-expected.r),Mathf.Abs(got.g-expected.g),Mathf.Abs(got.b-expected.b),Mathf.Abs(got.a-expected.a));check.maxError=Mathf.Max(check.maxError,error);check.meanError+=error/(W*H);}
                if(baseline!=null&&Mathf.Max(Mathf.Abs(got.r-baseline[i].r),Mathf.Abs(got.g-baseline[i].g),Mathf.Abs(got.b-baseline[i].b))>.01f)check.changedPixels++;
            }
            // PNG is a display preview; comparison uses the unencoded float readback.
            var png=new Texture2D(W,H,TextureFormat.RGBA32,false,true);png.SetPixels(pixels);png.Apply();File.WriteAllBytes(check.image,png.EncodeToPNG());UnityEngine.Object.DestroyImmediate(png);
            result.checks.Add(check);
            if(oracle!=null&&check.meanError>.002f)throw new Exception(id+" "+state+" differs from source-formula oracle: "+check.meanError+" max "+check.maxError);
            if(requireChange&&check.changedPixels<32)throw new Exception(id+" "+state+" has no measurable effect");return pixels;
        }finally{GL.sRGBWrite=oldSRGB;RenderTexture.active=previous;rt.Release();UnityEngine.Object.DestroyImmediate(rt);UnityEngine.Object.DestroyImmediate(read);}
    }
}
