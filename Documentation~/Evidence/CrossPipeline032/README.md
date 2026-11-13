# 同一个 Shader 的三管线对应（0.3.2）

用户要求每个 Shader 都有 Built-in、URP、HDRP 对应的 ASE 版本。本轮将“同源身份、实际文件、功能映射、宿主条件、画面对比”分别记录，不能再只按三份文件宣称功能齐全。

## 当前覆盖与未完成项

- 105 个同源方案、275 份 ASE 文件：Built-in 85、URP 85、HDRP 105。
- 85 个方案有三份图，60 个方案通过三目标功能映射审查；三管线画面等价为 0 项已确认。
- 24 个原创 Skin/Hair/Fabric/Jade 方案在 Built-in/URP 仍缺专用散射/Sheen/发丝模型，共 48 个有缺口的已生成版本。
- DeepWater 三份图已生成，但 HDRP 尚缺原有的独立高光、独立环境反射材质开关；默认均开启。该目标也标为有功能缺口。
- 20 个本地 HDRP 原图仍缺 Built-in/URP 的 40 个目标版本。逐项记录 SSS/Diffusion Profile、Hair、Fabric、SSR、Decals、双面法线、深度偏移或透明深度 Pass 等阻塞；未用普通 Lit 替代。
- 本地 100 个 Shader Graph 中原有 80 个阻塞仍未解决。1,042 条研究来源不是已生成 Shader 数。

`family-contracts.json` 是目录中 `familyContracts` 的证据副本，`computation-signatures.json` 对共同输出的原生计算做递归签名，排除节点 ID、布局和注释差异，保留输入端口、属性默认值、坐标/采样设置与顶点输出。计算签名本身不比较模板 BSDF、Pass 或宿主；这些通过独立缺口与条件记录审查，也不代表画面等价。

## 本轮实际新增

`Tools~/Build-DepthWaterPlan.py` 共享相同的 291 个计划节点，分别映射真实 URP/HDRP 模板选项和端口。生成前实际 `probe`、`describe`，由 ASE 创建图、写入元数据并保存重载。两份输出各有 385 个原生节点、10 组中文注释、0 个 Custom Expression，通过 ASE 1.9.9.13 / Unity 2022.3.10f1 / SRP 14.0.8 / Windows D3D11 编译，见 `Build-URP`、`Build-HDRP`。

保留世界坐标波浪、解析法线、两层细波纹、RGB 指数吸收、深浅水色、Fresnel、岸沫、水底世界坐标焦散、屏幕折射和散射。URP 使用 Opaque Texture + Depth Texture；HDRP 使用 Color Pyramid + Depth，去预曝光后输入 Emission。宿主光照、雾、透明背景范围和反射控制仍有明确差异，没有原场景或跨管线视觉等价结论。

修复新建水材质 Float 默认开启而本地关键词未开启的问题，初始化八组 Float/关键词及原创 Linear 波纹/焦散纹理。仅初始化新材质；复用材质保留用户编辑。不自动修改用户项目的相机、管线资产或场景；完整 Built-in 水面配套脚本没有导入 SRP。

## 验证与复现

相关核心检查为 523 项，EditorCompile 无警告/错误。`Tests/TestCrossPipelineContracts.py` 的 4 项检查包含跨三目标计算签名、属性/顶点改动检测、节点改名不影响签名、透明/世界法线/去预曝光选项。

实际水面夹具为 `Tests/UnityCrossPipelineWaterSmoke.cs`：使用 Linear、Game 相机、斜坡不透明棋盘水底，检查八组功能开关、两档 Density，另外比较无吸收/无扰动透射与移除水面的水底。HDRP 固定曝光，URP 使用单次预览提交。该测试验证有限夹具中的功能作用与颜色回读，不证明三管线灯光或原场景等价，也不评价最终画质。

最终 URP、HDRP **各 13 组、合计 26 组全部通过**。关闭吸收、扰动和反射后的场景颜色回读，两者与移除水面后的不透明水底参考均为像素平均误差 **0**；Density、深度开关与焦散有可测变化。URP Renderer 使用 Copy Depth=After Opaques，Opaque Texture 不下采样。预览图与逐项数据见 `Water-URP/`、`Water-HDRP/`、`Water-URP.json`、`Water-HDRP.json`。

批量入口通过 `Tests/UnityLibraryBatchSmoke.cs` 检查目录 API、105 个对应契约与 60 个三目标映射方案，以及所有当前管线材质、主 Pass、纹理/关键词、复用、编辑保留、停止和路径/哈希/管线保护。最新结果与检查清单由 `verification.json`、`validation-log-index.json` 记录。

最终 Built-in **85/85**、URP **85/85**、HDRP **105/105** 通过。三目标各验证水面的 8 组关键词初始化、2 张 Linear 数据纹理；HDRP 透明状态检查及 URP/HDRP 发卡裁剪检查通过。所有 275 份文件 SHA-256 与目录一致。

失败尝试保留在 `.build~/CrossPipeline032`：首次生成使用了错误的世界法线端口名称，改为 describe 对应模板选项的真实名称后重试成功；原夹具使用 Gamma，不计为有效 Linear 证据；首次 Linear 夹具存在曝光变化、URP Preview 禁用颜色拷贝及透明之后才复制深度的问题；透射回读校准还需关闭 URP 在 F0=0 时仍存在的掠射环境反射。两次 URP 启动授权握手失败，正常重试，未修改许可。以最终成功输出、实际 Shader 名称、输出 SHA-256 和日志完成标记为依据，禁止使用失败启动前的旧结果。

新增工具均只在此工作区/隔离项目操作。源工程及原始 Shader/Shader Graph 未导入、执行、覆盖或分发。包内没有 ASE 软件源码和研究缓存。
