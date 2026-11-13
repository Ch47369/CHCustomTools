# 0.5.0 场景测量审查与工具集界面

用户要求审查 WorkBuddy 场景测量工具并整合、打包发布，随后要求改进 VFX 自定义命名、修复着色器库按钮对齐。

原插件为用户项目中的 `com.unitytoolbox.distance-measure` 1.1.0。只读快照保存在 `.build~/Measurement050/Original`，原始文件 SHA-256 位于 `provenance.json`；原文件未被改写。整合时保留几何求交和 Scene 标注代码，使用独立命名空间 / GUID，重写存储及内嵌面板。没有导入旧独立窗口或注册第二个 Tools 入口。

| 原问题 | 修复与验证 |
| --- | --- |
| 面积周长没有计算最后一条闭合边 | 3–4–5 三角形周长由 7 修正为 12，面积仍为 6 |
| Physics 命中后直接返回，忽略前方无 Collider 网格 | 比较 Collider / 静态 Mesh 的距离；前方网格、隐藏、禁用和图层过滤实际检查 |
| 未保存场景共用存储键；缺少项目隔离和首次保存迁移 | 项目路径哈希 / 场景 GUID，未保存场景用会话及 handle；首次保存与场景切换实测 |
| 新增、删除、编辑、拖拽缺少 Undo | 使用独立临时 ScriptableObject 状态；真实 Scene 端点拖动和撤销检查 |
| 场景切换 / 重载仍保留输入状态 | 切换场景结束草稿和拖动；离页 / 关闭 / 重载停止捕获，记录经真实重载保留 |
| 0° / 180° 夹角被跳过 | 明确显示较小夹角，0 / 90 / 180 数值检查 |
| 非共面或自交边界可能显示误导性面积 | 共面、自交、退化检查；支持凹形、绕序反转、旋转及大平移；无效边界保留供编辑，不填充或伪造面积 |
| 缓存忽略可见性 / 相机 / 几何变化；控制权清理过宽 | Stage / Scene 可见性、相机投影 / 图层、ObjectChange / Undo 失效；只释放本工具 hotControl |
| 损坏数据或缺失条目可能覆盖旧记录 | 完整读取校验、保留旧字节、阻止编辑；健康场景仍可用 |

`unity-<version>-source.json` 是隔离 Unity 中 63 项测量检查；`custom-tools-<version>-source.json` 是 78 项音频 / VFX / 统一窗口回归，包含命名组合的旧方案解析、结果一致、顺序 / 分隔符 / 序号修改和方案保存，以及库按钮行的等宽几何检查。两版引擎为 2022.3.10f1、6000.0.80f1，均为 Windows D3D11 编辑器。功能界面包含中文和 English。

最终包安装结果位于 `Releases~/custom-tools-tarball-install-0.5.0.json`，实际 GitHub Release 下载升级结果位于 `Releases~/github-release-upgrade-0.5.0.json`，它们在打包 / 发布之后生成，避免归档内自引用。

复现：`Tools~/Run-ToolMenus.ps1 -TestClass UnityMeasurementSmoke` 或 `UnityCustomToolsSmoke`，使用独立 RunId；加 `-Tarballs -ShaderVersion 0.5.0` 验证最终包。核心与 EditorCompile 顺序运行。原始失败启动和一次同步 Undo / 切页 / 重载导致的测试夹具中断保留在 `.build~/Measurement050*/Attempts`；正式测试将事件分阶段后重试。不得把中断报告当作成功。Unity 隔离进程活跃时仍禁止修改共享 C#。

测量不是曲面表面积或骨骼 / GPU 形变测量；未进行复杂场景性能基准。293 个图、Runtime、音频算法、GitHub 更新器及 Agent 恢复代码与固定 0.4.9 包逐字节比较。本版不改变转换支持范围，也不增加图生成或画面等价结论。打包排除其他任务的 Backend、原始源码快照和本地缓存。
