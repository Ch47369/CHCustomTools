using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Text.RegularExpressions;

namespace ASEShaderConverter
{
    // Separate from the historical ASE-oriented ShaderGraphPlan. Ports are native SG slot IDs.
    [Serializable] public sealed class ShaderGraphNativePlan
    {
        public int schemaVersion = 1;
        public string pipeline = "URP", surface = "Unlit", shaderPath = "ShaderConverter";
        public bool acceptStandardUrpUnlitTarget;
        public List<ShaderGraphNativeNode> nodes = new List<ShaderGraphNativeNode>();
        public List<ShaderGraphNativeEdge> edges = new List<ShaderGraphNativeEdge>();
        public string colorNode = "";
        public int colorSlot;
    }
    [Serializable] public sealed class ShaderGraphNativeNode
    {
        public string id, type, propertyName = "", displayName = "", mask = "xy";
        public string propertyKind = "Numeric", textureDefault = "white";
        public string keywordReference = "", keywordDisplayName = "", keywordDefinition = "ShaderFeature", keywordScope = "Local", keywordStages = "All";
        public string[] keywordEntries = new string[0], keywordEntryReferences = new string[0];
        public int keywordDefault;
        public float[] value = new float[0];
        public float x, y;
        public int uvChannel;
        public bool slider;
        public float rangeMin, rangeMax = 1;
    }
    [Serializable] public sealed class ShaderGraphNativeEdge
    {
        public string from, to;
        public int fromSlot, toSlot;
    }
    [Serializable] public sealed class ShaderGraphNativeAnalysis
    {
        public ShaderGraphNativePlan plan;
        public ShaderConversionReport report = new ShaderConversionReport { targetGraph = "ShaderGraph" };
    }
    public static class ShaderGraphNativePlanner
    {
        // Restricted to audited scalar/vector operations. No arbitrary type/field reflection.
        public static readonly string[] NodeTypes = {
            "Vector1Node", "Vector2Node", "Vector3Node", "Vector4Node", "PropertyNode",
            "AddNode", "SubtractNode", "MultiplyNode", "DivideNode", "SaturateNode",
            "AbsoluteNode", "NegateNode", "SineNode", "CosineNode", "FloorNode",
            "CeilingNode", "FractionNode", "SquareRootNode", "PowerNode", "MinimumNode",
            "MaximumNode", "LerpNode", "KeywordNode", "SwizzleNode", "CombineNode", "UVNode", "SampleTexture2DNode"
        };
        static readonly Dictionary<string,string> Math = new Dictionary<string,string> {
            {"SimpleAddOpNode","AddNode"},{"SimpleSubtractOpNode","SubtractNode"},
            {"SimpleMultiplyOpNode","MultiplyNode"},{"SimpleDivideOpNode","DivideNode"},
            {"SaturateNode","SaturateNode"},{"AbsOpNode","AbsoluteNode"},{"NegateNode","NegateNode"},
            {"SinOpNode","SineNode"},{"CosOpNode","CosineNode"},{"FloorOpNode","FloorNode"},
            {"CeilOpNode","CeilingNode"},{"FractNode","FractionNode"},{"SqrtOpNode","SquareRootNode"},
            {"PowerNode","PowerNode"},{"SimpleMinOpNode","MinimumNode"},{"SimpleMaxOpNode","MaximumNode"},
            {"LerpOp","LerpNode"}
        };
        public static List<string> Validate(ShaderGraphNativePlan plan)
        {
            var errors = new List<string>();
            if (plan == null) { errors.Add("ShaderGraph native plan is missing."); return errors; }
            if (plan.schemaVersion != 1 || plan.pipeline != "URP" || plan.surface != "Unlit") errors.Add("Native ShaderGraph schema 1 currently requires URP Unlit.");
            if (plan.shaderPath == null || !Regex.IsMatch(plan.shaderPath,@"^[\p{L}\p{N}_ /.-]*$")) errors.Add("Shader path contains unsupported characters.");
            if (!plan.acceptStandardUrpUnlitTarget) errors.Add("Explicitly select the standard URP Unlit target adaptation (fog, SSAO, decals, depth/editor passes; opaque Alpha=1). This is not source host equivalence.");
            if (plan.nodes == null || plan.edges == null) { errors.Add("Native plan collections cannot be null."); return errors; }
            if (plan.nodes.Count > 2048 || plan.edges.Count > 8192) errors.Add("Native plan size limit exceeded.");
            var ids = new HashSet<string>(); var properties = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            foreach (var n in plan.nodes)
            {
                if (n == null || string.IsNullOrWhiteSpace(n.id) || !ids.Add(n.id)) { errors.Add("Invalid/duplicate native node ID."); continue; }
                if (!NodeTypes.Contains(n.type)) errors.Add("Unsupported native ShaderGraph node: " + n.type);
                if (n.value == null || n.value.Any(v => float.IsNaN(v) || float.IsInfinity(v))) errors.Add("Invalid native node value: " + n.id);
                int width = VectorWidth(n.type);
                if (width > 0 && (n.value == null || n.value.Length != width)) errors.Add("Vector constant width mismatch: " + n.id);
                if (n.type == "PropertyNode")
                {
                    if (string.IsNullOrEmpty(n.propertyName) || !Regex.IsMatch(n.propertyName, @"^_[A-Za-z0-9_]+$") || !properties.Add(n.propertyName)) errors.Add("PropertyNode requires a unique reference name: " + n.id);
                    if (n.propertyKind == "Texture2D") { if (!new[]{"white","black","gray"}.Contains(n.textureDefault)) errors.Add("Unsupported texture default: " + n.id); }
                    else if (n.propertyKind != "Numeric" || n.value == null || n.value.Length < 1 || n.value.Length > 4) errors.Add("PropertyNode requires 1-4 numeric defaults or an audited Texture2D: " + n.id);
                }
                if (n.type == "KeywordNode")
                {
                    if (string.IsNullOrEmpty(n.keywordReference) || !Regex.IsMatch(n.keywordReference, @"^_[A-Z0-9_]+$") || !properties.Add(n.keywordReference)) errors.Add("KeywordNode requires a unique uppercase reference name: " + n.id);
                    if (!string.IsNullOrEmpty(n.keywordDisplayName) && !Regex.IsMatch(n.keywordDisplayName, @"^[A-Za-z_][A-Za-z0-9_ ]*$")) errors.Add("SG14 KeywordNode display name must be ASCII for generated HLSL identifiers: " + n.id);
                    if (n.keywordEntries == null || n.keywordEntryReferences == null || n.keywordEntries.Length != n.keywordEntryReferences.Length || n.keywordEntries.Length < 2 || n.keywordEntries.Length > 8) errors.Add("KeywordNode Enum requires 2-8 entries and matching references: " + n.id);
                    else
                    {
                        var entryRefs = new HashSet<string>(StringComparer.Ordinal);
                        for (int i = 0; i < n.keywordEntries.Length; i++)
                            if (string.IsNullOrWhiteSpace(n.keywordEntries[i]) || string.IsNullOrWhiteSpace(n.keywordEntryReferences[i]) || !Regex.IsMatch(n.keywordEntryReferences[i], @"^[A-Z_][A-Z0-9_]*$") || !entryRefs.Add(n.keywordEntryReferences[i]) || Regex.Replace(n.keywordEntries[i], @"\s", "_").ToUpperInvariant() != n.keywordEntryReferences[i]) errors.Add("KeywordNode entries must be unique valid identifiers matching their exposed material labels: " + n.id);
                    }
                    if (n.keywordDefault < 0 || n.keywordEntries == null || n.keywordDefault >= n.keywordEntries.Length) errors.Add("KeywordNode default is outside its Enum entries: " + n.id);
                    if (!new[]{"ShaderFeature","MultiCompile"}.Contains(n.keywordDefinition) || n.keywordScope != "Local" || n.keywordStages != "All") errors.Add("Only local All-stage ShaderFeature/MultiCompile Enum Keywords are supported: " + n.id);
                }
                if (n.type != "PropertyNode" && !string.IsNullOrEmpty(n.propertyName)) errors.Add("Only PropertyNode accepts property metadata: " + n.id);
                if (n.slider && (n.type != "PropertyNode" || n.value == null || n.value.Length != 1 || !(n.rangeMin <= n.rangeMax) || float.IsInfinity(n.rangeMin) || float.IsInfinity(n.rangeMax))) errors.Add("Invalid slider: " + n.id);
                if (n.type == "SwizzleNode" && (string.IsNullOrEmpty(n.mask) || !Regex.IsMatch(n.mask, @"^[xyzw]{1,4}$"))) errors.Add("Invalid swizzle: " + n.id);
                if (n.type == "UVNode" && (n.uvChannel < 0 || n.uvChannel > 3)) errors.Add("UV channel must be 0-3: " + n.id);
                if (float.IsNaN(n.x) || float.IsInfinity(n.x) || float.IsNaN(n.y) || float.IsInfinity(n.y)) errors.Add("Invalid node position: " + n.id);
            }
            var targets = new HashSet<string>();
            foreach (var e in plan.edges)
            {
                if (e == null || !ids.Contains(e.from ?? "") || !ids.Contains(e.to ?? "")) { errors.Add("Unknown native edge endpoint."); continue; }
                if (!targets.Add(e.to + ":" + e.toSlot)) errors.Add("Multiple edges target one native input.");
            }
            if (!ids.Contains(plan.colorNode ?? "")) errors.Add("Native BaseColor output is missing.");
            var visited = new HashSet<string>(); var active = new HashSet<string>();
            Func<string,bool> cycle = null;
            cycle = id => { if (active.Contains(id)) return true; if (!visited.Add(id)) return false; active.Add(id); foreach (var e in plan.edges.Where(e => e != null && e.from == id)) if (cycle(e.to)) return true; active.Remove(id); return false; };
            if (errors.Count == 0 && ids.Any(cycle)) errors.Add("Native graph contains a cycle.");
            return errors;
        }
        public static int VectorWidth(string type) { return type != null && Regex.IsMatch(type, @"^Vector[1-4]Node$") ? type[6] - '0' : 0; }

        public static ShaderGraphNativeAnalysis Analyze(string source, string sourcePath, ShaderConversionOptions options)
        {
            options = options ?? new ShaderConversionOptions();
            var original = ShaderConversionEngine.Analyze(source, sourcePath, new ShaderConversionOptions {
                targetPipeline = options.targetPipeline, surface = options.surface,
                targetGraph = "ShaderGraph",
                customExpressionFallback = false, keepOriginalShaderName = options.keepOriginalShaderName,
                presentation = options.presentation
            });
            var result = new ShaderGraphNativeAnalysis { report = original.report };
            var r = result.report; r.targetGraph = "ShaderGraph";
            if (options.keepOriginalShaderName) r.blockers.Add("ShaderGraph names derive from shaderPath/output filename; keepOriginalShaderName is not adapted for this backend.");
            if (r.existingAseGraph) r.blockers.Add("ASE → ShaderGraph requires a reviewed native graph reader; generated HLSL is not used as a substitute. Use a reviewed Agent native plan for now.");
            if (ShaderGraphSource.IsGraph(source)) r.blockers.Add("ShaderGraph input is currently structural analysis only; automatic graph-to-graph conversion is not implemented for this input.");
            if (!r.CanGenerate) { r.status = "NeedsAgent"; return result; }
            result.plan = Map(original.plan, r, options.acceptStandardUrpUnlitTarget);
            r.blockers.AddRange(Validate(result.plan));
            r.nativeNodeCount = result.plan.nodes.Count;
            r.nativeMappings = result.plan.nodes.Select(n => n.id + " → ShaderGraph." + n.type).ToList();
            r.warnings.Remove("A plan is not a validated ASE shader. Generate and reload it in the target Unity/ASE environment, then compare rendering with the source.");
            r.standardTargetAdaptation = options.acceptStandardUrpUnlitTarget;
            r.status = r.blockers.Count == 0 ? "Planned" : "NeedsAgent";
            r.shaderName = "ShaderConverter/" + original.plan.shaderName.Replace("_ASE", "_SG");
            r.warnings.Add("Standard URP Unlit target adaptation: fog/SSAO/decals and auxiliary depth/editor passes follow Unity's target. No source host or scene equivalence is claimed.");
            return result;
        }
        static ShaderGraphNativePlan Map(ShaderGraphPlan source, ShaderConversionReport report, bool accept)
        {
            var plan = new ShaderGraphNativePlan { pipeline = source.pipeline, acceptStandardUrpUnlitTarget = accept };
            if (source.surface != "Unlit" || !string.IsNullOrEmpty(source.templateGuid)) report.blockers.Add("Only the general single-pass Unlit native plan can map to the standard ShaderGraph target.");
            var alpha = source.outputs.SingleOrDefault(o => o.masterPort == "Alpha");
            if (alpha == null || !IsOne(source, alpha.node, alpha.port, new HashSet<string>())) report.blockers.Add("Opaque ShaderGraph forces Alpha=1; the source Alpha must be provably constant 1. Non-constant or non-one Alpha is blocked.");
            foreach (var s in source.masterSettings)
                if (!new[]{"option:  Keep Alpha","option:Cast Shadows","option:Extra Pre Pass","option:Built-in Fog","option:Receive Shadows","option:Receive SSAO","option:Meta Pass","option:LOD CrossFade","option:Surface","template:RenderQueue"}.Contains(s.name)) report.blockers.Add("Unmapped source render state: " + s.name + "=" + s.value);
            var slots = new Dictionary<string,int>();
            var enumSwitchProperties = new HashSet<string>(source.nodes.Where(n => n.enumSwitch && !string.IsNullOrEmpty(n.enumProperty)).Select(n => n.enumProperty), StringComparer.Ordinal);
            foreach (var selector in source.nodes.Where(n => n.isEnum && enumSwitchProperties.Contains(n.propertyName)))
            {
                var uses = source.wires.Where(e => e.from == selector.id).ToArray();
                if (uses.Length != 1 || uses.Any(e => e.toPort != "2" || !source.nodes.Any(n => n.id == e.to && n.enumSwitch && n.enumProperty == selector.propertyName)))
                    report.blockers.Add("Enum selector must have one exclusive Lerp selector use; shared or arithmetic uses require an Agent keyword plan: " + selector.propertyName);
            }
            foreach (var selector in source.nodes.Where(n => n.enumSwitch))
                if (HasEnumAncestor(source, selector.id, new HashSet<string>())) report.blockers.Add("Nested enum Lerp requires an explicit Agent keyword plan: " + selector.id);
            foreach (var n in source.nodes)
            {
                var spec = new ShaderGraphNativeNode { id = n.id, x = n.x, y = n.y };
                int output = 0; string math;
                if (n.isEnum && !n.enumSwitch && enumSwitchProperties.Contains(n.propertyName)) continue;
                if (n.isEnum && !n.enumSwitch)
                {
                    report.blockers.Add("Enum Float property is only lowered when it directly selects a reviewed Lerp; provide an Agent Keyword plan for other uses: " + n.propertyName);
                    continue;
                }
                if (n.settings.Count > 0 && !(n.type == "TextureCoordinatesNode" && n.settings.All(s => s.name == "m_textureCoordChannel"))) { report.blockers.Add("Unmapped source node settings: " + n.id); continue; }
                if (!string.IsNullOrEmpty(n.propertyName))
                {
                    if (n.propertyKind != "Float" && n.propertyKind != "Range" && n.propertyKind != "Vector" && n.propertyKind != "2D") { report.blockers.Add("Unmapped property kind (including color-space semantics): " + n.propertyKind); continue; }
                    spec.type = "PropertyNode"; spec.propertyName = n.propertyName; spec.displayName = n.displayName;
                    if (n.propertyKind == "2D")
                    {
                        var texture = Regex.Match(n.value ?? "", "^\\s*\"(white|black|gray)\"\\s*\\{\\s*\\}\\s*$");
                        if (!texture.Success) { report.blockers.Add("Unsupported Texture2D default/block: " + n.propertyName); continue; }
                        spec.propertyKind = "Texture2D"; spec.textureDefault = texture.Groups[1].Value;
                    }
                    else spec.value = Numbers(n.value);
                    spec.slider = n.propertyKind == "Range"; spec.rangeMin = n.rangeMin; spec.rangeMax = n.rangeMax;
                }
                else if (n.type == "RangedFloatNode") { spec.type = "Vector1Node"; spec.value = Numbers(n.value); }
                else if (VectorWidth(n.type) > 0) { spec.type = n.type; spec.value = Numbers(n.value); }
                else if (n.type == "SwizzleNode") { spec.type = "SwizzleNode"; spec.mask = n.swizzle; output = 1; }
                else if (n.type == "TextureCoordinatesNode")
                {
                    if (source.wires.Any(e => e.to == n.id)) { report.blockers.Add("Vertex texture ST transform requires explicit stage mapping: " + n.id); continue; }
                    int channel = int.Parse(n.settings.Single(s => s.name == "m_textureCoordChannel").value,CultureInfo.InvariantCulture);
                    plan.nodes.Add(new ShaderGraphNativeNode { id = n.id + "_uv", type = "UVNode", uvChannel = channel, x = n.x-200, y = n.y });
                    spec.type = "SwizzleNode"; spec.mask = "xy"; output = 1;
                    plan.edges.Add(new ShaderGraphNativeEdge { from = n.id + "_uv", to = n.id, toSlot = 0 });
                }
                else if (n.type == "VertexToFragmentNode")
                {
                    var input = source.wires.SingleOrDefault(e => e.to == n.id);
                    if (input == null || source.nodes.Find(p => p.id == input.from).type != "TextureCoordinatesNode") { report.blockers.Add("Only direct UV forwarding can map to fragment UV; vertex arithmetic is blocked: " + n.id); continue; }
                    spec.type = "SwizzleNode"; spec.mask = "xy"; output = 1;
                }
                else if (n.type == "DynamicAppendNode") { spec.type = "CombineNode"; output = n.outputType == "FLOAT2" ? 6 : n.outputType == "FLOAT3" ? 5 : 4; }
                else if (n.type == "SamplerNode") spec.type = "SampleTexture2DNode";
                else if (n.type == "LerpOp" && n.enumSwitch)
                {
                    spec.type = "KeywordNode"; spec.keywordReference = n.enumProperty.ToUpperInvariant();
                    string sourceDisplayName = source.nodes.First(p => p.isEnum && p.propertyName == n.enumProperty).displayName;
                    spec.keywordDisplayName = Regex.IsMatch(sourceDisplayName ?? "", @"^[A-Za-z_][A-Za-z0-9_ ]*$") ? sourceDisplayName : n.enumProperty;
                    if (spec.keywordDisplayName != sourceDisplayName) report.warnings.Add("SG14 KeywordNode uses its display name in HLSL identifiers; material label adapted from '" + sourceDisplayName + "' to '" + spec.keywordDisplayName + "'.");
                    spec.keywordEntries = n.enumEntries; spec.keywordEntryReferences = n.enumReferences; spec.keywordDefault = n.enumDefault;
                    report.warnings.Add("Enum Float/Lerp becomes a local ShaderFeature Enum Keyword; source property " + n.enumProperty + " maps to " + spec.keywordReference + ". Material scripts must select the matching keyword variant instead of relying on SetFloat/interpolation.");
                }
                else if (Math.TryGetValue(n.type, out math)) { spec.type = math; output = math == "LerpNode" ? 3 : new[]{"AddNode","SubtractNode","MultiplyNode","DivideNode","PowerNode","MinimumNode","MaximumNode"}.Contains(math) ? 2 : 1; }
                else { report.blockers.Add("No reviewed ShaderGraph native mapping: " + n.type); continue; }
                plan.nodes.Add(spec); slots[n.id] = output;
            }
            foreach (var e in source.wires)
            {
                int to;
                if (!slots.ContainsKey(e.from) || !slots.ContainsKey(e.to)) continue;
                if (e.fromPort != "0" || !int.TryParse(e.toPort, out to)) { report.blockers.Add("Unmapped ASE port: " + e.from + ":" + e.fromPort + " → " + e.to + ":" + e.toPort); continue; }
                var destination = source.nodes.Find(n => n.id == e.to);
                if (destination.type == "SamplerNode") to++;
                if (destination.enumSwitch)
                {
                    if (to == 2) continue; // The ASE Float selector becomes a compile-time keyword.
                    to++;
                }
                plan.edges.Add(new ShaderGraphNativeEdge { from = e.from, fromSlot = slots[e.from], to = e.to, toSlot = to });
            }
            foreach (var o in source.outputs.Where(o => o.masterPort != "Alpha"))
                if (o.masterPort != "Color" || !string.IsNullOrEmpty(o.pass) || !slots.ContainsKey(o.node)) report.blockers.Add("Unmapped source master output: " + o.masterPort);
                else { plan.colorNode = o.node; plan.colorSlot = slots[o.node]; }
            return plan;
        }
        static bool HasEnumAncestor(ShaderGraphPlan plan, string id, HashSet<string> visited)
        {
            if (!visited.Add(id)) return false;
            bool enumNode = plan.nodes.Any(n => n.id == id && n.enumSwitch);
            return plan.wires.Where(e => e.to == id && !(enumNode && e.toPort == "2")).Any(e => plan.nodes.Any(n => n.id == e.from && n.enumSwitch) || HasEnumAncestor(plan, e.from, visited));
        }
        static bool IsOne(ShaderGraphPlan plan, string id, string port, HashSet<string> active)
        {
            if (port != "0" || !active.Add(id)) return false;
            var n = plan.nodes.Find(x => x.id == id); if (n == null || !string.IsNullOrEmpty(n.propertyName)) return false;
            if (n.type == "RangedFloatNode") return Numbers(n.value).SequenceEqual(new[]{1f});
            if (n.type == "SwizzleNode" && n.swizzle.Length == 1)
            {
                var e = plan.wires.Find(x => x.to == id && x.toPort == "0"); if (e == null) return false;
                var from = plan.nodes.Find(x => x.id == e.from); int c = "xyzw".IndexOf(n.swizzle);
                if (from.type == "DynamicAppendNode") { var component = plan.wires.Find(x => x.to == from.id && x.toPort == c.ToString(CultureInfo.InvariantCulture)); return component != null && IsOne(plan, component.from, component.fromPort, active); }
                // A vector Lerp can still have a provably constant Alpha when both
                // branches carry a constant one in that component.  Preserve the
                // opaque-target proof instead of treating every Lerp result as
                // unknown.  This is deliberately limited to the reviewed native
                // Lerp node and its explicit vector inputs.
                if (from.type == "LerpOp")
                {
                    var left = plan.wires.Find(x => x.to == from.id && x.toPort == "0");
                    var right = plan.wires.Find(x => x.to == from.id && x.toPort == "1");
                    return left != null && right != null && IsComponentOne(plan, left.from, left.fromPort, c, active) && IsComponentOne(plan, right.from, right.fromPort, c, active);
                }
                if (VectorWidth(from.type) > c && string.IsNullOrEmpty(from.propertyName)) return Numbers(from.value)[c] == 1f;
            }
            return false;
        }
        static bool IsComponentOne(ShaderGraphPlan plan, string id, string port, int component, HashSet<string> active)
        {
            var node = plan.nodes.Find(x => x.id == id); if (node == null) return false;
            if (node.type == "DynamicAppendNode")
            {
                var wire = plan.wires.Find(x => x.to == id && x.toPort == component.ToString(CultureInfo.InvariantCulture));
                return wire != null && IsOne(plan, wire.from, wire.fromPort, active);
            }
            if (node.type == "LerpOp")
            {
                var left = plan.wires.Find(x => x.to == id && x.toPort == "0");
                var right = plan.wires.Find(x => x.to == id && x.toPort == "1");
                return left != null && right != null && IsComponentOne(plan, left.from, left.fromPort, component, active) && IsComponentOne(plan, right.from, right.fromPort, component, active);
            }
            if (component == 0) return IsOne(plan, id, port, active);
            int width = VectorWidth(node.type);
            return width > component && string.IsNullOrEmpty(node.propertyName) && Numbers(node.value)[component] == 1f;
        }
        public static float[] Numbers(string value)
        {
            if (string.IsNullOrWhiteSpace(value)) return new float[0];
            return value.Trim('(',')',' ','\t').Split(',').Select(v => float.Parse(v, CultureInfo.InvariantCulture)).ToArray();
        }
    }
}
