using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;

namespace ASEShaderConverter
{
    [Serializable] public sealed class ShaderSemanticRule
    {
        public string id, title, implementation, recipe;
        public List<string> nativeNodes = new List<string>();
        public List<string> preserve = new List<string>();
        public List<string> validation = new List<string>();
    }
    [Serializable] public sealed class ShaderReferenceRule
    {
        public string file, signature, kind, notes;
        public List<string> ruleIds = new List<string>();
    }
    [Serializable] public sealed class ShaderRuleCatalog
    {
        public string version = ShaderRuleLibrary.Version;
        public List<ShaderSemanticRule> rules = new List<ShaderSemanticRule>();
        public List<ShaderReferenceRule> references = new List<ShaderReferenceRule>();
        public List<ShaderResearchSource> publicSources = new List<ShaderResearchSource>();
        public List<ShaderCategoryRule> categories = new List<ShaderCategoryRule>();
        public List<CharacterMaterialProfile> characterProfiles = new List<CharacterMaterialProfile>();
    }
    [Serializable] public sealed class ShaderCategoryRule
    {
        public string id, title, scope;
        public List<string> ruleIds = new List<string>();
    }
    [Serializable] public sealed class ShaderResearchSource
    {
        public string repository, url, license, focus;
        public string performanceEvidence = "SourceInspected; target GPU not benchmarked";
    }
    [Serializable] public sealed class AseSourceGraphInfo
    {
        public bool present, complete;
        public string version = "";
        public int nodeCount, wireCount, customExpressionCount;
        public List<string> nodeTypes = new List<string>();
        public List<string> templateGuids = new List<string>();
        public List<string> functionGuids = new List<string>();
    }
    [Serializable] public sealed class ShaderKnowledgeReview
    {
        public string libraryVersion = ShaderRuleLibrary.Version, classification = "Handwritten", sourceSignature = "";
        public string referenceFile = "", referenceNotes = "";
        public int explicitPassCount;
        public bool surfaceShader;
        public AseSourceGraphInfo graph = new AseSourceGraphInfo();
        public SourceGraphReview sourceGraph;
        public List<ShaderSemanticRule> rules = new List<ShaderSemanticRule>();
        public List<string> notes = new List<string>();
        public List<string> materialCategories = new List<string>();
        public List<CharacterMaterialReview> characterMaterials = new List<CharacterMaterialReview>();
        public ShaderPerformanceReview performance = new ShaderPerformanceReview();
    }
    [Serializable] public sealed class ShaderPerformanceReview
    {
        public string status = "NotBenchmarked";
        public int directTextureSampleSites, loopSites, explicitPasses;
        public bool includesMayAddWork;
        public List<string> observations = new List<string>();
    }

    // Persistent knowledge is available to both the UI and agents. A recorded recipe is
    // deliberately distinct from an implemented native planner or a validated ASE output.
    public static class ShaderRuleLibrary
    {
        public const string Version = "0.3.6";
        private static ShaderSemanticRule Rule(string id, string title, string implementation, string recipe, string nodes, string preserve, string validation)
        {
            return new ShaderSemanticRule { id=id, title=title, implementation=implementation, recipe=recipe,
                nativeNodes=nodes.Split('|').Where(s=>s.Length>0).ToList(), preserve=preserve.Split('|').Where(s=>s.Length>0).ToList(), validation=validation.Split('|').Where(s=>s.Length>0).ToList() };
        }
        private static ShaderReferenceRule Reference(string file, string signature, string kind, string rules, string notes)
        {
            return new ShaderReferenceRule { file=file, signature=signature, kind=kind, ruleIds=rules.Split('|').ToList(), notes=notes };
        }
        public static ShaderRuleCatalog Catalog()
        {
            var catalog = new ShaderRuleCatalog();
            catalog.rules.AddRange(new[] {
                Rule("ase-migration", "已有 ASE 图与依赖", "AseMigration", "由 ASE 打开并迁移完整图；分析元数据只用于清点，不重建生成的 HLSL。", "", "图版本|全部 Master 和 Pass|Function 子图 GUID|模板 GUID|节点设置和原有连线", "目标 ASE 能加载全部节点和依赖|保存重载|编译各 Pass|场景比较"),
                Rule("pure-functions", "纯数学辅助函数", "NativePlanner", "按值绑定参数、隔离局部作用域，将可解析的函数体内联为原生数学节点；不按文件名或源码签名授权。", "SimpleAddOpNode|SimpleMultiplyOpNode|DotProductOpNode|FractNode|LerpOp|CosOpNode", "参数类型与返回宽度|只允许局部赋值|精确宽度重载选择|拒绝递归、隐藏采样与全局写入|原有渲染和顶点检查继续执行", "调用与手动内联的数值结果一致|不同函数名和参数名|参数作用域互不污染|恶意或不支持的函数仍阻塞"),
                Rule("exact-helper-overloads", "按参数宽度选择辅助函数重载", "NativePlanner", "按函数名、参数数目和每个标量/向量宽度精确选择；允许不同宽度重载相互调用。", "", "拒绝精度类型同宽歧义|拒绝隐式转换|不能丢掉未支持的整数、资源或 out/inout 重载|按完整签名检查递归", "标量、float2、float4 三重载数值|重载间调用|重复、精度、整数和宽度不匹配拒绝"),
                Rule("scalar-conditionals", "标量条件与三元选择", "NativePlanner", "把标量 >、<、>=、<=、==、!= 的纯数值三元表达式映射为原生 If，显式接入大于、等于、小于三个结果口。", "ConditionalIfNode", "相等边界|分支结果宽度|右结合嵌套|拒绝分支采样、导数、向量谓词与副作用", "六种比较的负、零、正边界数值|嵌套与辅助函数|条件采样和宽度变化拒绝"),
                Rule("casts-intrinsics", "浮点显式转换与补充数学函数", "NativePlanner", "支持浮点标量复制、向量截取和同宽转换；补充 rsqrt/sign/trunc/fmod/atan/atan2/asin/acos 对应原生节点。", "SwizzleNode|DynamicAppendNode|RSqrtOpNode|SignOpNode|TruncOpNode|FmodOpNode|ATan2OpNode", "整数除法不当浮点除法|保留 f/h 字面量|拒绝整数转换和非法向量扩展|fmod 的负数截断语义|不保证 half/fixed 量化等价", "显式截取/复制|负数 fmod 和 trunc|atan2 输入顺序|非法常量与深度限制"),
                Rule("vertex-uv-arithmetic", "顶点 UV 动画与阶段", "NativePlanner", "在 float2 TEXCOORD varying 的单次赋值中规划纯算术、时间与参数；由 Vertex To Fragment 在原顶点阶段求值并插值。允许 TRANSFORM_TEX 后继续组合算术。", "TextureCoordinatesNode|TimeNode|VertexToFragmentNode|SinOpNode", "源 TEXCOORD 通道|顶点求值顺序|纹理 ST|不捕获片元局部变量|未使用的未适配赋值仍阻塞|不把顶点位置变形冒充 UV", "顶点滚动和正弦数值|ST 加时间|重复写入拒绝|阶段隔离与未使用未知函数拒绝"),
                Rule("pipeline-contract", "源管线与三条目标管线检查", "AnalysisRule", "分别检测源管线并独立分析 Built-in、URP、HDRP；仅共用可移植的数值图，逐目标检查模板和状态契约。", "", "实际 RenderPipeline Tag 和 include|源 HDRP 曝光与 Pass 不因目标改成 Built-in 而消失|混合管线不能靠目标选项消除|分析不等于生成验证", "三条管线分别报告|源 HDRP 向三个目标均保留审查|注释和 Shader 名不影响检测|目标项目 probe/describe 和真实生成另验"),
                Rule("dependency-stage-contract", "依赖、指令与阶段入口审查", "AnalysisRule", "统一识别 # 后空白的指令，审核引号及尖括号 include；宏路径、续行、include_with_pragmas 等保持阻塞。入口必须唯一定义；禁止辅助函数覆盖已映射的内置坐标变换。", "", "完整依赖路径|未知 include 不静默丢弃|续行先于注释处理|顶点单一末尾 return 与赋值顺序|入口重载审查|原有管线、属性和 Pass 阻塞继续生效", "合法空白指令和已知 include 可规划|未知依赖、宏路径、变体与目标不被绕过|内置变换覆盖和提前 return 阻塞|三目标合成契约回归|ASE 保存重载与画面另验"),
                Rule("opaque-state-contract", "Built-in / URP 不透明队列与剔除", "NativePlanner", "Geometry 队列显式设为 Opaque 并校验实际模板 Tags。Built-in 静态 Cull Front/Off 使用受限模块；URP 使用已描述的 Two Sided 选项及原值。", "", "目标模板真实选项|静态 Cull Front/Off|重复作用域仍阻塞|不擅自改变 Blend 或深度|ASE API 版本与保存重载校验", "两个目标的 Front/Off 计划|Geometry 队列|内联状态边界|生成与画面需另验"),
                Rule("ui-canvas", "UI / Canvas 与裁剪", "RecipeRecorded", "保留顶点色、Tint、PerRendererData、TextureSampleAdd、Stencil 与 RectMask2D，区分硬裁剪和像素大小/软度参与的软裁剪。", "VertexColorNode|SamplerNode|LerpOp", "Canvas 渲染模式|unity_GUIZTestMode|ColorMask|UI 关键字|字体 SDF 与外部图集|Gamma/Linear 顶点色|Alpha 精度", "Mask 和 RectMask2D 内外|软度与分辨率|字体边缘|Canvas Overlay/Camera/World|项目实际 UI 渲染路径"),
                Rule("ui-animation", "UI 动效与过渡", "RecipeRecorded", "把渐变、流光、溶解和扭曲的数值部分拆为节点，保留脚本驱动参数、关键词、额外 UV 通道、裁剪和最终 Alpha/混合。", "TimeNode|FractNode|SmoothstepOpNode|LerpOp|SamplerNode", "过渡速率和 0.9999 等边界系数|遮罩与动效先后顺序|局部坐标|采样滤波|SoftMask 包依赖|原始混合因子", "动效 0/边界/1|暂停与反向|滚动视图裁剪|叠色|Gamma/Linear|外部驱动独立改变"),
                Rule("vfx-particles", "特效与粒子数据", "RecipeRecorded", "保留 Particle System 顶点流、Custom Data、序列帧、Soft Particles、深度淡化和混合；GPU 仿真、拖尾和宿主 RT 调度独立列为依赖。", "VertexColorNode|SamplerNode|CameraDepthFade|TimeNode", "加法/直通 Alpha/预乘各自的 RGB 和 Alpha|粒子 UV 数据布局|深度与相机输入|VFX Graph/几何阶段不能只用片元图替代", "所有启用的顶点流|交叠和交界|近远裁剪|CPU/GPU 粒子|模拟纹理生命周期|目标管线辅助 Pass"),
                Rule("uv-animation", "UV 动画分类方案", "RecipeRecorded", "区分滚动、中心旋转、序列帧、流图和扭曲。可用纯算术由通用节点规划；整数帧索引、派生采样、分支和过滤行为仍须适配。", "TimeNode|TextureCoordinatesNode|SinOpNode|CosOpNode|FloorOpNode|FractNode", "源 UV 通道与阶段|_Time 分量|中心、方向与速度|Atlas 格数、帧序和插帧|ST 是否存在|wrap/filter/mip", "负速度|回绕与帧边界|非方形图集|多通道|顶点计算和片元计算分别验证"),
                Rule("vertex-animation", "顶点动画分类方案", "RecipeRecorded", "按空间记录波浪、风摆、公告板、VAT、骨骼或 GPU 位置纹理的变形步骤。需要顶点位置、法线/切线及各辅助 Pass 的一致计划。", "PositionNode|SinOpNode|TimeNode|SamplerNode|CrossProductOpNode", "Object/World 空间|绝对位置或相对偏移|法线/切线重建|显式顶点 LOD|Bounds 与 Culling|ShadowCaster/Depth/Motion Vectors|仿真脚本与历史位置", "非均匀缩放|动画时刻|边界裁剪|阴影和深度|运动矢量|纹理格式及布局"),
                Rule("bounded-loops", "固定次数的算术累加循环", "NativePlanner", "展开 for(int k=N; k<M; k++) 的算术累加，最多 16 次；循环体不读取计数器、不声明局部作用域、不采样、不跳转。", "SimpleAddOpNode|SimpleMultiplyOpNode", "原始运算顺序|每轮累加和频率/振幅更新|动态循环继续阻塞|零次循环仍审查副作用", "0/1/3/16 次边界|17 次拒绝|动态界限拒绝|break、计数器读取和纹理采样拒绝"),
                Rule("vertex-texture-st", "顶点纹理 Tiling/Offset", "NativePlanner", "按 TEXCOORD 语义映射 TRANSFORM_TEX，将纹理属性接到 UV 节点 Tex 端，再经 Vertex To Fragment 保留顶点计算和插值。", "TexturePropertyNode|TextureCoordinatesNode|VertexToFragmentNode", "源 UV 通道|实际纹理 ST|原顶点阶段|无 ST 的采样不得自动加 ST|重复写入继续阻塞", "不同属性和 UV 通道|Tex 连线|阶段节点|重复写入和非法语义拒绝"),
                Rule("unity-globals-distance", "时间、相机位置与距离", "NativePlanner", "_Time 映射完整四分量 Time 节点；_WorldSpaceCameraPos 映射世界相机位置；length/distance 使用对应原生节点。", "TimeNode|WorldSpaceCameraPos|LengthOpNode|DistanceOpNode", "_Time.x=t/20、y=t、z=2t、w=3t|坐标空间由原表达式决定|distance 两端宽度一致", "时间分量不互换|距离数值|非法宽度和纹理输入拒绝"),
                Rule("noise-fbm", "确定性噪声与分层累加", "RecipeRecorded", "先内联原 hash/value-noise，再展开固定 octave。不能把不同 hash 或 value noise 替换成 ASE 的 Simplex Noise。", "FractNode|FloorOpNode|DotProductOpNode|LerpOp|SimpleMultiplyOpNode", "hash 常数和输入空间|插值曲线|每层频率、振幅与累计顺序|时间分量", "整数晶格及边界|负坐标|多个动画时刻|像素比较"),
                Rule("fresnel-space", "Fresnel、视线与彩膜", "RecipeRecorded", "保留法线和视线的坐标空间、顶点插值与片元归一化顺序；dot→saturate→1-x→pow。余弦彩膜使用原相位和频率。", "NormalizeNode|DotProductOpNode|SaturateNode|OneMinusNode|PowerNode|CosOpNode", "正反面法线符号|视线方向|乘色、强度和 Alpha|不提前在顶点归一化", "非均匀缩放|正反面|掠射角|不同相机位置"),
                Rule("ordered-passes", "多 Pass、透明混合与回退", "RecipeRecorded", "为每个 Pass 分别记录顶点/片元输出、Cull、Blend、深度和队列，并保留执行顺序与 Fallback。", "", "内壁先、外壁后|Pass 数量与顺序|独立 Cull|混合和深度|Fallback", "逐 Pass 编译|正反绕序|透明重叠|回退资源存在"),
                Rule("stencil-state", "Stencil 与材质绑定状态", "RecipeRecorded", "通过模板明确绑定 Ref/Comp/Pass/ReadMask/WriteMask，不能只复制颜色图。", "", "Stencil 的作用范围|动态属性绑定|Blend、ColorMask、ZWrite、ZTest|材质属性特性", "遮罩内外|读写掩码|状态动态修改"),
                Rule("vertex-transform", "公告板、顶点位移与插值", "RecipeRecorded", "顶点变换需要独立阶段计划；物体原点、缩放、相机方向、叉积和轴向约束不得改成片元计算。", "PositionNode|ObjectPositionNode|ObjectScaleNode|WorldSpaceCameraPos|CrossProductOpNode", "局部/世界/裁剪空间|变形顺序|粒子自定义数据|ShadowCaster 与主 Pass 同步", "非均匀和负缩放|不同相机姿态|阴影|批处理与实例化"),
                Rule("pbr-outline", "PBR 材质输出与描边", "RecipeRecorded", "使用对应 Lit/Surface Master 的完整材质输出；描边为独立 Pass，保留膨胀方式和全部灯光/阴影等辅助 Pass。", "FresnelNode|TransformDirectionNode|UnpackScaleNormalNode", "金属/高光工作流|法线空间|透明与裁剪|子图依赖|描边 Cull/深度/Pass 顺序", "光照和反射|阴影与烘焙|描边厚度|所有材质输出"),
                Rule("dissolve-alpha", "溶解、粒子与渐隐", "RecipeRecorded", "把噪声、阈值、Smoothstep 与边缘颜色拆为原生节点，并分别映射 Alpha、裁剪和混合。", "SamplerNode|SmoothstepOpNode|LerpOp|VertexColorNode|PannerNode", "加法或直通 Alpha 混合|顶点色和粒子数据|UV 动画|裁剪阈值|阴影 Pass", "溶解 0/边界/1|顶点色 Alpha|透明重叠|裁剪阴影"),
                Rule("uv-rotate-fade", "中心旋转与物体距离渐隐", "RecipeRecorded", "UV 减中心→按原时间分量做正弦/余弦旋转→加回中心。距离使用物体原点；轴向坐标在顶点阶段选择后插值。", "TextureCoordinatesNode|SinOpNode|CosOpNode|SimpleMultiplyOpNode|LerpOp|ConditionalIfNode", "_Time.x 是 t/20|半径 0.51 外返回零 RGBA，不能替换成 clip|动态 Blend/Cull|连续两次 Alpha 更新和未钳制 lerp|未使用的 _MinValue 仍保留属性|不凭空添加纹理 ST", "旋转正负速度|半径边界|距离上下界及相等|两种轴|各种混合模式"),
                Rule("chroma-key", "YCbCr 视频抠像与羽化", "RecipeRecorded", "按原 Cb/Cr 系数计算色度距离平方，使用平方阈值求遮罩；保留 4/8 邻域、对角权重、边缘分支、去溢色和亮度补偿。", "DotProductOpNode|SimpleSubtractOpNode|SaturateNode|SamplerNode|SmoothstepOpNode|LerpOp|SimpleMinOpNode", "4 邻域系数 0.2|8 邻域对角 0.707、总系数 0.12774655|原 half 精度|TexelSize 与顶点 ST|最终 Alpha 来自 smoothedMask*TInt.a，不乘源 Alpha|不擅加除零 epsilon", "纯背景/前景/边缘|阈值相等时的原行为|不同分辨率与 ST|低/高质量关键词分别验证|半精度和分支内导数"),
                Rule("keyword-binding", "关键词、属性与编译变体", "RecipeRecorded", "分别记录属性 Toggle 派生关键词、pragma 的 global/local 关键词及条件分支；名称不一致时报告，不能自动改名绑定。0.2.8 人工计划的 StaticSwitch 受限适配为大写 Float 属性、0/1 默认值、local shader_feature，关键词为属性名加 _ON；不表示任意源码宏已能转换。", "StaticSwitch", "global/local 作用域|默认分支|宏与关键词原名|多 Pass 变体|实例化与 stereo|材质 float 与关键词需同步|HLSL 分支不移除 ShaderLab GrabPass", "每种关键词组合|材质数值与关键词独立变化|目标图形 API|ASE 开关设置保存重载"),
                Rule("screen-depth", "屏幕、深度与后处理", "RecipeRecorded", "分别映射屏幕/投影坐标、深度采样和还原、全屏 Blit 及相关相机输入；禁止用普通 UV 采样代替。", "GrabScreenPosition|ScreenDepthNode|CameraDepthFade", "透视除法|线性/原始深度|反向 Z|相机深度纹理依赖|平台 Y 翻转", "透视/正交相机|前后裁剪面|不同渲染 API"),
                Rule("sdf-raymarch", "SDF 与 Raymarch 控制流", "RecipeRecorded", "识别距离函数、固定/动态步进和提前退出；原生节点不足以表达迭代时，需局部 Custom Expression 的明确输入输出及原因。", "LengthOpNode|SimpleMinOpNode|SimpleMaxOpNode", "空间和距离单位|迭代上限与提前退出|法线估计|深度写入|不将整份 Shader 塞入 Custom Expression", "命中/未命中|步进边界|相机内外|深度遮挡"),
                Rule("bloom-pyramid", "Bloom 金字塔与 HDR 编码", "RecipeRecorded", "记录预过滤、降采样、升采样与最终合成各 Pass；金字塔调度由宿主脚本负责，不能由单个材质图替代。", "SamplerNode|SimpleMinOpNode|SimpleMaxOpNode|SimpleAddOpNode", "RGBM 与浮点 HDR 分支|Karis 亮度加权|4 点均值与 9 点 tent 权重|Gamma/Linear 变换|stereo 和平台 Y 翻转|最终保留 base.a", "桌面/移动编码|HDR 高亮|抗闪烁开关|分辨率与采样尺度|多级 RT 生命周期"),
                Rule("urp-pass-contract", "URP 模板与辅助 Pass", "RecipeRecorded", "按目标 URP 版本选择实际 ASE 模板并描述端口；保持材质 CBUFFER、变体、灯光输入与辅助 Pass 契约。", "", "SRP Batcher 的 UnityPerMaterial|DepthOnly/DepthNormals 与 Depth Priming|ShadowCaster/Meta|顶点色和光照输入|RenderPipeline/LightMode", "实际 URP 版本|Depth Priming 开关|相机深度/法线|阴影和烘焙|实例化与 stereo"),
                Rule("performance-evidence", "画质与 GPU 成本评估", "RecipeRecorded", "先保持行为，再按目标设备测 GPU 时间、带宽、overdraw、变体和画质误差；静态源码只能提示成本，不能给出性能优胜结论。", "", "采样调用位置不等于每像素采样次数|include、循环与分支会改变工作量|Register/Get 整理连线不保证减少 GPU 指令|避免用未经比较的便宜算法替换原效果", "固定场景和分辨率|GPU 型号/API/管线|GPU 中位数与高分位时间|移动端热稳定|材质画面对比"),
                Rule("water-material", "水面、折射、泡沫与焦散", "RecipeRecorded", "分开记录法线/波浪、Fresnel、深度着色、折射、岸沫及顶点位移；高级水系统还依赖模拟与渲染调度。原创 Built-in 深度水计划见 Tools~/Build-DepthWaterPlan.py：三向涌浪与解析斜率、双层线性斜率纹理、RGB 吸收、岸沫，0.2.8 加入按重建水底世界位置投影的双层流动焦散和独立效果开关。既有计划在 Unity 2022.3.10f1 / ASE 1.9.9.13 / D3D11 验证；不表示通用水转换或 SRP 支持。", "SamplerNode|FresnelNode|DepthFade|PannerNode|StaticSwitch", "透明与深度写入|屏幕颜色/深度输入|位移和法线空间一致|重建水底位置与深度衰减|焦散依赖水底透视|关键词分支与共享深度|关闭折射仍有 GrabPass 拷贝|预合成背景不再次 Alpha 混合", "水深、岸边和交叠|关闭和组合开关|透明排序|移动设备带宽|水面下视角尚未验证|人工计划不能替代目标场景验证"),
                Rule("skin-jade-scattering", "皮肤、玉石与透射散射", "RecipeRecorded", "区分皮肤漫反射/高光、厚度驱动透射与管线 SSS/Diffusion Profile；简化近似不能声称等价于屏幕空间或体积散射。", "SamplerNode|DotProductOpNode|PowerNode|LerpOp", "厚度单位和光照方向|扩散轮廓资产|散射颜色与能量|正背面|阴影和曝光|皮肤与玉石分别调参", "逆光与侧光|薄厚区域|不同光色|近远距离|SSS 开关及成本"),
                Rule("character-skin", "高质量人物皮肤与微表面", "RecipeRecorded", "人物皮肤独立建档：基色、双尺度法线、粗糙度/高光、厚度与 SSS Mask、扩散资产及可选皱纹驱动；先核对真实光照模板和外部扩散调度。", "SamplerNode|BlendNormalsNode|LerpOp", "漫反射/高光分离|SSS 不替代薄部位透射|厚度单位和贴图通道|Diffusion Profile/LUT|蒙皮与运动矢量|微表面过滤", "耳鼻逆光与面部厚部位|曝光和肤色|表情驱动|近远距离/TAA|目标 ASE 模板、图重载、编译和角色画面对比"),
                Rule("eye-cornea-iris", "人物眼球、角膜与虹膜", "RecipeRecorded", "单独描述角膜外层和虹膜/巩膜内层，保留各自法线、粗糙度、IOR、虹膜凹陷/折射、瞳孔缩放和巩膜散射；普通 Lit 或 Clear Coat 不视为等价眼球 BSDF。", "SamplerNode|FresnelNode|ParallaxMappingNode|LerpOp", "内外层法线与空间|IOR 和深度单位|瞳孔不误作透明|虹膜/角膜缘遮罩|眼睑遮挡和泪线|巩膜扩散资产|透明层与反射|眼球视线动画", "眼球转动/掠射角|虹膜视差和瞳孔范围|角膜高光/环境反射|眼睑交界|曝光与近远距离|目标 Eye 模板/资产/图重载/编译/画面对比"),
                Rule("character-material-contract", "人物材质依赖与质量边界", "AnalysisRule", "为皮肤、毛发、眼球、布料返回结构化输入、三管线适配要求、语义保留、验证与成本清单；分类只作线索，不解锁生成、不证明贴图/网格/宿主依赖齐备。", "", "发卡/发丝/壳层区分|棉麻/丝绸不同 BSDF|角膜/内层区分|SSS 外部调度|HDRP 版本边界|不宣称 3A 画质或 GPU 性能", "避免 Skinning/StereoEyeIndex 等误分类|四类及组合材质分析|规则和 API 可读|已有阻塞不可被类别标签绕过|实际角色及多光照验证另做"),
                Rule("hair-anisotropy", "头发与各向异性", "RecipeRecorded", "记录沿发丝切线的高光、双叶或物理散射模型；切线空间、Alpha Clip/Blend、背面和阴影必须独立映射。", "DotProductOpNode|NormalizeNode|PowerNode", "切线方向与手性|高光位移/宽度|发卡透明排序|Alpha 裁剪|双面法线|阴影覆盖", "旋转光源|近景发丝|重叠 overdraw|TAA/MSAA|阴影闪烁"),
                Rule("fabric-sheen", "布料、绒面与织物", "RecipeRecorded", "区分棉麻绒面 Sheen、丝绸各向异性和织纹法线；选择支持相应 BSDF 的模板，普通金属 PBR 不足以替代。", "SamplerNode|DotProductOpNode|LerpOp", "Sheen lobe 与能量补偿|切线和双面|织纹尺度|法线和粗糙度|透射", "掠射角|不同光向|织纹远近抗锯齿|双面与阴影"),
                Rule("metal-stone-pbr", "金属、石头与纹理映射", "RecipeRecorded", "分别记录金属/粗糙度或高光工作流；石头常用多尺度法线、遮蔽、细节和三平面映射，不依据名称自动改写材质。", "SamplerNode|TransformDirectionNode|LerpOp", "线性/颜色纹理空间|金属反射与环境|法线合成|AO 作用位置|三平面权重和负缩放|视差成本", "HDR 光照和反射探针|不同粗糙度|非均匀缩放|纹理接缝|距离和 mip")
            });
            catalog.rules.Add(Rule("shadergraph-contract", "Shader Graph 结构与目标语义", "AnalysisRule", "只读解析多 JSON 对象及旧版嵌套 JSON，清点实际节点、属性、连线、活动目标配置、输出块、关键词与子图/函数依赖；不会把未映射图标成已转换。", "", "活动 SubTarget/材质模型|顶点与片元输出|Pass、渲染状态和变体|属性默认值及纹理 GUID|子图与宿主数据|源 HDRP 依赖不能随目标切换消失", "损坏对象/连线/槽位拒绝|旧版清点|真实目标和依赖|各目标 ASE 保存重载/编译|原场景画面对比另做"));
            catalog.rules.Add(Rule("hosiery-weave", "丝袜、薄织物与覆盖率", "RecipeRecorded", "分开记录底层皮肤与丝袜外层、纤维方向、织纹覆盖率、掠射反光、厚度/透射、拉伸与接缝；不以普通半透明黑色替代完整丝袜材质。", "SamplerNode|FresnelNode|DotProductOpNode|LerpOp", "皮肤与衣物层次|覆盖率与透明混合|织纹真实尺度和过滤|各向异性方向|拉伸/密度|双面、阴影及深度", "正面与掠射角|腿部曲面拉伸|近远距离 moire/TAA|与皮肤交叠|阴影和透明排序|目标设备 GPU 时间"));
            catalog.rules.Add(Rule("explicit-image-filters", "显式输入图像滤镜与宿主边界", "RecipeRecorded", "记录 MIT Kino 暗角、模拟/数字故障和万花筒的逐源码三管线图计划；经验证的实际图由分类库提供，不是任意后处理代码的自动转换规则。", "SamplerNode|ATan2OpNode|StaticSwitch|PowerNode|StepOpNode", "原始 RGBA 与纹理坐标|Cull Off、ZTest Always、ZWrite Off、Blend Off|全局 multi_compile|噪声和历史帧输入|动画参数积分与相机注入|色彩编码与曝光阶段", "实际 ASE 保存重载与主 Pass 编译|显式纹理浮点渲染回读|参数与关键词作用|原相机和目标设备另行验证"));
            catalog.references.AddRange(new[] {
                Reference("BillBordScale.shader","e80a3bc5a0d18bb0bec5376ea2422947d6c37330f4c6fbeddfdc37c6f90b35d3","ExistingAseGraph","ase-migration|vertex-transform","ASE 19908；94 节点。公告板必须保留顶点空间和轴向约束。"),
                Reference("bubble.shader","0f6cbdcf4a5aa21b4003b016224b10c7d66b9f981079eb21eb3e5c36442bdec2","Handwritten","pure-functions|bounded-loops|noise-fbm|fresnel-space|ordered-passes","11 属性，双 Pass。内壁 Cull Front 先画，外壁 Cull Back 后画；均 ZWrite Off、SrcAlpha。hash21 常数 123.34/456.21/45.32，value-noise 用 f*f*(3-2*f)，fbm 三层振幅 .5/.25/.125、频率倍率 2.03。保留余弦相位 (0,.33,.67)、LOD 100 及 Unlit/Transparent Fallback。规则已记录，双 Pass 模板和阶段映射尚未验证。"),
                Reference("Custom2TexStencilmask.shader","e6d13de5d1ebbf70c97b83dcd84f734e779a3f8fb2d06e8cd47158b58a48aa83","ExistingAseGraph","ase-migration|stencil-state|dissolve-alpha","ASE 19908；158 节点。保留 Stencil、粒子数据、动画、混合和全部 Pass。"),
                Reference("Custom2TexV2.shader","d2ff75658d9996133f640da6af9d1532fe4daf30bf3f730bcb6369cc76ec378c","ExistingAseGraph","ase-migration|dissolve-alpha|vertex-transform","ASE 19908；121 节点。保留双纹理动画、距离渐隐、顶点色和粒子数据。"),
                Reference("Dissolve_add.shader","4e0f69b11883c9c1670b2e8669078d808e9b753c2bc24441950c38412bd5fc60","ExistingAseGraph","ase-migration|dissolve-alpha|fresnel-space","ASE 19908；36 节点。保留溶解边缘、Fresnel、加法混合和 Alpha。"),
                Reference("Fresnel_A.shader","6adbc342a5e4e5c096e418bd04f0ef5b51cf325badf05b496f7ed622fff60564","ExistingAseGraph","ase-migration|fresnel-space","ASE 19908；17 节点。保留法线和视线变换、Fresnel 参数及 Alpha。"),
                Reference("PBR.shader","e0ab06712280325c00af603753e3de0b2f564ccda0b9831c9a12f15f0766df3a","ExistingAseGraph","ase-migration|pbr-outline","ASE 19908；151 节点。Standard Surface 输出，依赖 Square Wave 子图 GUID 6f8df4c09ccca5d42b0d3d422aad9cbd。"),
                Reference("PBR_OutLine.shader","48f3727d0c9b2fba00f8ae1f0ab8ab12315a78a9363e772dc4695c7ffb2815ef","ExistingAseGraph","ase-migration|pbr-outline|ordered-passes","ASE 19908；178 节点。Lit 模板和独立 OutLinePass；保留 7 个显式 Pass，依赖同一 Square Wave 子图。"),
                Reference("RotateAroundCenter.shader","f7eac528ee3581ceea8ba3549d17dcd7da2c30ec1eaadaada620bf39fe11413e","Handwritten","uv-rotate-fade|vertex-transform|keyword-binding","14 属性。_Color.a 的赋值需在图中改为等价局部值，不能修改全局属性。保留两次顺序更新和平方项；_MinValue 原本未使用，不应擅自接线。两个 Toggle(_True) 不代表两个数值参数相互联动。模板绑定 Blend [_Src] [_Dst]、Cull [_CullMode]；阶段和状态适配仍待验证。"),
                Reference("TransMovie.shader","a0228a509ba72606798bb04d5870efcc2f917b002794c8eca7cc2441348b2ea3","Handwritten","pure-functions|chroma-key|keyword-binding","10 属性。Queue Transparent+1、Cull Off、ZWrite Off、SrcAlpha 混合。_HighQualityFeather 的普通 Toggle 派生 _HIGHQUALITYFEATHER_ON，与 pragma multi_compile_local _ _HIGH_QUALITY_FEATHER 不同；不得自动修正。仍需局部关键词、采样分支、half 精度与 stereo 模板适配验证。"),
                Reference("Vertex offset.shader","7bffb2ee1f0ee766ff62b3362ef9a9af074940647f054e59c9876eb81536fc9a","ExistingAseGraph","ase-migration|vertex-transform|dissolve-alpha","ASE 19908；53 节点。保留顶点位移、时间动画及 ShadowCaster。")
            });
            string[] sources = {
                "Unity-Technologies/Graphics|Unity Companion License|URP、HDRP Lit/散射、Hair、Eye、Fabric、Water；人物档案另核对已安装 HDRP 14.0.8，不将更新版本特性自动回填",
                "ronja-tutorials/ShaderTutorials|No root license declared|基础、Surface、噪声、SDF、深度和后处理；只读研究，不分发其源码",
                "keijiro/NoiseShader|MIT|Classic/Simplex 噪声、hash、fade 和重载依赖",
                "keijiro/KinoBloom|MIT|Bloom 多阶段、RGBM、抗闪烁、采样权重",
                "keijiro/KinoGlitch|MIT|屏幕失真和离散噪声",
                "keijiro/KinoMotion|MIT|运动向量、深度与重建采样",
                "keijiro/KinoFog|MIT|深度重建和雾",
                "Cyanilux/URP_ShaderCodeTemplates|CC0-1.0|URP Unlit/Lit、CBUFFER、辅助 Pass 与关键词",
                "danielshervheim/unity-stylized-water|BSD-3-Clause|水面波浪、GrabPass 折射、深度、泡沫与反射",
                "IronWarrior/ToonWaterShader|Unlicense|卡通水、深度边岸泡沫",
                "nvjob/nvjob-water-shader-simple-and-fast|MIT|简单水面方案；仓库命名不等于已测得高性能",
                "leonardo-domingues/skin-shader-unity|MIT|GPU Gems 皮肤散射、卷积纹理和外部调度",
                "itsFulcrum/Unity-URP-Hair-Shader|CC0-1.0|发卡双高光、切线、URP 光照和透明/阴影",
                "radiatoryang/unity-triplanar-terrain-cliff-shader|MIT|岩壁三平面、地形混合与法线",
                "aspect-ux/AspectURP|MIT at repository root; inspect per-file notices|SSS 近似、预积分皮肤、PBR、金属与多种案例；Depth_Jade 本身仅为深度查看器",
                "blurfeng/blur-toon-urp|MIT|角色卡通光照、阴影和轮廓",
                "hecomi/UnityFurURP|No fetched root license; inspect per-file and upstream notices|URP shell/fin/geometry 毛发、风摆及阴影；不假定普通片元图可替代几何阶段",
                "ColinLeung-NiloCat/UnityURPToonLitShaderExample|MIT|角色光照分层、描边、深度偏移及 invLerp/remap",
                "keijiro/KinoVignette|MIT notice in Vignette.shader; no fetched root license|暗角半径、Falloff 与四次衰减；显式输入滤镜三管线图见分类库",
                "keijiro/KinoMirror|MIT notice in Mirror.shader; no fetched root license|原留出样本已用于显式计划适配，不再作为未见留出证据；全局对称关键词、极坐标与边界反射",
                "knapeczadam/unity-shaders|MIT at repository root; Copyright (c) 2018 Knapecz Ádám|新增 37 份基础 Surface/Lambert/BlinnPhong/Standard 示例；保留编译指令和光照模型阻塞，未当作已生成库",
                "keijiro/KinoContour|MIT|独立留出检查集；深度/法线轮廓",
                "mob-sakai/UIEffect|MIT at repository root; bundled TMP files have separate notices|UI 动效、过渡、软裁剪、额外 UV、关键词与 SoftMask 依赖",
                "mob-sakai/ParticleEffectForUGUI|MIT|UI 加法粒子、软裁剪、顶点色 Gamma 处理、Alpha 量化与预乘",
                "keijiro/KvantSwarm|Per-file notices; no fetched root license|位置纹理驱动的顶点动画、相邻点法线重建、仿真与 Surface 阴影依赖"
            };
            foreach (string entry in sources)
            {
                string[] parts = entry.Split('|');
                catalog.publicSources.Add(new ShaderResearchSource { repository=parts[0], url="https://github.com/"+parts[0], license=parts[1], focus=parts[2] });
            }
            catalog.publicSources.Add(new ShaderResearchSource {
                repository="方木君 / Unity移动端高性能玉石材质",url="https://mp.weixin.qq.com/s/fzxGFhe5DofKpyauJSPypg",
                license="Article has no explicit open-source license; attributed native-node reimplementation. Reference text/images are not distributed.",
                focus="局部逻辑光源距离近似：方向变换后归一化、距离指数、先 saturate 再 remap、乘色后再次 saturate。只提供核心函数，完整 Lit 整合是补充实现。固定源码和验证范围见 Evidence/JadeArticle036。",
                performanceEvidence="Article title claims mobile performance; not benchmarked on target hardware." });
            string[] categories = {
                "Water|水|水面、折射、泡沫与模拟|water-material", "Skin|人物皮肤|SSS、微表面、厚度及皱纹驱动|character-skin",
                "Hair|头发与毛发|发卡、发丝、shell/fin|hair-anisotropy", "Fabric|布料|绒面、丝绸、织纹|fabric-sheen",
                "Eye|眼球|角膜、虹膜、瞳孔与巩膜|eye-cornea-iris",
                "Hosiery|丝袜与薄织物|皮肤/织物层次、覆盖率、纤维方向与拉伸|hosiery-weave",
                "Metal|金属|金属工作流和反射|metal-stone-pbr", "Stone|石头|岩壁、三平面与细节|metal-stone-pbr", "Jade|玉石|逻辑光源距离近似及厚度/扩散方案；不宣称真实体积散射|skin-jade-scattering",
                "UI|UI|Canvas、Mask、字体和图集|ui-canvas", "UIEffects|UI 动效|渐变、流光、溶解和过渡|ui-animation",
                "VFX|特效|粒子、拖尾、软粒子和 GPU 仿真|vfx-particles", "UVAnimation|UV 动画|滚动、旋转、序列帧和扭曲|uv-animation",
                "VertexAnimation|顶点动画|波浪、风摆、公告板和 VAT|vertex-animation"
            };
            foreach (string category in categories)
            {
                string[] fields = category.Split('|');
                catalog.categories.Add(new ShaderCategoryRule { id=fields[0], title=fields[1], scope=fields[2], ruleIds=new List<string> { fields[3] } });
            }
            catalog.characterProfiles = CharacterMaterialLibrary.Profiles();
            return catalog;
        }

        public static ShaderKnowledgeReview Review(string source)
        {
            if (source == null) throw new ArgumentNullException("source");
            var review = new ShaderKnowledgeReview { sourceSignature = ReviewedUiProfile.Signature(source) };
            string scan = ShaderText.NormalizeDirectives(ShaderText.RemoveComments(source));
            review.explicitPassCount = Regex.Matches(scan, @"\bPass\s*\{", RegexOptions.IgnoreCase).Count;
            review.surfaceShader = Regex.IsMatch(scan, @"#pragma\s+surface\b");
            review.graph = InspectGraph(source);
            review.classification = review.graph.present ? "ExistingAseGraph" : "Handwritten";
            var catalog = Catalog();
            var reference = catalog.references.FirstOrDefault(r => r.signature == review.sourceSignature);
            var ids = new HashSet<string>(StringComparer.Ordinal);
            if (reference != null) { review.referenceFile = reference.file; review.referenceNotes = reference.notes; foreach (string id in reference.ruleIds) ids.Add(id); }
            if (review.graph.present) ids.Add("ase-migration");
            if (Regex.IsMatch(scan, @"\b(?:inline\s+)?(?:float|half|fixed)[1-4]?\s+\w+\s*\([^;{}]*\)\s*\{")) ids.Add("pure-functions");
            if (Regex.IsMatch(scan, @"\bfor\s*\(")) ids.Add("bounded-loops");
            if (Regex.IsMatch(scan, @"\?[^;{}]+:")) ids.Add("scalar-conditionals");
            if (Regex.IsMatch(scan, @"\((?:float|half|fixed)[1-4]?\)|\b(?:rsqrt|sign|trunc|fmod|atan2?|asin|acos)\s*\(")) ids.Add("casts-intrinsics");
            if (Regex.Matches(scan, @"\b(?:float|half|fixed)[1-4]?\s+(\w+)\s*\([^;{}]*\)\s*\{").Cast<Match>().GroupBy(m=>m.Groups[1].Value).Any(g=>g.Count()>1)) ids.Add("exact-helper-overloads");
            if (Regex.IsMatch(scan, @"\bTEXCOORD[0-7]\b") && Regex.IsMatch(scan, @"\b(?:_Time|TRANSFORM_TEX)\b")) ids.Add("vertex-uv-arithmetic");
            if (Regex.IsMatch(scan, @"\bTRANSFORM_TEX\s*\(")) ids.Add("vertex-texture-st");
            if (Regex.IsMatch(scan, @"\b(?:_Time|_WorldSpaceCameraPos)\b|\b(?:length|distance)\s*\(")) ids.Add("unity-globals-distance");
            if (Regex.IsMatch(scan, @"\b(?:fbm|fBm|vnoise|hash21|snoise|simplex|cnoise)\s*\(")) ids.Add("noise-fbm");
            if (Regex.IsMatch(scan, @"\b(?:Stencil|GrabPass|UsePass)\b")) ids.Add("stencil-state");
            if (review.explicitPassCount > 1 || Regex.IsMatch(scan, @"\bFallback\s+""", RegexOptions.IgnoreCase)) ids.Add("ordered-passes");
            if (review.surfaceShader || Regex.IsMatch(scan, @"UnityPBSLighting|SurfaceOutputStandard|UniversalFragmentPBR")) ids.Add("pbr-outline");
            if (Regex.IsMatch(scan, @"#pragma\s+(?:multi_compile\w*|shader_feature\w*)|\[Toggle(?:\(|\])")) ids.Add("keyword-binding");
            if (Regex.IsMatch(scan, @"_CameraDepthTexture|SAMPLE_DEPTH_TEXTURE|LinearEyeDepth|ComputeScreenPos|vert_img")) ids.Add("screen-depth");
            if (Regex.IsMatch(scan, @"(?i)\b(?:raymarch|raymarching|sdSphere|sdBox|sdf)\b")) ids.Add("sdf-raymarch");
            if (Regex.IsMatch(scan, @"UniversalPipeline|render-pipelines\.universal/")) ids.Add("urp-pass-contract");
            if (Regex.IsMatch(scan, @"DownsampleFilter|UpsampleFilter|EncodeHDR|DecodeHDR")) ids.Add("bloom-pyramid");
            if (Regex.IsMatch(scan, @"(?i)fresnel|\bpow\s*\(\s*1\s*-\s*\w+")) ids.Add("fresnel-space");
            if (Regex.IsMatch(scan, @"UnityObjectToWorldNormal|TransformObjectToWorld|\bvertex\s*\+=|\bvertex\.[xyz]+\s*[+*/-]=")) ids.Add("vertex-transform");
            ids.Add("performance-evidence");
            ids.Add("pipeline-contract");
            ids.Add("dependency-stage-contract");
            if (Regex.IsMatch(scan, @"\bCull\s+(?:Front|Off)\b|""Queue""\s*=\s*""Geometry""")) ids.Add("opaque-state-contract");
            // Category matches are research hints, never exemptions from semantic validation.
            string[] categories = { "Water:water|ocean|foam|gerstner", "Metal:metallic|metalness|metal", "Stone:stone|rock|triplanar", "Jade:jade|nephrite", "Hosiery:hosiery|stocking|pantyhose|tights|丝袜" };
            foreach (string category in categories)
            {
                string[] parts = category.Split(':');
                if (Regex.IsMatch(scan, parts[1], RegexOptions.IgnoreCase)) review.materialCategories.Add(parts[0]);
            }
            review.characterMaterials = CharacterMaterialLibrary.Review(source);
            foreach(var character in review.characterMaterials)
            {
                review.materialCategories.Add(character.profileId);
                ids.Add(catalog.characterProfiles.Single(p=>p.id==character.profileId).ruleId);
                ids.Add("character-material-contract");
            }
            bool ui = Regex.IsMatch(scan, @"UnityUI\.cginc|\bUNITY_UI_|unity_GUIZTestMode|Shader\s*""(?:Hidden/)?UI/|\buieffect\b|UIEFFECT_", RegexOptions.IgnoreCase);
            if (ui) { review.materialCategories.Add("UI"); ids.Add("ui-canvas"); }
            if (ui && Regex.IsMatch(scan, @"UIEffect|_Transition|_EdgeShiny|_Gradation|_Dissolve|_Time\.[xyzw]", RegexOptions.IgnoreCase)) { review.materialCategories.Add("UIEffects"); ids.Add("ui-animation"); }
            if (Regex.IsMatch(scan, @"Particle|SOFTPARTICLES_ON|Dissolve|Trail|Swarm|AppendShellVertex", RegexOptions.IgnoreCase)) { review.materialCategories.Add("VFX"); ids.Add("vfx-particles"); }
            if (Regex.IsMatch(scan, @"_Time\.[xyzw]") && Regex.IsMatch(scan, @"\b(?:uv\w*|texcoord\w*)\b", RegexOptions.IgnoreCase)) { review.materialCategories.Add("UVAnimation"); ids.Add("uv-animation"); }
            if (Regex.IsMatch(scan, @"#pragma\s+surface[^\r\n]*\bvertex:|\.vertex(?:\.\w+)?\s*[+*/-]?=|AppendShellVertex|\b_PositionTex\b|\bVAT\b", RegexOptions.IgnoreCase)) { review.materialCategories.Add("VertexAnimation"); ids.Add("vertex-animation"); }
            if (review.materialCategories.Contains("Water")) ids.Add("water-material");
            if (review.materialCategories.Contains("Skin") || review.materialCategories.Contains("Jade")) ids.Add("skin-jade-scattering");
            if (review.materialCategories.Contains("Hair")) ids.Add("hair-anisotropy");
            if (review.materialCategories.Contains("Fabric")) ids.Add("fabric-sheen");
            if (review.materialCategories.Contains("Hosiery")) ids.Add("hosiery-weave");
            if (review.materialCategories.Contains("Metal") || review.materialCategories.Contains("Stone")) ids.Add("metal-stone-pbr");
            review.performance.directTextureSampleSites = Regex.Matches(scan, @"\b(?:tex2D\w*|tex3D\w*|texCUBE\w*|SAMPLE_TEXTURE\w*|SAMPLE_DEPTH_TEXTURE\w*)\s*\(").Count;
            review.performance.loopSites = Regex.Matches(scan, @"\b(?:for|while|do)\b").Count;
            review.performance.explicitPasses = review.explicitPassCount;
            review.performance.includesMayAddWork = Regex.IsMatch(scan, @"#\s*include\b");
            review.performance.observations.Add("静态调用位置不是运行次数；include、循环、宏和分支未经展开。性能尚未在目标 GPU 上测量。");
            if (review.performance.loopSites > 0) review.performance.observations.Add("循环展开可能增加指令和图规模；动态迭代需独立成本与语义审查。");
            if (Regex.IsMatch(scan, @"\bBlend\s+(?!Off\b)", RegexOptions.IgnoreCase)) review.performance.observations.Add("存在混合状态：透明覆盖层数和带宽可能比节点数更影响性能。");
            if (Regex.IsMatch(scan, @"\b(?:GrabPass|_CameraOpaqueTexture|_CameraDepthTexture)\b")) review.performance.observations.Add("依赖屏幕颜色或深度：需计入相机纹理或额外 Pass 的成本。");
            review.rules = catalog.rules.Where(r => ids.Contains(r.id)).ToList();
            if (review.graph.functionGuids.Count > 0) review.notes.Add("图依赖外部 ASE Function 资产；迁移前检查这些 GUID 在目标项目中可解析。");
            if (review.graph.present && !review.graph.complete) review.notes.Add("ASE 元数据不完整；应恢复原图，不能从生成的 HLSL 假装还原。");
            if (review.rules.Any(r => r.implementation == "RecipeRecorded")) review.notes.Add("已记录的语义方案不等于自动支持；未实现的模板、阶段与状态仍由原分析器阻塞。");
            return review;
        }
        private static AseSourceGraphInfo InspectGraph(string source)
        {
            var result = new AseSourceGraphInfo();
            int begin = source.IndexOf("/*ASEBEGIN", StringComparison.Ordinal);
            if (begin < 0) return result;
            result.present = true;
            int end = source.IndexOf("ASEEND*/", begin, StringComparison.Ordinal);
            result.complete = end >= 0;
            string block = source.Substring(begin, (end >= 0 ? end : source.Length) - begin);
            result.version = Regex.Match(block, @"(?m)^\s*Version=(\d+)").Groups[1].Value;
            var types = new HashSet<string>(StringComparer.Ordinal);
            foreach (string row in block.Split('\n'))
            {
                string type = row.StartsWith("Node;", StringComparison.Ordinal) ? row.Split(';')[1].Split(',')[0] : Regex.Match(row, "^\\{\\\"type\\\":\\\"([^,\\\"]+)").Groups[1].Value;
                if (type.Length > 0)
                {
                    result.nodeCount++; types.Add(type);
                    if (type.EndsWith(".CustomExpressionNode", StringComparison.Ordinal)) result.customExpressionCount++;
                    List<string> guids = type.EndsWith(".FunctionNode", StringComparison.Ordinal) ? result.functionGuids : type.EndsWith(".TemplateMultiPassMasterNode", StringComparison.Ordinal) ? result.templateGuids : null;
                    if (guids != null) foreach (Match guid in Regex.Matches(row, @"(?<![a-f0-9])[a-f0-9]{32}(?![a-f0-9])")) if (!guids.Contains(guid.Value)) guids.Add(guid.Value);
                }
                if (row.StartsWith("WireConnection;", StringComparison.Ordinal) || row.StartsWith("{\"wire\":", StringComparison.Ordinal)) result.wireCount++;
            }
            result.nodeTypes = types.OrderBy(s => s, StringComparer.Ordinal).ToList();
            return result;
        }
    }
}
