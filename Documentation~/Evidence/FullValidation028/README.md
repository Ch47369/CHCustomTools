# 2026-10-22 实际整批验证

已对当前恢复出的完整输入清单逐项执行目标环境检查。**插件仍不具备任意 Shader 完整转换能力。** 本证据明确区分阻塞、手写转换、已有 ASE 图迁移、图重载、Unity 编译和固定条件像素比较。

清单共 **457 个独立输入**：436 个公开 `.shader`、11 个用户参考、6 个包内手写示例、4 个此前审核过的源码输入。每个输入都在 Built-in / URP / HDRP 隔离项目通过实际 `ShaderConverterApi` 分析，共 **1371 次目标评估**。原始文件 SHA-256 在处理前后均匹配，没有覆盖原文件。固定公开语料另有 324 个 include，只清点，未独立编译。

这轮是用户随后明确要求“之前说过的所有 Shader 都验证”后的实际运行，与此前 [仅核心完整性审计](../CompletenessAudit028/README.md) 分开记录。所有写入均在本工作区 `.validation`，没有操作外部用户 Unity 项目，没有发布新安装包。

## 目标与结果

环境：Unity **2022.3.10f1**、ASE **1.9.9.13**、URP / HDRP **14.0.8**、Windows / Direct3D11。每个隔离项目先实际 `probe`；生成前按计划请求 `describe` 真实模板和节点端口。Batch 模式直接调用公开 API，不依赖交互编辑器的连接文件队列。

| 目标 | 已评估输入 | Generated：图重载及编译通过 | 已有图迁移及编译通过 | NeedsAgent：阻塞 | 已有图待跨管线迁移 |
| --- | ---: | ---: | ---: | ---: | ---: |
| Built-in | 457 | 11 | 8 | 438 | 0 |
| URP | 457 | 6 | 0 | 443 | 8 |
| HDRP | 457 | 0 | 0 | 449 | 8 |

这些 Generated 数包含公开、包内和已审核输入；不能把 11 / 6 解释成公开材质类别的通过数。最终整批运行无异常或输入哈希变化，阻塞项不是成功项。

| 436 个公开完整 Shader | Built-in | URP | HDRP |
| --- | ---: | ---: | ---: |
| 实际自动生成、ASE 保存重载及 Unity 编译 | 3 | 3 | 0 |
| 保留阻塞 | 433 | 433 | 436 |
| 固定像素状态数量 | 9 | 9 | 0 |
| 对比的最大 RGBA 绝对误差 | 0 | 0 | 未比较 |

三个公开输入均来自固定提交的 `ronja-tutorials/ShaderTutorials`：`Assets/009_Color_Blending/ColorBlending_Plain.shader`、`Assets/046_Partial_Derivatives/step.shader`、`Assets/046_Partial_Derivatives/uv.shader`。每个分别在两条管线执行三组 64×32 Linear RGBAFloat Blit 对比，设置非零颜色和 Blend=0/0.5/1，并拒绝空白参考或非有限像素。它们不能证明原场景、全部材质参数、所有变体或平台视觉等价。

水、皮肤、头发/毛发、布料、金属、石头、玉石、UI、UI 动效、特效、UV 动画、顶点动画 12 类仍是研究范围。这批公开完整 Shader 中相应启发式类别命中的自动通过数仍为 0，玉石完整 Shader 命中为 0。不能将函数节点、RecipeRecorded 或个别专用模板证明为完整类别覆盖。

## 用户的 11 个参考

原始文件全部位于用户提供的 `F:/XJZiZhiQuAR/Assets/Shader/`，与 RuleResearch026 留存的 11 项哈希一致。只在隔离项目复制和保存新的输出。

| 输入 | 类型 | 本次 Built-in 结果 |
| --- | --- | --- |
| BillBordScale.shader | 已有 ASE 图 | 迁移、节点/设置/引用重载、编译通过 |
| Custom2TexStencilmask.shader | 已有 ASE 图 | 同上 |
| Custom2TexV2.shader | 已有 ASE 图 | 同上 |
| Dissolve_add.shader | 已有 ASE 图 | 同上 |
| Fresnel_A.shader | 已有 ASE 图 | 同上 |
| PBR.shader | 已有 ASE 图 | 同上；在安装的 ASE 中解析 Square Wave Function 依赖 |
| PBR_OutLine.shader | 已有 ASE 图 | 同上；保留原图输出及设置 |
| Vertex offset.shader | 已有 ASE 图 | 同上 |
| bubble.shader | 手写 | NeedsAgent：多 Pass、透明/深度/裁剪状态、顶点世界法线及其他语义未完成适配 |
| RotateAroundCenter.shader | 手写 | NeedsAgent：动态 Blend/Cull、顶点/插值语义及属性映射未完成适配 |
| TransMovie.shader | 手写 | NeedsAgent：本地关键词、条件采样、立体渲染初始化和透明状态未完成适配 |

8 个已有图的迁移由真实 ASE API 完成：加载副本 → 保存到新路径 → 重载 → 比较节点 ID/类型、序列化设置、普通双向连线及 Register/Get 的真实引用 → 编译当前材质 Pass。ASE Get Local Var 的隐藏输入是用于循环检查的单向 dummy 引用；核验程序通过公开 `CurrentSelected` / `ReferencedNodeId` 验证它，不错误要求其存在普通反向线。最早的六项反向连接失败是核验程序误报，已修正并全部重跑；失败日志留在隐藏运行目录。

迁移通过表示这些已有图在此版本的 ASE 中可保存重载及编译，**不表示从手写 HLSL 重建成功，也没有原材质/原场景视觉比较**。它们在 URP / HDRP 只识别为已有图，未进行跨管线迁移。

## 已审核输入、基础接口与水示例复测

| 专项 | 本次完成的实际检查 | 视觉范围 |
| --- | --- | --- |
| Normal360、NormalImagePanZoom | 258 项；两图 ASE 重载/编译；49 组状态 | 雾模式、翻转、反向与 UI 参数等固定状态，最大误差 0 |
| DeepZoomPageTable360 | 34 项；ASE 重载/编译；6 组图像与裁剪 | 两种页表尺寸、三种 flip 值，最大误差 0 |
| DeepZoomPageTableUI | 139 项；ASE 重载/编译；排列、注释、引用与开关关闭路径 | 21 组 UI 材质/变体状态，最大误差 0 |
| Built-in 基础接口 | TintedTexture、原生数学、手工 CustomLoop 计划重载及编译 | 各一组 32×32 对比，最大误差 0 |
| URP 基础接口 | 原生常量计划及 UniversalTexture 重载/编译 | UniversalTexture 的固定对比通过 |
| HDRP 基础接口 | 原生常量计划重载及编译 | 无画面对比；不增加自动 HLSL 转换通过数 |
| 原创 DeepWater | 重新生成；ASE 重载/编译；34 属性；22 组关键词组合编译及隔离水岸渲染 | 全开、全关、十效果单独开/关；原创计划，无对应手写源的等价结论 |

4 个已审核源码入口共 76 组固定状态，依赖明确的源码签名和模板，不代表通用 UI/雾/纹理数组 Shader 全部支持。CustomLoop 是显式手工计划的 Custom Expression 接口检查，输入为 `seed:FLOAT4`、`steps:FLOAT`，输出为 `FLOAT4`；原因是输入相关的动态循环无法用标准数学节点表达。没有将未知源码静默放入 Custom Expression。

DeepWater 有 291 个原生计划节点，实际图包含自动加入的排列/变量引用节点。22 个组合是抽样，不是十个开关的全部 1024 种组合；GrabPass 的屏幕拷贝、构建变体裁剪、其他图形 API 和真机性能仍需要另测。该示例的通过不改变 `water-material` 的 RecipeRecorded 状态。

## 文件与复现

- [summary.json](summary.json)：三目标统计，Generated 与 MigrationCompiled 分开。
- [inventory.json](inventory.json)：457 个 ID、组别与原始 SHA-256，不附参考源码。
- [Built-in 逐文件结果](BuiltIn/results.json)、[URP 逐文件结果](URP/results.json)、[HDRP 逐文件结果](HDRP/results.json)：每个输入的状态、阻塞、实际生成报告、哈希、图/编译/fixture 标志。
- 各管线 `provenance.json` 指定最终采用的运行 ID、输入清单和核验代码哈希；同 ID 子目录保存真实 probe / describe。`summary.runIds` 也保留历史完成批次，逐行 `evidenceRunId` 才是结果来源。
- [Smoke](Smoke)：本次基础、已审核输入及水示例的原始 API 报告与固定像素检查结果。
- [verification.json](verification.json)：10 项 Unity 完成标记、隐藏原始日志路径/哈希、专项报告哈希与代码版本。
- [build-checks.json](build-checks.json)：本次 .NET 检查的已观察命令输出、检查数和退出状态。

最终整批运行 ID：Built-in `20261022-014516-4c6f66`、URP `20261022-014451-c9bf13`、HDRP `20261022-014614-0201f3`。原始日志在 `.build~/ValidationRuns`；输出图与来源副本仅在 `.validation`，不随包分发。遇到过 Unity 正规授权握手失败、核验文件替换失败和导入等待问题，已保留失败日志并通过最终完整重跑，未修改许可。

复现时在各管线隔离项目安装实际 ASE/模板和本包，复制 `Tests/UnityFullValidation.cs` 到 `Assets/Editor`。从外部输入清单调用 `UnityFullValidation.Run -validationInventory <inventory.json>`；程序先 probe/describe，每个 Editor update 处理一个输入并等待编译/导入，结束后写完整 JSON 和完成标记，自行退出，不使用 `-quit` 抢先结束。参考的源路径清单在本地隐藏目录，不在公开证据中分发。

随后运行 `powershell.exe -NoProfile -ExecutionPolicy Bypass -File Tools~/Collect-FullValidation.ps1`，再用正常 Python 运行 `Tools~/Summarize-FullValidation.py` 检查原始哈希、完整批次、完成标记和核验代码来源并收集专项证据。后者不会运行第三方源码。水复测使用 `Tools~/Build-DepthWaterPlan.py` 生成中间请求，再通过 `Tests/UnityWaterValidation.cs` 及本项目 Water 配套脚本在隔离项目调用实际 API。

本次修改相关检查：`dotnet run --project Tests/CoreChecks.csproj --no-restore` 为 **427 项通过**；`dotnet build Tests/EditorCompile.csproj --no-restore` 与 `dotnet build Tests/WaterAssetsCompile.csproj --no-restore` 均 **0 警告、0 错误**。未重建 release tarball。下一步完善应优先处理三个手写参考所需的模板、阶段、动态状态及关键词适配，而不是将阻塞项记成成功或继续扩大下载量。
