using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Text;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;
using R = ASEShaderConverter.Editor.AseReflection;

namespace ASEShaderConverter.Editor
{
    [Serializable] public sealed class ShaderGraphEnvironmentInfo
    {
        public string unityVersion, shaderGraphVersion = "", urpVersion = "", hdrpVersion = "", activePipeline, targetPipeline;
        public List<string> errors = new List<string>();
        public string[] supportedNodes = ShaderGraphNativePlanner.NodeTypes;
    }
    [Serializable] public sealed class ShaderGraphSlotInfo
    {
        public int id;
        public string name, type;
        public bool input;
    }
    [Serializable] public sealed class ShaderGraphNodeInfo
    {
        public string type;
        public List<ShaderGraphSlotInfo> slots = new List<ShaderGraphSlotInfo>();
    }
    public static class ShaderGraphEditorBridge
    {
        const string TargetName = "UnityEditor.Rendering.Universal.ShaderGraph.UniversalTarget";
        const string SubTargetName = "UnityEditor.Rendering.Universal.ShaderGraph.UniversalUnlitSubTarget";
        static Type Find(string full)
        {
            var type = AppDomain.CurrentDomain.GetAssemblies().Select(a => a.GetType(full, false)).FirstOrDefault(t => t != null);
            if (type == null) throw new NotSupportedException("ShaderGraph API is not installed/loaded: " + full);
            return type;
        }
        static object New(string name) { return Activator.CreateInstance(Find(name.Contains(".") ? name : "UnityEditor.ShaderGraph." + name),true); }
        static void SetNonPublic(object target, string name, object value)
        {
            Type type = target.GetType();
            var property = type.GetProperty(name, BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance);
            if (property != null && property.CanWrite) { property.SetValue(target, R.ConvertValue(value, property.PropertyType), null); return; }
            var field = type.GetField(name, BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance);
            if (field != null) { field.SetValue(target, R.ConvertValue(value, field.FieldType)); return; }
            throw new MissingMemberException(type.FullName, name);
        }
        static object Generic(object target, string name, Type arg, params object[] args)
        {
            var type = target as Type ?? target.GetType();
            var method = type.GetMethods(BindingFlags.Public | BindingFlags.Static | BindingFlags.Instance).Single(m => m.Name == name && m.IsGenericMethodDefinition && m.GetParameters().Length == args.Length);
            return method.MakeGenericMethod(arg).Invoke(target is Type ? null : target, args);
        }
        static object[] Nodes(object graph) { return R.Items(Generic(graph, "GetNodes", Find("UnityEditor.ShaderGraph.AbstractMaterialNode"))); }
        static object[] Slots(object node)
        {
            var type = Find("UnityEditor.ShaderGraph.MaterialSlot");
            var list = Activator.CreateInstance(typeof(List<>).MakeGenericType(type));
            Generic(node, "GetSlots", type, list); return R.Items(list);
        }
        static object Slot(object node, int id, bool input)
        {
            var slot = Slots(node).SingleOrDefault(s => (int)R.Get(s,"id") == id && (bool)R.Get(s,"isInputSlot") == input);
            if (slot == null) throw new ArgumentException("Missing " + (input ? "input" : "output") + " slot " + node.GetType().Name + ":" + id);
            return slot;
        }
        public static ShaderGraphEnvironmentInfo Probe() { return Probe("Auto"); }
        public static ShaderGraphEnvironmentInfo Probe(string pipeline)
        {
            string active = GraphicsSettings.currentRenderPipeline == null ? "BuiltIn" : GraphicsSettings.currentRenderPipeline.GetType().Name.Contains("Universal") ? "URP" : GraphicsSettings.currentRenderPipeline.GetType().Name.Contains("HDRenderPipeline") ? "HDRP" : "Other";
            var result = new ShaderGraphEnvironmentInfo { unityVersion = Application.unityVersion, activePipeline = active, targetPipeline = pipeline == "Auto" ? active : pipeline };
            var packages = UnityEditor.PackageManager.PackageInfo.GetAllRegisteredPackages();
            result.shaderGraphVersion = packages.FirstOrDefault(p => p.name == "com.unity.shadergraph")?.version ?? "";
            result.urpVersion = packages.FirstOrDefault(p => p.name == "com.unity.render-pipelines.universal")?.version ?? "";
            result.hdrpVersion = packages.FirstOrDefault(p => p.name == "com.unity.render-pipelines.high-definition")?.version ?? "";
            if (!result.unityVersion.StartsWith("2022.3.",StringComparison.Ordinal) || result.shaderGraphVersion != "14.0.8") result.errors.Add("Native ShaderGraph requires Unity 2022.3 / ShaderGraph 14.0.8.");
            if (!new[]{"BuiltIn","URP","HDRP"}.Contains(result.targetPipeline)) result.errors.Add("Unsupported native ShaderGraph target pipeline: " + result.targetPipeline);
            if (result.targetPipeline == "URP" && result.urpVersion != "14.0.8") result.errors.Add("Native URP ShaderGraph requires URP 14.0.8.");
            if (result.targetPipeline == "HDRP" && result.hdrpVersion != "14.0.8") result.errors.Add("Native HDRP ShaderGraph requires HDRP 14.0.8.");
            if (result.activePipeline != result.targetPipeline) result.errors.Add("Activate the target " + result.targetPipeline + " pipeline in this project before generating and compiling its ShaderGraph.");
            return result;
        }
        public static List<ShaderGraphNodeInfo> Describe(string[] types) { return Describe(types,"Auto"); }
        public static List<ShaderGraphNodeInfo> Describe(string[] types, string pipeline)
        {
            RequireEnvironment(pipeline);
            return (types == null || types.Length == 0 ? ShaderGraphNativePlanner.NodeTypes.Where(t => t != "PropertyNode").ToArray() : types).Select(t => {
                if (!ShaderGraphNativePlanner.NodeTypes.Contains(t)) throw new NotSupportedException("Unsupported native node: " + t);
                object node = New(t);
                if (t == "KeywordNode") ConfigureKeyword(null, node, new ShaderGraphNativeNode { keywordReference = "_MODE", keywordDisplayName = "模式", keywordEntries = new[]{"A","B"}, keywordEntryReferences = new[]{"A","B"} });
                return new ShaderGraphNodeInfo { type = t, slots = Slots(node).Select(s => new ShaderGraphSlotInfo { id = (int)R.Get(s,"id"), name = R.Get(s,"displayName").ToString(), type = R.Get(s,"valueType").ToString(), input = (bool)R.Get(s,"isInputSlot") }).ToList() };
            }).ToList();
        }
        static void RequireEnvironment(string pipeline)
        {
            var env = Probe(pipeline); if (env.errors.Count > 0) throw new NotSupportedException(string.Join("\n",env.errors.ToArray()));
        }
        public static ShaderConversionReport Generate(ShaderGraphNativePlan plan, string outputPath, ShaderConversionReport report = null)
        {
            report = report ?? new ShaderConversionReport { targetGraph = "ShaderGraph" };
            report.targetGraph = "ShaderGraph";
            report.blockers.AddRange(ShaderGraphNativePlanner.Validate(plan));
            if (report.blockers.Count > 0) { report.status = "Blocked"; return report; }
            try
            {
                RequireEnvironment(plan.pipeline);
                report.unityVersion = Application.unityVersion; report.shaderGraphVersion = Probe().shaderGraphVersion;
                report.pipeline = plan.pipeline; report.standardTargetAdaptation = true;
                string path = OutputPath(outputPath);
                if (File.Exists(path) || File.Exists(path + ".meta")) throw new IOException("Output already exists; choose a new .shadergraph path: " + path);
                object graph = New("GraphData"); R.Call(graph,"AddContexts");
                R.Set(graph,"path", plan.shaderPath); R.Call(graph,"SetGraphDefaultPrecision",R.Get(graph,"graphDefaultPrecision"));
                object target = CreateTarget(plan.pipeline);
                var targets = Array.CreateInstance(Find("UnityEditor.ShaderGraph.Target"),1); targets.SetValue(target,0);
                var descriptor = R.Get(Find("UnityEditor.ShaderGraph.BlockFields+SurfaceDescription"),"BaseColor");
                // HD's official Unlit factory includes default vertex outputs.
                // Omitting them suppresses Vertex.template.hlsl even in auxiliary
                // passes, leaving UnpackVaryingsMeshToFragInputs undefined.
                object[] defaults = plan.pipeline == "HDRP" ? new[]{
                    R.Get(Find("UnityEditor.ShaderGraph.BlockFields+VertexDescription"),"Position"),
                    R.Get(Find("UnityEditor.ShaderGraph.BlockFields+VertexDescription"),"Normal"),
                    R.Get(Find("UnityEditor.ShaderGraph.BlockFields+VertexDescription"),"Tangent"),
                    descriptor,
                    R.Get(Find("UnityEditor.ShaderGraph.BlockFields+SurfaceDescription"),"Emission"),
                    R.Get(Find("UnityEditor.ShaderGraph.BlockFields+SurfaceDescription"),"Alpha")
                } : new[]{descriptor};
                var descriptors = Array.CreateInstance(descriptor.GetType(),defaults.Length);
                for (int i = 0; i < defaults.Length; i++) descriptors.SetValue(defaults[i],i);
                R.Call(graph,"InitializeOutputs",targets,descriptors);
                var nodes = new Dictionary<string,object>();
                foreach (var n in plan.nodes)
                {
                    object node = New(n.type); R.Call(graph,"AddNode",node);
                    if (n.type == "PropertyNode") ConfigureProperty(graph,node,n);
                    if (n.type == "KeywordNode") ConfigureKeyword(graph,node,n);
                    int width = ShaderGraphNativePlanner.VectorWidth(n.type);
                    for (int c = 0; c < width; c++) R.Set(Slot(node,c+1,true),"value",n.value[c]);
                    if (n.type == "SwizzleNode") R.Set(node,"maskInput",n.mask);
                    if (n.type == "UVNode") R.Set(node,"uvChannel","UV"+n.uvChannel);
                    if (n.type == "SampleTexture2DNode")
                    {
                        // Exact SG14 adapter: raw tex2D has no URP global mip-bias adjustment.
                        node.GetType().GetProperty("enableGlobalMipBias",BindingFlags.Instance | BindingFlags.NonPublic).SetValue(node,false,null);
                    }
                    object draw = R.Get(node,"drawState"); R.Set(draw,"position",new Rect(n.x,n.y,180,140)); R.Set(node,"drawState",draw);
                    if (n.type != "KeywordNode") R.Set(node,"precision","Single"); nodes.Add(n.id,node);
                }
                foreach (var e in plan.edges) Connect(graph,nodes[e.from],e.fromSlot,nodes[e.to],e.toSlot);
                var block = Nodes(graph).Single(n => n.GetType().Name == "BlockNode" && ReferenceEquals(R.Get(n,"descriptor"),descriptor));
                Connect(graph,nodes[plan.colorNode],plan.colorSlot,block,0);
                R.Call(graph,"ValidateGraph");
                if (Nodes(graph).Any(n => (bool)R.Get(n,"hasError"))) throw new InvalidOperationException("Unity ShaderGraph validation rejected the native graph.");
                // Reject implicit vector truncation/padding. Scalar promotion is SG's documented behavior.
                foreach (var e in plan.edges)
                {
                    string from = R.Get(Slot(nodes[e.from],e.fromSlot,false),"concreteValueType").ToString();
                    string to = R.Get(Slot(nodes[e.to],e.toSlot,true),"concreteValueType").ToString();
                    if (from != to && from != "Vector1") throw new NotSupportedException("Native edge requires an explicit width conversion: " + e.from + " (" + from + ") → " + e.to + " (" + to + ")");
                }
                string colorType = R.Get(Slot(nodes[plan.colorNode],plan.colorSlot,false),"concreteValueType").ToString();
                if (colorType != "Vector3") throw new NotSupportedException("BaseColor output requires an explicit Vector3 result.");
                var serializer = Find("UnityEditor.ShaderGraph.Serialization.MultiJson");
                string json = (string)R.Call(serializer,"Serialize",graph);
                object reloaded = New("GraphData");
                Generic(serializer,"Deserialize",reloaded.GetType(),reloaded,json,null,false);
                R.Call(reloaded,"ValidateGraph");
                if (Nodes(reloaded).Any(n => (bool)R.Get(n,"hasError"))) throw new InvalidOperationException("Reloaded ShaderGraph contains validation errors.");
                if ((string)R.Call(serializer,"Serialize",reloaded) != json) throw new InvalidOperationException("ShaderGraph round-trip changed official serialized nodes, settings, properties or edges.");
                Directory.CreateDirectory(Path.GetDirectoryName(Path.GetFullPath(path)));
                using (var stream = new FileStream(path,FileMode.CreateNew,FileAccess.Write,FileShare.None))
                using (var writer = new StreamWriter(stream,new UTF8Encoding(false))) writer.Write(json);
                report.outputPath = path;
                // Reload the actual file as well; the serialized bytes are Unity's own format.
                object disk = New("GraphData"); Generic(serializer,"Deserialize",disk.GetType(),disk,File.ReadAllText(path),null,false);
                if ((string)R.Call(serializer,"Serialize",disk) != json) throw new InvalidOperationException("Disk ShaderGraph reload differs from saved content.");
                report.shaderGraphRoundTripPassed = true;
                AssetDatabase.ImportAsset(path,ImportAssetOptions.ForceSynchronousImport | ImportAssetOptions.ForceUpdate);
                Shader shader = AssetDatabase.LoadAssetAtPath<Shader>(path);
                report.shaderName = shader == null ? "" : shader.name;
                report.shaderCompiled = AseEditorBridge.CompileNativeShader(shader,plan.pipeline == "BuiltIn" ? "Pass" : plan.pipeline == "HDRP" ? "ForwardOnly" : "Universal Forward",report);
                report.nativeNodeCount = plan.nodes.Count; report.propertyCount = plan.nodes.Count(n => n.type == "PropertyNode" || n.type == "KeywordNode");
                report.status = report.shaderCompiled ? "Generated" : "ValidationFailed";
                report.warnings.Add("Generated native ShaderGraph under the standard " + plan.pipeline + " Unlit target; source host/scene equivalence and platform coverage are not implied.");
            }
            catch (Exception e) { report.blockers.Add("ShaderGraph generation/reload/compile at " + outputPath + ": " + e); report.status = "GenerationFailed"; }
            return report;
        }
        // Only fixed, reviewed SG14 target/data properties are accessed here. No
        // plan-supplied type names or field writes reach these version-gated adapters.
        static object CreateTarget(string pipeline)
        {
            string targetName = pipeline == "BuiltIn" ? "UnityEditor.Rendering.BuiltIn.ShaderGraph.BuiltInTarget" : pipeline == "HDRP" ? "UnityEditor.Rendering.HighDefinition.ShaderGraph.HDTarget" : TargetName;
            string subName = pipeline == "BuiltIn" ? "UnityEditor.Rendering.BuiltIn.ShaderGraph.BuiltInUnlitSubTarget" : pipeline == "HDRP" ? "UnityEditor.Rendering.HighDefinition.ShaderGraph.HDUnlitSubTarget" : SubTargetName;
            object target = New(targetName);
            if (!(bool)R.Call(target,"TrySetActiveSubTarget",Find(subName))) throw new NotSupportedException("Unity rejected " + pipeline + " Unlit subtarget.");
            if (pipeline == "HDRP")
            {
                object sub = R.Get(target,"activeSubTarget");
                object system = R.Get(sub,"systemData"), builtin = R.Get(sub,"builtinData"), unlit = R.Get(sub,"unlitData");
                R.Set(system,"surfaceType","Opaque"); R.Set(system,"renderQueueType","Opaque");
                R.Set(system,"zTest","LessEqual"); R.Set(system,"opaqueCullMode","Back");
                R.Set(system,"alphaTest",false); R.Set(system,"doubleSidedMode","Disabled");
                R.Set(system,"dotsInstancing",false); R.Set(system,"customVelocity",false); R.Set(system,"tessellation",false);
                R.Set(builtin,"distortion",false); R.Set(builtin,"addPrecomputedVelocity",false);
                R.Set(builtin,"depthOffset",false); R.Set(builtin,"supportLodCrossFade",false);
                R.Set(unlit,"enableShadowMatte",false); R.Set(unlit,"distortionOnly",false);
            }
            else
            {
                R.Set(target,"allowMaterialOverride",false); R.Set(target,"surfaceType","Opaque");
                R.Set(target,"renderFace","Front"); R.Set(target,"alphaClip",false);
                R.Set(target,"zWriteControl","ForceEnabled"); R.Set(target,"zTestMode","LEqual");
                if (pipeline == "URP")
                {
                    R.Set(target,"castShadows",false); R.Set(target,"receiveShadows",false); R.Set(target,"supportsLodCrossFade",false);
                }
            }
            return target;
        }
        static void ConfigureProperty(object graph, object node, ShaderGraphNativeNode spec)
        {
            int width = spec.value.Length;
            object property = New(spec.propertyKind == "Texture2D" ? "UnityEditor.ShaderGraph.Internal.Texture2DShaderProperty" : "UnityEditor.ShaderGraph.Internal.Vector"+width+"ShaderProperty");
            R.Set(property,"displayName",string.IsNullOrEmpty(spec.displayName) ? spec.propertyName : spec.displayName);
            // SG14 exposes referenceName read-only; this single internal setter is version gated.
            Find("UnityEditor.ShaderGraph.Internal.ShaderInput").GetProperty("overrideReferenceName",BindingFlags.Instance | BindingFlags.NonPublic).SetValue(property,spec.propertyName,null);
            if (spec.propertyKind == "Texture2D")
            {
                R.Set(property,"defaultType",spec.textureDefault == "gray" ? "Grey" : spec.textureDefault == "black" ? "Black" : "White");
                // Preserve the ordinary ShaderLab texture inspector's ST fields; sampling uses explicit UV.
                property.GetType().GetField("useTilingAndOffset",BindingFlags.Instance | BindingFlags.NonPublic).SetValue(property,true);
            }
            else { object value = width == 1 ? (object)spec.value[0] : new Vector4(spec.value[0],spec.value[1],width > 2 ? spec.value[2] : 0,width > 3 ? spec.value[3] : 0); R.Set(property,"value",value); }
            if (width == 1 && spec.slider) { R.Set(property,"floatType","Slider"); R.Set(property,"rangeValues",new Vector2(spec.rangeMin,spec.rangeMax)); }
            R.Call(graph,"AddGraphInput",property);
            R.Set(node,"property",property);
        }
        static void ConfigureKeyword(object graph, object node, ShaderGraphNativeNode spec)
        {
            if (spec.keywordEntries == null || spec.keywordEntryReferences == null || spec.keywordEntries.Length != spec.keywordEntryReferences.Length || spec.keywordEntries.Length < 2 || spec.keywordEntries.Length > 8)
                throw new ArgumentException("Keyword Enum requires 2-8 entries.");
            object keyword = New("UnityEditor.ShaderGraph.ShaderKeyword");
            R.Set(keyword,"displayName",string.IsNullOrEmpty(spec.keywordDisplayName) ? spec.keywordReference : spec.keywordDisplayName);
            SetNonPublic(keyword,"overrideReferenceName",spec.keywordReference);
            R.Set(keyword,"keywordType","Enum"); R.Set(keyword,"keywordDefinition",string.IsNullOrEmpty(spec.keywordDefinition) ? "ShaderFeature" : spec.keywordDefinition);
            R.Set(keyword,"keywordScope",string.IsNullOrEmpty(spec.keywordScope) ? "Local" : spec.keywordScope);
            R.Set(keyword,"keywordStages",string.IsNullOrEmpty(spec.keywordStages) ? "All" : spec.keywordStages);
            R.Set(keyword,"value",spec.keywordDefault);
            var entryType = Find("UnityEditor.ShaderGraph.KeywordEntry");
            var constructor = entryType.GetConstructor(BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic, null, new[]{typeof(int),typeof(string),typeof(string)}, null);
            if (constructor == null) throw new NotSupportedException("ShaderGraph KeywordEntry constructor changed.");
            var entries = (IList)Activator.CreateInstance(typeof(List<>).MakeGenericType(entryType));
            for (int i = 0; i < spec.keywordEntries.Length; i++) entries.Add(constructor.Invoke(new object[]{i + 1,spec.keywordEntries[i],spec.keywordEntryReferences[i]}));
            R.Set(keyword,"entries",entries);
            SetNonPublic(keyword,"generatePropertyBlock",true);
            // KeywordNode validation requires the exact ShaderKeyword instance
            // to be registered in GraphData before the node is evaluated.
            // Registering it also makes the generated enum material property
            // and its local variants part of official SG serialization.
            if (graph != null)
            {
                R.Call(graph,"AddGraphInput",keyword);
                if ((string)R.Get(keyword,"referenceName") != spec.keywordReference) throw new InvalidOperationException("ShaderGraph changed the reviewed keyword reference.");
            }
            R.Set(node,"keyword",keyword);
            R.Call(node,"UpdateNode");
        }
        static void Connect(object graph, object from, int fromId, object to, int toId)
        {
            Slot(from,fromId,false); Slot(to,toId,true);
            object edge = R.Call(graph,"Connect",R.Call(from,"GetSlotReference",fromId),R.Call(to,"GetSlotReference",toId));
            if (edge == null) throw new InvalidOperationException("Unity rejected a native ShaderGraph connection.");
        }
        static string OutputPath(string path)
        {
            if (string.IsNullOrWhiteSpace(path)) throw new ArgumentException("Output path is missing.");
            string absolute = Path.GetFullPath(path).Replace('\\','/'), assets = Path.GetFullPath(Application.dataPath).Replace('\\','/');
            if (!absolute.StartsWith(assets+"/",StringComparison.OrdinalIgnoreCase) || !absolute.EndsWith(".shadergraph",StringComparison.OrdinalIgnoreCase)) throw new ArgumentException("Output must be a new .shadergraph inside this project's Assets folder.");
            var parent = new DirectoryInfo(Path.GetDirectoryName(absolute));
            while (parent != null && parent.FullName.Length >= assets.Length) { if (parent.Exists && (parent.Attributes & FileAttributes.ReparsePoint) != 0) throw new ArgumentException("Linked output directories are not supported."); parent = parent.Parent; }
            return "Assets/"+absolute.Substring(assets.Length+1);
        }
    }
}
