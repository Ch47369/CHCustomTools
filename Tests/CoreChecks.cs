using System;
using System.IO;
using System.Linq;
using ASEShaderConverter;

internal static class CoreChecks
{
    private static int checks;
    private static void Check(bool condition, string name) { if (!condition) throw new Exception(name); checks++; }
    private static string Shader(string expression, string extra = "", string properties = "_Tint (\"Tint\", Color) = (1,0.5,0.25,0.8)")
    {
        return "Shader \"Checks/Handwritten\" { Properties { " + properties + " } SubShader { " + extra + @"
Pass { CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#include ""UnityCG.cginc""
struct appdata { float4 vertex : POSITION; float2 uv : TEXCOORD0; };
struct v2f { float4 pos : SV_POSITION; float2 uv : TEXCOORD0; };
v2f vert(appdata v) { v2f o; o.pos = UnityObjectToClipPos(v.vertex); o.uv = v.uv; return o; }
float4 frag(v2f i) : SV_Target { return " + expression + "; } ENDCG } } }";
    }
    public static void Main()
    {
        var simple = ShaderConversionEngine.Analyze(Shader("_Tint * saturate(float4(i.uv,0,1))"));
        Check(simple.report.CanGenerate, string.Join("; ", simple.report.blockers));
        Check(ShaderGraphValidator.Validate(simple.plan).Count == 0, "Planner must produce a valid graph");
        Check(simple.plan.outputs.Count == 2 && simple.plan.outputs.Any(o => o.masterPort == "Alpha"), "Preserve output alpha");
        Check(simple.plan.nodes.All(n => n.type != "CustomExpressionNode" && n.type != "AppendNode"), "Prefer current native nodes");
        var intrinsic = ShaderConversionEngine.Analyze(Shader("float4(exp2(i.uv.x),log2(_Tint.y),rcp(_Tint.z),1)"));
        Check(intrinsic.report.CanGenerate && intrinsic.report.customExpressionCount == 0, "Native intrinsic mappings");
        Check(intrinsic.plan.nodes.Any(n => n.type == "Exp2OpNode") && intrinsic.plan.nodes.Any(n => n.type == "ReciprocalOpNode"), "Correct ASE intrinsic types");
        var tex = ShaderConversionEngine.Analyze(Shader("tex2D(_MainTex,i.uv)", "", "_MainTex (\"Texture\", 2D) = \"gray\" {}"));
        Check(tex.report.CanGenerate && tex.plan.nodes.Any(n => n.type == "TexturePropertyNode") && tex.plan.nodes.Any(n => n.type == "SamplerNode"), "Texture property and explicit UV sampling");
        var custom = ShaderConversionEngine.Analyze(Shader("unknownHelper(_Tint)"));
        Check(!custom.report.CanGenerate && custom.report.customExpressionCount == 0, "Unknown helpers must not become unresolved custom code");
        Check(!ShaderConversionEngine.Analyze(Shader("_Tint", "Blend SrcAlpha OneMinusSrcAlpha")).report.CanGenerate, "Inline render state must not be dropped");
        Check(!ShaderConversionEngine.Analyze(Shader("_Tint").Replace("return _Tint;", "if (i.uv.x > 0) discard; return _Tint;")).report.CanGenerate, "Discard side effects");
        Check(!ShaderConversionEngine.Analyze(Shader("_Tint").Replace("o.uv = v.uv;", "o.uv = unknown(v.uv);")).report.CanGenerate, "Unadapted vertex varying modifications");
        Check(!ShaderConversionEngine.Analyze(Shader("_Tint").Replace("o.uv = v.uv;", "o.uv = v.uv; o.pos = UnityObjectToClipPos(v.vertex * 2);")).report.CanGenerate, "Second vertex transform must not be erased");
        Check(!ShaderConversionEngine.Analyze(Shader("_Tint").Replace("SV_Target", "SV_Target1")).report.CanGenerate, "MRT output requires explicit mapping");
        Check(!ShaderConversionEngine.Analyze(Shader("_Tint").Replace("struct appdata", "float4 _Tint = float4(0,0,0,0); struct appdata")).report.CanGenerate, "Global initializer must not become a material property");
        Check(!ShaderConversionEngine.Analyze(Shader("sin(_Tint)").Replace("struct appdata", "float4 sin(float4 x) { return x * x; } struct appdata")).report.CanGenerate, "Custom intrinsic overload must not map to built-in math");
        Check(!ShaderConversionEngine.Analyze(Shader("float4(1/2,0,0,1)")).report.CanGenerate, "Preserve integer constant division");
        Check(!ShaderConversionEngine.Analyze(Shader("_Tint").Replace("float4 pos : SV_POSITION;", "float4 pos : TEXCOORD1;")).report.CanGenerate, "Position output semantic must be checked");
        Check(!ShaderConversionEngine.Analyze(Shader("_Tint", "Tags { \"RenderType\"=\"TreeOpaque\" }")).report.CanGenerate, "Custom RenderType must not be discarded");
        Check(!ShaderConversionEngine.Analyze(Shader("_Tint").Replace("#pragma fragment frag", "#pragma fragment frag\n#define _Tint float4(1,1,1,1)")).report.CanGenerate, "Macros cannot be erased");
        Check(!ShaderConversionEngine.Analyze(Shader("_Tint").Replace("#pragma fragment frag", "#pragma fragment frag\n#pragma multi_compile_fog")).report.CanGenerate, "Variant suffix detection");
        Check(!ShaderConversionEngine.Analyze(Shader("float4(1,1,1,1)", "", "[HDR] _Tint (\"Tint\", Color) = (1,1,1,1)")).report.CanGenerate, "Property attributes require mapping");
        Check(ShaderConversionEngine.Analyze(Shader("_Tint") + "/*ASEBEGIN ASEEND*/").report.existingAseGraph, "Existing ASE graphs use migration path");
        Check(ShaderConversionEngine.Analyze(Shader("fallback").Replace("return fallback;", "float4 fallback = _Tint; return fallback;")).report.CanGenerate, "HLSL fallback variable must not become ShaderLab Fallback behavior");
        Check(ShaderConversionEngine.Analyze(Shader("_Tint").Replace("Checks/Handwritten", "Checks/Lighting")).report.CanGenerate, "Quoted Shader names must not become ShaderLab directives");
        Check(ShaderConversionEngine.Analyze(Shader("_Tint", "Fog { Mode Linear }").Replace("Checks/Handwritten", "Checks/CGPROGRAM")).report.blockers.Contains("Additional ShaderLab behavior requires an agent plan."), "Quoted program tokens must not hide actual ShaderLab behavior");
        string withFallback = Shader("_Tint");
        Check(!ShaderConversionEngine.Analyze(withFallback.Insert(withFallback.LastIndexOf('}'), " Fallback \"Legacy Shaders/Diffuse\" ")).report.CanGenerate, "Actual ShaderLab Fallback must stay blocked");
        Check(ShaderConversionEngine.Analyze(withFallback.Insert(withFallback.LastIndexOf('}'), " Fallback    Off ")).report.CanGenerate, "Fallback Off allows whitespace without creating a false blocker");
        Check(!ShaderConversionEngine.Analyze(withFallback.Insert(withFallback.LastIndexOf('}'), " CustomEditor \"Checks.Editor\" ")).report.CanGenerate, "Actual ShaderLab CustomEditor must stay blocked");
        var branch = ShaderConversionEngine.Analyze(Shader("float4(uv,0,1)").Replace("return float4(uv,0,1);", "float2 uv = i.uv; if (_Tint.x > 0.5) { uv.x = frac(1.0-uv.x); } else { uv.x = frac(uv.x); } return float4(uv,0,1);"));
        Check(branch.report.CanGenerate && branch.plan.nodes.Any(n => n.type == "ConditionalIfNode"), "Pure local if/else becomes a native If node");
        Check(ShaderGraphValidator.Validate(branch.plan).Count == 0, "Branch and local swizzle reconstruction must produce a valid acyclic graph");
        Check(!ShaderConversionEngine.Analyze(Shader("_Tint").Replace("return _Tint;", "_Tint.x = 0.0; return _Tint;")).report.CanGenerate, "Never rewrite uniforms as local assignments");
        Check(!ShaderConversionEngine.Analyze(Shader("_Tint").Replace("return _Tint;", "const float4 a = _Tint; a.x = 0.0; return a;")).report.CanGenerate, "Reject mutation of const locals");
        Check(!ShaderConversionEngine.Analyze(Shader("_Tint").Replace("return _Tint;", "float4 a = _Tint; if (i.uv.x > 0.5) { a.x = 0.0; } else { a.y = 1.0; } return a;")).report.CanGenerate, "Reject asymmetric branch assignments");
        Check(!ShaderConversionEngine.Analyze(Shader("_Tint").Replace("return _Tint;", "float4 a = _Tint; if (i.uv.x > 0.5) { a.x = 0.0; } return a;")).report.CanGenerate, "Reject branches without explicit else");
        Check(!ShaderConversionEngine.Analyze(Shader("float4(1,1,1,1)", "", "[NoScaleOffset] _Value (\"Value\", Float) = 0")).report.CanGenerate, "NoScaleOffset is only adapted for texture properties");
        Check(!ShaderConversionEngine.Analyze(Shader("float4(1,1,1,1)", "", "[Toggle(MY_KEYWORD)] _Value (\"Value\", Float) = 0")).report.CanGenerate, "Parameterized Toggle attributes stay blocked");
        Check(!ShaderConversionEngine.Analyze(Shader("_Tint", "Cull Front\nCull Back\n")).report.CanGenerate, "Never ignore a conflicting Cull scope override");
        var urp = ShaderConversionEngine.Analyze(Shader("_Tint"), "", new ShaderConversionOptions { targetPipeline = "URP" });
        Check(urp.plan.pipeline == "URP" && urp.report.pipeline == "URP", "Report target pipeline");
        simple.plan.wires.Add(new ShaderWirePlan { from = "missing", to = "missing" });
        Check(ShaderGraphValidator.Validate(simple.plan).Any(e => e.Contains("unknown node")), "Reject missing wire nodes");
        var cycle = new ShaderGraphPlan { shaderName = "Checks/Cycle", pipeline = "BuiltIn" };
        cycle.nodes.Add(new ShaderNodePlan { id = "a", type = "NegateNode" });
        cycle.nodes.Add(new ShaderNodePlan { id = "b", type = "NegateNode" });
        cycle.wires.Add(new ShaderWirePlan { from = "a", to = "b" }); cycle.wires.Add(new ShaderWirePlan { from = "b", to = "a" });
        cycle.outputs.Add(new ShaderOutputPlan { node = "a" });
        Check(ShaderGraphValidator.Validate(cycle).Contains("Graph has a cycle."), "Reject graph cycles");
        cycle.nodes[0].type = "CustomExpressionNode";
        Check(ShaderGraphValidator.Validate(cycle).Any(e => e.Contains("fallback reason")), "Custom code needs native-node justification");
        var togglePlan = new ShaderGraphPlan { shaderName="Checks/Toggle", pipeline="BuiltIn" };
        var toggle = new ShaderNodePlan { id="toggle", type="StaticSwitch", propertyName="_WATER_TEST", propertyKind="Float", value="1" };
        togglePlan.nodes.Add(toggle); togglePlan.outputs.Add(new ShaderOutputPlan {node="toggle",masterPort="Color"});
        Check(ShaderGraphValidator.Validate(togglePlan).Count==0,"Accept a declared local material toggle with a boolean default");
        toggle.value="2";
        Check(ShaderGraphValidator.Validate(togglePlan).Any(e=>e.Contains("StaticSwitch")),"Reject enum values masquerading as boolean keyword defaults");
        toggle.value="0"; toggle.propertyName="_MixedCase";
        Check(ShaderGraphValidator.Validate(togglePlan).Any(e=>e.Contains("StaticSwitch")),"Reject names ASE would silently uppercase and rebind");
        toggle.propertyName="";
        Check(ShaderGraphValidator.Validate(togglePlan).Any(e=>e.Contains("StaticSwitch")),"Reject undeclared material keyword switches");
        var layoutItems = new[] {
            new GraphLayoutItem { id="out",group="output",width=400,height=190 },
            new GraphLayoutItem { id="b",group="math",width=220,height=280 },
            new GraphLayoutItem { id="in",group="input",width=330,height=320 },
            new GraphLayoutItem { id="a",group="math",width=250,height=200 }
        };
        var layoutEdges = new[] { new ShaderWirePlan {from="in",to="a"},new ShaderWirePlan {from="in",to="b"},new ShaderWirePlan {from="a",to="out"},new ShaderWirePlan {from="b",to="out"} };
        ShaderGraphLayout.Arrange(layoutItems,layoutEdges);
        Check(layoutEdges.All(e=>layoutItems.First(n=>n.id==e.from).x+layoutItems.First(n=>n.id==e.from).width < layoutItems.First(n=>n.id==e.to).x),"Layout follows actual dependencies even with shuffled creation order");
        Check(layoutItems.All(a=>layoutItems.All(b=>a==b || a.x+a.width<=b.x || b.x+b.width<=a.x || a.y+a.height<=b.y || b.y+b.height<=a.y)),"Layout must prevent node rectangle overlap with unequal sizes");
        string firstLayout=string.Join(";",layoutItems.Select(n=>n.id+":"+n.x+","+n.y));
        ShaderGraphLayout.Arrange(layoutItems,layoutEdges);
        Check(firstLayout==string.Join(";",layoutItems.Select(n=>n.id+":"+n.x+","+n.y)),"Layout remains deterministic when applied again");
        bool layoutCycle=false;
        try { ShaderGraphLayout.Arrange(layoutItems,layoutEdges.Concat(new[]{new ShaderWirePlan{from="out",to="in"}}).ToArray()); } catch(ArgumentException) { layoutCycle=true; }
        Check(layoutCycle,"Layout rejects cycles rather than dropping dependencies");
        var interleaved = new[] {
            new GraphLayoutItem { id="early",group="normal" },
            new GraphLayoutItem { id="depth",group="depth" },
            new GraphLayoutItem { id="waves",group="waves" },
            new GraphLayoutItem { id="normal",group="normal" },
            new GraphLayoutItem { id="optics",group="optics" }
        };
        var interleavedEdges = new[] {
            new ShaderWirePlan {from="early",to="depth"}, new ShaderWirePlan {from="waves",to="normal"},
            new ShaderWirePlan {from="depth",to="optics"}, new ShaderWirePlan {from="normal",to="optics"}
        };
        ShaderGraphLayout.Arrange(interleaved,interleavedEdges);
        Check(interleaved.Count(n=>n.group=="normal")==2 && interleaved.Select(n=>n.group).Distinct().Count()==4,
            "Independent early group members must not split an acyclic multi-stage water graph into single-node frames");
        Check(interleavedEdges.All(e=>interleaved.First(n=>n.id==e.from).x+300 < interleaved.First(n=>n.id==e.to).x),
            "Contracted group order must keep every interleaved stage dependency moving right");
        var compact = new[] {
            new GraphLayoutItem {id="a",group="math"}, new GraphLayoutItem {id="b",group="math"},
            new GraphLayoutItem {id="c",group="math"}, new GraphLayoutItem {id="lateConstant",group="math"},
            new GraphLayoutItem {id="out",group="math"}
        };
        ShaderGraphLayout.Arrange(compact,new[] {
            new ShaderWirePlan {from="a",to="b"},new ShaderWirePlan {from="b",to="c"},
            new ShaderWirePlan {from="c",to="out"},new ShaderWirePlan {from="lateConstant",to="out"}
        });
        Check(compact.First(n=>n.id=="lateConstant").x==compact.First(n=>n.id=="c").x,
            "Late constants stay beside the consuming operation rather than stretching across every column");
        Check(branch.plan.comments.Count>=3 && branch.plan.nodes.All(n=>!string.IsNullOrEmpty(n.group)),"Source phases retain readable comment groups for branches and output");
        Check(ReviewedUiProfile.Signature(Shader("_Tint"))==ReviewedUiProfile.Signature(Shader("_Tint").Replace("Checks/Handwritten","DifferentName")+"/* comment */"),"Reviewed signatures allow names and comments without changing the shader contract");
        Check(!ShaderConversionEngine.Analyze(Shader("_Tint","Blend SrcAlpha OneMinusSrcAlpha")).report.CanGenerate,"Unreviewed UI shaders remain blocked");
        string directory = Path.GetFullPath("Samples~/Handwritten");
        Check(Directory.Exists(directory), "Run checks from the package workspace");
        foreach (string file in Directory.GetFiles(directory, "*.shader"))
        {
            var result = ShaderConversionEngine.Analyze(File.ReadAllText(file), file);
            if (file.EndsWith("CustomLoop.shader", StringComparison.OrdinalIgnoreCase)) Check(!result.report.CanGenerate && result.report.blockers.Any(b => b.Contains("control flow")), "Loop sample requires an explicit agent graph plan");
            else if (file.EndsWith("HighDefinitionColor.shader", StringComparison.OrdinalIgnoreCase)) Check(!result.report.CanGenerate && result.report.blockers.Any(b => b.Contains("exposure")), "HDRP requires explicit template semantics");
            else Check(result.report.CanGenerate, Path.GetFileName(file) + ": " + string.Join("; ", result.report.blockers));
        }
        checks += ReusableRuleChecks.Run();
        checks += SemanticCompletenessChecks.Run();
        checks += CharacterMaterialChecks.Run();
        checks += ShaderGraphSourceChecks.Run();
        checks += ShaderGraphNativeChecks.Run();
        checks += ShaderLibraryQueryChecks.Run();
        checks += PackageUpdateChecks.Run();
        Console.WriteLine("PASS: " + checks + " checks");
    }
}
