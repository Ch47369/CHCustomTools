using System;
using System.Collections.Generic;
using System.Linq;
using ASEShaderConverter;

// Synthetic contract probes. These test rejection of lost behavior, not rendered equivalence.
internal static class SemanticCompletenessChecks
{
    internal sealed class Probe
    {
        public string id, source, blocker;
        public bool portable;
    }
    internal sealed class Result
    {
        public string id, pipeline, sourcePipeline, status, requiredBlocker;
        public bool expectedCanPlan, actualCanPlan, passed;
        public List<string> blockers, planErrors;
    }
    private static string Source(string expression = "_Tint")
    {
        return "Shader \"Audit/Contract\" { Properties { _Tint (\"Tint\", Color) = (1,0.5,0.25,0.8) } SubShader { Pass { CGPROGRAM\n" +
            "#pragma vertex vertexMain\n#pragma fragment pixelMain\n#include \"UnityCG.cginc\"\n" +
            "struct Mesh { float4 position : POSITION; float2 uv : TEXCOORD0; };\n" +
            "struct Varyings { float4 clip : SV_POSITION; float2 uv : TEXCOORD0; };\n" +
            "Varyings vertexMain(Mesh mesh) { Varyings result; result.clip = UnityObjectToClipPos(mesh.position); result.uv = mesh.uv; return result; }\n" +
            "float4 pixelMain(Varyings data) : SV_Target { return " + expression + "; }\nENDCG } } }";
    }
    public static List<Probe> Probes()
    {
        string basic = Source(), inc = "#include \"UnityCG.cginc\"";
        var probes = new List<Probe>();
        Action<string,string> portable = (id,source) => probes.Add(new Probe { id=id, source=source, portable=true });
        Action<string,string,string> blocked = (id,source,reason) => probes.Add(new Probe { id=id, source=source, blocker=reason });
        portable("constant-color", basic);
        portable("vertex-uv-stage", Source("float4(data.uv,0,1)"));
        portable("known-angle-include", basic.Replace(inc, "#include <UnityCG.cginc>"));
        portable("spaced-entry-pragmas", basic.Replace("#pragma", "# pragma"));
        portable("tabbed-entry-pragmas", basic.Replace("#pragma", "#\tpragma"));
        portable("comments-are-not-directives", basic.Replace(inc, inc + "\n// #include <Missing.cginc>\n/* # pragma multi_compile_fog */"));
        portable("display-name-is-not-directive", basic.Replace("\"Tint\"", "\"# pragma multi_compile_fog\""));
        portable("pure-helper", basic.Replace("struct Mesh", "float4 tint(float4 x) { return x * 0.5; }\nstruct Mesh").Replace("return _Tint;", "return tint(_Tint);"));
        blocked("unknown-quoted-include", basic.Replace(inc, inc + "\n#include \"Missing.cginc\""), "Include needs explicit dependency mapping");
        blocked("unknown-angle-include", basic.Replace(inc, inc + "\n#include <Missing.cginc>"), "Include needs explicit dependency mapping");
        blocked("macro-include", basic.Replace(inc, inc + "\n#include DEPENDENCY_FILE"), "Include operand requires explicit dependency mapping");
        blocked("continued-include", basic.Replace(inc, inc + "\n#include \\\n\"Missing.cginc\""), "Preprocessor line continuation");
        blocked("continued-line-comment", basic.Replace("result.uv = mesh.uv;", "// hidden by continuation \\\nresult.uv = mesh.uv;\n"), "Preprocessor line continuation");
        blocked("include-trailing-tokens", basic.Replace(inc, inc + " MissingTokens"), "Include operand requires explicit dependency mapping");
        blocked("spaced-unknown-include", basic.Replace(inc, inc + "\n# include <Missing.cginc>"), "Include needs explicit dependency mapping");
        blocked("spaced-variant-pragma", basic.Replace(inc, inc + "\n# pragma multi_compile_fog"), "Pragma requires explicit ASE mapping");
        blocked("spaced-target-pragma", basic.Replace(inc, inc + "\n# pragma target 5.0"), "Non-default shader target");
        blocked("spaced-branch", basic.Replace(inc, inc + "\n# if UNKNOWN\n# endif"), "Preprocessor branches");
        blocked("pragma-include-with-pragmas", basic.Replace(inc, inc + "\n# include_with_pragmas \"Variants.hlsl\""), "Preprocessor directive requires explicit mapping");
        blocked("shadow-builtin-transform", basic.Replace("struct Mesh", "float4 UnityObjectToClipPos(float4 x) { return x * 2.0; }\nstruct Mesh"), "Helper/overloaded function");
        blocked("shadow-srp-transform", basic.Replace("UnityObjectToClipPos(mesh.position)", "TransformObjectToHClip(mesh.position.xyz)").Replace("struct Mesh", "float4 TransformObjectToHClip(float3 x) { return float4(x*2.0,1.0); }\nstruct Mesh"), "Helper/overloaded function");
        blocked("shadow-texture-st", basic.Replace("struct Mesh", "float2 TRANSFORM_TEX(float2 x, float2 y) { return x+y; }\nstruct Mesh"), "Helper/overloaded function");
        blocked("duplicate-vertex-entry", basic.Replace("ENDCG", "float4 vertexMain(float4 x) { return x * 2.0; }\nENDCG"), "Entry point requires exactly one definition");
        blocked("duplicate-fragment-entry", basic.Replace("ENDCG", "float4 pixelMain(float4 x) : SV_Target { return x; }\nENDCG"), "Entry point requires exactly one definition");
        blocked("return-before-varying-write", basic.Replace("result.uv = mesh.uv; return result;", "return result; result.uv = mesh.uv;"), "Vertex entry requires");
        blocked("return-before-position-write", basic.Replace("Varyings result; result.clip", "Varyings result; return result; result.clip").Replace("result.uv = mesh.uv; return result;", "result.uv = mesh.uv;"), "Vertex entry requires");
        blocked("duplicate-vertex-return", basic.Replace("return result;", "return result; return result;"), "Vertex entry requires");
        blocked("centroid-interpolation", basic.Replace("float2 uv : TEXCOORD0; };\nVaryings", "centroid float2 uv : TEXCOORD0; };\nVaryings"), "Non-default interpolation");
        blocked("vertex-position-animation", basic.Replace("UnityObjectToClipPos(mesh.position)", "UnityObjectToClipPos(mesh.position * 2.0)"), "Vertex position transformation");
        blocked("vertex-color-stage", basic.Replace("float2 uv : TEXCOORD0; };\nVaryings", "float2 uv : TEXCOORD0; float4 color : COLOR; };\nVaryings").Replace("return result;", "result.color = _Tint; return result;"), "Non-UV vertex assignment");
        blocked("transparent-blending", basic.Replace("Pass {", "Pass { Blend SrcAlpha OneMinusSrcAlpha\n"), "Render state needs ASE mapping");
        blocked("stencil", basic.Replace("Pass {", "Pass { Stencil { Ref 1 Comp Equal }\n"), "Stencil/GrabPass/UsePass");
        blocked("grabpass", basic.Replace("Pass {", "GrabPass {} Pass {"), "Stencil/GrabPass/UsePass");
        blocked("multiple-passes", basic.Replace("Pass {", "Pass {} Pass {"), "Multiple or implicit passes");
        blocked("depth-state", basic.Replace("Pass {", "Pass { ZWrite Off\n"), "Render state needs ASE mapping");
        blocked("mrt", basic.Replace("SV_Target", "SV_Target1"), "Fragment output semantic");
        blocked("discard", basic.Replace("return _Tint;", "discard; return _Tint;"), "clip/discard");
        blocked("hdrp-source-review", basic.Replace("SubShader {", "SubShader { Tags { \"RenderPipeline\"=\"HDRenderPipeline\" }"), "exposure");
        blocked("mixed-source-review", basic.Replace(inc, inc + "\n#include <Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl>\n#include <Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl>"), "Multiple source pipelines");
        return probes;
    }
    public static List<Result> Evaluate()
    {
        var rows = new List<Result>();
        foreach (Probe probe in Probes())
        foreach (string pipeline in new[] { "BuiltIn", "URP", "HDRP" })
        {
            var analysis = ShaderConversionEngine.Analyze(probe.source, probe.id, new ShaderConversionOptions { targetPipeline=pipeline });
            bool expected = probe.portable && pipeline != "HDRP";
            string blocker = probe.portable && pipeline == "HDRP" ? "exposure" : probe.blocker;
            var errors = analysis.report.CanGenerate ? ShaderGraphValidator.Validate(analysis.plan) : new List<string>();
            bool validated = analysis.report.status == "Generated" || analysis.report.aseRoundTripPassed || analysis.report.shaderCompiled || analysis.report.visualComparisonPassed;
            rows.Add(new Result { id=probe.id, pipeline=pipeline, sourcePipeline=analysis.report.sourcePipeline, status=analysis.report.status,
                requiredBlocker=blocker, expectedCanPlan=expected, actualCanPlan=analysis.report.CanGenerate, blockers=analysis.report.blockers, planErrors=errors,
                passed=expected == analysis.report.CanGenerate && errors.Count == 0 && !validated &&
                    (expected || analysis.report.blockers.Any(b => b.Contains(blocker))) });
        }
        return rows;
    }
    public static int Run()
    {
        var rows = Evaluate();
        var failed = rows.Where(r => !r.passed).ToArray();
        if (failed.Length > 0) throw new Exception("Semantic contract audit failed: " + string.Join("; ", failed.Select(r => r.id + "/" + r.pipeline + ": " + string.Join(",", r.blockers))));
        return rows.Count;
    }
}
