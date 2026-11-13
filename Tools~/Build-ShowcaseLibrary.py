"""Explicit native ASE conversion of AspectURP's complete three-layer parallax glitter.
No source HLSL, graph serialization or source textures are copied into the library.
"""
from pathlib import Path
import importlib.util,json,hashlib
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'.build~/Showcase035';E=ROOT/'Documentation~/Evidence/Showcase035'
spec=importlib.util.spec_from_file_location('showcase_base',ROOT/'Tools~/Build-ShaderLibraryPlans.py');base=importlib.util.module_from_spec(spec);spec.loader.exec_module(base)
spec=importlib.util.spec_from_file_location('filter_base',ROOT/'Tools~/Build-PublicLibrary.py');filters=importlib.util.module_from_spec(spec);spec.loader.exec_module(filters)
PIPES=('BuiltIn','URP','HDRP');GUIDS={p:hashlib.sha256(('aseshader-showcase035-'+p).encode()).hexdigest()[:32] for p in PIPES}
def read(p):return json.loads((ROOT/p).read_text(encoding='utf-8-sig'))
def write(p,o):base.write(p,o)
def template(p):
    text=filters.template(p).replace('Image Filter '+p,'Parallax Glitter '+p).replace('#pragma target 3.0','#pragma target 4.5')
    text=text.replace('"RenderType"="Opaque"','"RenderType"="TransparentCutout" "Queue"="AlphaTest" "IgnoreProjector"="True"')
    text=text.replace('Cull Off','Cull Back').replace('ZWrite Off','ZWrite On').replace('ZTest Always','ZTest LEqual').replace('        Pass\n','        LOD 100\n        Pass\n')
    text=text.replace('Name "Unlit"','Name "Unlit"\n            Tags { "LightMode"="'+('ForwardBase' if p=='BuiltIn' else 'SRPDefaultUnlit')+'" }')
    text=text.replace('float2 uv : TEXCOORD0;\n                /*ase_vdata:p=p;uv0=tc0.xy*/','float2 uv : TEXCOORD0;\n                float3 normal : NORMAL;\n                float4 tangent : TANGENT;\n                /*ase_vdata:p=p;uv0=tc0.xy;n=n;t=t*/')
    text=text.replace('/*ase_interp(1,):sp=sp.xyzw;uv0=tc0.xy*/','float3 tangentView : TEXCOORD1;\n                /*ase_interp(2,):sp=sp.xyzw;uv0=tc0.xy*/')
    text=text.replace('o.uv = v.uv;','o.uv = v.uv;\n                float3 binormal = cross(v.normal,v.tangent.xyz)*v.tangent.w;\n                float3 objectView = ObjSpaceViewDir(v.position);\n                o.tangentView = normalize(mul(float3x3(v.tangent.xyz,binormal,v.normal),objectView));')
    text=text.replace('/*ase_frag_code:i=FilterVaryings*/','/*ase_local_var*/float3 ase_tangentView = i.tangentView;\n                /*ase_frag_code:i=FilterVaryings*/\n                clip(/*ase_frag_out:Clip;Float*/1/*end*/ - 0.5);')
    # The original declares unused lighting variants; preserve their material interface/keywords.
    text=text.replace('#pragma fragment FilterFragment','#pragma fragment FilterFragment\n            #pragma multi_compile_fwdbase\n            #pragma multi_compile_fwdadd_fullshadows\n            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS\n            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE\n            #pragma multi_compile _ _SHADOWS_SOFT')
    text=text.replace('// Converter-owned raw image filter template. Input/output share the caller\'s\n// color encoding. No camera injection, lighting, tone mapping, fog or exposure.','// Converter-owned mesh host for the reviewed unlit glitter source.\n// Vertex tangent-view normalization/interpolation matches the source.\n// The node graph contains all material calculations; no lighting/fog/exposure is added.')
    text=text.replace('    }\n}\n','    }\n    Fallback "Transparent/Cutout/VertexLit"\n}\n')
    text=text.replace('#define SAMPLE_TEXTURE2D(tex, state, uv) tex2D(tex, uv)','#define SAMPLE_TEXTURE2D(tex, state, uv) tex2D(tex, uv)\n                #define SAMPLE_TEXTURE2D_LOD(tex, state, uv, lod) tex2Dlod(tex, float4(uv, 0, lod))')
    text=text.replace('#define SAMPLE_TEXTURE2D(tex, state, uv) tex.Sample(state, uv)','#define SAMPLE_TEXTURE2D(tex, state, uv) tex.Sample(state, uv)\n                #define SAMPLE_TEXTURE2D_LOD(tex, state, uv, lod) tex.SampleLevel(state, uv, lod)')
    return text

def build_plan(p):
    g=base.Graph(p,'VFX',True);g.plan.update(shaderName='ASELibrary/'+p+'/Showcase/LayeredParallaxGlitter',templateGuid=GUIDS[p]);g.plan['presentation'].update(maxRegisters=80,longWireDistance=1800)
    g.phase('inputs','01 原源码与输入','MIT: aspect-ux/AspectURP。完整三层流麻/视差闪片计算，非皮肤或体积散射。保留原属性；基色/色带 sRGB，噪声/裁剪/原始 RG 法线 Linear。')
    f=g.f;v=g.v;op=g.op;sw=g.sw;add=g.add;sub=g.sub;mul=g.mul;div=g.div;zero=f(0);one=f(1);uv=g.uv();textures={}
    def vec2(a,b):return op('DynamicAppendNode',a,b,outputType='FLOAT2')
    def vec3(a,b,c):return op('DynamicAppendNode',a,b,c,outputType='FLOAT3')
    def rgba(rgb,a):return op('DynamicAppendNode',sw(rgb,'x'),sw(rgb,'y'),sw(rgb,'z'),a,outputType='FLOAT4')
    def floatprop(value,name,title):return g.node('RangedFloatNode',value=str(value),propertyName=name,displayName=title,propertyKind='Float')
    def tex(name,title,default='white'):
        if name not in textures:textures[name]=g.node('TexturePropertyNode',propertyName=name,displayName=title,propertyKind='2D',value='"'+default+'" {}')
        return textures[name]
    def st(name):
        n=g.uv();g.wire(textures[name],n,'Tex');return n
    def sample(name,at,lod=False):
        n=g.node('SamplerNode',settings=[{'name':'m_mipMode','value':'MipLevel'}] if lod else []);g.wire(textures[name],n,'Tex');g.wire(at,n,'UV')
        if lod:g.wire(zero,n,'Level')
        return n
    for name,title in [('_MainTex','基色贴图'),('_NoiseTex','闪片噪声（线性）'),('_MipMap','闪片色带'),('_NormalMap','原始 RG 法线（线性）'),('_MaskAlpha','轮廓裁剪（线性）')]:tex(name,title)
    basecolor=v((.5,.5,.5,1),'_BaseColor','基色叠色',True)
    sparkle=sw(g.node('ColorNode',value='(1,1,1,1)',propertyName='_SparkleColor',displayName='闪片颜色（HDR）',propertyKind='Color',settings=[{'name':'attribute:HDR','value':'true'}]),'xyz')
    speed1=floatprop(.1,'_ShiningSpeed','第一层流速');speed2=floatprop(.1,'_ShiningSpeed_02','第二层流速');speed3=floatprop(.1,'_ShiningSpeed_03','第三层流速')
    depths=[f(20,'_DepthStep','第一层视差深度',max=300),f(20,'_DepthStep_02','第二层视差深度',max=300),f(20,'_DepthStep_03','第三层视差深度',max=300)]
    iteration=f(3,'_Iteration','每层迭代（向上取整）',min=1,max=15);die1=f(.5,'_DieValue01','速度衰减',min=.01,max=1);die2=f(3,'_DieValue02','亮度衰减',max=5)
    offsets=[sw(v((0,0,0,0)),'xy'),sw(v((.5,.5,0,0),'_OffsetSecond','第二层偏移'),'xy'),sw(v((.5,.5,0,0),'_OffsetThird','第三层偏移'),'xy')]
    g.phase('geometry','02 顶点视线与原始法线','模板按原顶点阶段计算 object->tangent 视线并归一化，再插值。此原生模板变量节点读取该插值；片元再归一化，保留源视差阶段。RG 法线不使用 Unity NormalMap 解包，避免改变源码通道约定。')
    view=op('NormalizeNode',g.node('TemplateLocalVarsNode',settings=[{'name':'templateLocal','value':'ase_tangentView'}]))
    packed=sample('_NormalMap',st('_NormalMap'));xy=mul(sub(mul(sw(packed,'xy'),f(2)),one),f(1,'_NormalScale','原始 RG 法线强度',max=3));z=op('SqrtOpNode',sub(one,op('SaturateNode',op('DotProductOpNode',xy,xy))));normal=vec3(sw(xy,'x'),sw(xy,'y'),z)
    reflected=op('ReflectOpNode',op('NegateNode',view),normal)
    parallax=div(sw(reflected,'xy'),mul(op('AbsOpNode',sw(reflected,'z')),f(612)))
    clock=div(g.node('SimpleTimeNode'),f(20));flows=[vec2(zero,mul(clock,speed1)),vec2(mul(mul(clock,speed1),f(.1)),mul(clock,speed2)),vec2(mul(mul(clock,speed1),f(-.1)),mul(clock,speed3))]
    noiseuv=st('_NoiseTex');mipuv=st('_MipMap');layers=[]
    for layer in range(3):
        # Split the 15 native iterations into three readable groups per independent layer.
        accumulated=sw(v((0,0,0,0)),'xyz');mipat=mipuv
        for j in range(1,16):
            if (j-1)%5==0:g.phase('layer'+str(layer)+'part'+str((j-1)//5),'0'+str(3+layer)+' 第'+str(layer+1)+'层 · 迭代 '+str(j)+'–'+str(j+4),'保留原循环逐次 UV 累加、LOD0 色带采样、pow/clamp/step 与 max 聚合。1–15 的迭代参数按原 j < Iteration+1 判断，不能改成普通双层贴图；静态展开有高采样/指令成本，仅 PC。')
            inv=f(1/j);mipat=add(mipat,vec2(zero,mul(mul(clock,f(.3)),inv)))
            mip=sw(sample('_MipMap',mipat,True),'xyz');delta=mul(parallax,mul(depths[layer],f(j)))
            at=add(add(add(noiseuv,delta),offsets[layer]),mul(flows[layer],op('PowerNode',inv,die1)))
            noise=sw(sample('_NoiseTex',at),'x');mask=op('StepOpNode',f(.3),op('SaturateNode',op('PowerNode',noise,f(max(1,min(6,7-j))))))
            brightness=op('ClampOpNode',mul(op('PowerNode',inv,die2),f(5)),zero,f(5));candidate=mul(mul(mul(sparkle,mask),mip),brightness)
            maximum=op('SimpleMaxOpNode',accumulated,candidate)
            gate=g.node('ConditionalIfNode');g.wire(add(iteration,one),gate,'A');g.wire(f(j),gate,'B');g.wire(maximum,gate,'A > B');g.wire(accumulated,gate,'A == B');g.wire(accumulated,gate,'A < B');accumulated=gate
        layers.append(accumulated)
    g.phase('composite','06 三层原始聚合与轮廓裁剪','保留源码 Spark += max(Spark, Layer) 的顺序（非简单三层相加），叠加 MainTex*BaseColor。按 MaskAlpha 原始 UV 的 R<0.5 裁剪。输出不添加 PBR/额外灯光、相机抓图、雾或曝光。')
    result=layers[0]
    for layer in layers[1:]:result=add(result,op('SimpleMaxOpNode',result,layer))
    result=add(result,mul(sw(sample('_MainTex',st('_MainTex')),'xyz'),sw(basecolor,'xyz')))
    g.output(rgba(result,one),'Color','Unlit');g.output(sw(sample('_MaskAlpha',uv),'x'),'Clip','Unlit')
    g.phase('unused','07 原图未参与输出的参数','以下参数在原源码仅声明或仅位于注释/无效分支，保留可编辑接口但不接入输出：ParallaxMap、ColorGradient、Color_pow、SparklePower、SpecularColor/Pow、RimColor/Power/Intensity。原图未输出灯光、抓屏或 PBR 响应，不借此声称已有这些功能。')
    tex('_ParallaxMap','源未使用：视差贴图');tex('_ColorGradient','源未使用：颜色梯度');f(1,'_Color_pow','源未使用：颜色指数',max=10);floatprop(10,'_SparklePower','源未使用：闪片指数')
    v((1,1,1,1),'_SpecularColor','源未使用：高光色',True);f(1,'_SpecularPow','源未使用：高光指数',min=1,max=150);v((.17,.36,.81,0),'_RimColor','源未使用：边缘色',True);f(8,'_RimPower','源未使用：边缘指数',min=.6,max=36);f(1,'_RimIntensity','源未使用：边缘强度',max=100)
    return g.plan

def main():
    manifest=read('.build~/ShaderCorpus/manifest-materials.json');repo=next(r for r in manifest['repositories'] if r['repository']=='aspect-ux/AspectURP');source=next(f for f in repo['files'] if f['path'].endswith('flow.shader'))
    assert repo['license']=='MIT';raw=Path(source['localPath']).read_bytes();assert hashlib.sha256(raw).hexdigest()==source['sha256']=='ceb4795f177903e42c4d3ab0e85d6ce3f741750a988346be488f17ff0926252f'
    # The frozen corpus identity is recorded before any ASE jobs are created.
    reviewed=OUT/'reviewed-source.json'
    if reviewed.exists():assert read(reviewed)['sha256']==source['sha256'],'Source changed; review before generation'
    else:write(reviewed,{**source,'repository':repo['repository'],'commit':repo['commit'],'license':repo['license']})
    entries=[]
    for p in PIPES:
        target=ROOT/'Editor/Templates'/('ParallaxGlitter'+p+'.shader');target.write_text(template(p),encoding='utf-8');target.with_suffix('.shader.meta').write_text('fileFormatVersion: 2\nguid: '+GUIDS[p]+'\n',encoding='utf-8')
        ident='showcase-'+p+'-LayeredParallaxGlitter';plan=build_plan(p);path=OUT/(ident+'.json');write(path,plan)
        write(OUT/('jobs-'+p+'.json'),{'jobs':[{'id':ident,'planPath':str(path),'output':'Assets/ASELibrary035/'+p+'/LayeredParallaxGlitter_ASE.shader'}]})
        entries.append(dict(id=ident,familyId='Aspect-LayeredParallaxGlitter',title='三层视差流麻与动态闪片',category='VFX',pipeline=p,origin='ReviewedMaterialAdaptation',recipe='LayeredParallaxGlitter',effect='法线反射视差 / 三层独立流动 / 1–15 次迭代 / 色带与亮度衰减 / 轮廓裁剪',plan=str(path.relative_to(ROOT)),source=source['url'],sourceSha256=source['sha256'],license='MIT; Copyright (c) 2024 Unknown (AspectURP LICENSE)',sourceRepository=repo['repository'],sourcePath=source['path'],sourceCommit=repo['commit']))
    write(OUT/'entries.json',entries);write(E/'source-review.json',{k:v for k,v in read(reviewed).items() if k!='localPath'})
    print('Three native plans:',[(e['pipeline'],len(read(e['plan'])['nodes'])) for e in entries])
if __name__=='__main__':main()
