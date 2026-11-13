# Agent 协议 v1

0.4.6 输出格式显示为 ASE / ShaderGraph，均提供 Built-in / URP / HDRP 选择。`options.targetGraph="ShaderGraph"` 路由 probe/describe/analyze/generate/generatePlan 支持 Unity2022.3、SG14.0.8 三管线标准不透明 Unlit 原生子集；URP/HDRP 需对应包14.0.8与活动管线。`options.acceptStandardUnlitTarget=true` 明确授权目标标准宿主；原生计划同名字段亦需填写。旧 `acceptStandardUrpUnlitTarget` 只授权 URP。源 HDRP 宿主审查仍保留。新计划使用独立 `shaderGraphPlan`；旧 `ShaderGraphPlan`/`plan` 仍为 ASE 类型与端口，不是 Unity `.shadergraph`。包 ID、程序集/命名空间、公开旧 API、schema1 与 Agent 目录兼容。通用 ASE↔ShaderGraph 自动互转尚未实现；具体字段、宿主适配选择和限制见 [图格式与 Agent 使用](ShaderConversionRoadmap.md)。目录、293 库图及规则仍沿用 0.3.6。

当 ShaderLab 明确声明 `[KeywordEnum(...)]` 或可解析的 `[Enum(Name,Value,...)]`，且枚举 Float 直接作为二路 `lerp` 的第三参数时，Shader Graph 原生计划使用 `KeywordNode` Enum；保留条目/默认值并跳过重复的连续 Float 属性；SG 关键词引用统一大写，非 ASCII 显示名用原属性引用显示并在报告注明原名（SG14 使用显示名生成 HLSL 标识符）。普通 Float + Lerp 继续映射 `LerpNode`。多条目、嵌套或未证明的用法返回 NeedsAgent，不能凭 Float 值猜测关键词。`KeywordNode` 只允许本地 All-stage `ShaderFeature`/`MultiCompile`，端口使用 SG14 实际 `KeywordEntry.id`；材料切换需要启用对应条目关键词，`SetFloat` 不等价于连续插值。

0.3.7 修复文件交付：协议格式不变，写入使用唯一临时文件，先尝试 `File.Replace`，失败后将旧文件重命名保存，再发布完整新文件；发布失败尝试恢复旧文件，恢复失败时警告明确列出保留原文件的位置。兼容发布期间目标路径可能短暂不存在，读取方需容忍文件不存在/占用并稍后重读。不得用直接覆盖写入代替请求的 `.tmp` → `.json` 发布。连接心跳失败不阻塞队列；请求执行后响应/归档失败，在当前 Editor 域中只重试交付，不重复 `Execute`，后续请求等待。域重载/退出不持久化待交付响应，也不自动重放 `.processing`，应先审查实际输出与现有响应。警告包含操作、绝对路径和异常链；持续占用不会被强制解锁。验证见 [AgentInbox037](Evidence/AgentInbox037/README.md)。

0.3.6 新增 `ReviewedArticleAdaptation`，首项为用户指定的方木君逻辑光源玉石文章核心函数。固定代码 SHA-256 `a9cc314b7587c26e32c17e12fd87f0a8dffb19447ad5528a1522e33dac99993f`，三管线显式原生图；完整原 Shader 未提供，Lit/Emission 整合为补充实现。新的受限 TransformDirectionNode 适配器仅接受 `m_from=World`、`m_to=Object`、`m_normalize=true` 三项完整组合，限定 ASE 1.9.9.13 并校验保存重载；不能借此写任意字段。图、公式浮点测试、实际相机和安装复用分别记录于 Evidence/JadeArticle036；原场景等价保持 false。

0.3.5 新增 `ReviewedMaterialAdaptation` 来源，首项为固定 MIT AspectURP 流麻源码 SHA-256 的显式原生图。`library` API 展示三管线条目、同源合同、PC 高复杂度与输入限制；一般 `generate` 自动规划能力未因手工计划入库扩大。图的材质计算全为原生节点，受限 TemplateLocalVarsNode 适配器仅接受 `ase_tangentView`，HDR 属性适配器仅接受 ColorNode，均限 ASE 1.9.9.13 并检查重载。复现及独立渲染/材质证据见 Evidence/Showcase035，只有 verification.json 中成功范围可作为当前结论。

0.3.4 统一入口为“ASE 着色器库”，人物档案嵌入对应分类，旧 `CharacterMaterialWindow.Open()` 仅跳转。`library` JSON 结构与 0.3.3 图、研究、契约不变，只有目录版本变化。`ShaderLibraryQuery.Filter` 默认包含所有已重载/编译图，严格三目标映射为显式 `ShaderLibraryScope.ThreeMappedTargets`。`Categories` 从真实图建立可安装分类，覆盖总览可以另含研究分类；研究页仅列有来源的类别。历史 UIAnimation 在查询层归并 UIEffects，保留来源原记录。方案、版本、研究来源、缺版本和已生成目标功能缺口分别计数。不得用界面重构扩大实际适配声明。

0.3.3 的分类库包含 109 个同源方案、287 份实际 ASE 图（89/89/109），89 个方案具备三份文件，64 个方案通过限定功能范围的三目标映射。新增四个 MIT Kino 显式输入图像滤镜，各有三目标版本；不自动注入相机，历史帧/噪声及动画参数由宿主供应。`operation: "library"` 通过条目的 `notes`、`dependencies` 和 `familyContracts.hostRequirements` 展示边界。新三套模板仅适用于原始图像滤镜的节点子集；不能当作任意 SRP 材质模板。`keyword:GlobalMultiCompile=true` 是受限 StaticSwitch 适配器，保留全局关键词及 multi_compile，水面默认 local shader_feature 行为继续分别验证。见 [本轮证据](Evidence/PublicLibrary033/README.md)。

0.3.1 的 `library` 响应增加 `familyId`、`effect`、`keywords`、`devices`、`performanceTier`、`performanceBasis`、`textureSampleSites`、`deviceValidation`、`shaderModel`、`graphicsApiValidation` 与 `deviceRequirements`。84 个完整三管线方案共 252 个文件；21 个历史单管线图单列补充库。静态分级不是实机性能结果。纯核心 `ShaderLibraryQuery` 提供组合检索与管线覆盖判断。编辑器 `ShaderLibraryBatch.Start(string[] ids)` 在当前管线异步创建已验证 Shader 与材质，保留用户修改，支持停止和持久化报告；只能从 Unity Editor 主线程调用。来源与分析记录不能作为批量生成输入。见 [LibraryTargets](LibraryTargets.md)。

0.3.0 新增 `{"schemaVersion":1,"operation":"library"}`：返回 `shaderLibrary`，包括真实可导入图的路径、SHA-256、管线、来源/许可、ASE 重载/编译/视觉状态、节点及注释数量、依赖和研究记录。编辑器入口为“分类 ASE 着色器库”，资源仅在用户选择匹配管线时导入。主转换器接受 `.shadergraph` / `.shadersubgraph` 分析，保留真实源模型、活动数据、输出块、关键词及依赖；分析不自动赋予生成能力。20 张经显式适配的本地图通过普通 `generatePlan` 与真实 ASE API 建立，不能把它当作任意 Shader Graph 转换器。详见 [ShaderLibrary](ShaderLibrary.md)。

0.2.9 新增人物材质库：`rules` 的 `ruleLibrary.characterProfiles` 包含 Skin、Hair、Eye、Fabric 四份档案；`analyze` 的 `analysis.knowledge.characterMaterials` 包含命中线索、`AnalysisOnly` 状态和 `requiredReview`。当前目录为 40 条规则、13 类。四类完整生成适配仍为 `RequiresAdapter`，人物档案为 `RecipeRecorded`，不能根据分类命中解除原转换阻塞。管线项的 `referenceTemplateGuid` 是实际核对过的参考身份，可能为空，不能作为支持声明；每个目标项目仍需 probe/describe。当前隔离 HDRP 环境未发现独立 Eye 模板，不能自动用普通 Lit 替代 Eye BSDF。输入/宿主与证据见 [CharacterMaterials.md](CharacterMaterials.md)。

请求与响应均为 UTF-8 JSON，字段大小写与 C# 数据模型一致。未知字段不作为成功映射的依据。`success=false` 时读取 `error` 和 `report.blockers`。`analyze` 成功只代表计划可生成，不能当作 ASE Shader 成功。

## 建议工作流

1. `probe` 获取实际 Unity/ASE 版本、当前管线及模板。`ready=false` 或模板缺失时先解决宿主环境。
2. `analyze` 传 `sourcePath` 或 `sourceText`，审查 `analysis.plan` 和 `report`。已有 ASE 图交给 ASE 迁移。
3. 简单子集用 `generate`；复杂源码由 Agent 逐项映射到 ASE 节点、顶点/片元输出、模板选项及渲染状态后用 `generatePlan`。
4. 模板端口不靠猜。先调用 `describe`，指定实际模板 GUID 和要查看的 `nodeTypes`。返回的 `description.masters` 包括模板 Master 与请求查看的节点端口；`options` 列出选项的原始名称与有效取值。
5. 检查生成报告和输出文件。完成目标材质/场景的画面比对之后才能认定等价。

```json
{
  "schemaVersion": 1,
  "operation": "describe",
  "templateGuid": "0770190933193b94aaa3065e307002fa",
  "nodeTypes": ["TexturePropertyNode", "SamplerNode", "SwizzleNode", "DynamicAppendNode", "CustomExpressionNode"]
}
```

## 三条目标管线分析

0.2.6 新增只读检查，不会写 Shader：

```json
{ "schemaVersion": 1, "operation": "analyzeTargets", "sourcePath": "Assets/Input.shader" }
```

响应的 `targetAnalyses` 分别包含 Built-in、URP、HDRP 的计划和报告。此操作 `success=true` 表示分析完成；能否生成须逐项检查无 blockers 且非已有 ASE 图（Unity JSON 不序列化只读的 `CanGenerate` 属性）。`report.sourcePipeline` 是检测到的源管线，`report.pipeline` 是目标，`crossPipeline` 表示两者不同。源 HDRP 的曝光、雾与 Pass 审查在转向其他管线时也保留；混合源管线必须逐 SubShader 审核。窗口的三目标结果使用同一核心入口。

实际生成仍需目标项目启用相应管线、probe/describe 真实模板，完成保存重载、编译和画面验证。`NativePlanner`、`AnalysisRule`、`AseMigration`、`RecipeRecorded` 分别描述计划实现、分析、原图迁移和待适配方案，不是统一的已验证支持声明。规则目录提供 12 个 `categories`，研究范围和前后对照见 `MaterialLibrary.md`、`Evidence/RuleResearch026/comparison.json`。

## 节点计划

`ShaderGraphPlan` 是插件自己的稳定中间格式，**不是 ASE 序列化格式**。所有集合必须存在，id 唯一，图不得有环。`type` 必须是当前安装 ASE 的表达式节点类型名。

```json
{
  "schemaVersion": 1,
  "operation": "generatePlan",
  "outputPath": "Assets/AgentConstant_ASE.shader",
  "plan": {
    "schemaVersion": 1,
    "shaderName": "Converted/AgentConstant",
    "pipeline": "BuiltIn",
    "surface": "Unlit",
    "nodes": [
      { "id": "color", "type": "Vector4Node", "value": "(1,0.2,0.1,0.8)", "settings": [], "customInputs": [] },
      { "id": "rgb", "type": "SwizzleNode", "swizzle": "xyz", "outputType": "FLOAT3", "settings": [], "customInputs": [] },
      { "id": "alpha", "type": "SwizzleNode", "swizzle": "w", "outputType": "FLOAT", "settings": [], "customInputs": [] }
    ],
    "wires": [
      { "from": "color", "fromPort": "0", "to": "rgb", "toPort": "0" },
      { "from": "color", "fromPort": "0", "to": "alpha", "toPort": "0" }
    ],
    "outputs": [
      { "node": "rgb", "port": "0", "masterPort": "Color", "pass": "Unlit" },
      { "node": "alpha", "port": "0", "masterPort": "Alpha", "pass": "Unlit" }
    ],
    "masterSettings": [
      { "name": "option:  Keep Alpha", "value": "true" },
      { "name": "option:Cast Shadows", "value": "false" }
    ]
  }
}
```

端口字符串表示 **ASE PortId** 或精确名称，数字不表示列表索引。连接前后检查实际端口和双向引用。`pass` 为空时优先当前主输出上的可写端口；其他情况要求匹配唯一的可见 Master，存在歧义时必须指定 `pass`。模板选项使用 `option:` 加真实名称，包括名称中的前导空格；取值来自 `describe`，不能套用另一个管线的选项。创建图时先执行 ASE 默认选项动作，再应用计划中的设置；保存前及重载后检查这些设置。

纹理使用 TexturePropertyNode → SamplerNode 的 Tex 输入，UV 显式连接到 UV 输入。节点属性通过 `propertyName`、`displayName`、`propertyKind` 和 `value` 定义；浮点范围用 `rangeMin/rangeMax`。自动生成的属性保持原 Shader 属性名。UV 通道的设置为 `{"name":"m_textureCoordChannel","value":"0"}`。

0.2.2 的受限适配器以 ASE 1.9.9.13 为验证基准：`propertyKind="2DArray"` 用 TexturePropertyNode 的类型配置 API；SamplerNode 设置 `m_mipMode=MipLevel`，以真实端口 `UV`、`Index`、`Level` 接线；`attribute:NoScaleOffset` / `attribute:Toggle` 调用 ASE 属性 API。`pass:Unlit:Cull=Front` 设置 Unlit Pass 的 Cull 模块；`template:ShaderModel=3.5` 和 `template:RenderQueue=Geometry` 校验模板及选项动作后的真实状态。保存重载后再次核对所有设置。空数组默认值由 ASE 规范化成 `white` 标记，报告保留这一差异，不改写 ASE 输出。

自动局部分支只支持有大括号的 `if/else`：比较标量，每臂给同一可变局部变量或同一 swizzle 赋值一次，值类型相同，且分支表达式无采样及副作用。使用 ConditionalIfNode 的比较结果端口保留等于边界。0.2.5 仅增加下述固定算术循环，动态/嵌套控制流、整数语义、const/uniform 改写等仍未适配。该子集面向有限浮点值；NaN/Infinity、精度窄化及平台差异需单独审查与验证。

0.2.5 的通用计划规则：

0.2.6 在下面的历史子集基础上扩展：按参数数目与精确宽度选择纯函数重载（精度同宽歧义仍拒绝）；标量六种比较的纯数值三元选择；浮点显式截取/复制；rsqrt/sign/trunc/fmod/atan/atan2/asin/acos；顶点 float2 UV 纯算术组合后经 Vertex To Fragment 插值。Built-in Cull Front/Off 与 URP Two Sided 分别使用各自模板设置，Geometry 队列两者都需校验实际 Tags。已有阻塞检查继续执行；不将顶点位置动画、UI/粒子完整效果或 HDRP 曝光视为已支持。新增图设置尚未在本轮实际生成验证。

- 纯数学辅助函数按参数值内联，参数和局部作用域隔离，仅接受 float/half/fixed 标量或向量和一个最终 return。拒绝重载、递归、out/inout、隐藏采样、全局写入、整数、宏和分支。嵌套深度最多 8，调用最多 256，图最多 4096 节点。
- `for (int k=N; k<M; k++) { ... }` 的 N/M 为非负十进制字面量，最多 16 次、8 个循环；循环体不能读取 k、声明局部量、嵌套控制流或采样。零次循环也审查禁止构造。支持可变局部的 `+=`、`-=`、`*=`、`/=` 复合赋值。
- 顶点 `TRANSFORM_TEX(input.uv, texture)` 需要 float2 TEXCOORD 语义和实际 2D 属性；Texture Property → UV 的 `Tex` 输入 → Vertex To Fragment → 片元采样。直接转发的 UV 不添加 ST，重复写入同一 varying 继续阻塞。
- `_Time` 保留 x=t/20、y=t、z=2t、w=3t；世界相机位置、length/distance 使用实际原生节点，距离两端宽度必须一致。新规则只完成源码引用编译和核心计划验证，未在本轮生成图。

只读规则入口：

```json
{ "schemaVersion": 1, "operation": "rules" }
```

返回 `ruleLibrary`。`analyze` 的 `analysis.knowledge` 同时提供命中规则、参考文件说明、原 ASE 图依赖、材质分类线索和未测量的静态性能线索。`NativePlanner` 是实现状态，`AseMigration` 是原图迁移路径，`RecipeRecorded` 是待适配方案；任何状态都不能代替报告中的真实生成验证。分类启发式可能误判，需按源码和资源核实。

Custom Expression 节点需提供 `code`、`outputType`、`customInputs` 和 `fallbackReason`。输入支持明确的 ASE 类型；桥接通过 ASE 的输入项维护 API 添加端口。代码不能依赖缺失的源码局部变量、宏、外部函数或未声明全局变量。自动分析当前没有未知函数兜底，以防错误语义被隐藏。

`generatePlan` 由提交计划的 Agent 负责原源码语义审查；结构与编译验证无法证明计划忠实于源 Shader。不能简单删除分析器的阻塞项后把半成品计划提交为成功转换。

0.2.3 的 `options.presentation` / `plan.presentation` 可包含 `autoLayout`、`addComments`、`useRegisters`（默认均 true）、`longWireDistance`（默认 1800）和 `maxRegisters`（默认 24）。节点可用 `group` 标识计算步骤，`label` 提供局部变量名称；`plan.comments` 中的 `{id,title,text}` 对应组的中文说明。自动分析从源码局部赋值、条件选择和输出创建这些组。没有说明的人工计划采用通用的连线说明，不猜测业务用途。

排列算法依据有向依赖分层，考虑节点尺寸与组间距，避免节点和 Comment 帧相互重叠。数值长线用 ASE 的 Register Local Var / Get Local Var API 连接，采样器和纹理对象不做数值 Register 改写；getter 引用与 Comment 成员在保存重载后验证。报告增加 `layoutApplied`、`commentCount`、`registerNodeCount`、`getNodeCount`，`nativeNodeCount` 包含新增 Register/Get，不含 Comment。

0.2.7 对收缩后的功能组依赖图排序，避免一个组里的独立常量先就绪时，把合法的整体数据流误判为组间回路。组内的短分支/常量向使用位置靠拢；长线 getter 按目标节点复用，而不是让一个 getter 在整个组中拉长线；主节点远距离数值输入也会整理。矩阵和资源类型不经数值 Register，人工计划可在各使用区重复创建只读的内置矩阵节点。新增原创水计划与实际 Built-in 验证见 `Samples~/Water/README.md`、`Validation.md`；不能由该结果推断任意原有图、ASE 版本或 SRP 管线已验证。

0.2.8 的人工计划可使用 `type="StaticSwitch"`、大写 `propertyName`、`propertyKind="Float"`、`value="0"` 或 `"1"`。这是固定的 Create / Toggle / local shader_feature / All stages 材质开关，关键词为 `propertyName + "_ON"`；不开放任意私有字段、动态分支、外部关键词或枚举模式。真实 ASE 1.9.9.13 的输入 PortId 为 True=0、False=1，不能按可见列表顺序猜端口。默认值、绑定、作用域和模式在保存重载后核对。Unity 材质的 float 与关键词是两个状态，运行时只 SetFloat 不会自动切换变体；需要同步 EnableKeyword/DisableKeyword。ShaderLab Pass、相机深度生成和外部探针更新不由数值分支自动移除。

DeepZoom UI 的专门适配器只接受 `ReviewedUiProfile.SourceSignature` 对应的完整 token 签名（忽略 Shader 名称、注释和空白）。数学部分继续使用原生节点；标准 UI 属性、顶点颜色与 Tint、全局 UI 关键词、硬裁剪、Stencil 和直通 Alpha 混合由本包自有模板承担。模板 GUID 为 `eab467e6cd0b4d27ab8e9e434d8c30e3`。未审核的 UI 修改仍保留原有阻塞。不要用 ASE 默认 UI 模板替换此模板：默认模板有不同的软裁剪、Alpha 处理和预乘混合行为。

0.2.4 增加以下已审核入口。`probe` 会注册全部自有模板；先 `describe` 其实际 Float4 Color 端口。模板 Master 的序列化设置也会随表达式节点一起保存重载比较。不要替换模板 GUID、移除阻塞或通过手写 ASE 元数据生成这些图。

| 输入行为 | 源码签名常量 | 模板 GUID | 模板负责的行为 |
| --- | --- | --- | --- |
| Normal360 | `ReviewedNormal360Profile.SourceSignature` | `a99d644facf4442398d54acf418923b9` | 顶点 TRANSFORM_TEX、Cull Off、LOD 100、源默认 target 2.5、Unity fog 坐标和变体；主 Pass 为 Unlit |
| NormalImagePanZoom | `ReviewedUiProfile.PanZoomSourceSignature` | `c08fd7d51a79449e86b199a5bb4a5724` | target 2.0、标准 UI 渲染状态、顶点色/Tint、矩形硬裁剪和 Alpha Clip；主 Pass 为 UI |

PanZoom 的 `_MainTex` 是原生 Texture Object 属性，新增受限 `attribute:PerRendererData` 适配调用 ASE 的属性 API，并在重载后校验。其余模板 UI 属性与图中的 ViewRect/翻转属性共同保留 11 个原属性。Normal360 图读取模板已做顶点 ST 变换的 UV，再按严格大于 0.5 的条件翻转；不能再次在采样前重复应用 ST。以上审查针对有限材质数值，场景画面仍需单独比较。

## 状态与验证

| 字段/状态 | 含义 |
| --- | --- |
| Planned | 分析得到节点计划，尚未在 ASE 中生成 |
| ExistingAseGraph | 已有 ASE 图，应走 ASE 迁移 |
| NeedsAgent / Blocked | 存在无法自动确认的语义或环境条件 |
| GenerationFailed | 建图、保存或重载出错，可能留下新建的诊断输出 |
| ValidationFailed | 已保存图，但当前 Unity 编译未通过或无法验证 |
| Generated | ASE 保存和重载检查通过，预期主 Pass 存在，当前材质 Pass 编译通过 |
| aseRoundTripPassed | 节点、设置和连接重载检查通过 |
| shaderCompiled | 当前图形 API 的同步 Pass 编译通过；不涵盖所有变体与平台 |
| visualComparisonPassed | 默认 false，需独立的画面对比流程 |

所有调用必须在 Unity Editor 主线程，等待脚本编译和资源导入完成。文件接入每次只处理一个请求；每个请求使用新的文件名，读取响应后由调用方决定保留或归档。分析核心 `ShaderConversionEngine.Analyze` 可在无 Unity 的 .NET 进程中运行，建图/序列化必须在 Unity/ASE 中完成。

UPM 安装时，`connection.json` 还提供 `instructionsPath` 和支持的 `operations`，让新 Agent 直接找到本协议。HDRP 手写片元代码进入 Agent 审查流程，必须明确处理原 Shader 与 HDRP 模板之间的曝光、雾、Alpha、混合和 Pass 差异；不能直接套用 Built-in 的选项。`generatePlan` 可使用已安装的 HDRP 模板创建原生图。
