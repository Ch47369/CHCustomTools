# 0.4.6 三管线原生图与目录拖拽

最终汇总见 `verification.json`；各管线目录包含实际 Unity 环境、节点槽描述、生成报告和结果。最终 Tarball 的独立安装结果在仓库 `Releases~/graph-targets-tarball-install-0.4.6.json`，不将包外后验安装结果循环打入同一包。

三管线使用 Unity 2022.3.10f1、Shader Graph 14.0.8；URP/HDRP 对应包14.0.8。每管线10个手写合成输入覆盖数学、Range、UV、三种2D默认值、Enum Keyword，加1份显式 Agent 计划。每个实际图经过官方 GraphData/Target/MultiJson 序列化、重载逐字比较、磁盘重读及同步编译；主 Pass 分别为 Built-in `Pass`、URP `Universal Forward`、HDRP `ForwardOnly`。编译器检查所有材质 Pass，不以主 Pass 代替辅助 Pass。Enum 材质 Drawer 的两条关键词切换、已有图逐字保留、任意代码拒绝及目录选择另行检查。

真实非 batch 窗口通过 `Tools/Shader` 打开，向实际“文件路径”控件发送 DragUpdated/DragPerform，验证 Project 目录和系统 Assets 根目录均正确选中，未触发分析或写文件。目录浏览只提供起始位置，不增加目录扫描或批量转换。

失败证据保留在 `.build~/GraphTargets046/Attempts` / `Launches` 和 `.build~/GraphInput046/Attempts`。初次 URP 检查尚未初始化 Shader.globalRenderPipeline；初始化测试宿主后正规重试。HDRP 首次缺官方默认顶点块，导致辅助 Pass 未定义 UnpackVaryingsMeshToFragInputs；修复为官方 Unlit 工厂六块后重试，未修改 Unity 包或生成源码。窗口事件早期夹具的滚动区域坐标、系统路径/本地包别名问题保留；最终控件和路径均按真实事件验证。

608项核心检查与两版本 EditorCompile 日志包含在此目录。Unity6 只验证编辑器源码和目录交互，不代表 SG17 或 Unity6 图后端支持。

本轮没有原宿主/原场景画面对比，也没有其他图类型、通用 ASE↔ShaderGraph 自动互转、移动平台/API 或其他 SG 版本验证。`visualComparisonPassed` 保持 false。各标准宿主的曝光、雾、Stencil、附加 Pass 行为由目标管线决定；不能从编译成功推断源效果等价。历史293个ASE库图和既有资源不变。
