using System;
using System.Linq;
using ASEShaderConverter;

internal static class CharacterMaterialChecks
{
    public static int Run()
    {
        int checks=0;
        Action<bool,string> check=(condition,name)=>{if(!condition)throw new Exception(name);checks++;};
        var catalog=ShaderRuleLibrary.Catalog();
        check(catalog.characterProfiles.Select(p=>p.id).SequenceEqual(new[]{"Skin","Hair","Eye","Fabric"}),"Four independently addressable character profiles");
        foreach(var profile in catalog.characterProfiles)
        {
            check(catalog.rules.Any(r=>r.id==profile.ruleId && r.implementation=="RecipeRecorded"),profile.id+": linked rule must not claim generation support");
            check(profile.implementation=="RecipeRecorded" && profile.qualityTarget.Contains("画面对比尚未验证") && profile.qualityTarget.Contains("不能宣称达到 3A"),profile.id+": honest character quality scope");
            check(profile.pipelines.Select(p=>p.pipeline).SequenceEqual(new[]{"BuiltIn","URP","HDRP"}) && profile.pipelines.All(p=>p.status=="RequiresAdapter"),profile.id+": three explicit pipeline adapter requirements");
            check(profile.inputs.Count>=5 && profile.inputs.All(i=>!string.IsNullOrEmpty(i.name)&&!string.IsNullOrEmpty(i.usage)&&!string.IsNullOrEmpty(i.colorSpace)),profile.id+": texture/asset input contract");
            check(profile.preserve.Count>=6 && profile.validation.Count>=5 && profile.costs.Count>=3 && profile.sources.Count>0,profile.id+": semantic, validation, cost and source contracts");
        }
        foreach(var pair in new[]{new[]{"Skin","Shader \"Character/Skin\" { float _SubsurfaceMask; float _DiffusionProfileHash; }"},new[]{"Hair","Shader \"Character/Fur\" { float3 strandTangentWS; float _HairCoverage; }"},new[]{"Eye","Shader \"Character/Eye\" { float _IrisDepth; float _CorneaIOR; }"},new[]{"Fabric","Shader \"Character/Silk\" { float _ClothSheen; }"}})
        {
            var review=ShaderRuleLibrary.Review(pair[1]);
            check(review.materialCategories.Contains(pair[0]),pair[0]+": category detected");
            check(review.characterMaterials.Any(r=>r.profileId==pair[0]&&r.status=="AnalysisOnly"&&r.requiredReview.Count>0),pair[0]+": assessment retains explicit review requirements");
            check(review.rules.Any(r=>r.id=="character-material-contract"),pair[0]+": character dependency analysis attached");
        }
        foreach(string source in new[]{"float unity_StereoEyeIndex; UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i); UNITY_VERTEX_OUTPUT_STEREO", "Shader \"Sky/Skyline\" { float skinningWeight; float3 eyespacePosition; }", "// Skin Eye Hair Fabric\n/* _CorneaIOR; _SubsurfaceMask; */ Shader \"Plain\" {}", "float diffusion; Shader \"Jade/Nephrite\" {}", "Shader \"Hidden/EyeAdaptation\" { float _EyeAdaptation; float eyeDepth; int stereoEyeIndex; }", "// _DiffusionProfileHash\nfloat diffusion;"})
            check(!CharacterMaterialLibrary.Review(source).Any(),"No character classification from stereo, skinning, comments or generic diffusion");
        var combined=ShaderRuleLibrary.Review("Shader \"Character/Combined\" { float _SkinMask; float _HairMask; float _IrisDepth; float _ClothSheen; }");
        check(combined.characterMaterials.Count==4 && combined.rules.Count(r=>r.id=="character-material-contract")==1,"Combined materials retain four profiles without duplicate contract");
        var eye=catalog.characterProfiles.Single(p=>p.id=="Eye");
        check(eye.pipelines.Single(p=>p.pipeline=="HDRP").requirements.Contains("普通 HDRP Lit"),"Eye does not silently downgrade to ordinary Lit");
        check(eye.pipelines.All(p=>string.IsNullOrEmpty(p.referenceTemplateGuid)),"No unverified Eye template identity is invented");
        check(catalog.characterProfiles.Where(p=>p.id!="Eye").All(p=>p.pipelines.Single(r=>r.pipeline=="HDRP").referenceTemplateGuid.Length==32),"Three actual HDRP reference template identities available for live describe");
        check(catalog.characterProfiles.Single(p=>p.id=="Hair").geometry.Contains("Shell/Fin"),"Hair geometry cannot silently collapse to hair cards");
        check(catalog.characterProfiles.Single(p=>p.id=="Fabric").preserve.Any(p=>p.Contains("棉麻")&&p.Contains("丝绸")),"Fabric models retain sheen/anisotropy distinction");
        var first=CharacterMaterialLibrary.Profiles();first[0].inputs.Clear();
        check(CharacterMaterialLibrary.Profiles()[0].inputs.Count>=5,"Profile callers cannot mutate subsequent catalog results");
        const string unsupported="Shader \"Character/Eye\" { SubShader { Tags { \"RenderPipeline\"=\"HDRenderPipeline\" } Pass { HLSLPROGRAM\n#pragma vertex vert\n#pragma fragment frag\n#include \"Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Eye/Eye.hlsl\"\nENDHLSL } } }";
        foreach(string target in new[]{"BuiltIn","URP","HDRP"})
        {
            var analysis=ShaderConversionEngine.Analyze(unsupported,"",new ShaderConversionOptions{targetPipeline=target});
            check(!analysis.report.CanGenerate && analysis.report.blockers.Count>0,target+": character classification does not bypass source HDRP/template/dependency blockers");
            check(analysis.knowledge.characterMaterials.Any(c=>c.profileId=="Eye"),target+": source Eye review survives target switching");
        }
        return checks;
    }
}
