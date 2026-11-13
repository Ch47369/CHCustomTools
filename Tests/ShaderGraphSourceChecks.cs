using System;
using System.Linq;
using ASEShaderConverter;

internal static class ShaderGraphSourceChecks
{
    public static int Run()
    {
        int count=0;Action<bool,string> check=(ok,message)=>{if(!ok)throw new Exception(message);count++;};
        const string source="{\"m_SGVersion\":3,\"m_Nodes\":[{\"m_Id\":\"n\"},{\"m_Id\":\"b\"}],\"m_Properties\":[{\"m_Id\":\"p\"}],\"m_Edges\":[{\"m_OutputSlot\":{\"m_Node\":{\"m_Id\":\"n\"},\"m_SlotId\":0},\"m_InputSlot\":{\"m_Node\":{\"m_Id\":\"b\"},\"m_SlotId\":0}}],\"m_ActiveTargets\":[{\"m_Id\":\"t\"}],\"m_Keywords\":[{}]}\n"+
        "{\"m_Type\":\"UnityEditor.ShaderGraph.PropertyNode\",\"m_ObjectId\":\"n\",\"m_Slots\":[{\"m_Id\":\"s1\"}]}\n"+
        "{\"m_Type\":\"UnityEditor.ShaderGraph.BlockNode\",\"m_ObjectId\":\"b\",\"m_SerializedDescriptor\":\"SurfaceDescription.BaseColor\",\"m_Slots\":[{\"m_Id\":\"s2\"}]}\n"+
        "{\"m_ObjectId\":\"s1\",\"m_Id\":0}\n{\"m_ObjectId\":\"s2\",\"m_Id\":0}\n"+
        "{\"m_ObjectId\":\"p\",\"m_Name\":\"Skin 基色\",\"m_DefaultReferenceName\":\"_SkinBase\",\"m_Type\":\"ColorShaderProperty\"}\n"+
        "{\"m_Type\":\"UnityEditor.Rendering.HighDefinition.ShaderGraph.HDTarget\",\"m_ObjectId\":\"t\",\"m_ActiveSubTarget\":{\"m_Id\":\"sub\"},\"m_Datas\":[{\"m_Id\":\"data\"}]}\n"+
        "{\"m_ObjectId\":\"sub\",\"m_Type\":\"StackLitSubTarget\"}\n{\"m_ObjectId\":\"data\",\"m_Type\":\"SystemData\",\"m_SurfaceType\":1}";
        var review=ShaderGraphSource.Inspect(source);
        check(review.nodeCount==2&&review.edgeCount==1&&review.format=="MultiJson","Multi-object Shader Graph structure");
        check(review.target=="StackLitSubTarget"&&review.sourcePipeline=="HDRP","Real active SubTarget retained");
        check(review.properties.Single().reference=="_SkinBase"&&review.properties.Single().name.Contains("基色"),"Property identity and Unicode retained");
        check(review.blocks.Single().connected&&review.targetSettings.Contains("SystemData.m_SurfaceType=1"),"Connected stage block and target state retained");
        foreach(string pipeline in new[]{"BuiltIn","URP","HDRP"})
        {
            var analysis=ShaderConversionEngine.Analyze(source,"Skin.shadergraph",new ShaderConversionOptions{targetPipeline=pipeline});
            check(!analysis.report.CanGenerate&&analysis.report.status=="NeedsAgent"&&!analysis.report.aseRoundTripPassed&&!analysis.report.shaderCompiled,"Graph classification cannot grant "+pipeline+" generation");
            check(analysis.knowledge.sourceGraph.sourcePipeline=="HDRP"&&analysis.knowledge.sourceGraph.target=="StackLitSubTarget","Source model survives "+pipeline+" target switch");
            check(analysis.knowledge.rules.Any(r=>r.id=="shadergraph-contract")&&analysis.report.blockers.Any(b=>b.Contains("keyword")),"Graph/keyword review through "+pipeline+" analysis");
        }
        foreach(string bad in new[]{source.Replace("\"m_Id\":\"s1\"","\"m_Id\":\"absent\""),source.Replace("\"m_SlotId\":0","\"m_SlotId\":9"),source+"{\"m_ObjectId\":\"n\"}",source+"junk"})
            check(ShaderConversionEngine.Analyze(bad,"Broken.shadergraph").report.blockers.Any(b=>b.Contains("parse/structure")),"Broken object/slot/trailing JSON rejected");
        const string legacy="{\"m_SerializableNodes\":[{\"typeInfo\":{\"fullName\":\"LegacyMaster\"},\"JSONnodeData\":\"{\\\"m_Name\\\":\\\"Master\\\"}\"}],\"m_SerializedProperties\":[],\"m_SerializableEdges\":[]}";
        check(ShaderGraphSource.Inspect(legacy).nodeCount==1&&ShaderGraphSource.Inspect(legacy).format=="LegacyNestedJson","Legacy nodes inventoried without running Unity code");
        check(!ShaderGraphSource.IsGraph("Shader \"Test\" {}")&&!ShaderGraphSource.IsGraph("{}"),"Normal ShaderLab and arbitrary JSON not misdetected");
        string duplicate=source.Replace("\"m_Datas\":[{\"m_Id\":\"data\"}]","\"m_Datas\":[{\"m_Id\":\"data\"},{\"m_Id\":\"stale\"}]")+"\n{\"m_ObjectId\":\"stale\",\"m_Type\":\"SystemData\",\"m_SurfaceType\":0}";
        review=ShaderGraphSource.Inspect(duplicate);
        check(review.targetSettings.Contains("SystemData.m_SurfaceType=1")&&!review.targetSettings.Contains("SystemData.m_SurfaceType=0")&&review.targetSettings.Any(x=>x.Contains("Ignored duplicate")),"HDRP first data instance remains active");
        string mixed=source.Replace("\"m_ActiveTargets\":[{\"m_Id\":\"t\"}]","\"m_ActiveTargets\":[{\"m_Id\":\"t\"},{\"m_Id\":\"u\"}]")+"\n{\"m_ObjectId\":\"u\",\"m_Type\":\"UnityEditor.Rendering.Universal.ShaderGraph.UniversalTarget\",\"m_ActiveSubTarget\":{\"m_Id\":\"us\"}}\n{\"m_ObjectId\":\"us\",\"m_Type\":\"UniversalLitSubTarget\"}";
        review=ShaderGraphSource.Inspect(mixed);check(review.sourcePipeline=="Mixed"&&review.target.Contains("StackLit")&&review.target.Contains("UniversalLit"),"Multiple active pipelines retained");
        foreach(string number in new[]{"+3","03","3.",".3"})check(ShaderConversionEngine.Analyze(source.Replace("\"m_SGVersion\":3","\"m_SGVersion\":"+number),"Bad.shadergraph").report.blockers.Any(x=>x.Contains("parse/structure")),"Invalid JSON number rejected");
        check(ShaderConversionEngine.Analyze(source+new string('[',140)+"0"+new string(']',140),"Deep.shadergraph").report.blockers.Any(x=>x.Contains("nesting")),"Deep nesting rejected before stack exhaustion");
        var hosiery=ShaderRuleLibrary.Review("Shader \"Character/Hosiery 丝袜\" {}");check(hosiery.materialCategories.Contains("Hosiery")&&hosiery.rules.Any(x=>x.id=="hosiery-weave"),"Hosiery research category links to its rule");
        return count;
    }
}
