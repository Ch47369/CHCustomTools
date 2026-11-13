using System;
using System.IO;
using System.Linq;
using System.Collections.Generic;
using ASEShaderConverter;
using ASEShaderConverter.Editor;
using UnityEditor;
using UnityEngine;

// Actual public bulk entry, preserving edits, with cancellation and guard checks.
public static class UnityLibraryBatchSmoke
{
    [Serializable] public sealed class Evidence
    {
        public string pipeline,error;public bool success,windowCreated,apiLoaded,checksumRejected,pathRejected,pipelineRejected,materialEditsPreserved,cancelled,originalExamplesBound,materialStatesInitialized;
        public int sampleTextureBindings,transparentMaterialChecks,hairClipChecks;
        public int waterKeywordChecks,waterTextureBindings;
        public int correspondenceContractCount,mappedFamilyCount;
        public List<ShaderLibraryBatch.Item> rows=new List<ShaderLibraryBatch.Item>();
    }
    static Evidence result;static ShaderLibraryEntry[] entries;static int state;static Material edited;static Color saved;
    public static void Run()
    {
        try
        {
            if(Path.GetFullPath(".").IndexOf(Path.DirectorySeparatorChar+".validation"+Path.DirectorySeparatorChar,StringComparison.OrdinalIgnoreCase)<0)throw new Exception("Isolation required");
            var api=ShaderConverterApi.Execute(new ShaderAgentRequest{operation="probe"});if(!api.success)throw new Exception(api.error);
            result=new Evidence{pipeline=api.environment.activePipeline};Shader.globalRenderPipeline=result.pipeline=="HDRP"?"HDRenderPipeline":result.pipeline=="URP"?"UniversalPipeline":"";
            var catalog=ShaderConverterApi.Execute(new ShaderAgentRequest{operation="library"});result.apiLoaded=catalog.success;
            result.correspondenceContractCount=catalog.shaderLibrary.familyContracts.Count;
            result.mappedFamilyCount=catalog.shaderLibrary.entries.GroupBy(ShaderLibraryQuery.Family).Count(g=>ShaderLibraryQuery.HasThreeMappedTargets(catalog.shaderLibrary.familyContracts.FirstOrDefault(c=>c.familyId==g.Key),g));
            string[] arguments=Environment.GetCommandLineArgs();
            int familyArgument=Array.IndexOf(arguments,"-expectedFamilies"),mappedArgument=Array.IndexOf(arguments,"-expectedMappedFamilies");
            int expectedFamilies=familyArgument<0?105:int.Parse(arguments[familyArgument+1]),expectedMapped=mappedArgument<0?60:int.Parse(arguments[mappedArgument+1]);
            if(result.correspondenceContractCount!=expectedFamilies||result.mappedFamilyCount!=expectedMapped)throw new Exception("Same-source pipeline contracts were not loaded by the public API");
            entries=catalog.shaderLibrary.entries.Where(e=>e.pipeline==result.pipeline).ToArray();
            var window=EditorWindow.GetWindow<ShaderLibraryWindow>();result.windowCreated=window!=null;window.Close();
            try{ShaderLibraryAssets.VerifiedPath(new ShaderLibraryEntry{path="Samples~/ShaderLibrary/../../README.shader"});}catch(ArgumentException){result.pathRejected=true;}
            var first=entries[0];string original=first.sha256;
            try{first.sha256=new string('0',64);ShaderLibraryAssets.VerifiedPath(first);}catch(InvalidDataException){result.checksumRejected=true;}finally{first.sha256=original;}
            var wrong=catalog.shaderLibrary.entries.First(e=>e.pipeline!=result.pipeline);
            try{ShaderLibraryBatch.Start(new[]{wrong.id});}catch(ArgumentException){result.pipelineRejected=true;}
            ShaderLibraryBatch.Start(entries.Select(e=>e.id).ToArray());state=0;EditorApplication.update+=Tick;
        }catch(Exception e){Fail(e);}
    }
    static void Tick()
    {
        if(EditorApplication.isCompiling||EditorApplication.isUpdating||ShaderLibraryBatch.IsRunning)return;
        try
        {
            if(state==0)
            {
                result.originalExamplesBound=true;result.materialStatesInitialized=true;
                var batch=ShaderLibraryBatch.LastResult;
                if(batch==null||!batch.completed||batch.cancelled||batch.items.Count!=entries.Length||batch.items.Any(i=>!i.success))throw new Exception("Public batch entry did not finish all requested items successfully.");
                foreach(var entry in entries)
                {
                    var item=ShaderLibraryBatch.Generate(entry.id);result.rows.Add(item);
                    if(!item.success)throw new Exception(entry.id+": "+item.error);
                    var material=AssetDatabase.LoadAssetAtPath<Material>(item.materialPath);
                    if(material==null)throw new Exception("Material asset missing: "+entry.id);
                    int pass=new[]{"ForwardOnly","Forward","Forward Unlit","ForwardLit","ForwardBase","Unlit","UI"}.Select(material.FindPass).Where(i=>i>=0).DefaultIfEmpty(-1).First();
                    if(pass<0)throw new Exception("Material forward pass not identified: "+entry.id);
                    if(!material.GetShaderPassEnabled(material.GetPassName(pass)))throw new Exception("Material forward pass disabled: "+entry.id+" "+material.GetPassName(pass));
                    if(!material.SetPass(pass)||ShaderUtil.ShaderHasError(material.shader))throw new Exception("Material forward pass compilation failed: "+entry.id+" "+material.GetPassName(pass));
                    if(entry.origin=="OriginalValidatedWater")
                    {
                        foreach(string f in new[]{"WAVES","RIPPLES","FRESNEL","DEPTH","FOAM","CAUSTICS","SCATTER","REFRACTION"})
                        {
                            string p="_WATER_"+f;
                            if(!material.HasProperty(p)||material.GetFloat(p)<.5f||!material.IsKeywordEnabled(p+"_ON"))throw new Exception("Water feature default missing: "+p);
                            result.waterKeywordChecks++;
                        }
                        foreach(string p in new[]{"_RippleSlope","_CausticTex"})
                        {
                            var t=material.GetTexture(p);var importer=AssetImporter.GetAtPath(AssetDatabase.GetAssetPath(t)) as TextureImporter;
                            if(t==null||importer==null||importer.sRGBTexture||!importer.mipmapEnabled||importer.textureType!=TextureImporterType.Default)throw new Exception("Water linear example data missing: "+p);
                            result.waterTextureBindings++;
                        }
                    }
                    if(entry.origin=="OriginalFoundation"||entry.origin=="OriginalEffect")
                    {
                        foreach(string property in new[]{"_EffectMask","_DissolveMap","_DistortionMap","_EffectLayer","_LayerMap","_EffectNormal"})
                        {
                            if(!material.HasProperty(property))continue;
                            var texture=material.GetTexture(property);string path=AssetDatabase.GetAssetPath(texture);
                            if(texture==null||!path.StartsWith("Assets/ASEShaderLibrary/Shared/OriginalExamples/",StringComparison.Ordinal))throw new Exception("Original example texture not bound: "+entry.id+" "+property);
                            var importer=(TextureImporter)AssetImporter.GetAtPath(path);
                            if(property=="_EffectNormal"&&importer.textureType!=TextureImporterType.NormalMap)throw new Exception("Normal example imported as color");
                            if((property=="_EffectMask"||property=="_DissolveMap"||property=="_DistortionMap")&&importer.sRGBTexture)throw new Exception("Linear example mask imported as sRGB");
                            result.sampleTextureBindings++;
                        }
                        if(entry.category=="Hair"&&result.pipeline!="BuiltIn")
                        {
                            string clip=result.pipeline=="HDRP"?"_AlphaCutoffEnable":"_AlphaClip";
                            if(!material.HasProperty(clip)||material.GetFloat(clip)<.5f||!material.IsKeywordEnabled("_ALPHATEST_ON"))throw new Exception("Hair clipping was not initialized: "+entry.id);
                            result.hairClipChecks++;
                        }
                    }
                    if(result.pipeline=="HDRP"&&material.HasProperty("_SurfaceType")&&material.GetFloat("_SurfaceType")>.5f)
                    {
                        if(!material.IsKeywordEnabled("_SURFACE_TYPE_TRANSPARENT")||material.GetFloat("_DstBlend")==0)throw new Exception("HDRP transparent material blend/keyword not initialized: "+entry.id);
                        result.transparentMaterialChecks++;
                    }
                }
                var row=result.rows.First(r=>{var m=AssetDatabase.LoadAssetAtPath<Material>(r.materialPath);return m.HasProperty("_BaseColor");});
                edited=AssetDatabase.LoadAssetAtPath<Material>(row.materialPath);saved=edited.GetColor("_BaseColor");edited.SetColor("_BaseColor",new Color(.123f,.234f,.345f,.456f));
                var again=ShaderLibraryBatch.Generate(row.id);result.materialEditsPreserved=again.success&&again.materialReused&&again.materialPath==row.materialPath&&edited.GetColor("_BaseColor")==new Color(.123f,.234f,.345f,.456f);
                edited.SetColor("_BaseColor",saved);AssetDatabase.SaveAssets();
                ShaderLibraryBatch.Start(new[]{entries[0].id});ShaderLibraryBatch.Cancel();result.cancelled=!ShaderLibraryBatch.IsRunning;state=1;return;
            }
            result.success=result.apiLoaded&&result.windowCreated&&result.pathRejected&&result.checksumRejected&&result.pipelineRejected&&result.materialEditsPreserved&&result.cancelled&&result.rows.Count==entries.Length;
            Directory.CreateDirectory("LibraryBuildEvidence");File.WriteAllText("LibraryBuildEvidence/batch-smoke-031.json",JsonUtility.ToJson(result,true));
            EditorApplication.update-=Tick;Debug.Log("ASE_LIBRARY_BATCH_SMOKE "+result.pipeline+" "+result.success+" "+result.rows.Count);EditorApplication.Exit(result.success?0:1);
        }catch(Exception e){Fail(e);}
    }
    static void Fail(Exception e)
    {
        Debug.LogException(e);if(result!=null){result.error=e.ToString();Directory.CreateDirectory("LibraryBuildEvidence");File.WriteAllText("LibraryBuildEvidence/batch-smoke-031.json",JsonUtility.ToJson(result,true));}
        EditorApplication.update-=Tick;EditorApplication.Exit(1);
    }
}
