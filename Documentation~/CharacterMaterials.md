# 人物材质说明（0.3.4 统一入口；保留历史研究记录）

0.3.1 为皮肤、毛发、眼球、布料、丝袜各补 5 个原创效果扩展，与原基础合计各 6 个方案，每个有 Built-in/URP/HDRP 版本。它们是可编辑的程序/纹理/微表面扩展，不是 3A 成片或原角色复刻；HDRP 专用模型与其他管线的能力差异仍明示。源 StackLit、专用 Eye 与原场景验证缺口未因此消失。库支持设备建议、静态复杂度、搜索与批量材质创建，见 [分类库](ShaderLibrary.md)。

0.3.0 已新增可导入的分类 ASE 图：皮肤、毛发、眼球、衣服布料及丝袜基础各有 Built-in/URP/HDRP 示例，另有三版毛发、三版眼球和两张织物等本地 HDRP 原图适配。所有可导入条目已在实际 ASE 保存重载并编译，见 [分类库](ShaderLibrary.md)。原创基础不表示原材质复刻，适配图仍需要原材质资源/宿主及视觉核对。0.2.9 的 `RecipeRecorded` 档案继续表示完整人物生产要求，不能据库中示例承诺任意人物材质已能自动转换或达到 3A 画质。

以下为 0.2.9 研究阶段的范围和接口记录；其中“未生成”适用于该历史批次。

皮肤、头发/毛发、眼球、衣服布料现已作为四份独立档案接入插件，覆盖输入资源、必须保留的语义、三条管线依赖、验证场景和成本线索。这里的“训练”指阅读参考源码并把研究结果持久化为插件规则与检查能力，不是训练模型权重，也不是已完成四种 3A 材质的自动生成。

四份档案均为 `RecipeRecorded`；分析命中为 `AnalysisOnly`，Built-in / URP / HDRP 的完整生成适配均为 `RequiresAdapter`。参考模板存在，只证明可以进一步检查模板，不能当作已经接通全部光照、资源与辅助 Pass。

| 材质 | 本版记录和检查的范围 | 关键外部依赖 |
| --- | --- | --- |
| 皮肤 | 漫反射/高光分离、次表面扩散、薄部位透射、厚度、宏观/毛孔法线、粗糙度、可选表情皱纹 | Diffusion Profile 或声明的预积分 LUT、扩散调度、帧设置、蒙皮与表情驱动 |
| 头发/毛发 | 发卡、真实发丝、Shell/Fin 的区别；切线与手性；双高光和 R/TT/TRT 模型；覆盖率、双面、阴影/深度/运动与 LOD | 网格根梢/密度/方向数据、透明排序、仿真、历史位置；不能用发卡公式代替所有发丝系统 |
| 眼球 | 角膜与虹膜/巩膜分层、独立法线/粗糙度、IOR、虹膜深度、瞳孔缩放、角膜缘、巩膜散射 | 专用 Eye BSDF/模板、折射输入、眼睑遮挡、泪线与视线动画；瞳孔黑色不等于透明 |
| 衣服布料 | 棉/绒面 Charlie/Sheen、丝绸各向异性、织纹方向/真实尺度、细节法线过滤、双面、厚度/透射 | 相应光照模板、蒙皮/布料模拟、阴影/深度/运动 Pass、透射资源 |

## 使用

0.3.4 在 Unity 打开：

`Tools → ASE Shader Converter → ASE 着色器库`

选择皮肤、毛发、眼球或布料分类及目标管线，展开“材质说明与适配要求”，查看输入、依赖与待验证项。独立人物库菜单已取消；旧代码 `CharacterMaterialWindow.Open()` 跳转到统一库的皮肤分类。主转换器的分析结果跳转到命中的人物分类。“检查当前项目环境与参考模板端口”执行真实 `probe`；管线一致且参考模板已激活时执行 `describe`。找不到专用模板时显示缺口。此按钮不生成图。

在主转换器中分析源码时，“转换规则与已记录的语义”会显示人物材质线索与必审项。分类基于去除注释后的符号与命名线索，可能重叠或误判，仍需核对实际源码和资源。通用 `eyeDepth`、`EyeAdaptation`、立体视图索引及 `skinning` 不应单独认定为眼球或皮肤。分类不会解除 Pass、阶段、宏、依赖或状态阻塞。

## 资源约定

基色通常为 sRGB；法线标为 NormalMap，必须保留原解码、切线空间和合成方法。遮罩、厚度、粗糙度、方向等数据通常为 Linear，但不假设任意源材质使用相同打包通道。IOR、瞳孔尺度、虹膜深度与厚度的范围和单位需按源实现确认。Diffusion Profile 是管线资产，不能自动替换成任意纹理。LUT 必须有明确生成、绑定和采样约定。

纹理、网格、宿主动画/仿真、Renderer Feature、扩散调度与管线资源均属于完整效果的依赖。只转换片元颜色数学不能重现整个角色材质。

## 管线与实际模板

Built-in 与 URP 仍需专用光照/宿主适配，默认 Standard/Lit 不具备上述全部散射模型。HDRP 参考版本是本机安装的 **14.0.8**，不能自动套用更新版本的能力。

Unity 2022.3.10f1 / ASE 1.9.9.13 / HDRP 14.0.8 的实际 probe/describe 已核对：

| 档案 | 参考模板 GUID | 当前证据 |
| --- | --- | --- |
| Skin | `53b46d85872c5b24c8f4f0a1c3fe4c87` | HDRP Lit 的真实端口/选项描述，仍需 SSS/Transmission 与宿主配置适配 |
| Hair | `e4fe21624ace6de4b9fbaabdda0c51de` | HDRP Hair 的真实端口/选项描述，尚未提交完整转换计划 |
| Fabric | `41e04be03f2c20941bc749271be1c937` | HDRP Fabric 的真实端口/选项描述，尚未提交完整转换计划 |
| Eye | 无 | 当前 probe 未发现独立 Eye 模板，不自动降级到普通 Lit |

上述 GUID 是参考身份，其他项目仍需重新 probe/describe。当前人物档案没有生成 ASE 图，没有人物 Shader 编译、角色画面对比或 GPU 基准。窗口创建/关闭测试也不代表人工完成界面视觉审阅。

## API 与后续验证

`rules` 返回 `ruleLibrary.characterProfiles`。每份档案包括 `inputs`、`pipelines`、`preserve`、`validation`、`costs`、`sources`；管线项的 `referenceTemplateGuid` 可能为空。`analyze` 返回 `analysis.knowledge.characterMaterials`，含命中线索和 `requiredReview`。数据同样由无 Unity 依赖的 `CharacterMaterialLibrary` 提供。

完整转换需继续落实目标模板、各阶段输出、辅助 Pass、关键词、全部属性和宿主依赖，再由 ASE 保存重载、Unity 编译。视觉验收分别比较正/背/掠射光、曝光、近远距离、运动、透明边缘和各材质特有行为；GPU 成本需在目标设备测试，不能根据采样数量或节点数直接排名。

本版来源、许可、固定版本、逐文件分析、模板描述和回归见 [CharacterMaterials029](Evidence/CharacterMaterials029/README.md)。持久实现为 `Runtime/CharacterMaterialLibrary.cs`、`Runtime/ShaderRuleLibrary.cs` 和 `Editor/CharacterMaterialWindow.cs`。
