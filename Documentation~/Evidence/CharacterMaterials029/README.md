# 0.2.9 人物材质研究与插件接入证据

本批对应皮肤、头发/毛发、眼球、衣服布料四类请求。新增四份材质档案、独立 Eye 分类、人物语义审查规则及 Editor 入口，目录为 40 条规则、13 类。规则分布为 9 NativePlanner、3 AnalysisRule、1 AseMigration、27 RecipeRecorded。四份人物档案均为方案记录，不代表完整材质自动生成或 3A 画质认证。

## 来源与计数

[sources.json](sources.json) 保存来源、版本/提交、许可、文件 SHA-256 与失败信息，不包含第三方源码。

- `leonardo-domingues/skin-shader-unity`：12 份文件，MIT，提交 `80e8c17424dd2d541922b7af227768f94fd30b6d`。
- `itsFulcrum/Unity-URP-Hair-Shader`：7 份文件，CC0-1.0，提交 `ffdb2a6549859c0387ea595bbb1e735ddcb95b32`。
- 本机已安装官方 HDRP 14.0.8：16 份 Eye/Hair/Fabric/Lit/SSS 版本参考，Unity Companion License；记录 package.json 和 LICENSE 哈希。该快照不是本次 Git 下载，不声称对应某个 Git HEAD。
- 官方 Graphics 仓库本次刷新超时，保留失败，不计为成功下载；以已安装版本补充明确版本的研究参考。

合计 35 份参考文件，其中 15 个完整 `.shader`、20 个 include；不是 35 个独立算法，也不表示相对旧语料新增了 35 个不同文件。第三方源码仅缓存到 `.build~/ShaderCorpus`，没有执行、导入或随插件打包。根许可不能替代逐文件版权审查。

## 分析与真实 Editor 检查

[Analysis/public-corpus-analysis.json](Analysis/public-corpus-analysis.json) 对 15 个 Shader 执行 Built-in / URP / HDRP 共 45 次目标分析，均保留阻塞，可规划为 0/0/0；20 个 include 仅清点。分析异常为 0，读取前后哈希一致。报告沿用通用 `publicSourceFiles` 字段，来源组成应以上述 19 份公开仓库文件 + 16 份已安装官方包参考解释。

[verification.json](verification.json) 与 [UnityHDRP](UnityHDRP) 来自工作区隔离项目实际运行的 Unity 2022.3.10f1 / ASE 1.9.9.13 / HDRP 14.0.8：

- 通过 `ShaderConverterApi` 实际执行 probe、rules、四类 analyze，四份档案可读取，复杂输入继续阻塞。
- 实际 describe HDRP Hair、Fabric、Lit 参考模板并保存端口/选项。当前 probe 未发现独立 Eye 模板。
- 新 Editor 窗口可创建并关闭；没有进行人工界面视觉审阅。
- 没有生成人物 ASE Shader，没有人物图保存重载、Shader 编译、角色场景视觉对比或 GPU 基准。

日志成功标记为 `ASE_CHARACTER_LIBRARY_SMOKE_PASS`，代码和日志哈希写入 verification。复制到本目录的是 API 输出与元数据，不是 ASE 模板源码。

## 回归与复现

最终核心检查 479 项通过，EditorCompile 零警告/错误，见 [build-checks.json](build-checks.json)。原冻结 760 源码清单再次校验哈希，436 个 Shader 三目标可规划仍为 Built-in 3、URP 3、HDRP 0；324 个 include 仅清点，见 [regression.json](regression.json)。此回归没有重新生成旧样例，不能替代历史 [FullValidation028](../FullValidation028/README.md) 的实际生成证据。

```powershell
dotnet run --project Tests/CoreChecks.csproj --no-restore
dotnet build Tests/EditorCompile.csproj --no-restore
dotnet run --project Tests/CorpusResearch.csproj --no-restore -- .build~/ShaderCorpus/manifest-character-reference029.json Documentation~/Evidence/CharacterMaterials029/Analysis
dotnet run --project Tests/CorpusResearch.csproj --no-restore -- .build~/ShaderCorpus/manifest-research026.json .build~/CharacterRegression029
```

以上 dotnet 操作顺序执行，避免共享输出锁竞争。只读下载入口为 `Tools~/Update-ShaderCorpus.ps1 -CharacterCollection -UseGitData -MaxFilesPerRepository 128`，安装版本参考收集为 `Tools~/Collect-CharacterResearch.py`。Unity 测试入口为 `Tests/UnityCharacterLibrarySmoke.cs` 的 `UnityCharacterLibrarySmoke.Run`，仅允许工作区 `.validation` HDRP 项目；测试方法自行退出 Editor，不加 `-quit`。收集通过 `Tools~/Collect-CharacterResearch.py --collect`。仅复制测试工具到隔离项目，第三方研究源码不导入。

使用与管线限制见 [人物材质库](../../CharacterMaterials.md)。后续优先实现和验证模板、宿主依赖与阶段适配，不能用继续增加下载量替代完整转换。
