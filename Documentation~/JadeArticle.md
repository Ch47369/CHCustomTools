# 方木君文章方案：逻辑光源玉石

参考：[方木君《Unity移动端高性能玉石材质》](https://mp.weixin.qq.com/s/fzxGFhe5DofKpyauJSPypg)。文章公开一个核心散射函数，没有完整 Shader、参数默认值、模型、贴图和原场景。本次按该函数制作 Built-in、URP、HDRP 三份原生 ASE 图，并用各自标准 Lit 模板补充抛光表面。函数计算与补充材质分别验证；没有作者原场景等价结论。

Unity 入口：`Tools → ASE Shader Converter → ASE 着色器库`，选择“玉石”，搜索“方木君”或“逻辑光源”，安装当前管线的 Shader 与材质。直接文件位于 `Samples~/ShaderLibrary/Jade/<BuiltIn|URP|HDRP>/FangmuLogicalLight_ASE.shader`；在 Unity 中导入后用正版 ASE 打开。标准 Lit 模板需与 Unity、ASE、目标管线版本兼容。

图中的五个中文气泡按顺序解释输入、方向变换、逻辑光源点、距离映射和补充表面。核心使用原生 Transform Direction、Vertex Position、Distance、Power、Saturate 和算术节点；没有 Custom Expression。

逻辑光源位于“局部中心偏移减去局部光方向乘光源距离”。片元到此点的距离除以深度与光源距离之和，做指数与第一次饱和，再用上下限重映射，乘 RGB 散射颜色后做第二次逐通道饱和。重映射的结果不能提前截断，否则会改变高颜色值和超出上限时的结果。

| 参数 | 含义与使用 |
| --- | --- |
| `_JadeOffset` | 局部中心偏移；偏心模型先调这个值，单位与网格局部坐标相同。 |
| `_JadeLightDistance` | 逻辑光源相对中心的距离，图默认 1；不是实时光源到模型的世界距离。 |
| `_JadeDepthDistance` | 距离归一化的深度尺度，图默认 0.5。 |
| `_JadePow` | 距离指数，图默认 2。 |
| `_JadeMinDist` / `_JadeMaxDist` | 第一次 saturate 之后的重映射范围，图默认 0.1 / 0.9。 |
| `_JadeColor` | 核心散射颜色，图默认绿色；文章原默认值未知。 |
| `_JADE_SCENE_LIGHT` | 新材质默认使用场景主方向光。关闭后使用手动方向。 |
| `_JadeMainLightWS` | 手动模式下，指向光源的非零世界方向。 |
| `_SurfaceColor` / `_Smoothness` | 补充 Lit 表面的基色和光滑度。 |
| `_JadeStrength` | 补充的核心 Emission 贡献，设 0 可观察只有 Lit 表面的结果。 |

保持 `DepthDistance + LightDistance > 0`、`MaxDist > MinDist`、`Pow > 0`，光方向非零，物体变换可逆。图保留原公式，不擅加 epsilon。模型缩放会影响局部空间与灯光方向，非等比缩放下的方向需先变换再归一化。静态网格已作为验证范围，骨骼和顶点变形需要另外适配。

场景模式使用 Built-in/URP 的主方向光，HDRP 使用第一盏方向光。需要指定另一盏光或场景无方向光时，关闭场景模式并手动提供世界方向。运行时代码修改开关时，需同步材质 Float 与 `_JADE_SCENE_LIGHT_ON` 关键词。通过库新建材质会初始化这两个状态，重新安装时保留已有材质修改。

核心函数本身不读取灯色、强度、阴影和法线。本次将它接为 Emission；补充 Lit 表面参与标准照明、反射与阴影，Emission 的透光项不会随遮挡消失。需要透光阴影、真实厚度或 HDRP Diffusion Profile 的场景需另做宿主整合。这是逻辑距离近似，不是真实体积散射，也不替代人物皮肤专用模型。

“移动端高性能”是参考文章标题。图的核心没有纹理采样和循环，标准 Lit 宿主另有照明、阴影及环境采样成本；没有移动端/Pad/GPU 时间测量。设备条目只是支持对应 Shader Model 的候选，实际验证平台与结果见 `Evidence/JadeArticle036/verification.json`。

文章未声明明确开源许可。发布内容保留作者、链接及独立实现的节点图，不包含原文章全文、截图、原模型和 ASE 软件源码。原始参考仅存于不分发的 `.build~/JadeReference036`。
