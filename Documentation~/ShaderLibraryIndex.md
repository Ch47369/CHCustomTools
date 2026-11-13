# ASE 着色器库索引（0.3.6）

293 份管线文件 / 111 个同源方案；三份齐备 91；三目标功能映射 66。固定测试不等于原场景等价。

[三管线对应与缺口](CrossPipelineLibrary.md)。设备为静态建议，复杂度不是 GPU 测速。

## Eye

| 同源方案 | Built-in | URP | HDRP |
| --- | --- | --- | --- |
| 虹膜瞳孔 | 已生成 / 功能映射；Low / Mobile,Pad,PC | 已生成 / 功能映射；Low / Mobile,Pad,PC | 已生成 / 功能映射；Low / PC |
| 虹膜同心纹 | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / PC |
| 虹膜纹理叠色 | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / PC |
| 虹膜程序斑点 | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / PC |
| 角膜缘平面色环 | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / PC |
| 巩膜顶点染色 | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / PC |
| Eye · 原图适配 1e59d245 | 待适配 / 未生成 | 待适配 / 未生成 | 已生成 / 功能映射；High / PC |
| Eye · 原图适配 6dec954b | 待适配 / 未生成 | 待适配 / 未生成 | 已生成 / 功能映射；High / PC |
| Eye · 原图适配 b22f3d64 | 待适配 / 未生成 | 待适配 / 未生成 | 已生成 / 功能映射；High / PC |

## Fabric

| 同源方案 | Built-in | URP | HDRP |
| --- | --- | --- | --- |
| 格纹布料 | 已生成 / 有功能缺口；Medium / Mobile,Pad,PC | 已生成 / 有功能缺口；Medium / Mobile,Pad,PC | 已生成 / 功能映射；High / PC |
| 交叉织纹染色 | 已生成 / 有功能缺口；Medium / Mobile,Pad,PC | 已生成 / 有功能缺口；Medium / Mobile,Pad,PC | 已生成 / 功能映射；High / PC |
| 织物基础 | 已生成 / 有功能缺口；Medium / Mobile,Pad,PC | 已生成 / 有功能缺口；Medium / Mobile,Pad,PC | 已生成 / 功能映射；High / PC |
| 印花遮罩 | 已生成 / 有功能缺口；Medium / Mobile,Pad,PC | 已生成 / 有功能缺口；Medium / Mobile,Pad,PC | 已生成 / 功能映射；High / PC |
| 条纹布料 | 已生成 / 有功能缺口；Medium / Mobile,Pad,PC | 已生成 / 有功能缺口；Medium / Mobile,Pad,PC | 已生成 / 功能映射；High / PC |
| 顶点布料染色 | 已生成 / 有功能缺口；Medium / Mobile,Pad,PC | 已生成 / 有功能缺口；Medium / Mobile,Pad,PC | 已生成 / 功能映射；High / PC |
| Fabric · 原图适配 aaace430 | 待适配 / 未生成 | 待适配 / 未生成 | 已生成 / 功能映射；High / PC |
| Fabric_Trans · 原图适配 efb1bec0 | 待适配 / 未生成 | 待适配 / 未生成 | 已生成 / 功能映射；High / PC |

## General

| 同源方案 | Built-in | URP | HDRP |
| --- | --- | --- | --- |
| SF_BaseTransparentGlass · 原图适配 044b7612 | 待适配 / 未生成 | 待适配 / 未生成 | 已生成 / 功能映射；Medium / PC |
| SF_Base · 原图适配 0b09e8a8 | 待适配 / 未生成 | 待适配 / 未生成 | 已生成 / 功能映射；Medium / PC |
| SF_Pipe_01 · 原图适配 2a377100 | 待适配 / 未生成 | 待适配 / 未生成 | 已生成 / 功能映射；Low / PC |
| SF_Base_VertexPaint · 原图适配 4a617f9c | 待适配 / 未生成 | 待适配 / 未生成 | 已生成 / 功能映射；High / PC |
| SF_BaseMasked · 原图适配 8cb1136f | 待适配 / 未生成 | 待适配 / 未生成 | 已生成 / 功能映射；Medium / PC |
| Unlit_Graph · 原图适配 91b14ee4 | 待适配 / 未生成 | 待适配 / 未生成 | 已生成 / 功能映射；Medium / PC |
| SF_BaseMaskedTranslucent · 原图适配 98503c76 | 待适配 / 未生成 | 待适配 / 未生成 | 已生成 / 功能映射；High / PC |
| SF_Base · 原图适配 bc4aa57b | 待适配 / 未生成 | 待适配 / 未生成 | 已生成 / 功能映射；Medium / PC |
| Unlit Shadow · 原图适配 e604d2ba | 待适配 / 未生成 | 待适配 / 未生成 | 已生成 / 功能映射；Low / PC |

## Hair

| 同源方案 | Built-in | URP | HDRP |
| --- | --- | --- | --- |
| 局部染发遮罩 | 已生成 / 有功能缺口；Medium / Mobile,Pad,PC | 已生成 / 有功能缺口；Medium / Mobile,Pad,PC | 已生成 / 功能映射；High / PC |
| 发卡覆盖 | 已生成 / 有功能缺口；Low / Mobile,Pad,PC | 已生成 / 有功能缺口；Low / Mobile,Pad,PC | 已生成 / 功能映射；High / PC |
| 发根发梢渐变 | 已生成 / 有功能缺口；Low / Mobile,Pad,PC | 已生成 / 有功能缺口；Low / Mobile,Pad,PC | 已生成 / 功能映射；High / PC |
| 发束条纹染色 | 已生成 / 有功能缺口；Low / Mobile,Pad,PC | 已生成 / 有功能缺口；Low / Mobile,Pad,PC | 已生成 / 功能映射；High / PC |
| 发梢覆盖渐隐 | 已生成 / 有功能缺口；Low / Mobile,Pad,PC | 已生成 / 有功能缺口；Low / Mobile,Pad,PC | 已生成 / 功能映射；High / PC |
| 顶点染发 | 已生成 / 有功能缺口；Low / Mobile,Pad,PC | 已生成 / 有功能缺口；Low / Mobile,Pad,PC | 已生成 / 功能映射；High / PC |
| SRP · 原图适配 4e9932aa | 待适配 / 未生成 | 待适配 / 未生成 | 已生成 / 功能映射；High / PC |
| Girl_Hair · 原图适配 5f1acba5 | 待适配 / 未生成 | 待适配 / 未生成 | 已生成 / 功能映射；High / PC |
| Girl_Hair · 原图适配 8b2f7097 | 待适配 / 未生成 | 待适配 / 未生成 | 已生成 / 功能映射；High / PC |
| Girl_Hair · 原图适配 bf1acc8b | 待适配 / 未生成 | 待适配 / 未生成 | 已生成 / 功能映射；High / PC |

## Hosiery

| 同源方案 | Built-in | URP | HDRP |
| --- | --- | --- | --- |
| 菱形网纹覆盖 | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / PC |
| 波点丝袜覆盖 | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / PC |
| 丝袜覆盖与织纹 | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / PC |
| 渐变丝袜覆盖 | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / PC |
| 蕾丝遮罩覆盖 | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / PC |
| 竖条罗纹覆盖 | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / PC |

## Jade

| 同源方案 | Built-in | URP | HDRP |
| --- | --- | --- | --- |
| 玉石云絮纹理 | 已生成 / 有功能缺口；Medium / Mobile,Pad,PC | 已生成 / 有功能缺口；Medium / Mobile,Pad,PC | 已生成 / 功能映射；High / PC |
| 玉石透射基础 | 已生成 / 有功能缺口；Medium / Mobile,Pad,PC | 已生成 / 有功能缺口；Medium / Mobile,Pad,PC | 已生成 / 功能映射；High / PC |
| 玉石渐变色 | 已生成 / 有功能缺口；Medium / Mobile,Pad,PC | 已生成 / 有功能缺口；Medium / Mobile,Pad,PC | 已生成 / 功能映射；High / PC |
| 玉皮径向遮罩 | 已生成 / 有功能缺口；Medium / Mobile,Pad,PC | 已生成 / 有功能缺口；Medium / Mobile,Pad,PC | 已生成 / 功能映射；High / PC |
| 玉石程序斑点 | 已生成 / 有功能缺口；Medium / Mobile,Pad,PC | 已生成 / 有功能缺口；Medium / Mobile,Pad,PC | 已生成 / 功能映射；High / PC |
| 玉石程序细纹 | 已生成 / 有功能缺口；Medium / Mobile,Pad,PC | 已生成 / 有功能缺口；Medium / Mobile,Pad,PC | 已生成 / 功能映射；High / PC |
| 逻辑光源玉石 · 方木君文章方案 | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / PC |


## Metal

| 同源方案 | Built-in | URP | HDRP |
| --- | --- | --- | --- |
| 拉丝纹理法线 | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / PC |
| 金属粗糙度 | 已生成 / 功能映射；Low / Mobile,Pad,PC | 已生成 / 功能映射；Low / Mobile,Pad,PC | 已生成 / 功能映射；Low / PC |
| 热变色渐变 | 已生成 / 功能映射；Low / Mobile,Pad,PC | 已生成 / 功能映射；Low / Mobile,Pad,PC | 已生成 / 功能映射；Low / PC |
| 氧化遮罩 | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / PC |
| 金属格纹面板 | 已生成 / 功能映射；Low / Mobile,Pad,PC | 已生成 / 功能映射；Low / Mobile,Pad,PC | 已生成 / 功能映射；Low / PC |
| 划痕粗糙度遮罩 | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / PC |
| Shader_Golem_Basic · 原图适配 1ddc5d05 | 待适配 / 未生成 | 待适配 / 未生成 | 已生成 / 功能映射；High / PC |

## Skin

| 同源方案 | Built-in | URP | HDRP |
| --- | --- | --- | --- |
| 顶点色腮红 | 已生成 / 有功能缺口；Medium / Mobile,Pad,PC | 已生成 / 有功能缺口；Medium / Mobile,Pad,PC | 已生成 / 功能映射；High / PC |
| 皮肤污渍层 | 已生成 / 有功能缺口；Medium / Mobile,Pad,PC | 已生成 / 有功能缺口；Medium / Mobile,Pad,PC | 已生成 / 功能映射；High / PC |
| 皮肤微表面 | 已生成 / 有功能缺口；Medium / Mobile,Pad,PC | 已生成 / 有功能缺口；Medium / Mobile,Pad,PC | 已生成 / 功能映射；High / PC |
| 程序雀斑 | 已生成 / 有功能缺口；Medium / Mobile,Pad,PC | 已生成 / 有功能缺口；Medium / Mobile,Pad,PC | 已生成 / 功能映射；High / PC |
| 油光遮罩 | 已生成 / 有功能缺口；Medium / Mobile,Pad,PC | 已生成 / 有功能缺口；Medium / Mobile,Pad,PC | 已生成 / 功能映射；High / PC |
| 肤色渐变 | 已生成 / 有功能缺口；Medium / Mobile,Pad,PC | 已生成 / 有功能缺口；Medium / Mobile,Pad,PC | 已生成 / 功能映射；High / PC |

## Stone

| 同源方案 | Built-in | URP | HDRP |
| --- | --- | --- | --- |
| 裂隙遮罩叠色 | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / PC |
| 岩石细节 | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / PC |
| 苔藓纹理遮罩 | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / PC |
| 岩层条纹 | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / PC |
| 岩石顶点染色 | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / PC |
| 湿润光滑度遮罩 | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / PC |

## UI

| 同源方案 | Built-in | URP | HDRP |
| --- | --- | --- | --- |
| 界面纹理 | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / PC |
| 界面矩形边框 | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / PC |
| 界面纵向渐变 | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / PC |
| 界面纹理叠色 | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / PC |
| 界面径向遮罩 | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / PC |
| 界面扫描线 | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / PC |

## UIEffects

| 同源方案 | Built-in | URP | HDRP |
| --- | --- | --- | --- |
| 界面流光 | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / PC |
| 界面动态网格 | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / PC |
| 界面呼吸亮度 | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / PC |
| 界面扩散圆环 | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / PC |
| 扫描线脉冲 | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / PC |
| 界面循环擦除 | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / PC |

## UVAnimation

| 同源方案 | Built-in | URP | HDRP |
| --- | --- | --- | --- |
| 镜像与万花筒滤镜 | 已生成 / 功能映射；Low / Mobile,Pad,PC | 已生成 / 功能映射；Low / Mobile,Pad,PC | 已生成 / 功能映射；Low / PC |
| 纹理扰动叠层 | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / PC |
| 序列帧叠层 | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / PC |
| 流动遮罩叠层 | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / PC |
| 双层UV流动 | 已生成 / 功能映射；Low / Mobile,Pad,PC | 已生成 / 功能映射；Low / Mobile,Pad,PC | 已生成 / 功能映射；Low / PC |
| 旋转纹理叠层 | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / PC |
| 往返UV叠层 | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / PC |
| RGB · 原图适配 18acaa20 | 待适配 / 未生成 | 待适配 / 未生成 | 已生成 / 功能映射；High / PC |

## VFX

| 同源方案 | Built-in | URP | HDRP |
| --- | --- | --- | --- |
| 三层视差流麻与动态闪片 | 已生成 / 功能映射；High / PC | 已生成 / 功能映射；High / PC | 已生成 / 功能映射；High / PC |
| 模拟信号故障滤镜 | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / PC |
| 数字故障与历史帧混合 | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / PC |
| 自然暗角滤镜 | 已生成 / 功能映射；Low / Mobile,Pad,PC | 已生成 / 功能映射；Low / Mobile,Pad,PC | 已生成 / 功能映射；Low / PC |
| 溶解叠加光束 | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / PC |
| 溶解与边缘 | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / PC |
| 呼吸溶解 | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / PC |
| 溶解叠加圆环 | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / PC |
| 条纹溶解 | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / PC |
| 柔边圆盘溶解 | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / PC |

## VertexAnimation

| 同源方案 | Built-in | URP | HDRP |
| --- | --- | --- | --- |
| 高度加权弯曲 | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / PC |
| 整体上下浮动 | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / PC |
| 双轴交叉风摆 | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / PC |
| 高频颤动 | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / PC |
| 顶点风摆 | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / PC |
| 径向顶点涟漪 | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / PC |

## Water

| 同源方案 | Built-in | URP | HDRP |
| --- | --- | --- | --- |
| DeepWater 深度吸收 / 折射 / 焦散 | 已生成 / 功能映射；High / PC | 已生成 / 功能映射；High / PC | 已生成 / 有功能缺口；High / PC |
| 双层流动法线 | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / PC |
| 流动泡沫遮罩 | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / PC |
| 流动水面基础 | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / PC |
| 掠射角水色 | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / PC |
| 同心波纹水色 | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / PC |
| 顶点波纹水面 | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / Mobile,Pad,PC | 已生成 / 功能映射；Medium / PC |

