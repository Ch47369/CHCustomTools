# 0.4.1 安装检查补充

主报告为 `Releases~/package-updater-install-verification-0.4.1.json`。每个隔离项目的 `result.json` 与 `packages-lock.json` 保留实际公开 UPM 安装结果和锁定提交。`v0.4.1` 对应提交 `221089fe7167e4b87c3209db9c06fb497c4da754`；不修改发布标签。

本轮从本地目录和 Tarball 切换到 Git 安装的公开 `Client.Add` 流程、固定标签确认及 SessionState 重载恢复已通过。安装使用仅作用于验证进程的 Git URL 重定向，指向同一发布提交的本地仓库镜像；不等于 GitHub 网络完整拉取通过。Tarball 初次实际安装的 1,144 个文件逐字节一致。Unity 2022.3 的两份 Git 缓存各有 1,235 个源码文件与标签一致（UPM 排除 `.gitignore`）；Unity 6 有 1,234 个完全一致，另一个 `package.json` 被 UPM 添加 `_fingerprint`，已核对该字段等于锁定提交，其余原字段全部相同。

两份包含 `UnityPackageUpdaterSmoke.cs` 的子目录保留实际运行夹具。它只比标签中原夹具增加一行 `EditorUtility.RequestScriptReload()`，用于强制测试正在安装时的脚本重载；相同源码替换来源时 Unity 可以省略自动重编译。该变体仅在隔离项目 Assets/Editor 使用，未修改插件源码。原流程不强制用户项目脚本重载。

`NetworkAttempts` 保留真实 GitHub 拉取超过夹具 210 秒时限的失败结果，以及安装后重查的网络失败。独立 Git CLI 也报告连接重置。初始两版 Unity 的实际私有标签查询通过，证据仍在 Documentation~/Evidence/PackageUpdater041；不同时间的网络状态分别记录，不能将镜像安装当作远程网络验证。

所有操作限定于本工作区的隔离项目，无外部用户项目修改。系统全局 Git 配置未更改；验证用 Git 配置位于忽略的 `.build~/PackageUpdater041`，只通过验证进程的 `GIT_CONFIG_GLOBAL` 引用，不进入包或用户配置。
