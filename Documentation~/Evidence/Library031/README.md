# 0.3.1 分类、三管线、设备与批量材质库证据

主库为 84 个原创材质方案 × 3 管线 = 252 个 Shader，其中 14 个为 0.3.0 基础方案，70 个为本次有实际连接计算的原创效果扩展。补充库是历史 20 个 HDRP 原图适配及 Built-in DeepWater，共 21 个单管线图；总计 273 文件、105 个方案。不能将管线文件数称作独立算法数，也不能把这些原创扩展称作网上/樱花兔源码的自动转换。

## 图生成

环境为 Unity 2022.3.10f1、ASE 1.9.9.13、URP/HDRP 14.0.8、Windows D3D11。仅使用工作区 `.validation/Unity2022`、`UnityURP`、`UnityHDRP`，未直接写外部用户项目或源项目。

- `Build-BuiltIn/results.json`、`Build-URP/results.json`、`Build-HDRP/results.json`：各 70 个最终成功结果，含真实 ASE 保存重载、Unity 编译、节点布局/中文 Comment 校验。
- `Build-*/probe.json`：实际宿主/模板版本检查；运行时在各项目 LibraryBuildEvidence 中保留逐图 describe 结果。
- `Build-BuiltIn-initial`、`Build-BuiltIn-retry`、`Build-URP-initial`、`Build-HDRP-initial`：保留首轮与中间尝试。Built-in 初次 Grid 因重复 `_PatternFrequency` 阻塞，修复后重跑；Grid 三目标最终还统一修复了中间脚本管道造成的标题编码问题。没有把这些中间输出作为最终库图。
- `Build-URP-final-grid`、`Build-HDRP-final-grid`、`Build-BuiltIn-final-grid-verified`：最终 Grid 重跑；最终 70 项清单用成功重跑替换相同 id 的中间结果，合并原因记录于 `note`。
- `Build-BuiltIn-licensing-failed-stale-result`：一次补跑未通过 Unity 授权握手，未执行测试；当时误读的旧结果保留为无效历史数据，不计入 Generated。后续移开旧结果，通过正常 Unity 启动重试，核对报告 Shader 名称等于最终计划，并实际重新生成和导入验证。收集器现强制拒绝名称与计划不同的过期结果。没有修改或绕过许可。
- `plan-contracts.json`：最终节点计划 SHA-256、结构数量与生成文件哈希。

新图均由 ASE API 写出元数据，没有拼接 ASE 主节点参数/元数据，没有 Custom Expression。原始参考 Shader、Graph、纹理和 ASE 软件源代码不打包。0.3.0 的 63 个已有库图保持原 SHA-256，证明本次没有覆盖参考或悄悄替换已有图。

## 分类与性能

- `library-manifest.json`：完整条目、管线与复杂度计数。
- `family-coverage.json`：105 个方案的三管线状态，缺失项为 RequiresAdapter。
- `static-profile-policy.json`：低/中/高复杂度分级依据；设备标签重叠。

HDRP 只归 PC；Mobile/Pad 为图级候选，所有项均 NotBenchmarked，另外显示最高 `#pragma target` 要求。只在 D3D11 验证，未做 Android/iOS/Metal/Vulkan/GLES 目标编译和硬件测速。采样位置及节点数不等于动态采样、指令数或 GPU 帧时间。

## 批量生成与发布

`Tests/UnityLibraryBatchSmoke.cs` 调用实际 `ShaderLibraryBatch.Start`，按当前管线生成全部条目，再检查主渲染 Pass、原创示例纹理及导入色彩空间、HDRP 透明混合/关键词、原创发卡裁剪。重复执行核对 Shader/材质复用及用户参数保留，并测试停止、跨管线拒绝、路径越界与错误哈希。每管线的成功结果在验证后收集为 `Batch-<pipeline>.json`，最终汇总是 `verification.json`。

`Batch-HDRP-initial.json` 保留首轮测试中未识别 `Forward Unlit` Pass 名称的失败。104 个材质的公开批量创建已完成，但测试的前向 Pass 名称表缺少该名称，导致检查提前结束；补齐名称后单独重跑 HDRP，最终以成功的 `Batch-HDRP.json` 为准。

原创小型 PNG 在隔离项目通过 Unity API 创建，不复制参考贴图。源材质的贴图、参数、Diffusion Profile、模型及帧设置仍需恢复；这些检查不证明原角色/原场景等价，也没有穷举全部关键词与所有辅助 Pass。

最终 CoreChecks、EditorCompile 与 Python 契约检查命令和进程结果记录在 `checks.json`；发布检查见 `Releases~/release-verification-0.3.1.json`。0.3.0 的来源解析/回归证据仍保留在 `LocalLibrary030`，本次仅扩展材质库和检索/生成工作流，未扩大通用 Shader 自动转换声明。
