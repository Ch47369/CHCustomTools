# DeepWater 场景外观诊断 · 2026-10-22

用户反馈将 DeepWater 材质直接赋给 Plane 后近乎全透明、没有颜色和透明度变化。本次只读检查外部项目的已保存场景/材质/Shader，并在工作区隔离项目实际渲染；没有修改外部用户项目或保存其场景。用户明确确认是直接赋材质。

## 已确认的源状态

`Assets/Art/CC.unity` 中水面 `Plane` 使用 `Assets/Shaders/Water_DeepWater_ASE.mat`，不是配套预制体。水面 Y=20.04，水底 `Plane (1)` Y=19.69，间隔约 0.35 米；保存的场景不存在 DepthWaterSurface 脚本 GUID。材质八个关键词均已开启，Density=0.7，DeepDistance=5，RGB 吸收为 (0.85,0.32,0.17)，两张配套纹理已赋值。不能将问题归因于这些材质开关关闭或纹理缺失。

真实生成 Shader 的浅/深水色只读取 RGB；主输出 Alpha 是常量 1，Blend One Zero。透明外观由 GrabPass 背景透射与 RGB 吸收/散射合成，颜色栏 Alpha 不控制不透明度。不存在独立整体 opacity 属性。此为当前设计限制，不是已实现的可调透明度功能。

两个水平面只有固定的浅间距，未提供明显水深坡度；正视 0.35 米光程时默认 RGB 透过率约 (81%,92%,96%)，深水色权重仅约 7%。观察角度会改变光程，不能将这些估算直接当作任意视角实测值。未检查用户当前未保存的场景、Scene 相机的实际深度绑定或运行时动态更改，不能声称缺组件必然以某一种颜色失效。

保存的 Main Camera 在 Y=1，低于该水面；此 Shader 为 Cull Back 且无水下渲染路径。若是从保存的 Game 相机看，应先把相机放到水面上方；这不代表当前实际编辑器相机位置。

## 隔离复现

`Tests/UnityWaterAppearanceDiagnostic.cs` 在 `.validation/DeepZoom2022` 创建水面与不透明水底，只修改临时材质实例，不挂深度组件，通过相机 DepthTextureMode 开关控制深度请求。为观察颜色/吸收，关闭波浪、细波纹、焦散、岸沫、Fresnel、高光和反射，固定动画；保留深度吸收、散射和屏幕透视。相机位于水面上方，截图 256×256，中央 128×128 计算 RGB 平均绝对差（0–1 归一化）。这些是诊断条件，不是用户原场景截图。

| 对比（对照为 0.35 米水深 / Density 0.7 / 深度开启） | 实测平均差 |
| --- | ---: |
| 水深改为 3 米 | 0.39022017 |
| 浅/深水颜色 Alpha 均从 1 改为 0 | 0 |
| Density 改为 3 | 0.19477029 |
| 相机不请求深度 | 0.08433878 |

前三项为自动断言：深水与增加吸收必须明显改变画面，颜色 Alpha 修改必须保持完全一致。本次通过，Unity 标记 `ASE_WATER_APPEARANCE_DIAGNOSTIC_PASS`。最后一项仅记录该渲染路径的现象：同一进程的前次渲染可能遗留全局深度绑定，不断言所有平台/首次相机渲染的缺深度行为。

- [浅水 0.35 米](shallow-035m-depth-on.png)
- [深水 3 米](deep-3m-depth-on.png)
- [颜色 Alpha=0](shallow-color-alpha-zero.png)
- [浅水 Density=3](shallow-density-3.png)
- [相机不请求深度](shallow-camera-depth-off.png)
- [原始测量](results.json)、[只读检查来源与哈希](inspection.json)

建议用户先给实际水面添加 DepthWaterSurface，保证不透明水底写入深度；临时用 Density=2–3、DeepDistance=0.5–1 排查吸收和深浅颜色，使用有深浅差异的坡形水底。关闭 Screen refraction and bottom 可暂时检查水体 RGB，随后恢复。修改颜色 Alpha 不会生效，需要后续明确设计并验证新的透明度/浑浊度控制。

本次未改 Shader 语义或材质参数，只补充使用说明与隔离诊断工具。CoreChecks 427 项通过，EditorCompile 0 警告/错误。核验程序维护副本仅比实际编译副本更新了一条关于缺深度边界的注释，二者哈希分别记录，执行逻辑相同。
