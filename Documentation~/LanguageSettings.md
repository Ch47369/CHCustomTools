# CH自定义工具集 · 统一语言设置

Shader转换器 0.4.2 与音频节奏曲线/特效资源整理 1.0.7 的 Package Manager 作者统一为 **CH自定义工具集**。Unity 为非官方包按作者分组；分组前的“包/Packages”由 Unity 的界面语言决定。

语言设置放在插件的独立 **工具集设置** 窗口。转换器主窗口或音频曲线主窗口点击“工具集设置”即可打开；也可使用 `Tools/Shader转换器/工具集设置` 或音频包的 `Tools/CH自定义工具集/设置`。各功能页面不重复提供语言切换控件。

设置仅有 **中文 / English** 两项。没有手动选择时读取 Unity 编辑器当前的界面语言；中文使用中文，其他语言使用 English。点击任意语言后保存为该用户的统一偏好，两个包独立安装或同时安装时均使用同一设置。选择“恢复默认语言”会清除手动偏好，重新根据 Unity 编辑器语言显示，不增加第三种语言选项，也不修改 Unity 或 Windows 的语言。

语言选择保存在本机 `EditorPrefs` 的 `CH.CustomTools.Language`，值为 `zh` 或 `en`。设置作用于同一用户的 CH 工具集全部功能，重启和脚本重载后保留。两个包同时安装时，两处入口打开同一个设置窗口；已打开的功能窗口标题、控件、操作提示和 Package Manager 更新面板会刷新。

界面翻译在显示层处理。兼容菜单入口保持现有路径。用户资源名称、文件路径、Shader 属性引用、已保存的命名规则、搜索预设、报告原始诊断、库中作品与研究正文、图内中文注释保留原值。切换语言不会重写图或转换结果。

Unity 2022.3 与 Unity 6 的编辑器语言读取仅使用已核对的内部只读属性 `UnityEditor.LocalizationDatabase.currentEditorLanguage` 和 `enableEditorLocalization`，不写入 Unity 设置；若未来版本没有这两个属性，缺省显示 English，手动中文/English 仍可使用。转换后端的版本限制沿用原说明。

复现：顺序运行核心检查和 EditorCompile，然后运行 `Tools~/Run-Localization.ps1`。检查覆盖实际窗口、双包共享设置、两个选项、默认与手动优先级、更新控件刷新及作者分组。验证脚本会恢复原语言偏好，仅在 `.validation` 隔离工程操作。
