# 0.4.0 原生 Shader Graph 后端验证

最终源码检查与隔离 Unity 结果以 [verification.json](verification.json) 为准。使用 Unity 2022.3.10f1、SG/URP 14.0.8、Linear、Windows D3D11，probe/describe 确认实际环境和槽位。手写样例与 Agent 计划生成的实际图经过官方序列化、内容逐字重载比较、实际 Pass 同步编译；未分发官方 SG 源码或参考 Shader。

7 个合成手写输入，各 5 组相同参数，在浮点 RT 中比较原 Shader 与目标图的中心像素，覆盖 UV、算术、三角/取整/插值、参数、2D 纹理；另有 4 组公式参考和未赋纹理 gray 默认值检查。新增的 Enum 夹具使用明确的 `[KeywordEnum(Base,Detail)]`，验证了 `KeywordNode` 的官方保存/重载、编译以及两条关键词变体的颜色分支。该夹具不代表整图、原宿主/场景、真实相机、跨管线或跨平台等价。

ShaderGraph 后端使用显式标准 URP Unlit 宿主适配；非 1 Alpha、Color 属性、未知状态和复杂阶段仍阻塞。通用 ASE↔Shader Graph 自动互转尚未实现。旧 293 ASE 库图、模板、目录/合同/研究与固定 0.3.7 包逐字节相同；Agent 文件交付逻辑仅菜单改名。

复现：顺序运行 CoreChecks 和 EditorCompile，然后在授权隔离项目执行 `Tools~/Run-ShaderGraphNative.ps1`，使用 `Collect-GraphInterop.py <成功 attempt ID>` 收集明确成功的一次结果。失败/重试保留在 `.build~/GraphInterop040/Attempts` 与 `Launches`，不要当成功结果覆盖。

发包执行 `Tools~/Build-Release.ps1`、`Verify-Release.py`、`Verify-GraphInteropRelease.py`。最终 Tarball 另在没有 ASE 的独立 URP 项目安装并复测，结果存于 `Releases~/graph-interop-install-verification-0.4.0.json`，与本目录的源码测试证据分开记录。
