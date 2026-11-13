# CH自定义工具集 0.4.8 验证

统一入口 Tools/CH自定义工具集；Shader / VFX / 设置。音频/VFX 来源固定为 AudioRhythmCurves 1.0.9 的提交 1408814cdfb53dc58c507c0d992c0bb42d44f538，算法/模型仅修改命名空间，窗口改为可序列化内嵌面板。旧 profile 的文本迁移创建独立副本，保留原文件；两版 Unity 均通过实际旧独立包共存和真实保存资源迁移。

629 核心检查，两版 EditorCompile 0 警告/错误。最初源码功能与窗口检查各62项，共存检查各63项。公开更新测试20项，含真实 GitHub 查询、严格新版本按钮规则及各类错误保持单窗。匿名下载完整 0.4.7 发布包15,145,664字节，哈希匹配固定历史文件；无效缓存被拒绝并保留。最终 Tarball 安装重复62项整合检查，结果在 Releases~ 单独保存以避免循环打包。

旧版更新曾真实进入 GitHub clone，3分钟未完成，记录在 old-git-install-failure.json；不能据此说本地 Git 仓库是更新源。完整 HTTP 流也受当前网络影响，历史失败保留在 .build~/GitHubDownload048/Attempts。最终使用公开 GitHub Release API、无登录、Unity 原生 HTTP 并行分段、Content-Range/大小/SHA-256 校验后安装。缓存位于项目 Packages/CHCustomToolsCache~，来源界面显示 GitHub Release。原 Git URL 和旧仓库名继续兼容。

最终 GitHub 发布安装验证使用明确的测试夹具：真实0.4.7包内容/版本，仅回移植当前候选更新器，再从公开 GitHub 下载真实0.4.8并由UPM安装，跨域重载确认版本、路径与来源。它证明新更新器能执行升级，不代表未修改的旧更新器已经得到修复；旧用户可先手动安装一次新版 Tarball。最终结果在 Releases~/github-release-upgrade-0.4.8.json。

未新增着色器转换算法或渲染等价结论；293库图、原协议与文件交付恢复逻辑对照固定0.4.7包逐字节保护。复现：Run-ToolMenus.ps1（UnityCustomToolsSmoke / UnityGitUpdateSmoke / UnityGitHubDownloadSmoke），Run-GitHubReleaseUpgrade.ps1，Verify-CustomToolsRelease.py。外部用户项目未被修改。
