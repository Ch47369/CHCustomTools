using System;
using System.Collections.Generic;

namespace ASEShaderConverter
{
    [Serializable] public sealed class ShaderLibraryEntry
    {
        public string id="", title="", category="", pipeline="", origin="", path="", sha256="", sourceSha256="", source="", license="", notes="", evidence="";
        public string unityVersion="", aseVersion="", templateGuid="", status="";
        public string familyId="", effect="", performanceTier="Unrated", performanceBasis="", deviceValidation="NotBenchmarked";
        public string shaderModel="", graphicsApiValidation="", deviceRequirements="";
        public int textureSampleSites;
        public bool transparent, vertexAnimation;
        public List<string> devices=new List<string>(), keywords=new List<string>();
        public bool aseRoundTripPassed, shaderCompiled, visualComparisonPassed, layoutApplied;
        public int nativeNodeCount, customExpressionCount, commentCount;
        public List<string> dependencies=new List<string>();
    }
    [Serializable] public sealed class ShaderResearchEntry
    {
        public string id="", title="", source="", sha256="", kind="", pipeline="", license="", status="AnalysisOnly", evidence="";
        public List<string> categories=new List<string>(), blockers=new List<string>();
    }
    [Serializable] public sealed class ShaderPipelineContract
    {
        public string pipeline="", entryId="", status="NotReviewed", evidence="";
        public List<string> gaps=new List<string>(), hostRequirements=new List<string>();
    }
    [Serializable] public sealed class ShaderFamilyContract
    {
        public string familyId="", sourceIdentity="", comparisonStatus="NotCompared";
        public List<string> sharedFeatures=new List<string>();
        public List<ShaderPipelineContract> targets=new List<ShaderPipelineContract>();
    }
    [Serializable] public sealed class ShaderLibraryCatalog
    {
        public string version="0.3.6", scope="ASE save/reload and compilation are verified per entry. Source assets, host setup and visual equivalence require separate validation.";
        public List<ShaderLibraryEntry> entries=new List<ShaderLibraryEntry>();
        public List<ShaderResearchEntry> research=new List<ShaderResearchEntry>();
        public List<ShaderFamilyContract> familyContracts=new List<ShaderFamilyContract>();
    }
}
