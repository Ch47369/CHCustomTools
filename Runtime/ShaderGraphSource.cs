using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Text;

namespace ASEShaderConverter
{
    [Serializable] public sealed class SourceGraphProperty { public string name, reference, type; public bool exposed; }
    [Serializable] public sealed class SourceGraphBlock { public string descriptor; public bool connected; }
    [Serializable] public sealed class SourceGraphNodeType { public string type; public int count; }
    [Serializable] public sealed class SourceGraphReview
    {
        public string format, status="AnalysisOnly", target="", sourcePipeline="Unknown";
        public int nodeCount, edgeCount, keywordCount, groupCount, noteCount;
        public List<SourceGraphProperty> properties=new List<SourceGraphProperty>();
        public List<SourceGraphBlock> blocks=new List<SourceGraphBlock>();
        public List<SourceGraphNodeType> nodeTypes=new List<SourceGraphNodeType>();
        public List<string> dependencies=new List<string>(), targetSettings=new List<string>(), blockers=new List<string>();
    }

    // Data-only JSON reader: Shader Graph serializes a stream of JSON objects, not one JSON document.
    // Keeping this in Core avoids a Unity/ShaderGraph assembly dependency and never instantiates project code.
    public static class ShaderGraphSource
    {
        static Dictionary<string,object> Map(object o) {return o as Dictionary<string,object> ?? new Dictionary<string,object>();}
        static object Get(object o,string key) {object value;return Map(o).TryGetValue(key,out value)?value:null;}
        static string Str(object o,string key) {return Convert.ToString(Get(o,key),CultureInfo.InvariantCulture)??"";}
        static List<object> List(object o,string key) {return Get(o,key) as List<object> ?? new List<object>();}
        static string Short(string value) {return value.Split('.').Last();}
        public static bool IsGraph(string source) {string scan=source.TrimStart('\uFEFF',' ','\t','\r','\n');return scan.StartsWith("{",StringComparison.Ordinal)&&(scan.Contains("\"m_SGVersion\"")||scan.Contains("\"m_SerializableNodes\"")||scan.Contains("\"m_SerializableEdges\""));}
        public static SourceGraphReview Inspect(string source)
        {
            if(source==null)throw new ArgumentNullException("source");
            var result=new SourceGraphReview();
            var objects=DataJson.ReadStream(source);if(objects.Count==0)throw new FormatException("Empty Shader Graph JSON stream.");
            var root=objects[0];var nodes=new List<object>();var props=new List<object>();var edges=new List<object>();
            if(Get(root,"m_SerializableNodes")!=null)
            {
                result.format="LegacyNestedJson";
                foreach(var row in List(root,"m_SerializableNodes")){var node=Map(DataJson.ReadStream(Str(row,"JSONnodeData")).Single());node["m_Type"]=Str(Get(row,"typeInfo"),"fullName");nodes.Add(node);}
                foreach(var row in List(root,"m_SerializedProperties")){var p=Map(DataJson.ReadStream(Str(row,"JSONnodeData")).Single());p["m_Type"]=Str(Get(row,"typeInfo"),"fullName");props.Add(p);}
                edges=List(root,"m_SerializableEdges");
                result.keywordCount=List(root,"m_SerializedKeywords").Count;result.groupCount=List(root,"m_Groups").Count;result.noteCount=List(root,"m_StickyNotes").Count;
                result.blockers.Add("Legacy Shader Graph master/slot and pipeline-version migration requires an explicit adapter; nested nodes are inventoried without executing project code.");
            }
            else
            {
                result.format="MultiJson";
                var ids=new Dictionary<string,object>(StringComparer.Ordinal);
                foreach(var o in objects){string id=Str(o,"m_ObjectId");if(id.Length==0)continue;if(ids.ContainsKey(id))throw new FormatException("Duplicate Shader Graph object ID: "+id);ids.Add(id,o);}
                foreach(var row in List(root,"m_Nodes")){object node;string id=Str(row,"m_Id");if(!ids.TryGetValue(id,out node))throw new FormatException("Missing Shader Graph node: "+id);nodes.Add(node);}
                foreach(var row in List(root,"m_Properties")){object property;string id=Str(row,"m_Id");if(!ids.TryGetValue(id,out property))throw new FormatException("Missing Shader Graph property: "+id);props.Add(property);}
                edges=List(root,"m_Edges");
                var nodeIds=new HashSet<string>(nodes.Select(n=>Str(n,"m_ObjectId")),StringComparer.Ordinal);
                var driven=new HashSet<string>(StringComparer.Ordinal);
                foreach(var edge in edges)
                {
                    var input=Get(edge,"m_InputSlot");var output=Get(edge,"m_OutputSlot");
                    string to=Str(Get(input,"m_Node"),"m_Id"),from=Str(Get(output,"m_Node"),"m_Id");
                    if(!nodeIds.Contains(to)||!nodeIds.Contains(from))throw new FormatException("Shader Graph edge references a missing node.");
                    string address=to+":"+Str(input,"m_SlotId");if(!driven.Add(address))throw new FormatException("Shader Graph input has multiple sources: "+address);
                    foreach(var pair in new[]{Tuple.Create(to,input),Tuple.Create(from,output)})
                    {
                        var slots=List(ids[pair.Item1],"m_Slots").Select(s=>Str(s,"m_Id")).ToArray();
                        if(!slots.Any(s=>ids.ContainsKey(s)&&Str(ids[s],"m_Id")==Str(pair.Item2,"m_SlotId")))throw new FormatException("Shader Graph edge references a missing slot.");
                    }
                }
                foreach(var node in nodes.Where(n=>Short(Str(n,"m_Type"))=="BlockNode"))result.blocks.Add(new SourceGraphBlock{descriptor=Str(node,"m_SerializedDescriptor"),connected=driven.Any(a=>a.StartsWith(Str(node,"m_ObjectId")+":",StringComparison.Ordinal))});
                // Only inspect active target data. Stale serialized copies are not active settings.
                var pipelines=new HashSet<string>(StringComparer.Ordinal);var subtargets=new List<string>();
                foreach(var t in List(root,"m_ActiveTargets"))
                {
                    object target;if(!ids.TryGetValue(Str(t,"m_Id"),out target)){result.blockers.Add("Missing active target object.");continue;}
                    string type=Str(target,"m_Type");pipelines.Add(type.Contains("HighDefinition")?"HDRP":type.Contains("Universal")?"URP":"Unknown");
                    object sub;if(ids.TryGetValue(Str(Get(target,"m_ActiveSubTarget"),"m_Id"),out sub))subtargets.Add(Short(Str(sub,"m_Type")));
                    var dataTypes=new HashSet<string>(StringComparer.Ordinal);
                    foreach(var datum in List(target,"m_Datas"))
                    {
                        object data;if(!ids.TryGetValue(Str(datum,"m_Id"),out data)){result.blockers.Add("Missing active target data.");continue;}
                        if(!dataTypes.Add(Str(data,"m_Type"))){result.targetSettings.Add("Ignored duplicate data: "+Str(data,"m_Type")+" (HDRP selects first instance)");continue;}
                        foreach(var field in Map(data).Where(kv=>kv.Key!="m_ObjectId"&&kv.Key!="m_Type"&&!(kv.Value is List<object>)&&!(kv.Value is Dictionary<string,object>)))
                            result.targetSettings.Add(Short(Str(data,"m_Type"))+"."+field.Key+"="+Convert.ToString(field.Value,CultureInfo.InvariantCulture));
                    }
                }
                result.sourcePipeline=pipelines.Count==1?pipelines.Single():pipelines.Count>1?"Mixed":"Unknown";
                result.target=string.Join(" | ",subtargets.Distinct().ToArray());
                result.keywordCount=List(root,"m_Keywords").Count;result.groupCount=List(root,"m_GroupDatas").Count+List(root,"m_Groups").Count;result.noteCount=List(root,"m_StickyNoteDatas").Count;
                if(result.target=="")result.blockers.Add("No recognized active Shader Graph subtarget; do not assume Lit or a surface template.");
            }
            foreach(var p in props)result.properties.Add(new SourceGraphProperty{name=Str(p,"m_Name"),reference=Str(p,"m_OverrideReferenceName").Length>0?Str(p,"m_OverrideReferenceName"):Str(p,"m_DefaultReferenceName"),type=Short(Str(p,"m_Type")),exposed=Get(p,"m_GeneratePropertyBlock")==null||Convert.ToBoolean(Get(p,"m_GeneratePropertyBlock"),CultureInfo.InvariantCulture)});
            foreach(var g in nodes.GroupBy(n=>Short(Str(n,"m_Type"))))result.nodeTypes.Add(new SourceGraphNodeType{type=g.Key,count=g.Count()});
            foreach(var n in nodes)
            {
                string type=Short(Str(n,"m_Type"));
                if(type=="SubGraphNode")result.dependencies.Add("SubGraph: "+Str(n,"m_SerializedSubGraph"));
                if(type=="CustomFunctionNode")result.dependencies.Add("CustomFunction: "+Str(n,"m_FunctionName")+" source="+Str(n,"m_FunctionSource")+" sourceType="+Str(n,"m_SourceType"));
            }
            result.nodeCount=nodes.Count;result.edgeCount=edges.Count;
            result.blockers.Add("Shader Graph analysis does not translate BSDF/Pass/state/vertex semantics. An explicit graph plan and target template adapter are required before generation.");
            if(result.dependencies.Count>0)result.blockers.Add("Resolve all subgraph/custom-function GUIDs and host dependencies before conversion.");
            if(result.keywordCount>0)result.blockers.Add("Preserve Shader Graph keyword definitions, scopes, stages and all controlled branches.");
            return result;
        }
        public static ShaderConversionAnalysis Analyze(string source,string path,ShaderConversionOptions options)
        {
            var result=new ShaderConversionAnalysis();var report=result.report;options=options??new ShaderConversionOptions();
            report.sourcePath=path??"";report.status="NeedsAgent";
            try
            {
                var review=Inspect(source);report.sourcePipeline=review.sourcePipeline;report.pipeline=options.targetPipeline=="Auto"?review.sourcePipeline:options.targetPipeline;
                report.crossPipeline=report.sourcePipeline!=report.pipeline;report.blockers.AddRange(review.blockers);
                result.plan.pipeline=report.pipeline;
                string hints=string.Join(" ",review.properties.Select(p=>p.name+" "+p.reference).ToArray())+" "+(path??"")+" "+review.target;
                result.knowledge=ShaderRuleLibrary.Review("Shader \"Source/Graph\" { "+hints+" }");
                result.knowledge.classification="ShaderGraph";result.knowledge.sourceGraph=review;
                result.knowledge.rules.Add(ShaderRuleLibrary.Catalog().rules.Single(r=>r.id=="shadergraph-contract"));
                if(report.crossPipeline)report.blockers.Add("Source "+report.sourcePipeline+" "+review.target+" needs a target-specific lighting/Pass adapter; selecting "+report.pipeline+" does not remove source requirements.");
            }
            catch(Exception e){report.blockers.Add("Shader Graph parse/structure failed: "+e.Message);}
            return result;
        }
    }

    internal sealed class DataJson
    {
        readonly string text;int at;
        DataJson(string source){text=source;}
        void Space(){while(at<text.Length&&(char.IsWhiteSpace(text[at])||text[at]=='\uFEFF'))at++;}
        void Expect(char c){Space();if(at>=text.Length||text[at++]!=c)throw new FormatException("Invalid JSON at "+at);}
        object Value(int depth=0)
        {
            if(depth>128)throw new FormatException("JSON nesting exceeds 128 levels.");
            Space();if(at>=text.Length)throw new FormatException("Unexpected end of JSON.");char c=text[at];
            if(c=='"')return String();
            if(c=='{'){at++;var map=new Dictionary<string,object>(StringComparer.Ordinal);Space();if(at<text.Length&&text[at]=='}'){at++;return map;}while(true){string k=String();Expect(':');if(map.ContainsKey(k))throw new FormatException("Duplicate JSON key "+k);map.Add(k,Value(depth+1));Space();if(at<text.Length&&text[at]=='}'){at++;return map;}Expect(',');}}
            if(c=='['){at++;var list=new List<object>();Space();if(at<text.Length&&text[at]==']'){at++;return list;}while(true){list.Add(Value(depth+1));Space();if(at<text.Length&&text[at]==']'){at++;return list;}Expect(',');}}
            foreach(var literal in new[]{"true","false","null"})if(at+literal.Length<=text.Length&&text.Substring(at,literal.Length)==literal){at+=literal.Length;return literal=="null"?null:(object)(literal=="true");}
            int start=at;while(at<text.Length&&"-+0123456789.eE".IndexOf(text[at])>=0)at++;double number;
            string token=text.Substring(start,at-start);
            if(at==start||!System.Text.RegularExpressions.Regex.IsMatch(token,@"\A-?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?(?:[eE][+-]?[0-9]+)?\z")||!double.TryParse(token,NumberStyles.Float,CultureInfo.InvariantCulture,out number)||double.IsInfinity(number)||double.IsNaN(number))throw new FormatException("Invalid JSON number at "+at);return number;
        }
        string String()
        {
            Expect('"');var s=new StringBuilder();while(at<text.Length){char c=text[at++];if(c=='"')return s.ToString();if(c<' ')throw new FormatException("JSON control character");if(c!='\\'){s.Append(c);continue;}if(at>=text.Length)break;c=text[at++];switch(c){case '"':case '\\':case '/':s.Append(c);break;case 'b':s.Append('\b');break;case 'f':s.Append('\f');break;case 'n':s.Append('\n');break;case 'r':s.Append('\r');break;case 't':s.Append('\t');break;case 'u':if(at+4>text.Length)throw new FormatException("Truncated JSON unicode");s.Append((char)int.Parse(text.Substring(at,4),NumberStyles.HexNumber,CultureInfo.InvariantCulture));at+=4;break;default:throw new FormatException("Unknown JSON escape");}}throw new FormatException("Unterminated JSON string");
        }
        public static List<object> ReadStream(string text){var parser=new DataJson(text);var result=new List<object>();parser.Space();while(parser.at<text.Length){result.Add(parser.Value());parser.Space();}return result;}
    }
}
