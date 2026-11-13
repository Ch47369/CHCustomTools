# 0.2.8 完整性接续审计（2026-10-22）

没有验证全部 Shader 的实际转换。此次对冻结清单做核心分析、契约回归和引用编译，不生成转换后的 ASE Shader，不执行来源代码，不修改用户项目。机器可读验证阶段均保持 false。

| 检查范围 | 结果 | 结论边界 |
| --- | --- | --- |
| 公开源码 | 24 仓库，760 文件，SHA-256 与固定清单一致 | 436 Shader、324 include；include 仅清点 |
| Built-in 自动计划 | 3/436，修复前后不变 | 433 仍阻塞；不是生成成功率 |
| URP 自动计划 | 3/436，修复前后不变 | 433 仍阻塞；不是生成成功率 |
| HDRP 自动计划 | 0/436 | 保留模板、曝光与源管线审查 |
| 留出完整 Shader | 0/3 可规划 | 未证明泛化转换成功 |
| 39 组合成契约、三目标 | 65/117 → 117/117 | 目标是检出语义遗漏与误拒绝，不是 39 个材质已转换 |
| 核心检查 | 310 → 427，通过 | .NET 计划/数值/结构与阻塞检查 |
| 公开函数提取探针 | 19/19 数值参考通过 | 函数级，不模拟 GPU half/fixed 精度 |
| EditorCompile | Unity 2022.3.10f1 引用，零警告/错误 | C# 编译，不是 Shader 编译 |
| 本轮实际 ASE 生成/重载、Shader 编译、画面比较 | 均未执行，生成数 0 | 历史样例证据不迁移到新规则 |

修复前的目标结果中，32 项本应阻塞却可规划，4 项合法空白指令写法误拒绝；修复后两者均归零。其余 16 项变化是加强阻塞原因验证：HDRP 原有总阻塞仍必须包含被测问题的具体诊断。重复入口案例将额外重载放在正常函数之后，确保检查不会只因错误选中首个签名而碰巧通过。前后使用完全相同的最终测试输入和测试程序集，仅替换核心程序集；基线核心 DLL 仅缓存在 `.build~`，不分发。

本次补足的是依赖和阶段审查：识别 `#` 后空白；对引号和尖括号 include 审核完整操作数；宏路径、续行和 `include_with_pragmas` 保持阻塞；续行在原始源码上检查以免 `//` 续行隐藏有效代码；拒绝覆盖 `UnityObjectToClipPos`、`TransformObjectToHClip`、`TRANSFORM_TEX` 的辅助函数；核对入口唯一定义与顶点输出声明、赋值、最终 return 顺序。新增规则为 `AnalysisRule`，未实现依赖预处理器、复杂光照模板或任意顶点动画。

`comparison.json` 保存同清单三目标与 12 类启发式覆盖、75 项目标诊断差异；`public-corpus-results.json` 保存 760 个路径、提交、SHA-256、分类和逐目标阻塞；`semantic-before.json` 与 `semantic-after.json` 保存相同 39 组自有合成输入及结果；`function-probes.json` 记录函数探针数值结果；`rule-catalog.json` 为当前规则目录；`verification.json` 记录源码哈希、命令、编译与未执行阶段。固定来源、URL、许可与逐文件声明可追溯到相同哈希的 [0.2.6 来源索引](../RuleResearch026/frozen-sources.json)，第三方源码仅位于 `.build~/ShaderCorpus`。

12 类的完整 Shader 命中数分别为水 10、皮肤 52、头发 11、布料 9、金属 50、石头 6、玉石 0、UI 43、UI 动效 24、特效 26、UV 动画 48、顶点动画 91。命中可以重叠，所有命中的完整 Shader 均仍阻塞；不能把类别记录等同于已支持。玉石存在研究规则及 include 线索，但此批没有命中的完整 Shader，属于验证缺口。

复现工作区源码检查：

```powershell
dotnet run --project Tests/CoreChecks.csproj --no-restore
dotnet build Tests/EditorCompile.csproj --no-restore
dotnet run --project Tests/CorpusResearch.csproj --no-restore -- --semantic-audit .build~/Audit/semantic-after.json
dotnet run --project Tests/CorpusResearch.csproj --no-restore -- .build~/ShaderCorpus/manifest-research026.json .build~/Audit/after
dotnet run --project Tests/CorpusResearch.csproj --no-restore -- --function-probes .build~/ShaderCorpus .build~/Audit/function-probes.json
```

若保存了修改前的核心程序集，可用 `Tools~/Compare-CompletenessAudit.ps1` 对同一清单和相同合成输入生成前后对照。当前只更新工作区源码与文档，未重打包或安装新版 tarball。未向正在运行的用户 Unity 项目提交 probe/describe 请求；本轮范围不进入项目内生成验证。
