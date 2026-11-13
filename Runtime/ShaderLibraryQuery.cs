using System;
using System.Collections.Generic;
using System.Linq;

namespace ASEShaderConverter
{
    public enum ShaderLibraryScope { AllGenerated, ThreeMappedTargets, WithGaps }

    [Serializable] public sealed class ShaderLibraryCategorySummary
    {
        public string id="";
        public int families, versions, builtIn, urp, hdrp, researchSources, missingTargets, featureGapTargets;
        public int VersionsFor(string pipeline)
        {
            return pipeline=="BuiltIn"?builtIn:pipeline=="URP"?urp:pipeline=="HDRP"?hdrp:versions;
        }
    }

    // Device labels are intended targets based on the graph and pipeline, not GPU results.
    public static class ShaderLibraryQuery
    {
        public static readonly string[] Pipelines={"BuiltIn","URP","HDRP"};
        static readonly Dictionary<string,string> Titles=ShaderRuleLibrary.Catalog().categories.ToDictionary(c=>c.id,c=>c.title);
        // Earlier research batches used UIAnimation for the UIEffects category.
        public static string CanonicalCategory(string id) {return id=="UIAnimation"?"UIEffects":id;}
        public static string Family(ShaderLibraryEntry entry) {return string.IsNullOrEmpty(entry.familyId)?entry.id:entry.familyId;}
        public static bool IsGenerated(ShaderLibraryEntry entry) {return entry.aseRoundTripPassed&&entry.shaderCompiled;}
        public static ShaderLibraryEntry[] Filter(ShaderLibraryCatalog catalog,string query="",string category="",string pipeline="",string device="",string tier="",ShaderLibraryScope scope=ShaderLibraryScope.AllGenerated)
        {
            var generated=catalog.entries.Where(IsGenerated).ToArray();
            var mapped=new HashSet<string>(generated.GroupBy(Family).Where(g=>HasThreeMappedTargets(catalog.familyContracts.FirstOrDefault(c=>c.familyId==g.Key),g)).Select(g=>g.Key));
            return generated.Where(e=>(scope==ShaderLibraryScope.AllGenerated || (scope==ShaderLibraryScope.ThreeMappedTargets)==mapped.Contains(Family(e))) && Matches(e,query,category,pipeline,device,tier)).ToArray();
        }
        // Asset categories come only from verified graphs; research-only categories stay in research.
        public static ShaderLibraryCategorySummary[] Categories(ShaderLibraryCatalog catalog,bool includeResearchOnly=false)
        {
            var generated=catalog.entries.Where(IsGenerated).ToArray();
            var ids=generated.Select(e=>CanonicalCategory(e.category));
            if(includeResearchOnly)ids=ids.Concat(catalog.research.SelectMany(e=>e.categories).Select(CanonicalCategory));
            return ids.Where(id=>!string.IsNullOrEmpty(id)).Distinct().OrderBy(id=>id).Select(id=>
            {
                var entries=generated.Where(e=>CanonicalCategory(e.category)==id).ToArray();
                var families=entries.GroupBy(Family).ToArray();
                return new ShaderLibraryCategorySummary{id=id,families=families.Length,versions=entries.Length,
                    builtIn=entries.Count(e=>e.pipeline=="BuiltIn"),urp=entries.Count(e=>e.pipeline=="URP"),hdrp=entries.Count(e=>e.pipeline=="HDRP"),
                    researchSources=catalog.research.Count(e=>e.categories.Any(c=>CanonicalCategory(c)==id)),
                    missingTargets=families.Sum(g=>Pipelines.Count(p=>!g.Any(e=>e.pipeline==p))),
                    featureGapTargets=families.Sum(g=>catalog.familyContracts.Where(c=>c.familyId==g.Key).SelectMany(c=>c.targets).Count(t=>t.gaps.Count>0&&g.Any(e=>e.id==t.entryId&&e.pipeline==t.pipeline)))};
            }).ToArray();
        }
        public static bool MatchesResearch(ShaderResearchEntry entry,string query,string category="",string pipeline="")
        {
            if(!string.IsNullOrEmpty(category)&&!entry.categories.Any(c=>CanonicalCategory(c)==CanonicalCategory(category)) || !string.IsNullOrEmpty(pipeline)&&entry.pipeline!=pipeline)return false;
            string text=entry.title+" "+entry.source+" "+entry.status+" "+entry.kind+" "+entry.pipeline+" "+string.Join(" ",entry.categories.Select(c=>c+" "+CanonicalCategory(c)+" "+CategoryTitle(c)).ToArray())+" "+string.Join(" ",entry.blockers.ToArray());
            return (query??"").Split((char[])null,StringSplitOptions.RemoveEmptyEntries).All(token=>text.IndexOf(token,StringComparison.OrdinalIgnoreCase)>=0);
        }
        public static bool HasThreeArtifacts(IEnumerable<ShaderLibraryEntry> family)
        {
            return new HashSet<string>(family.Where(e=>e.aseRoundTripPassed&&e.shaderCompiled).Select(e=>e.pipeline)).SetEquals(Pipelines);
        }
        public static bool HasThreeMappedTargets(ShaderFamilyContract contract,IEnumerable<ShaderLibraryEntry> family)
        {
            if(contract==null||contract.targets==null||contract.targets.Count!=Pipelines.Length)return false;
            var entries=family.ToArray();
            return Pipelines.All(p=>contract.targets.Count(t=>t.pipeline==p)==1 && contract.targets.Any(t=>t.pipeline==p&&t.status=="Mapped"&&t.gaps.Count==0&&entries.Any(e=>e.pipeline==p&&e.id==t.entryId&&e.aseRoundTripPassed&&e.shaderCompiled)));
        }
        public static string CategoryTitle(string id)
        {
            id=CanonicalCategory(id);string title;return Titles.TryGetValue(id,out title)?title:(id=="General"?"通用材质与工具":id);
        }
        public static bool Matches(ShaderLibraryEntry e,string query,string category="",string pipeline="",string device="",string tier="")
        {
            if(!string.IsNullOrEmpty(category)&&CanonicalCategory(e.category)!=CanonicalCategory(category) || !string.IsNullOrEmpty(pipeline)&&e.pipeline!=pipeline ||
               !string.IsNullOrEmpty(device)&&!e.devices.Contains(device) || !string.IsNullOrEmpty(tier)&&e.performanceTier!=tier)return false;
            string text=string.Join(" ",new[]{e.title,e.id,e.familyId,e.category,CategoryTitle(e.category),e.pipeline,e.effect,e.notes,e.source,e.performanceBasis,
                string.Join(" ",e.keywords.ToArray()),string.Join(" ",e.devices.ToArray()),e.devices.Contains("Mobile")?"移动端 手机 Android iOS":"",
                e.devices.Contains("Pad")?"平板 Pad Pad端 iPad":"",e.devices.Contains("PC")?"电脑 桌面 PC PC端":"",
                e.performanceTier=="Low"?"低 低复杂度":e.performanceTier=="Medium"?"中 中复杂度":e.performanceTier=="High"?"高 高复杂度":"未分级"});
            return (query??"").Split((char[])null,StringSplitOptions.RemoveEmptyEntries).All(token=>text.IndexOf(token,StringComparison.OrdinalIgnoreCase)>=0);
        }
        public static string Coverage(IEnumerable<ShaderLibraryEntry> family,ShaderFamilyContract contract=null)
        {
            var pipelines=new HashSet<string>(family.Where(e=>e.aseRoundTripPassed&&e.shaderCompiled).Select(e=>e.pipeline));
            return string.Join("  |  ",Pipelines.Select(p=>
            {
                var target=contract==null?null:contract.targets.FirstOrDefault(t=>t.pipeline==p);
                string status=!pipelines.Contains(p)?"待适配":target==null?"已生成 / 功能待审查":target.gaps.Count>0||target.status=="FeatureGap"?"已生成 / 有功能缺口":target.status=="Mapped"?"已生成 / 功能已映射":"已生成 / 功能待审查";
                return p+": "+status;
            }).ToArray());
        }
    }
}
