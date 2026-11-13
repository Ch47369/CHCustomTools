# 0.4.1 插件更新入口验证

最终检查结果见 `verification.json` 和两份 `unity-*.json`。测试使用工作区内独立项目，不写入外部用户项目；不要求 ASE 或渲染管线。

验证覆盖本包详情扩展、其他包/空选择/删除时隐藏、自动私有 Git 标签发现、重复选择复用会话缓存、无新版本隐藏更新按钮，以及未来版本才显示带版本号的更新按钮。未来版本的显示测试使用明确的合成状态，只验证 UI，不安装不存在的标签。

592 项纯核心检查包含 22 项版本/来源/降级保护检查。Editor 源码分别引用 Unity 2022.3.10f1 和 6000.0.80f1 的实际程序集编译，均为零警告、零错误。两个版本的隔离 Unity 编辑器运行实际私有仓库查询。转换核心、图保存及 SG14 版本限制沿用 0.4.0，本轮不扩大转换语义。

复现：顺序执行 `dotnet run --project Tests/CoreChecks.csproj --configfile .nuget.empty.config`、`dotnet build Tests/EditorCompile.csproj --configfile .nuget.empty.config --nologo`，再执行 `Tools~/Run-PackageUpdater.ps1`；Unity 6 使用该工具的 `-UnityEditorPath` 和独立 `-ProjectName UnityPackageUpdater041Unity6`。Unity 隔离项目活跃时不得修改共享 C#。运行结束后用 `Tools~/Collect-PackageUpdater.py` 收集。所有失败、早期测试与启动记录保留在 `.build~/PackageUpdater041/Attempts`。

标签发布后的 Local/Tarball → Git 实际安装、脚本重载确认及当前 Git 版本重复检查，另存 `Releases~/package-updater-install-verification-0.4.1.json`；该结果在首次打包后产生，避免循环修改已发布标签与包。Tarball/ZIP 排除参考源码、ASE 软件源码和缓存，文件校验见 `Tools~/Verify-Release.py` 与 `Tools~/Verify-PackageUpdaterRelease.py`。
