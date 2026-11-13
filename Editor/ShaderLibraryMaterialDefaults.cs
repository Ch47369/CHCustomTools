using System;
using System.Linq;
using UnityEditor;
using UnityEngine;

namespace ASEShaderConverter.Editor
{
    public static class ShaderLibraryMaterialDefaults
    {
        // Initialize only newly created materials. Reused assets keep all user changes.
        public static void Initialize(ShaderLibraryEntry entry,Material material)
        {
            if(entry.origin=="ReviewedMaterialAdaptation")ShowcaseMaterialPresets.Initialize(material);
            if(entry.origin=="ReviewedArticleAdaptation" && material.HasProperty("_JADE_SCENE_LIGHT"))
            {
                material.SetFloat("_JADE_SCENE_LIGHT",1);
                material.EnableKeyword("_JADE_SCENE_LIGHT_ON");
            }
            if(entry.origin=="OriginalValidatedWater")
            {
                ShaderLibrarySampleTextures.ApplyWater(material);
                foreach(string feature in new[]{"WAVES","RIPPLES","FRESNEL","DEPTH","FOAM","CAUSTICS","SCATTER","REFRACTION"})
                {
                    string property="_WATER_"+feature;
                    if(material.HasProperty(property)){material.SetFloat(property,1);material.EnableKeyword(property+"_ON");}
                }
            }
            if(entry.origin=="OriginalFoundation"||entry.origin=="OriginalEffect")
            {
                ShaderLibrarySampleTextures.Apply(entry,material);
                if(entry.category=="Hair")
                {
                    if(material.HasProperty("_AlphaCutoffEnable"))material.SetFloat("_AlphaCutoffEnable",1);
                    if(material.HasProperty("_AlphaClip"))material.SetFloat("_AlphaClip",1);
                }
            }
            // Use the installed pipeline's public ShaderGUI validation, just as the
            // Inspector does. This sets blend factors, keywords and enabled passes.
            string editorName=ShaderUtil.GetCurrentCustomEditor(material.shader);
            if(string.IsNullOrEmpty(editorName))return;
            Type type=AppDomain.CurrentDomain.GetAssemblies().Select(a=>a.GetType(editorName)??a.GetType("UnityEditor."+editorName)).FirstOrDefault(t=>t!=null&&typeof(ShaderGUI).IsAssignableFrom(t));
            if(type==null)throw new InvalidOperationException("Required material inspector is unavailable: "+editorName);
            var gui=(ShaderGUI)Activator.CreateInstance(type,true);gui.ValidateMaterial(material);
        }
    }
}
