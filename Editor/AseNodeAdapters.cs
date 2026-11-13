using System;
using System.Globalization;
using System.Reflection;
using UnityEditor;
using R = ASEShaderConverter.Editor.AseReflection;

namespace ASEShaderConverter.Editor
{
    // Restricted adapters checked against ASE 1.9.9.13's API. Each generated graph still
    // requires save/reload and compilation; source review alone is not runtime validation.
    internal static class AseNodeAdapters
    {
        private static void RequireVersion()
        {
            string version = (string)R.Call(R.Find("VersionInfo"), "StaticToString");
            if (version != "1.9.9.13") throw new NotSupportedException("Texture/attribute/render-state adapters need validation for ASE " + version + ". Verified version: 1.9.9.13.");
        }

        public static void Configure(object node, ShaderNodePlan spec, Action<object, string, string> setSerialized)
        {
            if (spec.type == "StaticSwitch")
            {
                // A deliberately narrow material checkbox adapter. Do not expose arbitrary
                // serialized fields, dynamic branches or undeclared external keywords.
                RequireVersion();
                if (string.IsNullOrEmpty(spec.propertyName) || spec.propertyName != spec.propertyName.ToUpperInvariant() ||
                    spec.propertyKind != "Float" || (spec.value != "0" && spec.value != "1"))
                    throw new ArgumentException("StaticSwitch requires an uppercase Float property and a 0/1 default.");
                setSerialized(node, "m_defaultValue", spec.value);
                setSerialized(node, "m_materialValue", spec.value);
                setSerialized(node, "m_multiCompile", "0");
                setSerialized(node, "m_isLocal", "true");
                setSerialized(node, "m_shaderStage", "All");
                setSerialized(node, "m_keywordModeType", "Toggle");
                setSerialized(node, "m_materialToggle", "true");
                setSerialized(node, "m_lockKeyword", "true");
                setSerialized(node, "m_unifiedBranch", "false");
                setSerialized(node, "m_generateKeyword", "true");
                setSerialized(node, "m_staticSwitchVarMode", "Create");
                R.Call(node, "UpdateLabels");
            }
            if (spec.propertyKind == "2DArray")
            {
                RequireVersion();
                if (spec.type != "TexturePropertyNode") throw new NotSupportedException("Texture arrays require a Texture Object property node.");
                setSerialized(node, "m_autocastMode", "LockedToTexture2DArray");
                MethodInfo method = node.GetType().GetMethod("ConfigTextureData", BindingFlags.NonPublic | BindingFlags.Instance);
                if (method == null) throw new NotSupportedException("ASE texture type adapter API changed.");
                method.Invoke(node, new[] { Enum.Parse(R.Find("TextureType"), "Texture2DArray") });
                R.Call(node, "ConfigureInputPorts");
                R.Call(node, "ConfigureOutputPorts");
            }
            foreach (NodeSetting setting in spec.settings)
            {
                if(spec.type=="TransformDirectionNode" && IsJadeDirectionTransform(spec))
                {
                    // URP TransformWorldToObjectDir defaults to normalization. Keep
                    // this exact reviewed World -> Object contract across hosts.
                    RequireVersion();setSerialized(node,setting.name,setting.value);
                }
                else if(spec.type=="TemplateLocalVarsNode"&&setting.name=="templateLocal"&&setting.value=="ase_tangentView")
                {
                    RequireVersion();setSerialized(node,"m_dataName",setting.value);
                    ResolveTemplateLocal(node,setting.value);
                }
                else if (spec.type == "StaticSwitch" && setting.name == "keyword:GlobalMultiCompile" && setting.value == "true")
                {
                    // Preserve the source's global multi_compile control. This is
                    // distinct from the default local shader_feature water toggles.
                    RequireVersion();setSerialized(node,"m_multiCompile","1");setSerialized(node,"m_isLocal","false");
                }
                else if (spec.type == "ScreenColorNode" && setting.name == "m_exposure" && setting.value == "false")
                {
                    // HDRP scene color is pre-exposed. Emission is exposed again by
                    // its host, so use ASE's inverse-exposure sampling path.
                    RequireVersion();setSerialized(node,setting.name,setting.value);
                }
                else if (spec.type == "ViewDirInputsCoordNode" && setting.name == "m_viewDirSpace" &&
                    (setting.value=="Object" || setting.value=="View" || setting.value=="World" || setting.value=="Tangent"))
                {
                    RequireVersion();setSerialized(node,setting.name,setting.value);
                }
                else if (spec.type == "TextureCoordinatesNode" && setting.name == "m_textureCoordChannel")
                {
                    int uv = int.Parse(setting.value, CultureInfo.InvariantCulture);
                    if (uv < 0 || uv > 7) throw new ArgumentOutOfRangeException("UV channel");
                    setSerialized(node, setting.name, setting.value);
                }
                else if (spec.type == "SamplerNode" && setting.name == "m_mipMode" && setting.value == "MipLevel")
                {
                    RequireVersion();
                    setSerialized(node, setting.name, setting.value);
                    R.Call(node, "ConfigureInputPorts");
                }
                else if (setting.name == "attribute:NoScaleOffset" && spec.type == "TexturePropertyNode")
                {
                    RequireVersion();
                    R.Call(node, "SetAttribute", "No Scale Offset", bool.Parse(setting.value));
                }
                else if (setting.name == "attribute:HDR" && spec.type == "ColorNode" && spec.propertyKind == "Color")
                {
                    RequireVersion();
                    R.Call(node, "SetAttribute", "HDR", bool.Parse(setting.value));
                    R.Call(node, "RefreshExternalReferences");
                }
                else if (setting.name == "attribute:Toggle" && spec.type == "RangedFloatNode" && spec.propertyKind == "Float")
                {
                    RequireVersion();
                    R.Call(node, "SetAttribute", "Toggle", bool.Parse(setting.value));
                }
                else if (setting.name == "attribute:HideInInspector" && !string.IsNullOrEmpty(spec.propertyName))
                {
                    RequireVersion();
                    R.Call(node, "SetAttribute", "Hide in Inspector", bool.Parse(setting.value));
                }
                else if (setting.name == "attribute:PerRendererData" && spec.type == "TexturePropertyNode" && spec.propertyKind == "2D")
                {
                    RequireVersion();
                    R.Call(node, "SetAttribute", "Per Renderer Data", bool.Parse(setting.value));
                }
                else throw new NotSupportedException("Unadapted ASE setting: " + spec.type + "." + setting.name);
            }
            if(spec.type=="TransformDirectionNode" && IsJadeDirectionTransform(spec))
            {
                var subtitle=node.GetType().GetMethod("UpdateSubtitle",BindingFlags.NonPublic|BindingFlags.Instance);
                if(subtitle==null)throw new NotSupportedException("ASE direction-transform presentation API changed.");
                subtitle.Invoke(node,null);
            }
            Verify(node, spec);
        }

        public static void Verify(object node, ShaderNodePlan spec)
        {
            if(spec.type=="TransformDirectionNode" && spec.settings.Count>0)
            {
                RequireVersion();
                if(!IsJadeDirectionTransform(spec))throw new NotSupportedException("Only the reviewed normalized World to Object direction transform is adapted.");
                var state=new SerializedObject((UnityEngine.Object)node);
                var from=state.FindProperty("m_from");var to=state.FindProperty("m_to");
                if(from.enumNames[from.enumValueIndex]!="World" || to.enumNames[to.enumValueIndex]!="Object" || !state.FindProperty("m_normalize").boolValue)
                    throw new InvalidOperationException("ASE lost the reviewed normalized World to Object direction transform.");
            }
            if (spec.type == "StaticSwitch")
            {
                var serialized = new SerializedObject((UnityEngine.Object)node);
                bool globalMulti=spec.settings.Exists(s=>s.name=="keyword:GlobalMultiCompile"&&s.value=="true");
                if ((int)R.Get(node, "DefaultValue") != int.Parse(spec.value, CultureInfo.InvariantCulture) ||
                    (string)R.Get(node, "CurrentKeyword") != spec.propertyName + "_ON" ||
                    !(bool)R.Get(node, "MaterialToggleActive") ||
                    serialized.FindProperty("m_multiCompile").intValue != (globalMulti?1:0) || serialized.FindProperty("m_isLocal").boolValue == globalMulti ||
                    serialized.FindProperty("m_shaderStage").enumValueIndex != 0 ||
                    serialized.FindProperty("m_unifiedBranch").boolValue || !serialized.FindProperty("m_generateKeyword").boolValue ||
                    R.Get(node, "KeywordModeTypeValue").ToString() != "Toggle")
                    throw new InvalidOperationException("ASE lost the local shader-feature material toggle: " + spec.propertyName);
            }
            if (spec.propertyKind == "2DArray" && R.Get(node, "CurrentType").ToString() != "Texture2DArray") throw new InvalidOperationException("ASE lost texture array property type.");
            foreach (NodeSetting setting in spec.settings)
            {
                if(spec.type=="TemplateLocalVarsNode"&&setting.name=="templateLocal")
                {
                    var field=new SerializedObject((UnityEngine.Object)node).FindProperty("m_dataName");
                    if(field==null||field.stringValue!=setting.value)throw new InvalidOperationException("ASE lost the reviewed template local binding.");
                    ResolveTemplateLocal(node,setting.value);
                }
                if(spec.type=="ScreenColorNode" && setting.name=="m_exposure")
                {
                    var p=new SerializedObject((UnityEngine.Object)node).FindProperty(setting.name);
                    if(p==null || p.boolValue)throw new InvalidOperationException("ASE lost inverse-exposure scene-color sampling.");
                }
                if(spec.type=="ViewDirInputsCoordNode" && setting.name=="m_viewDirSpace")
                {
                    var serialized=new SerializedObject((UnityEngine.Object)node);var p=serialized.FindProperty(setting.name);
                    if(p==null || p.enumNames[p.enumValueIndex]!=setting.value)throw new InvalidOperationException("ASE lost view-direction space.");
                }
                if (setting.name.StartsWith("attribute:", StringComparison.Ordinal))
                {
                    bool present = ((string)R.Get(node, "PropertyAttributes")).Contains("[" + setting.name.Substring(10) + "]");
                    if (present != bool.Parse(setting.value)) throw new InvalidOperationException("ASE lost property attribute: " + setting.name);
                }
                if (spec.type == "SamplerNode" && setting.name == "m_mipMode")
                {
                    foreach (object port in R.Items(R.Get(node, "InputPorts")))
                        if ((string)R.Get(port, "Name") == "Level" && !(bool)R.Get(port, "Visible")) throw new InvalidOperationException("ASE lost explicit texture LOD input.");
                }
            }
        }

        static bool IsJadeDirectionTransform(ShaderNodePlan spec)
        {
            return spec.settings.Count==3 &&
                spec.settings.Exists(s=>s.name=="m_from"&&s.value=="World") &&
                spec.settings.Exists(s=>s.name=="m_to"&&s.value=="Object") &&
                spec.settings.Exists(s=>s.name=="m_normalize"&&s.value=="true");
        }

        // ASE 1.9.9.13's native template-local node resolves its saved name lazily
        // during Draw. Resolve the same selection for headless construction/reload.
        // Only the reviewed geometry interpolator is admitted, never arbitrary HLSL.
        static void ResolveTemplateLocal(object node,string name)
        {
            RequireVersion();if(name!="ase_tangentView")throw new NotSupportedException("Unreviewed template local.");
            R.Call(node,"OnMasterNodeReplaced",R.Get(R.Get(node,"ContainerGraph"),"CurrentMasterNode"));
            var resolve=node.GetType().GetMethod("FetchDataId",BindingFlags.NonPublic|BindingFlags.Instance);
            if(resolve==null)throw new NotSupportedException("ASE template-local selection API changed.");
            resolve.Invoke(node,null);
            var serialized=new SerializedObject((UnityEngine.Object)node);
            if(serialized.FindProperty("m_currentDataIdx").intValue<0||serialized.FindProperty("m_dataName").stringValue!=name)
                throw new InvalidOperationException("Reviewed geometry interpolator is absent in the selected template.");
        }

        public static void ApplyMaster(object master, NodeSetting setting)
        {
            RequireVersion();
            if (setting.name == "pass:Unlit:Cull")
            {
                if ((string)R.Get(master, "PassName") != "Unlit" || (setting.value != "Front" && setting.value != "Off")) throw new NotSupportedException("Only Built-in Unlit Cull Front/Off is adapted.");
                object module = R.Get(R.Get(master, "PassModule"), "CullModeHelper");
                if (!(bool)R.Get(module, "ValidAndIndependent")) throw new NotSupportedException("Unlit template has no independent Cull module.");
                R.Set(module, "CurrentCullMode", setting.value);
                R.Set(module, "CustomEdited", true);
            }
            else if (setting.name != "template:ShaderModel" && setting.name != "template:RenderQueue") throw new NotSupportedException("Unadapted ASE master setting: " + setting.name);
            // Shader model/queue requests verify the real template, including actions from Surface.
            // Verification runs after all options, since option actions can set the queue.
        }

        public static void VerifyMaster(object master, NodeSetting setting)
        {
            if (setting.name == "pass:Unlit:Cull")
            {
                object module = R.Get(R.Get(master, "PassModule"), "CullModeHelper");
                if (R.Get(module, "CurrentCullMode").ToString() != setting.value) throw new InvalidOperationException("ASE lost requested Cull on the Unlit pass.");
            }
            else if (setting.name == "template:ShaderModel")
            {
                object module = R.Get(R.Get(master, "PassModule"), "ShaderModelHelper");
                if (!(bool)R.Get(module, "ValidData")) module = R.Get(R.Get(master, "SubShaderModule"), "ShaderModelHelper");
                if (!(bool)R.Get(module, "ValidData") || (string)R.Get(module, "CurrentShaderModel") != setting.value) throw new NotSupportedException("ASE template Shader Model does not match requested target " + setting.value);
            }
            else if (setting.name == "template:RenderQueue")
            {
                if (!(bool)R.Call(R.Get(R.Get(master, "SubShaderModule"), "TagsHelper"), "HasTag", "Queue", setting.value)) throw new InvalidOperationException("ASE template lost requested render queue: " + setting.value);
            }
            else throw new NotSupportedException("Unadapted ASE master setting: " + setting.name);
        }
    }
}
