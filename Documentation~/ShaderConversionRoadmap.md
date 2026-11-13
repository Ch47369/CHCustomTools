# Shader转换器：图格式与 Agent 使用

0.4.0 将显示名称、菜单和窗口统一为 **Shader转换器**。包 ID `com.aseshader.handwritten-converter`、C# 命名空间/程序集、旧 ASE 请求和 `Library/ASEShaderConverter/Agent` 目录继续兼容。分类库仍叫“ASE 着色器库”，293 个已有资产保持原格式与身份。

本阶段按用户选定的优先级实现 **手写 Shader → Shader Graph** 和 **Agent 原生 Shader Graph 建图**。四个方向共用来源输入和目标格式入口，但并非四个方向都已实现自动互转。

| 方向 | 0.4.0 行为 |
| --- | --- |
| 手写 Shader → ASE | 保留既有自动子集、审核方案和 Agent ASE 计划 |
| 手写 Shader → Shader Graph | 新增 URP 标准 Unlit 受限原生子集；需明确选择宿主适配，逐图保存重载与编译 |
| ASE → Shader Graph | 保留原图身份并明确阻塞；Agent 审查源图后提供原生目标计划。尚无通用 ASE 原图读取/自动映射器，不从生成 HLSL 反推 |
| Shader Graph → ASE | 保留新旧格式结构分析、历史逐图显式适配及 Agent ASE 计划；尚无通用双向自动映射器 |

## Shader Graph 输出范围

版本限定 Unity **2022.3**、Shader Graph **14.0.8**、URP **14.0.8**，目标项目必须启用 URP。Shader Graph 后端没有 ASE 安装依赖；ASE 输出和 ASE 库仍需要 ASE。其他版本、Built-in/HDRP 输出先阻塞，不能从 C# 可编译推断实际图支持。

手写输入先通过严格分析，再进行目标审查。首批支持单 Pass Unlit、Float/Range/Vector 属性、数值常量、直接 UV0–3 传递、普通 2D 属性与显式 UV 采样，以及加减乘除、saturate、abs、取负、sin/cos、floor/ceil/frac、sqrt、pow、min/max、lerp、分量重排和组合。纹理默认值限 white/black/gray；采样关闭 SG 默认开启的全局 Mip Bias。纹理 ST 字段保留，但顶点 TRANSFORM_TEX、非线性顶点计算、LOD/数组/法线采样尚未适配。

Color 属性的色彩空间、非恒定/非 1 Alpha、透明混合/裁剪、未适配的关键词、自定义函数/子图、多 Pass、Stencil、未映射渲染状态、专用 Lit/BSDF 和复杂阶段保持阻塞。自动路径只在能证明 Alpha 恒为 1 时使用不透明目标，不能用普通 Lit 或任意 Custom Function 替换不支持的语义。

### 枚举属性与 Lerp

ASE 图中有些枚举外观是一个 Float 属性接到 `Lerp` 的第三输入。Shader Graph 中这类值若有明确的 ShaderLab 离散声明（`[KeywordEnum(...)]` 或可解析的 `[Enum(Name,Value,...)]`），会在原生计划中降为本地 All-stage `ShaderFeature` Enum `KeywordNode`，保留条目和默认条目；引用按 SG14/材质 Drawer 规则转为大写（`_Mode` → `_MODE`）。非 ASCII 显示名会导致 SG14 生成无效 HLSL 标识符，因此用原属性引用显示，并在报告中记录原名与适配名；ASCII 显示名保留。原 Float 不会再作为连续材质属性重复生成。两条显式分支的输入接到 KeywordNode 的枚举端口，连续 Float + Lerp 仍保持普通 `LerpNode`。

自动映射只接受“已声明且独占一次第三个 Lerp 参数”的二路分支，枚举值必须按 0/1 顺序，默认值精确命中一个条目，条目名为 ASCII 标识符。多条目、嵌套 Lerp、枚举同时参与其他运算，或仅凭 Float 数值猜测枚举语义，都会返回 Agent 阻塞。Enum 是编译期变体：材料切换时要同步使用生成的关键词条目（例如 `_MODE_BASE` / `_MODE_DETAIL`），不能把 `SetFloat` 当作连续插值或保证会自动切换变体。实际 SG14.0.8 的保存重载、同步编译与两条关键词分支验证见 `Evidence/GraphInterop040` 的后续尝试；这不代表完整 ASE↔Shader Graph 自动互转。旧 ASE 自动路由仍阻塞尚未适配的枚举属性，不会静默丢弃材质 Inspector 行为。

**标准 URP Unlit 是明确的宿主适配。** Unity 的目标包含自身的雾、SSAO、Decal 条件与深度/编辑器附加 Pass；关闭投射阴影、材质覆盖和 LOD CrossFade 也不等于原始单 Pass 宿主。窗口需勾选对应选项，API 需 `acceptStandardUrpUnlitTarget=true`。报告记录 `standardTargetAdaptation=true`，`visualComparisonPassed` 仍为 false。要求完整保留原宿主的输入应保留阻塞，等待专用 Target/模板。

## Agent 接口

继续使用 schemaVersion 1。缺省 `options.targetGraph="ASE"`，旧 `plan` 字段含义不变。历史 `ShaderGraphPlan` 使用 ASE 类型/端口，**不是** Unity Shader Graph 格式。新后端使用独立的 `shaderGraphPlan`（`ShaderGraphNativePlan`）。

```json
{"schemaVersion":1,"operation":"probe","options":{"targetGraph":"ShaderGraph"}}
```

| operation | ShaderGraph 路由行为 |
| --- | --- |
| probe | 返回 shaderGraphEnvironment：Unity/SG/URP 版本、活动管线、错误及受限节点清单 |
| describe | 按 nodeTypes 返回实际原生槽 ID、方向和类型；省略时列出全部适配类型，空 PropertyNode 没有属性输出槽 |
| analyze | sourceText/sourcePath 经手写分析及目标审查，返回 shaderGraphAnalysis.plan/report |
| generate | 审查通过才保存新的 Assets/*.shadergraph，再重载及同步编译 |
| generatePlan | 接受独立 shaderGraphPlan；不接受 ASE plan 冒充 Unity SG 文件 |

`analyzeTargets` 仍是 ASE 三管线审查。`rules`/`library` 使用旧缺省路由。没有新增独立 inspect/validate 命令，也没有内置大模型或 API Key 服务；外部 Agent 继续通过文件队列或 C# Execute 接入。

原生计划使用 schemaVersion=1、pipeline=URP、surface=Unlit、shaderPath、acceptStandardUrpUnlitTarget=true、nodes、edges、colorNode/colorSlot。最终 Shader 名称为 shaderPath/输出文件名。type 必须来自 probe/describe 清单，不能传任意 C# 类型或内部字段名。

节点 value 是数值默认值；Vector1–4Node 必须恰有对应数量的分量。PropertyNode 提供 propertyName、displayName、propertyKind=Numeric 和 1–4 分量默认值；scalar 可用 slider/rangeMin/rangeMax。纹理使用 propertyKind=Texture2D、textureDefault=white/black/gray。SwizzleNode 的 mask 用 xyzw，UVNode 用 uvChannel=0–3。edges 使用真实 fromSlot/toSlot 整数；BaseColor 必须显式得到 Vector3，避免静默截断/补零。

`KeywordNode` 是受限的 Enum 计划节点：`keywordReference` 必须是大写 Shader 关键词引用名，`keywordEntries` 与 `keywordEntryReferences` 为 2–8 个唯一条目，`keywordDefault` 为条目索引；显示名限 ASCII，条目引用必须是与暴露标签相符的有效大写标识符；当前只接受本地、All 阶段的 `ShaderFeature` 或 `MultiCompile`。枚举端口 ID 来自实际 `KeywordEntry.id`，先用 `describe` 查看再连接。它用于已证明的离散分支，不替代普通 `LerpNode`。

完整请求见 [原生建图示例](../Samples~/AgentShaderGraphNativePlan.json)。先 probe/describe，再将 outputPath 改为目标项目中未使用的 Assets 路径。已有文件或 .meta 会阻止覆盖。

后端使用已安装 SG 的 GraphData/Target/SubTarget 建立真实节点，用官方 MultiJson 序列化，读回比较全部序列化节点、属性、设置与连线，再导入 Unity 同步编译实际 Pass。只有通过这些步骤才标 `Generated`。结果分别记录 shaderGraphRoundTripPassed、shaderCompiled、standardTargetAdaptation、shaderGraphVersion；ASE 标志不冒充 SG 重载结果。

## 后续双向互转

下一阶段需读取 ASE 原图真实节点/默认输入/连线/Function/模板合同，将 SG 结构读取扩展为逐节点语义，逐项保留精度、颜色空间、阶段、属性默认值、关键词与 Pass。先适配共同原生子集，再扩大 Lit、顶点和专用模型范围。Agent 目标计划不能证明源图已完整映射，完整性与画面对比仍需独立审核。

历史库及研究数量不因新后端增加。实际验证见 `Evidence/GraphInterop040/verification.json`；失败尝试保留在工作区 `.build~/GraphInterop040`。
