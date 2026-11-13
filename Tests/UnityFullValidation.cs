// Copy only into an isolated Unity project's Assets/Editor. Inputs stay outside user projects.
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Security.Cryptography;
using UnityEditor;
using UnityEngine;
using ASEShaderConverter;
using ASEShaderConverter.Editor;
using AmplifyShaderEditor;

public static class UnityFullValidation
{
    [Serializable] public sealed class Input { public string id, path, sha256, group; }
    [Serializable] public sealed class Inventory { public Input[] inputs; }
    [Serializable] public sealed class Row
    {
        public string id, group, sha256, pipeline, status, error="", outputPath="";
        public ShaderAgentResponse analysis, generation;
        public bool sourceHashMatched, sourceUnchanged, graphLoaded, graphRoundTrip, shaderCompiled, fixtureCompared;
        public int nodes, passes, fixtureCases;
        public float fixtureMaxError;
        public List<string> messages=new List<string>();
    }
    [Serializable] public sealed class Results
    {
        public string runId, pipeline, unityVersion, aseVersion, finishedUtc, harnessSha256, inventorySha256;
        public bool completed;
        public List<Row> rows=new List<Row>();
    }
    static string output, pipeline, runId;
    static Results results;
    static Input[] inputs;
    static int cursor;
    static string Hash(string path) { using(var h=SHA256.Create()) return BitConverter.ToString(h.ComputeHash(File.ReadAllBytes(path))).Replace("-", "").ToLowerInvariant(); }
    static void Save(string name,object value)
    {
        string path=Path.Combine(output,name),temp=path+".tmp";
        File.WriteAllText(temp,JsonUtility.ToJson(value,true));
        if(File.Exists(path))File.Replace(temp,path,null);else File.Move(temp,path);
    }
    public static void Run()
    {
        try
        {
            string project=Path.GetFullPath(".");
            if(project.IndexOf(Path.DirectorySeparatorChar+".validation"+Path.DirectorySeparatorChar,StringComparison.OrdinalIgnoreCase)<0) throw new Exception("Use workspace .validation projects only.");
            string[] args=Environment.GetCommandLineArgs(); int arg=Array.IndexOf(args,"-validationInventory");
            if(arg<0) throw new Exception("Missing inventory argument");
            var inventory=JsonUtility.FromJson<Inventory>(File.ReadAllText(args[arg+1]));
            runId=DateTime.UtcNow.ToString("yyyyMMdd-HHmmss")+"-"+Guid.NewGuid().ToString("N").Substring(0,6);
            output=Path.GetFullPath(Path.Combine("ValidationEvidence",runId)); Directory.CreateDirectory(output);
            var probe=ShaderConverterApi.Execute(new ShaderAgentRequest {operation="probe"}); Save("probe.json",probe);
            if(!probe.success) throw new Exception("Probe: "+probe.error+" "+string.Join(";",probe.environment.errors.ToArray()));
            pipeline=probe.environment.activePipeline;
            Shader.globalRenderPipeline=pipeline=="URP"?"UniversalPipeline":pipeline=="HDRP"?"HDRenderPipeline":"";
            results=new Results {runId=runId,pipeline=pipeline,unityVersion=Application.unityVersion,aseVersion=probe.environment.aseVersion,harnessSha256=Hash("Assets/Editor/UnityFullValidation.cs"),inventorySha256=Hash(args[arg+1])};
            inputs=inventory.inputs;cursor=0;EditorApplication.update+=Tick;
        }
        catch(Exception e) {File.WriteAllText("full-validation-error.txt",e.ToString());Debug.LogException(e);EditorApplication.Exit(1);}
    }
    static void Tick()
    {
        if(EditorApplication.isCompiling||EditorApplication.isUpdating)return;
        try
        {
            if(cursor<inputs.Length)
            {
                Input input=inputs[cursor++];
                var row=new Row {id=input.id,group=input.group,sha256=input.sha256,pipeline=pipeline};
                results.rows.Add(row);
                try
                {
                    row.sourceHashMatched=Hash(input.path)==input.sha256;
                    if(!row.sourceHashMatched) throw new Exception("Input hash mismatch");
                    row.analysis=ShaderConverterApi.Execute(new ShaderAgentRequest {operation="analyze",sourcePath=input.path,options=new ShaderConversionOptions {targetPipeline=pipeline}});
                    if(row.analysis.report==null) throw new Exception(row.analysis.error);
                    row.status=row.analysis.report.status;
                    if(row.analysis.report.existingAseGraph)
                    {
                        if(pipeline=="BuiltIn" && input.group=="UserReference") Migrate(input,row);
                        else row.messages.Add("Existing ASE graph needs its own pipeline/template migration; automatic conversion was not attempted.");
                    }
                    else if(row.analysis.success)
                    {
                        var plan=row.analysis.analysis.plan;
                        string guid=string.IsNullOrEmpty(plan.templateGuid)?(pipeline=="URP"?AseEditorBridge.UrpUnlitGuid:pipeline=="HDRP"?AseEditorBridge.HdrpUnlitGuid:AseEditorBridge.BuiltInUnlitGuid):plan.templateGuid;
                        var description=ShaderConverterApi.Execute(new ShaderAgentRequest {operation="describe",templateGuid=guid,nodeTypes=plan.nodes.Select(n=>n.type).Distinct().ToArray()});
                        Save("describe-"+results.rows.Count+".json",description);
                        if(!description.success) throw new Exception("Describe failed: "+description.error);
                        string name=Path.GetFileNameWithoutExtension(input.path);
                        Directory.CreateDirectory("Assets/FullValidation/"+runId);
                        row.outputPath=AssetDatabase.GenerateUniqueAssetPath("Assets/FullValidation/"+runId+"/"+results.rows.Count+"_"+name+"_ASE.shader");
                        row.generation=ShaderConverterApi.Execute(new ShaderAgentRequest {operation="generate",sourcePath=input.path,outputPath=row.outputPath,options=new ShaderConversionOptions {targetPipeline=pipeline}});
                        if(row.generation.report!=null) {row.status=row.generation.report.status;row.graphRoundTrip=row.generation.report.aseRoundTripPassed;row.shaderCompiled=row.generation.report.shaderCompiled;row.nodes=row.generation.report.nativeNodeCount;}
                        if(row.generation.success && input.group=="PublicCorpus") Compare(input,row);
                    }
                }
                catch(Exception e) {row.error=e.ToString();row.status=row.analysis!=null&&row.analysis.report!=null&&row.analysis.report.existingAseGraph?"MigrationFailed":"ValidationFailed";}
                finally {row.sourceUnchanged=File.Exists(input.path)&&Hash(input.path)==input.sha256;}
                if(cursor%50==0)Debug.Log("ASE_FULL_VALIDATION_PROGRESS: "+pipeline+" "+cursor+"/"+inputs.Length);
                return;
            }
            EditorApplication.update-=Tick;
            results.completed=true;results.finishedUtc=DateTime.UtcNow.ToString("O");Save("results.json",results);
            File.WriteAllText("full-validation-latest.txt",output);
            Debug.Log("ASE_FULL_VALIDATION_COMPLETE: "+pipeline+" rows="+results.rows.Count+" evidence="+output);
            EditorApplication.Exit(0);
        }
        catch(Exception e) {EditorApplication.update-=Tick;File.WriteAllText("full-validation-error.txt",e.ToString());Debug.LogException(e);EditorApplication.Exit(1);}
    }
    static string[] Edges(ParentGraph graph)
    {
        var edges=new List<string>();
        foreach(var node in graph.AllNodes) foreach(var port in node.InputPorts) foreach(var edge in port.ExternalReferences)
        {
            var producer=graph.GetNode(edge.NodeId);
            // ASE Get Local Var uses a one-way dummy input for loop detection.
            // Validate the real public reference instead of requiring a reverse wire.
            var getter=node as GetLocalVarNode;
            if(getter!=null && !port.Visible)
            {
                if(getter.HasMissingReference || getter.CurrentSelected==null || getter.CurrentSelected!=producer || getter.ReferencedNodeId!=edge.NodeId || edge.PortId!=0)
                    throw new Exception("Lost local variable reference: "+node.UniqueId+">"+edge.NodeId);
                edges.Add("reference:"+edge.NodeId+">"+node.UniqueId);
                continue;
            }
            if(producer==null || producer.GetOutputPortByUniqueId(edge.PortId)==null || !producer.GetOutputPortByUniqueId(edge.PortId).ExternalReferences.Any(r=>r.NodeId==node.UniqueId&&r.PortId==port.PortId)) throw new Exception("Lost reverse connection: "+edge.NodeId+":"+edge.PortId+">"+node.UniqueId+":"+port.PortId);
            edges.Add(edge.NodeId+":"+edge.PortId+">"+node.UniqueId+":"+port.PortId);
        }
        foreach(var getter in graph.AllNodes.OfType<GetLocalVarNode>())
            if(getter.HasMissingReference || getter.CurrentSelected==null || !edges.Contains("reference:"+getter.ReferencedNodeId+">"+getter.UniqueId))throw new Exception("Missing local variable reference: "+getter.UniqueId);
        foreach(var node in graph.AllNodes)foreach(var port in node.OutputPorts)foreach(var edge in port.ExternalReferences)
        {
            var consumer=graph.GetNode(edge.NodeId);
            if(consumer==null || !consumer.InputPorts.Any(p=>p.PortId==edge.PortId && p.ExternalReferences.Any(r=>r.NodeId==node.UniqueId&&r.PortId==port.PortId)))throw new Exception("Lost forward connection: "+node.UniqueId+":"+port.PortId+">"+edge.NodeId+":"+edge.PortId);
        }
        return edges.OrderBy(x=>x,StringComparer.Ordinal).ToArray();
    }
    static Dictionary<int,string> Settings(ParentGraph graph)
    {
        var data=new Dictionary<int,string>();
        foreach(var node in graph.AllNodes) {string settings="",connections="";node.WriteToString(ref settings,ref connections);data.Add(node.UniqueId,settings);}
        return data;
    }
    static void Migrate(Input input,Row row)
    {
        string directory="Assets/FullValidation/"+runId+"/References";Directory.CreateDirectory(directory);
        string copy=directory+"/"+Path.GetFileName(input.path);File.Copy(input.path,copy,false);
        AssetDatabase.ImportAsset(copy,ImportAssetOptions.ForceSynchronousImport|ImportAssetOptions.ForceUpdate);
        AmplifyShaderEditorWindow window=null; bool shown=false;var previous=UIUtils.CurrentWindow;
        var saveField=typeof(IOUtils).GetField("UseSaveThread",BindingFlags.Static|BindingFlags.Public|BindingFlags.NonPublic);
        if(saveField==null || saveField.FieldType!=typeof(bool)) throw new Exception("ASE synchronous save capability missing");
        bool saveThread=(bool)saveField.GetValue(null);
        try
        {
            window=AmplifyShaderEditorWindow.CreateTab();UIUtils.CurrentWindow=window;
            if(!UIUtils.Initialized) {window.Show();shown=true;window.SendEvent(new Event {type=EventType.Layout});window.SendEvent(new Event {type=EventType.Repaint});}
            row.graphLoaded=window.LoadFromDisk(copy).ToString()=="LOADED";
            if(!row.graphLoaded) throw new Exception("ASE could not load reference");
            var graph=window.CurrentGraph;graph.RefreshExternalReferences();row.nodes=graph.AllNodes.Count;
            var identities=graph.AllNodes.ToDictionary(n=>n.UniqueId,n=>n.GetType().FullName);var edges=Edges(graph);
            graph.CurrentMasterNode.ForceReordering();
            var settings=Settings(graph);
            row.outputPath=directory+"/Migrated_"+Path.GetFileName(input.path);
            saveField.SetValue(null,false);graph.FireMasterNode(Path.GetFullPath(row.outputPath),true);
            AssetDatabase.ImportAsset(row.outputPath,ImportAssetOptions.ForceSynchronousImport|ImportAssetOptions.ForceUpdate);
            if(window.LoadFromDisk(row.outputPath).ToString()!="LOADED")throw new Exception("ASE reload failed");
            graph=window.CurrentGraph;
            graph.RefreshExternalReferences();
            if(identities.Count!=graph.AllNodes.Count || identities.Any(pair=>graph.GetNode(pair.Key)==null || graph.GetNode(pair.Key).GetType().FullName!=pair.Value) || !edges.SequenceEqual(Edges(graph))) throw new Exception("Migration changed node identity or connections");
            var reloadedSettings=Settings(graph);
            if(settings.Any(pair=>reloadedSettings[pair.Key]!=pair.Value))throw new Exception("Migration changed serialized node settings: "+string.Join(",",settings.Where(pair=>reloadedSettings[pair.Key]!=pair.Value).Select(pair=>pair.Key.ToString()).ToArray()));
            row.graphRoundTrip=true;
            var shader=AssetDatabase.LoadAssetAtPath<Shader>(row.outputPath);var material=new Material(shader);
            try {row.passes=material.passCount;if(row.passes==0)throw new Exception("No material passes");for(int p=0;p<material.passCount;p++)ShaderUtil.CompilePass(material,p,true);}
            finally {UnityEngine.Object.DestroyImmediate(material);}
            row.messages.AddRange(ShaderUtil.GetShaderMessages(shader).Select(m=>m.message));
            row.shaderCompiled=!ShaderUtil.ShaderHasError(shader);
            row.status=row.shaderCompiled?"MigrationCompiled":"ValidationFailed";
            row.messages.Add("Node identities, serialized settings and both directions of connections reloaded. Material visual equivalence requires further checks. This is migration, not handwritten conversion.");
        }
        finally
        {
            saveField.SetValue(null,saveThread);
            try {if(window!=null){window.ShaderIsModified=false;if(shown)window.Close();else UnityEngine.Object.DestroyImmediate(window);}}
            catch(Exception e){row.messages.Add("Window cleanup: "+e.Message);}
            finally {UIUtils.CurrentWindow=previous;}
        }
    }
    static void Compare(Input input,Row row)
    {
        string copy="Assets/FullValidation/"+runId+"/"+results.rows.Count+"_Source.shader";
        File.Copy(input.path,copy,false);AssetDatabase.ImportAsset(copy,ImportAssetOptions.ForceSynchronousImport|ImportAssetOptions.ForceUpdate);
        var source=AssetDatabase.LoadAssetAtPath<Shader>(copy);var generated=AssetDatabase.LoadAssetAtPath<Shader>(row.outputPath);
        var passMaterial=new Material(generated);int generatedPass=passMaterial.FindPass("Unlit");UnityEngine.Object.DestroyImmediate(passMaterial);
        for(int state=0;state<3;state++)
        {
            Color[] a=Render(source,0,state),b=Render(generated,generatedPass,state);
            if(ShaderUtil.ShaderHasError(source))throw new Exception("Source fixture did not compile");
            if(!a.Any(c=>Mathf.Abs(c.r)+Mathf.Abs(c.g)+Mathf.Abs(c.b)>0.05f))throw new Exception("Blank reference is not a valid comparison");
            for(int i=0;i<a.Length;i++)for(int c=0;c<4;c++){float error=Mathf.Abs(a[i][c]-b[i][c]);if(float.IsNaN(error)||float.IsInfinity(error))throw new Exception("Non-finite pixels");row.fixtureMaxError=Mathf.Max(row.fixtureMaxError,error);}
            row.fixtureCases++;
        }
        row.fixtureCompared=row.fixtureMaxError<=2f/255f;
        row.messages.Add("Three 64x32 Linear RGBAFloat Blit fixtures, nonzero Color/Tint and Blend=0/0.5/1. Not a scene or all-platform/variant comparison.");
        if(!row.fixtureCompared)throw new Exception("Pixel error="+row.fixtureMaxError);
    }
    static Color[] Render(Shader shader,int pass,int state)
    {
        if(pass<0)throw new Exception("Expected Unlit pass missing");
        var material=new Material(shader);var target=RenderTexture.GetTemporary(64,32,0,RenderTextureFormat.ARGBFloat,RenderTextureReadWrite.Linear);var previous=RenderTexture.active;Texture2D pixels=null;
        if(material.HasProperty("_Color"))material.SetColor("_Color",state==1?new Color(0.8f,0.4f,0.2f,0.6f):new Color(0.3f,0.65f,0.85f,0.9f));
        if(material.HasProperty("_SecondaryColor"))material.SetColor("_SecondaryColor",new Color(0.9f,0.2f,0.4f,0.5f));
        if(material.HasProperty("_Blend"))material.SetFloat("_Blend",state*0.5f);
        try {ShaderUtil.CompilePass(material,pass,true);Graphics.Blit(Texture2D.whiteTexture,target,material,pass);RenderTexture.active=target;pixels=new Texture2D(64,32,TextureFormat.RGBAFloat,false,true);pixels.ReadPixels(new Rect(0,0,64,32),0,0);pixels.Apply();return pixels.GetPixels();}
        finally {RenderTexture.active=previous;RenderTexture.ReleaseTemporary(target);UnityEngine.Object.DestroyImmediate(material);if(pixels!=null)UnityEngine.Object.DestroyImmediate(pixels);}
    }
}
