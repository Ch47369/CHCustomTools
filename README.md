# Shader转换器

**0.4.1 插件更新按钮**：后台自动检查私有 Git 仓库正式标签，**只有仓库版本高于当前安装版本时，Package Manager 详情页才显示“更新到 X.Y.Z”**，无新版本时隐藏更新按钮；菜单 `Tools/Shader转换器/检查插件更新` 和主窗口也有入口，并可手动刷新。本地目录/Tarball 安装可切换为私有 Git 标签安装。0.4.0 及更早版本需先通过 Git URL 安装一次 0.4.1。按钮使用 Unity 的公开详情扩展 API；Git 包不会获得注册表包的原生工具栏按钮或左侧“更新”列表。具体操作与认证要求见 [插件更新](Documentation~/PackageUpdates.md)。

插件统一名称为 **Shader转换器**，入口为 `Tools → Shader转换器 → 打开转换器`，Project 右键菜单为 `Shader转换器 → 分析并转换`。0.4.0 按优先级新增 **手写 Shader → Shader Graph** 和 **Agent 原生 Shader Graph 建图**，保留全部现有 ASE 功能。新后端限定 Unity 2022.3 / Shader Graph 14.0.8 / URP 14.0.8 的标准 Unlit 原生子集，支持数学、Float/Range/Vector 参数、UV 与普通 2D 采样。明确声明的 ShaderLab Enum 若直接控制二路 Lerp，会在 Shader Graph 中生成 Enum `KeywordNode`；普通 Float/Lerp 保持连续 `LerpNode`，多条目/嵌套/未证明语义交给 Agent。必须明确选择标准 URP 宿主适配，Alpha 无法证明恒为 1 或其他未映射语义仍阻塞。ASE↔Shader Graph 的通用自动互转尚未实现，输入继续提供分析与 Agent 显式适配路径；完整支持表、示例与限制见 [图格式与 Agent 使用](Documentation~/ShaderConversionRoadmap.md)。

包 ID、旧 C# API、Agent 接入路径及所有已有图/资源身份保留，支持既有安装原位升级。Shader Graph 输出不要求安装 ASE；分类库继续标记为“ASE 着色器库”，其中 293 个图仍需要 ASE。实际图重载/编译与合成浮点夹具分别记录于 [0.4.0 证据](Documentation~/Evidence/GraphInterop040/README.md)，不代表原场景或跨平台画面等价。下述 0.3.x 为历史验证记录。

**0.3.7 Agent 文件接入修复**：修复 Unity/Mono 下更新连接信息或响应时 `File.Replace` 报“无法删除要被替换的文件”的恢复路径。替换失败后先保留旧文件再尝试重命名发布；真正被占用时保留旧内容并稍后重试。连接心跳失败不再阻止请求，已执行请求的响应和归档失败只重试交付，不重新执行生成。警告显示操作、完整路径和异常链。着色器库沿用 0.3.6 的 111 个方案 / 293 份图，验证见 [AgentInbox037](Documentation~/Evidence/AgentInbox037/README.md)。

**0.3.6 玉石文章方案入库**：按用户指定的[方木君《Unity移动端高性能玉石材质》](https://mp.weixin.qq.com/s/fzxGFhe5DofKpyauJSPypg)，将其逻辑光源距离核心函数适配为 Built-in、URP、HDRP 三份可编辑 ASE 图，每图 50 个实际原生节点、五组中文气泡、0 Custom Expression。原局部方向归一化、逻辑光源减号、距离指数、两次 saturate 与 remap 顺序保留；文章未提供完整 Shader，标准 Lit 表面与 Emission 整合、默认参数为补充实现，没有原完整材质/场景等价结论。统一库选择“浏览文章方案 · 逻辑光源玉石”或搜索“方木君”，安装当前管线 Shader + 材质。三管线各 14 状态公式与真实相机验证范围见 [JadeArticle036](Documentation~/Evidence/JadeArticle036/README.md)，使用见 [玉石说明](Documentation~/JadeArticle.md)。当前 111 个同源方案 / 293 份图（91/91/111）；旧图和历史证据保留。文章标题不作为移动端测速证据。

这是一个 Unity Editor 插件。它将手写 Shader 分析成可审核的节点计划，在**目标项目实际安装的 ASE** 中创建模板、原生节点与连接，由 ASE 自己生成 Shader、图元数据和校验和。不会将原 HLSL 附上伪造图元当成转换结果。

**0.3.5 完整源码效果入库**：新增 MIT AspectURP 三层视差流麻 / 动态闪片，同一源码分别生成 Built-in、URP、HDRP 可编辑 ASE 图。保留原始 RG 法线反射视差、三层独立流动、每层 1–15 次迭代、累计色带采样、速度/亮度衰减、原顺序 max 聚合和轮廓裁剪。每图 2,501 个实际原生节点、13 组中文气泡、0 Custom Expression；材质安装时生成五张原创示例贴图，可应用蓝青/金橙/紫色配色。统一库有“浏览完整源码效果”入口，也可搜“流麻”。这是 **1 个同源效果 × 3 管线**，三个配色不增加 Shader 方案数；PC 高复杂度，未做 GPU 测速。当前全库 **110 个同源方案 / 290 份图（90/90/110）**；90 个三份齐备、65 个三目标功能已映射。验证范围与使用见 [Showcase035](Documentation~/Evidence/Showcase035/README.md)，固定夹具对比不等于原场景等价。以下旧版本数字保留为历史。

当前是可验证的基础版本，不能自动转换任意 HLSL。自动路径只处理明确支持的单 Pass Unlit 子集；复杂 Shader 由 Agent 分析后提交节点计划。不支持的语义、模板和配置会产生阻塞报告。

**0.3.4 统一着色器库**：入口为 `Tools → ASE Shader Converter → ASE 着色器库`。人物材质的输入、宿主、管线要求与模板检查合并到皮肤、毛发、眼球和布料分类。默认显示当前管线全部已验证图，三目标功能映射为可选筛选；分类从实际图建立，研究来源单独计数。新增分类收录总览、每管线图数、缺版本/功能缺口计数、空结果解释与重置。本轮不新增 Shader，不解除原有模型或管线阻塞，见 [统一库说明](Documentation~/Evidence/LibraryUI034/README.md)。

**0.3.3 公开源码适配入库（历史）**：现有 **109 个同源方案、287 份真实 ASE 文件**（Built-in 89、URP 89、HDRP 109）。新增 MIT Kino 自然暗角、模拟信号故障、数字故障与历史帧混合、镜像与万花筒四个同源方案，各有三管线 ASE 图，具备原生节点排列、四组中文气泡和分类检索。89 个方案有三份文件，64 个通过三目标功能映射审查；已有 45 个方案的缺口继续明示。这四个新方案为显式输入纹理滤镜，需外部输入/历史帧/动画参数和全屏绘制，不自动注入相机。实际保存重载、编译及三管线共 39 组浮点回读检查见 [历史证据](Documentation~/Evidence/PublicLibrary033/README.md)，逐方案对应见 [三管线表](Documentation~/CrossPipelineLibrary.md)，许可见 [第三方声明](Documentation~/ThirdPartyNotices.md)。

本轮下载并分析 41 份源码，37 个新来源身份加入研究页，研究总数 1,079；自动转换器对这 41 份源码仍有阻塞，新增四个方案通过逐源码显式计划生成。下载数、独立方案数、三管线文件数和可自动转换数分别计数。

**0.3.2 历史批次**：当时库有 105 个同源方案、275 份真实 ASE 文件（Built-in 85、URP 85、HDRP 105）。85 个方案具备三份文件，60 个方案通过三目标功能映射审查；24 个人物/玉石方案存在专用散射模型缺口，DeepWater 的 HDRP 版本仍缺独立高光/环境反射开关，20 个原图方案仍缺 Built-in/URP 适配。该批次新增完整 DeepWater 的 URP/HDRP 可编辑图，保留同一套波浪、吸收、折射、焦散和岸沫计算，并修复新材质的八组关键词初始化。三份图存在不代表功能齐全或画面等价。见 [历史证据](Documentation~/Evidence/CrossPipeline032/README.md)。

分类库保留 14 类、静态复杂度、Mobile/Pad/PC 分组及组合搜索，一键生成当前管线 Shader 与 `.mat`，保留已有修改。70 个原创效果扩展有实际原生计算，不计作 210 种独立算法或网上源码转换。设备标签未做硬件测速；仅 Windows D3D11 验证，HDRP 只归 PC。见 [使用说明](Documentation~/ShaderLibrary.md)、[设备与批量操作](Documentation~/LibraryTargets.md)。

**0.3.0 首批分类库（历史）**：当时打包 63 个真实可编辑 ASE Shader：14 类 × Built-in/URP/HDRP 的 42 个原创基础图、20 个本地 HDRP Shader Graph 显式适配、1 个完整 Built-in DeepWater。所有条目通过实际 ASE 保存重载与 Unity 编译、原生节点布局及中文气泡注释验证；原图适配需要绑定原材质资源，没有原角色/原场景视觉等价结论。

本地 21 个压缩包与解压目录按数据读取，去重为 255 份源码，152 张图/子图解析成功。100 个 Shader Graph 中 20 个已生成，80 个仍有明确阻塞；StackLit、专用 Eye 模型和复杂宿主不以普通 Lit 替代。统一研究页记录 1,042 个来源身份，原始参考源码不随包分发。完整使用、三管线边界、丝袜基础及水面设置见 [分类库说明](Documentation~/ShaderLibrary.md)，计数与证据见 [LocalLibrary030](Documentation~/Evidence/LocalLibrary030/README.md)。JSON 请求 `operation: "library"` 返回同一份目录；42 条语义规则/14 个研究分类继续通过 `rules`/`analyze` 提供。

安装包为 `Releases~/com.aseshader.handwritten-converter-0.4.1.tgz`（UPM）或 `Releases~/ShaderConverter-0.4.1.zip`。以下旧版数字按历史批次保留。

**0.2.9 人物材质库**：新增皮肤、头发/毛发、眼球、衣服布料四份独立档案，记录 SSS/厚度/微法线、发卡与发丝散射/覆盖、角膜虹膜分层、棉绒 Sheen 与丝绸各向异性，以及三管线依赖、输入色彩空间、验证与成本要求。当时使用独立人物库入口，0.3.4 已合并到统一 ASE 着色器库的对应分类，可实际检查当前环境及参考模板端口；主转换器分析与 JSON API 同步显示人物语义审查。四类仍为方案/分析能力，完整生成适配尚未实现，不能宣称已训练模型权重或达到 3A 画质。479 项核心检查、EditorCompile 与隔离 HDRP API/模板检查通过，35 份人物参考的完整 Shader 三目标可规划为 0/0/0；详情见 [人物材质库](Documentation~/CharacterMaterials.md) 和 [证据](Documentation~/Evidence/CharacterMaterials029/README.md)。

2026-10-22 接续完整性审计：固定 760 份公开源码中，436 个完整 Shader 已分别执行三目标核心分析，324 个 include 仅清点；Built-in、URP 各 3/436 可规划，HDRP 为 0/436，留出样本仍为 0/3。修复依赖、预处理指令、内置变换覆盖和顶点 return 顺序的误放行，39 组合成契约探针共 117 项通过，全部核心检查 427 项通过。该审计阶段没有生成图，见 [完整性审计](Documentation~/Evidence/CompletenessAudit028/README.md)。

随后按用户“所有之前的 Shader 都继续验证”的要求，在工作区隔离项目中实际复测 **457 个输入 × 3 个目标管线**。436 个公开 Shader 中，Built-in / URP 各 3 个完成 ASE 保存重载、Unity 编译及各 9 组固定像素对比，HDRP 自动转换为 0；其余保持阻塞。11 个用户参考全部核对哈希，8 个已有 ASE 图完成 Built-in 迁移、节点/设置/引用重载与编译，3 个手写输入仍需适配。另复测 4 个已审核输入的 76 组固定渲染状态，以及 DeepWater 的 22 组开关编译与渲染。**仍不能说任意 Shader 转换功能齐全，也未证明原用户场景视觉等价。** 逐文件状态、版本和证据见 [实际整批验证](Documentation~/Evidence/FullValidation028/README.md)。

## 安装和使用

1. ASE 输出/库需安装正版 ASE 和目标管线模板。Shader Graph 输出需 Unity 2022.3、URP/Shader Graph 14.0.8 并启用 URP，无需安装 ASE。
2. 推荐使用 Git 安装：Package Manager → **Add package from git URL**，填写 `https://github.com/Ch47369/ShaderConverter.git#v0.4.1`。仓库为私有，电脑需安装 Git 并通过系统 Git 凭据管理器或 SSH 认证有访问权限的 GitHub 账号；Package Manager 不会授予仓库权限，URL 中也不应填写 Token。已配置 SSH 的电脑可使用 `ssh://git@github.com/Ch47369/ShaderConverter.git#v0.4.1`。固定标签安装对应版本；后续用插件的“检查更新”按钮升级。也可从私有仓库的 Release 下载 `.tgz`，用 Add package from tarball 安装。源码目录支持 Add package from disk 选择 `package.json`；完整着色器库需保留配套目录。
3. 打开 `Tools/Shader转换器/打开转换器`，把 Project 窗口中的 Shader 拖到“输入 Shader”栏，或把系统文件夹中的单个 `.shader` 拖到拖放区域。也可浏览、粘贴路径或使用选中 Shader；切换输入会建议一个不会覆盖原文件的 `Assets/*_ASE.shader` 输出路径。
4. 选择输出格式 ASE 或 Shader Graph；后者需选择 URP 并明确勾选标准宿主适配。点击“分析”，通过后点击“生成并验证”，获取新的 `.shader` 或 `.shadergraph`。若显示“需要适配”，列出的项目仍阻止生成；复制/导出报告供 Agent 逐项适配。已有输出不会覆盖。
5. 在 ASE 中打开输出，并在目标场景比较原、新材质的颜色、Alpha、深度和渲染状态。报告中的 `visualComparisonPassed` 默认是 false。

0.2.3 默认开启“高级：节点排列与功能说明”：依据实际连线按计算步骤从左到右分层，添加中文 Comment 说明，将较长的数值连线换成命名的 Register/Get 引用。纹理对象靠近采样器摆放；纹理、采样器等资源不会强行写进数值 Register。可以分别关闭排列、注释、长线整理，或调整长线距离。需要重新整理旧版转换结果时，选择原手写 Shader 重新生成新文件；直接输入已有 ASE 图仍走 ASE 迁移流程。

0.2.7 修复复杂图中功能组被误判为环并拆成大量小框的问题：先对功能组整体排序，再在组内按连线分层；常量靠近使用位置，同列按上游位置排序。长线的 Get 靠近各自使用节点，远距离主节点输入也经过命名 Register/Get。保存前调用 ASE 自己的属性排序，避免纹理对象连接后的属性顺序规范化造成重载误报。此次原创深度水已经在 Unity 2022.3.10f1 / ASE 1.9.9.13 / Built-in / D3D11 中保存重载、编译并渲染预览，九个中文功能区解释各段作用；使用和成本边界见 [DeepWater 示例](Samples~/Water/README.md)。这不增加任意水 Shader 的自动转换承诺，也不会自动整理用户所有已有 ASE 图。

0.2.8 为 DeepWater 加入按水底世界位置投影的双层流动焦散，以及八个独立本地关键词开关；高光与探针反射使用模板的两个 Material Toggle。StaticSwitch 受限适配器只接受大写 Float 属性和 0/1 默认值，通过 ASE 创建、保存、重载校验。水底透视关闭时裁掉屏幕采样和焦散贡献，ShaderLab GrabPass 拷贝仍存在。各开关的实际作用、共享成本与材质预设见 [水示例](Samples~/Water/README.md)。这不是通用 HLSL 关键词自动转换功能。

0.2.4 新增两个经源码签名审核的转换入口。`Normal360` 使用原生 UV、条件选择和纹理采样节点，由自带 `Normal360Fog` 模板保留顶点阶段的纹理缩放/偏移、LOD 100、双面显示及 Unity 的无雾/Linear/Exp/Exp2 变体；`NormalImagePanZoom` 使用原生采样、缩放平移与越界 Alpha 节点，由 `UiPanZoom` 模板保留原 Shader Model 2.0、顶点色与 Tint、直通 Alpha 混合、Stencil、ColorMask、GUI 深度和两个 UI 关键词。新模板随插件安装，编辑这些输出时需要保留插件。仅匹配已审核的源码版本，行为改动后会继续阻塞，不能据此推断任意带雾或 UI Shader 均可自动转换。

本次 DeepZoomPageTableUI 已通过源码签名审核，使用插件自带的 UI 模板保留 SrcAlpha 混合、Stencil、ColorMask、GUI 深度测试、顶点色乘 Tint、矩形硬裁剪和两个全局 UI 变体。该路径仅支持已审核的源码版本，不是通用 UI Shader 自动转换器；改动行为后仍会返回阻塞。Unity 2022.3.10f1 / ASE 1.9.9.13 / D3D11 已完成图重载、编译及 21 组固定状态画面对比。UI 输出的图编辑依赖本包中的 `Editor/Templates/UiStraightAlpha.shader`，请先更新插件再导入该输出。

0.2.2 已适配 Built-in 的 `2DArray`、`tex2Dlod` / 纹理数组显式 LOD 采样、`round`、局部赋值与受限 `if/else`、`[NoScaleOffset]`、`[Toggle]`、`Cull Front`、`Queue=Geometry` 和 target 3.5。相关 ASE 设置适配器目前限定 **ASE 1.9.9.13**，其他版本需重新验证。用户的 DeepZoomPageTable360 已在 Unity 2022.3.10f1 / ASE 1.9.9.13 Built-in 隔离项目生成 79 个原生节点，完成重载、编译及六组固定参数的像素比较；这不代表原场景已验证。

0.2.5 增加可复用的纯数学辅助函数内联、固定次数算术累加循环、顶点 `TRANSFORM_TEX`、时间/相机变量及 length/distance 原生计划规则，不再只依赖逐文件签名适配。仍限制在明确支持的单 Pass Unlit 子集，所有原有阶段、属性和渲染状态检查继续生效。新规则通过 .NET 数值及结构检查；本轮按用户要求没有生成 Shader，因此尚无这些新规则的 ASE 保存重载、Unity Shader 编译及画面对比证据。

0.2.6 增加精确参数宽度的函数重载、纯数值三元选择、浮点显式转换、8 个补充数学函数，以及顶点 UV 算术到片元插值的原生计划。Built-in 的 Cull Front/Off 和 URP 对应 Two Sided 选项分别适配；Geometry 队列在两者中显式校验。修复属性显示名 “Blend Value” 被误判为渲染状态的问题。分析窗口新增 Built-in / URP / HDRP 独立检查，报告保留 `sourcePipeline` 和目标 `pipeline`；源 HDRP 的曝光/Pass 审查不会因改选目标而消失。

规则库现在记录水、皮肤、头发/毛发、布料、金属、石头、玉石、UI、UI 动效、特效、UV 动画、顶点动画 12 类。分类与方案不等于完整效果已能转换。累计研究 24 个仓库的 760 份源码；同一批 436 个完整 Shader 的可规划数量由 0 增至 3，19 个数学函数探针由 3 个增至 19 个；留出的 3 个完整 Shader 仍有阻塞。303 项核心检查与 Editor 引用编译通过，本轮生成的 ASE Shader 为 0。具体来源、前后差异和限制见 [材质与动效规则库](Documentation~/MaterialLibrary.md)。

分析窗口新增“转换规则与已记录的语义”，显示原生计划规则、待适配方案、已有 ASE 图版本和 Function 依赖，并给出材质分类线索、静态采样位置/循环/Pass 等成本线索。规则库可通过 `rules` 操作读取。`RecipeRecorded` 不表示自动支持，静态成本信息不表示 GPU 基准成绩。水、皮肤、头发、布料、金属、石头和玉石的分类研究、来源及限制见 [材质规则库](Documentation~/MaterialLibrary.md)。第三方完整源码仅缓存在 `.build~`，不随包分发。

你这次提供的 11 个 Shader 中，8 个已有 ASE 图，应由 ASE 打开和迁移；3 个手写文件的多 Pass、阶段、混合/关键词语义已记录，但仍需要模板和语义适配。它们不能用于证明任意手写源码已能自动转换。`Samples~/Handwritten` 提供无 ASE 元数据的转换输入。

参考图的分析见 `Documentation~/ReferenceAnalysis.md`。`Samples~/Generated` 提供实际由 ASE 生成的输出，按管线分开，便于打开检查；这些是固定测试样例，跨版本使用仍需 ASE 迁移和验证。

## Agent 接入

Unity 打开项目并完成导入后，插件自动维护：

```text
<UnityProject>/Library/ASEShaderConverter/Agent/
  connection.json
  requests/<unique-id>.json
  responses/<unique-id>.json
```

Agent 先读 `connection.json` 确认项目、会话和更新时间。请求先写 `.tmp`，再在同一目录重命名为 `<unique-id>.json`，避免读取半写入文件。Unity 主线程执行请求并写入同名响应。每个请求使用新 id；`.processing` 表示已认领，`.processing.done` 表示已完成。域重载或崩溃留下的 `.processing` 不自动重放，先检查输出再用新 id 重试。编辑器在播放、编译和导入期间暂停处理请求，关闭 Unity 后不会处理请求。没有网络服务或特定 Agent SDK 依赖。

0.3.7：协议文件被短暂占用时自动退避。连接心跳失败与队列独立；响应写入或请求归档失败时，仅在当前 Editor 域中保留结果并重试交付，期间暂停后续请求。兼容重命名发布会出现短暂的目标文件缺失，调用方遇到不存在/占用时应稍后重新读取，不会读取到本插件写入的半个 JSON。若持久占用仍存在，警告会列出完整文件路径；先释放该文件的读取器/同步工具占用，再等待恢复，不必删除 Shader 或整个 Library。

```json
{ "schemaVersion": 1, "operation": "probe" }
```

```json
{
  "schemaVersion": 1,
  "operation": "generate",
  "sourcePath": "Assets/MyHandwritten.shader",
  "outputPath": "Assets/MyHandwritten_ASE.shader",
  "options": { "targetPipeline": "Auto", "surface": "Unlit", "keepOriginalShaderName": false }
}
```

接口支持 `probe`、`describe`、`rules`、`analyze`、`analyzeTargets`、`generate`、`generatePlan`。`analyzeTargets` 只读返回 Built-in、URP、HDRP 各自的计划与阻塞，不触发生成。直接从 Unity Editor 主线程调用 `ShaderConverterApi.ExecuteJson(json)` 也使用相同协议。详细工作流见 `Documentation~/AgentProtocol.md`。

未运行的项目可以使用批处理入口：

```powershell
& '<UnityEditor>/Unity.exe' -batchmode -projectPath '<UnityProject>' `
  -executeMethod ASEShaderConverter.Editor.ShaderConverterApi.ExecuteCommandLine `
  -aseRequest '<request.json>' -aseResponse '<response.json>' -logFile '<log.txt>'
```

不要对已经打开的同一个项目再启动批处理。当前项目内优先使用文件接入或已有的 Unity Agent 桥接。

## 转换规则

- 优先创建 ASE 原生节点；算术、纹理采样、UV、向量组合/分量、插值、常见数学函数、指数、对数、倒数已有原生映射。
- Custom Expression 需要 Agent 提交完整代码、明确输入/输出和 `fallbackReason`，解释为什么原生节点不能表达。未知函数不会自动被粘入一个含未解析全局变量的 Custom Expression。
- 片元颜色拆成 RGB 和 Alpha 输出；不透明模板必须保留 Alpha，原始单 Pass 不应新增投射阴影行为，相关选项必须由 ASE 正式选项动作应用。
- 输出路径必须在当前项目 `Assets` 下，拒绝覆盖已有文件。已有 ASE 图进入迁移流程，不重建它的生成 HLSL。
- 保存后由 ASE 重新载入，检查节点、双向连线、节点序列化设置和请求的模板选项，再要求 Unity 选中预期主 Pass 并同步编译当前图形 API 下的材质 Pass。找不到主 Pass 时会失败，避免把 fallback 编译当成成功。`Generated` 不代表画面已经比对一致，也不代表所有构建平台、关键词组合均已编译。

## Unity / 管线兼容范围

包最低声明 Unity 2021.3。桥接层采用能力探测和反射，不依赖 ASE 的程序集名称，也不直接引用 URP/HDRP 程序集。宿主 Unity、ASE、渲染管线包及模板必须彼此兼容。不同管线需要在各自项目中生成和验证，目标管线必须匹配当前质量级别实际启用的管线。

| 项目 | 当前状态 |
| --- | --- |
| ASE API/源码对照 | 以用户提供的 1.9.9.13 为基准 |
| Unity 2021.3.30f1 | 插件引用编译通过；提供的 ASE 源码使用该 Unity 没有的 `SerializedProperty.boxedValue`，实际运行被 ASE 自身编译错误阻塞 |
| Unity 2022.3.10f1 / 6000.0.80f1 | 已实际验证 Built-in 的原生图、循环回退图、保存重载、主 Pass 编译和测试样例画面 |
| Built-in Unlit | 纹理、数学和 Custom Expression 样例通过；详细证据见 `Documentation~/Validation.md` |
| URP 14.0.8 / Unity 2022.3.10f1 | 原生图及手写纹理样例通过保存、重载和编译；纹理主颜色 Pass 进行独立像素比较 |
| HDRP 14.0.8 / Unity 2022.3.10f1 | 明确提交的原生节点图通过保存、重载和主 Pass 编译；自动片元转换需 Agent 审查，未验证场景画面等价 |
| Lit / 顶点变形 / 多 Pass / Stencil / 透明 / 变体 | 自动转换会阻塞；Agent 需要明确节点、输出、模板和已适配的配置，不承诺自动等价转换 |

当前可提交的设置适配器包括常量/属性默认值、UV 通道、Swizzle、Append、Custom Expression、纹理数组类型、显式 LOD、两种属性特性、Built-in Unlit Cull Front 和 ASE 模板选项。Shader Model 与 Geometry Queue 请求会校验真实模板状态。未适配的节点配置/渲染状态会被拒绝，不能用任意反射字段写入绕过 ASE。ASE 会把空数组默认值写成 `white` 标记；本次验证中原、新材质均未自动绑定数组资源，原默认值保留在计划中，报告也明确记录此规范化。

URP/HDRP 必须先让 ASE 根据实际 SRP 包版本完成模板激活。该 ASE 自带版本化模板及清单；不要把 `.shader` 占位文件当作可生成模板。URP 自动路径关闭模板附加的阴影接收、SSAO、雾、额外前置 Pass、Meta 和 LOD 淡入效果，仍需检查完整场景中的辅助 Pass 行为。

## 本地验证

```powershell
dotnet restore Tests/CoreChecks.csproj --configfile .nuget.empty.config
dotnet run --project Tests/CoreChecks.csproj --no-restore
dotnet restore Tests/EditorCompile.csproj --configfile .nuget.empty.config
dotnet build Tests/EditorCompile.csproj --no-restore
```

Editor 编译检查可通过 `-p:UnityEditorPath=<Unity安装目录>/Editor` 指定版本。构建产物置于 `.build~`，Unity 不将其当成插件程序集再次导入。

`Tools~/Prepare-Validation.ps1 -AseSource <已安装的ASE目录>` 可在 `.validation/Unity2022` 建立隔离测试项目，再以 `-executeMethod UnitySmoke.Run` 执行实际测试。该目录包含用户自己的 ASE 副本，仅用于本机验证，不包含在插件交付内容中。

准备工具可指定 `-ProjectName` 和 `-UnityVersion`。SRP 检查入口为 `UnitySrpSmoke.Run -asePipeline URP` 或 `HDRP`，先在隔离项目安装对应 SRP 包。检查脚本只在隔离项目通过 ASE 自己的模板清单完成版本选择；不用于修改用户原项目。

`Tools~/Build-Release.ps1` 按文件白名单生成 `.tgz`、`.zip` 和 SHA-256 校验记录，排除 ASE 安装副本及本地验证/构建缓存。

验证矩阵、测试条件、复现方法与已知限制见 [验证记录](Documentation~/Validation.md)。Unity 6000.0.80f1 的实时 Agent 文件接入已完成环境探测、模板查询、分析和生成验证。
