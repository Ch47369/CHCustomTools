# 公开 Shader、人物材质、UI 与动画分类规则（0.3.5）

0.3.6 新增用户指定的方木君玉石文章来源身份，将公开的逻辑光源距离核心函数显式适配为三管线 ASE 原生图。目录来源 `ReviewedArticleAdaptation`，研究状态 `ReviewedLibraryPlans`；文章不是完整 Shader，标准 Lit 表面与 Emission 整合为补充实现，不增加通用自动规划能力。原参数、局部方向归一化、距离指数和两次饱和顺序、输入边界及未测速范围见 [玉石说明](JadeArticle.md) 和 [本轮证据](Evidence/JadeArticle036/README.md)。研究身份从 1,079 增至 1,080，旧身份不去重删除。

0.3.5 把已有研究身份中的 MIT AspectURP 三层视差流麻显式适配为三管线 ASE 原生图，未增加重复研究身份。目录 `ReviewedMaterialAdaptation` 与 `ReviewedLibraryPlans` 表示此固定源码经显式计划入库，不表示通用 HLSL 自动规划器支持任意类似材质。完整计算、属性、未用参数与 PC 成本见 [Showcase035](Evidence/Showcase035/README.md)。

0.3.3 继续公开源码下载与逐源码适配：41 份源码完成三目标共 123 次核心分析；37 个新增来源身份保留模型/Pass/编译指令阻塞。四个 MIT Kino 图像滤镜通过显式原生计划形成 12 份实际 ASE 图，三目标功能范围限定为输入纹理到输出纹理，不自动提供相机注入、噪声/历史帧捕获或动画宿主。语义规则增加“显式输入图像滤镜与宿主边界”，共 43 条。分类库现为 109 个同源方案、287 份图；89 个有三份文件，64 个通过限定功能映射；画面等价尚未证明。分类检索、设备与静态复杂度沿用既有入口，见 [分类库](ShaderLibrary.md)、[证据](Evidence/PublicLibrary033/README.md)、[MIT 声明](ThirdPartyNotices.md)。

0.3.1 分类库扩充为 273 个管线文件：84 个原创方案均有三管线版本，共 252 个；21 个历史单管线图在补充库显式列出缺口。新增为原创效果扩展，不增加任意源码的自动转换能力，42 条语义规则保持原有含义。设备建议/静态成本/组合检索和一键生成见 [LibraryTargets](LibraryTargets.md)，完整列表见 [ShaderLibraryIndex](ShaderLibraryIndex.md)。

0.3.0 增加本地 Shader Graph 新旧格式分析、丝袜语义规则及分类 ASE 库：42 条规则、14 个研究分类；63 个实际保存重载并编译的 ASE 图单独列出，供分类导入。1,042 个来源身份包含以前网上素材、本地源码和用户参考，研究记录不等于可用图。100 张本地 Shader Graph 中 20 张生成适配，其余 80 张保留阻塞。详细范围、所有素材身份及三管线差异见 [分类库说明](ShaderLibrary.md) 和 [本轮证据](Evidence/LocalLibrary030/README.md)。以下 0.2.9/0.2.8/0.2.6 数字按对应历史批次保留。

0.2.9 新增独立人物材质库：皮肤、头发/毛发、眼球、衣服布料四份档案，记录输入色彩空间、网格/宿主、必须保留的语义、三目标依赖、验证和成本线索。现有目录为 40 条规则（9 NativePlanner、3 AnalysisRule、1 AseMigration、27 RecipeRecorded）、13 类（增加 Eye）。人物方案均为 RecipeRecorded，分析为 AnalysisOnly，完整生成适配仍为 RequiresAdapter。新增人物窗口可 probe/describe 当前环境和已登记参考模板；实际 HDRP 检查发现 Hair、Fabric、Lit 模板，未发现独立 Eye 模板。详见 [人物材质库](CharacterMaterials.md)。

本批固定 35 份参考：19 份来自两个明确许可公开仓库，16 份为已安装官方 HDRP 14.0.8 版本参考；Graphics Git 刷新失败独立记录。15 个完整 Shader 的 45 次目标分析均需适配，20 个 include 仅清点，没有生成人物图。核心 479 项、EditorCompile 和隔离 Unity API/模板检查通过。旧冻结 760 源码回归三目标仍为 3/3/0 可规划，无异常。新证据见 [CharacterMaterials029](Evidence/CharacterMaterials029/README.md)。下文 0.2.8、12 类和旧检查数量均属于历史批次，不能当作本版完整人物转换能力；研究持久化也不等于训练了模型权重。

2026-10-22 后续实际验证已按用户要求覆盖 436 个公开 Shader、11 个参考、6 个包内样例、4 个已审核输入，共 457 个输入的三目标分析。公开源码实际 ASE 重载/编译及固定像素对比为 Built-in 3/436、URP 3/436、HDRP 0/436；未支持项保留阻塞。11 个参考中 8 个已有 ASE 图通过 Built-in 迁移重载/编译，3 个手写文件仍需阶段、Pass、状态及变体适配。4 个已审核输入另通过 76 组固定渲染状态，DeepWater 通过 22 组开关编译和渲染。实际证据见 [FullValidation028](Evidence/FullValidation028/README.md)。这不把 12 类 RecipeRecorded 升级成可自动转换，也没有 GPU 性能或原场景等价结论。

此前接续审计没有新增下载或生成 Shader：对同一清单 760 份源码核对哈希，436 个完整 Shader 分别运行三目标核心分析，共 1308 次目标评估，无分析异常。Built-in/URP 各 3/436 可规划，HDRP 0/436，留出 0/3。324 个 include 仅清点，既不表示依赖已解析，也不表示编译成功。该阶段证据见 [CompletenessAudit028](Evidence/CompletenessAudit028/README.md)，下文“本轮”仍指对应研究批次。

本次新增 `dependency-stage-contract` 为 `AnalysisRule`，不增加复杂材质转换承诺。修复 `#` 后空白指令、尖括号/宏 include 与续行的遗漏；保留合法空白写法和已知 include，阻塞未知依赖及未适配变体；同时防止同名辅助函数覆盖已映射内置变换、重复入口定义，以及顶点提前/重复 return 被当作顺序赋值。39 组合成契约在三个目标上由 65/117 提升为 117/117；原先 32 个错误“可规划”目标结果归零，4 个合法写法误拒绝归零，其他差异为阻塞原因检查。总计 427 项核心检查、19/19 函数数值探针通过，Editor 引用编译零警告/错误。规则目录现为 37 条：9 NativePlanner、2 AnalysisRule、1 AseMigration、25 RecipeRecorded。本次没有 ASE 保存重载、Unity Shader 编译、画面或 GPU 实测。

12 类为源码启发式线索，类别会重叠，不能当作逐类完整材质认证。本批被标记的完整 Shader 为水 10、皮肤 52、头发/毛发 11、布料 9、金属 50、石头 6、玉石 0、UI 43、UI 动效 24、特效 26、UV 动画 48、顶点动画 91；这些类别的自动可规划数量均为 0。玉石规则还包含 include/研究方案，但本轮完整 Shader 分类没有玉石命中，不能声称玉石转换验证通过。三个可规划样本不在这些类别命中中。

0.2.8 按用户对原创水面的追加要求，补充水底焦散与材质效果开关。深度间隙经视线修正后重建水底世界位置，XZ 投影两次采样原创无缝焦散图，随垂直水深衰减，再参与透射与吸收。它是水面上方观看时的屏幕空间近似，不修改真实水底材质或代替投影灯。八个 StaticSwitch 使用 local shader_feature，另外两个模板开关分别控制高光与探针反射。关闭焦散/细波纹/泡沫对应的采样分支可以从变体移除；折射关闭仍保留 ShaderLab GrabPass 拷贝，深度与反射探针的外部生成成本也需单独管理。实测范围见 [验证记录](Validation.md)；没有新增 GPU 基准或 SRP 水面验证，整体 `water-material` 与通用 `keyword-binding` 仍为 `RecipeRecorded`。

0.2.7 后续按用户新的创作请求，制作了原创 Built-in 深度水计划并在实际 Unity/ASE 中生成、重载、编译和渲染。它包含三向涌浪/解析斜率、双层线性斜率纹理、RGB Beer-Lambert 吸收、Fresnel、浅岸泡沫、屏幕折射和探针反射；九个功能区按依赖排列。可复用计划作者为 `Tools~/Build-DepthWaterPlan.py`，设置和边界见 [水示例](../Samples~/Water/README.md)。这是经验证的一份人工设计计划，`water-material` 仍为 `RecipeRecorded`，不能把它当作任意手写水 Shader 或 URP/HDRP 水系统的自动支持。下文的“本轮”与 0.2.6 计数保留为此前研究批次的历史记录。

本轮按用户要求只下载、阅读、分析和更新插件，没有生成转换后的 ASE Shader，没有写入用户 Unity 项目。规则保存在 `Runtime/ShaderRuleLibrary.cs`，原生计划实现保存在 `Runtime/HlslFunctionLibrary.cs` 和 `Runtime/ASEShaderConversionCore.cs`。新会话读取本文件和 `AgentProtocol.md` 即可接续，不依赖聊天记忆，也不是对模型权重进行了训练。

公开源码缓存位于工作区 `.build~/ShaderCorpus`。累计只读分析 24 个仓库的 760 份源文件：436 个 Shader 和 324 个 HLSL/CGINC。0.2.6 新增 8 个仓库以及已有 Graphics 仓库的公共函数，共 106 份文件。每个完整 Shader 分别针对 Built-in、URP、HDRP 分析；include 记录函数、依赖、规则和成本线索，不声称完成预处理或完整语义转换。另对用户提供的 11 个 Shader 检查了分析前后的 SHA-256，全部一致。

逐文件来源 URL、提交、SHA-256、三条目标管线阻塞与规则命中见 [公开样本报告](Evidence/RuleResearch026/public-corpus-analysis.json) 和 [用户参考报告](Evidence/RuleResearch026/user-reference-analysis.json)；[前后对照](Evidence/RuleResearch026/comparison.json) 使用同一冻结清单比较 0.2.5 与 0.2.6；持久数据快照见 [36 条规则与 12 个分类](Evidence/RuleResearch026/rule-catalog.json)。第三方源码不随交付包分发。UIEffect 仓库附带的 TMP 文件有单独版权说明，不能将根 MIT 许可套用于全部文件。GitHub 根许可证或仓库热度也不能证明目标设备上的画质或速度。

## 材质分类

| 类别 | 本轮收集并检查的来源 | 已记录的关键行为 | 质量与成本的选择依据 |
| --- | --- | --- | --- |
| 水 | [Stylized Water](https://github.com/danielshervheim/unity-stylized-water)、[ToonWaterShader](https://github.com/IronWarrior/ToonWaterShader)、[NVJOB](https://github.com/nvjob/nvjob-water-shader-simple-and-fast)、官方 HDRP Water | 世界空间波浪、法线、Fresnel、屏幕颜色/深度、折射、泡沫、反射、顶点位移 | 简单法线动画、卡通深度泡沫与完整 HDRP 模拟是不同成本档次。先确认所需效果，再测透明 overdraw、屏幕拷贝、模拟和反射成本 |
| 人物皮肤 | [GPU Gems 皮肤示例](https://github.com/leonardo-domingues/skin-shader-unity)、AspectURP 预积分皮肤、官方 HDRP Lit/SSS | 漫反射与高光分离、多尺度 Gaussian 散射、拉伸/厚度、衰减与阴影、Diffusion Profile | 预积分、Wrap 近似和多级散射不是等价效果；多张 RT、模糊和灯光调度必须计入预算 |
| 头发 | [Fulcrum URP Hair](https://github.com/itsFulcrum/Unity-URP-Hair-Shader)、官方 HDRP Hair | 双高光、切线偏移、切线手性、Alpha Clip/Blend、双面法线、阴影和光照循环 | 近景高光质量、发卡层叠 overdraw、透明排序与阴影稳定性都要比较；发丝系统不能只用一个普通 PBR 高光替代 |
| 布料 | 官方 HDRP Fabric、AspectURP 各向异性参考 | 棉/绒面与丝绸分别选 BSDF、Charlie 与 GGX 各向异性、预积分 FGD、切线、织纹 | 官方实现为绒面选择 Charlie D 与 Ashikhmin 可见性近似，丝绸使用各向异性 GGX；这些是已观察到的设计选择，未测量其在本项目的 GPU 时间 |
| 金属 | 官方 URP Lit、HDRP Lit/StackLit/AxF、AspectURP PBR | 金属或高光工作流、粗糙度、F0、法线、IBL/反射、必要的各向异性或涂层 | 先保证 HDR 环境反射和纹理色彩空间；是否需要额外 lobe/涂层按画质收益决定，不能仅按节点数比较 |
| 石头/岩壁 | [三平面地形岩壁](https://github.com/radiatoryang/unity-triplanar-terrain-cliff-shader)、Ronja 三平面/地形、AspectURP PBR | 世界空间三平面、坡度/地形层混合、法线、AO、细节、实例化与地形孔洞 | 三轴采样和多层地形增加带宽；检查方向权重、法线接缝、负缩放、远处 mip 和孔洞 Pass |
| 玉石 | AspectURP `Fake_BSSRDF` / `WrapLighting`、官方 HDRP Lit 的透射/散射机制 | 正背向透射、散射色、粗糙度、厚度/尺度及灯光空间 | 已收集可用于玉石的散射参考。尚未核实一个完整、独立且经过画面与性能验证的专用玉石实现；不得把近似透光当成真实体积散射 |
| UI | [UIEffect](https://github.com/mob-sakai/UIEffect)、[ParticleEffectForUGUI](https://github.com/mob-sakai/ParticleEffectForUGUI) | Canvas、Stencil、RectMask2D、软裁剪、图集、字体、顶点色 Gamma 处理 | 检查 Canvas 模式、像素大小、软度、材质合批和图集；字体 SDF 与普通 RGBA 图像分别处理 |
| UI 动效 | UIEffect 的 transition、gradation、edge shiny 与 detail | 过渡速率、额外 UV、流光、溶解、动态混合、SoftMask 依赖 | 记录采样滤波、迭代、透明覆盖和关键词；效果图和名称不构成性能证据 |
| 特效 | ParticleEffectForUGUI、官方 URP Particles、KvantSwarm、URP Fur | 粒子顶点流、预乘/加法、软粒子、拖尾、几何扩展与 GPU 仿真 | 将宿主模拟、位置纹理更新、几何放大和透明 overdraw 计入整体预算 |
| UV 动画 | UIEffect detail/transition、Ronja UV 案例、Kino 坐标效果 | 滚动、中心旋转、扭曲、序列帧、ST、时间分量和原始计算阶段 | 原生计划已实现受限纯浮点 UV 算术和顶点插值；图集索引、分支采样和导数仍需逐语义适配 |
| 顶点动画 | [UnityFurURP](https://github.com/hecomi/UnityFurURP)、[KvantSwarm](https://github.com/keijiro/KvantSwarm)、已有公告板/位移参考 | 风摆、shell/fin、位置纹理、VAT 类布局、法线重建、阴影和深度同步 | 位置变形属于待适配方案；新增顶点 UV 规则不能代替位置动画、Geometry 或 Surface Shader |

`AspectURP/Assets/PBRLibrary/SSS/WrapLighting/Depth_Jade.shader` 虽然文件名含 Jade，实际只读取场景深度并显示线性深度，而且 UV 类型需要额外审查。它不是一份完整玉石材质。分类必须检查源码，不能按文件名、截图或搜索标题认定功能。

## 已提取的具体不变量

- Stylized Water：GrabPass、相机深度、世界空间波浪和反射立方体共同参与。波高用于几何与法线估计；屏幕抓取坐标没有简单随波高一起移动。四向法线/泡沫采样、光学深度和雾/阴影变体都影响结果。不能只转换最终颜色算术。
- GPU Gems 皮肤：材质使用多组散射权重与方差、多个模糊 Irradiance 纹理、Stretch/TSM/Beckmann 等输入。多个辅助 Shader 和外部生成/调度共同构成效果，单个颜色图不足以重现。没有执行仓库脚本或渲染测试。
- Fulcrum Hair：两次 ShiftTangent 和两次高光求值，切线包含手性与非均匀缩放处理；URP 光照、阴影、GI 与透明覆盖仍需模板映射。不能假设一个各向异性节点自动替代全部代码。
- HDRP Fabric：Cotton/Wool 与 Silk 的直接光、环境光卷积和预积分资源不同，Charlie 的可见性项使用近似。保留原能量和资源约定后才能讨论进一步优化。
- 地形岩壁：除了三平面采样，还有 Terrain 控制图/层、法线、实例化、孔洞和 Pass 依赖，不能按普通网格单纹理材质处理。
- AspectURP Fake_BSSRDF：观察到扭曲后的光向、视线点积及正背向组合，并叠加主灯颜色、环境反射和雾。它是近似散射示例，不能声称拥有真实厚度传播或能量守恒的 BSSRDF。
- Kino Bloom：RGBM/浮点 HDR 平台分支，4 点降采样，Karis 亮度加权，9 点 tent 的中心/边/角权重，Gamma/Linear 转换与最终 base Alpha。金字塔 RT 调度属于宿主系统依赖。
- NoiseShader：不同 Classic/Simplex 的 hash、mod289、permute 和五次 fade 必须保留。0.2.6 支持精确标量/向量宽度和参数数目的重载；同宽精度歧义、整数/out/inout 重载仍阻塞。Common 与 1D GradientNoise 的 16 个函数探针可形成原生计划，不等于全部噪声算法或 include 已完成转换。
- Ronja Noise/SDF：发现宏定义 octave、读取循环下标的偏移、嵌套 Voronoi 搜索、SDF 的旋转/距离组合。仅部分纯数学基础符合新规则；宏、重载、计数器依赖与 Surface/光照仍需适配。
- Cyanilux URP：CBUFFER、顶点色、DepthOnly/DepthNormals、ShadowCaster/Meta、灯光与局部关键词属于模板契约。不同 URP 版本和 Depth Priming 会影响渲染，不能只保留主颜色 Pass。
- ParticleEffectForUGUI：先把插值 Alpha 量化到 1/255 步长，再乘纹理与 TextureSampleAdd；软裁剪使用像素尺寸和软度，Alpha Clip 后还执行 `color.rgb *= color.a`，最终 `Blend One One`。不能直接改成 SrcAlpha 混合或重复预乘。样本注释写 1/256，实际 `0xff` 是 255，应以表达式为准。
- UIEffect：`transition_rate()` 保留 `frac(speed * _Time.y + rate * 0.9999)`；detail 的纹理 ST、时间速度与额外 UVMask 不可遗漏。关键词、SoftMask include、采样滤波和脚本驱动参数仍属于完整效果的依赖。
- URP Fur：Shell 用 `_Time.w` 驱动风摆，按壳层索引沿世界方向扩展；包含 Geometry/Tessellation、法线/切线及 Shadow/Depth 依赖，不是普通 UV 动画。
- KvantSwarm：顶点读取三个相邻位置纹理点，叉积求 binormal 与法线，再按线宽与随机数变形；位置纹理由 Kernel 与宿主调度更新。只转换 Surface 的颜色不能重现模拟效果。

## 插件实现与剩余范围

在 0.2.5 纯函数、受限循环、纹理 ST、时间与距离规则之上，0.2.6 实现了精确宽度重载、受限标量三元选择、浮点显式转换、8 个补充数学函数，以及顶点 UV 算术 → Vertex To Fragment 的阶段计划。Builtin 的 Cull Front/Off、URP 的对应 Two Sided 选项与两者的 Geometry 队列均有显式设置。还修复属性显示名 “Blend Value” 被当作 ShaderLab 状态，以及从 HDRP 转出时源曝光语义被目标选项掩盖的问题。

303 项核心检查覆盖数值、作用域、比较相等边界、三条管线、属性解析、资源拒绝和阶段隔离；Editor 在 Unity 2022.3.10f1 引用下编译通过，零警告和错误。新增设置仍需在目标项目通过 ASE 实际保存重载与渲染验证。

`rules` 接口和分析窗口区分 `NativePlanner`、`AnalysisRule`、`AseMigration` 与 `RecipeRecorded`。当前 36 条规则包括 9 组原生计划、1 组管线分析、1 组原图迁移与 25 组待适配方案。分类线索可能重叠或误判，不能替代语义检查。`analyzeTargets` 只读返回三条目标管线的独立计划和阻塞；源 HDRP 的曝光、Pass 等审查在转向 Built-in/URP 时同样保留。

同一冻结清单的 436 个完整 Shader：旧版 0 个可规划，新版 3 个可规划，433 个仍有阻塞。3 个为 Ronja 的 `ColorBlending_Plain`、`046_Partial_Derivatives/step` 与 `uv`，Built-in 和 URP 目标均能形成结构检查通过的计划；HDRP 目标均仍须审查。它们尚未生成或渲染验证。独立留出的 KinoMirror/KinoContour 共 3 个完整 Shader 仍全部阻塞，不能宣称泛化抽查已通过。

19 个直接从公开源文件提取的纯数学函数探针由 3/19 提升到 19/19，并对可规划的图使用独立 .NET 数值参考检查，包含负数 mod、mod289、重载 permute、五次 fade、两种 GradientNoise 调用与 remap，见 [之前](Evidence/RuleResearch026/function-probes-before.json) / [之后](Evidence/RuleResearch026/function-probes-after.json)。双精度参考不模拟 GPU 的 half/fixed 量化。这些是函数级计划，不能计作 19 个完整 Shader，也不能将 324 个 include 的清点算成编译成功。剩余整文件阻塞主要包括 Surface/Lit、外部依赖、位置动画、多 Pass、Stencil、LOD、Fallback、变体和平台宏；任意 Shader 在三条管线间自由转换尚未实现。

新规则本轮没有执行 ASE 保存重载、Unity Shader 编译、画面对比或 GPU 基准。旧版已验证样例的证据不迁移为新规则的验证结论。

## 获取与复现

```powershell
# 默认集合和材质集合都保存具体提交及哈希；适当提高上限才能覆盖较大目录。
powershell.exe -NoProfile -ExecutionPolicy Bypass -File Tools~/Update-ShaderCorpus.ps1 -MaxFilesPerRepository 192
powershell.exe -NoProfile -ExecutionPolicy Bypass -File Tools~/Update-ShaderCorpus.ps1 -MaterialCollection -UseGitData -MaxFilesPerRepository 192
powershell.exe -NoProfile -ExecutionPolicy Bypass -File Tools~/Update-ShaderCorpus.ps1 -PipelineCollection -UseGitData -MaxFilesPerRepository 64
powershell.exe -NoProfile -ExecutionPolicy Bypass -File Tools~/Update-ShaderCorpus.ps1 -UiVfxCollection -UseGitData -MaxFilesPerRepository 64
# 只查询候选，不执行或导入来源代码。
powershell.exe -NoProfile -ExecutionPolicy Bypass -File Tools~/Update-ShaderCorpus.ps1 -DiscoverMaterials

dotnet restore Tests/CorpusResearch.csproj --configfile .nuget.empty.config
dotnet run --project Tests/CorpusResearch.csproj --no-restore -- .build~/ShaderCorpus/manifest.json .build~/NewEvidence
dotnet run --project Tests/CorpusResearch.csproj --no-restore -- --function-probes .build~/ShaderCorpus .build~/function-probes.json
```

下载器使用缓存，Git 模式只取需要的源码路径并禁用仓库钩子。失败的刷新保留已完成的记录与源文件。目录上限、未声明许可证、API 限流、404 和连接失败都可能影响覆盖，因此不承诺“全网所有免费 Shader”。本轮一次较大范围刷新失败后，从保留的已下载文件和固定提交恢复了缓存索引；其中官方 URP 的 192 个文件还与本地固定 Git tree 的 blob 哈希逐个核对。该恢复不代表后来失败的扩充已经下载成功。

持续积累的原则：优先补充类别缺口及可复用语义，保存精确来源和提交，加入能检出错误的回归验证，再更新状态。优先参考官方或明确许可且机制清楚的实现；“性能卓越”必须绑定 GPU、API、分辨率、场景、画质和帧时间证据，当前没有此类实测排名。

0.2.6 使用独立集合清单保存增量，不覆盖 0.2.5 的来源证据。一次 `MirzaBeig/URP-Particle-Shaders` 获取返回仓库不存在，已记录为失败且未计入 24 个仓库/760 个文件。重复的第三方示例可能跨仓库出现；文件总数按固定仓库、提交、路径计数，不代表算法数量。后续优先补实际模板、阶段和依赖适配，不以继续扩大下载数代替可执行支持。
