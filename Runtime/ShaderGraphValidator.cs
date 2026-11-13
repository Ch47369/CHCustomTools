using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;

namespace ASEShaderConverter
{
    public static class ShaderGraphValidator
    {
        public static List<string> Validate(ShaderGraphPlan plan)
        {
            var errors = new List<string>();
            if (plan == null) { errors.Add("Graph plan is missing."); return errors; }
            if (plan.schemaVersion != 1) errors.Add("Unsupported graph schema version.");
            if (string.IsNullOrWhiteSpace(plan.shaderName) || plan.shaderName.IndexOfAny(new[] { '"', '\r', '\n' }) >= 0) errors.Add("Shader name is invalid.");
            if (!new[] { "BuiltIn", "URP", "HDRP" }.Contains(plan.pipeline)) errors.Add("Resolve the target pipeline before generation.");
            if (!new[] { "Unlit", "Lit" }.Contains(plan.surface)) errors.Add("Unknown surface model.");
            if (plan.surface == "Lit" && string.IsNullOrEmpty(plan.templateGuid)) errors.Add("Lit plans require an explicit installed ASE template GUID.");
            if (plan.nodes == null || plan.wires == null || plan.outputs == null || plan.masterSettings == null) { errors.Add("Graph collections cannot be null."); return errors; }
            var nodes = new Dictionary<string, ShaderNodePlan>(StringComparer.Ordinal);
            var properties = new HashSet<string>(StringComparer.Ordinal);
            foreach (var node in plan.nodes)
            {
                if (node == null || string.IsNullOrEmpty(node.id) || string.IsNullOrEmpty(node.type)) { errors.Add("Every node needs an id and ASE type."); continue; }
                if (nodes.ContainsKey(node.id)) { errors.Add("Duplicate node id: " + node.id); continue; }
                nodes.Add(node.id, node);
                if (!string.IsNullOrEmpty(node.propertyName) && (!Regex.IsMatch(node.propertyName, @"^[A-Za-z_]\w*$") || !properties.Add(node.propertyName))) errors.Add("Invalid or duplicate property: " + node.propertyName);
                if (node.settings == null || node.customInputs == null) { errors.Add("Node collections cannot be null: " + node.id); continue; }
                if (node.type == "StaticSwitch" && (string.IsNullOrEmpty(node.propertyName) ||
                    node.propertyName != node.propertyName.ToUpperInvariant() || node.propertyKind != "Float" ||
                    (node.value != "0" && node.value != "1")))
                    errors.Add("StaticSwitch requires an uppercase Float property and a 0/1 default: " + node.id);
                if (node.type == "CustomExpressionNode")
                {
                    if (string.IsNullOrWhiteSpace(node.fallbackReason)) errors.Add("Custom Expression needs a native-node fallback reason: " + node.id);
                    if (string.IsNullOrWhiteSpace(node.code) || string.IsNullOrEmpty(node.outputType)) errors.Add("Custom Expression needs code and an output type: " + node.id);
                    var names = new HashSet<string>(StringComparer.Ordinal);
                    foreach (var input in node.customInputs)
                        if (input == null || string.IsNullOrEmpty(input.name) || !Regex.IsMatch(input.name, @"^[A-Za-z_]\w*$") || !names.Add(input.name)) errors.Add("Custom Expression input names must be valid and unique: " + node.id);
                }
            }
            var destinations = new HashSet<string>(StringComparer.Ordinal);
            foreach (var wire in plan.wires)
            {
                if (wire == null || wire.from == null || wire.to == null || !nodes.ContainsKey(wire.from) || !nodes.ContainsKey(wire.to)) { errors.Add("Wire references an unknown node."); continue; }
                if (string.IsNullOrEmpty(wire.fromPort) || string.IsNullOrEmpty(wire.toPort)) errors.Add("Wire port is empty.");
                if (!destinations.Add(wire.to + ":" + wire.toPort)) errors.Add("Multiple wires target the same input: " + wire.to + ":" + wire.toPort);
            }
            var visited = new HashSet<string>(); var active = new HashSet<string>();
            foreach (string id in nodes.Keys) if (HasCycle(id, plan.wires, visited, active)) { errors.Add("Graph has a cycle."); break; }
            if (plan.outputs.Count == 0) errors.Add("At least one master output is required.");
            destinations.Clear();
            foreach (var output in plan.outputs)
            {
                if (output == null || output.node == null || !nodes.ContainsKey(output.node)) { errors.Add("Output references an unknown node."); continue; }
                if (string.IsNullOrEmpty(output.masterPort)) errors.Add("Master port is empty.");
                if (!destinations.Add(output.pass + ":" + output.masterPort)) errors.Add("Duplicate master output: " + output.masterPort);
            }
            return errors;
        }

        private static bool HasCycle(string id, List<ShaderWirePlan> wires, HashSet<string> visited, HashSet<string> active)
        {
            if (active.Contains(id)) return true;
            if (!visited.Add(id)) return false;
            active.Add(id);
            foreach (var wire in wires) if (wire != null && wire.from == id && wire.to != null && HasCycle(wire.to, wires, visited, active)) return true;
            active.Remove(id);
            return false;
        }
    }
}
