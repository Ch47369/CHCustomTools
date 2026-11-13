using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Runtime.ExceptionServices;
using System.Text.RegularExpressions;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;
using R = ASEShaderConverter.Editor.AseReflection;

namespace ASEShaderConverter.Editor
{
    [Serializable] public sealed class AseTemplateInfo
    {
        public string guid, name, path, pipeline;
        public bool ready;
    }
    [Serializable] public sealed class AseEnvironmentInfo
    {
        public string unityVersion, aseVersion = "", activePipeline;
        public List<AseTemplateInfo> templates = new List<AseTemplateInfo>();
        public List<string> errors = new List<string>();
    }
    [Serializable] public sealed class AsePortInfo
    {
        public int id;
        public string name, type;
        public bool visible, locked;
    }
    [Serializable] public sealed class AseNodeInfo
    {
        public string type, pass;
        public List<AsePortInfo> inputs = new List<AsePortInfo>(), outputs = new List<AsePortInfo>();
    }
    [Serializable] public sealed class AseTemplateDescription
    {
        public List<AseNodeInfo> masters = new List<AseNodeInfo>();
        public List<NodeSetting> options = new List<NodeSetting>();
    }

    public static partial class AseEditorBridge
    {
        public const string BuiltInUnlitGuid = "0770190933193b94aaa3065e307002fa";
        public const string UrpUnlitGuid = "2992e84f91cbeb14eab234972e07ea9d";
        public const string HdrpUnlitGuid = "7f5cb9c3ea6481f469fdd856555439ef";

        public static AseEnvironmentInfo Probe()
        {
            var env = new AseEnvironmentInfo { unityVersion = Application.unityVersion, activePipeline = ActivePipeline() };
            try
            {
                env.aseVersion = (string)R.Call(R.Find("VersionInfo"), "StaticToString");
                object manager = R.Get(R.Find("TemplatesManager"), "Instance");
                if (manager == null) throw new InvalidOperationException("ASE template manager is not initialized.");
                foreach (string ownedGuid in new[] { ReviewedUiProfile.TemplateGuid, ReviewedUiProfile.PanZoomTemplateGuid, ReviewedNormal360Profile.TemplateGuid })
                    if (!string.IsNullOrEmpty(AssetDatabase.GUIDToAssetPath(ownedGuid))) R.Call(manager, "CheckAndLoadTemplate", ownedGuid);
                int count = (int)R.Get(manager, "TemplateCount");
                for (int i = 0; i < count; i++)
                {
                    object template = R.Call(manager, "GetTemplate", i);
                    string guid = (string)R.Get(template, "GUID"), path = AssetDatabase.GUIDToAssetPath(guid);
                    string body = File.Exists(path) ? File.ReadAllText(path) : "";
                    env.templates.Add(new AseTemplateInfo { guid = guid, name = (string)R.Get(template, "Name"), path = path,
                        pipeline = ShaderConversionEngine.DetectPipeline(body), ready = (bool)R.Get(template, "IsValid") && body.Contains("/*ase_name") && body.Contains("/*ase_frag_out") });
                }
            }
            catch (Exception e) { env.errors.Add(e.Message); }
            return env;
        }

        public static ShaderConversionReport Generate(ShaderGraphPlan plan, string outputPath, ShaderConversionReport report = null)
        {
            report = report ?? new ShaderConversionReport();
            report.blockers.AddRange(ShaderGraphValidator.Validate(plan));
            if (report.existingAseGraph || report.blockers.Count > 0) { report.status = "Blocked"; return report; }
            var env = Probe();
            report.unityVersion = env.unityVersion; report.aseVersion = env.aseVersion;
            report.shaderName = plan.shaderName; report.pipeline = plan.pipeline;
            report.blockers.AddRange(env.errors);
            if (env.activePipeline != plan.pipeline) report.blockers.Add("Target pipeline must match this project's active pipeline: " + env.activePipeline);
            string guid = string.IsNullOrEmpty(plan.templateGuid) ? DefaultGuid(plan.pipeline) : plan.templateGuid;
            report.templateGuid = guid;
            AseTemplateInfo template = env.templates.Find(t => t.guid == guid);
            // Converter-owned Canvas template uses UnityCG/UnityUI and no pipeline lighting.
            // Only this audited identity is portable; arbitrary Built-in templates stay blocked.
            bool canvasTemplate = guid == ReviewedUiProfile.TemplateGuid;
            if (template == null || !template.ready || (template.pipeline != plan.pipeline && !canvasTemplate))
                report.blockers.Add("The target ASE template is missing, a placeholder, or belongs to another pipeline. Import ASE's matching SRP template package first: " + guid);
            string path = "";
            try
            {
                path = AssetOutputPath(outputPath);
                if (File.Exists(path)) report.blockers.Add("Output already exists. Choose a new .shader path: " + path);
                foreach (var node in plan.nodes)
                {
                    Type type = R.Find(node.type);
                    if (!R.Find("ParentNode").IsAssignableFrom(type) || R.Find("MasterNode").IsAssignableFrom(type)) report.blockers.Add("Not a supported ASE expression node: " + node.type);
                }
            }
            catch (Exception e) { report.blockers.Add(e.Message); }
            if (report.blockers.Count > 0) { report.status = "Blocked"; return report; }

            object previous = R.Get(R.Find("UIUtils"), "CurrentWindow");
            EditorWindow window = null;
            bool shown = false;
            var savedCulture = System.Threading.Thread.CurrentThread.CurrentCulture;
            var savedUICulture = System.Threading.Thread.CurrentThread.CurrentUICulture;
            FieldInfo saveThreadField = R.Find("IOUtils").GetField("UseSaveThread", BindingFlags.Static | BindingFlags.Public | BindingFlags.NonPublic);
            if (saveThreadField == null || saveThreadField.FieldType != typeof(bool)) { report.blockers.Add("ASE synchronous save configuration is not adapted."); report.status = "Blocked"; return report; }
            object saveThread = saveThreadField.GetValue(null);
            try
            {
                System.Threading.Thread.CurrentThread.CurrentCulture = CultureInfo.InvariantCulture;
                window = CreateWindow(guid, out shown);
                object graph = R.Get(window, "CurrentGraph");
                object master = R.Get(graph, "CurrentMasterNode");
                R.Call(master, "SetName", plan.shaderName);
                ApplyOptions(master, plan.masterSettings);
                var nodes = new Dictionary<string, object>(StringComparer.Ordinal);
                foreach (var spec in plan.nodes)
                {
                    object node = R.Call(graph, "CreateNode", R.Find(spec.type), false, new Vector2(spec.x, spec.y), -1, true);
                    if (node == null || node.GetType() != R.Find(spec.type)) throw new NotSupportedException("ASE replaced/rejected node type: " + spec.type);
                    Configure(node, spec);
                    nodes.Add(spec.id, node);
                }
                var presentation = new GraphPresenter(graph, plan, nodes);
                var connections = new List<ExpectedConnection>();
                // Input notifications propagate types. Process producer nodes before consumers.
                foreach (var spec in Topological(plan))
                    foreach (var wire in plan.wires.Where(w => w.to == spec.id)) presentation.ConnectWire(wire, connections);
                foreach (var output in plan.outputs)
                    presentation.ConnectOutput(output, connections);
                R.Call(graph, "RefreshExternalReferences");
                presentation.Finish(report);
                VerifyOptions(R.Get(graph, "CurrentMasterNode"), plan.masterSettings);
                var mastersToVerify = new[] { ReviewedUiProfile.TemplateGuid, ReviewedUiProfile.PanZoomTemplateGuid, ReviewedNormal360Profile.TemplateGuid }.Contains(plan.templateGuid) ? R.Items(R.Get(graph, "AllNodes")).Where(n => R.Find("MasterNode").IsInstanceOfType(n)) : Enumerable.Empty<object>();
                var savedNodes = nodes.Values.Concat(presentation.AddedNodes).Concat(mastersToVerify).ToArray();
                var identities = savedNodes.ToDictionary(R.Id, n => n.GetType().FullName);
                var nodeIds = nodes.ToDictionary(pair => pair.Key, pair => R.Id(pair.Value));
                // ASE removes sampler placeholders from the visible property list when a
                // Texture Object is connected. Run its own public ordering pass before
                // capturing the settings; Execute performs the same pass during save.
                R.Call(master, "ForceReordering");
                var before = CaptureNodeData(savedNodes);
                Directory.CreateDirectory(Path.GetDirectoryName(Path.GetFullPath(path)));
                saveThreadField.SetValue(null, false);
                R.Call(graph, "FireMasterNode", Path.GetFullPath(path), true);
                report.outputPath = path;
                if (!File.Exists(path) || !File.ReadAllText(path).Contains("/*ASEBEGIN")) throw new InvalidOperationException("ASE did not save graph metadata.");
                AssetDatabase.ImportAsset(path, ImportAssetOptions.ForceSynchronousImport | ImportAssetOptions.ForceUpdate);
                var loaded = R.Call(window, "LoadFromDisk", path);
                if (loaded.ToString() != "LOADED") throw new InvalidOperationException("ASE reload failed: " + loaded);
                graph = R.Get(window, "CurrentGraph");
                VerifyOptions(R.Get(graph, "CurrentMasterNode"), plan.masterSettings);
                foreach (var identity in identities)
                {
                    object node = R.Call(graph, "GetNode", identity.Key);
                    if (node == null || node.GetType().FullName != identity.Value) throw new InvalidOperationException("ASE round-trip changed node " + identity.Key);
                }
                foreach (var spec in plan.nodes) AseNodeAdapters.Verify(R.Call(graph, "GetNode", nodeIds[spec.id]), spec);
                presentation.Verify(graph);
                foreach (var edge in connections) VerifyConnection(graph, edge);
                var after = CaptureNodeData(identities.Keys.Select(id => R.Call(graph, "GetNode", id)));
                foreach (var pair in before) if (after[pair.Key] != pair.Value)
                    throw new InvalidOperationException("ASE round-trip changed serialized settings on node " + pair.Key +
                        " (" + identities[pair.Key] + "). Before: " + pair.Value + "; after: " + after[pair.Key]);
                report.aseRoundTripPassed = true;
                string mainPass = (string)R.Get(R.Get(graph, "CurrentMasterNode"), "PassName");
                report.shaderCompiled = Compile(AssetDatabase.LoadAssetAtPath<Shader>(path), mainPass, report);
                report.customExpressionCount = plan.nodes.Count(n => n.type == "CustomExpressionNode");
                report.nativeNodeCount = plan.nodes.Count - report.customExpressionCount + report.registerNodeCount + report.getNodeCount;
                report.propertyCount = AssetDatabase.LoadAssetAtPath<Shader>(path).GetPropertyCount();
                if (plan.nodes.Any(n => n.propertyKind == "2DArray"))
                    report.warnings.Add("ASE 1.9.9.13 serializes the empty 2DArray default as the token white. No default array asset is assigned; the source default token remains recorded in the plan. Validate unassigned textures separately.");
                report.fallbackReasons = plan.nodes.Where(n => n.type == "CustomExpressionNode").Select(n => n.fallbackReason).ToList();
                report.status = report.shaderCompiled ? "Generated" : "ValidationFailed";
                report.warnings.Add("Rendering equivalence has not been checked. Compare source and generated materials in the target pipeline.");
            }
            catch (Exception e) { report.blockers.Add(e.Message); report.status = "GenerationFailed"; Debug.LogException(e); }
            finally
            {
                saveThreadField.SetValue(null, saveThread);
                try { DestroyWindow(window, shown); }
                finally
                {
                    R.Set(R.Find("UIUtils"), "CurrentWindow", previous);
                    System.Threading.Thread.CurrentThread.CurrentCulture = savedCulture;
                    System.Threading.Thread.CurrentThread.CurrentUICulture = savedUICulture;
                }
            }
            return report;
        }

        public static AseTemplateDescription DescribeTemplate(string guid, params string[] nodeTypes)
        {
            object previous = R.Get(R.Find("UIUtils"), "CurrentWindow");
            EditorWindow window = null;
            bool shown = false;
            try
            {
                window = CreateWindow(guid, out shown); object graph = R.Get(window, "CurrentGraph");
                var description = new AseTemplateDescription();
                foreach (var node in R.Items(R.Get(graph, "AllNodes")).Where(n => R.Find("MasterNode").IsInstanceOfType(n))) description.masters.Add(Describe(node));
                foreach (var type in nodeTypes ?? new string[0]) description.masters.Add(Describe(R.Call(graph, "CreateNode", R.Find(type), false, -1, true)));
                foreach (object helper in OptionHelpers(R.Get(graph, "CurrentMasterNode")))
                    foreach (object item in R.Items(R.Get(helper, "PassCustomOptionsUI")))
                    {
                        object options = R.Get(item, "Options");
                        description.options.Add(new NodeSetting("option:" + R.Get(options, "Name"), string.Join("|", (string[])R.Get(options, "Options"))));
                    }
                return description;
            }
            finally { try { DestroyWindow(window, shown); } finally { R.Set(R.Find("UIUtils"), "CurrentWindow", previous); } }
        }

        private static void DestroyWindow(EditorWindow window, bool shown)
        {
            if (window == null) return;
            if (shown) { R.Set(window, "ShaderIsModified", false); window.Close(); }
            else UnityEngine.Object.DestroyImmediate(window);
        }

        private static EditorWindow CreateWindow(string guid, out bool shown)
        {
            shown = false;
            var window = (EditorWindow)R.Call(R.Find("AmplifyShaderEditorWindow"), "CreateTab", null, null);
            R.Set(R.Find("UIUtils"), "CurrentWindow", window);
            try
            {
                R.Call(window, "CreateNewTemplateGraph", guid);
                // ASE initializes port-casting helpers and skin resources in its own OnGUI.
                // A newly created tab has not received that event during batch/agent calls.
                if (!(bool)R.Get(R.Find("UIUtils"), "Initialized"))
                {
                    window.Show();
                    shown = true;
                    window.SendEvent(new Event { type = EventType.Layout });
                    window.SendEvent(new Event { type = EventType.Repaint });
                    if (!(bool)R.Get(R.Find("UIUtils"), "Initialized")) throw new NotSupportedException("ASE did not initialize its editor resources.");
                }
                // Template options have pass/port actions that normally settle on GUI updates.
                // Apply ASE's own default cascade before selecting outputs or user overrides.
                object graph = R.Get(window, "CurrentGraph");
                foreach (object master in R.Items(R.Get(graph, "AllNodes")).Where(n => n.GetType().Name == "TemplateMultiPassMasterNode")) R.Call(master, "ForceOptionsRefresh");
            }
            catch { DestroyWindow(window, shown); throw; }
            return window;
        }

        private static void Configure(object node, ShaderNodePlan spec)
        {
            if (!string.IsNullOrEmpty(spec.propertyName))
            {
                // ASE global names allow exact ShaderLab identifiers, including names without an
                // underscore. Register the name first, then use ASE's type transition bookkeeping.
                R.Call(node, "ChangeParameterType", Enum.Parse(R.Find("PropertyType"), "Global"));
                R.Call(node, "RegisterPropertyName", true, spec.propertyName, true, false);
                R.Call(node, "ChangeParameterType", Enum.Parse(R.Find("PropertyType"), "Property"));
                if ((string)R.Get(node, "PropertyName") != spec.propertyName) throw new InvalidOperationException("ASE renamed property: " + spec.propertyName);
                SetSerialized(node, "m_autoGlobalName", "false");
                SetSerialized(node, "m_propertyInspectorName", spec.displayName ?? spec.propertyName);
                R.Call(node, "OnPropertyNameChanged");
                R.Set(node, "AutoRegister", true);
            }
            if (spec.type == "RangedFloatNode")
            {
                R.Set(node, "Value", float.Parse(spec.value, CultureInfo.InvariantCulture));
                R.Call(node, "SetTypeChangeRange", new Vector2(spec.rangeMin, spec.rangeMax));
            }
            else if (spec.type == "ColorNode" || spec.type == "Vector4Node" || spec.type == "IntegerNode")
            {
                float[] v = (spec.value ?? "0").Trim('(', ')').Split(',').Select(s => float.Parse(s, CultureInfo.InvariantCulture)).ToArray();
                if (spec.type != "IntegerNode" && v.Length != 4) throw new ArgumentException("Vector/color default requires four components.");
                Vector4 value = v.Length == 4 ? new Vector4(v[0], v[1], v[2], v[3]) : new Vector4(v[0], 0, 0, 0);
                R.Call(node, "SetTypeChangeValues", value, value);
            }
            else if (spec.type == "TexturePropertyNode")
            {
                Match m = Regex.Match(spec.value ?? "", "\"([^\"]*)\"");
                if (!m.Success) throw new ArgumentException("Texture default is missing.");
                if (spec.propertyKind == "2DArray")
                {
                    if (m.Groups[1].Value.Length != 0) throw new NotSupportedException("Texture array defaults require an explicit asset adapter.");
                }
                else R.Set(node, "DefaultTextureValue", m.Groups[1].Value);
            }
            else if (spec.type == "SwizzleNode" || spec.type == "DynamicAppendNode")
            {
                string t = spec.outputType ?? "FLOAT4";
                SetSerialized(node, "m_selectedOutputType", t);
                int width = t == "FLOAT" ? 1 : int.Parse(t.Substring(5), CultureInfo.InvariantCulture);
                SetSerialized(node, "m_selectedOutputTypeInt", (width - (spec.type == "SwizzleNode" ? 1 : 2)).ToString(CultureInfo.InvariantCulture));
                if (spec.type == "SwizzleNode")
                {
                    if (string.IsNullOrEmpty(spec.swizzle) || spec.swizzle.Length != width) throw new ArgumentException("Swizzle mask and output type mismatch.");
                    for (int i = 0; i < width; i++) SetSerialized(node, "m_selectedOutputSwizzleTypes.Array.data[" + i + "]", "xyzw".IndexOf(spec.swizzle[i]).ToString(CultureInfo.InvariantCulture));
                }
                R.Call(node, "ChangeOutputType", R.WireType(t), false);
            }
            else if (spec.type == "CustomExpressionNode") ConfigureCustom(node, spec);
            AseNodeAdapters.Configure(node, spec, SetSerialized);
        }

        private static void ConfigureCustom(object node, ShaderNodePlan spec)
        {
            if (!new[] { "FLOAT", "FLOAT2", "FLOAT3", "FLOAT4" }.Contains(spec.outputType)) throw new NotSupportedException("Custom Expression output type is not adapted.");
            SetSerialized(node, "m_code", spec.code);
            SetSerialized(node, "m_outputTypeIdx", (spec.outputType == "FLOAT" ? 1 : int.Parse(spec.outputType.Substring(5), CultureInfo.InvariantCulture)).ToString(CultureInfo.InvariantCulture));
            SetSerialized(node, "m_functionMode", Regex.IsMatch(spec.code, @"\breturn\b").ToString());
            // Port addition/removal must go through ASE's item bookkeeping, not just its port list.
            InvokeAdapted(node, "RemovePortAt", 0);
            for (int i = 0; i < spec.customInputs.Count; i++)
            {
                InvokeAdapted(node, "AddPortAt", i, false);
                object port = R.Items(R.Get(node, "InputPorts"))[i];
                R.Set(port, "Name", spec.customInputs[i].name);
                R.Call(port, "ChangeType", R.WireType(spec.customInputs[i].type), false);
            }
            R.Call(node, "ChangeOutputType", R.WireType(spec.outputType), false);
        }

        private static void SetSerialized(object node, string path, string value)
        {
            var serialized = new SerializedObject((UnityEngine.Object)node);
            SerializedProperty p = serialized.FindProperty(path);
            if (p == null) throw new NotSupportedException("ASE serialized setting changed: " + node.GetType().Name + "." + path);
            switch (p.propertyType)
            {
                case SerializedPropertyType.String: p.stringValue = value; break;
                case SerializedPropertyType.Boolean: p.boolValue = bool.Parse(value); break;
                case SerializedPropertyType.Integer: p.intValue = int.Parse(value, CultureInfo.InvariantCulture); break;
                case SerializedPropertyType.Enum:
                    int index = Array.IndexOf(p.enumNames, value);
                    if (index < 0) throw new ArgumentException("ASE enum setting is invalid: " + value);
                    p.enumValueIndex = index; break;
                default: throw new NotSupportedException("ASE setting type is not adapted: " + path);
            }
            serialized.ApplyModifiedPropertiesWithoutUndo();
        }

        private static void InvokeAdapted(object node, string name, params object[] args)
        {
            MethodInfo method = node.GetType().GetMethod(name, BindingFlags.NonPublic | BindingFlags.Instance);
            if (method == null) throw new NotSupportedException("ASE Custom Expression API changed: " + name);
            try { method.Invoke(node, args); } catch (TargetInvocationException e) { ExceptionDispatchInfo.Capture(e.InnerException ?? e).Throw(); throw; }
        }

        private static object[] OptionHelpers(object master)
        {
            if (master.GetType().Name != "TemplateMultiPassMasterNode") throw new NotSupportedException("Only current ASE multi-pass templates are adapted for options.");
            return new[] { R.Get(master, "SubShaderOptions"), R.Get(master, "PassOptions") };
        }
        private static void ApplyOptions(object master, List<NodeSetting> settings)
        {
            foreach (var setting in settings)
            {
                if (!setting.name.StartsWith("option:", StringComparison.Ordinal)) { AseNodeAdapters.ApplyMaster(master, setting); continue; }
                string name = setting.name.Substring(7);
                var matches = OptionHelpers(master).SelectMany(h => R.Items(R.Get(h, "PassCustomOptionsUI"))).Where(i => (string)R.Get(R.Get(i, "Options"), "Name") == name).ToArray();
                if (matches.Length != 1) throw new NotSupportedException("ASE template option missing or ambiguous: " + name);
                string[] choices = (string[])R.Get(R.Get(matches[0], "Options"), "Options");
                int index = Array.IndexOf(choices, setting.value);
                if (index < 0) throw new ArgumentException("Invalid template option value: " + name + " = " + setting.value);
                // Changing the selection alone does not run ASE's actions.
                R.Set(matches[0], "CurrentOption", index);
                R.Call(matches[0], "Update", 0, false);
            }
        }

        private static void VerifyOptions(object master, List<NodeSetting> settings)
        {
            foreach (NodeSetting setting in settings)
            {
                if (!setting.name.StartsWith("option:", StringComparison.Ordinal)) { AseNodeAdapters.VerifyMaster(master, setting); continue; }
                string name = setting.name.Substring("option:".Length);
                object[] matches = OptionHelpers(master).SelectMany(h => R.Items(R.Get(h, "PassCustomOptionsUI"))).Where(i => (string)R.Get(R.Get(i, "Options"), "Name") == name).ToArray();
                if (matches.Length != 1) throw new InvalidOperationException("ASE lost template option: " + name);
                string[] choices = (string[])R.Get(R.Get(matches[0], "Options"), "Options");
                int selected = (int)R.Get(matches[0], "CurrentOption");
                if (selected < 0 || selected >= choices.Length || choices[selected] != setting.value) throw new InvalidOperationException("ASE changed template option: " + name);
            }
        }

        private static object ResolveMaster(object graph, ShaderOutputPlan output)
        {
            object main = R.Get(graph, "CurrentMasterNode");
            if (string.IsNullOrEmpty(output.pass) && Ports(main, true).Any(p => Matches(p, output.masterPort) && (bool)R.Get(p, "Visible") && !(bool)R.Get(p, "Locked"))) return main;
            object[] masters = R.Items(R.Get(graph, "AllNodes")).Where(n => R.Find("MasterNode").IsInstanceOfType(n)).ToArray();
            masters = masters.Where(n => n.GetType().Name != "TemplateMultiPassMasterNode" || !(bool)R.Get(n, "IsInvisible")).ToArray();
            if (!string.IsNullOrEmpty(output.pass)) masters = masters.Where(n => n.GetType().Name == "TemplateMultiPassMasterNode" && (string)R.Get(n, "PassName") == output.pass).ToArray();
            // Linked ASE ports can exist on several passes; only the visible owner is writable.
            var candidates = masters.Where(n => Ports(n, true).Any(p => Matches(p, output.masterPort) && (bool)R.Get(p, "Visible") && !(bool)R.Get(p, "Locked"))).ToArray();
            if (candidates.Length != 1) throw new NotSupportedException("Master output missing or ambiguous; specify the pass: " + output.masterPort);
            return candidates[0];
        }
        private static object[] Ports(object node, bool input) { return R.Items(R.Get(node, input ? "InputPorts" : "OutputPorts")); }
        private static bool Matches(object port, string name) { return R.Get(port, "PortId").ToString() == name || (string)R.Get(port, "Name") == name; }
        private static object Port(object node, string name, bool input)
        {
            object[] ports = Ports(node, input).Where(p => Matches(p, name)).ToArray();
            if (ports.Length != 1) throw new NotSupportedException("Port missing or ambiguous: " + node.GetType().Name + "." + name);
            return ports[0];
        }
        private static void Connect(object graph, object from, string fromPort, object to, string toPort)
        {
            object input = Port(to, toPort, true), output = Port(from, fromPort, false);
            if ((bool)R.Get(input, "Locked") || !(bool)R.Get(input, "Visible")) throw new NotSupportedException("ASE input is hidden or locked: " + toPort);
            if ((bool)R.Get(input, "IsConnected")) throw new InvalidOperationException("ASE input already has a source: " + toPort);
            R.Call(graph, "CreateConnection", R.Id(to), (int)R.Get(input, "PortId"), R.Id(from), (int)R.Get(output, "PortId"), false);
            VerifyConnection(graph, Expected(graph, from, fromPort, to, toPort));
        }
        private sealed class ExpectedConnection { public int from, fromPort, to, toPort; }
        private static ExpectedConnection Expected(object graph, object from, string fromPort, object to, string toPort)
        {
            return new ExpectedConnection { from = R.Id(from), to = R.Id(to), fromPort = (int)R.Get(Port(from, fromPort, false), "PortId"), toPort = (int)R.Get(Port(to, toPort, true), "PortId") };
        }
        private static void VerifyConnection(object graph, ExpectedConnection edge)
        {
            object from = R.Call(graph, "GetNode", edge.from), to = R.Call(graph, "GetNode", edge.to);
            object input = Port(to, edge.toPort.ToString(CultureInfo.InvariantCulture), true), output = Port(from, edge.fromPort.ToString(CultureInfo.InvariantCulture), false);
            bool forward = R.Items(R.Get(input, "ExternalReferences")).Any(r => (int)R.Get(r, "NodeId") == edge.from && (int)R.Get(r, "PortId") == edge.fromPort);
            bool reverse = R.Items(R.Get(output, "ExternalReferences")).Any(r => (int)R.Get(r, "NodeId") == edge.to && (int)R.Get(r, "PortId") == edge.toPort);
            if (!forward || !reverse) throw new InvalidOperationException("ASE rejected or lost a connection: " + edge.from + ":" + edge.fromPort + " -> " + edge.to + ":" + edge.toPort);
        }
        private static IEnumerable<ShaderNodePlan> Topological(ShaderGraphPlan plan)
        {
            var done = new HashSet<string>();
            while (done.Count < plan.nodes.Count)
                foreach (var node in plan.nodes) if (!done.Contains(node.id) && plan.wires.Where(w => w.to == node.id).All(w => done.Contains(w.from))) { done.Add(node.id); yield return node; }
        }
        private static Dictionary<int, string> CaptureNodeData(IEnumerable<object> nodes)
        {
            var result = new Dictionary<int, string>();
            foreach (object node in nodes)
            {
                // ASE's own node writer gives a stable comparison without Unity instance ids.
                MethodInfo writer = node.GetType().GetMethod("WriteToString", new[] { typeof(string).MakeByRefType(), typeof(string).MakeByRefType() });
                if (writer == null) throw new MissingMethodException("ASE node writer is missing.");
                object[] args = { "", "" }; writer.Invoke(node, args);
                result.Add(R.Id(node), (string)args[0]);
            }
            return result;
        }
        internal static bool CompileNativeShader(Shader shader, string expectedPass, ShaderConversionReport report) { return Compile(shader, expectedPass, report); }
        private static bool Compile(Shader shader, string expectedPass, ShaderConversionReport report)
        {
            if (shader == null) { report.blockers.Add("Unity did not import the generated Shader."); return false; }
            MethodInfo method = typeof(ShaderUtil).GetMethod("CompilePass", BindingFlags.Public | BindingFlags.Static, null, new[] { typeof(Material), typeof(int), typeof(bool) }, null);
            if (method == null) { report.warnings.Add("This Unity version has no adapted synchronous pass compiler; shader compilation remains unverified."); return false; }
            var material = new Material(shader);
            try
            {
                if (!shader.isSupported || shader.name != report.shaderName || material.passCount == 0 || (!string.IsNullOrEmpty(expectedPass) && material.FindPass(expectedPass) < 0))
                {
                    report.blockers.Add("Unity did not select the intended ASE shader/pass (" + expectedPass + "). Check pipeline initialization, target platform, and fallback selection before retrying.");
                    return false;
                }
                for (int pass = 0; pass < material.passCount; pass++) method.Invoke(null, new object[] { material, pass, true });
            }
            finally { UnityEngine.Object.DestroyImmediate(material); }
            foreach (var message in ShaderUtil.GetShaderMessages(shader)) if (message.severity.ToString() == "Error") report.blockers.Add(message.message + " (" + message.file + ":" + message.line + ")");
            return report.blockers.Count == 0 && !ShaderUtil.ShaderHasError(shader);
        }
        private static AseNodeInfo Describe(object node)
        {
            var info = new AseNodeInfo { type = node.GetType().Name, pass = node.GetType().Name == "TemplateMultiPassMasterNode" ? (string)R.Get(node, "PassName") : "" };
            foreach (bool input in new[] { true, false }) foreach (var port in Ports(node, input))
                (input ? info.inputs : info.outputs).Add(new AsePortInfo { id = (int)R.Get(port, "PortId"), name = (string)R.Get(port, "Name"), type = R.Get(port, "DataType").ToString(), visible = (bool)R.Get(port, "Visible"), locked = input && (bool)R.Get(port, "Locked") });
            return info;
        }
        private static string DefaultGuid(string pipeline) { return pipeline == "URP" ? UrpUnlitGuid : pipeline == "HDRP" ? HdrpUnlitGuid : BuiltInUnlitGuid; }
        private static string ActivePipeline()
        {
            RenderPipelineAsset asset = GraphicsSettings.currentRenderPipeline;
            if (asset == null) return "BuiltIn";
            string name = asset.GetType().FullName;
            return name.Contains("Universal") ? "URP" : name.Contains("HDRender") ? "HDRP" : "Unknown";
        }
        internal static string AssetOutputPath(string path)
        {
            if (string.IsNullOrWhiteSpace(path)) throw new ArgumentException("Output path is missing.");
            string absolute = Path.GetFullPath(path).Replace('\\', '/');
            string assets = Path.GetFullPath(Application.dataPath).Replace('\\', '/');
            if (!absolute.StartsWith(assets + "/", StringComparison.OrdinalIgnoreCase) || !absolute.EndsWith(".shader", StringComparison.OrdinalIgnoreCase)) throw new ArgumentException("Output must be a .shader file inside this project's Assets folder.");
            return "Assets/" + absolute.Substring(assets.Length + 1);
        }
    }
}
