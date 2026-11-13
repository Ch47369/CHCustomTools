# 0.3.7 Agent 文件接入恢复

本轮针对 `ShaderAgentInbox.Update()` 的“无法删除要被替换的文件”警告修复协议文件发布。原实现将所有 IO 错误归并到第 72 行，只显示异常消息；`connection.json` 心跳与请求共用外层 try，心跳失败会在读取请求之前中断。

`AtomicWrite` 现在使用唯一临时文件，先尝试 `File.Replace`。当 Unity/Mono 的替换 API 失败且源/目标仍存在时，先将旧文件重命名保留，再发布完整新文件；发布失败尝试恢复旧文件，恢复失败的错误包含原文件保留位置。清理自身创建的临时/备份文件为尽力操作，不先删除目标。真正的文件占用不会被强制解除。兼容发布期间目标可能短暂不存在，读取方需要稍后重读；不是无间隙原子替换保证。

心跳失败独立退避，不再阻塞请求。请求执行后的响应与归档在当前 Editor 域中保留，写盘失败只重试交付；已发布响应的归档重试不再重写响应，也不重复执行生成。此状态不跨域重载/崩溃持久化，`.processing` 的人工审查与新 id 重试规则保持有效。错误包含操作、路径和异常链。

验证范围：

- 纯核心检查 540 项通过；Editor 引用编译 0 警告、0 错误。
- Unity 2022.3.10f1 / ASE 1.9.9.13 / Windows D3D11 非 batch 隔离项目，23 项恢复检查通过，原始结果见 `recovery.json`。测试通过只读目标复现 `File.Replace` 失败，并验证兼容重命名发布；通过未共享删除权限的读取句柄验证旧内容保留、解除占用后的恢复、心跳独立、响应保留、后续请求等待、归档冲突、诊断路径和清理。
- 测试通过反射推进同一个实际 `Update`，仅将 `nextPoll` 置零跳过 30 秒等待，不改变执行/发布逻辑。没有将具体用户项目中的锁持有者定位为确定原因，也没有在用户项目应用修复。
- 恢复测试不覆盖断电、进程被杀、恶意同时写入或恢复重命名本身失败的注入；对应边界由协议与保留文件诊断说明，不宣称这些情况已验证。
- 完整文件协议 `probe` / `describe` / `analyze` / `generate` 的结果与失败尝试见 `verification.json`。原始失败日志保存在 `.build~/AgentInbox037/Attempts`，不打包本地缓存或完整 Editor 日志。

最终标准 Unity 2022.3.10f1 全流程成功结果为 `protocol.json`：`Generated`、`aseRoundTripPassed=true`、`shaderCompiled=true`、0 Custom Expression。首轮启动未完成测试；首轮协议生成受到本机内置 include/主 Pass 选择失败影响，另一个已安装编辑器启动亦未完成；改为明确使用项目工作目录后，标准编辑器正规重试完成。成功日志中仍有前期内置 include 编译诊断，不能将 Editor 引用编译的 0/0 扩大为整个 Unity 日志零错误；只将最终 API 验证通过的生成标为成功。Tarball 成品的实际安装恢复测试另存于 `Releases~/agent-inbox-install-verification-0.3.7.json`，与最终归档哈希关联，不写入归档后再改变安装包。

着色器目录、规则、模板和全部图沿用 0.3.6；不新增图、转换语义或画面等价结论。目录内部版本保持 `0.3.6`，插件包版本为 `0.3.7`。发包检查将目录/研究/同源契约、Runtime、其余 Editor 文件与 Samples 对照固定 0.3.6 Tarball SHA-256 `a8b329a09aa185cb34c844a051c0f6028e651689facd3b74ef9e16809f1f4ec2`；全部 293 份库图须哈希一致。

复现（关闭隔离 Unity，保留用户编辑器）：

```powershell
dotnet run --project Tests/CoreChecks.csproj --configfile .nuget.empty.config
dotnet build Tests/EditorCompile.csproj --configfile .nuget.empty.config
& Tools~/Run-AgentInbox.ps1 -Mode Recovery
# 等待上述进程退出后再运行另一项。
& Tools~/Run-AgentInbox.ps1 -Mode Protocol
```

两项均使用已准备好的 `.validation/Unity2022`，不自动下载或复制 ASE。`Run-AgentInbox.ps1` 支持 `-UnityEditorPath` 指定已安装编辑器；标记文件确保启动域重载后能开始测试。没有协议标记时不自动执行测试。打包和核验：`Tools~/Build-Release.ps1`、`Tools~/Verify-Release.py`、`Tools~/Verify-AgentInboxRelease.py`。历史包与证据保留。
