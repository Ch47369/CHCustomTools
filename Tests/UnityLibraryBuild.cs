// Run only in workspace .validation projects; never imports or executes reference project code.
using System;
using System.IO;
using System.Linq;
using System.Collections.Generic;
using ASEShaderConverter;
using ASEShaderConverter.Editor;
using UnityEditor;
using UnityEngine;

public static class UnityLibraryBuild
{
    [Serializable] public sealed class Job { public string id, output, planPath; }
    [Serializable] public sealed class Jobs { public Job[] jobs; }
    [Serializable] public sealed class Result { public string id, output; public ShaderAgentResponse response; }
    [Serializable] public sealed class Results { public string pipeline; public bool completed; public List<Result> rows=new List<Result>(); }
    static string root, output; static Jobs jobs; static int cursor; static Results results;
    static void Save(string name,object data) {File.WriteAllText(Path.Combine(output,name),JsonUtility.ToJson(data,true));}
    public static void Describe()
    {
        try
        {
            Setup();var env=ShaderConverterApi.Execute(new ShaderAgentRequest{operation="probe"});Save("probe.json",env);
            if(!env.success)throw new Exception(env.error);
            string[] types={"SamplerNode","TexturePropertyNode","ViewDirInputsCoordNode","WorldPosInputsNode","NormalVertexDataNode","WorldNormalVector","ObjectToWorldMatrix","NormalBlendNode","BlendNormalsNode","FresnelNode","TextureCoordinatesNode","DynamicAppendNode","SimpleTimeNode","RotatorNode","PannerNode","SimpleMultiplyOpNode","PowerNode","DotProductOpNode","LerpOp","ConditionalIfNode","UnpackScaleNormalNode","PosVertexDataNode","CameraPositionNode","VertexColorNode","RangedFloatNode","RGBToHSVNode","HSVToRGBNode"};
            // Some ASE names vary; report individual descriptions without suppressing successful ones.
            foreach(var t in env.environment.templates.Where(t=>t.ready&&t.pipeline==env.environment.activePipeline))
            {
                var d=ShaderConverterApi.Execute(new ShaderAgentRequest{operation="describe",templateGuid=t.guid});Save("template-"+t.guid+".json",d);
            }
            var guid=env.environment.templates.First(t=>t.ready&&t.pipeline==env.environment.activePipeline).guid;
            foreach(string type in types)Save("node-"+type+".json",ShaderConverterApi.Execute(new ShaderAgentRequest{operation="describe",templateGuid=guid,nodeTypes=new[]{type}}));
            Debug.Log("ASE_LIBRARY_DESCRIBE_PASS");EditorApplication.Exit(0);
        }catch(Exception e){Debug.LogException(e);EditorApplication.Exit(1);}
    }
    static void Setup()
    {
        root=Path.GetFullPath(".");
        if(root.IndexOf(Path.DirectorySeparatorChar+".validation"+Path.DirectorySeparatorChar,StringComparison.OrdinalIgnoreCase)<0)throw new Exception("Isolation required");
        output=Path.GetFullPath("LibraryBuildEvidence");Directory.CreateDirectory(output);
        Shader.globalRenderPipeline=AseEditorBridge.Probe().activePipeline=="HDRP"?"HDRenderPipeline":AseEditorBridge.Probe().activePipeline=="URP"?"UniversalPipeline":"";
    }
    public static void Run()
    {
        try
        {
            Setup();var env=ShaderConverterApi.Execute(new ShaderAgentRequest{operation="probe"});Save("probe.json",env);if(!env.success)throw new Exception(env.error);
            string[] args=Environment.GetCommandLineArgs();int at=Array.IndexOf(args,"-libraryJobs");if(at<0)throw new Exception("Missing -libraryJobs");
            jobs=JsonUtility.FromJson<Jobs>(File.ReadAllText(args[at+1]));results=new Results{pipeline=env.environment.activePipeline};
            foreach(var job in jobs.jobs)Directory.CreateDirectory(Path.GetDirectoryName(job.output));
            AssetDatabase.Refresh(ImportAssetOptions.ForceSynchronousImport);
            cursor=0;EditorApplication.update+=Tick;
        }catch(Exception e){Debug.LogException(e);EditorApplication.Exit(1);}
    }
    static void Tick()
    {
        if(EditorApplication.isCompiling||EditorApplication.isUpdating)return;
        try
        {
            if(cursor>=jobs.jobs.Length){results.completed=true;Save("results.json",results);Debug.Log("ASE_LIBRARY_BUILD_COMPLETE "+results.pipeline);EditorApplication.update-=Tick;EditorApplication.Exit(0);return;}
            var job=jobs.jobs[cursor++];var plan=JsonUtility.FromJson<ShaderGraphPlan>(File.ReadAllText(job.planPath));
            var description=ShaderConverterApi.Execute(new ShaderAgentRequest{operation="describe",templateGuid=plan.templateGuid,nodeTypes=plan.nodes.Select(n=>n.type).Distinct().ToArray()});Save(job.id+"-describe.json",description);
            ShaderAgentResponse response;
            if(!description.success) response=description;
            else response=ShaderConverterApi.Execute(new ShaderAgentRequest{operation="generatePlan",plan=plan,outputPath=AssetDatabase.GenerateUniqueAssetPath(job.output)});
            results.rows.Add(new Result{id=job.id,output=response.report==null?"":response.report.outputPath,response=response});Save("results.json",results);
            Debug.Log("ASE_LIBRARY_JOB "+job.id+" "+response.success+" "+response.error);
        }catch(Exception e){Debug.LogException(e);EditorApplication.update-=Tick;EditorApplication.Exit(1);}
    }
}
