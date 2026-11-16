# Scene stability 0.6.5

本轮保留原有配色、圆点、描边、字体和胶囊标签，去掉 Audio / RhythmCurves 下方说明文字。修复右键结束开放测量，右键拖动交给 Unity；所有测量计算、存储和拾取保持原有实现。

发布前使用 v0.6.4 加明确白名单的独立包副本，避免混入工作区另一项 SidebarLine / Backend 功能。Runtime、293 图、音频 VFX 算法和更新器逐字节保护。

SceneStability 测试以 SceneView.SendEvent 发送实际编辑器事件，并读取 Scene 渲染像素；覆盖 24 帧近原点 / 大坐标、透视 / 正交和轻微相机移动，以及跨近裁面线条。不是物理鼠标右键拖动的桌面验收。PathPreview 覆盖连续透明绘制、旧输出恢复、Game 相机隔离、保存场景字节不变及清理；其透明重复绘制测试在 0.6.4 也通过，因此属于回归保护，不作为已复现的旧版故障。

未发布的早期尝试保留在 .build~/SceneStability065*/Attempts 与 PreviousReports。原生宽线在大坐标透视下出现断线和尖刺；GL 试验在不同回调次序中出现不稳定结果，未作为发布实现。最终用不修改 GL 矩阵的 Editor 专用投影材质与临时 Mesh 绘制，保留深度及像素宽度，并统一最后绘制标签。

最终源验证见 verification.json；最终 Tarball 安装、全部包内容和 GitHub 实际升级报告在 Releases~ 中。
