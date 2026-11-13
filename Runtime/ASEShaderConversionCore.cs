using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;

namespace ASEShaderConverter
{
    // This assembly plans graphs only. ASE in the host Unity editor owns serialization and code generation.
    [Serializable] public sealed class ShaderConversionOptions
    {
        public string targetPipeline = "Auto"; // Auto, BuiltIn, URP, HDRP
        public string surface = "Unlit"; // Unlit, Lit (agent-authored graphs)
        public string targetGraph = "ASE"; // ASE (legacy default), ShaderGraph
        public bool acceptStandardUrpUnlitTarget;
        public bool keepOriginalShaderName;
        public bool customExpressionFallback = true;
        public GraphPresentationOptions presentation = new GraphPresentationOptions();
    }

    [Serializable] public sealed class NodeSetting
    {
        public string name, value;
        public NodeSetting() { }
        public NodeSetting(string name, string value) { this.name = name; this.value = value; }
    }
    [Serializable] public sealed class CustomInput
    {
        public string name, type = "FLOAT";
    }
    [Serializable] public sealed class ShaderNodePlan
    {
        public string id, type, purpose, fallbackReason;
        public string group = "", label = "";
        public float x, y;
        public string propertyName, displayName, value, propertyKind;
        public string swizzle, code, outputType;
        // Explicit discrete control metadata. ASE keeps the original Float/Lerp;
        // the Shader Graph backend may lower the reviewed pair to an Enum KeywordNode.
        public bool isEnum;
        public string[] enumEntries = new string[0], enumReferences = new string[0];
        public int enumDefault;
        public bool enumSwitch;
        public string enumProperty;
        public float rangeMin, rangeMax;
        public List<NodeSetting> settings = new List<NodeSetting>();
        public List<CustomInput> customInputs = new List<CustomInput>();
    }
    [Serializable] public sealed class ShaderWirePlan
    {
        public string from, fromPort = "0", to, toPort = "0";
    }
    [Serializable] public sealed class ShaderOutputPlan
    {
        public string node, port = "0", masterPort = "Color", pass = "";
    }
    [Serializable] public sealed class ShaderGraphPlan
    {
        public int schemaVersion = 1;
        public string shaderName, pipeline = "Auto", surface = "Unlit", templateGuid = "";
        public List<ShaderNodePlan> nodes = new List<ShaderNodePlan>();
        public List<ShaderWirePlan> wires = new List<ShaderWirePlan>();
        public List<ShaderOutputPlan> outputs = new List<ShaderOutputPlan>();
        public List<NodeSetting> masterSettings = new List<NodeSetting>();
        public GraphPresentationOptions presentation = new GraphPresentationOptions();
        public List<GraphCommentPlan> comments = new List<GraphCommentPlan>();
    }
    [Serializable] public sealed class ShaderConversionReport
    {
        public string status = "Planned", sourcePath = "", outputPath = "", shaderName = "", pipeline = "";
        public string unityVersion = "", aseVersion = "", templateGuid = "";
        public string sourcePipeline = "";
        public bool crossPipeline;
        public bool existingAseGraph, aseRoundTripPassed, shaderCompiled, visualComparisonPassed;
        public string targetGraph = "ASE", shaderGraphVersion = "";
        public bool shaderGraphRoundTripPassed, standardTargetAdaptation;
        public int nativeNodeCount, customExpressionCount, propertyCount;
        public bool layoutApplied;
        public int commentCount, registerNodeCount, getNodeCount;
        public List<string> nativeMappings = new List<string>();
        public List<string> fallbackReasons = new List<string>();
        public List<string> blockers = new List<string>();
        public List<string> warnings = new List<string>();
        public bool CanGenerate { get { return blockers.Count == 0 && !existingAseGraph; } }
    }
    [Serializable] public sealed class ShaderConversionAnalysis
    {
        public ShaderGraphPlan plan = new ShaderGraphPlan();
        public ShaderConversionReport report = new ShaderConversionReport();
        public ShaderKnowledgeReview knowledge = new ShaderKnowledgeReview();
    }

    public static class ShaderConversionEngine
    {
        public static ShaderConversionAnalysis Analyze(string source, string sourcePath = "", ShaderConversionOptions options = null)
        {
            if (source == null) throw new ArgumentNullException("source");
            if (ShaderGraphSource.IsGraph(source)) return ShaderGraphSource.Analyze(source, sourcePath, options);
            options = options ?? new ShaderConversionOptions();
            var result = new ShaderConversionAnalysis();
            var report = result.report;
            var plan = result.plan;
            plan.presentation = options.presentation ?? new GraphPresentationOptions();
            report.sourcePath = sourcePath ?? "";
            string scan = ShaderText.NormalizeDirectives(ShaderText.RemoveComments(source));
            result.knowledge = ShaderRuleLibrary.Review(source);
            Match name = Regex.Match(scan, @"\bShader\s*""([^""]+)""");
            if (!name.Success) report.blockers.Add("ShaderLab Shader name was not found.");
            plan.shaderName = (name.Success ? name.Groups[1].Value : "Converted/Shader") + (options.keepOriginalShaderName ? "" : "_ASE");
            report.shaderName = plan.shaderName;
            report.sourcePipeline = DetectPipeline(scan);
            plan.pipeline = options.targetPipeline == "Auto" ? report.sourcePipeline : options.targetPipeline;
            report.pipeline = plan.pipeline;
            report.crossPipeline = report.sourcePipeline != plan.pipeline;
            if (report.sourcePipeline == "Mixed") report.blockers.Add("Multiple source pipelines require selecting and reviewing each SubShader; a target selection does not resolve source semantics.");
            plan.surface = options.surface;
            if (!new[] { "Auto", "BuiltIn", "URP", "HDRP" }.Contains(plan.pipeline)) report.blockers.Add("Unknown target pipeline: " + plan.pipeline);
            if (source.Contains("/*ASEBEGIN") && source.Contains("ASEEND*/"))
            {
                report.existingAseGraph = true;
                report.status = "ExistingAseGraph";
                report.warnings.Add("The input already contains an ASE graph. Open/migrate it with the installed ASE; do not reconstruct it from generated HLSL.");
                return result;
            }
            if (source.Contains("/*ASEBEGIN"))
            {
                report.blockers.Add("Incomplete ASE graph metadata. Recover the original graph before migration; do not rebuild its generated HLSL.");
                report.status = "NeedsAgent";
                return result;
            }
            // Line splicing precedes comment removal in HLSL; a continued // comment can hide live code.
            // Keep this check on raw text, including before the reviewed-signature adapters.
            if (Regex.IsMatch(source, @"\\[ \t]*\r?\n")) report.blockers.Add("Preprocessor line continuation requires explicit dependency and directive mapping.");
            if (ReviewedUiProfile.TryBuild(scan, plan, report, options)) return result;
            if (ReviewedNormal360Profile.TryBuild(scan, plan, report, options)) return result;
            var properties = ParseProperties(scan, report, allowDiscreteKeywordLowering: options.targetGraph == "ShaderGraph");
            report.propertyCount = properties.Count;
            // Render state and vertex semantics must be represented in the graph, never silently dropped.
            CheckSemantics(scan, plan, report);
            Match pragma = Regex.Match(scan, @"#pragma\s+fragment\s+(\w+)");
            string fragmentName = pragma.Success ? pragma.Groups[1].Value : "frag";
            Match function = Regex.Match(scan, @"\b(?:fixed|half|float)4\s+" + Regex.Escape(fragmentName) + @"\s*\(\s*\w+\s+(\w+)\s*\)\s*(?::[^\{]+)?\{");
            if (!function.Success)
                report.blockers.Add("Automatic planning currently requires one float4/half4/fixed4 fragment with one varying input. Use an agent graph plan for surface outputs or other signatures.");
            else
            {
                if (!Regex.IsMatch(function.Value, @":\s*SV_Target(?:0)?\s*\{$", RegexOptions.IgnoreCase)) report.blockers.Add("Fragment output semantic must be SV_Target or SV_Target0; other render targets require explicit mapping.");
                int open = scan.IndexOf('{', function.Index + function.Length - 1);
                int close = ShaderText.FindMatchingBrace(scan, open);
                if (close < 0) report.blockers.Add("Unbalanced fragment function braces.");
                else
                {
                    string body = scan.Substring(open + 1, close - open - 1);
                    var builder = new ExpressionGraphBuilder(plan, report, properties, options);
                    try { builder.Build(body, function.Groups[1].Value, scan); }
                    catch (NotSupportedException e) { report.blockers.Add(e.Message); }
                }
            }
            report.nativeNodeCount = plan.nodes.Count(n => n.type != "CustomExpressionNode");
            report.customExpressionCount = plan.nodes.Count(n => n.type == "CustomExpressionNode");
            report.status = report.CanGenerate ? "Planned" : "NeedsAgent";
            report.warnings.Add("A plan is not a validated ASE shader. Generate and reload it in the target Unity/ASE environment, then compare rendering with the source.");
            return result;
        }

        // Read-only planning for each target. No Unity API, asset writes or generation.
        public static List<ShaderConversionAnalysis> AnalyzeTargets(string source, string sourcePath = "", ShaderConversionOptions options = null)
        {
            options = options ?? new ShaderConversionOptions();
            return new[] { "BuiltIn", "URP", "HDRP" }.Select(target => Analyze(source, sourcePath, new ShaderConversionOptions {
                targetPipeline = target, surface = options.surface, keepOriginalShaderName = options.keepOriginalShaderName,
                customExpressionFallback = options.customExpressionFallback, presentation = options.presentation
            })).ToList();
        }

        public static string DetectPipeline(string source)
        {
            string scan = ShaderText.RemoveComments(source);
            var detected = new HashSet<string>(StringComparer.Ordinal);
            foreach (string tags in ShaderText.BlocksAfter(ShaderText.MaskPrograms(scan), "Tags"))
                foreach (Match tag in Regex.Matches(tags, @"""RenderPipeline""\s*=\s*""([^""]+)""", RegexOptions.IgnoreCase))
                    detected.Add(tag.Groups[1].Value == "UniversalPipeline" ? "URP" : tag.Groups[1].Value == "HDRenderPipeline" ? "HDRP" : "Unknown");
            foreach (Match include in Regex.Matches(scan, @"(?m)^[ \t]*#\s*include\s*[""<]([^"">]+)["">]"))
            {
                if (include.Groups[1].Value.Contains("com.unity.render-pipelines.high-definition/")) detected.Add("HDRP");
                if (include.Groups[1].Value.Contains("com.unity.render-pipelines.universal/")) detected.Add("URP");
            }
            return detected.Count == 0 ? "BuiltIn" : detected.Count == 1 ? detected.First() : "Mixed";
        }

        internal static List<ShaderProperty> ParseProperties(string scan, ShaderConversionReport report, bool reviewedUi = false, bool allowDiscreteKeywordLowering = false)
        {
            string block = ShaderText.FindBlockAfter(scan, "Properties");
            var list = new List<ShaderProperty>();
            string pattern = @"(?<attrs>(?:\s*\[[^\]]+\])*)\s*(?<name>\w+)\s*\(\s*""(?<display>[^""]*)""\s*,\s*(?<kind>Range\s*\([^)]*\)|2DArray|2D|3D|Cube|Color|Vector|Float|Integer|Int)\s*\)\s*=\s*(?<value>\([^)]*\)|""[^""]*""\s*\{[^}]*\}|[-+\w.]+)";
            foreach (Match m in Regex.Matches(block, pattern, RegexOptions.IgnoreCase))
            {
                var p = new ShaderProperty { name = m.Groups["name"].Value, display = m.Groups["display"].Value, kind = m.Groups["kind"].Value, value = m.Groups["value"].Value, attributes = m.Groups["attrs"].Value.Trim() };
                string canonicalKind = new[] { "2DArray", "2D", "3D", "Cube", "Color", "Vector", "Float", "Integer", "Int" }.FirstOrDefault(k => string.Equals(k, p.kind, StringComparison.OrdinalIgnoreCase));
                if (canonicalKind != null) p.kind = canonicalKind;
                Match range = Regex.Match(p.kind, @"Range\s*\(\s*([^,]+),\s*([^)]+)\)", RegexOptions.IgnoreCase);
                if (range.Success)
                {
                    p.kind = "Range";
                    if (!FiniteNumber(range.Groups[1].Value, out p.min) || !FiniteNumber(range.Groups[2].Value, out p.max)) report.blockers.Add("Invalid finite Range bounds for property: " + p.name);
                }
                Match enumAttribute = Regex.Match(p.attributes, @"\[(?<mode>KeywordEnum|Enum)\s*\((?<body>[^)]*)\)\]", RegexOptions.IgnoreCase);
                if (enumAttribute.Success && allowDiscreteKeywordLowering)
                {
                    p.enumIsKeyword = string.Equals(enumAttribute.Groups["mode"].Value, "KeywordEnum", StringComparison.OrdinalIgnoreCase);
                    ParseDiscreteProperty(p, enumAttribute.Groups["body"].Value, report);
                }
                if (list.Any(previous => previous.name == p.name)) { report.blockers.Add("Duplicate ShaderLab property: " + p.name); continue; }
                float numeric;
                if ((p.kind == "Float" || p.kind == "Range") && !FiniteNumber(p.value, out numeric)) report.blockers.Add("Invalid finite numeric property default: " + p.name);
                if ((p.kind == "Color" || p.kind == "Vector") && (p.value.Trim('(', ')').Split(',').Length != 4 || p.value.Trim('(', ')').Split(',').Any(v => !FiniteNumber(v, out numeric)))) report.blockers.Add("Color/Vector property requires four finite components: " + p.name);
                list.Add(p);
                // ShaderLab Int is a legacy float-backed property; Integer uses real integers.
                if (p.kind == "Int") report.blockers.Add("Legacy ShaderLab Int property " + p.name + " requires an agent to choose the correct float-backed ASE property.");
                if (Regex.Matches(p.attributes, @"\[[^\]]+\]").Cast<Match>().Any(a =>
                    !(a.Value == "[NoScaleOffset]" && (p.kind == "2D" || p.kind == "2DArray")) &&
                    !(a.Value == "[Toggle]" && p.kind == "Float") &&
                    !(p.isEnum && string.Equals(a.Value, enumAttribute.Value, StringComparison.Ordinal)) &&
                    !(reviewedUi && (a.Value == "[HideInInspector]" || (a.Value == "[PerRendererData]" && p.kind == "2D") || (a.Value == "[Toggle(UNITY_UI_ALPHACLIP)]" && p.kind == "Float")))))
                    report.blockers.Add("Property attributes need explicit ASE mapping: " + p.name + " " + p.attributes);
            }
            string remaining = Regex.Replace(block, pattern, "", RegexOptions.IgnoreCase).Trim();
            if (remaining.Length > 0) report.blockers.Add("Unrecognized Properties syntax: " + remaining.Substring(0, Math.Min(100, remaining.Length)));
            return list;
        }

        private static void ParseDiscreteProperty(ShaderProperty property, string body, ShaderConversionReport report)
        {
            if (property.kind != "Float" && property.kind != "Range")
            {
                report.blockers.Add("Shader keyword enum requires a Float/Range property: " + property.name);
                return;
            }
            var entries = new List<string>();
            var references = new List<string>();
            var values = new List<int>();
            string[] tokens = body.Split(',').Select(token => token.Trim()).ToArray();
            if (property.enumIsKeyword)
            {
                foreach (string token in tokens)
                {
                    string reference = SanitizeKeywordReference(token);
                    if (!Regex.IsMatch(token, @"^[A-Za-z_][A-Za-z0-9_]*$") || entries.Contains(token, StringComparer.OrdinalIgnoreCase) || references.Contains(reference, StringComparer.Ordinal))
                    {
                        report.blockers.Add("KeywordEnum entries must be unique identifier-like names: " + property.name);
                        return;
                    }
                    entries.Add(token); references.Add(reference); values.Add(entries.Count - 1);
                }
            }
            else
            {
                if (tokens.Length == 0 || tokens.Length % 2 != 0)
                {
                    report.blockers.Add("Enum requires name/value pairs before it can become a Shader Graph keyword: " + property.name);
                    return;
                }
                for (int i = 0; i < tokens.Length; i += 2)
                {
                    int numeric;
                    if (!int.TryParse(tokens[i + 1], NumberStyles.Integer, CultureInfo.InvariantCulture, out numeric))
                    {
                        report.blockers.Add("Enum values must be integer constants before keyword lowering: " + property.name);
                        return;
                    }
                    string reference = SanitizeKeywordReference(tokens[i]);
                    if (!Regex.IsMatch(tokens[i], @"^[A-Za-z_][A-Za-z0-9_]*$") || entries.Contains(tokens[i], StringComparer.OrdinalIgnoreCase) || references.Contains(reference, StringComparer.Ordinal))
                    {
                        report.blockers.Add("Enum entries must be unique identifier-like names: " + property.name);
                        return;
                    }
                    entries.Add(tokens[i]); references.Add(reference); values.Add(numeric);
                }
            }
            if (entries.Count < 2 || entries.Count > 8)
            {
                report.blockers.Add("Shader Graph Enum Keyword requires 2-8 entries: " + property.name);
                return;
            }
            if (!values.SequenceEqual(Enumerable.Range(0, values.Count)))
            {
                report.blockers.Add("Automatic Enum/Lerp keyword lowering requires sequential values beginning at 0; other values require an Agent plan: " + property.name);
                return;
            }
            float defaultValue;
            if (!FiniteNumber(property.value, out defaultValue))
            {
                report.blockers.Add("Enum selector default must be finite: " + property.name);
                return;
            }
            int selected = values.FindIndex(value => value == defaultValue);
            if (selected < 0)
            {
                report.blockers.Add("Enum default must exactly match a declared entry value: " + property.name);
                return;
            }
            property.enumEntries = entries.ToArray(); property.enumReferences = references.ToArray();
            property.enumDefault = selected;
            property.isEnum = true;
        }

        private static string SanitizeKeywordReference(string value)
        {
            string reference = Regex.Replace(value ?? "", "[^A-Za-z0-9_]", "_").ToUpperInvariant();
            if (reference.Length > 0 && char.IsDigit(reference[0])) reference = "_" + reference;
            return reference;
        }
        private static bool FiniteNumber(string value, out float numeric)
        {
            return float.TryParse(value, NumberStyles.Float, CultureInfo.InvariantCulture, out numeric) && !float.IsNaN(numeric) && !float.IsInfinity(numeric);
        }

        private static void CheckSemantics(string scan, ShaderGraphPlan plan, ShaderConversionReport report)
        {
            if (plan.pipeline == "HDRP" || report.sourcePipeline == "HDRP") report.blockers.Add("HDRP raw fragment output needs an agent plan that explicitly reviews template passes, exposure, fog, blending, and alpha behavior, including when HDRP is the source pipeline.");
            string shaderLabWithStrings = ShaderText.MaskPrograms(scan);
            string shaderLab = ShaderText.MaskBlocks(ShaderText.MaskStrings(shaderLabWithStrings), "Properties");
            var programs = Regex.Matches(scan, "\"(?:\\\\.|[^\"\\\\])*\"|\\b(?<kind>CGPROGRAM|HLSLPROGRAM|CGINCLUDE|HLSLINCLUDE)\\b(?<body>.*?)\\b(?:ENDCG|ENDHLSL)\\b", RegexOptions.Singleline).Cast<Match>().Where(m=>m.Groups["body"].Success).ToArray();
            if (programs.Length != 1 || programs.Any(p=>p.Groups["kind"].Value.EndsWith("INCLUDE", StringComparison.Ordinal))) report.blockers.Add("Automatic planning requires one program block with no additional shared program blocks.");
            if (Regex.Matches(scan, @"#pragma\s+vertex\s+").Count != 1 || Regex.Matches(scan, @"#pragma\s+fragment\s+").Count != 1) report.blockers.Add("Exactly one vertex and fragment entry point must be declared.");
            if (programs.Length == 1)
            {
                string program = programs[0].Groups["body"].Value;
                var functions = new HlslFunctionLibrary(program);
                var entryNames = new HashSet<string>(Regex.Matches(program, @"#pragma\s+(?:vertex|fragment)\s+(\w+)").Cast<Match>().Select(m => m.Groups[1].Value));
                foreach (string entry in entryNames)
                    if (Regex.Matches(program, @"\b\w+\s+" + Regex.Escape(entry) + @"\s*\([^;{}]*\)\s*(?::[^;{}]+)?\{").Count != 1)
                        report.blockers.Add("Entry point requires exactly one definition; overloads need explicit stage mapping: " + entry);
                foreach (Match definition in Regex.Matches(program, @"\b\w+\s+(\w+)\s*\([^;{}]*\)\s*(?::[^;{}]+)?\{"))
                    if (!entryNames.Contains(definition.Groups[1].Value) && !functions.IsAdapted(definition.Groups[1].Value)) report.blockers.Add("Helper/overloaded function needs explicit semantic mapping: " + definition.Groups[1].Value);
                if (ShaderText.RemoveBracedBlocks(program).Contains("=") || Regex.IsMatch(program, @"\b(?:SamplerState|SamplerComparisonState)\s+\w+\s*\{|\bregister\s*\(")) report.blockers.Add("Global initializers, inline sampler states, and explicit registers require an agent plan.");
            }
            if (plan.surface != "Unlit") report.blockers.Add("Automatic fragment conversion targets Unlit. Supply explicit Lit master outputs in an agent graph plan.");
            if (Regex.Matches(shaderLab, @"\bPass\s*\{", RegexOptions.IgnoreCase).Count != 1) report.blockers.Add("Multiple or implicit passes require explicit agent mapping.");
            if (Regex.Matches(shaderLab, @"\bSubShader\s*\{", RegexOptions.IgnoreCase).Count != 1) report.blockers.Add("Multiple SubShaders require explicit agent mapping.");
            if (Regex.IsMatch(shaderLab, @"\b(?:Stencil|GrabPass|UsePass)\b")) report.blockers.Add("Stencil/GrabPass/UsePass requires explicit ASE template settings.");
            if (Regex.IsMatch(scan, @"#pragma\s+(?:multi_compile|shader_feature|surface|geometry|hull|domain)\b")) report.blockers.Add("Shader variants or additional stages require explicit ASE mapping.");
            const string stateNames = "Blend|BlendOp|Cull|ZWrite|ZTest|ColorMask|Offset|AlphaToMask|ZClip|Conservative";
            foreach (Match state in Regex.Matches(shaderLab, @"\b(" + stateNames + @")\b[ \t]*([^\r\n{}]*?)(?=\b(?:" + stateNames + @"|Pass|Tags|LOD|Name|Fallback|CustomEditor|Lighting|Fog|AlphaTest|Dependency)\b|[\r\n{}]|$)", RegexOptions.IgnoreCase))
            {
                string key = state.Groups[1].Value.ToLowerInvariant(), value = state.Groups[2].Value.Trim();
                bool standard = (key == "blend" && value == "Off") || (key == "cull" && value == "Back") || (key == "zwrite" && value == "On") || (key == "ztest" && value == "LEqual") || (key == "colormask" && value == "RGBA") || (key == "offset" && Regex.IsMatch(value, @"^0\s*,\s*0$")) || (key == "alphatomask" && value == "Off");
                if (!standard && plan.pipeline == "BuiltIn" && key == "cull" && new[] { "Front", "Off" }.Contains(value))
                    plan.masterSettings.Add(new NodeSetting("pass:Unlit:Cull", value));
                else if (!standard && plan.pipeline == "URP" && key == "cull" && new[] { "Front", "Off" }.Contains(value))
                    plan.masterSettings.Add(new NodeSetting("option:Two Sided", value == "Off" ? "On" : "Cull Front"));
                else if (!standard) report.blockers.Add("Render state needs ASE mapping: " + state.Value.Trim());
            }
            if (plan.masterSettings.Any(s => s.name == "pass:Unlit:Cull" || s.name == "option:Two Sided") && Regex.Matches(shaderLab, @"\bCull\s+", RegexOptions.IgnoreCase).Count > 1)
                report.blockers.Add("Multiple Cull declarations require explicit pass/subshader scope mapping.");
            if (ShaderText.BlocksAfter(shaderLabWithStrings, "Tags").Any(tags=>Regex.IsMatch(tags, @"""(?:Transparent|TransparentCutout|AlphaTest|Overlay)"""))) report.blockers.Add("Transparency/queue/alpha clipping needs explicit template options and Alpha output.");
            foreach (Match target in Regex.Matches(scan, @"#pragma\s+target\s+([^\r\n]+)"))
            {
                string value = target.Groups[1].Value.Trim();
                if (plan.pipeline == "BuiltIn" && value == "3.5") plan.masterSettings.Add(new NodeSetting("template:ShaderModel", value));
                else if (!new[] { "2.0", "2.5", "3.0" }.Contains(value)) report.blockers.Add("Non-default shader target requires explicit template settings.");
            }
            if (Regex.IsMatch(scan, @"#\s*(?:define|undef|if|ifdef|ifndef|elif|else|endif)\b")) report.blockers.Add("Preprocessor branches and macros require explicit agent mapping.");
            foreach (Match directive in Regex.Matches(scan, @"#\s*(\w+)"))
                if (!new[] { "pragma", "include" }.Contains(directive.Groups[1].Value)) report.blockers.Add("Preprocessor directive requires explicit mapping: " + directive.Value);
            foreach (Match directive in Regex.Matches(scan, @"#pragma\s+(\w+)"))
                if (!new[] { "vertex", "fragment", "target" }.Contains(directive.Groups[1].Value)) report.blockers.Add("Pragma requires explicit ASE mapping: " + directive.Value);
            string programText = string.Join("\n", programs.Select(p => p.Groups["body"].Value).ToArray());
            foreach (Match include in Regex.Matches(programText, @"(?m)^[ \t]*#include\b([^\r\n]*)"))
            {
                Match operand = Regex.Match(include.Groups[1].Value, "^[ \\t]*(?:\"(?<path>[^\"\\r\\n]+)\"|<(?<path>[^>\\r\\n]+)>)[ \\t]*$");
                if (!operand.Success) report.blockers.Add("Include operand requires explicit dependency mapping: " + include.Value.Trim());
                else if (!new[] { "UnityCG.cginc", "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl", "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl" }.Contains(operand.Groups["path"].Value))
                    report.blockers.Add("Include needs explicit dependency mapping: " + operand.Groups["path"].Value);
            }
            // ShaderLab keywords can also be ordinary HLSL identifiers or quoted display names.
            if (Regex.IsMatch(shaderLab, @"\bLOD\s+\d+\b", RegexOptions.IgnoreCase)) report.blockers.Add("ShaderLab LOD selection requires explicit ASE template settings.");
            if (Regex.IsMatch(shaderLab, @"\b(?:Fog|Lighting|AlphaTest|CustomEditor|Dependency)\b|\bFallback\s+(?!\s*Off\b)", RegexOptions.IgnoreCase)) report.blockers.Add("Additional ShaderLab behavior requires an agent plan.");
            foreach (string tags in ShaderText.BlocksAfter(shaderLabWithStrings, "Tags"))
            foreach (Match tag in Regex.Matches(tags, @"""([^""\r\n]+)""\s*=\s*""([^""\r\n]+)"""))
            {
                if (tag.Groups[1].Value == "Queue" && tag.Groups[2].Value == "Geometry" && new[] { "BuiltIn", "URP" }.Contains(plan.pipeline))
                {
                    plan.masterSettings.Add(new NodeSetting("option:Surface", "Opaque"));
                    plan.masterSettings.Add(new NodeSetting("template:RenderQueue", "Geometry"));
                    continue;
                }
                if (!new[] { "RenderPipeline", "RenderType", "LightMode" }.Contains(tag.Groups[1].Value) ||
                    (tag.Groups[1].Value == "RenderType" && tag.Groups[2].Value != "Opaque") ||
                    (tag.Groups[1].Value == "RenderPipeline" && !new[] { "UniversalPipeline", "HDRenderPipeline" }.Contains(tag.Groups[2].Value)) ||
                    (tag.Groups[1].Value == "LightMode" && !new[] { "Always", "SRPDefaultUnlit", "UniversalForward" }.Contains(tag.Groups[2].Value)))
                    report.blockers.Add("Tag needs explicit template mapping: " + tag.Value);
            }
        }
    }

    internal sealed class ShaderProperty
    {
        public string name, display, kind, value, attributes;
        public float min, max;
        public bool isEnum, enumIsKeyword;
        public string[] enumEntries = new string[0], enumReferences = new string[0];
        public int enumDefault;
    }
    internal sealed class GraphValue
    {
        public string id, type, port = "0";
        public GraphValue(string id, string type, string port = "0") { this.id = id; this.type = type; this.port = port; }
    }

    internal sealed class ExpressionGraphBuilder
    {
        private readonly ShaderGraphPlan plan;
        private readonly ShaderConversionReport report;
        private readonly ShaderConversionOptions options;
        private readonly List<ShaderProperty> properties;
        private readonly Dictionary<string, GraphValue> values = new Dictionary<string, GraphValue>(StringComparer.Ordinal);
        private readonly Dictionary<string, string> varyingInputs = new Dictionary<string, string>(StringComparer.Ordinal);
        private readonly Dictionary<string, HlslExpr> varyingExpressions = new Dictionary<string, HlslExpr>(StringComparer.Ordinal);
        private readonly Dictionary<string, GraphValue> varyingValues = new Dictionary<string, GraphValue>(StringComparer.Ordinal);
        private readonly Dictionary<string, string> vertexUvInputs = new Dictionary<string, string>(StringComparer.Ordinal);
        private bool vertexExpression;
        private readonly HashSet<string> locals = new HashSet<string>(StringComparer.Ordinal);
        private readonly HashSet<string> constants = new HashSet<string>(StringComparer.Ordinal);
        private string inputName;
        private HlslFunctionLibrary functions;
        private Dictionary<string, GraphValue> functionGlobals;
        private readonly HashSet<string> activeFunctions = new HashSet<string>(StringComparer.Ordinal);
        private int functionCalls;
        private int expressionDepth;
        public ExpressionGraphBuilder(ShaderGraphPlan p, ShaderConversionReport r, List<ShaderProperty> props, ShaderConversionOptions o) { plan = p; report = r; properties = props; options = o; }

        public void Build(string body, string input, string source, bool reviewedUi = false, string templateColorPass = "")
        {
            inputName = input;
            functions = new HlslFunctionLibrary(source);
            if (reviewedUi || templateColorPass.Length > 0) varyingInputs[input + ".uv"] = "0";
            else DiscoverVaryings(source);
            foreach (ShaderProperty p in properties)
            {
                string type = p.kind == "2D" || p.kind == "2DArray" ? "TexturePropertyNode" : p.kind == "Color" ? "ColorNode" : p.kind == "Vector" ? "Vector4Node" : p.kind == "Integer" ? "IntegerNode" : "RangedFloatNode";
                if (new[] { "Cube", "3D" }.Contains(p.kind) || (p.kind == "2DArray" && plan.pipeline != "BuiltIn")) throw Unsupported("Texture kind requires an agent sampler plan: " + p.kind);
                ShaderNodePlan node = AddNode(type, "Property " + p.name);
                node.group = "properties"; node.label = p.name;
                if (p.kind == "Integer") throw Unsupported("Integer arithmetic requires an agent plan with explicit casts and output types.");
                node.propertyName = p.name; node.displayName = p.display; node.value = p.value; node.propertyKind = p.kind; node.rangeMin = p.min; node.rangeMax = p.max;
                node.isEnum = p.isEnum; node.enumEntries = p.enumEntries; node.enumReferences = p.enumReferences; node.enumDefault = p.enumDefault;
                foreach (Match attribute in Regex.Matches(p.attributes, @"\[([^\]]+)\]"))
                    if (!(p.isEnum && (attribute.Groups[1].Value.StartsWith("KeywordEnum", StringComparison.OrdinalIgnoreCase) || attribute.Groups[1].Value.StartsWith("Enum", StringComparison.OrdinalIgnoreCase))))
                        node.settings.Add(new NodeSetting("attribute:" + attribute.Groups[1].Value, "true"));
                values.Add(p.name, new GraphValue(node.id, p.kind == "2DArray" ? "SAMPLER2DARRAY" : p.kind == "2D" ? "SAMPLER2D" : p.kind == "Color" || p.kind == "Vector" ? "FLOAT4" : p.kind == "Integer" ? "INT" : "FLOAT"));
            }
            plan.comments.Add(new GraphCommentPlan { id = "properties", title = "材质输入", text = "这些属性提供纹理、颜色和参数；属性名与原 Shader 一致。" });
            functionGlobals = new Dictionary<string, GraphValue>(values, StringComparer.Ordinal);
            int vertexStart = plan.nodes.Count;
            foreach (string varying in varyingExpressions.Keys) VertexVarying(varying);
            AddPhase(vertexStart, "顶点 UV 与插值", "在顶点阶段计算原 UV 表达式，再插值到片元；保留纹理 ST、时间分量和源 TEXCOORD 通道。");
            body = HlslFunctionLibrary.ExpandBoundedLoops(body);
            // Only pure local assignments and single-assignment if/else branches are adapted.
            if (Regex.IsMatch(body, @"[#]|\b(?:for|while|switch|clip|discard)\b")) throw Unsupported("Fragment control flow or clip/discard requires an agent plan; preserve its side effects and inputs.");
            bool returned = false;
            int cursor = 0;
            while (cursor < body.Length)
            {
                while (cursor < body.Length && (char.IsWhiteSpace(body[cursor]) || body[cursor] == ';')) cursor++;
                if (cursor == body.Length) break;
                if (returned) throw Unsupported("Statements after return are not supported.");
                int phaseStart = plan.nodes.Count;
                if (Regex.IsMatch(body.Substring(cursor), @"^if\s*\(")) { BuildIf(body, ref cursor); AddPhase(phaseStart, "条件选择", "比较输入并选择分支，更新局部变量；保留相等时的分支结果。"); continue; }
                int semicolon = body.IndexOf(';', cursor);
                if (semicolon < 0) throw Unsupported("Fragment statement is missing a semicolon.");
                string s = body.Substring(cursor, semicolon - cursor).Trim();
                cursor = semicolon + 1;
                if (s.StartsWith("return ", StringComparison.Ordinal))
                {
                    GraphValue value = BuildOrFallback(s.Substring(7));
                    if (Width(value.type) != 4) throw Unsupported("Fragment result must have four components.");
                    if (templateColorPass.Length > 0)
                    {
                        plan.outputs.Add(new ShaderOutputPlan { node = value.id, port = value.port, masterPort = "Color", pass = templateColorPass });
                        AddPhase(phaseStart, "颜色与雾效输出", "保留采样 RGBA；模板使用顶点雾坐标应用 Unity 雾效，保留 Alpha 与双面渲染。");
                        returned = true; continue;
                    }
                    if (reviewedUi)
                    {
                        plan.outputs.Add(new ShaderOutputPlan { node = value.id, port = value.port, masterPort = "Color", pass = "UI" });
                        string explanation = "UI 模板继续乘顶点颜色与 Tint，应用矩形硬裁剪、Alpha Clip、Stencil 和 SrcAlpha 透明混合。";
                        if (phaseStart == plan.nodes.Count)
                        {
                            string group = plan.nodes.First(n => n.id == value.id).group;
                            var comment = plan.comments.FirstOrDefault(c => c.id == group);
                            if (comment != null) comment.text = "按加载状态与图像范围选择备用图或 Tile；模板再应用顶点色、Tint、UI 裁剪、Stencil 和透明混合。";
                        }
                        else AddPhase(phaseStart, "UI 输出", explanation);
                        returned = true; continue;
                    }
                    GraphValue rgb = Swizzle(value, "xyz"), alpha = Swizzle(value, "w");
                    plan.outputs.Add(new ShaderOutputPlan { node = rgb.id, port = rgb.port, masterPort = "Color" });
                    plan.outputs.Add(new ShaderOutputPlan { node = alpha.id, port = alpha.port, masterPort = "Alpha" });
                    plan.masterSettings.Add(new NodeSetting("option:  Keep Alpha", "true"));
                    plan.masterSettings.Add(new NodeSetting("option:Cast Shadows", "false"));
                    if (plan.pipeline == "URP")
                    {
                        plan.masterSettings.Add(new NodeSetting("option:Extra Pre Pass", "false"));
                        plan.masterSettings.Add(new NodeSetting("option:Built-in Fog", "false"));
                        plan.masterSettings.Add(new NodeSetting("option:Receive Shadows", "Force Off"));
                        plan.masterSettings.Add(new NodeSetting("option:Receive SSAO", "false"));
                        plan.masterSettings.Add(new NodeSetting("option:Meta Pass", "false"));
                        plan.masterSettings.Add(new NodeSetting("option:LOD CrossFade", "false"));
                    }
                    AddPhase(phaseStart, "最终颜色与透明度", GraphExplanation.ForExpression(s.Substring(7)) + " 输出到主节点的颜色和 Alpha。");
                    returned = true; continue;
                }
                Match assign = Regex.Match(s, @"^(?:const\s+)?(?:float|half|fixed|int)([1-4])?\s+(\w+)\s*=\s*(.+)$", RegexOptions.Singleline);
                if (!assign.Success)
                {
                    Match update = Regex.Match(s, @"^(\w+(?:\.[xyzwrgba]{1,4})?)\s*([+*/-]?)=\s*(.+)$", RegexOptions.Singleline);
                    if (!update.Success) throw Unsupported("Mutable or unrecognized fragment statement: " + s);
                    string expression = update.Groups[2].Value.Length == 0 ? update.Groups[3].Value : "(" + update.Groups[1].Value + ")" + update.Groups[2].Value + "(" + update.Groups[3].Value + ")";
                    AssignLocal(update.Groups[1].Value, BuildOrFallback(expression));
                    AddPhase(phaseStart, update.Groups[1].Value, GraphExplanation.ForExpression(expression));
                    continue;
                }
                if (values.ContainsKey(assign.Groups[2].Value)) throw Unsupported("Duplicate local declaration: " + s);
                if (Regex.IsMatch(s, @"^(?:const\s+)?int[1-4]?\b")) throw Unsupported("Integer locals require explicit integer nodes and casts.");
                string declared = assign.Groups[1].Success ? "FLOAT" + assign.Groups[1].Value : "FLOAT";
                GraphValue assigned = BuildOrFallback(assign.Groups[3].Value);
                if (Width(assigned.type) != Width(declared)) throw Unsupported("Implicit local type conversion requires an explicit node: " + s);
                values.Add(assign.Groups[2].Value, assigned);
                plan.nodes.First(n => n.id == assigned.id).label = assign.Groups[2].Value;
                AddPhase(phaseStart, assign.Groups[2].Value, GraphExplanation.ForExpression(assign.Groups[3].Value));
                locals.Add(assign.Groups[2].Value);
                if (Regex.IsMatch(s, @"^const\b")) constants.Add(assign.Groups[2].Value);
            }
            if (!returned) throw Unsupported("Fragment return was not found.");
        }

        private void AddPhase(int start, string name, string text)
        {
            if (start == plan.nodes.Count) return;
            string group = "phase" + start;
            foreach (var node in plan.nodes.Skip(start)) if (string.IsNullOrEmpty(node.group)) node.group = group;
            plan.comments.Add(new GraphCommentPlan { id = group, title = name == "条件选择" ? name : "计算 " + name, text = text });
        }

        private void BuildIf(string body, ref int cursor)
        {
            int open = body.IndexOf('(', cursor), close = MatchParenthesis(body, open);
            if (close < 0) throw Unsupported("Unbalanced fragment condition.");
            var condition = ExpressionParser.TryParse(body.Substring(open + 1, close - open - 1)) as BinaryExpr;
            if (condition == null || !new[] { ">", "<", ">=", "<=", "==", "!=" }.Contains(condition.Op)) throw Unsupported("Only scalar comparisons with single local assignments are adapted for if/else.");
            int firstOpen = SkipWhite(body, close + 1);
            if (firstOpen >= body.Length || body[firstOpen] != '{') throw Unsupported("Adapted if/else branches require braces.");
            int firstClose = ShaderText.FindMatchingBrace(body, firstOpen);
            if (firstClose < 0) throw Unsupported("Unbalanced fragment branch.");
            int otherwise = SkipWhite(body, firstClose + 1);
            if (!Regex.IsMatch(body.Substring(otherwise), @"^else\b")) throw Unsupported("An explicit else branch is required.");
            int secondOpen = SkipWhite(body, otherwise + 4);
            if (secondOpen >= body.Length || body[secondOpen] != '{') throw Unsupported("Adapted else branches require braces.");
            int secondClose = ShaderText.FindMatchingBrace(body, secondOpen);
            if (secondClose < 0) throw Unsupported("Unbalanced fragment branch.");
            string first = body.Substring(firstOpen + 1, firstClose - firstOpen - 1), second = body.Substring(secondOpen + 1, secondClose - secondOpen - 1);
            Match a = Regex.Match(first, @"^\s*(\w+(?:\.[xyzwrgba]{1,4})?)\s*=\s*([^;{}]+);\s*$");
            Match b = Regex.Match(second, @"^\s*(\w+(?:\.[xyzwrgba]{1,4})?)\s*=\s*([^;{}]+);\s*$");
            if (!a.Success || !b.Success || a.Groups[1].Value != b.Groups[1].Value || Regex.IsMatch(first + second, @"\b(?:tex\w*|SAMPLE_\w+|UNITY_SAMPLE_\w+)\s*\("))
                throw Unsupported("If/else must assign the same local once in each branch, without texture sampling or side effects.");
            GraphValue selection = BuildConditional(condition, ExpressionParser.TryParse(a.Groups[2].Value), ExpressionParser.TryParse(b.Groups[2].Value));
            AssignLocal(a.Groups[1].Value, selection);
            cursor = secondClose + 1;
        }

        private GraphValue BuildConditional(BinaryExpr condition, HlslExpr yesExpression, HlslExpr noExpression)
        {
            if (condition == null || !new[] { ">", "<", ">=", "<=", "==", "!=" }.Contains(condition.Op) || yesExpression == null || noExpression == null)
                throw Unsupported("Conditional selection requires a scalar comparison and two numeric expressions.");
            if (HasStageSensitiveCall(condition) || HasStageSensitiveCall(yesExpression) || HasStageSensitiveCall(noExpression))
                throw Unsupported("Conditional sampling or derivatives require explicit branch/stage mapping.");
            GraphValue left = BuildExpr(condition.Left), right = BuildExpr(condition.Right);
            GraphValue yes = BuildExpr(yesExpression), no = BuildExpr(noExpression);
            if (Width(left.type) != 1 || Width(right.type) != 1 || Width(yes.type) == 0 || yes.type != no.type) throw Unsupported("If/else requires scalar comparison and matching numeric assignment types.");
            ShaderNodePlan node = AddNode("ConditionalIfNode", "Scalar conditional selection");
            Wire(left, node.id, "0"); Wire(right, node.id, "1");
            for (int category = -1; category <= 1; category++)
            {
                bool truth = condition.Op == ">" ? category > 0 : condition.Op == "<" ? category < 0 : condition.Op == ">=" ? category >= 0 : condition.Op == "<=" ? category <= 0 : condition.Op == "==" ? category == 0 : category != 0;
                Wire(truth ? yes : no, node.id, category == 1 ? "2" : category == 0 ? "3" : "4");
            }
            return new GraphValue(node.id, yes.type);
        }

        private static bool HasStageSensitiveCall(HlslExpr expression)
        {
            var call = expression as CallExpr;
            if (call != null) return Regex.IsMatch(call.Name, @"(?i)^(?:tex|sample_|unity_sample_|ddx|ddy|fwidth)") || call.Arguments.Any(HasStageSensitiveCall);
            var binary = expression as BinaryExpr;
            if (binary != null) return HasStageSensitiveCall(binary.Left) || HasStageSensitiveCall(binary.Right);
            var conditional = expression as ConditionalExpr;
            if (conditional != null) return HasStageSensitiveCall(conditional.Condition) || HasStageSensitiveCall(conditional.Yes) || HasStageSensitiveCall(conditional.No);
            var unary = expression as UnaryExpr;
            if (unary != null) return HasStageSensitiveCall(unary.Value);
            var cast = expression as CastExpr;
            if (cast != null) return HasStageSensitiveCall(cast.Value);
            var member = expression as MemberExpr;
            return member != null && HasStageSensitiveCall(member.Target);
        }

        private void AssignLocal(string target, GraphValue assigned)
        {
            string[] parts = target.Split('.');
            if (!locals.Contains(parts[0]) || constants.Contains(parts[0])) throw Unsupported("Only mutable local variables can be assigned: " + target);
            GraphValue previous = values[parts[0]];
            if (parts.Length == 1)
            {
                if (previous.type != assigned.type) throw Unsupported("Local assignment type mismatch: " + target);
                values[parts[0]] = assigned; return;
            }
            string mask = parts[1].Replace('r', 'x').Replace('g', 'y').Replace('b', 'z').Replace('a', 'w');
            if (mask.Distinct().Count() != mask.Length || mask.Length != Width(assigned.type) || mask.Any(c => "xyzw".IndexOf(c) >= Width(previous.type))) throw Unsupported("Invalid local swizzle assignment: " + target);
            var components = new List<GraphValue>();
            for (int i = 0; i < Width(previous.type); i++)
            {
                int replacement = mask.IndexOf("xyzw"[i]);
                components.Add(replacement < 0 ? Swizzle(previous, "xyzw"[i].ToString()) : mask.Length == 1 ? assigned : Swizzle(assigned, "xyzw"[replacement].ToString()));
            }
            if (components.Count == 1) values[parts[0]] = components[0];
            else
            {
                GraphValue appended = Operation("DynamicAppendNode", components.ToArray(), previous.type);
                plan.nodes.Last().outputType = previous.type;
                values[parts[0]] = appended;
            }
        }

        private static int SkipWhite(string text, int index) { while (index < text.Length && char.IsWhiteSpace(text[index])) index++; return index; }
        private static int MatchParenthesis(string text, int open)
        {
            int depth = 0;
            for (int i = open; i < text.Length; i++) { if (text[i] == '(') depth++; else if (text[i] == ')' && --depth == 0) return i; }
            return -1;
        }

        private void DiscoverVaryings(string source)
        {
            Match vp = Regex.Match(source, @"#pragma\s+vertex\s+(\w+)");
            if (!vp.Success) throw Unsupported("Vertex entry point was not found.");
            Match vf = Regex.Match(source, @"\b(?<result>\w+)\s+" + Regex.Escape(vp.Groups[1].Value) + @"\s*\(\s*(?<inputType>\w+)\s+(?<arg>\w+)\s*\)\s*\{");
            if (!vf.Success) throw Unsupported("Vertex signature requires agent mapping.");
            int start = source.IndexOf('{', vf.Index + vf.Length - 1), end = ShaderText.FindMatchingBrace(source, start);
            if (end < 0) throw Unsupported("Unbalanced vertex function.");
            string body = source.Substring(start + 1, end - start - 1);
            string arg = vf.Groups["arg"].Value;
            string inputStruct = ShaderText.FindBlockAfter(source, "struct " + vf.Groups["inputType"].Value);
            string outputStruct = ShaderText.FindBlockAfter(source, "struct " + vf.Groups["result"].Value);
            if (inputStruct.Length == 0 || outputStruct.Length == 0 || !Regex.IsMatch(outputStruct, @"\b(?:float|half|fixed)4\s+\w+\s*:\s*SV_POSITION\b")) throw Unsupported("Vertex structs require explicit position/interpolator semantics.");
            if (Regex.IsMatch(inputStruct + outputStruct, @"\b(?:nointerpolation|noperspective|centroid|sample)\b")) throw Unsupported("Non-default interpolation requires an agent plan.");
            Match position = Regex.Match(body, @"(?<object>\w+)\s*\.\s*(?<field>\w+)\s*=\s*(?:UnityObjectToClipPos|TransformObjectToHClip)\s*\(\s*" + arg + @"\.(?<source>\w+)(?:\.xyz)?\s*\)\s*;");
            if (!position.Success || !Regex.IsMatch(outputStruct, @"\b" + Regex.Escape(position.Groups["field"].Value) + @"\s*:\s*SV_POSITION\b") || !Regex.IsMatch(inputStruct, @"\b" + Regex.Escape(position.Groups["source"].Value) + @"\s*:\s*POSITION\b") || !Regex.IsMatch(body, @"\breturn\s+" + Regex.Escape(position.Groups["object"].Value) + @"\s*;")) throw Unsupported("Vertex position transformation requires explicit ASE vertex nodes.");
            string outputObject = Regex.Escape(position.Groups["object"].Value);
            if (!Regex.IsMatch(body, @"^\s*" + Regex.Escape(vf.Groups["result"].Value) + @"\s+" + outputObject + @"\s*;") ||
                !Regex.IsMatch(body, @"\breturn\s+" + outputObject + @"\s*;\s*$") || Regex.Matches(body, @"\breturn\b").Count != 1)
                throw Unsupported("Vertex entry requires one output declaration followed by assignments and one final return; early returns need explicit stage mapping.");
            Match fp = Regex.Match(source, @"#pragma\s+fragment\s+(\w+)");
            if (!fp.Success || !Regex.IsMatch(source, @"\b" + Regex.Escape(fp.Groups[1].Value) + @"\s*\(\s*" + Regex.Escape(vf.Groups["result"].Value) + @"\s+")) throw Unsupported("Fragment/vertex varying struct mismatch.");
            foreach (Match uv in Regex.Matches(inputStruct, @"\b(?:float|half|fixed)2\s+(\w+)\s*:\s*TEXCOORD([0-7])\b"))
                vertexUvInputs[arg + "." + uv.Groups[1].Value] = uv.Groups[2].Value;
            var assignments = Regex.Matches(body, @"(?<object>\w+)\s*\.\s*(?<field>\w+)\s*=\s*(?<expression>[^;{}]+);", RegexOptions.Singleline);
            var assignedVaryings = new HashSet<string>(StringComparer.Ordinal);
            string remaining = body;
            foreach (Match assignment in assignments)
            {
                if (assignment.Index == position.Index && assignment.Length == position.Length) { remaining = remaining.Replace(assignment.Value, ""); continue; }
                string target = assignment.Groups["field"].Value;
                if (!assignedVaryings.Add(target)) throw Unsupported("Repeated vertex varying writes require an explicit stage plan: " + target);
                if (assignment.Groups["object"].Value != position.Groups["object"].Value || !Regex.IsMatch(outputStruct, @"\b(?:float|half|fixed)2\s+" + Regex.Escape(target) + @"\s*:\s*TEXCOORD[0-7]\b"))
                    throw Unsupported("Non-UV vertex assignment requires an explicit node plan: " + assignment.Value);
                HlslExpr expression = ExpressionParser.TryParse(assignment.Groups["expression"].Value);
                if (expression == null || HasStageSensitiveCall(expression)) throw Unsupported("Vertex UV expressions must be pure numeric expressions without sampling or derivatives.");
                varyingExpressions[inputName + "." + target] = expression;
                remaining = remaining.Replace(assignment.Value, "");
            }
            string residual = Regex.Replace(remaining, @"\b" + Regex.Escape(vf.Groups["result"].Value) + @"\s+" + Regex.Escape(position.Groups["object"].Value) + @"\s*;|\breturn\s+" + Regex.Escape(position.Groups["object"].Value) + @"\s*;", "").Trim();
            if (residual.Length > 0) throw Unsupported("Vertex modifications/varyings need explicit ASE mapping: " + residual);
        }

        private GraphValue VertexVarying(string name)
        {
            GraphValue cached;
            if (varyingValues.TryGetValue(name, out cached)) return cached;
            var saved = new Dictionary<string, GraphValue>(values, StringComparer.Ordinal);
            string[] savedLocals = locals.ToArray(), savedConstants = constants.ToArray();
            try
            {
                vertexExpression = true; values.Clear(); locals.Clear(); constants.Clear();
                foreach (var binding in functionGlobals) values.Add(binding.Key, binding.Value);
                GraphValue value = BuildExpr(varyingExpressions[name]);
                if (value.type != "FLOAT2") throw Unsupported("Vertex UV varying requires exactly float2: " + name);
                var stage = AddNode("VertexToFragmentNode", "Interpolate vertex UV expression " + name);
                Wire(value, stage.id, "0");
                cached = new GraphValue(stage.id, "FLOAT2"); varyingValues.Add(name, cached);
                return cached;
            }
            finally
            {
                vertexExpression = false; values.Clear(); foreach (var binding in saved) values.Add(binding.Key, binding.Value);
                locals.Clear(); foreach (string local in savedLocals) locals.Add(local);
                constants.Clear(); foreach (string constant in savedConstants) constants.Add(constant);
            }
        }

        private GraphValue BuildOrFallback(string expression)
        {
            HlslExpr ast = ExpressionParser.TryParse(expression);
            if (ast == null) throw Unsupported("Expression syntax requires an agent plan: " + expression);
            return BuildExpr(ast);
        }
        private GraphValue BuildExpr(HlslExpr expr)
        {
            if (++expressionDepth > 128) { expressionDepth--; throw Unsupported("Expression nesting exceeds the 128-level planning limit."); }
            try { return BuildExpression(expr); }
            finally { expressionDepth--; }
        }
        private GraphValue BuildExpression(HlslExpr expr)
        {
            var conditional = expr as ConditionalExpr;
            if (conditional != null) return BuildConditional(conditional.Condition as BinaryExpr, conditional.Yes, conditional.No);
            var cast = expr as CastExpr;
            if (cast != null) return ExplicitCast(BuildExpr(cast.Value), HlslFunctionLibrary.Type(cast.Type));
            var num = expr as NumberExpr;
            if (num != null)
            {
                float numeric;
                if (!float.TryParse(num.Value, NumberStyles.Float, CultureInfo.InvariantCulture, out numeric) || float.IsNaN(numeric) || float.IsInfinity(numeric))
                    throw Unsupported("Numeric literal is invalid or exceeds finite float range: " + num.Value);
                var n = AddNode("RangedFloatNode", "Constant"); n.value = num.Value;
                return new GraphValue(n.id, "FLOAT");
            }
            var id = expr as IdentifierExpr;
            if (id != null)
            {
                GraphValue value;
                if (values.TryGetValue(id.Name, out value)) return value;
                if (id.Name == "_Time" || id.Name == "_WorldSpaceCameraPos")
                {
                    var node = AddNode(id.Name == "_Time" ? "TimeNode" : "WorldSpaceCameraPos", "Unity global " + id.Name);
                    value = new GraphValue(node.id, id.Name == "_Time" ? "FLOAT4" : "FLOAT3");
                    values.Add(id.Name, value); return value;
                }
                throw Unsupported("Unresolved identifier: " + id.Name);
            }
            var member = expr as MemberExpr;
            if (member != null)
            {
                string channel;
                if (!vertexExpression && activeFunctions.Count == 0 && varyingExpressions.ContainsKey(member.Original)) return VertexVarying(member.Original);
                if (vertexExpression && activeFunctions.Count == 0 && vertexUvInputs.TryGetValue(member.Original, out channel))
                {
                    var uv = AddNode("TextureCoordinatesNode", "Vertex UV" + channel); uv.settings.Add(new NodeSetting("m_textureCoordChannel", channel));
                    return new GraphValue(uv.id, "FLOAT2");
                }
                if (activeFunctions.Count == 0 && varyingInputs.TryGetValue(member.Original, out channel))
                {
                    var n = AddNode("TextureCoordinatesNode", "UV" + channel); n.settings.Add(new NodeSetting("m_textureCoordChannel", channel));
                    return new GraphValue(n.id, "FLOAT2");
                }
                return Swizzle(BuildExpr(member.Target), member.Name);
            }
            var unary = expr as UnaryExpr;
            if (unary != null)
            {
                GraphValue value = BuildExpr(unary.Value);
                if (Width(value.type) == 0) throw Unsupported("Unary arithmetic requires a numeric value.");
                if (unary.Op == "+") return value;
                if (unary.Op == "-") return Operation("NegateNode", new[] { value }, value.type);
                throw Unsupported("Unsupported unary operator: " + unary.Op);
            }
            var binary = expr as BinaryExpr;
            if (binary != null)
            {
                if (binary.Op == "/" && IntegralConstant(binary.Left) && IntegralConstant(binary.Right)) throw Unsupported("Integer constant division must preserve HLSL integer arithmetic; supply explicit casts or an agent plan.");
                string type;
                switch (binary.Op) { case "+": type = "SimpleAddOpNode"; break; case "-": type = "SimpleSubtractOpNode"; break; case "*": type = "SimpleMultiplyOpNode"; break; case "/": type = "SimpleDivideOpNode"; break; case "%": throw Unsupported("HLSL remainder requires an explicit semantic choice; fmod and integer remainder differ."); default: throw Unsupported("Comparison requires a native Compare/If node plan."); }
                GraphValue a = BuildExpr(binary.Left), b = BuildExpr(binary.Right);
                return Operation(type, new[] { a, b }, Merge(a.type, b.type));
            }
            var call = expr as CallExpr;
            if (call == null) throw Unsupported("Unrecognized expression.");
            if (call.Name == "TRANSFORM_TEX")
            {
                string channel;
                var meshUv = call.Arguments.Count == 2 ? call.Arguments[0] as MemberExpr : null;
                var texture = call.Arguments.Count == 2 ? call.Arguments[1] as IdentifierExpr : null;
                if (!vertexExpression || activeFunctions.Count > 0 || meshUv == null || texture == null || !vertexUvInputs.TryGetValue(meshUv.Original, out channel) || !properties.Any(p => p.name == texture.Name && p.kind == "2D"))
                    throw Unsupported("TRANSFORM_TEX requires a vertex float2 UV semantic and a declared 2D property.");
                var uv = AddNode("TextureCoordinatesNode", "Vertex TRANSFORM_TEX " + texture.Name);
                uv.settings.Add(new NodeSetting("m_textureCoordChannel", channel)); Wire(values[texture.Name], uv.id, "Tex");
                return new GraphValue(uv.id, "FLOAT2");
            }
            if (functions != null && functions.Contains(call.Name))
            {
                GraphValue[] arguments = call.Arguments.Select(BuildExpr).ToArray();
                return InlineFunction(functions.Resolve(call.Name, arguments.Select(a => a.type).ToArray()), arguments);
            }
            string name = call.Name.ToLowerInvariant();
            if (new[] { "float", "half", "fixed" }.Contains(name))
            {
                if (call.Arguments.Count != 1) throw Unsupported("Scalar constructor requires one numeric argument.");
                return ExplicitCast(BuildExpr(call.Arguments[0]), "FLOAT");
            }
            Match constructor = Regex.Match(name, @"^(?:float|half|fixed)([2-4])$");
            if (constructor.Success)
            {
                int count = int.Parse(constructor.Groups[1].Value, CultureInfo.InvariantCulture);
                var components = new List<GraphValue>();
                foreach (var arg in call.Arguments)
                {
                    GraphValue v = BuildExpr(arg);
                    if (Width(v.type) == 1) components.Add(v);
                    else for (int c = 0; c < Width(v.type); c++) components.Add(Swizzle(v, "xyzw"[c].ToString()));
                }
                if (components.Count == 1) while (components.Count < count) components.Add(components[0]);
                if (components.Count != count) throw Unsupported("Vector constructor component count mismatch.");
                var appended = Operation("DynamicAppendNode", components.ToArray(), "FLOAT" + count);
                plan.nodes.Last().outputType = appended.type; return appended;
            }
            if (name == "tex2dlod" || name == "unity_sample_tex2darray_lod")
            {
                bool array = name == "unity_sample_tex2darray_lod";
                if (call.Arguments.Count != (array ? 3 : 2)) throw Unsupported("Explicit LOD sample argument count mismatch.");
                GraphValue texture = BuildExpr(call.Arguments[0]), coordinates = BuildExpr(call.Arguments[1]);
                if (texture.type != (array ? "SAMPLER2DARRAY" : "SAMPLER2D") || coordinates.type != (array ? "FLOAT3" : "FLOAT4")) throw Unsupported("Explicit LOD texture/coordinate type mismatch.");
                ShaderNodePlan sample = AddNode("SamplerNode", array ? "Texture array LOD sample" : "2D explicit LOD sample");
                sample.settings.Add(new NodeSetting("m_mipMode", "MipLevel"));
                Wire(texture, sample.id, "Tex"); Wire(Swizzle(coordinates, "xy"), sample.id, "UV");
                if (array) Wire(Swizzle(coordinates, "z"), sample.id, "Index");
                GraphValue lod = array ? BuildExpr(call.Arguments[2]) : Swizzle(coordinates, "w");
                if (lod.type != "FLOAT") throw Unsupported("Texture LOD must be scalar.");
                Wire(lod, sample.id, "Level");
                return new GraphValue(sample.id, "FLOAT4");
            }
            if (name == "tex2d" || name == "sample_texture2d")
            {
                int expected = name == "tex2d" ? 2 : 3;
                if (call.Arguments.Count != expected) throw Unsupported("Texture sampling argument count mismatch.");
                GraphValue texture = BuildExpr(call.Arguments[0]);
                if (texture.type != "SAMPLER2D") throw Unsupported("tex2D requires a texture object input.");
                if (expected == 3)
                {
                    var texId = call.Arguments[0] as IdentifierExpr; var samplerId = call.Arguments[1] as IdentifierExpr;
                    if (texId == null || samplerId == null || samplerId.Name != "sampler" + texId.Name) throw Unsupported("Non-default sampler state requires an explicit Sampler State node.");
                }
                GraphValue uv = BuildExpr(call.Arguments[expected - 1]);
                if (uv.type != "FLOAT2") throw Unsupported("tex2D requires float2 coordinates.");
                var n = AddNode("SamplerNode", "Texture sample"); Wire(texture, n.id, "0"); Wire(uv, n.id, "1");
                return new GraphValue(n.id, "FLOAT4");
            }
            string[] funcs = { "length:LengthOpNode:1", "distance:DistanceOpNode:2", "saturate:SaturateNode:1", "abs:AbsOpNode:1", "normalize:NormalizeNode:1", "sin:SinOpNode:1", "cos:CosOpNode:1", "tan:TanOpNode:1", "sqrt:SqrtOpNode:1", "frac:FractNode:1", "floor:FloorOpNode:1", "round:RoundOpNode:1", "ceil:CeilOpNode:1", "pow:PowerNode:2", "lerp:LerpOp:3", "dot:DotProductOpNode:2", "cross:CrossProductOpNode:2", "min:SimpleMinOpNode:2", "max:SimpleMaxOpNode:2", "step:StepOpNode:2", "smoothstep:SmoothstepOpNode:3", "clamp:ClampOpNode:3", "exp:ExpOpNode:1", "exp2:Exp2OpNode:1", "log:LogOpNode:1", "log2:Log2OpNode:1", "log10:Log10OpNode:1", "rcp:ReciprocalOpNode:1", "rsqrt:RSqrtOpNode:1", "sign:SignOpNode:1", "trunc:TruncOpNode:1", "fmod:FmodOpNode:2", "atan:ATanOpNode:1", "atan2:ATan2OpNode:2", "asin:ASinOpNode:1", "acos:ACosOpNode:1" };
            string[] mapping = funcs.Select(f => f.Split(':')).FirstOrDefault(f => f[0] == name);
            if (mapping != null)
            {
                if (call.Arguments.Count != int.Parse(mapping[2], CultureInfo.InvariantCulture)) throw Unsupported("Function argument count mismatch: " + name);
                GraphValue[] args = call.Arguments.Select(BuildExpr).ToArray();
                if (args.Any(a => Width(a.type) == 0)) throw Unsupported("Math intrinsics require scalar/vector numeric inputs: " + name);
                if ((name == "dot" || name == "distance") && args[0].type != args[1].type) throw Unsupported(name + " requires matching input widths.");
                if (name == "lerp" && args.Length == 3 && call.Arguments[2] is IdentifierExpr)
                {
                    ShaderNodePlan selector = plan.nodes.FirstOrDefault(node => node.id == args[2].id && node.isEnum);
                    if (selector != null)
                    {
                        if (selector.enumEntries == null || selector.enumEntries.Length != 2)
                            throw Unsupported("An Enum-controlled Lerp needs exactly two explicit branches; nested/multi-entry enum lowering requires an Agent plan.");
                        var keywordLerp = AddNode("LerpOp", "Enum Float/Lerp → Shader Graph Keyword");
                        keywordLerp.enumSwitch = true; keywordLerp.enumProperty = selector.propertyName;
                        keywordLerp.enumEntries = selector.enumEntries; keywordLerp.enumReferences = selector.enumReferences; keywordLerp.enumDefault = selector.enumDefault;
                        Wire(args[0], keywordLerp.id, "0"); Wire(args[1], keywordLerp.id, "1"); Wire(args[2], keywordLerp.id, "2");
                        return new GraphValue(keywordLerp.id, Merge(args[0].type, args[1].type));
                    }
                }
                // ASE Smoothstep orders Value, Min, Max; HLSL orders Min, Max, Value.
                if (name == "smoothstep") args = new[] { args[2], args[0], args[1] };
                string output = name == "dot" || name == "length" || name == "distance" ? "FLOAT" : args.Select(a => a.type).Aggregate(Merge);
                if (name == "cross" && args.Any(a => a.type != "FLOAT3")) throw Unsupported("cross requires float3 inputs.");
                return Operation(mapping[1], args, output);
            }
            // Unknown helper functions require an agent to supply explicit inputs and a reason why
            // the installed ASE native nodes cannot express them. Never paste unresolved HLSL.
            throw Unsupported("Function requires a native node mapping or a self-contained Custom Expression with explicit inputs: " + call.Name);
        }
        private GraphValue Swizzle(GraphValue value, string mask)
        {
            string normalized = mask.Replace('r', 'x').Replace('g', 'y').Replace('b', 'z').Replace('a', 'w');
            if (normalized.Length < 1 || normalized.Length > 4 || normalized.Any(c => "xyzw".IndexOf(c) < 0 || "xyzw".IndexOf(c) >= Width(value.type))) throw Unsupported("Invalid swizzle: " + mask);
            var n = AddNode("SwizzleNode", "Swizzle " + mask); n.swizzle = normalized; n.outputType = Type(normalized.Length); Wire(value, n.id, "0");
            return new GraphValue(n.id, n.outputType);
        }
        private GraphValue ExplicitCast(GraphValue value, string target)
        {
            int from = Width(value.type), to = Width(target);
            if (from == 0 || to == 0 || (from != 1 && to > from)) throw Unsupported("Explicit cast requires numeric truncation or scalar splat: " + value.type + " to " + target);
            if (from == to) return value;
            if (from > to) return Swizzle(value, "xyzw".Substring(0, to));
            GraphValue result = Operation("DynamicAppendNode", Enumerable.Repeat(value, to).ToArray(), target);
            plan.nodes.Last().outputType = target;
            return result;
        }
        private GraphValue Operation(string type, GraphValue[] args, string output)
        {
            var n = AddNode(type, type); for (int i = 0; i < args.Length; i++) Wire(args[i], n.id, i.ToString(CultureInfo.InvariantCulture));
            return new GraphValue(n.id, output);
        }
        private ShaderNodePlan AddNode(string type, string purpose)
        {
            if (plan.nodes.Count >= 4096) throw Unsupported("Native graph expansion exceeded 4096 nodes.");
            int index = plan.nodes.Count;
            var n = new ShaderNodePlan { id = "n" + index, type = type, purpose = purpose, x = -1500 + (index / 6) * 300, y = (index % 6) * 180 };
            plan.nodes.Add(n); report.nativeMappings.Add(purpose + " -> " + type); return n;
        }
        private void Wire(GraphValue from, string to, string port) { plan.wires.Add(new ShaderWirePlan { from = from.id, fromPort = from.port, to = to, toPort = port }); }
        private static int Width(string type) { return type == "INT" || type == "FLOAT" || type == "FLOAT1" ? 1 : type == "FLOAT2" ? 2 : type == "FLOAT3" ? 3 : type == "FLOAT4" ? 4 : 0; }
        private static string Type(int count) { return count == 1 ? "FLOAT" : "FLOAT" + count; }
        private static string Merge(string a, string b)
        {
            int aw = Width(a), bw = Width(b);
            if (aw == 0 || bw == 0 || (aw != bw && aw != 1 && bw != 1)) throw Unsupported("Type conversion needs an explicit ASE node: " + a + " / " + b);
            return Type(Math.Max(aw, bw));
        }
        private static bool IntegralConstant(HlslExpr expression)
        {
            var number = expression as NumberExpr;
            if (number != null) return number.IntegerLiteral;
            var unary = expression as UnaryExpr;
            if (unary != null) return IntegralConstant(unary.Value);
            var binary = expression as BinaryExpr;
            return binary != null && IntegralConstant(binary.Left) && IntegralConstant(binary.Right);
        }
        private static NotSupportedException Unsupported(string message) { return new NotSupportedException(message); }

        private GraphValue InlineFunction(HlslLocalFunction function, GraphValue[] arguments)
        {
            if (!string.IsNullOrEmpty(function.error)) throw Unsupported(function.name + ": " + function.error);
            if (activeFunctions.Contains(function.Signature) || activeFunctions.Count >= 8 || ++functionCalls > 256) throw Unsupported("Recursive or excessive helper expansion: " + function.Signature);
            if (arguments.Length != function.parameters.Count) throw Unsupported("Helper argument count mismatch: " + function.name);
            for (int i = 0; i < arguments.Length; i++) if (arguments[i].type != function.parameterTypes[i]) throw Unsupported("Helper argument type conversion requires explicit nodes: " + function.name);
            var savedValues = new Dictionary<string, GraphValue>(values, StringComparer.Ordinal);
            string[] savedLocals = locals.ToArray(), savedConstants = constants.ToArray();
            activeFunctions.Add(function.Signature);
            try
            {
                values.Clear(); locals.Clear(); constants.Clear();
                foreach (var value in functionGlobals) values.Add(value.Key, value.Value);
                for (int i = 0; i < arguments.Length; i++) { values[function.parameters[i]] = arguments[i]; locals.Add(function.parameters[i]); }
                string[] statements = HlslFunctionLibrary.Statements(function.body);
                foreach (string statement in statements)
                {
                    if (statement.StartsWith("return ", StringComparison.Ordinal))
                    {
                        GraphValue result = BuildOrFallback(statement.Substring(7));
                        if (result.type != function.returnType) throw Unsupported("Helper return type conversion requires explicit nodes: " + function.name);
                        report.nativeMappings.Add("Pure helper " + function.Signature + " -> native arithmetic nodes");
                        return result;
                    }
                    Match declaration = Regex.Match(statement, @"^(?<const>const\s+)?(?<type>(?:float|half|fixed)[1-4]?)\s+(?<id>\w+)\s*=\s*(?<value>.+)$", RegexOptions.Singleline);
                    if (declaration.Success)
                    {
                        string id = declaration.Groups["id"].Value;
                        if (values.ContainsKey(id)) throw Unsupported("Helper local shadows an existing binding: " + id);
                        GraphValue value = BuildOrFallback(declaration.Groups["value"].Value);
                        if (value.type != HlslFunctionLibrary.Type(declaration.Groups["type"].Value)) throw Unsupported("Helper local type conversion requires explicit nodes: " + id);
                        values.Add(id, value); locals.Add(id); if (declaration.Groups["const"].Success) constants.Add(id);
                    }
                    else
                    {
                        Match assignment = Regex.Match(statement, @"^(?<id>\w+(?:\.[xyzwrgba]{1,4})?)\s*(?<op>[+*/-]?)=\s*(?<value>.+)$", RegexOptions.Singleline);
                        if (!assignment.Success) throw Unsupported("Unsupported helper statement: " + statement);
                        string target = assignment.Groups["id"].Value, expression = assignment.Groups["value"].Value;
                        if (assignment.Groups["op"].Length > 0) expression = "(" + target + ")" + assignment.Groups["op"].Value + "(" + expression + ")";
                        AssignLocal(target, BuildOrFallback(expression));
                    }
                }
                throw Unsupported("Helper return was not found: " + function.name);
            }
            finally
            {
                values.Clear(); foreach (var value in savedValues) values.Add(value.Key, value.Value);
                locals.Clear(); foreach (string name in savedLocals) locals.Add(name);
                constants.Clear(); foreach (string name in savedConstants) constants.Add(name);
                activeFunctions.Remove(function.Signature);
            }
        }
    }

    internal static class ShaderText
    {
        private static string Blank(string value) { return new string(value.Select(c => c == '\r' || c == '\n' ? c : ' ').ToArray()); }
        public static string NormalizeDirectives(string source)
        {
            // HLSL permits whitespace between # and its directive. Preserve quoted ShaderLab text.
            return Regex.Replace(source, "\"(?:\\\\.|[^\"\\\\])*\"|(?m:^[ \\t]*#[ \\t]+)",
                m => m.Value.StartsWith("\"", StringComparison.Ordinal) ? m.Value : Regex.Replace(m.Value, "#[ \\t]+", "#"));
        }
        public static string MaskStrings(string source) { return Regex.Replace(source, "\"(?:\\\\.|[^\"\\\\])*\"", m => Blank(m.Value)); }
        public static string MaskPrograms(string source)
        {
            return Regex.Replace(source, "\"(?:\\\\.|[^\"\\\\])*\"|\\b(?:CGPROGRAM|HLSLPROGRAM|CGINCLUDE|HLSLINCLUDE)\\b.*?\\b(?:ENDCG|ENDHLSL)\\b",
                m => m.Value.StartsWith("\"", StringComparison.Ordinal) ? m.Value : Blank(m.Value), RegexOptions.Singleline);
        }
        public static IEnumerable<string> BlocksAfter(string source, string keyword)
        {
            string masked = MaskStrings(source);
            foreach (Match match in Regex.Matches(masked, @"\b" + Regex.Escape(keyword) + @"\s*\{"))
            {
                int open = masked.IndexOf('{', match.Index), close = FindMatchingBrace(source, open);
                if (close >= 0) yield return source.Substring(open + 1, close - open - 1);
            }
        }
        public static string MaskBlocks(string source, string keyword)
        {
            string masked = MaskStrings(source);
            foreach (Match match in Regex.Matches(masked, @"\b" + Regex.Escape(keyword) + @"\s*\{"))
            {
                int open = masked.IndexOf('{', match.Index), close = FindMatchingBrace(source, open);
                if (close >= 0) source = source.Substring(0, match.Index) + Blank(source.Substring(match.Index, close - match.Index + 1)) + source.Substring(close + 1);
            }
            return source;
        }
        public static string RemoveBracedBlocks(string source)
        {
            var result = new StringBuilder();
            for (int i = 0; i < source.Length; i++)
            {
                if (source[i] != '{') { result.Append(source[i]); continue; }
                int end = FindMatchingBrace(source, i);
                if (end < 0) return source;
                result.Append(';'); i = end;
            }
            return result.ToString();
        }
        public static string RemoveComments(string source)
        {
            // Preserve quoted strings, including URL text in property names.
            return Regex.Replace(source, "\"(?:\\\\.|[^\"\\\\])*\"|/\\*.*?\\*/|//[^\\r\\n]*", m => m.Value.StartsWith("\"") ? m.Value : Blank(m.Value), RegexOptions.Singleline);
        }
        public static string FindBlockAfter(string source, string keyword)
        {
            Match m = Regex.Match(MaskStrings(source), @"\b" + Regex.Escape(keyword) + @"\s*\{");
            if (!m.Success) return "";
            int start = source.IndexOf('{', m.Index), end = FindMatchingBrace(source, start);
            return end < 0 ? "" : source.Substring(start + 1, end - start - 1);
        }
        public static int FindMatchingBrace(string text, int open)
        {
            int depth = 0; bool quoted = false;
            for (int i = open; i >= 0 && i < text.Length; i++)
            {
                if (text[i] == '\\' && quoted) { i++; continue; }
                if (text[i] == '"') quoted = !quoted;
                if (quoted) continue;
                if (text[i] == '{') depth++;
                if (text[i] == '}' && --depth == 0) return i;
            }
            return -1;
        }
    }
}
