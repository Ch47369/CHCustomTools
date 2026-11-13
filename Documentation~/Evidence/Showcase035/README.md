# 0.3.5 完整源码效果：三层视差流麻 / 动态闪片

本轮将 AspectURP 的 `Assets/Cases/流麻/流麻flow.shader` 显式改写为 ASE 原生计算图，提供同一源码的 Built-in、URP、HDRP 版本。它是一个完整视觉效果方案，三个管线文件和三种配色预设分别计数，不算九种算法。原图为 Unlit 视差闪片，不能当作 PBR 金属、皮肤散射或真实体积材质。

来源为 `aspect-ux/AspectURP`，固定提交 `5944b6eb656d76e0371c9831a1ac50fbf8f1d934`，SHA-256 `ceb4795f177903e42c4d3ab0e85d6ce3f741750a988346be488f17ff0926252f`。身份见 [source-review.json](source-review.json)，完整 MIT 许可见 [第三方声明](../../ThirdPartyNotices.md)。插件分发 ASE 衍生图及原创程序纹理生成器，不附带参考项目源码或贴图。

图保留原始 RG 法线手动解码、顶点归一化切线视线插值、片元再次归一化、反射视差、三层独立流速和偏移、每层 1–15 次迭代、逐次累计色带 UV、显式 LOD0、pow/step/clamp 遮罩及速度/亮度衰减、逐层 max 与顺序 `Spark += max(Spark,Layer)`、基色叠加以及 MaskAlpha 原始 UV 的 R<0.5 裁剪。分数迭代如 1.5 保留原源码运行两次的行为。保留原 HDR 颜色、Float 流速、Range、Vector、纹理属性及裁剪渲染状态。

原源码中的 `_ParallaxMap`、`_ColorGradient`、`_Color_pow`、`_SparklePower`、高光和边缘光参数不参与最终输出。它们在“原图未参与输出的参数”气泡中保留可编辑接口，没有虚构其功能。光照/抓屏计算在原输出中无贡献，不增加对应宿主依赖。源 `Fallback` 和声明的光照变体保留；本轮同源功能映射限定显式 Unlit 正向 Pass，不证明后备阴影 Pass、XR 或整个原场景等价。

每份计划 1,674 个节点，实际节点与 Register/Get、中文注释以真实 `Build-<pipeline>/results.json` 为准。ASE 1.9.9.13 的 TemplateLocalVarsNode 受限适配器读取模板的真实切线视线插值，HDR ColorNode 通过公开属性 API 设置并保存重载检查。没有把材质算法放进 Custom Expression，也没有手写 ASE 元数据。

安装入口为 **Tools → ASE Shader Converter → ASE 着色器库**。点击“浏览完整源码效果 · 三层视差流麻”，或组合搜索“源码适配 流麻 PC 高”。选择当前工程管线并安装 Shader + 材质。新材质会生成并绑定五张原创示例贴图：噪声、色带、原始 RG 法线、轮廓、底色；另可选中安装的 `.mat`，在该方案详情应用蓝青、金橙、紫色预设。再次安装保留已有材质编辑，主动点击预设会调整所选材质参数，可撤销。

网格必须具备 UV0、法线、切线。原始 RG 法线必须为 **Default + Linear**，不要设成 Unity NormalMap；噪声/裁剪也为 Linear，色带/基色为 sRGB。保留原反射 z 接近零时的掠射角奇点，没有改变原数学来掩盖它。迭代合同范围是 1–15，超范围输入不保证一致。

此效果为 **PC / 高复杂度 / target 4.5**。静态图含 93 个采样位置，三层共最多 45 次迭代；实际采样与指令成本受条件分支、编译器、参数和屏幕覆盖面积影响，没有 GPU 基准。不能因为默认迭代为 3 就宣称适合低端手机。仅在 Unity 2022.3.10f1、ASE 1.9.9.13、Windows D3D11 验证；其他图形 API、移动端及 XR 未验证。

验证文件分别记录生成重载/编译、固定浮点回读、原 URP Shader 对比、实际管线相机、默认材质/配色/复用保护；最终状态以 [verification.json](verification.json) 为准。固定程序贴图、相机和参数夹具不等于原项目场景画面等价。历史版本和失败尝试保留，未成功输出不收录。

最终三管线浮点对照使用相同 Linear 项目色彩空间，并以最大通道误差 1e-5 检查。初次 Built-in Gamma 与 SRP Linear 混用产生底色偏差，该结果及原设置保存在 `.build~/Showcase035/MixedColorSpaces035` 与 Attempts，不能用来宣称三管线画面一致。真实相机图片包含各管线显示/曝光阶段与不同渲染时刻，仅展示可用效果；浮点计算对比使用显式固定时间和相同输入。

最终结果：三管线各 13/13 组浮点状态通过；URP 原源码对照 13/13，最大通道误差约 9.54e-7；Built-in/HDRP 对 URP 的 26 组 Linear 固定夹具最大通道差均为 0。三套实际 Game 相机显示/黑色控制与静止输入的相机物体共同平移测试通过。三套材质安装各完成 5 张贴图类型/色彩空间检查、3 个配色检查，以及材质编辑/安装 Shader/库原图的保留检查。核心 540 项、EditorCompile 零警告/错误。旧 287 个条目及 109 个同源合同保持相同，研究来源身份仍为 1,079。汇总与逐项数值见 verification.json，展示拼图见 preview.png。

复现顺序：`Build-ShowcaseLibrary.py` → `Run-ShowcaseLibrary.ps1 -Stage Build` → `-Stage Render` / `-Stage Scene` → `Collect-ShowcaseLibrary.py` → `-Stage Batch` → `Verify-ShowcaseLibrary.py`。Unity 活跃期间禁止修改共享 C#。Unity 授权失败只作正常重试，不修改许可。

旧版 40 个缺失管线版本、49 个已生成目标功能缺口及 80 个本地 Shader Graph 阻塞不因这一项新效果解除。
