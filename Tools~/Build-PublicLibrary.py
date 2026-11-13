"""Reviewed MIT image filters, four source identities x three pipeline hosts.

Only authored ASE templates and graph plans are written here. ASE itself writes
all graph metadata. Downloaded code remains data in the non-distributed cache.
"""
from pathlib import Path
import importlib.util,json,hashlib
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'.build~/PublicLibrary033'
E=ROOT/'Documentation~/Evidence/PublicLibrary033'
PIPES=('BuiltIn','URP','HDRP')
GUIDS={'BuiltIn':'b9e3bd2247b04c12ac193aa10cb6ed01','URP':'b9e3bd2247b04c12ac193aa10cb6ed02','HDRP':'b9e3bd2247b04c12ac193aa10cb6ed03'}
RECIPES={
 'Vignette':('自然暗角滤镜','VFX','keijiro/KinoVignette','Vignette.shader'),
 'AnalogGlitch':('模拟信号故障滤镜','VFX','keijiro/KinoGlitch','AnalogGlitch.shader'),
 'DigitalGlitch':('数字故障与历史帧混合','VFX','keijiro/KinoGlitch','DigitalGlitch.shader'),
 'Mirror':('镜像与万花筒滤镜','UVAnimation','keijiro/KinoMirror','Mirror.shader')}
REVIEWED={
 'Vignette':'8c720c4921f159e66fe246358d6bc26802e8d3a8f0b5a6ad0f0065072c0a770e',
 'AnalogGlitch':'c1b87c7900a9851890ad859fd67a2d55f2a837729bd3d67ba1fbc74f1a3448f8',
 'DigitalGlitch':'ef529f7b8c93c28da3a78a7fac24cb094bf341b6b849e1204ee94123947e43ad',
 'Mirror':'e2544167d674120179943f71eb30990e21fd9dbead9d4d7f699343faa6852a46'}

def read(p):return json.loads((ROOT/p).read_text(encoding='utf-8-sig'))
def write(p,o):p.parent.mkdir(parents=True,exist_ok=True);p.write_text(json.dumps(o,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
spec=importlib.util.spec_from_file_location('public_graph_base',ROOT/'Tools~/Build-ShaderLibraryPlans.py')
base=importlib.util.module_from_spec(spec);spec.loader.exec_module(base)

def template(p):
    tag={'BuiltIn':'','URP':' "RenderPipeline"="UniversalPipeline"','HDRP':' "RenderPipeline"="HDRenderPipeline"'}[p]
    text='''// Converter-owned raw image filter template. Input/output share the caller's
// color encoding. No camera injection, lighting, tone mapping, fog or exposure.
Shader /*ase_name*/"Hidden/ASE Converter/Image Filter PIPELINE"/*end*/
{
    Properties
    {
        /*ase_props*/
    }
    SubShader
    {
        Tags { "RenderType"="Opaque"PIPELINE_TAG }
        Cull Off
        ZWrite Off
        ZTest Always
        Blend Off
        /*ase_pass*/
        Pass
        {
            Name "Unlit"
            CGPROGRAM
            #pragma target 3.0
            #pragma vertex FilterVertex
            #pragma fragment FilterFragment
            #include "UnityCG.cginc"
            /*ase_pragma*/
            struct FilterInput
            {
                float4 position : POSITION;
                float2 uv : TEXCOORD0;
                /*ase_vdata:p=p;uv0=tc0.xy*/
            };
            struct FilterVaryings
            {
                float4 position : SV_POSITION;
                float2 uv : TEXCOORD0;
                /*ase_interp(1,):sp=sp.xyzw;uv0=tc0.xy*/
            };
            /*ase_globals*/
            FilterVaryings FilterVertex(FilterInput v /*ase_vert_input*/)
            {
                FilterVaryings o;
                /*ase_vert_code:v=FilterInput;o=FilterVaryings*/
                v.position.xyz += /*ase_vert_out:Offset;Float3*/float3(0,0,0)/*end*/;
                o.position = UnityObjectToClipPos(v.position);
                o.uv = v.uv;
                return o;
            }
            float4 FilterFragment(FilterVaryings i /*ase_frag_input*/) : SV_Target
            {
                /*ase_frag_code:i=FilterVaryings*/
                return /*ase_frag_out:Color;Float4*/float4(1,1,1,1)/*end*/;
            }
            ENDCG
        }
    }
}
'''.replace('PIPELINE_TAG',tag).replace('PIPELINE',p)
    if p!='BuiltIn':
        # Image filters need no SRP lighting/camera library. Keep templates
        # importable in Built-in projects without an installed SRP package.
        # These standard sampling shims cover only this reviewed node subset.
        text=text.replace('#include "UnityCG.cginc"','''#include "UnityCG.cginc"
            #if defined(SHADER_API_GLES)
                #define TEXTURE2D(name) sampler2D name
                #define SAMPLER(name)
                #define SAMPLE_TEXTURE2D(tex, state, uv) tex2D(tex, uv)
            #else
                #define TEXTURE2D(name) Texture2D name
                #define SAMPLER(name) SamplerState name
                #define SAMPLE_TEXTURE2D(tex, state, uv) tex.Sample(state, uv)
            #endif
            // ASE SRP Time nodes use seconds from _TimeParameters.x. Preserve
            // the source's engine time even for explicit Blit without a camera.
            #define _TimeParameters float4(_Time.y, sin(_Time.y), cos(_Time.y), 0.0)''')
    return text

def build_plan(p,key):
    title,cat,repo,file=RECIPES[key];g=base.Graph(p,cat,True)
    g.plan.update(shaderName='ASELibrary/'+p+'/PublicFilters/'+key,templateGuid=GUIDS[p])
    g.phase('inputs','01 输入与宿主','MIT 来源 '+repo+' / '+file+'。此图为显式输入纹理的全屏滤镜；不会自动注入相机。输入输出采用调用者相同色彩编码，不额外曝光或色调映射。')
    uv=g.uv();f=g.f;v=g.v;op=g.op;sw=g.sw;add=g.add;sub=g.sub;mul=g.mul;div=g.div
    def vec2(a,b):return add(mul(a,sw(v((1,0,0,0)),'xy')),mul(b,sw(v((0,1,0,0)),'xy')))
    def vec3(a,b,c):return add(add(mul(a,sw(v((1,0,0,0)),'xyz')),mul(b,sw(v((0,1,0,0)),'xyz'))),mul(c,sw(v((0,0,1,0)),'xyz')))
    def rgba(rgb,a):return op('DynamicAppendNode',sw(rgb,'x'),sw(rgb,'y'),sw(rgb,'z'),a,outputType='FLOAT4')
    textures={}
    def sample(name,at,default='white'):
        if name not in textures:textures[name]=g.node('TexturePropertyNode',propertyName=name,displayName={'_MainTex':'输入图像','_NoiseTex':'外部故障噪声','_TrashTex':'外部历史帧'}[name],propertyKind='2D',value='"'+default+'" {}',settings=[{'name':'attribute:NoScaleOffset','value':'true'}])
        sampler=g.node('SamplerNode');g.wire(textures[name],sampler,'Tex');g.wire(at,sampler,'UV');return sampler
    def frac(a):return op('FractNode',a)
    def sine(a):return op('SinOpNode',a)
    g.phase('coordinates','02 坐标与参数','保留原始 UV0 和原 shader uniform 名称；原 C# 宿主提供的参数现可在材质中显式设置。纹理无 ST 变换，与原片元一致。')
    if key=='Vignette':
        coord=mul(mul(sub(uv,sw(v((.5,.5,0,0)),'xy')),sw(v((1,1,0,0),'_Aspect','纵横比向量'),'xy')),f(2))
        g.phase('filter','03 镜头暗角','径向距离乘 Falloff，衰减为 1 / (1 + r²)²；只衰减 RGB，保留输入 Alpha。')
        rf=mul(op('LengthOpNode',coord),f(.5,'_Falloff','暗角衰减',max=3));term=add(mul(rf,rf),f(1));e=div(f(1),mul(term,term));src=sample('_MainTex',uv);color=rgba(mul(sw(src,'xyz'),e),sw(src,'w'))
    elif key=='AnalogGlitch':
        u=sw(uv,'x');y=sw(uv,'y');time=div(g.node('SimpleTimeNode'),f(20))
        jitter=sw(v((0,1,0,0),'_ScanLineJitter','扫描线位移与阈值'),'xy');jumpv=sw(v((0,0,0,0),'_VerticalJump','垂直跳动强度与相位'),'xy');driftv=sw(v((0,0,0,0),'_ColorDrift','颜色漂移强度与相位'),'xy')
        def nrand(a,b):return frac(mul(sine(add(mul(a,f(12.9898)),mul(b,f(78.233)))),f(43758.5453)))
        g.phase('filter','03 信号扰动','保留 nrand 常数、_Time.x=秒/20、扫描线阈值、垂直跳动、横抖及独立绿色通道漂移。外部宿主负责动画参数积分。')
        j=sub(mul(nrand(y,time),f(2)),f(1));j=mul(j,mul(op('StepOpNode',sw(jitter,'y'),op('AbsOpNode',j)),sw(jitter,'x')))
        jump=g.lerp(y,frac(add(y,sw(jumpv,'y'))),sw(jumpv,'x'));shake=mul(sub(nrand(time,f(2)),f(.5)),f(0,'_HorizontalShake','横向抖动',max=1))
        drift=mul(sine(add(jump,sw(driftv,'y'))),sw(driftv,'x'));x=add(add(u,j),shake)
        src1=sample('_MainTex',frac(vec2(x,jump)));src2=sample('_MainTex',frac(vec2(add(x,drift),jump)))
        color=rgba(vec3(sw(src1,'x'),sw(src2,'y'),sw(src1,'z')),f(1))
    elif key=='DigitalGlitch':
        glitch=sample('_NoiseTex',uv,'black');intensity=f(0,'_Intensity','故障强度');threshold=sub(f(1.001),mul(intensity,f(1.001)))
        g.phase('filter','03 数字故障','三个门限分别控制位移、历史帧替换和颜色置换；保留 2.5/3.5 次方与原 RGB 交换。调用者必须供应噪声和历史帧。')
        wd=op('StepOpNode',threshold,op('PowerNode',sw(glitch,'z'),f(2.5)));wf=op('StepOpNode',threshold,op('PowerNode',sw(glitch,'w'),f(2.5)));wc=op('StepOpNode',threshold,op('PowerNode',sw(glitch,'z'),f(3.5)))
        at=frac(add(uv,mul(sw(glitch,'xy'),wd)));src=sample('_MainTex',at);trash=sample('_TrashTex',at,'black');rgb=sw(g.lerp(src,trash,wf),'xyz')
        total=add(add(sw(rgb,'x'),sw(rgb,'y')),sw(rgb,'z'));neg=op('SaturateNode',add(sw(rgb,'yxz'),mul(sub(f(1),total),f(.5))));color=rgba(g.lerp(rgb,neg,wc),sw(src,'w'))
    elif key=='Mirror':
        divisor=f(1.57079632679,'_Divisor','角度重复周期（弧度）',min=.001,max=6.28318530718);offset=f(0,'_Offset','重复角偏移',min=-6.28318530718,max=6.28318530718);roll=f(0,'_Roll','旋转角',min=-6.28318530718,max=6.28318530718)
        sc=sub(uv,sw(v((.5,.5,0,0)),'xy'));phi=op('ATan2OpNode',sw(sc,'y'),sw(sc,'x'));radius=op('LengthOpNode',sc)
        g.phase('filter','03 极坐标镜像','保留 atan2、角度取模、边界反射与原全局 SYMMETRY_ON multi_compile；不是普通 UV 旋转。Divisor 必须大于 0。')
        phi=add(phi,offset);phi=sub(phi,mul(divisor,op('FloorOpNode',div(phi,divisor))));mirrored=op('SimpleMinOpNode',phi,sub(divisor,phi))
        switch=g.node('StaticSwitch',propertyName='SYMMETRY',displayName='全局镜面对称',propertyKind='Float',value='0',settings=[{'name':'keyword:GlobalMultiCompile','value':'true'}]);g.wire(phi,switch,'False');g.wire(mirrored,switch,'True')
        phi=add(switch,sub(roll,offset));at=add(mul(vec2(op('CosOpNode',phi),sine(phi)),radius),sw(v((.5,.5,0,0)),'xy'))
        at=op('SimpleMaxOpNode',op('SimpleMinOpNode',at,sub(f(2),at)),op('NegateNode',at));color=sample('_MainTex',at)
    else:raise ValueError(key)
    g.phase('output','04 原始图像输出','原 Pass 的 Cull Off、ZTest Always、ZWrite Off、Blend Off、RGBA 写入由插件自有模板保留。通过 ASE 保存重载和 Unity 编译后入库；采样夹具不代表真实相机集成或所有平台等价。')
    # Give the output contract a visible typed RGBA node and its own comment.
    # Pure swizzle preserves channels without introducing another effect.
    color=sw(color,'xyzw');g.output(color,'Color','Unlit');return g.plan

def main():
    manifest=read('.build~/ShaderCorpus/Library033/manifest-library033.json');entries=[]
    for p in PIPES:
        target=ROOT/'Editor/Templates'/('ImageFilter'+p+'.shader');target.write_text(template(p),encoding='utf-8')
        target.with_suffix('.shader.meta').write_text('fileFormatVersion: 2\nguid: '+GUIDS[p]+'\n',encoding='utf-8');jobs=[]
        for key,(title,cat,repo,file) in RECIPES.items():
            record=next(r for r in manifest['repositories'] if r['repository']==repo and r['success'])
            source=next(f for f in record['files'] if Path(f['path']).name==file);data=Path(source['localPath']).read_bytes();assert hashlib.sha256(data).hexdigest()==source['sha256']
            assert source['sha256']==REVIEWED[key],('Source changed; review and adapt before generation',key)
            # These repos have no root LICENSE, but each selected shader embeds MIT.
            text=data.decode('utf-8-sig');assert 'Copyright (C) 2015 Keijiro Takahashi' in text and 'Permission is hereby granted, free of charge' in text and 'THE SOFTWARE IS PROVIDED' in text
            plan=build_plan(p,key);ident='public-'+p+'-'+key;path=OUT/(ident+'.json');write(path,plan)
            jobs.append({'id':ident,'planPath':str(path),'output':'Assets/ASELibrary033/'+p+'/'+key+'_ASE.shader'})
            entries.append({'id':ident,'familyId':'Kino-'+key,'title':title,'category':cat,'pipeline':p,'origin':'PublicSourceAdaptation','recipe':key,'effect':title,'plan':str(path.relative_to(ROOT)),
                            'source':source['url'],'sourceSha256':source['sha256'],'license':'MIT; Copyright (C) 2015 Keijiro Takahashi','sourceRepository':repo,'sourcePath':source['path'],'sourceCommit':record['commit']})
        write(OUT/('jobs-'+p+'.json'),{'jobs':jobs})
    write(OUT/'entries.json',entries)
    write(E/'download-manifest.json',{'downloadedUtc':manifest['downloadedUtc'],'repositories':[{k:v for k,v in r.items() if k!='files'}|{'files':[{k:v for k,v in f.items() if k!='localPath'} for f in r.get('files',[])]} for r in manifest['repositories']]})
    print('Reviewed public native plans:',len(entries))
if __name__=='__main__':main()
