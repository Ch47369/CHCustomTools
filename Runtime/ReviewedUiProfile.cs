using System;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
using System.Text.RegularExpressions;

namespace ASEShaderConverter
{
    // A reviewed source signature, NOT blanket permission to bypass unsupported UI semantics.
    // Changing any token other than the shader name/comments/whitespace leaves the normal blockers.
    public static class ReviewedUiProfile
    {
        public const string TemplateGuid = "eab467e6cd0b4d27ab8e9e434d8c30e3";
        public const string SourceSignature = "35a270c13137241f646d8a1753db56ef57817917fbd367aa5749b62e8e5e38fb";
        public const string PanZoomTemplateGuid = "c08fd7d51a79449e86b199a5bb4a5724";
        public const string PanZoomSourceSignature = "0330c7672d514bec9ff5937c0aa69e6062088f574588c0fdc8e4aa7cd57e0ea0";
        public static string Signature(string source)
        {
            string canonical = Regex.Replace(ShaderText.RemoveComments(source), @"\bShader\s*""[^""\r\n]+""", "Shader");
            canonical = Regex.Replace(canonical, @"\s+", "");
            using (var hash = SHA256.Create()) return BitConverter.ToString(hash.ComputeHash(Encoding.UTF8.GetBytes(canonical))).Replace("-", "").ToLowerInvariant();
        }
        internal static bool TryBuild(string scan, ShaderGraphPlan plan, ShaderConversionReport report, ShaderConversionOptions options)
        {
            string signature = Signature(scan);
            bool panZoom = signature == PanZoomSourceSignature;
            if (plan.pipeline != "BuiltIn" || plan.surface != "Unlit" || (!panZoom && signature != SourceSignature)) return false;
            plan.templateGuid = panZoom ? PanZoomTemplateGuid : TemplateGuid;
            var templateProperties = new[] { "_MainTex", "_Color", "_StencilComp", "_Stencil", "_StencilOp", "_StencilWriteMask", "_StencilReadMask", "_ColorMask", "_UseUIAlphaClip" };
            if (panZoom) templateProperties = templateProperties.Where(p => p != "_MainTex").ToArray();
            var properties = ShaderConversionEngine.ParseProperties(scan, report, true);
            report.propertyCount = properties.Count;
            try
            {
                Match frag = Regex.Match(scan, @"fixed4\s+frag\s*\(v2f\s+input\)\s*:\s*SV_Target\s*\{");
                int open = scan.IndexOf('{', frag.Index), close = ShaderText.FindMatchingBrace(scan, open);
                string body = scan.Substring(open + 1, close - open - 1);
                body = Regex.Replace(body, @"(if\s*\(_FlipHorizontally > 0\.5\)\s*\{[^{}]+\})", "$1 else { viewUV.x = viewUV.x; }");
                body = Regex.Replace(body, @"color\s*\*=\s*input\.color\s*;", "");
                if (panZoom)
                {
                    body = Regex.Replace(body, @"\*\s*input\.color\s*;", ";");
                    body = Regex.Replace(body, @"color\.a\s*\*=\s*([^;]+);", "color.a = color.a * $1;");
                }
                body = Regex.Replace(body, @"#ifdef\s+UNITY_UI_(?:CLIP_RECT|ALPHACLIP)\b.*?#endif", "", RegexOptions.Singleline);
                new ExpressionGraphBuilder(plan, report, properties.Where(p => !templateProperties.Contains(p.name)).ToList(), options).Build(body, "input", scan, true);
                if (panZoom)
                {
                    var output = plan.nodes.First(n => n.id == plan.outputs.Single().node);
                    var explanation = plan.comments.FirstOrDefault(c => c.id == output.group);
                    if (explanation != null) explanation.text = "采样 _ViewRect 缩放/平移后的纹理；UV 越界时 Alpha 为零。模板继续乘顶点色与 Tint，应用矩形硬裁剪、Alpha Clip、Stencil 和透明混合。";
                }
                report.nativeMappings.Add("Reviewed UI profile: template preserves vertex COLOR * _Color, hard clip, global UI keywords, Stencil, GUI ZTest, ColorMask and straight-alpha blending.");
                foreach (string name in templateProperties) report.nativeMappings.Add("UI template property: " + name);
                report.warnings.Add("This UI adapter is restricted to the reviewed source signature. It uses the converter's hard-clip/straight-alpha UI template; ASE's default UI template has different blending and clipping.");
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
