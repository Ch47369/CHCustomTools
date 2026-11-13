# 验证记录

0.3.0 新增本地 255 份源码/152 张图或子图的数据分析、100 张 Shader Graph 的逐项适配结果，以及 63 个可导入 ASE 图（42 原创基础 + 20 本地图适配 + 1 历史完整 DeepWater）。全部可导入条目有实际 ASE 保存重载、Unity 编译和布局/Comment 保留证据。验证环境为 Unity 2022.3.10f1、ASE 1.9.9.13、URP/HDRP 14.0.8、D3D11；原场景和原角色视觉等价尚未验证。最终导入回归、核心/Editor 检查与分发哈希见 [LocalLibrary030](Evidence/LocalLibrary030/README.md) 及其 `verification.json`。下文历史计数适用于各自批次。

2026-10-22 **0.2.9 人物材质库**：479 项核心检查通过，EditorCompile 零警告/错误；实际 Unity 2022.3.10f1 / ASE 1.9.9.13 / HDRP 14.0.8 隔离项目中，四份档案通过 rules/analyze API，复杂人物输入继续阻塞，Hair/Fabric/Lit 模板实际 describe 成功，当前无独立 Eye 模板。窗口创建/关闭通过；未进行人工界面视觉审阅。35 份研究参考中 15 个 Shader × 3 目标均需适配，20 个 include 仅清点；旧 760 份固定清单三目标仍为 3/3/0 可规划，哈希一致、无分析异常。本批没有人物 ASE 图保存重载、人物 Shader 编译、角色画面对比或 GPU 测试。证据见 [CharacterMaterials029](Evidence/CharacterMaterials029/README.md)，以下旧批次的实际图验证不能转算为新增人物能力。

2026-10-22 用户随后明确要求继续验证全部已列输入，已在工作区隔离项目实际执行 457 个输入 × Built-in / URP / HDRP，共 1371 次目标评估。版本为 Unity 2022.3.10f1 / ASE 1.9.9.13 / SRP 14.0.8 / D3D11。Built-in 共 11 个输入 Generated、8 个已有图 MigrationCompiled、438 个阻塞；URP 为 6 / 0 / 443，另 8 个已有图未做跨管线迁移；HDRP 为 0 / 0 / 449，另 8 个已有图未做跨管线迁移。436 个公开 Shader 中实际生成仍仅 3 / 3 / 0；Built-in、URP 各 9 组固定像素对比最大误差均为 0。全部原始输入哈希一致。详细逐文件结果和验证边界见 [FullValidation028](Evidence/FullValidation028/README.md)。

用户的 11 个参考全部找到且与历史证据哈希匹配；8 个已有图均通过 Built-in 保存重载及编译，bubble / RotateAroundCenter / TransMovie 仍为 NeedsAgent。4 个已审核源码入口完成专项重载/编译与 76 组渲染状态检查；原创 DeepWater 重新生成，22 组关键词组合编译及渲染通过。原用户场景、全部关键词组合、设备/图形 API 和 GPU 性能未验证。没有写入用户项目或发布新 tarball。核心 427 项通过；EditorCompile、WaterAssetsCompile 均零警告/错误。

此前的完整性接续审计仅执行核心分析、.NET 数值/契约检查与 Editor C# 引用编译。固定 436 个公开 Shader 的三目标分析为 Built-in 3/436、URP 3/436、HDRP 0/436；另 324 个 include 只清点。39 个合成契约 × 3 目标共 117 项、19 个函数探针数值检查通过。该审计阶段生成数为 0，保留于 [CompletenessAudit028](Evidence/CompletenessAudit028/README.md)。下文的“本轮”保留为各自历史批次的范围，不能替代上面的最新实际验证。

本记录整理于 2026-10-21。早期转换结果来自本机隔离项目，使用用户提供的 ASE 1.9.9.13，未修改参考 Shader 或 ASE 源码。0.2.7 按用户新增请求在当前项目的 Shaders 目录交付原创水面，并更新插件依赖；各项验证环境与边界分别列出。证据见 [Evidence](Evidence)，早期样例路径及 SHA-256 见 [manifest.json](Evidence/manifest.json)。

## 0.2.8 水底焦散与十个材质开关

在同一 Unity 2022.3.10f1 / ASE 1.9.9.13 / Built-in / D3D11 环境更新原创 DeepWater。291 个原生计划节点，经 ASE 保存重载后为 385 个原生节点（33 Register、61 Get）、0 Custom Expression、34 属性和 10 个无重叠中文 Comment。保持按组依赖排列。新增 StaticSwitch 适配器限定大写 Float 属性、0/1 默认值、Create/Toggle/local shader_feature；默认、关键词名、作用域、模式、设置序列化、连线和位置重载检查通过。

焦散从水面深度与视线重建不透明水底位置，按世界 XZ 采样两层原创周期纹理，并按水深衰减，在 RGB 吸收前照亮水底场景色。动画速度置零后，在相同沙岸/石块夹具中比较焦散开关，960×600 预览中 43,171 个像素的 RGB 总差超过 6/255；整幅平均 RGB 绝对差约 0.008304。该检查证明当前夹具里开关改变可见画面，不是与原始 Shader 的等价比较，也不证明水下视角或屏幕外焦散。

全开、全关、十个效果逐项单独开启与关闭共 22 组关键词组合实际选择 ForwardBase 编译并隔离渲染，编译消息为空。另检查三份 Low/Medium/High 预设的主 Pass。生成源码中细波纹两次采样、岸沫一次采样、焦散两次采样和屏幕取色位于对应 `#ifdef` 分支内；焦散还嵌套在屏幕水下透视分支内。ShaderLab GrabPass 保留，相机深度生成、实时探针更新和网格顶点数量也不会随数值开关自动移除。没有 GPU 帧时间、Android 真机或 SRP 水面验证。

310 项核心检查通过；EditorCompile 与 WaterAssetsCompile 零警告、零错误。生成输出通过原有 Shader GUID 发布；材质的 float、有效本地关键词和焦散纹理绑定持久保存，保持既有引用。未切换或保存用户已修改的 Main 场景。原始计划、生成报告、组合报告、预览与交付哈希见 `Evidence/DepthWater028`。`visualComparisonPassed` 保持 false。

## 0.2.7 原创深度水与复杂图排列

按用户新增创作请求，在其当前 Built-in 项目制作并验证 `Water/DeepWater_ASE`。实际环境为 Unity 2022.3.10f1 / ASE 1.9.9.13 / D3D11。220 个原生计划节点经过插件/ASE 生成后包含 294 个原生节点（25 个 Register、49 个 Get），0 个 Custom Expression、18 个材质属性和 9 个中文 Comment 区。涌浪/细波纹并行，组间按数据依赖排列，常量靠近运算。矩阵输入在使用区域各自读取。

ASE 保存和重载后核对节点类型、序列化设置、双向连线、请求的模板选项、Register/Get 引用、Comment 成员与节点位置；预期 ForwardBase 同步编译通过。预览工具也实际选择索引 1 的 ForwardBase，避免把索引 0 的 GrabPass 无法 SetPass 当作编译失败。隔离 PreviewRenderUtility 中渲染沙岸、石块和水面，产出 1600×1000 预览；未切换或保存用户已修改的 Main 场景。

这份水面是原创设计，没有源画面对照，`visualComparisonPassed=false`。预览证明当前环境可以渲染水深色彩、波纹、折射和接触泡沫；不证明其他图形 API、Android 真机、URP/HDRP 或所有相机视角正确。未进行 GPU 基准。功能、依赖、使用与屏幕空间局限见 [水示例](../Samples~/Water/README.md)。原始生成响应、预览报告与交付哈希保存在 `Evidence/DepthWater027`。

`Tests/CoreChecks.csproj`：306 项通过；`Tests/EditorCompile.csproj` 和 `Tests/WaterAssetsCompile.csproj`：引用 Unity 2022.3.10f1 编译通过。排列回归覆盖独立组员穿插创建造成的错误组回路、依赖方向、常量靠近消费者、尺寸防重叠、确定性与真实环拒绝。此次实际水图同时覆盖扩展后的主节点 Register 路由与按消费者放置 Get。旧 ASE 图不会因更新插件自动改写。

## 0.2.5 规则研究的验证边界

本轮按用户要求不生成转换后的 Shader。新增的函数内联、固定算术循环、顶点 ST、全局变量和距离规则，仅完成核心计划检查与 Editor 源码引用编译。旧版的 ASE 保存重载/编译/像素结果不能作为这些新规则的运行验证。

- `Tests/CoreChecks.csproj`：135 项通过，含独立计划数据流求值、函数隔离、0/1/3/16 次循环与拒绝条件、时间分量、距离/SDF 数值、ST 纹理和阶段连线、重复 varying 写入、LOD 不丢失、图依赖检查。
- `Tests/EditorCompile.csproj`：引用 Unity 2022.3.10f1 编译；最终结果见本轮证据。
- `Tests/CorpusResearch.csproj`：只读分析 16 个公开仓库的 654 个源文件及用户的 11 个 Shader，校验读取前后哈希，所有转换验证字段保持 false。公开 Shader 373 个、include 281 个。报告见 [RuleResearch025](Evidence/RuleResearch025/public-corpus-analysis.json)。
- 373 个公开 Shader 仍有阶段、模板、依赖、LOD、宏等至少一项阻塞；报告不把数学部分可解析当作整份文件已支持。
- 没有 GPU 帧时间测试或新增画面对比，不给出“效果与性能最优”的实测排名。

## 验证矩阵

| Unity / 管线 | 插件源码引用编译 | ASE 保存并重载 | Unity Shader 编译 | 样例像素比较 |
| --- | --- | --- | --- | --- |
| 2021.3.30f1 / Built-in | 通过 | 阻塞 | 未完成 | 未完成 |
| 2022.3.10f1 / Built-in | 通过 | 三个样例通过 | 三个样例通过 | 三个样例最大 RGBA 误差均为 0 |
| 6000.0.32f1 / Built-in | 未单独执行引用编译；实际 Editor 已编译 | 三个样例通过 | 三个样例通过 | 三个样例最大 RGBA 误差均为 0 |
| 6000.0.38f1 / Built-in | 通过 | 未完成 | 未完成 | 未完成 |
| **6000.0.80f1 / Built-in** | **通过** | **三个样例通过** | **三个样例通过** | **三个样例最大 RGBA 误差均为 0** |
| 2022.3.10f1 / URP 14.0.8 | 通过 | 常量图及自动纹理图通过 | 两图主 Pass 通过 | 自动纹理图主颜色 Pass 最大 RGBA 误差为 0 |
| 2022.3.10f1 / HDRP 14.0.8 | 通过 | 显式节点计划通过 | 主 Pass 通过 | 未进行场景画面比较 |

Unity 2021.3 上，用户提供的 ASE 在 `TemplateManifest.cs` 使用了该 Unity 没有的 `SerializedProperty.boxedValue`，其自身编译错误阻止了实际验证。需要与 Unity 2021 兼容的 ASE 后才能继续，不声明该组合可运行。6000.0.38f1 的本机安装缺少 `UnityPackageManager.exe`，仅完成引用编译。

用户指定的 6000.0.80f1 实际安装在 `D:\AZ\Unity\6000.0.80f1\Editor\Unity.exe`。像素测试使用 Windows Editor、Direct3D 11；未验证其他操作系统、构建目标或图形 API。

## 测试内容

| 样例 | 入口 | 原生节点 | Custom Expression | 检查 |
| --- | --- | ---: | ---: | --- |
| TintedTexture | 自动分析并生成 | 9 | 0 | 纹理、Tint、Strength、RGB/Alpha |
| NativeMath | 自动分析后提交计划 | 19 | 0 | Exp2、Log2、Reciprocal、Append、属性与 UV |
| CustomLoop | 人工节点计划 | 8 | 1 | 带输入的循环、输入端口、代码及回退原因 |
| URP UniversalTexture | 自动分析并生成 | 5 | 0 | 管线模板、纹理、RGB/Alpha |
| URP / HDRP NativePipeline | 人工节点计划 | 3 | 0 | 常量、RGB/Alpha 拆分及目标模板主 Pass |

节点数不包含模板 Master。CustomLoop 用 `seed: FLOAT4` 和 `steps: FLOAT` 作为输入，输出 `FLOAT4`；可变迭代次数的循环没有对应的标准数学节点，因此显式采用 Custom Expression。这个测试证明受控回退流程能用，不代表分析器会自动识别并转换任意循环。

每个成功输出都由 ASE 创建图、保存，再由 ASE 重载；桥接比对节点、节点设置、双向连线和请求的模板选项。Unity 必须选中预期主 Pass，检查 Shader 支持情况并同步编译当前材质的 Pass，防止 fallback 掩盖目标 Shader 问题。

像素比较使用相同的 2×2 RGBA 测试纹理、Point 采样、32×32 Linear ARGB32 渲染目标，比较全部 RGBA 分量，阈值为 `2/255`。Built-in 材质使用 `_Tint=(0.7,0.45,0.2,0.6)`、`_Strength=1.3`。原、新 Shader 都先编译，再执行 `Graphics.Blit` 并读取像素。URP 测试明确启用管线 Shader tag，并使用主颜色 Pass；这是独立 Pass 对比，没有完整 SRP 场景、摄像机、曝光、雾或辅助 Pass 交互的等价结论。

`visualComparisonPassed=true` 只对报告对应的固定样例与参数成立。原始报告保留生成时的通用警告，末尾另附该测试的像素比较结果。HDRP 常量图的 `visualComparisonPassed` 保持 false。

核心独立检查为 55 项，覆盖支持的表达式、属性、图结构验证，以及对未适配顶点、多 Pass、混合、Stencil、变体、未知函数和其他语义的阻塞。检查区分 HLSL 局部变量 `fallback`、字符串中的关键字与真实 ShaderLab 指令；同时确认真实 Fallback、CustomEditor 等行为仍会阻塞。0.2.2 新增局部分支、swizzle 更新、const/uniform 保护、两臂一致性、属性特性适用类型和冲突 Cull 声明检查；0.2.3 新增依赖排列、尺寸不等的节点防重叠、重复排列确定性、环检测、源码步骤分组和审核签名边界检查。循环样例需要显式 Agent 计划，独立检查不将它当作自动转换支持项。引用编译结果与 Unity 实际运行结果分别记录，不能互相替代。

0.2.1 的窗口输入检查在隔离的 Unity 2022.3.10f1 / ASE 1.9.9.13 Built-in 项目执行了 20 项断言，覆盖 Project Shader 对象、系统文件路径、大小写扩展名、拒绝多文件与错误类型、UPM 路径解析、输出留在 Assets、切换输入清空旧分析，以及适配警告与实际验证失败的错误等级。此检查使用真实导入资源与 Unity 拖拽载荷 API，不包含鼠标拖放录制或新的画面对比。证据见 `Evidence/SourceChecks/window-0.2.1.json`。

0.2.2 使用目标项目文件接入的 `probe` 和 `describe` 确认 Unity 2022.3.10f1 / ASE 1.9.9.13 / Built-in 后，在 `.validation/DeepZoom2022` 隔离项目验证用户的 DeepZoomPageTable360。生成图包含 79 个原生节点、0 个 Custom Expression、6 个原名属性；ASE 保存重载、请求的模板/属性/采样设置、双向连线和 Unity D3D11 编译通过。独立编写的 ArrayLookup 回归样例也完成 33 个原生节点的生成、重载与编译。`UnityArraySmoke.Run` 共 34 项检查，证据见 `Evidence/DeepZoom2022/verification.json`。用户源文件未放入插件包；转换结果单独交付。

DeepZoom 画面测试使用反面四边形、正交相机、128×64 Linear ARGB32 目标，逐像素比较全部 RGBA。输入包含带独立 mip 颜色的 256×256 三层纹理数组、RGBAFloat 页表、非平凡缩放/偏移、四种取整输入与有效性标记、渐变备用纹理、越出 0–1 的 UV，以及非默认材质纹理 ST。4×2 与 3×3 两种网格分别测试翻转值 0、0.5、1，六组最大误差均为 0（阈值 2/255）。每组要求源画面可见且包含超过 100 种像素值，避免空白比较；另翻转三角形绕序，确认原、新 Shader 都剔除正面。以上仅为固定测试夹具，不涵盖用户的 360 球体场景、全部参数或其他平台，因此 API 生成报告的 `visualComparisonPassed` 保持 false，测试结果单独记录。

ASE 1.9.9.13 将原空 `2DArray` 默认标记写成 `white`；原、新材质的 `GetTexture` 均返回 null。原始默认值留在计划中，生成报告明确记录规范化。这项检查没有断言其他平台中未赋数组的采样颜色。新增受限适配器在其他 ASE 版本会阻塞，旧版本组合的历史测试不能证明新增功能兼容。

Unity 6000.0.80f1 的实际文件收件箱检查也已通过：读取连接信息与协议文档位置，依次请求 `probe`、`describe`、`analyze`、`generate`，得到三阶段查询结果和经过 ASE 重载、Unity 编译的原生图。证据为 `Evidence/Unity6_80/agent-inbox.json`。此项没有另做画面比较，生成响应中的 `visualComparisonPassed` 保持 false。

## 0.2.3 排列、注释与 DeepZoom UI

先通过目标项目的文件接口 `probe`、`describe` 确认实际环境与节点能力，再在 Unity 2022.3.10f1 / ASE 1.9.9.13 / Built-in / Windows D3D11 隔离项目验证。独立核心检查 55 项通过，Editor 引用编译为 0 警告、0 错误。原始响应、像素记录与摘要见 [Presentation2022/verification.json](Evidence/Presentation2022/verification.json)。

| 输出 | 计算原生节点 | Register / Get | Comment | 属性 | Unity 检查 |
| --- | ---: | ---: | ---: | ---: | ---: |
| DeepZoomPageTable360_ASE_Organized | 79 | 9 / 11 | 13 | 6 | 34 |
| DeepZoomPageTableUI_ASE | 96 | 12 / 16 | 15 | 16 | 139 |

两图均无 Custom Expression。报告的原生节点总数包含 Register/Get，分别为 99 和 124；Comment 不计入原生节点数。ASE 保存重载后核对节点、设置、双向连线、Comment 成员、Register/Get 引用与最终位置，再通过 Unity 主 Pass 编译。额外关闭全部排列选项生成 UI 图，确认仍能重载与编译，且无 Comment/Register/Get。这里验证的是从手写输入生成新图，没有实现对任意已有 ASE 图的原地整理。

360 整理版再次通过六组 128×64 RGBA 夹具对比，最大误差均为 0，并保留正面剔除。UI 使用 128×64 Linear RGBAFloat 目标，21 组状态的全部 RGBA 分量最大误差均为 0：两个 UI 全局关键词的四种组合乘三种翻转值，共 12 组；四组 Stencil；ColorMask 为 0、14、1 的三组；GUI ZTest Never/Always 两组。测试分别断言硬裁剪、Alpha 裁剪、Stencil、颜色写入和深度开关确实影响画面，并要求可见、非恒定的参考图。

UI 使用本包自有模板 `eab467e6cd0b4d27ab8e9e434d8c30e3`，保留顶点色乘 Tint、SrcAlpha 混合、矩形硬裁剪和原始 UI 渲染状态；16 个属性的类型、特性和数值默认值逐项比较。适配仅匹配已审核的完整源码 token 签名，忽略名称、空白与注释；改变 Alpha 裁剪阈值会重新产生阻塞。不能把 ASE 默认 UI 模板当成行为相同的替代模板。该 UI 图编辑需要安装 0.2.3，确保模板 GUID 可解析。

这些是固定夹具对比，未比较用户实际 360 球体或 Canvas/Mask/RectMask2D 场景；API 报告的 `visualComparisonPassed` 保持 false，夹具结果另记。新增受限设置仍只在 ASE 1.9.9.13 验证，不能由历史兼容矩阵推断其他组合可用。用户手写输入与参考 ASE 源码均未打入插件包。

## 0.2.4 Normal360 与 NormalImagePanZoom

Unity 2022.3.10f1 / ASE 1.9.9.13 / Built-in / Windows D3D11 隔离项目执行 `UnityNormalSmoke.Run`，258 项检查通过，49 组 128×64 Linear RGBAFloat 渲染状态的最大 RGBA 误差均为 0。核心独立检查 55 项通过，Editor 引用编译 0 警告、0 错误。原始响应、模板端口和逐状态像素记录见 [Normal2022/verification.json](Evidence/Normal2022/verification.json)。

| 输出 | 计算原生节点 | Register / Get | Comment | 属性 |
| --- | ---: | ---: | ---: | ---: |
| Normal360_ASE | 12 | 1 / 1 | 4 | 2 |
| NormalImagePanZoom_ASE | 31 | 6 / 6 | 7 | 11 |

两图均无 Custom Expression，经过 ASE 保存重载和主 Pass 编译。所有原属性名、类型、特性与数值默认值逐项核对；自有模板 Master 的设置也参与序列化重载比较。变更 Cull、翻转比较边界或 UI Alpha Clip 阈值时会离开审核入口并重新阻塞。

Normal360 的 26 组状态覆盖无雾/Linear/Exp/Exp2、三个翻转值、两种三角形绕序，以及严格阈值上方与单位 ST。非默认纹理 ST 与源码一样在顶点阶段应用。雾测试使用透视相机；参考画面开关 Linear 雾的最大差异为 0.3024847，确认测试实际显雾；两个绕序的参考图均可见且非常量。保留 LOD 100 和源默认 target 2.5，未增加阴影 Pass。

NormalImagePanZoom 的 23 组状态覆盖两个全局 UI 关键词的四种组合乘三个翻转值、两种额外 ViewRect、四组 Stencil、三组 ColorMask 和两组 GUI ZTest。保留原 target 2.0、PerRendererData、隐藏属性、顶点色乘 Tint、越界 Alpha、直通 Alpha 混合与硬裁剪。测试要求开关确实改变参考画面，防止空白结果通过比较。之前 DeepZoom UI 的 139 项回归检查也通过，21 组 RGBA 对比误差均为 0。

以上仅为固定夹具，未比较用户真实球体或 Canvas/Mask/RectMask2D 场景；API 的 `visualComparisonPassed` 仍为 false。源文件只用于本机隔离验证，不随插件分发。

## 复现

先在包根目录运行 README 中的 `Tests/CoreChecks.csproj` 与 `Tests/EditorCompile.csproj`。使用指定 Unity 引用时，将 `-p:UnityEditorPath=<Editor目录>` 传给后者。

在包根目录准备隔离项目：

```powershell
& './Tools~/Prepare-Validation.ps1' -AseSource '<本机合法ASE安装目录>' `
  -ProjectName Unity6_80 -UnityVersion 6000.0.80f1
& '<6000.0.80f1安装目录>/Editor/Unity.exe' -batchmode `
  -projectPath '<包根目录>/.validation/Unity6_80' `
  -executeMethod UnitySmoke.Run -logFile '<日志绝对路径>'
```

`UnitySmoke.Run` 通过后写入 `ASE_CONVERTER_SMOKE_PASS`，并退出隔离 Editor。检查该标记、生成报告与像素比较文件，不能只看启动进程的返回码。

窗口输入检查使用同一隔离项目，以 `-batchmode -executeMethod UnityWindowSmoke.Run` 启动。成功后写入 `window-smoke-result.txt` 及 `ASE_CONVERTER_WINDOW_SMOKE_PASS`，并退出隔离 Editor。它不生成或覆盖用户的 Shader。

DeepZoom 检查需自行提供获授权的输入（该文件不随插件分发），复制到隔离项目 `Assets/Source/DeepZoomPageTable360.shader`，将 `Tests/UnityArraySmoke.cs` 复制到其 `Assets/Editor`，再以 `-batchmode -executeMethod UnityArraySmoke.Run` 启动。读取 `array-smoke-result.txt`、`array-conversion.json`、`array-sample.json`、`array-pixels.txt` 和日志标记 `ASE_ARRAY_SMOKE_PASS: 34`。生成使用新路径，不会覆盖已有输出。

UI 检查同样需自行提供获授权的 `DeepZoomPageTableUI.shader`，复制到隔离项目 `Assets/Source/DeepZoomPageTableUI.shader`，将 `Tests/UnityPresentationSmoke.cs` 复制到其 `Assets/Editor`，以 `-batchmode -executeMethod UnityPresentationSmoke.Run` 启动。读取 `presentation-smoke-result.txt`、`ui-conversion.json`、`ui-template.json`、`ui-environment.json`、`ui-no-presentation.json`、`ui-pixels.txt` 与日志标记 `ASE_PRESENTATION_SMOKE_PASS: 139`。源码需匹配审核签名，具体版本与输出哈希见本次验证摘要。

Normal 检查需自行提供获授权的 `Normal360.shader` 与 `NormalImagePanZoom.shader`，复制到隔离项目 `Assets/Source`；将 `Tests/UnityNormalSmoke.cs` 复制到其 `Assets/Editor`，以 `-batchmode -executeMethod UnityNormalSmoke.Run` 启动。检查 `normal-smoke-result.txt`、`normal-pixels.txt`、两个 `normal-*-conversion.json`、模板查询结果与日志标记 `ASE_NORMAL_SMOKE_PASS: 258; cases=49`。不要对已打开的用户项目启动此批处理入口。

SRP 隔离项目需要安装对应版本的 URP 或 HDRP 包。使用 `UnitySrpSmoke.Run -asePipeline URP` 或 `HDRP`；测试通过后写入 `ASE_CONVERTER_SRP_SMOKE_PASS: <管线>`。测试脚本调用 ASE 自身的模板清单与版本选择流程，不能用占位 `.shader` 文件代替激活后的模板。不要对准备好的 SRP 项目重新运行准备脚本，因为它会重写依赖清单。

文件收件箱在非 batch Editor 中处理请求。使用同一隔离 Built-in 项目，以 `-executeMethod UnityAgentSmoke.Run` 启动，**不传 `-batchmode` 或 `-quit`**；它等待 `connection.json`，通过原子发布请求文件依次执行 `probe`、`describe`、`analyze`、`generate`，成功后写入 `agent-inbox.json` 和 `ASE_CONVERTER_AGENT_SMOKE_PASS`，并退出隔离 Editor。批处理转换本身使用 `ShaderConverterApi.ExecuteCommandLine`，与实时文件收件箱是两个入口。

## 尚未覆盖

没有验证任意 Unity/ASE/SRP 版本组合，也没有穷举材质参数、关键词组合或平台变体。HDRP 手写片元自动转换需 Agent 审查曝光、雾、Alpha、混合与 Pass。Lit、顶点变形、透明、Stencil、多 Pass 和复杂变体仍需适配与逐项验证。六个用户参考 Shader 已有 ASE 图，不能作为手写源码转换测试输入。
