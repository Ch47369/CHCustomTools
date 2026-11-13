// Isolated Unity integration of the unified window, real catalog and public material installer.
using System;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Collections.Generic;
using ASEShaderConverter;
using ASEShaderConverter.Editor;
using UnityEditor;
using UnityEngine;

public static class UnityLibraryBrowserSmoke
{
    [Serializable] public sealed class Evidence
    {
        public bool success,legacyRedirected,resetRestored,sourceFilesUnchanged;
        public string pipeline,version,error,finishedUtc;
        public int checks,defaultVisibleVersions,strictVisibleVersions,allVersions,researchSources,guiEventsDispatched;
        public List<ShaderLibraryCategorySummary> categories=new List<ShaderLibraryCategorySummary>();
        public List<ShaderLibraryBatch.Item> installs=new List<ShaderLibraryBatch.Item>();
    }
    static Evidence result=new Evidence();
    static ShaderLibraryWindow window;
    const BindingFlags Private=BindingFlags.Instance|BindingFlags.NonPublic;
    static object Get(string field){return typeof(ShaderLibraryWindow).GetField(field,Private).GetValue(window);}
    static void Set(string field,object value){typeof(ShaderLibraryWindow).GetField(field,Private).SetValue(window,value);}
    static void Check(bool ok,string name){if(!ok)throw new Exception(name);result.checks++;}
    static List<string> guiErrors=new List<string>();
    static void Log(string condition,string trace,LogType type){if(type==LogType.Exception||type==LogType.Error||type==LogType.Assert)guiErrors.Add(condition);}
    public static void Run()
    {
        try
        {
            if(Path.GetFullPath(".").IndexOf(Path.DirectorySeparatorChar+".validation"+Path.DirectorySeparatorChar,StringComparison.OrdinalIgnoreCase)<0)throw new Exception("Isolation required");
            var probe=ShaderConverterApi.Execute(new ShaderAgentRequest{operation="probe"});Check(probe.success,"Actual ASE environment");
            result.pipeline=probe.environment.activePipeline;
            var api=ShaderConverterApi.Execute(new ShaderAgentRequest{operation="library"});Check(api.success,"Public library API");
            var catalog=api.shaderLibrary;result.version=catalog.version;
            result.categories=ShaderLibraryQuery.Categories(catalog,true).ToList();
            result.allVersions=ShaderLibraryQuery.Filter(catalog).Length;result.researchSources=catalog.research.Count;
            Check(result.allVersions==287&&result.researchSources==1079,"No generated/research count inflation");
            Check(result.categories.Count==15&&result.categories.Sum(c=>c.versions)==287&&result.categories.Sum(c=>c.families)==109,"Actual per-category coverage");
            Check(result.categories.Sum(c=>c.missingTargets)==40&&result.categories.Sum(c=>c.featureGapTargets)==49,"Outstanding conversions remain visible");
            result.defaultVisibleVersions=ShaderLibraryQuery.Filter(catalog,pipeline:result.pipeline).Length;
            result.strictVisibleVersions=ShaderLibraryQuery.Filter(catalog,pipeline:result.pipeline,scope:ShaderLibraryScope.ThreeMappedTargets).Length;
            Check(result.defaultVisibleVersions==(result.pipeline=="HDRP"?109:89)&&result.strictVisibleVersions==64,"Default and explicit mapped-only scopes");
            ShaderLibraryWindow.Open();window=EditorWindow.GetWindow<ShaderLibraryWindow>();
            Check(Get("catalog")!=null&&(string)Get("activePipeline")==result.pipeline,"Window loaded catalog and actual pipeline");
            Check((int)Get("scope")==0,"Default includes actual graphs with documented gaps");
            foreach(var category in new[]{"Skin","Hair","Eye","Fabric","Hosiery","Water","Metal","Stone","Jade","UI","UIEffects","VFX","UVAnimation","VertexAnimation"})
            {
                ShaderLibraryWindow.OpenCategory(category);
                Check((string)Get("categoryId")==category&&(int)Get("scope")==0&&(int)Get("tab")==0,"Unified category navigation "+category);
                Check(ShaderLibraryQuery.Filter(catalog,category:category,pipeline:result.pipeline).Length>=6,"Main category has real graphs "+category);
            }
            var general=result.categories.Single(c=>c.id=="General");
            Check(general.builtIn==0&&general.urp==0&&general.hdrp==9&&general.missingTargets==18,"General pipeline absence is explicit");
            Set("search","no match 034");Set("device",1);Set("tier",3);Set("scope",1);Set("tab",1);Set("researchCategoryId","Hair");
            typeof(ShaderLibraryWindow).GetMethod("ResetFilters",Private).Invoke(window,null);
            result.resetRestored=(string)Get("search")==""&&(string)Get("categoryId")==""&&(string)Get("researchCategoryId")==""&&(int)Get("device")==0&&(int)Get("tier")==0&&(int)Get("scope")==0&&(int)Get("tab")==0;
            Check(result.resetRestored,"Reset clears restrictive filters and both category states");
            CharacterMaterialWindow.Open();result.legacyRedirected=Resources.FindObjectsOfTypeAll<CharacterMaterialWindow>().Length==0&&(string)Get("categoryId")=="Skin";
            Check(result.legacyRedirected,"Legacy character entry redirects without a duplicate window");
            var menu=typeof(CharacterMaterialWindow).GetMethod("Open").GetCustomAttributes(typeof(MenuItem),false);
            Check(menu.Length==0,"No duplicate character menu");
            Application.logMessageReceived+=Log;
            // Dispatch actual IMGUI layout/repaint events for character, no-match and research views.
            foreach(int view in new[]{0,1})
            {
                Set("tab",view);Set(view==0?"categoryId":"researchCategoryId","Skin");
                window.SendEvent(new Event{type=EventType.Layout});window.SendEvent(new Event{type=EventType.Repaint});result.guiEventsDispatched+=2;
            }
            Set("tab",0);Set("categoryId","General");Set("pipeline",1);Set("overview",true);
            window.SendEvent(new Event{type=EventType.Layout});window.SendEvent(new Event{type=EventType.Repaint});result.guiEventsDispatched+=2;
            Application.logMessageReceived-=Log;
            Check(guiErrors.Count==0,"Unified UI events: "+string.Join("; ",guiErrors.ToArray()));
            // One real item per populated category checks the unchanged public install path.
            var selected=ShaderLibraryQuery.Filter(catalog,pipeline:result.pipeline).GroupBy(e=>e.category).Select(g=>g.First()).ToArray();
            foreach(var entry in selected)
            {
                var item=ShaderLibraryBatch.Generate(entry.id);result.installs.Add(item);Check(item.success,"Install actual category "+entry.category+": "+item.error);
                var material=AssetDatabase.LoadAssetAtPath<Material>(item.materialPath);
                Check(material!=null&&!ShaderUtil.ShaderHasError(material.shader),"Imported ASE material compiles "+entry.category);
            }
            result.sourceFilesUnchanged=catalog.entries.All(e=>File.Exists(ShaderLibraryAssets.VerifiedPath(e)));
            Check(result.sourceFilesUnchanged,"All delivered graph checksums unchanged");
            result.success=true;Finish(0);
        }
        catch(Exception e){Application.logMessageReceived-=Log;result.error=e.ToString();Debug.LogException(e);Finish(1);}
    }
    static void Finish(int code)
    {
        if(window!=null)window.Close();result.finishedUtc=DateTime.UtcNow.ToString("o");
        Directory.CreateDirectory("LibraryBuildEvidence");File.WriteAllText("LibraryBuildEvidence/browser-smoke-034.json",JsonUtility.ToJson(result,true));
        Debug.Log("ASE_LIBRARY_BROWSER_SMOKE "+result.pipeline+" "+result.success+" checks="+result.checks);EditorApplication.Exit(code);
    }
}
