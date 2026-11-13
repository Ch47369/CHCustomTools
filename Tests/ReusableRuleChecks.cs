using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using ASEShaderConverter;

internal static class ReusableRuleChecks
{
    private static int checks;
    private static void Check(bool ok, string message) { if (!ok) throw new Exception(message); checks++; }
    private static string Source(string expression, string helper = "")
    {
        return "Shader \"Rules/ArbitraryName\" { Properties { _Tint (\"Tint\", Color) = (1,0.5,0.25,0.8) _Map (\"Map\", 2D) = \"white\" {} } SubShader { Pass { CGPROGRAM\n" +
            "#pragma vertex vertexMain\n#pragma fragment pixelMain\n#include \"UnityCG.cginc\"\n" + helper + @"
struct InputMesh { float4 position : POSITION; float2 coords : TEXCOORD1; };
struct RasterData { float4 clip : SV_POSITION; float2 mapping : TEXCOORD0; };
RasterData vertexMain(InputMesh mesh) { RasterData result; result.clip = UnityObjectToClipPos(mesh.position); result.mapping = mesh.coords; return result; }
float4 pixelMain(RasterData data) : SV_Target { return " + expression + "; }\nENDCG } } }";
    }
    private static ShaderConversionAnalysis Plan(string expression, string helper = "")
    {
        var a = ShaderConversionEngine.Analyze(Source(expression, helper));
        Check(a.report.CanGenerate, string.Join("; ", a.report.blockers));
        Check(ShaderGraphValidator.Validate(a.plan).Count == 0, "Invalid reusable-rule graph");
        Check(a.plan.nodes.All(n => n.type != "CustomExpressionNode"), "Arithmetic rules must use native nodes");
        return a;
    }
    private static void Rejected(string expression, string helper, string message)
    {
        Check(!ShaderConversionEngine.Analyze(Source(expression, helper)).report.CanGenerate, message);
    }
    private static void Near(double[] actual, params double[] expected)
    {
        Check(actual.Length == expected.Length && actual.Zip(expected, (a,b) => Math.Abs(a-b) < 1e-6).All(x=>x),
            "Numerical mismatch: " + string.Join(",", actual) + " expected " + string.Join(",", expected));
    }
    public static int Run()
    {
        // Independent arithmetic evaluation checks dataflow and scoping, rather than node names alone.
        var nested = Plan("float4(fold(2.0), fold(3.0), _Tint.z, 1.0)",
            "float squareShift(float number) { float result = number * number; result += 1.0; return result; } " +
            "float fold(float number) { float result = squareShift(number); result *= squareShift(number + 1.0); return result; }");
        Near(EvaluateColor(nested.plan), 50,170,0.25);
        var modifiedParameter = Plan("float4(update(4.0), update(7.0), 0.0, 1.0)", "float update(float value) { value -= 2.0; value /= 2.0; return value; }");
        Near(EvaluateColor(modifiedParameter.plan),1,2.5,0);
        var globalRead = Plan("float4(tintRead(3.0),0.0,0.0,1.0)", "float tintRead(float x) { return _Tint.z * x; }");
        Near(EvaluateColor(globalRead.plan),0.75,0,0);
        var caller = Source("float4(shared, helper(2.0), 0.0, 1.0)", "float helper(float x) { float shared = x + 1.0; return shared; }")
            .Replace("return float4(shared,", "float shared = 9.0; return float4(shared,");
        var callerAnalysis = ShaderConversionEngine.Analyze(caller);
        Check(callerAnalysis.report.CanGenerate,"Helper local cannot overwrite caller local");
        Near(EvaluateColor(callerAnalysis.plan),9,3,0);
        Rejected("float4(helper(1.0),0,0,1)", "float helper(float x) { return callerOnly + x; }", "No caller-local capture");
        Rejected("float4(helper(1.0),0,1)", "float2 helper(float x) { return data.mapping; }", "Helper cannot capture entrypoint varyings");
        Rejected("helper(_Tint)", "float4 helper(float4 x) { _Tint.x = 0.0; return x; }", "No uniform writes inside helper");
        Rejected("helper(_Tint)", "float4 helper(float4 x) { const float4 copy = x; copy.x = 0.0; return copy; }", "No const mutation");
        Rejected("helper(_Tint)", "float4 helper(float4 x) { return helper(x); }", "No recursive helper expansion");
        var overload = Plan("float4(helper(2.0),helper(float2(3.0,4.0)),helper(_Tint).z,1.0)", "float helper(float x) { return x*x; } float helper(float2 x) { return length(x); } float4 helper(float4 x) { return x*2.0; }");
        Near(EvaluateColor(overload.plan),4,5,0.5);
        var chain = Plan("float4(chain(float2(2.0,3.0)),0,0,1)", "float chain(float x) { return x*x; } float chain(float2 x) { return chain(x.x)+chain(x.y); }");
        Near(EvaluateColor(chain.plan),13,0,0);
        Rejected("float4(helper(1.0),0,0,1)", "float helper(float x) { return x; } half helper(half x) { return x; }", "Precision-only overloads cannot be distinguished");
        Rejected("float4(helper(1.0),0,0,1)", "float helper(float x) { return x; } int helper(int x) { return x; }", "An unsupported integer overload cannot be ignored");
        Rejected("float4(helper(1.0),0,0,1)", "float helper(float x) { return x; } float helper(float x) { return x+1.0; }", "Duplicate overload is ambiguous");
        Rejected("float4(helper(float3(1,2,3)),0,0,1)", "float helper(float x) { return x; } float helper(float2 x) { return x.x; }", "No implicit vector overload truncation");
        Rejected("helper(_Tint)", "float4 helper(float4 x) { return tex2D(_Map,x.xy); }", "Hidden texture sampling stays blocked");
        Rejected("helper(_Tint)", "float4 helper(float4 x) { return unknown(x); }", "Unknown nested helper stays blocked");
        Rejected("float4(helper(1.0),0,0,1)", "float helper(float2 x) { return x.x; }", "Argument width mismatch");
        Rejected("float4(helper(1.0),0,0,1)", "float helper(float x) { return float2(x,x); }", "Return width mismatch");
        Rejected("helper(_Tint)", "float4 helper(inout float4 x) { return x; }", "inout requires explicit semantics");
        Rejected("helper(_Tint)", "float4 helper(float4 x) { if(x.x>0.0) { return x; } return x; }", "Helper control flow stays blocked");
        foreach (int iterations in new[]{0,1,3,16})
        {
            string helper = "float accumulate(float seed) { float total=0.0; float amplitude=1.0; for(int octave=0; octave<"+iterations+"; octave++) { total += seed * amplitude; amplitude *= 0.5; } return total; }";
            var a=Plan("float4(accumulate(2.0),0,0,1)",helper);
            Near(EvaluateColor(a.plan),4*(1-Math.Pow(0.5,iterations)),0,0);
        }
        foreach (string loop in new[]{
            "for(int k=0;k<17;k++){ a+=1.0; }",
            "for(int k=0;k<count;k++){ a+=1.0; }",
            "for(int k=0;k<3;k++){ a+=k; }",
            "for(int k=0;k<3;k++){ break; }",
            "for(int k=0;k<3;k++){ float local=1.0; a+=local; }",
            "for(int k=0;k<0;k++){ a+=tex2D(_Map,float2(0,0)).x; }"})
            Rejected("float4(accumulate(1.0),0,0,1)", "float accumulate(float count) { float a=0.0; "+loop+" return a; }", "Unsafe loop must remain blocked: "+loop);
        var fragmentLoop = ShaderConversionEngine.Analyze(Source("float4(a,0,0,1)").Replace("return float4(a,", "float a=1.0; for(int k=2;k<5;k++){ a*=2.0; } return float4(a,"));
        Check(fragmentLoop.report.CanGenerate,"Bounded loops also work in fragment locals");
        Near(EvaluateColor(fragmentLoop.plan),8,0,0);
        var time=Plan("float4(_Time.x,_Time.y,_Time.z,1)");
        Near(EvaluateColor(time.plan),2,40,80);
        var metric=Plan("float4(length(float2(3,4)),distance(float3(1,2,3),float3(1,2,8)),length(_WorldSpaceCameraPos),1)");
        Near(EvaluateColor(metric.plan),5,5,13);
        Rejected("float4(distance(float2(0,0),float3(0,0,0)),0,0,1)","","Mismatched distance widths");
        Rejected("float4(length(_Map),0,0,1)","","Texture is not numeric");
        foreach (string op in new[]{">","<",">=","<=","==","!="})
            foreach (double input in new[]{-1.0,0.0,1.0})
            {
                string x=input.ToString("0.0",CultureInfo.InvariantCulture);
                bool truth=op==">"?input>0:op=="<"?input<0:op==">="?input>=0:op=="<="?input<=0:op=="=="?input==0:input!=0;
                Near(EvaluateColor(Plan("float4(("+x+op+"0.0 ? 7.0 : -3.0),0,0,1)").plan),truth?7:-3,0,0);
            }
        Near(EvaluateColor(Plan("float4(1.0<0.0 ? 9.0 : 2.0>0.0 ? 5.0 : 6.0,0,0,1)").plan),5,0,0);
        Near(EvaluateColor(Plan("float4(select(_Tint).xy,0,1)","float4 select(float4 x) { return x.x >= 1.0 ? x*2.0 : x*3.0; }").plan),2,1,0);
        Rejected("_Tint.x>0.0 ? tex2D(_Map,data.mapping) : _Tint","","Conditional texture sampling must stay blocked");
        Rejected("float4(float2(1,2)>float2(0,0) ? 1.0 : 2.0,0,0,1)","","Vector comparison is not a scalar branch");
        Rejected("float4(1.0>0.0 ? float2(1,2) : 1.0,0,1)","","No implicit conditional type conversions");
        Near(EvaluateColor(Plan("float4((float2)_Tint, float(_Tint.z), 1)").plan),1,0.5,0.25);
        Near(EvaluateColor(Plan("float4((float3)2.0,1)").plan),2,2,2);
        Near(EvaluateColor(Plan("float4((float)1/2.0,1f/2f,1h/4h,1)").plan),0.5,0.5,0.25);
        Rejected("float4((float3)float2(1,2),1)","","Non-scalar vector widening is not a cast");
        Rejected("float4((int)2.5,0,0,1)","","Integer casts require integer semantics");
        Near(EvaluateColor(Plan("float4(fmod(-5.0,2.0),trunc(-1.8),rsqrt(4.0),1)").plan),-1,-1,0.5);
        Near(EvaluateColor(Plan("float4(sign(-3.0),atan2(1.0,0.0),acos(0.0),1)").plan),-1,Math.PI/2,Math.PI/2);
        Near(EvaluateColor(Plan("float4(atan(1.0),asin(1.0),sign(0.0),1)").plan),Math.PI/4,Math.PI/2,0);
        Rejected("float4(1e999,0,0,1)","","Non-finite constants cannot be serialized to ASE");
        Rejected(new string('(',400)+"_Tint"+new string(')',400),"","Deep expressions are diagnosed without stack exhaustion");
        Rejected(string.Join("+",Enumerable.Repeat("_Tint",500)),"","Deep binary ASTs are bounded");
        // SDF rectangle: exercises signed inside/outside distance with native length/min/max helpers.
        string sdf="float boxMetric(float2 p,float2 size) { float2 edge=abs(p)-size; float outside=length(max(edge,0.0)); float inside=min(max(edge.x,edge.y),0.0); return outside+inside; }";
        Near(EvaluateColor(Plan("float4(boxMetric(float2(0,0),float2(1,1)),boxMetric(float2(4,5),float2(1,1)),0,1)",sdf).plan),-1,5,0);
        var st = ShaderConversionEngine.Analyze(Source("tex2D(_Map,data.mapping)").Replace("result.mapping = mesh.coords;","result.mapping = TRANSFORM_TEX(mesh.coords, _Map);"));
        Check(st.report.CanGenerate,"Vertex ST plan: "+string.Join(";",st.report.blockers));
        var uv=st.plan.nodes.Single(n=>n.type=="TextureCoordinatesNode");
        var stage=st.plan.nodes.Single(n=>n.type=="VertexToFragmentNode");
        Check(uv.settings.Any(s=>s.name=="m_textureCoordChannel" && s.value=="1"),"Source TEXCOORD1 preserved");
        Check(st.plan.wires.Any(w=>w.to==uv.id && w.toPort=="Tex" && st.plan.nodes.Single(n=>n.id==w.from).propertyName=="_Map"),"ST uses exact texture property");
        Check(st.plan.wires.Any(w=>w.from==uv.id && w.to==stage.id),"ST computation is interpolated from vertex stage");
        var raw=Plan("tex2D(_Map,data.mapping)");
        Check(!raw.plan.wires.Any(w=>raw.plan.nodes.Single(n=>n.id==w.to).type=="TextureCoordinatesNode" && w.toPort=="Tex"),"Raw UV never acquires implicit ST");
        foreach(string assignment in new[]{"result.mapping = TRANSFORM_TEX(mesh.coords, _Map); result.mapping = mesh.coords;", "result.mapping = mesh.coords; result.mapping = mesh.coords;", "result.mapping = TRANSFORM_TEX(mesh.coords, _Map); result.mapping = TRANSFORM_TEX(mesh.coords, _Map);"})
            Check(!ShaderConversionEngine.Analyze(Source("tex2D(_Map,data.mapping)").Replace("result.mapping = mesh.coords;",assignment)).report.CanGenerate,"Repeated varying writes stay blocked");
        Check(!ShaderConversionEngine.Analyze(Source("tex2D(_Map,data.mapping)").Replace("result.mapping = mesh.coords;","result.mapping = TRANSFORM_TEX(mesh.position, _Map);")).report.CanGenerate,"ST requires UV semantic");
        var animated=ShaderConversionEngine.Analyze(Source("float4(data.mapping,0,1)").Replace("result.mapping = mesh.coords;","result.mapping = mesh.coords + float2(sin(_Time.y),_Tint.x);"));
        Check(animated.report.CanGenerate,"Vertex UV arithmetic: "+string.Join(";",animated.report.blockers));
        Near(EvaluateColor(animated.plan),0.2+Math.Sin(40),1.7,0);
        Check(animated.plan.nodes.Count(n=>n.type=="VertexToFragmentNode")==1,"Vertex UV expression is interpolated once");
        Check(animated.plan.wires.Any(w=>animated.plan.nodes.Single(n=>n.id==w.from).type=="SinOpNode"),"Vertex UV sine remains upstream of interpolator");
        var compoundSt=ShaderConversionEngine.Analyze(Source("tex2D(_Map,data.mapping)").Replace("result.mapping = mesh.coords;","result.mapping = TRANSFORM_TEX(mesh.coords,_Map) + float2(_Time.x,0.0);"));
        Check(compoundSt.report.CanGenerate,"ST and animation compose in original vertex stage");
        Check(!ShaderConversionEngine.Analyze(Source("_Tint").Replace("result.mapping = mesh.coords;","result.mapping = unknown(mesh.coords);")).report.CanGenerate,"Unused unsupported vertex semantics must still block");
        Check(!ShaderConversionEngine.Analyze(Source("float4(data.mapping,0,1)").Replace("result.mapping = mesh.coords;","result.mapping = float2(callerOnly,0.0);").Replace("return float4(data.mapping", "float callerOnly=1.0; return float4(data.mapping")).report.CanGenerate,"Vertex cannot capture fragment locals");
        Check(ShaderConversionEngine.Analyze(Source("_Tint").Replace("Color)","color)")).report.CanGenerate,"Case-insensitive ShaderLab property types");
        var broken=ShaderConversionEngine.Analyze(Source("_Tint")+"/*ASEBEGIN\nVersion=19908");
        Check(!broken.report.CanGenerate && !broken.knowledge.graph.complete,"Incomplete graph is not handwritten input");
        string metadata="/*ASEBEGIN\nVersion=19908\nNode;AmplifyShaderEditor.FunctionNode;1;6f8df4c09ccca5d42b0d3d422aad9cbd\nWireConnection;1;0;2;0\nASEEND*/";
        var graph=ShaderRuleLibrary.Review(metadata).graph;
        Check(graph.complete && graph.nodeCount==1 && graph.wireCount==1 && graph.functionGuids.Single()=="6f8df4c09ccca5d42b0d3d422aad9cbd","Graph dependency inventory");
        Check(ShaderRuleLibrary.Catalog().rules.Select(r=>r.id).Distinct().Count()==ShaderRuleLibrary.Catalog().rules.Count,"Unique persistent rules");
        Check(!ShaderConversionEngine.Analyze(Source("_Tint").Replace("SubShader {", "SubShader { LOD 100 ")).report.CanGenerate,"ShaderLab LOD must not be silently dropped");
        Check(!ShaderConversionEngine.Analyze(Source("_Tint").Replace("_Tint (\"Tint\", Color) = (1,0.5,0.25,0.8)","_Tint (\"Tint\", Color) = (1,0.5,NaN,0.8)")).report.CanGenerate,"Non-finite property defaults are diagnosed");
        Check(!ShaderConversionEngine.Analyze(Source("_Tint").Replace("Properties {", "Properties { _Speed (\"Speed\", Range(0,notANumber)) = 1 ")).report.CanGenerate,"Invalid Range does not throw");
        Check(!ShaderConversionEngine.Analyze(Source("_Tint").Replace("Properties {", "Properties { _Tint (\"Duplicate\", Color) = (1,1,1,1) ")).report.CanGenerate,"Duplicate property does not throw");
        Check(ShaderConversionEngine.Analyze(Source("_Tint").Replace("\"Tint\"", "\"Blend Value Cull Front Stencil\"")).report.CanGenerate,"Property display text is not ShaderLab state");
        Check(ShaderConversionEngine.Analyze(Source("_Tint").Replace("Pass {", "Pass { Name \"Cull Front\"\nBlend Off Cull Back ZWrite On\n")).report.CanGenerate,"Inline standard states and quoted pass names");
        Check(ShaderConversionEngine.Analyze(Source("_Tint").Replace("return _Tint;", "float Blend=1.0; return _Tint * Blend;")).report.CanGenerate,"HLSL local is not ShaderLab Blend");
        Check(!ShaderConversionEngine.Analyze(Source("_Tint").Replace("Pass {", "Pass { Blend Off Cull Back ZTest Always\n")).report.CanGenerate,"An unsupported inline depth state must not disappear");
        foreach(string pipeline in new[]{"BuiltIn","URP"})
            foreach(string cull in new[]{"Front","Off"})
            {
                var opaque=ShaderConversionEngine.Analyze(Source("_Tint").Replace("SubShader {", "SubShader { Tags { \"Queue\"=\"Geometry\" } Cull "+cull+"\n"),"",new ShaderConversionOptions{targetPipeline=pipeline});
                Check(opaque.report.CanGenerate,"Static opaque queue and Cull plan for "+pipeline+"/"+cull);
                Check(opaque.plan.masterSettings.Any(s=>s.name=="template:RenderQueue" && s.value=="Geometry"),"Geometry queue is verified on the real template");
                Check(opaque.plan.masterSettings.Any(s=>s.name==(pipeline=="URP"?"option:Two Sided":"pass:Unlit:Cull") && s.value==(pipeline=="URP"?(cull=="Off"?"On":"Cull Front"):cull)),"Target-specific Cull setting");
            }
        Check(ShaderConversionEngine.DetectPipeline(Source("_Tint").Replace("Rules/ArbitraryName","HDRP/UniversalPipeline"))=="BuiltIn","Quoted shader names do not select a pipeline");
        Check(ShaderConversionEngine.DetectPipeline(Source("_Tint")+"// UniversalPipeline com.unity.render-pipelines.high-definition/")=="BuiltIn","Comments do not select a pipeline");
        string urp=Source("_Tint").Replace("SubShader {", "SubShader { Tags { \"RenderPipeline\"=\"UniversalPipeline\" }")
            .Replace("UnityCG.cginc","Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl")
            .Replace("UnityObjectToClipPos(mesh.position)","TransformObjectToHClip(mesh.position.xyz)").Replace("CGPROGRAM","HLSLPROGRAM").Replace("ENDCG","ENDHLSL");
        foreach(string source in new[]{Source("_Tint"),urp})
        {
            var targets=ShaderConversionEngine.AnalyzeTargets(source);
            Check(targets.Count==3 && targets.Select(a=>a.report.pipeline).SequenceEqual(new[]{"BuiltIn","URP","HDRP"}),"All three targets independently analyzed");
            Check(targets[0].report.CanGenerate && targets[1].report.CanGenerate,"Portable unlit math may target Built-in or URP");
            Check(!targets[2].report.CanGenerate && targets[2].report.blockers.Any(b=>b.Contains("exposure")),"HDRP cannot inherit another pipeline's assumptions");
            Check(targets.All(a=>a.report.sourcePipeline==ShaderConversionEngine.DetectPipeline(source) && a.report.crossPipeline==(a.report.sourcePipeline!=a.report.pipeline)),"Source and target remain separate");
            Check(targets.All(a=>!a.report.aseRoundTripPassed && !a.report.shaderCompiled && !a.report.visualComparisonPassed && a.report.status!="Generated"),"Target analysis never claims generation or validation");
        }
        string hdrp=urp.Replace("UniversalPipeline","HDRenderPipeline").Replace("com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl","com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl");
        Check(ShaderConversionEngine.AnalyzeTargets(hdrp).All(a=>!a.report.CanGenerate && a.report.blockers.Any(b=>b.Contains("exposure"))),"HDRP source semantics remain blockers even for another target");
        string mixed=urp.Replace("\"UniversalPipeline\"","\"UniversalPipeline\" \"RenderPipeline\"=\"HDRenderPipeline\"");
        Check(ShaderConversionEngine.DetectPipeline(mixed)=="Mixed" && ShaderConversionEngine.AnalyzeTargets(mixed).All(a=>!a.report.CanGenerate),"Target selection cannot erase multiple source pipelines");
        var catalog=ShaderRuleLibrary.Catalog();
        Check(catalog.categories.Count==14 && catalog.categories.Select(c=>c.id).Distinct().Count()==14,"Fourteen persistent material/animation categories including Eye and Hosiery");
        Check(catalog.categories.All(c=>c.ruleIds.All(id=>catalog.rules.Any(r=>r.id==id))),"Every category links to a real rule");
        var effects=ShaderRuleLibrary.Review("Shader \"UI/ParticleGlow\" { float2 uv; _Time.y; UIEFFECT_; _TransitionRate; v.vertex.xyz = position; }");
        Check(new[]{"UI","UIEffects","VFX","UVAnimation","VertexAnimation"}.All(c=>effects.materialCategories.Contains(c)),"UI, UI effects, VFX, UV and vertex animations independently classified");
        Check(new[]{"ui-canvas","ui-animation","vfx-particles","uv-animation","vertex-animation"}.All(id=>catalog.rules.Single(r=>r.id==id).implementation=="RecipeRecorded"),"Category inventory does not masquerade as complete conversion support");
        return checks;
    }

    private static double[] EvaluateColor(ShaderGraphPlan plan)
    {
        var values=new Dictionary<string,double[]>();
        Func<string,double[]> eval=null;
        eval=id=> {
            double[] cached;
            if(values.TryGetValue(id,out cached)) return cached;
            var n=plan.nodes.Single(x=>x.id==id);
            var wires=plan.wires.Where(w=>w.to==id).OrderBy(w=>int.Parse(w.toPort,CultureInfo.InvariantCulture)).ToArray();
            double[][] args=wires.Select(w=>eval(w.from)).ToArray();
            double[] result;
            Func<Func<double[],double>,double[]> map=f=>Enumerable.Range(0,args.Max(a=>a.Length)).Select(c=>f(args.Select(a=>a[a.Length==1?0:c]).ToArray())).ToArray();
            switch(n.type) {
                case "ColorNode": result=new[]{1.0,0.5,0.25,0.8}; break;
                case "TimeNode": result=new[]{2.0,40.0,80.0,120.0}; break;
                case "TextureCoordinatesNode": result=new[]{0.2,0.7}; break;
                case "VertexToFragmentNode": result=args[0]; break;
                case "WorldSpaceCameraPos": result=new[]{3.0,4.0,12.0}; break;
                case "RangedFloatNode": result=new[]{double.Parse(n.value,CultureInfo.InvariantCulture)}; break;
                case "DynamicAppendNode": result=args.SelectMany(a=>a).Take(n.outputType=="FLOAT2"?2:n.outputType=="FLOAT3"?3:4).ToArray(); break;
                case "SwizzleNode": result=n.swizzle.Select(c=>args[0]["xyzw".IndexOf(c)]).ToArray(); break;
                case "SimpleAddOpNode": result=map(a=>a[0]+a[1]); break;
                case "SimpleSubtractOpNode": result=map(a=>a[0]-a[1]); break;
                case "SimpleMultiplyOpNode": result=map(a=>a[0]*a[1]); break;
                case "SimpleDivideOpNode": result=map(a=>a[0]/a[1]); break;
                case "SimpleMaxOpNode": result=map(a=>Math.Max(a[0],a[1])); break;
                case "SimpleMinOpNode": result=map(a=>Math.Min(a[0],a[1])); break;
                case "AbsOpNode": result=map(a=>Math.Abs(a[0])); break;
                case "NegateNode": result=map(a=>-a[0]); break;
                case "LengthOpNode": result=new[]{Math.Sqrt(args[0].Sum(x=>x*x))}; break;
                case "DistanceOpNode": result=new[]{Math.Sqrt(args[0].Zip(args[1],(a,b)=>(a-b)*(a-b)).Sum())}; break;
                case "ConditionalIfNode": result=args[args[0][0]>args[1][0]?2:args[0][0]==args[1][0]?3:4]; break;
                case "SignOpNode": result=map(a=>Math.Sign(a[0])); break;
                case "TruncOpNode": result=map(a=>Math.Truncate(a[0])); break;
                case "FmodOpNode": result=map(a=>a[0]%a[1]); break;
                case "RSqrtOpNode": result=map(a=>1/Math.Sqrt(a[0])); break;
                case "ATan2OpNode": result=map(a=>Math.Atan2(a[0],a[1])); break;
                case "ACosOpNode": result=map(a=>Math.Acos(a[0])); break;
                case "ASinOpNode": result=map(a=>Math.Asin(a[0])); break;
                case "ATanOpNode": result=map(a=>Math.Atan(a[0])); break;
                case "SinOpNode": result=map(a=>Math.Sin(a[0])); break;
                default: throw new Exception("Evaluator needs an independent mapping for "+n.type);
            }
            values.Add(id,result); return result;
        };
        return eval(plan.outputs.Single(o=>o.masterPort=="Color").node);
    }
}
