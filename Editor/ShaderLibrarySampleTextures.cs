using System;
using System.IO;
using UnityEditor;
using UnityEngine;

namespace ASEShaderConverter.Editor
{
    // Small original demonstration resources, created through Unity APIs. No reference
    // project textures are copied. Existing textures and material edits are preserved.
    public static class ShaderLibrarySampleTextures
    {
        const string Folder="Assets/ASEShaderLibrary/Shared/OriginalExamples";
        public static void ApplyWater(Material material)
        {
            Bind(material,"_RippleSlope","WaterSlope",false);
            Bind(material,"_CausticTex","WaterCaustic",false);
        }
        public static void Apply(ShaderLibraryEntry entry,Material material)
        {
            if(material.HasProperty("_BaseColor"))material.SetColor("_BaseColor",Palette(entry.category));
            Bind(material,"_EffectMask","CloudMask",false);
            Bind(material,"_DissolveMap","CloudMask",false);
            Bind(material,"_DistortionMap","Distortion",false);
            Bind(material,"_EffectLayer",entry.effect.IndexOf("序列帧",StringComparison.Ordinal)>=0?"Flipbook4x4":"ColorPattern",false,true);
            Bind(material,"_LayerMap","ColorPattern",false,true);
            Bind(material,"_EffectNormal","FineNormal",true);
            if(entry.category=="Hair")Bind(material,"_BaseMap","HairCoverage",false,true);
        }
        static void Bind(Material material,string property,string kind,bool normal,bool srgb=false)
        {
            if(material.HasProperty(property))material.SetTexture(property,Ensure(kind,normal,srgb));
        }
        static Color Palette(string c)
        {
            switch(c)
            {
                case "Skin":return new Color(.72f,.45f,.35f,1);
                case "Hair":return new Color(.12f,.07f,.035f,1);
                case "Fabric":return new Color(.2f,.35f,.55f,1);
                case "Hosiery":return new Color(.08f,.06f,.05f,.9f);
                case "Water":return new Color(.12f,.35f,.45f,1);
                case "Metal":return new Color(.72f,.74f,.78f,1);
                case "Stone":return new Color(.4f,.38f,.32f,1);
                case "Jade":return new Color(.12f,.5f,.28f,1);
                case "VFX":return new Color(1,.25f,.03f,1);
                case "VertexAnimation":return new Color(.2f,.45f,.12f,1);
                default:return Color.white;
            }
        }
        static Texture2D Ensure(string kind,bool normal,bool srgb)
        {
            string path=Folder+"/"+kind+".png";
            if(File.Exists(path))
            {
                var existing=AssetDatabase.LoadAssetAtPath<Texture2D>(path);
                if(existing==null)throw new IOException("Existing sample texture could not be loaded; preserved: "+path);
                return existing;
            }
            const int size=128;var pixels=new Color[size*size];
            for(int y=0;y<size;y++)for(int x=0;x<size;x++)
            {
                float u=(x+.5f)/size,v=(y+.5f)/size;Color color;
                if(kind=="WaterSlope")
                {
                    // Periodic signed slope data around 0.5, not a normal map.
                    float a=(u*7+v*3)*Mathf.PI*2,b=(u*3-v*5)*Mathf.PI*2;
                    color=new Color(.5f+Mathf.Cos(a)*.16f+Mathf.Cos(b)*.09f,.5f+Mathf.Sin(a)*.12f-Mathf.Sin(b)*.1f,.5f+Mathf.Sin(a+b)*.4f,1);
                }
                else if(kind=="WaterCaustic")
                {
                    float a=Mathf.Abs(Mathf.Sin((u*4+v*3)*Mathf.PI*2)),b=Mathf.Abs(Mathf.Sin((u*3-v*4)*Mathf.PI*2));
                    float light=Mathf.Pow(1-Mathf.Min(a,b),9);color=new Color(light,light,light,1);
                }
                else if(kind=="FineNormal")
                {
                    var n=new Vector3(Mathf.Sin(u*Mathf.PI*32)*.18f,Mathf.Sin(v*Mathf.PI*4)*.04f,1).normalized;
                    color=new Color(n.x*.5f+.5f,n.y*.5f+.5f,n.z*.5f+.5f,1);
                }
                else if(kind=="HairCoverage")
                {
                    float strand=Mathf.Pow(Mathf.Abs(Mathf.Sin(u*Mathf.PI*18)),.35f);
                    float edge=Mathf.SmoothStep(0,1,Mathf.Clamp01(Mathf.Min(u,1-u)*12));
                    color=new Color(.65f+strand*.35f,.65f+strand*.35f,.65f+strand*.35f,strand*edge*Mathf.SmoothStep(0,1,v*7));
                }
                else if(kind=="Distortion")color=new Color(Mathf.PerlinNoise(u*4,v*4),Mathf.PerlinNoise(u*4+17,v*4+9),0,1);
                else if(kind=="ColorPattern")color=Color.Lerp(new Color(.05f,.15f,.8f,1),new Color(1,.55f,.05f,1),Mathf.Clamp01(u*.6f+v*.4f+Mathf.Sin(u*32)*.12f));
                else if(kind=="Flipbook4x4")
                {
                    int column=x/32,row=y/32;float frame=(row*4+column)/15f;
                    float dx=(x%32+.5f)/32-.5f,dy=(y%32+.5f)/32-.5f;
                    float radius=.08f+frame*.38f,ring=1-Mathf.SmoothStep(0,1,Mathf.InverseLerp(.015f,.08f,Mathf.Abs(Mathf.Sqrt(dx*dx+dy*dy)-radius)));
                    color=Color.Lerp(new Color(.05f,.1f,.2f,1),new Color(1,.2f+frame*.6f,.05f,1),ring);
                }
                else
                {
                    float value=Mathf.Clamp01(Mathf.PerlinNoise(u*5+3,v*5+7)*.72f+Mathf.PerlinNoise(u*13+11,v*13+5)*.28f);
                    color=new Color(value,value,value,1);
                }
                pixels[y*size+x]=color;
            }
            var texture=new Texture2D(size,size,TextureFormat.RGBA32,false,!srgb);
            try{texture.SetPixels(pixels);texture.Apply();Directory.CreateDirectory(Folder);File.WriteAllBytes(path,texture.EncodeToPNG());}
            finally{UnityEngine.Object.DestroyImmediate(texture);}
            AssetDatabase.ImportAsset(path,ImportAssetOptions.ForceSynchronousImport);
            var importer=(TextureImporter)AssetImporter.GetAtPath(path);importer.textureType=normal?TextureImporterType.NormalMap:TextureImporterType.Default;
            importer.sRGBTexture=srgb;importer.wrapMode=TextureWrapMode.Repeat;importer.mipmapEnabled=true;importer.alphaSource=TextureImporterAlphaSource.FromInput;importer.SaveAndReimport();
            return AssetDatabase.LoadAssetAtPath<Texture2D>(path);
        }
    }
}
