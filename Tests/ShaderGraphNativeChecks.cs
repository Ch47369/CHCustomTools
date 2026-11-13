using System;
using System.Linq;
using ASEShaderConverter;

internal static class ShaderGraphNativeChecks
{
    public static string Source(string expression, string properties = "_Strength (\"Strength\", Range(0,2)) = 0.5")
    {
        return "Shader \"Checks/NativeSG\" { Properties { "+properties+" } SubShader { Pass { CGPROGRAM\n#pragma vertex vert\n#pragma fragment frag\n#include \"UnityCG.cginc\"\nfloat _Strength; struct appdata { float4 vertex:POSITION; float2 uv:TEXCOORD0; }; struct v2f { float4 pos:SV_POSITION; float2 uv:TEXCOORD0; }; v2f vert(appdata v) { v2f o; o.pos=UnityObjectToClipPos(v.vertex); o.uv=v.uv; return o; } float4 frag(v2f i):SV_Target { return "+expression+"; } ENDCG } } }";
    }
    public static int Run()
    {
        int checks = 0;
        Action<bool,string> check = (ok,name) => { if(!ok) throw new Exception(name); checks++; };
        var options = new ShaderConversionOptions { targetPipeline = "URP", targetGraph = "ShaderGraph", acceptStandardUrpUnlitTarget = true };
        var a = ShaderGraphNativePlanner.Analyze(Source("float4(saturate(_Strength*2.0),0.25,0.75,1.0)"),"test.shader",options);
        check(a.report.CanGenerate,string.Join(";",a.report.blockers));
        check(a.plan.nodes.Any(n => n.type == "MultiplyNode") && a.plan.nodes.Any(n => n.type == "PropertyNode" && n.slider),"Math and slider map to real native SG nodes");
        check(a.plan.nodes.All(n => !n.type.Contains("Custom")),"No HLSL/custom fallback");
        check(ShaderGraphNativePlanner.Validate(a.plan).Count == 0,"Mapped native plan validates");
        check(ShaderGraphNativePlanner.Analyze(Source("float4(i.uv,0.25,1.0)"),"uv.shader",options).report.CanGenerate,"Direct UV forwarding maps");
        var texture=ShaderGraphNativePlanner.Analyze(Source("float4(tex2D(_MainTex,i.uv).rgb,1.0)","_MainTex (\"Texture\", 2D) = \"gray\" {}").Replace("float _Strength;","sampler2D _MainTex;"),"tex.shader",options);
        check(texture.report.CanGenerate,string.Join(";",texture.report.blockers));
        check(texture.plan.nodes.Any(n=>n.propertyKind=="Texture2D" && n.textureDefault=="gray") && texture.plan.nodes.Any(n=>n.type=="SampleTexture2DNode"),"Explicit texture sample and default map");
        string enumProperties = "[KeywordEnum(Base,Detail)] _Mode (\"模式\", Float) = 0";
        var enumSource = Source("lerp(float4(1,0,0,1),float4(0,1,0,1),_Mode)", enumProperties).Replace("float _Strength;", "float _Strength; float _Mode;");
        var enumAnalysis = ShaderGraphNativePlanner.Analyze(enumSource,"enum.shader",options);
        check(enumAnalysis.report.CanGenerate,string.Join(";",enumAnalysis.report.blockers));
        check(enumAnalysis.plan.nodes.Any(n=>n.type=="KeywordNode" && n.keywordReference=="_MODE" && n.keywordEntries.SequenceEqual(new[]{"Base","Detail"})),"ASE Float/Lerp enum lowers to an SG Enum KeywordNode");
        check(!enumAnalysis.plan.nodes.Any(n=>n.type=="PropertyNode" && n.propertyName=="_Mode"),"Enum selector Float is not duplicated as a continuous SG property");
        check(enumAnalysis.plan.nodes.Single(n=>n.type=="KeywordNode").keywordDisplayName=="_Mode" && enumAnalysis.report.warnings.Any(w=>w.Contains("模式")),"Non-ASCII enum label adaptation is explicit in report");
        check(!ShaderConversionEngine.Analyze(enumSource,"enum.shader",new ShaderConversionOptions { targetPipeline="URP" }).report.CanGenerate,"Legacy ASE route keeps unsupported Enum attributes blocked");
        foreach (string declaration in new[]{"[Enum(Base,1,Detail,2)] _Mode (\"模式\", Float) = 1", "[Enum(Base,1,Detail,0)] _Mode (\"模式\", Float) = 0", "[KeywordEnum(Base,Detail)] _Mode (\"模式\", Float) = 0.5", "[KeywordEnum(Base,,Detail)] _Mode (\"模式\", Float) = 0"})
            check(!ShaderGraphNativePlanner.Analyze(enumSource.Replace(enumProperties,declaration),"invalid-enum.shader",options).report.CanGenerate,"Noncanonical enum values/defaults/entries cannot silently become keywords");
        var namedEnum=ShaderGraphNativePlanner.Analyze(enumSource.Replace(enumProperties,"[Enum(Base,0,Detail,1)] _Mode (\"模式\", Float) = 1"),"named-enum.shader",options);
        check(namedEnum.report.CanGenerate && namedEnum.plan.nodes.Single(n=>n.type=="KeywordNode").keywordDefault==1,"Explicit 0/1 Enum and nonzero default lower correctly");
        check(!ShaderGraphNativePlanner.Analyze(enumSource.Replace("return lerp", "float extra=_Mode*0.5; return lerp"),"shared-enum.shader",options).report.CanGenerate,"Enum selector arithmetic use is not dropped");
        string nested=enumSource.Replace(enumProperties,enumProperties+" [KeywordEnum(First,Second)] _Other (\"Other\", Float) = 0").Replace("float _Mode;","float _Mode; float _Other;").Replace("lerp(float4(1,0,0,1),float4(0,1,0,1),_Mode)","lerp(lerp(float4(1,0,0,1),float4(0,1,0,1),_Other),float4(0,0,1,1),_Mode)");
        check(!ShaderGraphNativePlanner.Analyze(nested,"nested-enum.shader",options).report.CanGenerate,"Nested enum selectors require a reviewed Agent plan");
        var keywordPlan = new ShaderGraphNativePlan { acceptStandardUrpUnlitTarget=true, colorNode="mode", colorSlot=0 };
        keywordPlan.nodes.Add(new ShaderGraphNativeNode { id="base", type="Vector3Node", value=new[]{1f,0f,0f} });
        keywordPlan.nodes.Add(new ShaderGraphNativeNode { id="detail", type="Vector3Node", value=new[]{0f,1f,0f} });
        keywordPlan.nodes.Add(new ShaderGraphNativeNode { id="mode", type="KeywordNode", keywordReference="_MODE", keywordEntries=new[]{"Base","Detail"}, keywordEntryReferences=new[]{"BASE","DETAIL"}, keywordDefault=0 });
        keywordPlan.edges.Add(new ShaderGraphNativeEdge { from="base", fromSlot=0, to="mode", toSlot=1 });
        keywordPlan.edges.Add(new ShaderGraphNativeEdge { from="detail", fromSlot=0, to="mode", toSlot=2 });
        check(ShaderGraphNativePlanner.Validate(keywordPlan).Count==0,"Explicit Enum KeywordNode plan validates");
        keywordPlan.nodes[2].keywordEntryReferences[1]="BASE";
        check(ShaderGraphNativePlanner.Validate(keywordPlan).Count>0,"Duplicate Enum keyword references are rejected");
        var continuousLerp = ShaderGraphNativePlanner.Analyze(Source("lerp(float4(1,0,0,1),float4(0,1,0,1),_Strength)"),"continuous.shader",options);
        check(continuousLerp.report.CanGenerate && continuousLerp.plan.nodes.Any(n=>n.type=="LerpNode"),"Ordinary Float/Lerp remains continuous");
        var threeWay = ShaderGraphNativePlanner.Analyze(Source("lerp(float4(1,0,0,1),float4(0,1,0,1),_Mode)","[KeywordEnum(Base,Detail,Accent)] _Mode (\"模式\", Float) = 0").Replace("float _Strength;", "float _Strength; float _Mode;"),"three-way.shader",options);
        check(!threeWay.report.CanGenerate && threeWay.report.blockers.Any(b=>b.Contains("exactly two explicit branches")),"Multi-entry enum Lerp requires an explicit Agent branch plan");
        foreach(string expr in new[]{"float4(1,0,0,0.5)","float4(1,0,0,_Strength)","unknown(_Strength)"}) check(!ShaderGraphNativePlanner.Analyze(Source(expr),"blocked.shader",options).report.CanGenerate,"Unknown or alpha-loss input blocked: "+expr);
        check(!ShaderGraphNativePlanner.Analyze(Source("float4(1,0,0,1)").Replace("o.uv=v.uv","o.uv=sin(v.uv)"),"vertex.shader",options).report.CanGenerate,"Vertex nonlinear arithmetic is not moved to fragment");
        check(!ShaderGraphNativePlanner.Analyze(Source("float4(1,0,0,1)"),"review.shader",new ShaderConversionOptions{targetPipeline="URP"}).report.CanGenerate,"Standard target adaptation is explicit");
        a.plan.edges.Add(new ShaderGraphNativeEdge{from="missing",to=a.plan.colorNode}); check(ShaderGraphNativePlanner.Validate(a.plan).Any(),"Dangling edge rejected"); a.plan.edges.RemoveAt(a.plan.edges.Count-1);
        a.plan.nodes[0].type="System.IO.File"; check(ShaderGraphNativePlanner.Validate(a.plan).Any(),"Arbitrary reflected type blocked");
        return checks;
    }
}
