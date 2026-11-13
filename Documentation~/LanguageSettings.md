# CH自定义工具集 · 内置语言切换

作者 **CH**。统一入口为 **Tools → CH自定义工具集**；Shader转换器、音频曲线和特效资源整理均在同一窗口内切换。

语言入口只有 **设置 → 常规** 中的 **中文 / English** 两种选择。全部功能共用这个设置，子页面不重复放语言按钮；语言功能随工具集安装和更新。

未手动选择时读取 Unity 编辑器当前界面语言，中文显示中文，其他语言显示 English。手动选择后保存偏好，重启与脚本重载后保留。点击“恢复默认语言”清除覆盖，重新跟随 Unity；语言选项仍只有中文和 English。

偏好保存于 EditorPrefs 键 `CH.CustomTools.Language`（zh/en）。升级期间若同时安装旧独立音频插件，两者仍共享该偏好。切换语言会刷新窗口；资源名称、路径、命名模式、图与原始诊断保留。

Unity 2022.3 与 Unity 6 只读 `UnityEditor.LocalizationDatabase.currentEditorLanguage` 与 `enableEditorLocalization`，不修改 Unity 设置；不支持的版本默认 English，手动切换仍可用。读取延后到编辑器主循环，后台文本查询只读缓存。

复现：顺序运行核心检查和 EditorCompile，再运行 `Tools~/Run-ToolMenus.ps1`。检查在 `.validation` 隔离项目执行，并恢复原语言偏好。历史设置窗口和独立包验证证据保留。
