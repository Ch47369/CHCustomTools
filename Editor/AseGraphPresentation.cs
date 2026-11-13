using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using System.Text.RegularExpressions;
using UnityEditor;
using UnityEngine;
using R = ASEShaderConverter.Editor.AseReflection;

namespace ASEShaderConverter.Editor
{
    public static partial class AseEditorBridge
    {
        private sealed class GraphPresenter
        {
            private readonly object graph;
            private readonly ShaderGraphPlan plan;
            private readonly GraphPresentationOptions options;
            private readonly Dictionary<string, object> nodes;
            private readonly Dictionary<string, GraphLayoutItem> items;
            private readonly List<ShaderWirePlan> layoutEdges;
            private readonly Dictionary<string, object> registers = new Dictionary<string, object>();
            private readonly Dictionary<string, object> getters = new Dictionary<string, object>();
            private readonly Dictionary<int, int> references = new Dictionary<int, int>();
            private readonly Dictionary<int, int[]> frames = new Dictionary<int, int[]>();
            private readonly Dictionary<int, Vector2> positions = new Dictionary<int, Vector2>();
            public readonly List<object> AddedNodes = new List<object>();

            public GraphPresenter(object graph, ShaderGraphPlan plan, Dictionary<string, object> nodes)
            {
                this.graph = graph; this.plan = plan; this.nodes = nodes;
                options = plan.presentation ?? new GraphPresentationOptions();
                items = plan.nodes.ToDictionary(n => n.id, n => Item(n.id, n.group, nodes[n.id]));
                layoutEdges = plan.wires.ToList();
                // Texture objects cannot be stored in numeric local variables. Keep a texture
                // beside its sampler when all its consumers belong to one computation phase.
                foreach (var spec in plan.nodes.Where(n => n.type == "TexturePropertyNode"))
                {
                    var consumers = plan.wires.Where(e => e.from == spec.id).Select(e => items[e.to].group).Distinct().ToArray();
                    if (consumers.Length == 1) items[spec.id].group = consumers[0];
                }
                if (options.autoLayout) ShaderGraphLayout.Arrange(items.Values.ToList(), layoutEdges);
            }
            private static GraphLayoutItem Item(string id, string group, object node)
            {
                Rect size = (Rect)R.Get(node, "TruePosition");
                return new GraphLayoutItem { id = id, group = group, x = size.x, y = size.y, width = Math.Max(240, size.width), height = Math.Max(180, size.height) };
            }
            public void ConnectWire(ShaderWirePlan wire, List<ExpectedConnection> connections)
            {
                object from = nodes[wire.from], to = nodes[wire.to];
                string fromPort = wire.fromPort;
                float distance = Mathf.Abs(items[wire.from].x - items[wire.to].x) + Mathf.Abs(items[wire.from].y - items[wire.to].y) * 0.5f;
                string type = R.Get(Port(from, fromPort, false), "DataType").ToString();
                bool numeric = new[] { "FLOAT", "FLOAT2", "FLOAT3", "FLOAT4", "COLOR" }.Contains(type);
                string key = wire.from + ":" + wire.fromPort;
                if (options.autoLayout && options.useRegisters && numeric && distance > Math.Max(600, options.longWireDistance)
                    && (registers.ContainsKey(key) || registers.Count < Math.Max(0, options.maxRegisters)))
                {
                    // A single getter shared by distant consumers recreates the long wire.
                    // Reuse one getter per consumer, including multiple ports on that node.
                    string consumer = items[wire.to].group + ":" + wire.to;
                    object getter = RouteReference(wire.from, fromPort, items[wire.to].group, consumer, connections);
                    string getterKey = key + ":" + consumer;
                    layoutEdges.Add(new ShaderWirePlan { from = "get_" + getterKey, to = wire.to });
                    from = getter; fromPort = "0";
                }
                Connect(graph, from, fromPort, to, wire.toPort);
                connections.Add(Expected(graph, from, fromPort, to, wire.toPort));
            }
            public void ConnectOutput(ShaderOutputPlan output, List<ExpectedConnection> connections)
            {
                object from = nodes[output.node], target = ResolveMaster(graph, output);
                string port = output.port;
                string type = R.Get(Port(from, port, false), "DataType").ToString();
                string key = output.node + ":" + port;
                float distance = items.Values.Max(n => n.x + n.width) + 400 - items[output.node].x;
                if (options.autoLayout && options.useRegisters && new[] { "FLOAT", "FLOAT2", "FLOAT3", "FLOAT4", "COLOR" }.Contains(type)
                    && distance > Math.Max(600, options.longWireDistance)
                    && (registers.ContainsKey(key) || registers.Count < Math.Max(0, options.maxRegisters)))
                {
                    from = RouteReference(output.node, port, "master_outputs", "master_outputs", connections); port = "0";
                }
                Connect(graph, from, port, target, output.masterPort);
                connections.Add(Expected(graph, from, port, target, output.masterPort));
            }
            private object RouteReference(string sourceId, string sourcePort, string targetGroup, string consumer, List<ExpectedConnection> connections)
            {
                string key = sourceId + ":" + sourcePort;
                object register;
                if (!registers.TryGetValue(key, out register))
                {
                    register = Create("RegisterLocalVarNode", "reg_" + key, items[sourceId].group);
                    var spec = plan.nodes.First(n => n.id == sourceId);
                    string name = Regex.Replace(string.IsNullOrEmpty(spec.label) ? spec.id : spec.label, @"[^A-Za-z0-9_]", "_");
                    AsePresentationAdapter.NameRegister(register, "ase_" + name + "_" + R.Id(register));
                    Connect(graph, nodes[sourceId], sourcePort, register, "0");
                    connections.Add(Expected(graph, nodes[sourceId], sourcePort, register, "0"));
                    registers.Add(key, register);
                    layoutEdges.Add(new ShaderWirePlan { from = sourceId, to = "reg_" + key });
                }
                string getterKey = key + ":" + consumer;
                object getter;
                if (!getters.TryGetValue(getterKey, out getter))
                {
                    getter = Create("GetLocalVarNode", "get_" + getterKey, targetGroup);
                    AsePresentationAdapter.LinkGetter(getter, register);
                    getters.Add(getterKey, getter); references.Add(R.Id(getter), R.Id(register));
                    layoutEdges.Add(new ShaderWirePlan { from = "reg_" + key, to = "get_" + getterKey });
                }
                return getter;
            }
            private object Create(string type, string id, string group)
            {
                AsePresentationAdapter.RequireVersion();
                object node = R.Call(graph, "CreateNode", R.Find(type), false, -1, true);
                AddedNodes.Add(node); items.Add(id, Item(id, group, node)); extraIds.Add(id, R.Id(node));
                return node;
            }
            public void Finish(ShaderConversionReport report)
            {
                var all = nodes.Values.Concat(AddedNodes).ToDictionary(R.Id);
                if (options.autoLayout)
                {
                    ShaderGraphLayout.Arrange(items.Values.ToList(), layoutEdges);
                    foreach (var pair in items)
                    {
                        object node = nodes.ContainsKey(pair.Key) ? nodes[pair.Key] : AddedNodes.First(n => R.Id(n) == NodeIdForItem(pair.Key));
                        var pos = new Vector2(pair.Value.x, pair.Value.y);
                        R.Set(node, "Vec2Position", pos); positions[R.Id(node)] = pos;
                        var spec = plan.nodes.FirstOrDefault(n => n.id == pair.Key);
                        if (spec != null) { spec.x = pos.x; spec.y = pos.y; }
                    }
                    float right = items.Values.Max(n => n.x + n.width) + 400;
                    foreach (object master in R.Items(R.Get(graph, "AllNodes")).Where(n => R.Find("MasterNode").IsInstanceOfType(n)))
                        R.Set(master, "Vec2Position", new Vector2(right, 200));
                    report.layoutApplied = true;
                }
                if (options.addComments)
                {
                    foreach (var group in items.GroupBy(p => p.Value.group))
                    {
                        var members = group.Select(p => nodes.ContainsKey(p.Key) ? nodes[p.Key] : all[NodeIdForItem(p.Key)]).ToArray();
                        var description = (plan.comments ?? new List<GraphCommentPlan>()).FirstOrDefault(c => c.id == group.Key);
                        if (description == null && group.Key == "master_outputs")
                            description = new GraphCommentPlan { title = "09 主节点输入", text = "从命名 Register 读取远处的法线、顶点位移等结果，在主节点旁连接到对应端口，避免长线横穿整个图。" };
                        object frame = R.Call(graph, "CreateNode", R.Find("CommentaryNode"), false, -1, true);
                        AsePresentationAdapter.ConfigureComment(frame, members,
                            description == null ? "计算与传递" : description.title,
                            description == null ? "这些节点按数据依赖连接，将输入计算为下游使用的结果。" : description.text,
                            group.Select(p => p.Value).ToArray(), options.autoLayout);
                        frames.Add(R.Id(frame), members.Select(R.Id).ToArray()); AddedNodes.Add(frame);
                    }
                }
                report.registerNodeCount = registers.Count; report.getNodeCount = getters.Count; report.commentCount = frames.Count;
            }
            private readonly Dictionary<string, int> extraIds = new Dictionary<string, int>();
            private int NodeIdForItem(string key) { return extraIds[key]; }
            public void Verify(object reloadedGraph)
            {
                foreach (var pair in references)
                {
                    object getter = R.Call(reloadedGraph, "GetNode", pair.Key);
                    if ((int)R.Get(getter, "ReferencedNodeId") != pair.Value || (bool)R.Get(getter, "HasMissingReference")) throw new InvalidOperationException("ASE lost a Register/Get reference.");
                }
                foreach (var frame in frames) AsePresentationAdapter.VerifyComment(R.Call(reloadedGraph, "GetNode", frame.Key), frame.Value);
                foreach (var pair in positions)
                    if (Vector2.Distance((Vector2)R.Get(R.Call(reloadedGraph, "GetNode", pair.Key), "Vec2Position"), pair.Value) > 0.1f) throw new InvalidOperationException("ASE changed arranged node coordinates.");
            }
        }
    }

    // Only these specific serialized presentation fields are adapted for this verified ASE version.
    internal static class AsePresentationAdapter
    {
        public static void RequireVersion()
        {
            if ((string)R.Call(R.Find("VersionInfo"), "StaticToString") != "1.9.9.13") throw new NotSupportedException("Graph presentation adapters require ASE 1.9.9.13.");
        }
        public static void NameRegister(object node, string name)
        {
            RequireVersion();
            var serialized = new SerializedObject((UnityEngine.Object)node);
            serialized.FindProperty("m_variableName").stringValue = name;
            serialized.ApplyModifiedPropertiesWithoutUndo();
            node.GetType().GetMethod("CheckAndChangeName", BindingFlags.Instance | BindingFlags.NonPublic).Invoke(node, null);
            if ((string)R.Get(node, "DataToArray") != name) throw new InvalidOperationException("ASE rejected a local variable name.");
        }
        public static void LinkGetter(object getter, object register)
        {
            RequireVersion();
            R.Set(getter, "CurrentSelected", register);
            var serialized = new SerializedObject((UnityEngine.Object)getter);
            serialized.FindProperty("m_nodeId").intValue = R.Id(register);
            serialized.FindProperty("m_referenceId").intValue = (int)R.Call(R.Find("UIUtils"), "GetLocalVarNodeRegisterId", R.Id(register));
            serialized.ApplyModifiedPropertiesWithoutUndo();
            R.Call(getter, "RefreshExternalReferences"); R.Call(getter, "UpdateLocalVar");
        }
        public static void ConfigureComment(object frame, object[] members, string title, string text, GraphLayoutItem[] layout, bool arranged)
        {
            RequireVersion();
            Array typed = Array.CreateInstance(R.Find("ParentNode"), members.Length);
            for (int i = 0; i < members.Length; i++) typed.SetValue(members[i], i);
            R.Call(frame, "CreateFromSelectedNodes", Vector2.zero, typed);
            var serialized = new SerializedObject((UnityEngine.Object)frame);
            serialized.FindProperty("m_titleText").stringValue = Clean(title);
            serialized.FindProperty("m_commentText").stringValue = Clean(text);
            if (arranged)
            {
                float x = layout.Min(n => n.x) - 50, y = layout.Min(n => n.y) - 100;
                serialized.FindProperty("m_position").rectValue = new Rect(x, y, Math.Max(640, layout.Max(n => n.x + n.width) - x + 50), layout.Max(n => n.y + n.height) - y + 50);
            }
            serialized.ApplyModifiedPropertiesWithoutUndo();
            R.Set(frame, "m_frameColor", new Color(0.25f,0.55f,0.75f,1));
        }
        private static string Clean(string text) { return (text ?? "").Replace(';', '；').Replace('\n',' ').Replace('\r',' '); }
        public static void VerifyComment(object frame, int[] expected)
        {
            RequireVersion(); R.Call(frame, "ResolvePendingMemberIds");
            var field = frame.GetType().GetField("m_nodesOnCommentary", BindingFlags.Instance | BindingFlags.NonPublic);
            int[] actual = R.Items(field.GetValue(frame)).Select(R.Id).OrderBy(id => id).ToArray();
            if (!actual.SequenceEqual(expected.OrderBy(id => id))) throw new InvalidOperationException("ASE lost Comment group membership.");
        }
    }
}
