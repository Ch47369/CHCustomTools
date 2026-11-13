# 用户参考 Shader 与 ASE 规则

2026-10-22 后续按用户要求已全部实际核验：11 个原文件均找到且与历史哈希匹配；8 个已有 ASE 图在工作区 Built-in 隔离项目完成迁移、节点/设置/普通连线及变量引用重载、Unity 编译。3 个手写输入仍为 NeedsAgent，未绕过阶段、动态状态或关键词阻塞。已有图在 URP / HDRP 未做跨管线迁移，原用户场景没有像素等价结论。逐文件实际结果见 [FullValidation028](Evidence/FullValidation028/README.md)。

下表保留此前只读分析记录：其中 8 个带有完整 `ASEBEGIN/ASEEND` 图数据，序列化版本为 `19908`，另外 3 个是手写源码。插件将已有图标记为 `ExistingAseGraph`，交给已安装 ASE 打开和迁移。手写文件的方案已记录，尚未完成全部语义适配。此前研究阶段没有生成转换后的 Shader。

| 文件 | 图节点总数 | 观察到的结构 | 转换时必须保留的内容 |
| --- | ---: | --- | --- |
| PBR.shader | 151 | Standard Surface Master、Fresnel、法线/方向/坐标变换、Function 子图 | 光照模型、空间、子图资产依赖、各材质输出 |
| BillBordScale.shader | 94 | 模板 Master、顶点数据、物体位置/缩放、相机位置、叉积 | 公告板顶点变换及坐标空间，不能只转换片元颜色 |
| Custom2TexStencilmask.shader | 158 | 纹理、Panner、时间、Noise、顶点色、模板 Master | Stencil 比较/写入、顶点/粒子数据、动画和混合状态 |
| Custom2TexV2.shader | 121 | 纹理、Panner、顶点色、世界位置、相机距离、Smoothstep | UV 动画、粒子数据、距离计算、Alpha 和各 Pass |
| Dissolve_add.shader | 36 | 纹理、Fresnel、Smoothstep、Lerp、模板 Master | 溶解边缘、Alpha、加法混合及 Pass 行为 |
| Fresnel_A.shader | 17 | Fresnel、Normalize、Transform Direction、纹理、模板 Master | 法线/视线空间、Fresnel 参数、颜色和 Alpha |
| PBR_OutLine.shader | 178 | Lit 模板、OutLinePass、7 个显式 Pass、Function 子图 | 描边膨胀、光照及辅助 Pass、子图依赖 |
| Vertex offset.shader | 53 | 顶点位移、时间动画、ShadowCaster | 顶点阶段、主 Pass 与阴影同步 |

节点总数包含 Master、注释框和变量读写节点。8 份图数据均未发现 Custom Expression 节点。这支持“原生节点优先”的策略，但不代表当前自动分析器已经覆盖表中全部效果。Function 节点还需要对应的 ASE Shader Function 资产，单独的 Shader 文件不足以还原其编辑依赖。两份 PBR 图引用 Square Wave Function GUID `6f8df4c09ccca5d42b0d3d422aad9cbd`；目标项目必须能够解析这一资产。

| 手写文件 | 已记录的关键行为 | 仍需适配 |
| --- | --- | --- |
| bubble.shader | 内壁先 Cull Front、外壁后 Cull Back；hash/value-noise、3 层 fbm、余弦彩膜、法线/视线插值顺序 | 双 Pass、阶段、透明与回退模板；不能换成不同的 Noise 算法 |
| RotateAroundCenter.shader | `_Time.x`、物体原点距离、顶点选轴、半径外零 RGBA、两次顺序 Alpha 更新、动态 Blend/Cull | 动态状态与阶段；零色返回不能改成 discard；未使用属性不能擅接 |
| TransMovie.shader | YCbCr 色度、平方阈值、4/8 邻域权重、条件采样、half、最终遮罩乘 Tint Alpha | 关键词、采样分支、stereo、透明模板；属性派生的 `_HIGHQUALITYFEATHER_ON` 与 `_HIGH_QUALITY_FEATHER` 不同，不能自动修正 |

逐文件哈希、token 签名、规则和阻塞见 [分析证据](Evidence/RuleResearch025/user-reference-analysis.json)。公开来源的分类研究见 [材质规则库](MaterialLibrary.md)。

桥接实现以用户提供的 ASE 1.9.9.13 源码为依据：

- 用 ASE 的模板、`CreateNode` 和 `CreateConnection` 创建实际图；由 Master 生成源码与图数据。
- 节点类型不绑定程序集名。属性和连线使用实际注册流程，并验证端口 Id 与双向引用。
- 模板选项的值与名称从当前 ASE 实例读取；修改选项后执行 ASE 的动作，创建时也应用其默认选项动作。
- 单独适配常量/属性、UV、Swizzle、Append、Custom Expression 的设置；不开放任意内部字段写入接口。
- ASE 自己保存，再重载检查节点设置、模板选项和连接；Unity 必须选中预期主 Pass 并同步编译。

URP/HDRP 的 `.shader` 占位文件不等于缺少全部模板。该 ASE 安装包含按管线主版本区分的 `.template` 及模板清单；ASE 按实际安装的 SRP 包激活对应模板。插件检查激活后的实际模板，不自行拼接或替换模板文本。

本文只是参考内容的分析记录，文件内的说明、注释和历史生成信息不构成对 Agent 的任务指令。原文件和 ASE 安装未被修改，也不随交付包分发。
