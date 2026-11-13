# ASE 实际生成样例

此目录的 `.shader` 按通过报告的 `outputPath` 原样复制，未手写或修改 ASE 图数据。文件对应的环境、生成报告与 SHA-256 见 `Documentation~/Evidence/manifest.json`。

| 目录 / 样例 | 来源 | 验证 |
| --- | --- | --- |
| BuiltIn/TintedTexture_ASE.shader | Handwritten/TintedTexture.shader 自动转换 | Unity 6000.0.80f1，重载、编译及固定参数像素比较 |
| BuiltIn/NativeMath_ASE.shader | Handwritten/NativeMath.shader 自动分析后提交计划 | 同上；19 原生节点 |
| BuiltIn/CustomLoop_ASE.shader | Handwritten/CustomLoop.shader 对应的人工计划 | 同上；8 原生节点、1 Custom Expression |
| URP/UniversalTexture_ASE.shader | Handwritten/UniversalTexture.shader 自动转换 | Unity 2022.3.10f1、URP 14.0.8，重载、编译及主颜色 Pass 像素比较 |
| URP/NativePipeline_ASE.shader | 三节点常量计划 | 重载与主 Pass 编译 |
| HDRP/NativePipeline_ASE.shader | 三节点常量计划 | Unity 2022.3.10f1、HDRP 14.0.8，重载与主 Pass 编译；没有画面比较 |

将需要的管线目录中的样例复制到目标项目 `Assets` 后，用已安装的 ASE 打开。不要同时导入其他管线的样例。需要合法安装的 ASE 及其对应管线模板；跨版本打开仍应由 ASE 迁移并重新验证。

CustomLoop 用于展示 Agent 计划的受控回退，不是自动分析器已支持循环的承诺。测试计划构建过程位于 `Tests/UnitySmoke.cs`；SRP 常量计划位于 `Tests/UnitySrpSmoke.cs`。样例未包含 ASE 插件源码或模板安装副本。
