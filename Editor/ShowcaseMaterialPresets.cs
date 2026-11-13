using System;
using System.IO;
using UnityEditor;
using UnityEngine;

namespace ASEShaderConverter.Editor
{
    // Original procedural resources only. No reference-project images are distributed.
    public static class ShowcaseMaterialPresets
    {
        const string Folder="Assets/ASEShaderLibrary/Shared/Showcase035";
        public static void Initialize(Material material)
        {
            material.SetTexture("_NoiseTex",Ensure("GlitterNoise",false));material.SetTexture("_MipMap",Ensure("GlitterPalette",true));
            material.SetTexture("_NormalMap",Ensure("GlitterRawNormal",false));material.SetTexture("_MaskAlpha",Ensure("GlitterCutout",false));material.SetTexture("_MainTex",Ensure("GlitterBase",true));
            Apply(material,0);
        }
        public static void Apply(Material material,int preset)
        {
            if(preset<0||preset>2)throw new ArgumentOutOfRangeException("preset");
            material.SetColor("_BaseColor",new Color(.12f,.12f,.18f,1));
            material.SetColor("_SparkleColor",preset==0?new Color(.18f,.7f,1,1):preset==1?new Color(1,.38f,.075f,1):new Color(.65f,.12f,.8f,1));
            material.SetFloat("_Iteration",3);material.SetFloat("_NormalScale",.8f);material.SetFloat("_DepthStep",30);material.SetFloat("_DepthStep_02",65);material.SetFloat("_DepthStep_03",110);
            material.SetFloat("_ShiningSpeed",.15f);material.SetFloat("_ShiningSpeed_02",-.12f);material.SetFloat("_ShiningSpeed_03",.09f);
            material.SetVector("_OffsetSecond",new Vector4(.22f,.38f,0,0));material.SetVector("_OffsetThird",new Vector4(.63f,.12f,0,0));material.SetFloat("_DieValue01",.5f);material.SetFloat("_DieValue02",3);
        }
        static Texture2D Ensure(string kind,bool srgb)
        {
            string path=Folder+"/"+kind+".png";
            if(File.Exists(path))
            {
                var existing=AssetDatabase.LoadAssetAtPath<Texture2D>(path);if(existing==null)throw new IOException("Existing texture preserved but unreadable: "+path);return existing;
            }
            const int size=256;var texture=new Texture2D(size,size,TextureFormat.RGBA32,true,!srgb);
            for(int y=0;y<size;y++)for(int x=0;x<size;x++)
            {
                float u=(x+.5f)/size,v=(y+.5f)/size;Color c;
                if(kind=="GlitterNoise")
                {
                    float a=Mathf.Sin((u*7+v*3)*Mathf.PI*2),b=Mathf.Sin((u*13-v*9)*Mathf.PI*2),d=Mathf.Sin((u*23+v*17)*Mathf.PI*2);float n=Mathf.Clamp01(.56f+.24f*a+.15f*b+.1f*d);c=new Color(n,n,n,1);
                }
                else if(kind=="GlitterPalette")c=Color.Lerp(new Color(.08f,.2f,.85f,1),new Color(.95f,.18f,.35f,1),u*.5f+v*.5f);
                else if(kind=="GlitterRawNormal")c=new Color(.5f+Mathf.Sin(u*Mathf.PI*4)*.16f,.5f+Mathf.Cos(v*Mathf.PI*6)*.13f,1,1);
                else if(kind=="GlitterCutout"){float d=Mathf.Pow(Mathf.Abs(u-.5f)*2,4)+Mathf.Pow(Mathf.Abs(v-.5f)*2,4);float value=d<.8f?1:0;c=new Color(value,value,value,1);}
                else c=new Color(.04f+u*.025f,.03f+v*.02f,.06f,1);
                texture.SetPixel(x,y,c);
            }
            texture.Apply();Directory.CreateDirectory(Folder);File.WriteAllBytes(path,texture.EncodeToPNG());UnityEngine.Object.DestroyImmediate(texture);AssetDatabase.ImportAsset(path,ImportAssetOptions.ForceSynchronousImport);
            var importer=(TextureImporter)AssetImporter.GetAtPath(path);importer.textureType=TextureImporterType.Default;importer.sRGBTexture=srgb;importer.wrapMode=TextureWrapMode.Repeat;importer.mipmapEnabled=true;importer.textureCompression=TextureImporterCompression.Uncompressed;importer.SaveAndReimport();return AssetDatabase.LoadAssetAtPath<Texture2D>(path);
        }
    }
}
