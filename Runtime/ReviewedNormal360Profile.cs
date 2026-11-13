using System;
using System.Linq;
using System.Text.RegularExpressions;

namespace ASEShaderConverter
{
    // This exact reviewed contract includes fog, vertex-stage texture ST and two-sided rendering.
    public static class ReviewedNormal360Profile
    {
        public const string TemplateGuid = "a99d644facf4442398d54acf418923b9";
        public const string SourceSignature = "d90c85c129448fc0acac12a78e0726f7715b13e1a935c1805e5a5a1cee33c4c4";

        internal static bool TryBuild(string scan, ShaderGraphPlan plan, ShaderConversionReport report, ShaderConversionOptions options)
        {
            if (plan.pipeline != "BuiltIn" || plan.surface != "Unlit" || ReviewedUiProfile.Signature(scan) != SourceSignature) return false;
            plan.templateGuid = TemplateGuid;
            var properties = ShaderConversionEngine.ParseProperties(scan, report);
            report.propertyCount = properties.Count;
            try
            {
                Match fragment = Regex.Match(scan, @"fixed4\s+frag\s*\(\s*v2f\s+i\s*\)\s*:\s*SV_Target\s*\{");
                int open = scan.IndexOf('{', fragment.Index), close = ShaderText.FindMatchingBrace(scan, open);
                string body = scan.Substring(open + 1, close - open - 1);
                body = Regex.Replace(body, @"(if\s*\(_FlipHorizontally\s*>\s*0\.5\)\s*\{[^{}]+\})", "$1 else { uv.x = uv.x; }");
                body = Regex.Replace(body, @"UNITY_APPLY_FOG\s*\(\s*i\.fogCoord\s*,\s*col\s*\)\s*;", "");
                new ExpressionGraphBuilder(plan, report, properties, options).Build(body, "i", scan, templateColorPass: "Unlit");
                var output = plan.nodes.First(n => n.id == plan.outputs.Single().node);
                var explanation = plan.comments.FirstOrDefault(c => c.id == output.group);
                if (explanation != null) explanation.text += " 模板先在顶点阶段应用 _MainTex 的缩放/偏移，最终保留 Alpha 并应用 Unity 雾效；双面可见。";
                report.nativeMappings.Add("Reviewed Normal360 profile: native UV/If/sample graph; template preserves vertex TRANSFORM_TEX, Cull Off, LOD 100, default target 2.5, multi_compile_fog, UNITY_TRANSFER_FOG and UNITY_APPLY_FOG.");
                report.warnings.Add("This Normal360 adapter is restricted to the reviewed source signature and requires the converter's two-sided fog template.");
            }
            catch (NotSupportedException e) { report.blockers.Add(e.Message); }
            report.blockers.AddRange(ShaderGraphValidator.Validate(plan));
            report.nativeNodeCount = plan.nodes.Count(n => n.type != "CustomExpressionNode");
            report.status = report.CanGenerate ? "Planned" : "NeedsAgent";
            report.warnings.Add("A plan is not a validated ASE shader. Generate and reload it in the target Unity/ASE environment, then compare rendering with the source.");
            return true;
        }
    }
}
