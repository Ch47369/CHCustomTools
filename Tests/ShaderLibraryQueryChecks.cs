using System;
using System.Collections.Generic;
using System.Linq;
using ASEShaderConverter;

internal static class ShaderLibraryQueryChecks
{
    public static int Run()
    {
        int count=0;Action<bool,string> check=(ok,name)=>{if(!ok)throw new Exception(name);count++;};
        var e=new ShaderLibraryEntry{id="fabric-urp",familyId="Fabric-Checks",title="格纹布料",category="Fabric",pipeline="URP",performanceTier="Medium",devices=new List<string>{"Mobile","Pad","PC"},keywords=new List<string>{"cloth","checker"},aseRoundTripPassed=true,shaderCompiled=true};
        check(ShaderLibraryQuery.Matches(e,"布料 Pad URP"),"Chinese and device aliases with AND search");
        check(ShaderLibraryQuery.Matches(e,"CLOTH\tchecker  平板"),"Whitespace/case insensitive combined search");
        check(!ShaderLibraryQuery.Matches(e,"cloth eye"),"All search terms are required");
        check(!ShaderLibraryQuery.Matches(e,"",pipeline:"HDRP"),"Pipeline filter cannot expose incompatible assets");
        check(!ShaderLibraryQuery.Matches(e,"",tier:"High"),"Complexity filter");
        check(!ShaderLibraryQuery.Matches(e,"",device:"Console"),"Unsupported target device filter");
        check(ShaderLibraryQuery.Matches(e,"",category:"Fabric",pipeline:"URP",device:"Pad",tier:"Medium"),"Combined independent filters");
        var blocked=new ShaderLibraryEntry{pipeline="HDRP",shaderCompiled=false,aseRoundTripPassed=true};
        string coverage=ShaderLibraryQuery.Coverage(new[]{e,blocked});
        check(coverage.Contains("URP: 已生成")&&coverage.Contains("HDRP: 待适配")&&coverage.Contains("BuiltIn: 待适配"),"A missing or uncompiled pipeline never appears generated");
        check(ShaderLibraryQuery.Family(e)=="Fabric-Checks","Family grouping joins pipeline versions");
        check(ShaderLibraryQuery.Family(new ShaderLibraryEntry{id="legacy"})=="legacy","Legacy entries retain independent identities");
        var bi=new ShaderLibraryEntry{id="bi",pipeline="BuiltIn",shaderCompiled=true,aseRoundTripPassed=true};
        var hd=new ShaderLibraryEntry{id="hd",pipeline="HDRP",shaderCompiled=true,aseRoundTripPassed=true};
        var three=new[]{bi,e,hd};
        check(ShaderLibraryQuery.HasThreeArtifacts(three),"Three files are counted independently of behavior");
        check(!ShaderLibraryQuery.HasThreeMappedTargets(null,three),"Missing contracts never imply feature completeness");
        var contract=new ShaderFamilyContract{targets=new List<ShaderPipelineContract>{new ShaderPipelineContract{pipeline="BuiltIn",entryId="bi",status="Mapped"},new ShaderPipelineContract{pipeline="URP",entryId=e.id,status="Mapped"},new ShaderPipelineContract{pipeline="HDRP",entryId="hd",status="Mapped"}}};
        check(ShaderLibraryQuery.HasThreeMappedTargets(contract,three),"Audited mappings require all three generated identities");
        contract.targets[0].status="FeatureGap";contract.targets[0].gaps.Add("Missing hair scattering");
        check(!ShaderLibraryQuery.HasThreeMappedTargets(contract,three),"A compiled PBR approximation cannot satisfy a hair contract");
        check(ShaderLibraryQuery.Coverage(three,contract).Contains("BuiltIn: 已生成 / 有功能缺口"),"Coverage exposes behavior gaps alongside generated files");
        contract.targets[0].status="Mapped";
        check(!ShaderLibraryQuery.HasThreeMappedTargets(contract,three),"Mapped label cannot override a known gap");
        contract.targets[0].gaps.Clear();contract.targets[0].entryId="unrelated";
        check(!ShaderLibraryQuery.HasThreeMappedTargets(contract,three),"A different source identity does not complete the same family");
        // A research-only category and a failed graph must never become installable choices.
        var catalog=new ShaderLibraryCatalog();
        var cloth=new ShaderLibraryEntry{id="cloth-hdrp",familyId="cloth",category="Fabric",pipeline="HDRP",aseRoundTripPassed=true,shaderCompiled=true};
        var failed=new ShaderLibraryEntry{id="bad",familyId="bad",category="Failed",pipeline="URP",aseRoundTripPassed=true};
        catalog.entries.AddRange(new[]{e,cloth,failed});
        catalog.research.Add(new ShaderResearchEntry{title="Fabric archive",pipeline="HDRP",categories=new List<string>{"Fabric","ResearchOnly"},blockers=new List<string>{"Missing host"}});
        catalog.familyContracts.Add(new ShaderFamilyContract{familyId=e.familyId,targets=new List<ShaderPipelineContract>{new ShaderPipelineContract{pipeline="URP",entryId=e.id,status="FeatureGap",gaps=new List<string>{"Missing Sheen"}}}});
        var categories=ShaderLibraryQuery.Categories(catalog);
        check(categories.Length==1&&categories[0].id=="Fabric","Install categories exclude research-only and failed assets");
        var summary=categories[0];
        check(summary.families==2&&summary.versions==2&&summary.builtIn==0&&summary.urp==1&&summary.hdrp==1,"Category counts separate source families and pipeline files");
        check(summary.researchSources==1&&summary.missingTargets==4&&summary.featureGapTargets==1,"Research and missing targets are independent of generated versions");
        check(summary.VersionsFor("BuiltIn")==0&&summary.VersionsFor("HDRP")==1&&summary.VersionsFor("")==2,"Pipeline-specific zero coverage remains visible");
        var researchOnly=ShaderLibraryQuery.Categories(catalog,true).Single(c=>c.id=="ResearchOnly");
        check(researchOnly.versions==0&&researchOnly.researchSources==1,"Research-only category explicitly reports zero ASE graphs");
        check(ShaderLibraryQuery.Filter(catalog).Length==2,"Default library includes verified character examples with documented gaps");
        check(ShaderLibraryQuery.Filter(catalog,category:"Fabric",pipeline:"URP").Single()==e,"Current pipeline keeps its actual character graph visible");
        check(ShaderLibraryQuery.Filter(catalog,category:"ResearchOnly").Length==0,"Research does not inflate install results");
        check(ShaderLibraryQuery.Filter(catalog,scope:ShaderLibraryScope.ThreeMappedTargets).Length==0,"Mapped-only view remains an explicit strict filter");
        check(ShaderLibraryQuery.Filter(catalog,scope:ShaderLibraryScope.WithGaps).Length==2,"Gap view includes missing target versions");
        check(ShaderLibraryQuery.Filter(catalog,query:"nothing").Length==0&&ShaderLibraryQuery.Filter(catalog).Length==2,"Clearing filters restores generated results");
        check(ShaderLibraryQuery.Filter(catalog,device:"Pad",tier:"High").Length==0,"Combined device and complexity may legitimately have no results");
        var research=catalog.research[0];
        check(ShaderLibraryQuery.MatchesResearch(research,"布料 Missing",pipeline:"HDRP"),"Research supports Chinese category and blocker AND search");
        check(!ShaderLibraryQuery.MatchesResearch(research,"布料 absent")&&!ShaderLibraryQuery.MatchesResearch(research,"",pipeline:"URP"),"Research filters do not match unrelated terms or pipelines");
        catalog.research.Add(new ShaderResearchEntry{title="Old UI research",categories=new List<string>{"UIAnimation","UIEffects"}});
        var ui=ShaderLibraryQuery.Categories(catalog,true).Single(c=>c.id=="UIEffects");
        check(ui.researchSources==1&&!ShaderLibraryQuery.Categories(catalog,true).Any(c=>c.id=="UIAnimation"),"Historical UI aliases merge without duplicating a source");
        check(ShaderLibraryQuery.MatchesResearch(catalog.research[1],"UIEffects",category:"UIEffects"),"Canonical UI category finds historical research");
        check(ShaderLibraryQuery.CategoryTitle("UIAnimation")==ShaderLibraryQuery.CategoryTitle("UIEffects"),"UI aliases share the displayed title");
        return count;
    }
}
