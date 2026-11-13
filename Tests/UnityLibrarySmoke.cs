using System;
using System.IO;
using System.Linq;
using System.Collections.Generic;
using ASEShaderConverter;
using ASEShaderConverter.Editor;
using UnityEditor;
using UnityEngine;

// Isolated integration test: actual catalog API, window, per-pipeline import and Unity compilation.
public static class UnityLibrarySmoke
{
    [Serializable] public sealed class Row {public string id,path,error;public bool compiled;}
    [Serializable] public sealed class Evidence {public string pipeline;public bool success,windowCreated,apiLoaded,pathEscapeRejected,pipelineMismatchRejected;public List<Row> rows=new List<Row>();}
    static ShaderLibraryEntry[] entries;static Evidence evidence;static int cursor;static bool localOnly;
    public static void RunLocal(){localOnly=true;Run();}
    static void Isolated(){if(Path.GetFullPath(".").IndexOf(".validation",StringComparison.OrdinalIgnoreCase)<0)throw new Exception("Isolated workspace project required.");}
    public static void Guards()
    {
        try
        {
            Isolated();bool rejected=false;
            try{ShaderLibraryAssets.VerifiedPath(new ShaderLibraryEntry{path="Samples~/ShaderLibrary/../../Editor/Templates/Outside.shader"});}catch(ArgumentException){rejected=true;}
            if(!rejected)throw new Exception("Library traversal must be rejected before file access.");
            var catalog=ShaderLibraryAssets.Load();var entry=catalog.entries[0];string originalHash=entry.sha256;bool mismatch=false;
            entry.sha256=new string('0',64);try{ShaderLibraryAssets.VerifiedPath(entry);}catch(InvalidDataException){mismatch=true;}finally{entry.sha256=originalHash;}
            if(!mismatch)throw new Exception("Checksum mismatch must be rejected.");
            var window=EditorWindow.GetWindow<ShaderLibraryWindow>();window.Close();
            File.WriteAllText("LibraryBuildEvidence/library-guards.json",JsonUtility.ToJson(new Evidence{success=true,windowCreated=true,pathEscapeRejected=true,apiLoaded=catalog.entries.Count==63},true));
            Debug.Log("ASE_LIBRARY_GUARDS_PASS");EditorApplication.Exit(0);
        }catch(Exception e){Debug.LogException(e);EditorApplication.Exit(1);}
    }
    public static void ImportWater()
    {
        try{Isolated();string path=ShaderLibraryAssets.Import("original-BuiltIn-DeepWater");File.WriteAllText("LibraryBuildEvidence/water-import-path.txt",path);Debug.Log("ASE_LIBRARY_WATER_IMPORTED "+path);EditorApplication.Exit(0);}
        catch(Exception e){Debug.LogException(e);EditorApplication.Exit(1);}
    }
    public static void CheckWaterSupport()
    {
        try
        {
            Isolated();var type=AppDomain.CurrentDomain.GetAssemblies().Select(a=>a.GetType("ASEShaderWater.Editor.DepthWaterAuthoring")).FirstOrDefault(t=>t!=null);
            if(type==null)throw new Exception("Water authoring script did not compile.");
            type.GetMethod("CreateFromMenu").Invoke(null,null);
            var material=AssetDatabase.LoadAssetAtPath<Material>("Assets/Shaders/DeepWater/DeepWater.mat");
            var prefab=AssetDatabase.LoadAssetAtPath<GameObject>("Assets/Shaders/DeepWater/DeepWater.prefab");
            bool success=material!=null&&prefab!=null&&material.GetTexture("_RippleSlope")!=null&&material.GetTexture("_CausticTex")!=null&&prefab.GetComponents<Component>().Any(c=>c!=null&&c.GetType().Name=="DepthWaterSurface")&&!ShaderUtil.ShaderHasError(material.shader);
            File.WriteAllText("LibraryBuildEvidence/water-support.json",JsonUtility.ToJson(new Evidence{pipeline="BuiltIn",success=success},true));
            Debug.Log("ASE_LIBRARY_WATER_SUPPORT "+success);EditorApplication.Exit(success?0:1);
        }catch(Exception e){Debug.LogException(e);EditorApplication.Exit(1);}
    }
    public static void Run()
    {
        try
        {
            Isolated();
            var api=ShaderConverterApi.Execute(new ShaderAgentRequest{operation="library"});
            if(!api.success)throw new Exception(api.error);
            evidence=new Evidence{pipeline=AseEditorBridge.Probe().activePipeline,apiLoaded=api.shaderLibrary.entries.Count>0};
            Shader.globalRenderPipeline=evidence.pipeline=="HDRP"?"HDRenderPipeline":evidence.pipeline=="URP"?"UniversalPipeline":"";
            var window=EditorWindow.GetWindow<ShaderLibraryWindow>();evidence.windowCreated=window!=null;window.Close();
            try{ShaderLibraryAssets.VerifiedPath(new ShaderLibraryEntry{path="Samples~/ShaderLibrary/../../../package.json"});}catch(ArgumentException){evidence.pathEscapeRejected=true;}
            var other=api.shaderLibrary.entries.First(e=>e.pipeline!=evidence.pipeline);
            try{ShaderLibraryAssets.Import(other.id);}catch(InvalidOperationException){evidence.pipelineMismatchRejected=true;}
            entries=api.shaderLibrary.entries.Where(e=>e.pipeline==evidence.pipeline&&e.id!="original-BuiltIn-DeepWater"&&(!localOnly||e.origin=="LocalGraphAdaptation")).ToArray();
            cursor=0;EditorApplication.update+=Tick;
        }catch(Exception e){Debug.LogException(e);EditorApplication.Exit(1);}
    }
    static void Tick()
    {
        if(EditorApplication.isCompiling||EditorApplication.isUpdating)return;
        try
        {
            if(cursor>=entries.Length)
            {
                evidence.success=evidence.apiLoaded&&evidence.windowCreated&&evidence.pathEscapeRejected&&evidence.pipelineMismatchRejected&&evidence.rows.All(r=>r.compiled);
                Directory.CreateDirectory("LibraryBuildEvidence");File.WriteAllText("LibraryBuildEvidence/"+(localOnly?"import-local-smoke.json":"import-smoke.json"),JsonUtility.ToJson(evidence,true));
                Debug.Log("ASE_LIBRARY_IMPORT_SMOKE "+evidence.pipeline+" "+evidence.success+" "+evidence.rows.Count);EditorApplication.update-=Tick;EditorApplication.Exit(evidence.success?0:1);return;
            }
            var entry=entries[cursor++];var row=new Row{id=entry.id};
            try
            {
                row.path=ShaderLibraryAssets.Import(entry.id);var shader=AssetDatabase.LoadAssetAtPath<Shader>(row.path);
                if(shader==null)throw new Exception("Imported shader missing.");
                var material=new Material(shader);try{row.compiled=material.SetPass(0)&&!ShaderUtil.ShaderHasError(shader);}finally{UnityEngine.Object.DestroyImmediate(material);}
                if(!row.compiled)row.error=string.Join(" | ",ShaderUtil.GetShaderMessages(shader).Select(m=>m.message).ToArray());
            }catch(Exception ex){row.error=ex.ToString();}
            evidence.rows.Add(row);Debug.Log("ASE_LIBRARY_IMPORT "+row.id+" "+row.compiled);
        }catch(Exception e){Debug.LogException(e);EditorApplication.update-=Tick;EditorApplication.Exit(1);}
    }
}
