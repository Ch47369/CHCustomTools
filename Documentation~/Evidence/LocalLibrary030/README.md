# 0.3.0 本地 Shader Graph 研究与分类 ASE 库

本批所有生成、导入及编译在 `F:/ASEShader/.validation` 的隔离项目中执行。外部樱花兔目录只读，不导入或执行原工程脚本，不覆盖源图。第三方原始源码缓存只在 `.build~/LocalShaderGraphs`，不进入安装包。

## 覆盖

- 21 个压缩包和解压目录，797 条来源记录；按内容 SHA-256 去重后 255 份源码：100 Shader Graph、52 子图、57 Shader、32 HLSL、10 CGINC、4 Compute。
- 255 份均核对源哈希；152 张图/子图的新旧 JSON 均解析成功。图/子图及 Shader 共 209 输入 × 3 目标 = 627 次核心分析，无未捕获异常。include/compute 只作清点。
- 2,822 条材质关联、31 条 ProjectVersion 和 31 条管线包版本记录，含压缩包/解压目录的重复来源；未发现名称明确的丝袜材质。
- 100 个 Shader Graph 的保守显式适配器可为 20 个创建计划；这 20 个在实际 HDRP/ASE 环境生成、保存重载并编译。其余 80 个逐项记录首个阻塞，后续仍可能存在其他阻塞。
- 42 个原创基础图覆盖 14 类 × 3 目标，另加入一份此前已验证的完整 Built-in DeepWater。可导入库合计 63 图（Built-in 15、URP 14、HDRP 34）。
- 所有库条目都有中文 Comment、布局/重载验证、0 Custom Expression。原图适配保留原功能组，并按依赖阶段拆分重入，避免逐节点生成气泡。没有原角色/原场景的像素等价、其他 API 或 GPU 基准结果。

## 证据文件

| 文件/目录 | 含义 |
| --- | --- |
| `local-source-research.json` | 源身份、SHA-256、序列化结构/属性/节点/依赖与档案清点，不含原始源码 |
| `project-material-metadata.json` | 原项目版本与材质到 Shader GUID 的关联，不含完整材质 YAML |
| `core-analysis.json` | 255 份源的核心分析、三目标阻塞与分类；此文件自身不证明生成 |
| `local-adaptation-plans.json` | 100 张图的适配结果、纹理 GUID、非活动输出保留方式及实际生成状态 |
| `Original-BuiltIn`, `Original-URP`, `Original-HDRP` | 原创基础图的真实 ASE 生成报告与 probe |
| `Local-HDRP` | 首批试验报告，含最新 HDRP 皮肤/玉石 Diffusion Profile 原生属性更新 |
| `Local-HDRP-refinement` | 中间试验结果；不是最终库清单 |
| `Local-HDRP-final` | 最终适配报告，保留失败/修复/排版重建的历史尝试 |
| `library-manifest.json` | 实际交付 Shader 的路径、SHA-256、验证状态、环境和限制 |
| `verification.json` | 最终检查、导入测试、回归、文件哈希与命令记录 |

失败尝试保留为历史证据：初次库工具缺少输出父目录、URP 发卡模板选项不匹配、动态数值槽未解析、非活动输出/透明深度端口不匹配等。最终条目只采用成功报告；没有通过修改 ASE 元数据或跳过 ASE 校验来解决。

HDRP 活动数据按官方 14.0.8 `HDTarget` 的 FirstOrDefault 规则选择相同类型的第一份数据，不把后续旧副本当成活动配置。Shader Graph 的动态向量按官方规则处理：scalar 可提升，多个非 scalar 选最小宽度；Matrix4x4 序列化默认值仅在已解析为向量时读取第 0 行，真正矩阵运算保持阻塞。Blend 枚举与对应公式按安装包核对。视线坐标通过受限 ASE 版本适配器设置并重载验证。

本地 Eye 源模型为 HDRP Lit/SSS。源 StackLit、专用 Eye BSDF、Hair 真实发丝宿主与 Fog/Decal 等能力不以普通 Lit 替代。Hair 的 light-facing normal 在已核对模板中通过 Strands + Approximate 对应其宏；这项设置不生成发丝几何，也不证明仿真宿主已移植。

## 复现

1. 数据读取：`Tools~/Research-LocalShaderGraphs.py <原目录>`、`Tools~/Enrich-LocalShaderResearch.py`。后者从本地缓存清单读取已授权源目录。
2. 三目标分析：`dotnet run --project Tests/LocalGraphResearch.csproj -- .build~/LocalShaderGraphs/manifest.json Documentation~/Evidence/LocalLibrary030`。
3. 原创计划：`Tools~/Build-ShaderLibraryPlans.py`；原图显式计划：`Tools~/Plan-LocalShaderGraphs.py`。只输出普通计划 JSON，不写 ASE 序列化。
4. 在各隔离项目复制 `Tests/UnityLibraryBuild.cs` 至 Assets/Editor，先 `UnityLibraryBuild.Describe` 实际 probe/describe，再 `UnityLibraryBuild.Run -libraryJobs <清单>`。等待 `ASE_LIBRARY_BUILD_COMPLETE`；不带 `-quit`。
5. 将成功结果归档到对应证据目录，运行 `Tools~/Collect-ShaderLibrary.py`，只复制成功保存重载且编译通过的实际 Shader 字节。
6. `Tests/UnityLibrarySmoke.cs` 的 `Run` 验证真实窗口/API、路径限制、管线限制和条目导入/编译；`ImportWater` 后重新启动执行 `CheckWaterSupport` 验证深度水资源生成与预制体组件。
7. 顺序执行 CoreChecks、EditorCompile、WaterAssetsCompile；运行 `Tests/ShaderLibraryPlanChecks.py` 及固定 760 清单的 CorpusResearch 回归。最后 `Tools~/Build-Release.ps1` 打包并检查分发排除项。

编译和生成的状态分别记录。原图贴图、Diffusion Profile、材质参数、灯光/曝光、角色几何与视觉比较仍未验证。研究页不是“所有 Shader 已完整转换”的证明。
