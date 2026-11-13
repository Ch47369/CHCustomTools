"""Author an original, native-node Built-in ASE water plan (Python stdlib only).

The plan is NOT an ASE shader. Submit it to generatePlan in the live, probed
Unity/ASE 1.9.9.13 environment to generate and verify the actual graph.
"""
import argparse
import json
from pathlib import Path


def build_plan(pipeline='BuiltIn'):
    if pipeline not in ('BuiltIn','URP','HDRP'):
        raise ValueError('Unknown pipeline: '+pipeline)
    p = dict(schemaVersion=1, shaderName='Water/DeepWater_ASE', pipeline='BuiltIn',
             surface='Lit', templateGuid='ed95fe726fd7b4644bb42f4d1ddd2bcd',
             nodes=[], wires=[], outputs=[], masterSettings=[], comments=[],
             presentation=dict(autoLayout=True, addComments=True, useRegisters=True,
                               longWireDistance=1400, maxRegisters=48))
    group = 'coordinates'

    def node(id, type, **kw):
        p['nodes'].append(dict(id=id, type=type, group=group, label=id,
                              settings=[], customInputs=[], **kw))
        return id

    def wire(source, target, port=0):
        source, output = (source, 0) if isinstance(source, str) else source
        p['wires'].append(dict(from_=source, fromPort=str(output), to=target, toPort=str(port)))
        p['wires'][-1]['from'] = p['wires'][-1].pop('from_')

    def op(id, type, *args):
        node(id, type)
        for i, arg in enumerate(args):
            wire(arg, id, i)
        return id

    def scalar(id, value, property=None, display=None, limits=None):
        return node(id, 'RangedFloatNode', value=str(value),
                    propertyName=property, displayName=display,
                    propertyKind='Range' if limits else 'Float',
                    rangeMin=limits[0] if limits else 0,
                    rangeMax=limits[1] if limits else 0)

    def vec(id, value, property=None, display=None, color=False):
        return node(id, 'ColorNode' if color else 'Vector4Node',
                    value='('+','.join(map(str,value))+')', propertyName=property,
                    displayName=display, propertyKind='Color' if color else 'Vector')

    def sw(id, value, mask):
        mask=mask.translate(str.maketrans('rgba','xyzw'))
        node(id, 'SwizzleNode', swizzle=mask, outputType='FLOAT'+(str(len(mask)) if len(mask)>1 else ''))
        wire(value,id)
        return id

    def append(id, values):
        node(id, 'DynamicAppendNode', outputType='FLOAT'+str(len(values)))
        for i,v in enumerate(values): wire(v,id,i)
        return id

    def toggle(id, enabled, disabled, property, display):
        node(id, 'StaticSwitch', propertyName=property, displayName=display,
             propertyKind='Float', value='1')
        # ASE PortId is not list index: True=0, False=1 (live describe).
        wire(enabled,id,'True');wire(disabled,id,'False')
        return id

    def comment(id, title, text):
        p['comments'].append(dict(id=id,title=title,text=text))

    add=lambda id,a,b:op(id,'SimpleAddOpNode',a,b)
    mul=lambda id,a,b:op(id,'SimpleMultiplyOpNode',a,b)
    div=lambda id,a,b:op(id,'SimpleDivideOpNode',a,b)
    sub=lambda id,a,b:op(id,'SimpleSubtractOpNode',a,b)
    sat=lambda id,a:op(id,'SaturateNode',a)
    lerp=lambda id,a,b,t:op(id,'LerpOp',a,b,t)
    neg=lambda id,a:op(id,'NegateNode',a)
    smooth=lambda id,a,lo,hi:op(id,'SmoothstepOpNode',a,lo,hi)

    world=node('world_position','WorldPosInputsNode')
    xz=sw('world_xz',world,'xz')
    time=node('time_seconds','SimpleTimeNode')
    speed=scalar('wave_speed',0.75,'_WaveSpeed','01 Waves / speed',(.05,2))
    clock=mul('water_clock',time,speed)
    comment(group,'01 世界坐标与时间','以世界 XZ 米制坐标驱动波浪与细波纹；对象缩放不改变波长。所有动画共享时间和速度。适用于水平水面。')

    group='waves'
    zero=scalar('wave_zero',0)
    one=scalar('wave_one',1)
    amplitude=scalar('wave_height',0.13,'_WaveHeight','01 Waves / height (m)',(0,.6))
    length=scalar('wave_scale',1,'_WaveScale','01 Waves / frequency',(.1,3))
    heights=[]; dx=[]; dz=[]
    for i,(kx,kz,omega,weight,phase) in enumerate([
            (.52,.17,.9,.57,.1),(-.23,.86,1.23,.28,1.6),(1.13,.65,1.58,.15,3.0)]):
        name='swell_'+str(i+1)
        direction=sw(name+'_direction',vec(name+'_parameters',(kx,kz,0,0)),'xy')
        k=mul(name+'_wavevector',direction,length)
        distance=op(name+'_distance','DotProductOpNode',xz,k)
        phase_time=mul(name+'_time',clock,scalar(name+'_omega',omega))
        phase_node=add(name+'_phase',add(name+'_travel',distance,phase_time),scalar(name+'_offset',phase))
        a=mul(name+'_amplitude',amplitude,scalar(name+'_weight',weight))
        heights.append(mul(name+'_height',op(name+'_sin','SinOpNode',phase_node),a))
        slope=mul(name+'_derivative',op(name+'_cos','CosOpNode',phase_node),a)
        dx.append(mul(name+'_slope_x',slope,sw(name+'_kx',k,'x')))
        dz.append(mul(name+'_slope_z',slope,sw(name+'_kz',k,'y')))
    height=add('swell_height',add('height_pair',heights[0],heights[1]),heights[2])
    slope_x=add('swell_slope_x',add('slope_x_pair',dx[0],dx[1]),dx[2])
    slope_z=add('swell_slope_z',add('slope_z_pair',dz[0],dz[1]),dz[2])
    wavepacket=toggle('waves_enabled',append('wave_displacement_and_slopes',(height,slope_x,slope_z,zero)),
                      vec('waves_disabled',(0,0,0,0)), '_WATER_WAVES','Enable / 01 Geometry waves')
    height=sw('enabled_wave_height',wavepacket,'x')
    slope_x=sw('enabled_wave_slope_x',wavepacket,'y')
    slope_z=sw('enabled_wave_slope_z',wavepacket,'z')
    offset4=append('world_wave_offset',(zero,height,zero,zero))
    world_to_object=node('world_to_object','WorldToObjectMatrix')
    offset=sw('object_wave_offset',mul('offset_transform',world_to_object,offset4),'xyz')
    comment(group,'02 三向缓慢涌浪与解析斜率','三组不同方向、频率和速度的正弦波叠加成米制位移，同时用 cos 求导得到匹配的水面斜率。w=0 的矩阵变换将世界位移转回对象空间，不受平移影响。细分网格才有真实起伏。')

    group='ripples'
    tex=node('ripple_texture','TexturePropertyNode',propertyName='_RippleSlope',
             displayName='02 Ripples / seamless slope field',propertyKind='2D',value='"gray" {}')
    tiling=scalar('ripple_scale',.40,'_RippleScale','02 Ripples / tiling per meter',(.05,2))
    strength=scalar('ripple_strength',.48,'_RippleStrength','02 Ripples / strength',(0,1.5))
    uv1=mul('ripple_uv_a',xz,tiling)
    flow1=sw('ripple_flow_a',vec('ripple_flow_a_data',(.036,.021,0,0)),'xy')
    pan1=node('ripple_pan_a','PannerNode');wire(uv1,pan1,0);wire(flow1,pan1,2);wire(clock,pan1,1)
    uv2=mul('ripple_uv_b',sw('rotated_xz',xz,'yx'),mul('ripple_second_scale',tiling,scalar('ripple_scale_ratio',1.63)))
    flow2=sw('ripple_flow_b',vec('ripple_flow_b_data',(-.019,.029,0,0)),'xy')
    pan2=node('ripple_pan_b','PannerNode');wire(uv2,pan2,0);wire(flow2,pan2,2);wire(clock,pan2,1)
    sample1=node('ripples_a','SamplerNode');wire(tex,sample1,'Tex');wire(pan1,sample1,'UV')
    sample2=node('ripples_b','SamplerNode');wire(tex,sample2,'Tex');wire(pan2,sample2,'UV')
    rgba=sw('ripple_slope_a',sample1,'rg');rgbb=sw('ripple_slope_b',sample2,'gr')
    # Both samples encode [0,1] slopes: sum minus one decodes their average.
    summed=add('encoded_ripple_sum',rgba,rgbb)
    ripple=mul('detail_slope',sub('signed_ripple_slope',summed,scalar('slope_decode_bias',1)),strength)
    ripple=toggle('ripples_enabled',ripple,sw('flat_ripple_slope',vec('ripples_disabled',(0,0,0,0)),'xy'),
                  '_WATER_RIPPLES','Enable / 02 Fine ripples (2 samples)')
    comment(group,'03 双层无缝细波纹','两次采样同一张原创线性斜率纹理，以不同方向和尺度流动。RG 解码为有正负的斜率；第二层交换通道。B 作为岸沫破碎噪声。纹理必须关闭 sRGB，保持 Repeat 与 mipmap。')

    group='normal'
    nx=neg('negative_slope_x',add('total_slope_x',slope_x,sw('detail_x',ripple,'x')))
    nz=neg('negative_slope_z',add('total_slope_z',slope_z,sw('detail_z',ripple,'y')))
    normal=op('water_normal_ws','NormalizeNode',append('slope_normal_ws',(nx,scalar('normal_y',1),nz)))
    view=node('view_to_camera_ws','ViewDirInputsCoordNode')
    fresnel=node('water_fresnel','FresnelNode')
    wire(normal,fresnel,0);wire(view,fresnel,4)
    wire(scalar('water_f0',.02037),fresnel,1)
    wire(scalar('water_fresnel_scale',.97963),fresnel,2)
    wire(scalar('water_fresnel_power',5),fresnel,3)
    fresnel=toggle('fresnel_enabled',fresnel,scalar('fresnel_disabled',0),
                   '_WATER_FRESNEL','Enable / 03 Transmission Fresnel')
    comment(group,'04 真实方向法线与 Fresnel','将涌浪解析斜率和细波纹斜率相加，构造并归一化世界空间法线。Schlick Fresnel 使用水的正视反射率约 2.04%，斜视时增强反射并减少透射。主节点 Normal Space 必须为 World。')

    group='depth'
    depth=node('scene_depth_gap','DepthFade')
    depth0=op('positive_depth','SimpleMaxOpNode',depth,scalar('depth_zero',0))
    depth_clamp=op('depth_eye','SimpleMinOpNode',depth0,scalar('depth_limit',80))
    view4=append('view_direction4',((view,1),(view,2),(view,3),scalar('view_w_zero',0)))
    camera_matrix=node('world_to_camera','WorldToCameraMatrix')
    view_camera=mul('view_camera_space',camera_matrix,view4)
    view_z=op('view_cosine','AbsOpNode',sw('view_camera_z',view_camera,'z'))
    ray_cos=op('safe_ray_cosine','SimpleMaxOpNode',view_z,scalar('min_ray_cosine',.12))
    ray_depth=div('optical_path_m',depth_clamp,ray_cos)
    density=scalar('density',.7,'_Density','03 Depth / absorption density',(.01,3))
    absorb=sw('absorption_rgb',vec('absorption',(.85,.32,.17,0),'_Absorption','03 Depth / absorption RGB (1/m)'),'xyz')
    optical=mul('optical_thickness',ray_depth,density)
    transmission=op('rgb_transmittance','ExpOpNode',neg('negative_extinction',mul('rgb_extinction',optical,absorb)))
    deepdistance=scalar('deep_distance',5,'_DeepDistance','03 Depth / deep color distance (m)',(.1,25))
    depthblend=sat('deep_color_weight',div('depth_color_gradient',ray_depth,deepdistance))
    depthpacket=toggle('depth_enabled',append('depth_packet',(sw('transmission_r',transmission,'x'),sw('transmission_g',transmission,'y'),sw('transmission_b',transmission,'z'),depthblend)),
                       vec('depth_disabled',(1,1,1,0)), '_WATER_DEPTH','Enable / 04 Depth absorption and tint')
    transmission=sw('enabled_transmittance',depthpacket,'xyz')
    depthblend=sw('enabled_depth_blend',depthpacket,'w')
    shallow=sw('shallow_rgb',vec('shallow_color',(.12,.48,.40,1),'_ShallowColor','03 Depth / shallow scattering',True),'rgb')
    deep=sw('deep_rgb',vec('deep_color',(.012,.13,.19,1),'_DeepColor','03 Depth / deep scattering',True),'rgb')
    scattercolor=lerp('depth_scattering_color',shallow,deep,depthblend)
    edge=smooth('shore_contact_fade',depth_clamp,scalar('contact_start',0),scalar('contact_width',.10))
    comment(group,'05 真实深度与可选光吸收','Depth Fade 减去已位移水面的线性眼空间深度，除以视线余弦得到水中路程。T=exp(-吸收系数×密度×路程)。开关关闭时透过率为 1，颜色使用浅水色；泡沫、焦散和折射仍可能需要共享深度。')

    group='caustics'
    # Trace the camera ray from the water surface to the opaque bed. This is an
    # above-water screen-space approximation, not a projector lighting other objects.
    bottom=sub('underwater_position_ws',world,mul('water_to_bed_ray',view,ray_depth))
    bottomxz=sw('bottom_world_xz',bottom,'xz')
    vertical=op('vertical_water_depth','SimpleMaxOpNode',sub('bed_below_water',(world,2),sw('bed_y',bottom,'y')),scalar('caustic_depth_zero',0))
    ctex=node('caustic_texture','TexturePropertyNode',propertyName='_CausticTex',
              displayName='06 Caustics / seamless light pattern',propertyKind='2D',value='"black" {}')
    cscale=scalar('caustic_scale',.28,'_CausticScale','06 Caustics / tiling per meter',(.05,2))
    cspeed=scalar('caustic_speed',.65,'_CausticSpeed','06 Caustics / animation speed',(0,2))
    cclock=mul('caustic_clock',time,cspeed)
    samples=[]
    for i,(flow,ratio) in enumerate([((.025,.017,0,0),1),((-.018,.023,0,0),1.17)]):
        name='caustic_'+str(i+1)
        uv=mul(name+'_uv',bottomxz,mul(name+'_scale',cscale,scalar(name+'_ratio',ratio)))
        pan=node(name+'_pan','PannerNode');wire(uv,pan,0);wire(cclock,pan,1)
        wire(sw(name+'_flow',vec(name+'_flow_data',flow),'xy'),pan,2)
        sample=node(name+'_sample','SamplerNode');wire(ctex,sample,'Tex');wire(pan,sample,'UV')
        samples.append((sample,1))
    pattern=op('moving_caustic_network','SimpleMinOpNode',*samples)
    cstrength=scalar('caustic_strength',3,'_CausticStrength','06 Caustics / brightness',(0,6))
    cfalloff=scalar('caustic_falloff',.45,'_CausticFalloff','06 Caustics / depth extinction',(0,3))
    atten=mul('caustic_depth_attenuation',op('caustic_extinction','ExpOpNode',neg('caustic_optical_depth',mul('caustic_depth_loss',vertical,cfalloff))),edge)
    tint=sw('caustic_tint_rgb',vec('caustic_tint',(1,.94,.72,1),'_CausticTint','06 Caustics / light tint',True),'rgb')
    caustic=toggle('caustics_enabled',mul('caustic_light',tint,mul('caustic_intensity',pattern,mul('caustic_brightness',cstrength,atten))),
                   sw('caustics_off',vec('caustics_disabled',(0,0,0,0)),'xyz'),
                   '_WATER_CAUSTICS','Enable / 06 Underwater caustics (2 samples)')
    comment(group,'06 水底焦散：重建位置与流动光网','从水面沿相机视线和深度间隙重建水底位置，按水底世界 XZ 投影两层原创焦散纹理，缓慢错向流动。随垂直水深衰减并经水体吸收合成。关闭会裁掉焦散贡献；依赖屏幕水下透视，不是场景投影灯或水下相机效果。')

    group='foam'
    foamnoise=node('foam_noise_sample','SamplerNode');wire(tex,foamnoise,'Tex')
    fuv=mul('foam_noise_uv',xz,scalar('foam_noise_scale',.48))
    fpan=node('foam_noise_pan','PannerNode');wire(fuv,fpan,0);wire(clock,fpan,1)
    wire(sw('foam_flow',vec('foam_flow_data',(.029,.014,0,0)),'xy'),fpan,2);wire(fpan,foamnoise,'UV')
    noise=(foamnoise,3)
    width=scalar('foam_width',.5,'_FoamWidth','04 Foam / shoreline width (m)',(.02,2))
    shore=op('shore_foam_band','OneMinusNode',sat('shore_distance_normalized',div('shore_depth_width',depth_clamp,width)))
    band=mul('foam_band_shape',shore,shore)
    broken=smooth('foam_breakup',noise,scalar('foam_noise_low',.34),scalar('foam_noise_high',.66))
    # Moving rings make the contact foam less static without turning the whole surface white.
    ringphase=sub('shore_ring_phase',mul('shore_ring_distance',depth_clamp,scalar('foam_ring_frequency',14)),mul('shore_ring_time',clock,scalar('foam_ring_speed',1.8)))
    rings=add('shore_ring_positive',mul('shore_ring_half',op('shore_ring_sin','SinOpNode',ringphase),scalar('foam_half',.5)),scalar('foam_ring_bias',.5))
    ringweight=lerp('foam_ring_modulation',scalar('foam_ring_min',.35),scalar('foam_ring_max',1),rings)
    foamstrength=scalar('foam_strength',.7,'_FoamStrength','04 Foam / amount',(0,1))
    foam=sat('shore_foam',mul('foam_contact',mul('foam_pattern',mul('foam_band_breakup',band,broken),ringweight),mul('foam_amount',foamstrength,edge)))
    foam=toggle('foam_enabled',foam,scalar('foam_disabled',0),'_WATER_FOAM','Enable / 05 Shore foam (1 noise sample)')
    foamcolor=sw('foam_rgb',vec('foam_color',(.82,.91,.88,1),'_FoamColor','04 Foam / color',True),'rgb')
    comment(group,'07 可选浅岸泡沫','按深度间隙生成岸沫，独立采样斜率纹理 B 通道作为流动噪声，再乘推进条带与接触软化。与细波纹开关独立；关闭泡沫会裁掉这个额外采样及粗糙度/颜色贡献。')

    group='refraction'
    normal4=append('normal_ws4',(sw('normal_x',normal,'x'),sw('normal_y_component',normal,'y'),sw('normal_z',normal,'z'),scalar('normal_w_zero',0)))
    # Matrices cannot be stored in numeric Register/Get nodes. Read this cheap
    # built-in matrix locally instead of drawing a wire across three modules.
    refract_camera_matrix=node('refraction_world_to_camera','WorldToCameraMatrix')
    normal_camera=mul('normal_camera_space',refract_camera_matrix,normal4)
    offsetxy=sw('refraction_direction',normal_camera,'xy')
    refractstrength=scalar('refraction_strength',.014,'_RefractionStrength','05 Optics / refraction',(0,.05))
    refractfade=sat('shallow_refraction_fade',div('refraction_depth',depth_clamp,scalar('refraction_fade_distance',.65)))
    distortion=mul('screen_distortion',offsetxy,mul('refraction_weight',refractstrength,refractfade))
    grab=node('grab_screen_uv','GrabScreenPosition')
    grabxy=sw('grab_xy',grab,'xy')
    # Bound offsets at screen edges. GrabScreenPosition owns the platform projection handling.
    grabuv=sat('safe_refracted_uv',add('distorted_grab_uv',grabxy,distortion))
    scene=node('refracted_scene_color','ScreenColorNode');wire(grabuv,scene,'UV')
    scene_rgb=sw('refracted_rgb',scene,'rgb')
    scene_rgb=mul('caustic_lit_bottom',scene_rgb,add('bottom_light_gain',scalar('base_bottom_light',1),caustic))
    transmitted=mul('absorbed_scene',scene_rgb,transmission)
    scatter=mul('absorbed_scattering',scattercolor,op('absorbed_fraction','OneMinusNode',transmission))
    scatterweight=scalar('scattering_strength',.75,'_ScatteringStrength','05 Optics / scattering',(0,1.5))
    scatterenergy=toggle('scattering_enabled',mul('scattering_energy',scatter,scatterweight),
                         sw('scattering_off',vec('scattering_disabled',(0,0,0,0)),'xyz'),
                         '_WATER_SCATTER','Enable / 07 Water scattering')
    under=toggle('refraction_enabled',add('underwater_color',transmitted,scatterenergy),
                 scattercolor,'_WATER_REFRACTION','Enable / 08 Screen refraction and bottom')
    transmitted_fresnel=mul('transmitted_fresnel',under,op('fresnel_transmission','OneMinusNode',fresnel))
    emission=mul('water_transmission_emission',transmitted_fresnel,op('foam_transmission','OneMinusNode',foam))
    comment(group,'08 可选屏幕折射与水下合成','相机空间法线扰动屏幕坐标，浅岸缩小偏移。水底颜色乘焦散光网，再经 RGB 吸收和可选散射，最后让出 Fresnel 与泡沫能量。关闭屏幕折射时改用水体颜色，裁掉屏幕采样和焦散；ShaderLab 的 GrabPass 拷贝仍存在。')

    group='surface'
    reflect=scalar('reflection_strength',1,'_ReflectionStrength','05 Optics / reflection',(0,2))
    f0=mul('pbr_f0',scalar('pbr_water_f0',.02037),mul('reflection_contact',reflect,edge))
    specular=lerp('surface_specular',f0,scalar('foam_specular',.028),foam)
    specular_rgb=append('specular_rgb',(specular,specular,specular))
    smoothness=scalar('smoothness',.94,'_Smoothness','05 Optics / smoothness',(.5,.99))
    smoothfinal=lerp('surface_smoothness',smoothness,scalar('foam_smoothness',.28),foam)
    diffuse=mul('water_diffuse',scatterenergy,scalar('water_diffuse_fraction',.08))
    albedo=lerp('surface_albedo',diffuse,foamcolor,foam)
    alpha=scalar('composite_alpha',1)
    comment(group,'09 PBR 高光、探针反射与合成','Specular 工作流由方向光及 Reflection Probe 产生高光与反射；模板 Material Toggle 分别控制两者，使用 Unity 的 OFF 关键词。Transparent、ZWrite Off、One/Zero 已合成背景。各效果使用本地 shader_feature，构建时仅保留实际使用的材质组合。')
    for n,port in [(albedo,'Albedo'),(normal,'Normal WS'),(specular_rgb,'Specular'),
                   (smoothfinal,'Smoothness'),(emission,'Emission'),(alpha,'Alpha'),
                   (offset,'Vertex Offset')]:
        p['outputs'].append({'node':n,'port':'0','masterPort':port,'pass':'ForwardBase'})
    for name,value in [('Workflow','Specular'),('Surface','Transparent'),('  Blend','Translucent'),
                       ('Normal Space','World'),('Two Sided','Cull Back'),('Cast Shadows','false'),
                       ('Deferred Pass','false'),('Meta Pass','false'),('Add Pass','false'),
                       ('Receive Specular','Material Toggle'),('Receive Reflections','Material Toggle'),
                       ('LOD CrossFade','false'),('GPU Instancing','true'),('Built-in Fog','true')]:
        p['masterSettings'].append(dict(name='option:'+name,value=value))
    if pipeline!='BuiltIn':
        # Share the actual computation, properties and switches. Only the target
        # host model, master ports and explicit screen-color exposure differ.
        p['pipeline']=pipeline
        p['shaderName']='Water/DeepWater_'+pipeline+'_ASE'
        p['templateGuid']={'URP':'94348b07e5e8bab40bd6c8a1e3df54cd',
                           'HDRP':'53b46d85872c5b24c8f4f0a1c3fe4c87'}[pipeline]
        for output in p['outputs']:
            output['pass']='ForwardLit' if pipeline=='URP' else ''
            output['masterPort']={'Albedo':'Base Color','Normal WS':'World Normal' if pipeline=='URP' else 'Normal WS'}.get(output['masterPort'],output['masterPort'])
        settings=[('Workflow','Specular'),('Surface','Transparent'),('  Blend','Alpha'),
                  ('Fragment Normal Space','World'),('Two Sided','Cull Back'),
                  ('Cast Shadows','false'),('Forward Only','true'),('Meta Pass','false'),
                  ('Specular Highlights','Material Toggle'),('Environment Reflections','Material Toggle'),
                  ('GPU Instancing','true'),('Built-in Fog','true'),('Vertex Position','Relative')]
        if pipeline=='HDRP':
            settings=[('Surface Type','Transparent'),('  Rendering Pass','Default'),
                      ('  Refraction Model','None'),('    Blending Mode','Alpha'),
                      ('    Blend Preserves Specular','true'),('  ZWrite','false'),
                      ('Double-Sided','Disabled'),('Alpha Clipping','Force Off'),
                      ('Material Type','Specular Color'),('Normal Space','World'),
                      ('Receive SSR Transparent','false'),('GPU Instancing','true'),
                      ('Vertex Position','Relative')]
            next(n for n in p['nodes'] if n['id']=='refracted_scene_color')['settings']=[dict(name='m_exposure',value='false')]
        p['masterSettings']=[dict(name='option:'+name,value=value) for name,value in settings]
        for c in p['comments']:
            if c['id']=='refraction':
                c['text']=c['text'].replace('ShaderLab 的 GrabPass 拷贝仍存在。',
                    '使用 URP Opaque Texture / HDRP Color Pyramid；关闭采样不自动关闭宿主颜色拷贝。HDRP 采样去预曝光后进入 Emission，避免重复曝光。')
            if c['id']=='surface':
                c['text']='相同的 Specular 工作流、方向光和探针反射；透明 Alpha=1 输出已合成的背景，ZWrite Off。URP 保留高光/环境反射材质开关；HDRP 专用 BSDF 的这两个独立开关未适配，默认均开启。各管线灯光、雾、探针和颜色拷贝宿主有差异，尚未证明像素等价。'
    return p


if __name__=='__main__':
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('output',type=Path)
    ap.add_argument('--shader-path',default='Assets/Shaders/DeepWater_ASE.shader')
    ap.add_argument('--pipeline',choices=['BuiltIn','URP','HDRP'],default='BuiltIn')
    args=ap.parse_args()
    plan=build_plan(args.pipeline)
    args.output.parent.mkdir(parents=True,exist_ok=True)
    args.output.write_text(json.dumps(dict(schemaVersion=1,operation='generatePlan',
                          outputPath=args.shader_path,plan=plan),ensure_ascii=False,indent=2),encoding='utf-8')
    print(f"{len(plan['nodes'])} native nodes, {len(plan['wires'])} wires, {len(plan['comments'])} comment groups")
