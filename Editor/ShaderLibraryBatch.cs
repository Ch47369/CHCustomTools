using System;
using System.IO;
using System.Linq;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

namespace ASEShaderConverter.Editor
{
    public static class ShaderLibraryBatch
    {
        [Serializable] public sealed class Item {public string id,shaderPath,materialPath,error;public bool success,materialReused;}
        [Serializable] public sealed class Report {public string pipeline;public bool completed,cancelled;public int requested;public List<Item> items=new List<Item>();}
        static string[] ids; static int cursor;static Report report;static string reportPath;
        public static bool IsRunning {get;private set;}
        static string lastReportZh="",lastReportEn="";
        public static string LastReport {get{return CHToolLanguage.Pick(lastReportZh,lastReportEn);}}
        public static Report LastResult {get;private set;}
        public static string Progress {get{return IsRunning?CHToolLanguage.Pick("生成进度 ","Progress ")+cursor+" / "+ids.Length:"";}}
        public static Item Generate(string id)
        {
            var item=new Item{id=id};
            try
            {
                var entry=ShaderLibraryAssets.Load().entries.Single(e=>e.id==id);
                // Batch mode installs shader data only; no script import or domain reload.
                item.shaderPath=ShaderLibraryAssets.Import(id,false);
                var shader=AssetDatabase.LoadAssetAtPath<Shader>(item.shaderPath);
                if(shader==null||ShaderUtil.ShaderHasError(shader))throw new InvalidOperationException("Imported shader has compilation errors.");
                string candidate=Path.ChangeExtension(item.shaderPath,".mat").Replace('\\','/');
                var existing=AssetDatabase.LoadAssetAtPath<Material>(candidate);
                if(existing!=null&&existing.shader==shader){item.materialPath=candidate;item.materialReused=true;}
                else
                {
                    item.materialPath=AssetDatabase.GenerateUniqueAssetPath(candidate);
                    var material=new Material(shader){name=Path.GetFileNameWithoutExtension(item.materialPath)};
                    try{ShaderLibraryMaterialDefaults.Initialize(entry,material);AssetDatabase.CreateAsset(material,item.materialPath);}catch{UnityEngine.Object.DestroyImmediate(material);throw;}
                }
                item.success=true;
            }catch(Exception ex){item.error=ex.Message;}
            return item;
        }
        public static void Start(string[] requested)
        {
            if(IsRunning)throw new InvalidOperationException("A material batch is already running.");
            var catalog=ShaderLibraryAssets.Load();var environment=AseEditorBridge.Probe();
            if(environment.errors.Count>0)throw new InvalidOperationException(string.Join("\n",environment.errors.ToArray()));
            ids=requested.Distinct().ToArray();
            if(ids.Any(id=>!catalog.entries.Any(e=>e.id==id&&e.pipeline==environment.activePipeline&&e.aseRoundTripPassed&&e.shaderCompiled)))throw new ArgumentException("All requested entries must be validated for the active pipeline.");
            report=new Report{pipeline=environment.activePipeline,requested=ids.Length};cursor=0;
            string folder="Library/ASEShaderConverter/LibraryBatches";Directory.CreateDirectory(folder);reportPath=folder+"/"+Guid.NewGuid().ToString("N")+".json";
            Save();IsRunning=true;lastReportZh=lastReportEn="";EditorApplication.update+=Tick;AssemblyReloadEvents.beforeAssemblyReload+=Interrupted;
        }
        public static void Cancel(){if(!IsRunning)return;report.cancelled=true;Finish();}
        static void Interrupted(){if(!IsRunning)return;report.cancelled=true;Finish();}
        static void Save(){File.WriteAllText(reportPath,JsonUtility.ToJson(report,true));}
        static void Tick()
        {
            if(EditorApplication.isCompiling||EditorApplication.isUpdating)return;
            if(cursor>=ids.Length){report.completed=true;Finish();return;}
            try{report.items.Add(Generate(ids[cursor++]));Save();}
            catch(Exception ex){Debug.LogException(ex);report.cancelled=true;Finish();}
        }
        static void Finish()
        {
            EditorApplication.update-=Tick;AssemblyReloadEvents.beforeAssemblyReload-=Interrupted;IsRunning=false;AssetDatabase.SaveAssets();Save();
            lastReportZh=(report.cancelled?"已停止":"已完成")+"：成功 "+report.items.Count(i=>i.success)+"，失败 "+report.items.Count(i=>!i.success)+"，未处理 "+(ids.Length-cursor)+"。报告："+reportPath;
            lastReportEn=(report.cancelled?"Stopped":"Completed")+": succeeded "+report.items.Count(i=>i.success)+", failed "+report.items.Count(i=>!i.success)+", pending "+(ids.Length-cursor)+". Report: "+reportPath;
            LastResult=report;
            Debug.Log(LastReport);
        }
    }
}
