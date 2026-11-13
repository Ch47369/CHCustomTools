# 0.2.6 可核查的研究结果

本目录只含分析数据、来源索引和验证记录，不含第三方完整源码。没有生成 ASE Shader，没有修改用户 Unity 项目。`Planned` 表示核心分析器形成结构可检查的计划，不表示 ASE 已保存重载、Unity 已编译或画面已等价。

| 项目 | 0.2.5 | 0.2.6 |
| --- | --- | --- |
| 同一冻结清单的完整公开 Shader | 436 | 436 |
| 按源管线自动选择目标，可规划 | 0 | 3 |
| 独立 Built-in 目标，可规划 | 未执行逐目标审计 | 3 |
| 独立 URP 目标，可规划 | 未执行逐目标审计 | 3 |
| 独立 HDRP 目标，可规划 | 未执行逐目标审计 | 0 |
| 纯数学函数探针，可规划并通过 .NET 数值参考 | 3/19 | 19/19 |
| 留出仓库完整 Shader，可规划 | 0/3 | 0/3 |
| 本轮 ASE Shader 生成 | 0 | 0 |

累计 24 个仓库、760 个固定提交的源码路径，包含 436 个 Shader 和 324 个 include。0.2.6 新下载 106 个文件，新增 8 个仓库，另扩充已有官方 Graphics 的公共函数目录。跨仓库副本分别计数，文件数不等于独立算法数。一次不存在的仓库获取已在清单记录，未计入成功总数。

- `public-corpus-analysis.json`：逐路径 URL、提交、SHA-256、源管线、三条目标管线结果、规则、分类与静态成本线索；全部哈希已核对。
- `comparison.json`：同一清单、相同哈希的 0.2.5/0.2.6 阻塞差异；不把减少诊断条数算作成功转换。
- `function-probes-before.json` / `function-probes-after.json`：从 NoiseShader Common/Noise1D 和 Nilo 的 invLerp/remap 中提取完整数学定义，外层测试程序只在内存里组装。独立双精度参考检查图的数据流，未模拟 GPU 精度量化。
- `user-reference-analysis.json`：11 个用户参考的分析与前后哈希；8 个已有 ASE 图保持迁移路径，3 个手写文件仍需适配。
- `rule-catalog.json`：36 条规则和 12 个分类，其中 9 组原生计划、1 组分析、1 组 ASE 迁移、25 组方案记录。
- `frozen-sources.json`：固定来源索引，不含本机缓存绝对路径。恢复到 `<corpus-root>/<owner>--<repo>/<path>` 后，将清单放到 corpus 根目录即可运行分析器；根许可与逐文件说明可能不同。
- `verification.json`：303 项核心检查、Unity 2022.3.10f1 引用下 Editor 编译（0 警告/0 错误）、源码哈希与没有执行的验证阶段。

留出仓库为 KinoMirror 和 KinoContour，在实现前由下载集合指定。3 个文件仍因后处理、Pass、include、顶点和深度语义阻塞，不能据此宣称泛化转换已成功。新增的 UI、UI 动效、特效、UV 动画与顶点动画类别中，只有明确实现的数值/UV 子集可由原生计划器执行；完整类别方案仍需模板、阶段、宿主资源和目标管线适配。

复现当前源码分析：

```powershell
dotnet run --project Tests/CoreChecks.csproj --no-restore
dotnet build Tests/EditorCompile.csproj --no-restore
dotnet run --project Tests/CorpusResearch.csproj --no-restore -- <corpus-root>/frozen-sources.json <output-directory>
dotnet run --project Tests/CorpusResearch.csproj --no-restore -- --function-probes <corpus-root> <output-directory>/function-probes.json
```

旧版比较使用修改前保存的 0.2.5 核心程序集；它不随包分发。函数探针测试代码相同，仅替换核心程序集。第三方源码不执行、不导入 Unity、不随交付包分发。
