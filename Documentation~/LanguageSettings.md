# CH 工具 · 内置语言切换

Shader转换器 0.4.5 与音频节奏曲线/特效资源整理 1.0.9 的作者为 **CH**。点击 **Tools/Shader** 直接打开 Shader转换器主窗口；音频曲线与特效引用整理位于 **Tools/VFX**。

每个工具的主窗口直接显示 **中文 / English** 切换按钮。语言功能包含在各自插件包中，随插件安装和更新；没有独立语言插件、设置窗口或顶部设置菜单，各子页面不重复放按钮。

未手动选择时读取 Unity 编辑器当前界面语言，中文显示中文，其他语言显示 English。手动选择后保存偏好，重启与脚本重载后保留。点击“恢复默认语言”清除手动偏好，重新跟随 Unity；语言选项仍只有中文和 English。

同一用户的 CH 功能共用 EditorPrefs 键 `CH.CustomTools.Language`（zh/en）。两个包可以各自安装、维护和更新，无程序集依赖。两包同时安装时，修改任意主窗口的语言会刷新其他工具；资源名称、路径、命名模式、图与原始诊断保留。

Unity 2022.3 与 Unity 6 只读 `UnityEditor.LocalizationDatabase.currentEditorLanguage` 与 `enableEditorLocalization`，不修改 Unity 设置；不支持的版本默认 English，手动切换仍可用。读取延后到编辑器主循环，后台文本查询只读缓存。

复现：顺序运行核心检查和 EditorCompile，再运行 `Tools~/Run-ToolMenus.ps1`。验证仅在 .validation 隔离工程执行，并恢复原语言偏好。0.4.2 历史设置窗口证据单独保留。
