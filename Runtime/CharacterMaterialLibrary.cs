using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;

namespace ASEShaderConverter
{
    [Serializable] public sealed class CharacterMaterialInput
    {
        public string name, usage, colorSpace;
    }
    [Serializable] public sealed class CharacterPipelineRequirement
    {
        public string pipeline, status = "RequiresAdapter", requirements, referenceTemplateGuid = "";
    }
    [Serializable] public sealed class CharacterMaterialProfile
    {
        public string id, title, ruleId, implementation = "RecipeRecorded", qualityTarget, geometry;
        public List<CharacterMaterialInput> inputs = new List<CharacterMaterialInput>();
        public List<CharacterPipelineRequirement> pipelines = new List<CharacterPipelineRequirement>();
        public List<string> preserve = new List<string>(), validation = new List<string>(), costs = new List<string>(), sources = new List<string>();
    }
    [Serializable] public sealed class CharacterMaterialReview
    {
        public string profileId, title, status = "AnalysisOnly";
        public List<string> matchedSignals = new List<string>();
        public List<string> requiredReview = new List<string>();
    }

    // Material production contracts, not a BSDF implementation or a quality certification.
    // No Unity dependency: the same data is returned through rules/analyze and shown in Editor.
    public static class CharacterMaterialLibrary
    {
        const string Scope = "高质量实时人物目标；分类库有已保存重载并编译的基础图和部分原图适配。完整角色贴图/宿主与原场景画面对比尚未验证，不能宣称达到 3A 成片质量。";
        static CharacterMaterialInput Input(string name, string usage, string space) { return new CharacterMaterialInput {name=name,usage=usage,colorSpace=space}; }
        static CharacterPipelineRequirement Pipeline(string id, string requirements) { return new CharacterPipelineRequirement {pipeline=id,requirements=requirements}; }
        static string[] Split(string value) { return value.Split('|'); }
        static CharacterMaterialProfile Profile(string id,string title,string rule,string geometry,string preserve,string validation,string costs)
        {
            return new CharacterMaterialProfile {id=id,title=title,ruleId=rule,qualityTarget=Scope,geometry=geometry,
                preserve=Split(preserve).ToList(),validation=Split(validation).ToList(),costs=Split(costs).ToList()};
        }
        public static List<CharacterMaterialProfile> Profiles()
        {
            var skin=Profile("Skin","人物皮肤 / SSS 与微表面","character-skin",
                "保留蒙皮、法线/切线、UV 接缝和脸部细节；表情皱纹贴图依赖动画驱动。",
                "漫反射与高光分离|次表面扩散与薄部位透射分开|厚度尺度与 Diffusion Profile 资产|粗糙度/高光工作流|微法线远距过滤|皱纹驱动与阴影/深度/运动矢量 Pass",
                "白光/彩光/逆光|耳鼻薄部位与脸颊厚部位|曝光与肤色|表情与蒙皮运动|SSS 开关|近景/远景及 TAA 稳定性",
                "屏幕空间 SSS 是外部扩散调度，不能靠几个数学节点替代|细节纹理与皱纹层带宽|透射阴影、Diffusion Profile 与帧设置成本");
            skin.inputs.AddRange(new[]{Input("Base Color","去除烘焙高光/阴影的肤色","sRGB"),Input("Normal / Micro Normal","宏观与毛孔法线，保留压缩解码及合成方式","NormalMap"),Input("Mask / Roughness / Specular","通道布局按源材质确认，不能自动假定","Linear"),Input("Thickness / Subsurface Mask","厚度量纲、归一化与扩散遮罩分别确认","Linear"),Input("Diffusion Profile / SSS LUT","管线资产或预积分 LUT；必须明确生成与绑定","AssetOrDeclaredLUT"),Input("Wrinkle Maps (optional)","表情驱动的法线/粗糙度层","DeclaredPerChannel")});
            skin.pipelines.AddRange(new[]{Pipeline("BuiltIn","需要专门光照模板和 SSS 预积分/屏幕扩散宿主；普通 Standard 的包裹漫反射不能冒充完整 SSS。"),Pipeline("URP","需要对应版本的自定义光照及 Renderer Feature/扩散调度；默认 Lit 没有等价 HDRP SSS。"),Pipeline("HDRP","参考 14.0.8 Lit 的 Subsurface Scattering/Transmission、Diffusion Profile 与相机/资源帧设置；必须 describe ASE 模板是否暴露相同功能。")});
            skin.sources.AddRange(new[]{"Unity-Technologies/Graphics: Lit + SubsurfaceScattering (installed HDRP 14.0.8)","leonardo-domingues/skin-shader-unity (MIT; external convolution host)"});

            var hair=Profile("Hair","头发 / 毛发与各向异性","hair-anisotropy",
                "区分 Hair Cards 发卡、真实 Strand 发丝与 Shell/Fin 壳层毛发；切线方向、根梢属性、Bounds 和 LOD 不能省略。",
                "发卡与发丝散射模型不混同|切线轴向与手性|双叶高光或 R/TT/TRT 各叶的原始定义|Alpha Clip/Blend/AlphaToCoverage 各自语义|双面法线与透明排序|毛发密度/风摆/历史位置|ShadowCaster/Depth/Motion Vectors 覆盖一致",
                "绕光高光移动|正背光与轮廓透射|发卡多层交叠|Alpha 边缘及阴影|LOD/距离/运动|TAA/MSAA 各自检查|壳层外轮廓与几何阶段",
                "发卡主要关注 overdraw、阴影和 Alpha 测试|真实发丝的几何/模拟与散射成本|壳层/fin 的 draw、顶点放大与剔除成本");
            hair.inputs.AddRange(new[]{Input("Base / Root-Tip Color","基色或根梢/染色分布","sRGBOrDeclared"),Input("Opacity / Coverage","覆盖率，过滤、mip 与阈值必须配套","Linear"),Input("Tangent / Flow","梳理方向和正交基；不能当普通 RGB 法线读取","LinearOrVertexAttribute"),Input("Normal / Roughness / Shift","原模型的法线、纵向/横向粗糙度与高光位移","DeclaredPerChannel"),Input("Strand / Shell Data","长度、密度、根梢、LOD、仿真及运动历史","MeshAndHostData")});
            hair.pipelines.AddRange(new[]{Pipeline("BuiltIn","需要各向异性光照模板、覆盖/双面与阴影适配；壳层/发丝几何和宿主仿真独立实现。"),Pipeline("URP","需要相应版本的灯光/阴影接口及 Alpha/DepthNormals 适配；示例双高光不是所有物理发丝模型的等价实现。"),Pipeline("HDRP","参考目标版本 Hair BSDF；14.0.8 的实际特性不能套用后续 HDRP 物理发丝功能。ASE 模板、透明深度与运动 Pass 逐项核对。")});
            hair.sources.AddRange(new[]{"Unity-Technologies/Graphics: Hair (installed HDRP 14.0.8)","itsFulcrum/Unity-URP-Hair-Shader (CC0-1.0)","hecomi/UnityFurURP (license unresolved; read-only research only)"});

            var eye=Profile("Eye","眼球 / 角膜、虹膜与巩膜","eye-cornea-iris",
                "明确角膜外壳与眼球内层是双网格还是管线单材质模型；虹膜凹陷、瞳孔遮罩、眼睑遮挡及泪线分开。",
                "角膜与内层不同法线和粗糙度|IOR 与折射空间|虹膜凹陷和视差深度|瞳孔直径及 UV 原点|巩膜散射与血丝|角膜高光与反射|眼睑遮挡/泪线及透明排序|蒙皮/视线动画与运动 Pass",
                "正视/掠射与眼球转动|瞳孔缩放及虹膜边缘|角膜高光/反射|侧面虹膜视差|眼睑/泪线遮挡|近远距离/曝光|不同光源及立体视图",
                "角膜折射采样及透明叠层|双层 BSDF 与视差步骤|巩膜 SSS 外部调度|额外眼睑/泪线几何和材质成本");
            eye.inputs.AddRange(new[]{Input("Iris / Sclera Base","虹膜和巩膜颜色；布局与遮罩按源确认","sRGB"),Input("Iris / Cornea Normal","内层与角膜外层分别保留","NormalMap"),Input("Iris / Pupil / Limbal Masks","虹膜、瞳孔和角膜缘，不把瞳孔黑色当透明","Linear"),Input("IOR / Iris Depth / Pupil Scale","量纲、折射方向及瞳孔尺寸范围","Parameters"),Input("Thickness / Diffusion Profile","巩膜散射的管线/贴图依赖","AssetOrLinear"),Input("Occlusion / Tearline","眼睑阴影与泪线是独立模型/材质或输入","DeclaredHostData")});
            eye.pipelines.AddRange(new[]{Pipeline("BuiltIn","需要角膜/虹膜分层光照与折射模板；仅加 Clear Coat 或普通透明高光不能视为等价眼球。"),Pipeline("URP","需要自定义眼球光照、折射输入与必要的 Renderer Feature；内外层法线与排序独立审查。"),Pipeline("HDRP","参考 14.0.8 Eye 的角膜/虹膜双层、IOR 与 SSS；不能以普通 HDRP Lit 输出代替 Eye BSDF，ASE Eye 模板是否可用须实际 probe/describe。")});
            eye.sources.Add("Unity-Technologies/Graphics: Eye/Eye.hlsl + Eye.cs.hlsl + EyeUtils.hlsl (installed HDRP 14.0.8)");

            var fabric=Profile("Fabric","衣服布料 / Sheen、丝绸与织纹","fabric-sheen",
                "衣服蒙皮/布料模拟是宿主功能；棉麻/绒面与丝绸分别选择散射模型，保留织纹方向与双面厚度。",
                "棉麻 Sheen 与丝绸各向异性区分|原始粗糙度/能量补偿|织纹切线方向与真实尺度|细节法线和远距过滤|双面法线/透射与厚度|污渍/磨损遮罩|蒙皮/布料模拟与 Shadow/Depth/Motion Pass",
                "棉麻/丝绸分别绕光|掠射角与褶皱|织纹近远抗锯齿|正背面及逆光透射|布料运动和阴影|曝光与多光源",
                "Sheen/各向异性 BSDF 成本|高频织纹纹理和采样过滤|双面 overdraw 与透射阴影|布料模拟、顶点运动与历史帧的额外成本");
            fabric.inputs.AddRange(new[]{Input("Base Color","织物基色/图案，去除烘焙光照","sRGB"),Input("Normal / Weave Detail","褶皱和细织纹，保留法线合成及真实尺寸","NormalMap"),Input("Roughness / Sheen / Anisotropy","具体模型与通道按原源材质确认","Linear"),Input("Tangent / Weave Direction","丝绸高光及纤维方向","LinearOrVertexAttribute"),Input("Thickness / Transmission","背光透射与双面近似","Linear"),Input("Simulation / Wear Masks (optional)","布料运动宿主及污渍/磨损层","DeclaredHostData")});
            fabric.pipelines.AddRange(new[]{Pipeline("BuiltIn","需要棉麻 Sheen/丝绸各向异性专用光照模板；普通 Standard 不提供等价 Fabric BSDF。"),Pipeline("URP","需要目标版本的自定义 Sheen/各向异性光照及双面/阴影适配；织纹数学可复用但不代表完整材质转换。"),Pipeline("HDRP","参考 14.0.8 Fabric 的 Cotton/Wool 与 Silk 模型、透射和切线设置；ASE 模板与各辅助 Pass 须实际核对。")});
            fabric.sources.Add("Unity-Technologies/Graphics: Fabric/Fabric.hlsl + Fabric.cs.hlsl (installed HDRP 14.0.8)");
            // Real template identities observed with ASE 1.9.9.13 / HDRP 14.0.8.
            // A reference identity is not a capability guarantee in another project.
            skin.pipelines.Single(p=>p.pipeline=="HDRP").referenceTemplateGuid="53b46d85872c5b24c8f4f0a1c3fe4c87";
            hair.pipelines.Single(p=>p.pipeline=="HDRP").referenceTemplateGuid="e4fe21624ace6de4b9fbaabdda0c51de";
            fabric.pipelines.Single(p=>p.pipeline=="HDRP").referenceTemplateGuid="41e04be03f2c20941bc749271be1c937";
            return new List<CharacterMaterialProfile>{skin,hair,eye,fabric};
        }

        public static List<CharacterMaterialReview> Review(string source)
        {
            if(source==null)throw new ArgumentNullException("source");
            string scan=ShaderText.NormalizeDirectives(ShaderText.RemoveComments(source));
            string semanticScan=scan;
            // Split naming conventions before exact token checks. Stereo eye indices,
            // skinning and unrelated words such as skyline must not classify a material.
            scan=Regex.Replace(scan,@"\b(?:unity_StereoEyeIndex|UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX|UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO|UNITY_VERTEX_OUTPUT_STEREO|unity_StereoEyeIndices)\b"," ");
            scan=Regex.Replace(scan,@"([A-Z]+)([A-Z][a-z])","$1 $2");
            scan=Regex.Replace(scan,@"([a-z0-9])([A-Z])","$1 $2");
            var tokens=new HashSet<string>(Regex.Matches(scan,@"[A-Za-z]+[0-9]*").Cast<Match>().Select(m=>m.Value.ToLowerInvariant()),StringComparer.Ordinal);
            var signals=new Dictionary<string,string[]> {
                {"Skin",Split("skin|subsurface|diffusionprofile|diffusion")},
                {"Hair",Split("hair|strand|strands|kajiya|marschner|fur|shell|fin")},
                {"Eye",Split("eye|eyes|cornea|corneal|iris|sclera|pupil|limbal")},
                {"Fabric",Split("fabric|cloth|cotton|wool|silk|sheen|weave")}
            };
            var result=new List<CharacterMaterialReview>();
            foreach(var profile in Profiles())
            {
                var matches=signals[profile.id].Where(tokens.Contains).ToList();
                // Diffusion alone is shared with jade and other materials; require a
                // skin/subsurface signal or an actual DiffusionProfile symbol.
                if(profile.id=="Skin" && !tokens.Contains("skin")&&!tokens.Contains("subsurface") && !Regex.IsMatch(semanticScan,@"\b_?DiffusionProfile\w*\b",RegexOptions.IgnoreCase))continue;
                // Eye-space depth and eye adaptation are camera concepts, not eyeballs.
                if(profile.id=="Eye" && !matches.Any(s=>s!="eye"&&s!="eyes") &&
                    !Regex.IsMatch(semanticScan,@"\bShader\s*""(?:[^""]*/)?Eyes?""|\bMATERIALFEATUREFLAGS_EYE\b|\b_Eye(?:Color|Normal|Mask|Iris|Pupil)\w*\b",RegexOptions.IgnoreCase))continue;
                if(matches.Count==0)continue;
                result.Add(new CharacterMaterialReview{profileId=profile.id,title=profile.title,matchedSignals=matches,
                    requiredReview=profile.preserve.Concat(new[]{"贴图、网格、宿主脚本、模板与目标环境必须实际检查；源码分类不能证明这些依赖已齐备。",Scope}).ToList()});
            }
            return result;
        }
    }
}
