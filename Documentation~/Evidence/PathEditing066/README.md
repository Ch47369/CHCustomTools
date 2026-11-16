0.6.6 路径编辑修复与逐点三轴旋转。

源代码 Unity 2022.3.10f1 的 50 项检查已通过，包括真实主窗“使用当前选择的路径”点击、选择模型后继续拖点、实际 RotationHandle 拖动、W/E，以及每个开放/闭合路径点的三轴旋转、非均匀缩放、Undo/Redo。测试发送 SceneView 事件并观察几何，不代表物理桌面鼠标验证。

最终 Tarball 的两版安装回归结果与 GitHub 升级报告放在 Releases~，发布页同时附加。测试类 UnityPathEditingSmoke、旧 UnityPathInsertionSmoke/UnitySceneToolsSmoke/UnityPathPreviewSmoke/UnityPathVisibilitySmoke。包覆盖核验 Tools~/Verify-PathEditingRelease.py，固定 0.6.5 SHA256；全部 Runtime、293 图、测量、音频/VFX、渲染与更新器不变。

三轴旋转转动点的切线与 roll，不增加 Runtime 字段；点位置不变，局部曲线形状可变。模型预览仍要求指定模型和启用 Scene 编辑，最后生成才保存。失败尝试保留 .build~/PathEditing066/Attempts。
