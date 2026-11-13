# 公开源码三管线 ASE 图（0.3.3）

本批次继续下载、逐源码审核和验证，将四个明确带有 MIT 文件内声明的 Kino Shader 改写为原生可编辑 ASE 图。所有图保留四组中文功能注释并由 ASE 写入元数据；不拼装图元数据或校验和。

## 下载与研究边界

`Tools~/Update-ShaderCorpus.ps1 -LibraryCollection -MaxFilesPerRepository 64` 下载 41 份源码：knapeczadam/unity-shaders 的 37 份 Surface/Lambert/BlinnPhong/Standard 等示例，KinoVignette 1 份、KinoGlitch 2 份、KinoMirror 1 份。原始源码仅存放在 `.build~/ShaderCorpus`，未执行原项目脚本或导入原始研究源码，未随包分发。

四份 Kino 原身份已在旧研究清单中，因此新增来源身份是 37 个，不能把 41 份重新下载全计作新增。37 份新示例仍需要逐源码处理光照模型、Surface 编译指令和 Pass；未按下载成功标成 Generated。源代码许可与根许可证/文件内声明分开记录。Ronja 仓库根许可证未明确，本轮没有分发其派生图。KinoMirror 原本是历史留出样本，本轮用于显式适配后不再是未见的留出测试集；历史留出数据不因此改写。

## 四个同源方案与宿主

| 同源方案 | 原始计算与控制 | 宿主要求 |
| --- | --- | --- |
| 自然暗角 | Aspect、Falloff；1/(1+r²)² 衰减；保留 Alpha | 输入图像；宿主负责纵横比 |
| 模拟信号故障 | 原 nrand 常数、_Time.x、扫描线、垂直跳动、横抖和绿色漂移 | 外部设置并积分原同名动画参数 |
| 数字故障 | 噪声位移、历史帧混合、RGB 置换与输入 Alpha | _NoiseTex、_TrashTex 由调用者提供；不在图中捕获历史帧 |
| 镜像与万花筒 | 极坐标重复、边界反射、原全局 SYMMETRY_ON multi_compile | Divisor>0；宿主可使用全局关键词 |

三套插件自有图像滤镜模板均明确保留 Cull Off、ZWrite Off、ZTest Always、Blend Off 和 RGBA 原始输出，分别声明目标管线。它们使用相同的无光照纹理处理；不额外引入雾、曝光或色调映射。图只负责输入纹理到输出纹理的计算；相机注入、SRP Renderer Feature/Custom Pass、XR、动态分辨率和相机纹理方向没有实现或验证。不能把本次输出称作完整的原后处理组件移植。

原 C# 宿主写入的 uniform 以同名材质参数暴露，默认值为插件示例预设。`Mapped` 针对这一明确输入输出范围的 Shader 功能映射，宿主依赖另列；不代表原相机、原工程或完整三管线画面等价。

## 复现与证据

1. 下载：`Tools~/Update-ShaderCorpus.ps1 -LibraryCollection`。固定提交、路径、SHA-256 见 `download-manifest.json`。
2. 计划：`Tools~/Build-PublicLibrary.py`。四份审核源码 SHA-256 被固定，下载发生变化时拒绝生成，要求重新审查。
3. 生成：`Tools~/Run-PublicLibrary.ps1 -Stage Build`。仅使用 `.validation` 项目，通过 probe/describe 与公开 generatePlan API 建图。`Build-*` 保存本轮报告；失败尝试保存在 `.build~/PublicLibrary033/Attempts`。
4. 图像回读：`Tools~/Run-PublicLibrary.ps1 -Stage Filters`。`Tests/UnityPublicFilterSmoke.cs` 使用显式输入纹理、浮点 RT 与 CPU 原公式参考，检查 RGBA、参数和全局关键词作用。此夹具没有自动相机注入或真实历史帧捕获，输出为 `Filters-*`。
5. 入库：`Tools~/Collect-PublicLibrary.py` 只接受同批完成、身份一致且 ASE 重载/编译成功的四源三目标输出；`Build-CrossPipelineContracts.py` 写入同源契约与分类索引。
6. 批量入口：`Tools~/Run-PublicLibrary.ps1 -Stage Batch`，检查公开 API、窗口、批量材质、编辑保留、停止和路径/哈希/管线保护。

最终数量、通过状态和实际像素误差以 `verification.json` 为准。历史 0.3.2 水面测试与 80 个本地 Graph 阻塞保持其原有证据范围。新下载量、独立算法数、管线文件数和硬件性能分别计数。

## 最终结果与失败保留

本批四源三目标 **12/12** 真实 ASE 保存重载/编译通过；每图四组中文注释、原生节点、0 个 Custom Expression。目录总计 **287 份文件 / 109 个同源方案**，Built-in/URP/HDRP 为 **89/89/109**；89 个方案三份文件齐备，64 个方案完成限定功能范围的映射审查。`Mapped` 不表示原工程或通用跨管线视觉等价。

三个显式滤镜夹具各 **13/13**、共 **39/39** 通过。36 组与 CPU 原公式参考比较，最大平均误差 **4.4703171e-8**、最大通道误差 **2.0861626e-7**；另三组扫描线/抖动仅检查有可测变化，避免把不同浮点平台的 sin/hash 随机数当作逐像素等价。两个全局 Mirror 变体均检查了实际采样结果。三管线批量入口 **89/89、89/89、109/109** 通过，包含材质初始化、复用编辑保留、停止和保护检查。水面八组关键词和两张数据贴图继续检查；水面渲染状态使用 0.3.2 历史证据，本轮没有重复声称新跑水面夹具。

核心检查 **523 项通过**，EditorCompile **0 警告 / 0 错误**，Python 对应契约 **6 项通过**。41 份源码的 **123 次核心目标分析**均有明确阻塞，未出现分析异常；四份 Kino 使用单独人工审核的固定 SHA 计划生成，主自动转换器对这些输入仍不生成图。旧有 40 份缺失管线版本、49 个已生成版本功能缺口及 80 个本地 Graph 阻塞没有被新滤镜掩盖。

失败尝试包括：一次测试脚本命名空间遗漏、ASE 模板同行渲染状态标签重叠、SRP 采样宏未定义、SRP 包未安装时的模板导入依赖、UV 推导全屏投影造成纵向翻转，以及点采样测试像素正好落在纹理单元边界。修复后重新运行；最终使用原 UnityObjectToClipPos 顶点变换、48×32 非边界采样和原始浮点读取。Unity 启动偶发许可握手失败仅正常重试，未更改授权数据。所有旧结果在重跑前移入 Attempts，失败启动不复用旧成功结果；日志索引保留路径、摘要和 SHA，原日志留在不分发缓存。

研究身份的历史重复字节记录全部保留。新缓存采用 `.build~/ShaderCorpus/Library033`，防止更新覆盖旧清单；同一提交/路径的 LF 与 CRLF 以可复核的字节转换证明为格式别名，保留旧 SHA，不重复增加来源数。
