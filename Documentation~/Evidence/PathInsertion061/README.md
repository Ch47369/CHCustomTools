# PathInsertion061

最终源码结果 verification.json：Unity2022.3.10f1与6000.0.80f1各63项实际检查，包含6组精确Bezier分段（开放、闭合末段、自动/手动控制柄、非均匀世界变换、完整前后线形、roll、Undo/Redo），以及真实Scene鼠标Ctrl悬停、Ctrl点击、选择生成物子级、屏幕插点位置、移动手柄拖拽、独立撤销、端点去重和离线不插点。

Scene交互由单一SceneView回调处理，不依赖Inspector窗口存在；原CustomEditor不再重复绘制Scene手柄。最大512点、相机后方/近裁面、Alt、正在操作的其他手柄、测量与运动预览让行。静态生成物仍需重建。全部运行时（含路径程序集）、旧293图、VFX/音频、测量和更新器保持与固定0.6.0包一致。

失败历史保留 .build~/PathInsertion061/Attempts。20261113100109783、100251247、100500470与100729059为SceneView.SendEvent经UI Toolkit工具栏转换坐标后的夹具偏差；诊断确认事件接收位置比发送位置少47像素。最终夹具用公开Scene事件校准坐标转换并保留实际像素精度。100929970与101105513暴露隐藏项目无Inspector导致原CustomEditor手柄不绘制；移入统一Scene回调并完整发送MouseDrag.delta后，101310994通过63项，Unity6的101518361也通过63项。失败不计通过，诊断日志代码已移除。

629核心检查通过，两版EditorCompile均0警告/错误。最终Tarball安装、原99项路径回归、GitHub实际升级另见Releases~报告。验证仅Windows D3D11和所列Unity版本，不扩大Shader转换支持、Player构建或硬件性能结论。
