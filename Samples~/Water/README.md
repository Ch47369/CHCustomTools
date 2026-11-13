# DeepWater：可编辑的 Built-in ASE 深度水

0.3.0 已将真实 ASE Shader 打包进分类库。打开 `Tools/ASE Shader Converter/分类 ASE 着色器库`，在 Built-in / Water 中导入 DeepWater；等待脚本编译后执行 `Water/Create supporting assets` 即可创建下文的原创配套资源。无需先手动运行节点计划。分类库会保留已有文件；详细安装和其他管线的能力范围见 [分类库说明](../../Documentation~/ShaderLibrary.md)。

这是一套原创的水面节点计划和配套资源工具。`Tools~/Build-DepthWaterPlan.py` 输出插件中间计划；目标 Unity/ASE 通过 `generatePlan` 创建真正的图。脚本不会拼接 ASE 元数据。水面包含三向涌浪及解析斜率、双层流动细波纹、Fresnel、相机深度、RGB 吸收、浅岸泡沫、水底流动焦散、屏幕折射与 PBR 高光/探针反射，全部使用原生 ASE 节点。0.2.8 增加十个效果开关，便于按需要保留效果。

## 当前项目中的使用

- Shader：`Assets/Shaders/DeepWater_ASE.shader`，菜单名 `Water/DeepWater_ASE`。
- 已配置材质：`Assets/Shaders/DeepWater/DeepWater.mat`。
- 可直接拖入场景的预制体：`Assets/Shaders/DeepWater/DeepWater.prefab`。
- 真实 Unity 渲染预览：`Assets/Shaders/DeepWater/DeepWater_Preview.png`。

预制体是水平的 24×24 米水面，128×128 段网格，包含相机深度辅助脚本和一个可选的天空反射探针。把它放在岸边地形上方，调节 Y 高度。预制体未自动添加到用户的场景中。若场景已有合适的 Reflection Probe，可停用预制体里的 `Optional sky reflection` 子物体，使用场景探针。

单独使用材质时，需要水平 XZ 网格、足够的网格细分，以及相机 `DepthTextureMode.Depth`。把 `Runtime/DepthWaterSurface.cs` 加到水面即可在相机渲染前启用深度；它保留相机已有标志，不会在禁用时删除其他效果需要的深度。水底与岸边几何需要写入相机深度，普通不透明材质通常符合条件。

## 直接赋给 Plane 时的颜色与透明度检查

只把 `.mat` 拖到 Plane 不会自动添加深度组件。选中真正的水面，在 Add Component 中添加 `DepthWaterSurface`；源码文件应已导入项目。材质贴图与八个效果关键词齐全，也不能替代相机深度纹理。Built-in 深度还要求水底使用能写入相机深度的 Shader（通常需要相应 ShadowCaster Pass）；透明底面不一定被记录。组件会为能够渲染该水面 Layer 的相机请求深度，包括 Scene 相机；不要仅凭 Inspector 中开关值认定实际深度可用。

当前实现通过 GrabPass 采样背景，在 Shader 内计算水下透射、吸收和散射，再以 `Blend One Zero` 输出已合成的颜色，主输出 Alpha 固定为 1。**Shallow Color / Deep Color 只取 RGB，颜色栏的 A 值不控制透明度。** Inspector 中尚无独立的整体不透明度或浑浊度参数，不应将颜色 A 当作可用功能。

深浅变化主要由水面到不透明水底的光程驱动：透过率 `T=exp(-Absorption×Density×光程)`，越深越有色且越难看清底部。以默认 Density=0.7、Absorption=(0.85,0.32,0.17) 和正视约 0.35 米光程估算，RGB 透过率仍约为 (81%,92%,96%)，视觉接近清水；DeepDistance=5 时深色权重约 7%。两个平行 Plane 之间只有固定浅间距时，也不会自然生成明显的水深渐变。

排查顺序：先确认 DepthWaterSurface 和不透明水底，再临时将 Density 调到 2–3、DeepDistance 调到 0.5–1，并选择有明显 RGB 差异的浅/深水色；这些是诊断值，最终按场景米制尺度调整。把水底一侧降低到 2–3 米、另一侧保留浅岸，才能判断深浅效果。关闭 Enable / 08 Screen refraction and bottom 可暂时去掉背景透视，检查水体 RGB 颜色是否正常；之后重新开启。关闭透视不能代替解决深度依赖，GrabPass 拷贝仍存在。

当前水面只渲染正面（Cull Back），没有水下相机着色；相机在水面下方时不可将不可见结果解释为正常的水下透明效果。反射强度需要场景天空或 Reflection Probe 提供实际反射内容；普通 Unity Plane 顶点稀疏，也无法表现预制网格同样细腻的几何波浪。

## 主要参数

| 参数 | 用途 |
| --- | --- |
| Waves / height、frequency、speed | 米制起伏、波浪频率与整体速度；平滑几何波浪需要细分网格 |
| Ripples / tiling、strength | 表面细波纹密度和强度；纹理是线性斜率数据，保持 sRGB 关闭、Repeat 和 mipmap |
| Depth / absorption RGB、density、deep distance | 水中色光衰减与深浅过渡；提高吸收/密度会使水更浓、更难看清水底 |
| Depth / shallow、deep scattering | 浅水和深水的散射颜色 |
| Foam / width、strength、color | 岸边泡沫范围、强度与颜色 |
| Optics / refraction、reflection、smoothness | 屏幕扭曲强度、反射强度与光滑度 |
| Caustics / brightness、tiling、animation speed | 水底焦散亮度、每米重复次数与流动速度 |
| Caustics / depth extinction、light tint | 深水衰减和聚光的色调；先降低亮度可得到更克制的浅水效果 |

## 效果 Toggle 与成本

在 `DeepWater.mat` 的 Inspector 中勾选/取消各项 Enable。八个原生 ASE Switch 使用 `shader_feature_local`，高光和反射使用模板的本地片元关键词。它们不是把最终强度乘零的普通 float；关闭细波纹、岸沫、焦散和屏幕透视的变体不包含相应的采样分支。

| Inspector 中的开关 | 关闭后的变化 | 成本关系 |
| --- | --- | --- |
| Enable / 01 Geometry waves | 水面几何和涌浪解析斜率变平 | 移除三向波浪贡献；现有网格顶点数不变，需要时另外换低细分网格 |
| Enable / 02 Fine ripples | 去掉两层细波纹法线 | 裁掉两次细波纹采样；岸沫独立采样同一资源，不受此项影响 |
| Enable / 03 Transmission Fresnel | 不再按视角减少水下透射颜色 | 只控制这段透射权重，PBR 反射内部的 Fresnel 保留 |
| Enable / 04 Depth absorption and tint | 透过率变为 1，水体色固定为浅水色 | 不等于关闭相机深度；岸沫、焦散、折射仍可能需要它 |
| Enable / 05 Shore foam | 去掉岸沫及其颜色/粗糙度贡献 | 裁掉一次独立噪声采样与泡沫计算 |
| Enable / 06 Underwater caustics | 去掉水底的流动光网 | 裁掉两次焦散采样、重建与衰减贡献；需要开启水下透视才能看到焦散 |
| Enable / 07 Water scattering | 去掉吸收后的补偿散射与其少量漫反射 | 水下透视关闭时仍保留基础水体颜色 |
| Enable / 08 Screen refraction and bottom | 水底透视改为水体颜色，同时隐藏焦散 | 裁掉屏幕取色及嵌套焦散分支；**ShaderLab GrabPass 的屏幕拷贝仍存在** |
| Specular Highlights | 关闭直接光高光 | 模板 `_SPECULARHIGHLIGHTS_OFF` 变体 |
| Reflections | 关闭水面探针反射采样贡献 | 模板 `_GLOSSYREFLECTIONS_OFF`；外部实时反射探针若仍更新，需要单独停用 |

焦散从已位移水面沿相机视线和深度间隙重建水底世界位置，按 XZ 投影两层原创无缝纹理，并随垂直水深和 RGB 吸收衰减。它用于水面上方看见的不透明水底，不会给其他物体的材质写入真实灯光，也不是水下相机/体积焦散。低角度、遮挡交界和屏幕外仍有屏幕空间近似的限制。

配套有三份可继续调整的材质：`DeepWater_High.mat` 全开；`DeepWater_Medium.mat` 关闭岸沫、焦散和探针反射，保留水下透视与高光；`DeepWater_Low.mat` 保留深浅着色、散射及透射角度权重，使用平静的着色水面。三个预设都仍使用同一带 GrabPass 的 Shader，不等于免屏幕拷贝的低端专用 Shader，也没有 GPU 帧时间保证。可先关闭焦散、探针反射、岸沫，再按画面需要决定细波纹和几何涌浪。

运行时脚本更改效果时，必须同时设置对应 Float 属性与关键词，例如 `_WATER_CAUSTICS` 为 0/1，并 DisableKeyword/EnableKeyword(`_WATER_CAUSTICS_ON`)；只 SetFloat 不会切换变体。高光/反射为 OFF 关键词。构建中的 shader_feature 可能裁掉未使用组合，应让需要的预设材质随构建保留，运行时任意组合需显式保留和验证。

## 节点阅读

图按数据依赖从左向右展开；涌浪与细波纹上下并列，随后汇合法线。十个中文 Comment 区域依次解释世界坐标/时间、涌浪位移、细波纹、法线/Fresnel、深度/吸收、水底焦散、浅岸泡沫、屏幕折射、PBR 合成和主节点输入。常量靠近运算，远距离数值通过命名 Register/Get 传递。可在 ASE 的节点列表中选择对应 Comment，再点 Focus on Selection，聚焦到一个功能区阅读。

## 重新生成

1. 在目标项目安装 ASE 及本插件，先执行 `probe`、`describe`，核对模板和真实端口。计划目前针对 Built-in/Lit 模板 `ed95fe726fd7b4644bb42f4d1ddd2bcd`、ASE 1.9.9.13。
2. 在包工作区运行 `python Tools~/Build-DepthWaterPlan.py water-request.json --shader-path Assets/Shaders/DeepWater_ASE.shader`。如果输出已存在，应使用一个新的诊断路径；插件拒绝覆盖。
3. 将请求按 AgentProtocol 的原子写入方式提交到目标项目 Agent 收件箱，等待 `Generated`、保存重载和编译通过。
4. 把本示例的 `Runtime` 和 `Editor` 源码复制到目标 `Assets/Shaders/DeepWater` 的相应目录。执行 `Tools/ASE Shader Converter/Water/Create supporting assets` 创建原始斜率纹理、焦散纹理、网格、天空 cubemap、材质预设、预制体和预览。旧版水材质只首次初始化新增开关，以后保留用户选择；已有资源复用，工具不会切换或保存打开的场景。

## 验证边界与成本

实际验证环境为 Unity 2022.3.10f1、ASE 1.9.9.13、Built-in、Direct3D11。ASE 保存重载、节点设置、连线、Comment 成员、Register 引用、位置与 ForwardBase 编译经过检查。0.2.8 共 291 个原生计划节点，实际图含 385 个原生节点（33 Register、61 Get）、0 Custom Expression、34 属性、10 个无重叠 Comment。全开、全关和十个效果逐项单独开启/关闭共 22 组关键词组合经过主 Pass 编译与隔离水岸渲染；冻结动画速度后另存焦散开/关预览。它是新创作，没有对应源 Shader 的像素等价结论。URP/HDRP、Android 真机及其他图形 API 尚未验证。

GrabPass 需要屏幕颜色拷贝，相机深度也有成本；较多透明覆盖、网格细分和反射资源应按目标设备测量。当前没有 GPU 基准或“移动端高性能”结论。折射属于屏幕空间近似，浅岸减弱偏移并限制屏幕 UV，未实现前景深度拒绝、水下视角、平面反射或完整海洋模拟。水面预制体的简单天空反射可以替换为场景环境。
