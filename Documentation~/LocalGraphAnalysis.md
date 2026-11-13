# 樱花兔本地图剖析索引（0.3.0）

这里按唯一内容 SHA-256 列出 100 张 Shader Graph 的分析和适配状态；52 个子图与其余 Shader/HLSL/Compute 的清点见本轮证据 JSON。名称相同的版本不合并成一张图。分析读取结构、属性、活动模型、状态、阶段及依赖，不执行工程脚本。

20 张适配图使用真实 ASE API 生成并保存重载/编译。原材质纹理、扩散资产、人物模型、灯光/曝光与源场景画面尚未验证；Generated 不表示原图完整生产效果已复现。其余图保留首个阻塞，不能将首个阻塞修复等同于其余语义也已适配。

| 原图路径 | 内容哈希前缀 | 活动模型 | 节点 / 属性 | 本版结果 |
| --- | --- | --- | --- | --- |
| Assets/Art/Shaders/SF_Base BlendingWithTerrain.shadergraph | dff3a366d0cc | HDLitSubTarget | 54 / 15 | 阻塞：Unadapted built-in feature m_ConservativeDepthOffset |
| Assets/Scans Factory/GateBackyard/Shaders/SF_Base.shadergraph | 0b09e8a8e8b4 | HDLitSubTarget | 42 / 13 | 已生成，源资源/画面待验证 |
| Assets/Art/Shaders/SF_BaseDecal_01.shadergraph | c31bbec3eca7 | DecalSubTarget | 18 / 3 | 阻塞：No equivalent ASE template adapter for DecalSubTarget; model not downgraded. |
| Assets/Scans Factory/GateBackyard/Shaders/SF_BaseDecal_02.shadergraph | ecdf53e9246c | DecalSubTarget | 34 / 10 | 阻塞：No equivalent ASE template adapter for DecalSubTarget; model not downgraded. |
| Assets/Art/Shaders/SF_BaseTransparentGlass.shadergraph | 044b7612c112 | HDLitSubTarget | 48 / 16 | 已生成，源资源/画面待验证 |
| Assets/Art/Shaders/SF_Fog.shadergraph | 63e82913eb58 | HDUnlitSubTarget | 30 / 5 | 阻塞：Native semantic adapter not implemented for RemapNode |
| Assets/Scans Factory/GateBackyard/Shaders/SF_Pipe_01.shadergraph | 2a377100bd62 | HDLitSubTarget | 18 / 1 | 已生成，源资源/画面待验证 |
| Assets/Art/Shaders/Anisotropy Graph.shadergraph | 501d7be67506 | HDLitSubTarget | 69 / 23 | 阻塞：Missing transparent feature m_TransparentWritesMotionVec |
| Assets/Art/Shaders/Anisotropy Graph_D.shadergraph | a6de1919eaa3 | HDLitSubTarget | 88 / 27 | 阻塞：Native semantic adapter not implemented for ExponentialNode |
| Assets/Art/Shaders/Anisotropy_S.shadergraph | 4ea2ecce3642 | HDLitSubTarget | 72 / 23 | 阻塞：Missing transparent feature m_TransparentWritesMotionVec |
| Assets/Shader/Girl_Hair.shadergraph | 5f1acba57c6f | HairSubTarget | 62 / 24 | 已生成，源资源/画面待验证 |
| Assets/Art/Shaders/Light.shadergraph | c0533fde7f10 | HDUnlitSubTarget | 73 / 18 | 阻塞：Non-alpha transparent blend requires reviewed target mapping. |
| Assets/Art/Shaders/LitBasicGraph_Iridescence.ShaderGraph | 922206b0d3a3 | HDLitSubTarget | 64 / 23 | 阻塞：Unadapted system feature m_DOTSInstancing |
| Assets/Art/Shaders/Unlit_Graph.shadergraph | 91b14ee430f3 | HDUnlitSubTarget | 9 / 3 | 已生成，源资源/画面待验证 |
| Assets/Art/Shaders/Particle.shadergraph | b1ca84f8cadd | HDUnlitSubTarget | 45 / 5 | 阻塞：Non-alpha transparent blend requires reviewed target mapping. |
| Assets/Art/Shaders/Particle_Blend.shadergraph | 5a4fb1118aec | HDUnlitSubTarget | 42 / 6 | 阻塞：Native semantic adapter not implemented for SceneDepthNode |
| Assets/Art/Shader/Particle_Flow.shadergraph | 7e1c6c498641 | HDUnlitSubTarget | 93 / 15 | 阻塞：Non-alpha transparent blend requires reviewed target mapping. |
| Assets/Art/Shader/Particle_Flow_Blend.shadergraph | 0fe23ee8d499 | HDUnlitSubTarget | 91 / 16 | 阻塞：Native semantic adapter not implemented for CombineNode |
| Assets/Shader/Fabric Shader.shadergraph | dbf4c58cc37f | FabricSubTarget | 76 / 26 | 阻塞：Implicit bound Fresnel normal/view slots need explicit coordinate-space adapters. |
| Assets/Shader/Skin.shadergraph | 4ec73cc0c8d9 | StackLitSubTarget | 71 / 37 | 阻塞：No equivalent ASE template adapter for StackLitSubTarget; model not downgraded. |
| Assets/Game_art/Shader/Fabric_Trans.ShaderGraph | efb1bec0bd9d | FabricSubTarget | 69 / 21 | 已生成，源资源/画面待验证 |
| Assets/Game_art/Shader/Glass_Rain.ShaderGraph | d6d08e15eab3 | HDLitSubTarget | 34 / 11 | 阻塞：Non-default transparent rendering pass requires review. |
| Assets/Game_art/Shader/RGB.shadergraph | 18acaa20c040 | HDLitSubTarget | 37 / 10 | 已生成，源资源/画面待验证 |
| Assets/Game_art/Shader/Velvet.ShaderGraph | a42337ecb412 | LegacyNestedJson | 40 / 15 | 阻塞：Legacy master-node graph needs version migration and a model adapter. |
| Assets/Art/Shader/Cover Grass.ShaderGraph | 85a538b528c3 | LegacyNestedJson | 67 / 8 | 阻塞：Legacy master-node graph needs version migration and a model adapter. |
| Assets/Art/Shader/Distortion.shadergraph | 293755a24c51 | LegacyNestedJson | 53 / 14 | 阻塞：Legacy master-node graph needs version migration and a model adapter. |
| Assets/Art/Shader/Leafs.shadergraph | 0d98ce2bd295 | HDLitSubTarget | 59 / 15 | 阻塞：Unadapted system feature m_DOTSInstancing |
| Assets/Game_art/Volumetric Samples/Fog Volume Shadergraph/LocalClouds.shadergraph | ce2ef9e9e16c | FogVolumeSubTarget | 55 / 14 | 阻塞：No equivalent ASE template adapter for FogVolumeSubTarget; model not downgraded. |
| Girl_project(1)/Assets/ShaderLibrary/Eye.shadergraph | b22f3d64654c | HDLitSubTarget | 194 / 22 | 已生成，源资源/画面待验证 |
| Assets/ShaderLibrary/Girl_Hair.shadergraph | bf1acc8b5350 | HairSubTarget | 62 / 24 | 已生成，源资源/画面待验证 |
| Assets/ShaderLibrary/LitSimple_wobble.shadergraph | 4aa9f2d9d0e6 | HDLitSubTarget | 123 / 31 | 阻塞：Keyword definitions and branches have not been mapped. |
| Assets/ShaderLibrary/Skin_Rain.shadergraph | 5d3637eaa5b3 | StackLitSubTarget | 102 / 35 | 阻塞：No equivalent ASE template adapter for StackLitSubTarget; model not downgraded. |
| Assets/_Packages/com.unity.demoteam.hair/Samples~/HairSample/Materials/SRP.shadergraph | 4e9932aa7d81 | HDLitSubTarget  /  UniversalLitSubTarget | 13 / 2 | 已生成，源资源/画面待验证 |
| Assets/Shaders/Hair/HairShader Graph.shadergraph | 7ffd503f71d3 | HairSubTarget | 27 / 4 | 阻塞：Connected vertex stage VertexDescription.Position needs reviewed absolute/relative and normal/tangent mapping. |
| Assets/Shaders/Hair/HairShader.shadergraph | 3e9616eef84c | HairSubTarget | 153 / 41 | 阻塞：Unadapted system feature m_CustomVelocity |
| Assets/Shaders/Hair/MarschnerBasic.shadergraph | 75a13af9e5b0 | HairSubTarget | 30 / 6 | 阻塞：Unadapted system feature m_CustomVelocity |
| Assets/Shaders/ShaderLibrary/DigitalHuman_Skin_Rain.shadergraph | a0b3b9bf8192 | StackLitSubTarget | 102 / 35 | 阻塞：No equivalent ASE template adapter for StackLitSubTarget; model not downgraded. |
| Assets/Shaders/ShaderLibrary/Eye.shadergraph | 6dec954b5a2e | HDLitSubTarget | 219 / 22 | 已生成，源资源/画面待验证 |
| Assets/_Packages/com.unity.demoteam.hair/Runtime/HairMaterialDefaultLitSRP.shadergraph | 6c683211e8ec | HDLitSubTarget  /  UniversalLitSubTarget | 12 / 0 | 阻塞：Connected vertex stage VertexDescription.Normal needs reviewed absolute/relative and normal/tangent mapping. |
| Assets/Art/Shaders/SF_Base.shadergraph | bc4aa57b1388 | HDLitSubTarget | 50 / 16 | 已生成，源资源/画面待验证 |
| Assets/Art/Shaders/SF_BaseDecal_02.shadergraph | aa6ad0c9a158 | DecalSubTarget | 34 / 10 | 阻塞：No equivalent ASE template adapter for DecalSubTarget; model not downgraded. |
| Assets/Art/Shaders/SF_BaseMasked.shadergraph | 8cb1136f317e | HDLitSubTarget | 47 / 15 | 已生成，源资源/画面待验证 |
| Assets/Art/Shaders/SF_BaseMaskedTranslucent.shadergraph | 98503c7606a4 | HDLitSubTarget | 48 / 15 | 已生成，源资源/画面待验证 |
| Assets/Art/Shaders/SF_BaseRMA.shadergraph | 80d30ee004da | HDLitSubTarget | 52 / 16 | 阻塞：Unadapted built-in feature m_AddPrecomputedVelocity |
| Assets/Art/Shaders/SF_Base_VertexPaint.shadergraph | 4a617f9c3b5d | HDLitSubTarget | 77 / 19 | 已生成，源资源/画面待验证 |
| Assets/Art/Shaders/SF_Water.shadergraph | cd6782ca55f2 | HDLitSubTarget | 52 / 11 | 阻塞：Native semantic adapter not implemented for SceneDepthNode |
| Assets/Mimic/Materials/Shaders/Triplanar Normal Displacement.shadergraph | 32f21be1a796 | BuiltInLitSubTarget  /  HDLitSubTarget  /  UniversalLitSubTarget | 28 / 8 | 阻塞：Connected vertex stage VertexDescription.Position needs reviewed absolute/relative and normal/tangent mapping. |
| Assets/Mimic/Materials/Shaders/Unlit Shadow.shadergraph | e604d2baf899 | BuiltInUnlitSubTarget  /  HDLitSubTarget  /  UniversalLitSubTarget | 12 / 1 | 已生成，源资源/画面待验证 |
| Assets/Art/Shaders/Anisotropy Graph.shadergraph | b324576552cc | HDLitSubTarget | 73 / 23 | 阻塞：Missing transparent feature m_TransparentWritesMotionVec |
| Assets/Art/Shaders/Dissolve.shadergraph | 5ec99312e0fb | HDLitSubTarget | 68 / 17 | 阻塞：Native semantic adapter not implemented for TriplanarNode |
| Assets/Art/Shaders/Girl_Hair.shadergraph | 8b2f70979b9e | HairSubTarget | 62 / 24 | 已生成，源资源/画面待验证 |
| Assets/ShaderLibrary/Skin.shadergraph | 4da2ac361cb6 | StackLitSubTarget | 82 / 29 | 阻塞：No equivalent ASE template adapter for StackLitSubTarget; model not downgraded. |
| Assets/ShaderLibrary/CarPaint.shadergraph | 29221741da5b | StackLitSubTarget | 50 / 21 | 阻塞：No equivalent ASE template adapter for StackLitSubTarget; model not downgraded. |
| Assets/ShaderLibrary/Hologram.shadergraph | 3cf4ee4b1500 | HDLitSubTarget | 34 / 10 | 阻塞：Implicit bound Fresnel normal/view slots need explicit coordinate-space adapters. |
| Assets/ShaderLibrary/Eye.shadergraph | 1e59d2455441 | HDLitSubTarget | 219 / 22 | 已生成，源资源/画面待验证 |
| Assets/ShaderLibrary/Anisotropy_S.shadergraph | 2cd75307e9fc | HDLitSubTarget | 71 / 23 | 阻塞：Missing transparent feature m_TransparentWritesMotionVec |
| Assets/ShaderLibrary/Rain_Decal.ShaderGraph | 058a25826913 | DecalSubTarget | 47 / 11 | 阻塞：No equivalent ASE template adapter for DecalSubTarget; model not downgraded. |
| Assets/Art/Shaders/HDRP_Add_CG.shadergraph | e35193c477f9 | LegacyNestedJson | 84 / 15 | 阻塞：Legacy master-node graph needs version migration and a model adapter. |
| Assets/Art/Shaders/HDRP_Blend_CG.shadergraph | 0059e06fb2ed | LegacyNestedJson | 85 / 16 | 阻塞：Legacy master-node graph needs version migration and a model adapter. |
| Assets/Art/Shaders/ParticleLit.shadergraph | d845301879ae | LegacyNestedJson | 4 / 1 | 阻塞：Legacy master-node graph needs version migration and a model adapter. |
| Assets/Art/Shaders/ParticleLitCameraFading.shadergraph | 58c36e7ec171 | LegacyNestedJson | 7 / 2 | 阻塞：Legacy master-node graph needs version migration and a model adapter. |
| Assets/Art/Shaders/ParticleLitDistortion.shadergraph | 9ab8b6e11f1b | LegacyNestedJson | 10 / 4 | 阻塞：Legacy master-node graph needs version migration and a model adapter. |
| Assets/Art/Shaders/ParticleLitFlipbook.shadergraph | 8684f99cfaed | LegacyNestedJson | 4 / 1 | 阻塞：Legacy master-node graph needs version migration and a model adapter. |
| Assets/Art/Shaders/ParticleLitFlipbookCameraFading.shadergraph | c6dbe4d65333 | LegacyNestedJson | 7 / 2 | 阻塞：Legacy master-node graph needs version migration and a model adapter. |
| Assets/Art/Shaders/ParticleLitSoft.shadergraph | e8196e66abb1 | LegacyNestedJson | 7 / 2 | 阻塞：Legacy master-node graph needs version migration and a model adapter. |
| Assets/Art/Shaders/ParticleUnlit.shadergraph | 8d2698c29a66 | LegacyNestedJson | 4 / 1 | 阻塞：Legacy master-node graph needs version migration and a model adapter. |
| Assets/Art/Shaders/ParticleUnlitCameraFading.shadergraph | c554dc4e3c32 | LegacyNestedJson | 7 / 2 | 阻塞：Legacy master-node graph needs version migration and a model adapter. |
| Assets/Art/Shaders/ParticleUnlitDistortion.shadergraph | 4f39acd113ec | LegacyNestedJson | 10 / 4 | 阻塞：Legacy master-node graph needs version migration and a model adapter. |
| Assets/Art/Shaders/ParticleUnlitFlipbook.shadergraph | bf7aa3a8765c | LegacyNestedJson | 4 / 1 | 阻塞：Legacy master-node graph needs version migration and a model adapter. |
| Assets/Art/Shaders/ParticleUnlitFlipbookCameraFading.shadergraph | 39b1e16e4e39 | LegacyNestedJson | 7 / 2 | 阻塞：Legacy master-node graph needs version migration and a model adapter. |
| Assets/Art/Shaders/ParticleUnlitSoft.shadergraph | 2a399092c104 | LegacyNestedJson | 7 / 2 | 阻塞：Legacy master-node graph needs version migration and a model adapter. |
| Assets/FantasyGolemPack/Material/Shader/Shader_Golem_Basic.shadergraph | 1ddc5d05b394 | HDLitSubTarget | 28 / 8 | 已生成，源资源/画面待验证 |
| Assets/Game_Art/ShaderGraph/Bark_Wind.shadergraph | d50a228fd4f1 | HDLitSubTarget | 109 / 25 | 阻塞：Keyword definitions and branches have not been mapped. |
| Assets/Game_Art/ShaderGraph/Lava.shadergraph | fa96790a898f | HDLitSubTarget | 108 / 27 | 阻塞：Native semantic adapter not implemented for RemapNode |
| Assets/Game_Art/ShaderGraph/Leaves_Wind.shadergraph | dcff7223c248 | HDLitSubTarget | 112 / 25 | 阻塞：Keyword definitions and branches have not been mapped. |
| Assets/ShaderGraph/Beach FoamMask.shadergraph | b0670d87c9ba | CustomTextureSubTarget | 20 / 0 | 阻塞：This adapter requires an explicit HDRP active target. |
| Assets/ShaderGraph/Rock Foam.shadergraph | 297031a7e0f0 | CustomTextureSubTarget | 22 / 0 | 阻塞：This adapter requires an explicit HDRP active target. |
| Assets/ShaderGraph/WaveFoam_BC.shadergraph | 2e3dbc3a6a2f | CustomTextureSubTarget | 49 / 1 | 阻塞：This adapter requires an explicit HDRP active target. |
| Assets/ShaderGraph/WaveFoam_Deformer.shadergraph | b32b78271200 | CustomTextureSubTarget | 59 / 0 | 阻塞：This adapter requires an explicit HDRP active target. |
| Assets/ShaderGraph/WaveFoam_N.shadergraph | 87585b0da344 | CustomTextureSubTarget | 30 / 0 | 阻塞：This adapter requires an explicit HDRP active target. |
| Assets/ShaderGraph/WaveFoam_S.shadergraph | e34331e9e930 | CustomTextureSubTarget | 42 / 0 | 阻塞：This adapter requires an explicit HDRP active target. |
| Assets/Shader/Unity Shader Graph/LitBasicGraph_Snow.ShaderGraph | e36b2a153e51 | HDLitSubTarget | 68 / 19 | 阻塞：Unadapted system feature m_DOTSInstancing |
| Assets/Shader/Unity Shader Graph/Snow (Particles).shadergraph | 6573b9d35a57 | HDLitSubTarget | 26 / 4 | 阻塞：Non-alpha transparent blend requires reviewed target mapping. |
| Spatial_project/Assets/Art/Shaders/Unity Shader Graph/Bark_Wind.shadergraph | 83893de6a18e | HDLitSubTarget | 125 / 29 | 阻塞：Keyword definitions and branches have not been mapped. |
| Spatial_project/Assets/Art/Shaders/Unity Shader Graph/Leaves_Wind.shadergraph | f9b6d4acf99d | HDLitSubTarget | 127 / 31 | 阻塞：Keyword definitions and branches have not been mapped. |
| Spatial_project/Assets/Art/Shaders/Unity Shader Graph/LitBasicGraph.ShaderGraph | 5316682e2baa | HDLitSubTarget | 53 / 18 | 阻塞：Unadapted system feature m_DOTSInstancing |
| Spatial_project/Assets/Art/Shaders/Unity Shader Graph/LitBasicGraph_NormalOS.ShaderGraph | fef503afea36 | HDLitSubTarget | 54 / 18 | 阻塞：Unadapted system feature m_DOTSInstancing |
| Spatial_project/Assets/Art/Shaders/Unity Shader Graph/Planet.ShaderGraph | ae45c36ed110 | LegacyNestedJson | 72 / 10 | 阻塞：Legacy master-node graph needs version migration and a model adapter. |
| Assets/Shader/Dissolve.shadergraph | bdf79f18db6b | HDLitSubTarget | 129 / 44 | 阻塞：Keyword definitions and branches have not been mapped. |
| Assets/Game_art/Volumetric Samples/Fog Volume Shadergraph/Foggy Orb.shadergraph | cf5dd0fd77d4 | FogVolumeSubTarget | 40 / 10 | 阻塞：No equivalent ASE template adapter for FogVolumeSubTarget; model not downgraded. |
| Assets/Game_art/Volumetric Samples/Fog Volume Shadergraph/Fumes.shadergraph | bcd0a959d6d8 | FogVolumeSubTarget | 49 / 11 | 阻塞：No equivalent ASE template adapter for FogVolumeSubTarget; model not downgraded. |
| Assets/Game_art/Volumetric Samples/Fog Volume Shadergraph/Ground Smoke.shadergraph | 5d3cba7c8608 | FogVolumeSubTarget | 55 / 11 | 阻塞：No equivalent ASE template adapter for FogVolumeSubTarget; model not downgraded. |
| Assets/Game_art/Volumetric Samples/Fog Volume Shadergraph/ProceduralNoiseShowcase.shadergraph | 66f6c056e2e7 | FogVolumeSubTarget | 16 / 5 | 阻塞：Keyword definitions and branches have not been mapped. |
| Assets/Game_art/Volumetric Samples/Fog Volume Shadergraph/Volumetric Heart.shadergraph | c9aef46148c5 | FogVolumeSubTarget | 36 / 6 | 阻塞：No equivalent ASE template adapter for FogVolumeSubTarget; model not downgraded. |
| Assets/ShaderLibrary/Fabric.ShaderGraph | aaace4303347 | FabricSubTarget | 68 / 21 | 已生成，源资源/画面待验证 |
| Assets/ShaderLibrary/Fabric_Curtains.ShaderGraph | 0ff24413881c | HDLitSubTarget | 53 / 16 | 阻塞：Non-default transparent rendering pass requires review. |
| Assets/ShaderLibrary/Fabric_Detail.ShaderGraph | 359f4dbeee14 | FabricSubTarget | 79 / 23 | 阻塞：Baked GI override outputs need a dedicated mapping. |
| Assets/ShaderLibrary/Fabric_Rim_Detail_POM.ShaderGraph | db83e8cab821 | FabricSubTarget | 62 / 21 | 阻塞：Native semantic adapter not implemented for ParallaxOcclusionMappingNode |
| Assets/ShaderLibrary/Vegetation.ShaderGraph | 72c6c58db9fb | HDLitSubTarget | 98 / 25 | 阻塞：Coat/ray-tracing/refraction material extension requires a dedicated adapter. |
| Assets/ShaderLibrary/VideoPlayer.shadergraph | c87b4e0e2511 | HDLitSubTarget | 22 / 7 | 阻塞：Coat/ray-tracing/refraction material extension requires a dedicated adapter. |

## 已生成图的输入、输出与状态

属性引用名、纹理默认白/黑/法线类型与 NoScaleOffset 声明保留。纹理 GUID 只是原工程依赖身份，没有把原始贴图打包进插件。SSS 还需正确的 Diffusion Profile 和 HDRP 帧设置；毛发需要实际网格/发丝宿主数据。源中已禁用的部分端口在适配图中保留为断开原生分支，下面单独列出。

需要按源材质恢复材质开关和数值。模板 Alpha Clipping=Material Toggle 时，新建材质仍需启用 Alpha Clipping / Shadow Threshold 等开关；图端口存在不能当作源材质关键词已初始化。当前库提供 Shader，不携带原项目材质实例。

### SF_Base · 0b09e8a8e8b4

原路径：`Assets/Scans Factory/GateBackyard/Shaders/SF_Base.shadergraph`。源模型：`HDLitSubTarget`；源节点 42，属性 13。

ASE 活动输出：`Base Color`、`Normal`、`Metallic`、`Emission`、`Smoothness`、`Occlusion`、`Alpha`。

模板状态：Surface Type=Opaque；Double-Sided=Disabled；Alpha Clipping=Force Off；  Use Shadow Threshold=Force Off；Material Type=Standard；  Energy Conserving Specular=true；Receive Decals=Material Toggle；Receive SSR=true；Specular Occlusion Mode=Off。

功能阶段：02 原生运算与采样 · 阶段 1 → 01 原图属性与资源 · 阶段 1。

源属性：`_BaseColorMap`、`_NormalMap`、`Smoothness`、`Color_B058D3E1`、`Vector1_2E02C893`、`Vector1_99C632AB`、`Vector1_60757AD5`、`Boolean_8DF6575E`、`Boolean_8D2075D0`、`Vector1_19174781`、`Vector1_5DE2A733`、`Vector1_5E4C65CA`、`Vector1_31C5A0D2`。

需重绑的默认资源：`_NormalMap` → `07c705c812ce4d74a961f65dc8dbe447`；`Smoothness` → `2205ca0505c13cc4b993bd8c9ada4050`。

### SF_BaseTransparentGlass · 044b7612c112

原路径：`Assets/Art/Shaders/SF_BaseTransparentGlass.shadergraph`。源模型：`HDLitSubTarget`；源节点 48，属性 16。

ASE 活动输出：`Base Color`、`Normal`、`Emission`、`Smoothness`、`Occlusion`、`Alpha`、`Metallic`。

模板状态：Surface Type=Transparent；  Back Then Front Rendering=false；  Transparent Depth Prepass=false；  Transparent Depth Postpass=false；  ZWrite=false；  Z Test=Less Equal；Double-Sided=Enabled；Alpha Clipping=Force Off；  Use Shadow Threshold=Force Off；Material Type=Standard；  Energy Conserving Specular=true；    Blend Preserves Specular=true；Receive Decals=Material Toggle；Receive SSR=true；Specular Occlusion Mode=Off。

功能阶段：02 原生运算与采样 · 阶段 1 → 01 原图属性与资源 · 阶段 1。

源属性：`_BaseColorMap`、`_NormalMap`、`Smoothness`、`Color_B058D3E1`、`Vector1_2E02C893`、`Vector1_99C632AB`、`Vector1_60757AD5`、`Boolean_8DF6575E`、`Boolean_8D2075D0`、`Vector1_19174781`、`Vector1_5DE2A733`、`Vector1_5E4C65CA`、`Vector1_31C5A0D2`、`_Translucency`、`_TranclucentContrast`、`_TranclucentBrightness`。

需重绑的默认资源：`_NormalMap` → `07c705c812ce4d74a961f65dc8dbe447`；`Smoothness` → `2205ca0505c13cc4b993bd8c9ada4050`。

### SF_Pipe_01 · 2a377100bd62

原路径：`Assets/Scans Factory/GateBackyard/Shaders/SF_Pipe_01.shadergraph`。源模型：`HDLitSubTarget`；源节点 18，属性 1。

ASE 活动输出：`Base Color`、`Normal`、`Metallic`、`Emission`、`Smoothness`、`Occlusion`、`Alpha`、`Alpha Clip Threshold`。

模板状态：Surface Type=Opaque；Double-Sided=Disabled；Alpha Clipping=Material Toggle；  Use Shadow Threshold=Force Off；Material Type=Standard；  Energy Conserving Specular=true；Receive Decals=Material Toggle；Receive SSR=true；Specular Occlusion Mode=Off。

功能阶段：02 原生运算与采样 · 阶段 1 → 01 原图属性与资源 · 阶段 1。

源属性：`_BaseColorMap`。

没有记录到图默认纹理 GUID；这不代表源材质无需纹理，材质实例的资源仍须手动绑定。

### Girl_Hair · 5f1acba57c6f

原路径：`Assets/Shader/Girl_Hair.shadergraph`。源模型：`HairSubTarget`；源节点 62，属性 24。

ASE 活动输出：`Base Color`、`Normal`、`Hair Strand Direction`、`Transmittance`、`Rim Transmission Intensity`、`Smoothness`、`Occlusion`、`Alpha`、`Alpha Clip Threshold`、`Alpha Clip Threshold Depth Postpass`、`Specular Tint`、`Specular Shift`、`Secondary Specular Tint`、`Secondary Smoothness`、`Secondary Specular Shift`、`Depth Offset`、`Emission`、`Alpha Clip Threshold Shadow`。

模板状态：Surface Type=Transparent；  Back Then Front Rendering=false；  Transparent Depth Prepass=false；  Transparent Depth Postpass=true；  Transparent Writes Motion Vectors=false；  Depth Write=true；  Depth Test=Less Equal；Double-Sided=Mirrored Normals；Alpha Clipping=Material Toggle；  Use Shadow Threshold=Material Toggle；Material Type=Approximate；Geometry Type=Strands；  Scattering Mode=Approximate；  Preserve Specular Lighting=false；Receive Decals=false；Receive SSR=false；Specular Occlusion Mode=From AO；Depth Offset=true。

功能阶段：原图功能区 · Apply Vertex Color + Tint · 阶段 1 → 原图功能区 · Base Maps · 阶段 1 → 原图功能区 · Apply Vertex Color + Tint · 阶段 2 → 原图功能区 · Base Maps · 阶段 2 → 原图功能区 · UV_Tiling · 阶段 1 → 02 原生运算与采样 · 阶段 3 → 02 原生运算与采样 · 阶段 1 → 原图功能区 · Rim · 阶段 1 → 原图功能区 · Rim · 阶段 4 → 02 原生运算与采样 · 阶段 5 → 原图功能区 · Strands · 阶段 1 → 原图功能区 · Transmittance · 阶段 1 → 原图功能区 · Transmittance · 阶段 3 → 原图功能区 · Primary Specular · 阶段 1 → 原图功能区 · Mask Maps · 阶段 1 → 01 原图属性与资源 · 阶段 1 → 原图功能区 · Secondary Specular · 阶段 1。

源属性：`Texture2D_117EA600`、`Color_52EF55BA`、`Texture2D_40B90743`、`Texture2D_A7A7608F`、`Vector3_F569DE10`、`Vector1_D16DBCEB`、`Vector1_BB81CAD1`、`Vector1_E7158B77`、`Color_1C5A1173`、`Vector1_405E5753`、`Vector1_DD882285`、`Color_CF1227FA`、`Vector1_DBA3A12F`、`Vector1_3B29C969`、`Color_E6DB92F6`、`Vector1_41F43B0E`、`Vector1_7322D21`、`Boolean_98BB4CFB`、`Vector1_1988C34`、`Vector1_AB8257D1`、`Vector1_A5DC34DE`、`Vector1_0af3b6d2a9624d9989497d3204108514`、`Color_ecfcc6c3231043c98de37a71b076e50c`、`Vector1_01a1b992598247a5a800180fa8691f3a`。

没有记录到图默认纹理 GUID；这不代表源材质无需纹理，材质实例的资源仍须手动绑定。

### Unlit_Graph · 91b14ee430f3

原路径：`Assets/Art/Shaders/Unlit_Graph.shadergraph`。源模型：`HDUnlitSubTarget`；源节点 9，属性 3。

ASE 活动输出：`Color`、`Alpha`、`Alpha Clip Threshold`。

模板状态：Surface Type=Transparent；  Depth Write=false；  Depth Test=Less Equal；  Blending Mode=Alpha；  Receive Fog=true；Double-Sided=false；Alpha Clipping=Material Toggle；  Use Shadow Threshold=Force Off。

功能阶段：02 原生运算与采样 · 阶段 1。

源属性：`Color_AAB12E35`、`Vector1_E7596DB`、`Vector1_BFDF7C4A`。

没有记录到图默认纹理 GUID；这不代表源材质无需纹理，材质实例的资源仍须手动绑定。

### Fabric_Trans · efb1bec0bd9d

原路径：`Assets/Game_art/Shader/Fabric_Trans.ShaderGraph`。源模型：`FabricSubTarget`；源节点 69，属性 21。

ASE 活动输出：`Base Color`、`Normal`、`Smoothness`、`Occlusion`、`Specular`、`Emission`、`Alpha`、`Thickness`。

模板状态：Surface Type=Opaque；Double-Sided=Enabled；Alpha Clipping=Force Off；  Use Shadow Threshold=Force Off；Material Type=Cotton Wool；Transmission=true；  Subsurface Scattering=false；Energy Conserving Specular=true；Receive Decals=false；Receives SSR=false；Specular Occlusion Mode=From AO。

功能阶段：02 原生运算与采样 · 阶段 1 → 01 原图属性与资源 · 阶段 1。

源属性：`Vector1_4784DC7`、`Color_512C93D4`、`Texture2D_2D0D32F9`、`AlbedoNoisePower`、`Texture2D_1C6F9DC8`、`Vector1_CC012422`、`Vector1_430999C3`、`Vector1_E6267AA5`、`Texture2D_C4AB2143`、`Vector1_4548C0F8`、`Vector1_18BBE2E1`、`Color_A43A3DFB`、`Vector1_BD133B8D`、`Texture2D_26D18CAA`、`Vector1_CB152CD2`、`AlbedoDetail`、`Texture2D_D3552121`、`Vector1_5514B0AB`、`Texture2D_C388EAF4`、`Vector1_54B720F6`、`Thickness`。

没有记录到图默认纹理 GUID；这不代表源材质无需纹理，材质实例的资源仍须手动绑定。

### RGB · 18acaa20c040

原路径：`Assets/Game_art/Shader/RGB.shadergraph`。源模型：`HDLitSubTarget`；源节点 37，属性 10。

ASE 活动输出：`Base Color`、`Normal`、`Metallic`、`Emission`、`Smoothness`、`Occlusion`、`Alpha`。

模板状态：Surface Type=Opaque；Double-Sided=Disabled；Alpha Clipping=Force Off；  Use Shadow Threshold=Force Off；Material Type=Standard；  Energy Conserving Specular=true；Receive Decals=Material Toggle；Receive SSR=true；Specular Occlusion Mode=Off。

功能阶段：02 原生运算与采样 · 阶段 1 → 01 原图属性与资源 · 阶段 1。

源属性：`Texture2D_70A1ED03`、`Texture2D_9AA06F06`、`Texture2D_3CEB49AA`、`Texture2D_295F699D`、`Texture2D_EFCE13EC`、`Vector1_D7EEB1EB`、`Texture2D_459718CA`、`Vector1_E48F0360`、`Vector1_1D31CB2E`、`Vector1_C81EA580`。

没有记录到图默认纹理 GUID；这不代表源材质无需纹理，材质实例的资源仍须手动绑定。

### Eye · b22f3d64654c

原路径：`Girl_project(1)/Assets/ShaderLibrary/Eye.shadergraph`。源模型：`HDLitSubTarget`；源节点 194，属性 22。

ASE 活动输出：`Base Color`、`Normal`、`Emission`、`Smoothness`、`Occlusion`、`Alpha`、`Alpha Clip Threshold`、`Thickness`、`Diffusion Profile`、`Subsurface Mask`。

模板状态：Surface Type=Opaque；Double-Sided=Disabled；Alpha Clipping=Material Toggle；  Use Shadow Threshold=Force Off；Material Type=Subsurface Scattering；  Energy Conserving Specular=false；  Transmission=true；Receive Decals=Force Off；Receive SSR=true；Specular Occlusion Mode=Off。

功能阶段：02 原生运算与采样 · 阶段 1 → 原图功能区 · Sclera Shadow · 阶段 1 → 02 原生运算与采样 · 阶段 2 → 02 原生运算与采样 · 阶段 3 → 原图功能区 · Parallax Calculation · 阶段 2 → 原图功能区 · Parallax Calculation · 阶段 1 → 原图功能区 · Iris Shadow · 阶段 1 → 原图功能区 · Iris Shadow · 阶段 4 → 02 原生运算与采样 · 阶段 5 → 原图功能区 · Limbal Ring · 阶段 1 → 原图功能区 · Limbal Ring · 阶段 6 → 原图功能区 · Limbal Ring · 阶段 2 → 原图功能区 · Limbal Ring · 阶段 5 → 原图功能区 · Parallax Calculation B · 阶段 4 → 原图功能区 · Parallax Calculation B · 阶段 1 → 原图功能区 · Parallax Calculation B · 阶段 2 → 原图功能区 · Overall Brightness · 阶段 1 → 原图功能区 · Overall Brightness · 阶段 7 → 02 原生运算与采样 · 阶段 8 → 原图功能区 · Smoothness Calculation · 阶段 1 → 原图功能区 · Smoothness Calculation · 阶段 2 → 01 原图属性与资源 · 阶段 1。

源属性：`_scleraColor`、`_irisColor`、`_illumColor`、`_pupilSize`、`_irisSize`、`_parallax`、`_scleraSize`、`_limbus`、`_specsize`、`_smoothness`、`_reflectTerm`、`_brightShift`、`_scleraShadowAmt`、`_irisShadowAmt`、`_IrisColorTex`、`_IrisTex`、`_CorneaBump`、`_EyeBump`、`_IrisBump`、`_MainTex`、`_ShadeScleraTex`、`_ShadeIrisTex`。

需重绑的默认资源：`_MainTex` → `4f47073b006bcef44bc62e532cafc4fb`；`_ShadeScleraTex` → `4a04cda9fb11e7245b2e2b6ed221e008`；`_IrisColorTex` → `6dee9e1c6726c9a4fb3b487598969152`；`_IrisTex` → `d6f59e45d58f66344811c1af0bf412a2`；`_ShadeIrisTex` → `b444eddaee4f4e84b82d5448a713adc1`；`_EyeBump` → `81b3acbd0c61e354bb574c92d8fb9da0`；`_CorneaBump` → `fb64935e844038c40a4780f4ef1a7693`；`_IrisBump` → `778e5c3fd9fd91c43821754495d8bf1b`。

### Girl_Hair · bf1acc8b5350

原路径：`Assets/ShaderLibrary/Girl_Hair.shadergraph`。源模型：`HairSubTarget`；源节点 62，属性 24。

ASE 活动输出：`Base Color`、`Normal`、`Hair Strand Direction`、`Transmittance`、`Rim Transmission Intensity`、`Smoothness`、`Occlusion`、`Alpha`、`Alpha Clip Threshold`、`Alpha Clip Threshold Depth Postpass`、`Specular Tint`、`Specular Shift`、`Secondary Specular Tint`、`Secondary Smoothness`、`Secondary Specular Shift`、`Depth Offset`、`Emission`、`Alpha Clip Threshold Shadow`。

模板状态：Surface Type=Transparent；  Back Then Front Rendering=false；  Transparent Depth Prepass=false；  Transparent Depth Postpass=true；  Transparent Writes Motion Vectors=false；  Depth Write=true；  Depth Test=Less Equal；Double-Sided=Mirrored Normals；Alpha Clipping=Material Toggle；  Use Shadow Threshold=Material Toggle；Material Type=Approximate；Geometry Type=Strands；  Scattering Mode=Approximate；  Preserve Specular Lighting=false；Receive Decals=false；Receive SSR=false；Specular Occlusion Mode=From AO；Depth Offset=true。

功能阶段：原图功能区 · Apply Vertex Color + Tint · 阶段 1 → 原图功能区 · Base Maps · 阶段 1 → 原图功能区 · Apply Vertex Color + Tint · 阶段 2 → 原图功能区 · Base Maps · 阶段 2 → 原图功能区 · UV_Tiling · 阶段 1 → 02 原生运算与采样 · 阶段 3 → 02 原生运算与采样 · 阶段 1 → 原图功能区 · Rim · 阶段 1 → 原图功能区 · Rim · 阶段 4 → 02 原生运算与采样 · 阶段 5 → 原图功能区 · Strands · 阶段 1 → 原图功能区 · Transmittance · 阶段 1 → 原图功能区 · Transmittance · 阶段 3 → 原图功能区 · Primary Specular · 阶段 1 → 原图功能区 · Mask Maps · 阶段 1 → 01 原图属性与资源 · 阶段 1 → 原图功能区 · Secondary Specular · 阶段 1。

源属性：`Texture2D_117EA600`、`Color_52EF55BA`、`Texture2D_40B90743`、`Texture2D_A7A7608F`、`Vector3_F569DE10`、`Vector1_D16DBCEB`、`Vector1_BB81CAD1`、`Vector1_E7158B77`、`Color_1C5A1173`、`Vector1_405E5753`、`Vector1_DD882285`、`Color_CF1227FA`、`Vector1_DBA3A12F`、`Vector1_3B29C969`、`Color_E6DB92F6`、`Vector1_41F43B0E`、`Vector1_7322D21`、`Boolean_98BB4CFB`、`Vector1_1988C34`、`Vector1_AB8257D1`、`Vector1_A5DC34DE`、`Vector1_0af3b6d2a9624d9989497d3204108514`、`Color_ecfcc6c3231043c98de37a71b076e50c`、`Vector1_01a1b992598247a5a800180fa8691f3a`。

没有记录到图默认纹理 GUID；这不代表源材质无需纹理，材质实例的资源仍须手动绑定。

### SRP · 4e9932aa7d81

原路径：`Assets/_Packages/com.unity.demoteam.hair/Samples~/HairSample/Materials/SRP.shadergraph`。源模型：`HDLitSubTarget | UniversalLitSubTarget`；源节点 13，属性 2。

ASE 活动输出：`Base Color`、`Normal`、`Metallic`、`Emission`、`Smoothness`、`Occlusion`、`Alpha`。

模板状态：Surface Type=Opaque；Double-Sided=Disabled；Alpha Clipping=Force Off；  Use Shadow Threshold=Force Off；Material Type=Standard；  Energy Conserving Specular=true；Receive Decals=Material Toggle；Receive SSR=true；Specular Occlusion Mode=Off。

功能阶段：02 原生运算与采样 · 阶段 1 → 01 原图属性与资源 · 阶段 1。

源属性：`Color_020ef9a5ab8249da91e6a350af13f799`、`Vector1_aa16d99ab74643eda4ab5ea1fd910540`。

没有记录到图默认纹理 GUID；这不代表源材质无需纹理，材质实例的资源仍须手动绑定。

### Eye · 6dec954b5a2e

原路径：`Assets/Shaders/ShaderLibrary/Eye.shadergraph`。源模型：`HDLitSubTarget`；源节点 219，属性 22。

ASE 活动输出：`Base Color`、`Normal`、`Emission`、`Smoothness`、`Occlusion`、`Alpha`、`Alpha Clip Threshold`、`Subsurface Mask`、`Thickness`、`Diffusion Profile`。

模板状态：Surface Type=Opaque；Double-Sided=Disabled；Alpha Clipping=Material Toggle；  Use Shadow Threshold=Force Off；Material Type=Subsurface Scattering；  Energy Conserving Specular=false；  Transmission=true；Receive Decals=Force Off；Receive SSR=true；Specular Occlusion Mode=Off。

功能阶段：02 原生运算与采样 · 阶段 1 → 原图功能区 · Sclera Shadow · 阶段 1 → 02 原生运算与采样 · 阶段 2 → 02 原生运算与采样 · 阶段 3 → 原图功能区 · Parallax Calculation · 阶段 2 → 原图功能区 · Parallax Calculation · 阶段 1 → 原图功能区 · Iris Shadow · 阶段 1 → 原图功能区 · Iris Shadow · 阶段 4 → 02 原生运算与采样 · 阶段 5 → 原图功能区 · Limbal Ring · 阶段 1 → 原图功能区 · Limbal Ring · 阶段 6 → 原图功能区 · Limbal Ring · 阶段 2 → 原图功能区 · Limbal Ring · 阶段 5 → 原图功能区 · Parallax Calculation B · 阶段 4 → 原图功能区 · Parallax Calculation B · 阶段 1 → 原图功能区 · Parallax Calculation B · 阶段 2 → 原图功能区 · Overall Brightness · 阶段 1 → 原图功能区 · Overall Brightness · 阶段 7 → 02 原生运算与采样 · 阶段 8 → 原图功能区 · Specular Calculation · 阶段 1 → 原图功能区 · Specular Calculation · 阶段 2 → 原图功能区 · Smoothness Calculation · 阶段 1 → 原图功能区 · Smoothness Calculation · 阶段 2 → 01 原图属性与资源 · 阶段 1。

源属性：`_scleraColor`、`_irisColor`、`_illumColor`、`_pupilSize`、`_irisSize`、`_parallax`、`_scleraSize`、`_limbus`、`_specsize`、`_smoothness`、`_reflectTerm`、`_brightShift`、`_scleraShadowAmt`、`_irisShadowAmt`、`_IrisColorTex`、`_IrisTex`、`_CorneaBump`、`_EyeBump`、`_IrisBump`、`_MainTex`、`_ShadeScleraTex`、`_ShadeIrisTex`。

没有记录到图默认纹理 GUID；这不代表源材质无需纹理，材质实例的资源仍须手动绑定。

源中禁用、保留断开计算的输出：`SurfaceDescription.Specular`。

### SF_Base · bc4aa57b1388

原路径：`Assets/Art/Shaders/SF_Base.shadergraph`。源模型：`HDLitSubTarget`；源节点 50，属性 16。

ASE 活动输出：`Base Color`、`Normal`、`Metallic`、`Emission`、`Smoothness`、`Occlusion`、`Alpha`。

模板状态：Surface Type=Opaque；Double-Sided=Disabled；Alpha Clipping=Force Off；  Use Shadow Threshold=Force Off；Material Type=Standard；  Energy Conserving Specular=true；Receive Decals=Material Toggle；Receive SSR=true；Specular Occlusion Mode=Off。

功能阶段：02 原生运算与采样 · 阶段 1 → 01 原图属性与资源 · 阶段 1。

源属性：`_BaseColorMap`、`_DetailNormalMap`、`_NormalMap`、`_AlbedoColorMask`、`Smoothness`、`Color_B058D3E1`、`Vector1_2E02C893`、`Vector1_99C632AB`、`Vector1_60757AD5`、`Boolean_8DF6575E`、`Boolean_8D2075D0`、`Vector1_19174781`、`Vector1_5DE2A733`、`Vector1_5E4C65CA`、`_DetailNormalStrenght`、`Vector1_31C5A0D2`。

需重绑的默认资源：`_AlbedoColorMask` → `2205ca0505c13cc4b993bd8c9ada4050`；`_NormalMap` → `07c705c812ce4d74a961f65dc8dbe447`；`_DetailNormalMap` → `abc00000000005661724113764724317`；`Smoothness` → `2205ca0505c13cc4b993bd8c9ada4050`。

### SF_BaseMasked · 8cb1136f317e

原路径：`Assets/Art/Shaders/SF_BaseMasked.shadergraph`。源模型：`HDLitSubTarget`；源节点 47，属性 15。

ASE 活动输出：`Base Color`、`Normal`、`Emission`、`Smoothness`、`Occlusion`、`Alpha`、`Alpha Clip Threshold`、`Metallic`。

模板状态：Surface Type=Transparent；  Back Then Front Rendering=false；  Transparent Depth Prepass=false；  Transparent Depth Postpass=false；  ZWrite=false；  Z Test=Less Equal；Double-Sided=Enabled；Alpha Clipping=Material Toggle；  Use Shadow Threshold=Force Off；Material Type=Standard；  Energy Conserving Specular=true；    Blend Preserves Specular=true；Receive Decals=Material Toggle；Receive SSR=true；Specular Occlusion Mode=Off。

功能阶段：02 原生运算与采样 · 阶段 1 → 01 原图属性与资源 · 阶段 1。

源属性：`_BaseColorMap`、`_NormalMap`、`_Mask`、`Smoothness`、`Color_B058D3E1`、`Vector1_2E02C893`、`Vector1_99C632AB`、`Vector1_60757AD5`、`Boolean_8DF6575E`、`_AlphaFromAlbedoMap`、`Boolean_8D2075D0`、`Vector1_19174781`、`Vector1_5DE2A733`、`Vector1_5E4C65CA`、`Vector1_31C5A0D2`。

需重绑的默认资源：`_NormalMap` → `07c705c812ce4d74a961f65dc8dbe447`；`Smoothness` → `2205ca0505c13cc4b993bd8c9ada4050`；`_Mask` → `2205ca0505c13cc4b993bd8c9ada4050`。

### SF_BaseMaskedTranslucent · 98503c7606a4

原路径：`Assets/Art/Shaders/SF_BaseMaskedTranslucent.shadergraph`。源模型：`HDLitSubTarget`；源节点 48，属性 15。

ASE 活动输出：`Base Color`、`Normal`、`Emission`、`Smoothness`、`Occlusion`、`Alpha`、`Alpha Clip Threshold`。

模板状态：Surface Type=Opaque；Double-Sided=Enabled；Alpha Clipping=Material Toggle；  Use Shadow Threshold=Force Off；Material Type=Translucent；  Energy Conserving Specular=true；  Transmission=true；Receive Decals=Material Toggle；Receive SSR=true；Specular Occlusion Mode=Off。

功能阶段：02 原生运算与采样 · 阶段 1 → 01 原图属性与资源 · 阶段 1。

源属性：`_BaseColorMap`、`_NormalMap`、`_Mask`、`Smoothness`、`Color_B058D3E1`、`Vector1_2E02C893`、`Vector1_99C632AB`、`Vector1_60757AD5`、`Boolean_8DF6575E`、`_AlphaFromAlbedo`、`Boolean_8D2075D0`、`Vector1_19174781`、`Vector1_5DE2A733`、`Vector1_5E4C65CA`、`Vector1_31C5A0D2`。

需重绑的默认资源：`_NormalMap` → `07c705c812ce4d74a961f65dc8dbe447`；`Smoothness` → `2205ca0505c13cc4b993bd8c9ada4050`；`_Mask` → `2205ca0505c13cc4b993bd8c9ada4050`。

### SF_Base_VertexPaint · 4a617f9c3b5d

原路径：`Assets/Art/Shaders/SF_Base_VertexPaint.shadergraph`。源模型：`HDLitSubTarget`；源节点 77，属性 19。

ASE 活动输出：`Base Color`、`Normal`、`Metallic`、`Emission`、`Smoothness`、`Occlusion`、`Alpha`。

模板状态：Surface Type=Opaque；Double-Sided=Disabled；Alpha Clipping=Force Off；  Use Shadow Threshold=Force Off；Material Type=Standard；  Energy Conserving Specular=true；Receive Decals=Material Toggle；Receive SSR=true；Specular Occlusion Mode=Off。

功能阶段：02 原生运算与采样 · 阶段 1 → 01 原图属性与资源 · 阶段 1。

源属性：`_BaseColorMap2`、`_BaseColorMap`、`_NormalMap2`、`_DetailNormalMap`、`_NormalMap`、`_Mask`、`_AlbedoColorMask`、`Smoothness`、`Color_B058D3E1`、`Vector1_2E02C893`、`Vector1_99C632AB`、`Vector1_60757AD5`、`Boolean_8DF6575E`、`Boolean_8D2075D0`、`Vector1_19174781`、`Vector1_5DE2A733`、`Vector1_5E4C65CA`、`_Blend_Brigtness`、`_Blend_Contrast`。

需重绑的默认资源：`_AlbedoColorMask` → `2205ca0505c13cc4b993bd8c9ada4050`；`_Mask` → `abc00000000000204514655943510958`；`_NormalMap` → `07c705c812ce4d74a961f65dc8dbe447`；`_DetailNormalMap` → `abc00000000005661724113764724317`；`Smoothness` → `2205ca0505c13cc4b993bd8c9ada4050`；`_NormalMap2` → `07c705c812ce4d74a961f65dc8dbe447`。

### Unlit Shadow · e604d2baf899

原路径：`Assets/Mimic/Materials/Shaders/Unlit Shadow.shadergraph`。源模型：`BuiltInUnlitSubTarget | HDLitSubTarget | UniversalLitSubTarget`；源节点 12，属性 1。

ASE 活动输出：`Base Color`、`Smoothness`、`Normal`、`Emission`、`Occlusion`、`Metallic`、`Alpha`。

模板状态：Surface Type=Opaque；Double-Sided=Disabled；Alpha Clipping=Force Off；  Use Shadow Threshold=Force Off；Material Type=Standard；  Energy Conserving Specular=true；Receive Decals=Material Toggle；Receive SSR=true；Specular Occlusion Mode=From AO。

功能阶段：02 原生运算与采样 · 阶段 1 → 01 原图属性与资源 · 阶段 1。

源属性：`_Color`。

没有记录到图默认纹理 GUID；这不代表源材质无需纹理，材质实例的资源仍须手动绑定。

### Girl_Hair · 8b2f70979b9e

原路径：`Assets/Art/Shaders/Girl_Hair.shadergraph`。源模型：`HairSubTarget`；源节点 62，属性 24。

ASE 活动输出：`Base Color`、`Normal`、`Hair Strand Direction`、`Transmittance`、`Rim Transmission Intensity`、`Smoothness`、`Occlusion`、`Alpha`、`Alpha Clip Threshold`、`Specular Tint`、`Specular Shift`、`Secondary Specular Tint`、`Secondary Smoothness`、`Secondary Specular Shift`、`Depth Offset`、`Emission`、`Alpha Clip Threshold Shadow`。

模板状态：Surface Type=Transparent；  Back Then Front Rendering=false；  Transparent Depth Prepass=false；  Transparent Depth Postpass=false；  Transparent Writes Motion Vectors=false；  Depth Write=true；  Depth Test=Less Equal；Double-Sided=Mirrored Normals；Alpha Clipping=Material Toggle；  Use Shadow Threshold=Material Toggle；Material Type=Approximate；Geometry Type=Card；  Preserve Specular Lighting=false；Receive Decals=false；Receive SSR=false；Specular Occlusion Mode=From AO；Depth Offset=true。

功能阶段：原图功能区 · Apply Vertex Color + Tint · 阶段 1 → 原图功能区 · Base Maps · 阶段 1 → 原图功能区 · Apply Vertex Color + Tint · 阶段 2 → 原图功能区 · Base Maps · 阶段 2 → 原图功能区 · UV_Tiling · 阶段 1 → 02 原生运算与采样 · 阶段 3 → 02 原生运算与采样 · 阶段 1 → 原图功能区 · Rim · 阶段 1 → 原图功能区 · Rim · 阶段 4 → 02 原生运算与采样 · 阶段 5 → 原图功能区 · Strands · 阶段 1 → 原图功能区 · Transmittance · 阶段 1 → 原图功能区 · Transmittance · 阶段 3 → 原图功能区 · Primary Specular · 阶段 1 → 原图功能区 · Mask Maps · 阶段 1 → 01 原图属性与资源 · 阶段 1 → 原图功能区 · Secondary Specular · 阶段 1。

源属性：`Texture2D_117EA600`、`Color_52EF55BA`、`Texture2D_40B90743`、`Texture2D_A7A7608F`、`Vector3_F569DE10`、`Vector1_D16DBCEB`、`Vector1_BB81CAD1`、`Vector1_E7158B77`、`Color_1C5A1173`、`Vector1_405E5753`、`Vector1_DD882285`、`Color_CF1227FA`、`Vector1_DBA3A12F`、`Vector1_3B29C969`、`Color_E6DB92F6`、`Vector1_41F43B0E`、`Vector1_7322D21`、`Boolean_98BB4CFB`、`Vector1_1988C34`、`Vector1_AB8257D1`、`Vector1_A5DC34DE`、`Vector1_0af3b6d2a9624d9989497d3204108514`、`Color_ecfcc6c3231043c98de37a71b076e50c`、`Vector1_01a1b992598247a5a800180fa8691f3a`。

没有记录到图默认纹理 GUID；这不代表源材质无需纹理，材质实例的资源仍须手动绑定。

源中禁用、保留断开计算的输出：`SurfaceDescription.AlphaClipThresholdDepthPostpass`。

### Eye · 1e59d2455441

原路径：`Assets/ShaderLibrary/Eye.shadergraph`。源模型：`HDLitSubTarget`；源节点 219，属性 22。

ASE 活动输出：`Base Color`、`Normal`、`Emission`、`Smoothness`、`Occlusion`、`Alpha`、`Alpha Clip Threshold`、`Subsurface Mask`、`Thickness`、`Diffusion Profile`。

模板状态：Surface Type=Opaque；Double-Sided=Disabled；Alpha Clipping=Material Toggle；  Use Shadow Threshold=Force Off；Material Type=Subsurface Scattering；  Energy Conserving Specular=false；  Transmission=true；Receive Decals=Force Off；Receive SSR=true；Specular Occlusion Mode=Off。

功能阶段：02 原生运算与采样 · 阶段 1 → 原图功能区 · Sclera Shadow · 阶段 1 → 02 原生运算与采样 · 阶段 2 → 02 原生运算与采样 · 阶段 3 → 原图功能区 · Parallax Calculation · 阶段 2 → 原图功能区 · Parallax Calculation · 阶段 1 → 原图功能区 · Iris Shadow · 阶段 1 → 原图功能区 · Iris Shadow · 阶段 4 → 02 原生运算与采样 · 阶段 5 → 原图功能区 · Limbal Ring · 阶段 1 → 原图功能区 · Limbal Ring · 阶段 6 → 原图功能区 · Limbal Ring · 阶段 2 → 原图功能区 · Limbal Ring · 阶段 5 → 原图功能区 · Parallax Calculation B · 阶段 4 → 原图功能区 · Parallax Calculation B · 阶段 1 → 原图功能区 · Parallax Calculation B · 阶段 2 → 原图功能区 · Overall Brightness · 阶段 1 → 原图功能区 · Overall Brightness · 阶段 7 → 02 原生运算与采样 · 阶段 8 → 原图功能区 · Specular Calculation · 阶段 1 → 原图功能区 · Specular Calculation · 阶段 2 → 原图功能区 · Smoothness Calculation · 阶段 1 → 原图功能区 · Smoothness Calculation · 阶段 2 → 01 原图属性与资源 · 阶段 1。

源属性：`_scleraColor`、`_irisColor`、`_illumColor`、`_pupilSize`、`_irisSize`、`_parallax`、`_scleraSize`、`_limbus`、`_specsize`、`_smoothness`、`_reflectTerm`、`_brightShift`、`_scleraShadowAmt`、`_irisShadowAmt`、`_IrisColorTex`、`_IrisTex`、`_CorneaBump`、`_EyeBump`、`_IrisBump`、`_MainTex`、`_ShadeScleraTex`、`_ShadeIrisTex`。

没有记录到图默认纹理 GUID；这不代表源材质无需纹理，材质实例的资源仍须手动绑定。

源中禁用、保留断开计算的输出：`SurfaceDescription.Specular`。

### Shader_Golem_Basic · 1ddc5d05b394

原路径：`Assets/FantasyGolemPack/Material/Shader/Shader_Golem_Basic.shadergraph`。源模型：`HDLitSubTarget`；源节点 28，属性 8。

ASE 活动输出：`Base Color`、`Normal`、`Metallic`、`Smoothness`、`Emission`、`Occlusion`、`Alpha`。

模板状态：Surface Type=Opaque；Double-Sided=Disabled；Alpha Clipping=Force Off；  Use Shadow Threshold=Force Off；Material Type=Standard；  Energy Conserving Specular=true；Receive Decals=Material Toggle；Receive SSR=true；Specular Occlusion Mode=From AO。

功能阶段：02 原生运算与采样 · 阶段 1。

源属性：`Texture2D_2861c5eefa234470bb8464831805711a`、`Texture2D_41e6e251b907435483c56fb17f37530f`、`Color_f3153648de1748e6b69fba15bfe6f3ae`、`Texture2D_a2ac2b2722264dbbb22d33ddfb484893`、`Texture2D_be9a9663d4b24bd3abc330ee3720a2c6`、`Texture2D_c64441735dfa401ca814b0af0ea573de`、`Color_352c0c5aed5245dbab96dc4e0343d3da`、`Texture2D_3ddaa6d9019544859c0eea30f4d9bb4f`。

没有记录到图默认纹理 GUID；这不代表源材质无需纹理，材质实例的资源仍须手动绑定。

### Fabric · aaace4303347

原路径：`Assets/ShaderLibrary/Fabric.ShaderGraph`。源模型：`FabricSubTarget`；源节点 68，属性 21。

ASE 活动输出：`Base Color`、`Normal`、`Smoothness`、`Occlusion`、`Specular`、`Emission`、`Alpha`。

模板状态：Surface Type=Opaque；Double-Sided=Enabled；Alpha Clipping=Force Off；  Use Shadow Threshold=Force Off；Material Type=Cotton Wool；Transmission=false；  Subsurface Scattering=false；Energy Conserving Specular=true；Receive Decals=false；Receives SSR=false；Specular Occlusion Mode=From AO。

功能阶段：02 原生运算与采样 · 阶段 1 → 01 原图属性与资源 · 阶段 1。

源属性：`Vector1_4784DC7`、`Color_512C93D4`、`Texture2D_2D0D32F9`、`AlbedoNoisePower`、`Texture2D_1C6F9DC8`、`Vector1_CC012422`、`Vector1_430999C3`、`Vector1_E6267AA5`、`Texture2D_C4AB2143`、`Vector1_4548C0F8`、`Vector1_18BBE2E1`、`Color_A43A3DFB`、`Vector1_BD133B8D`、`Texture2D_26D18CAA`、`Vector1_CB152CD2`、`AlbedoDetail`、`Texture2D_D3552121`、`Vector1_5514B0AB`、`Texture2D_C388EAF4`、`Vector1_54B720F6`、`Thickness`。

没有记录到图默认纹理 GUID；这不代表源材质无需纹理，材质实例的资源仍须手动绑定。

源中禁用、保留断开计算的输出：`SurfaceDescription.Thickness`。

## 人物和布料的具体边界

- 皮肤：本批若干源使用 StackLit，当前 ASE 无匹配模板，保持阻塞。分类库中的皮肤是原创 Lit/SSS 基础，不能冒充这些 StackLit 皮肤的完整转换。
- 眼球：三版源图的活动模型为 Lit/SSS，包含视线/UV/虹膜及法线运算。适配器显式保留切线视线空间、采样与默认块数值；非活动 Specular 分支保留断开。没有专用 Eye BSDF 或角膜外壳/眼睑宿主的等价结论。
- 毛发：原图透明、裁剪、双面、深度前后 Pass、阴影阈值、光照面向法线与各向异性参数分别映射。Strands + Approximate 在当前模板只是对应光照宏，不能证明生成真实发丝或迁移其仿真。
- 织物：按源 Cotton/Wool 或 Silk 模型选真实 Fabric 模板，分别保留 SSS、Transmission、厚度、透明及双面设置，未以普通 Lit 替代其 BSDF。
- 丝袜：原材质名称尚未明确匹配；当前库为独立原创覆盖/织纹近似，不能宣称已转换该工程的丝袜。
