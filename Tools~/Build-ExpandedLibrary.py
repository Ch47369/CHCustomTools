"""Auditable original effect extensions, not copies/conversions of research sources.
Each recipe adds connected native-node calculations to a validated foundation.
ASE alone writes shaders and graph metadata. Three pipeline jobs per recipe.
"""
from pathlib import Path
import importlib.util,json,hashlib
ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('foundation',ROOT/'Tools~/Build-ShaderLibraryPlans.py')
base=importlib.util.module_from_spec(spec);spec.loader.exec_module(base)
OUT=ROOT/'.build~/LibraryPlans031'
# Labels describe the actual added operation, not a complete physical material model.
RECIPES={
 'Skin':[('Freckles','程序雀斑','dots'),('Blush','顶点色腮红','vertex'),('Tan','肤色渐变','gradient'),('OilMask','油光遮罩','smoothmask'),('Dust','皮肤污渍层','mask')],
 'Hair':[('RootTip','发根发梢渐变','gradient'),('Streaks','发束条纹染色','stripes'),('VertexDye','顶点染发','vertex'),('DyeMask','局部染发遮罩','mask'),('TipFade','发梢覆盖渐隐','coverage')],
 'Eye':[('LimbalRing','角膜缘平面色环','ringtint'),('IrisBands','虹膜同心纹','radialbands'),('IrisMask','虹膜纹理叠色','mask'),('ScleraTint','巩膜顶点染色','vertex'),('IrisSpeckles','虹膜程序斑点','dots')],
 'Fabric':[('Checks','格纹布料','checker'),('Stripes','条纹布料','stripes'),('CrossWeave','交叉织纹染色','cross'),('Print','印花遮罩','mask'),('VertexDye','顶点布料染色','vertex')],
 'Hosiery':[('Dots','波点丝袜覆盖','dotcoverage'),('Rib','竖条罗纹覆盖','stripecoverage'),('Lace','蕾丝遮罩覆盖','maskcoverage'),('Gradient','渐变丝袜覆盖','coverage'),('Diamond','菱形网纹覆盖','diamondcoverage')],
 'Water':[('Foam','流动泡沫遮罩','flowmask'),('Ripples','同心波纹水色','radialbands'),('RimTint','掠射角水色','fresneltint'),('VertexWave','顶点波纹水面','ripplevertex'),('DualNormal','双层流动法线','flownormal')],
 'Metal':[('Brushed','拉丝纹理法线','detailnormal'),('Oxidized','氧化遮罩','mask'),('Scratches','划痕粗糙度遮罩','smoothmask'),('HeatTint','热变色渐变','gradient'),('Panels','金属格纹面板','checker')],
 'Stone':[('MossMask','苔藓纹理遮罩','mask'),('Strata','岩层条纹','stripes'),('Cracks','裂隙遮罩叠色','cracks'),('Wet','湿润光滑度遮罩','smoothmask'),('VertexPaint','岩石顶点染色','vertex')],
 'Jade':[('Veins','玉石程序细纹','cross'),('Clouds','玉石云絮纹理','mask'),('Gradient','玉石渐变色','gradient'),('Speckles','玉石程序斑点','dots'),('Rind','玉皮径向遮罩','ringtint')],
 'UI':[('Gradient','界面纵向渐变','gradient'),('RadialMask','界面径向遮罩','radialcoverage'),('Frame','界面矩形边框','framecoverage'),('Scanline','界面扫描线','stripes'),('MaskTint','界面纹理叠色','mask')],
 'UIEffects':[('ScanPulse','扫描线脉冲','pulsestripe'),('Pulse','界面呼吸亮度','pulse'),('Wipe','界面循环擦除','wipecoverage'),('Grid','界面动态网格','flowgrid'),('RingPulse','界面扩散圆环','pulsering')],
 'VFX':[('Ring','溶解叠加圆环','radialcoverage'),('Beam','溶解叠加光束','beamcoverage'),('SoftDisc','柔边圆盘溶解','softcoverage'),('Scan','条纹溶解','stripecoverage'),('Pulse','呼吸溶解','pulse')],
 'UVAnimation':[('LayerRotate','旋转纹理叠层','rotatelayer'),('FlowMask','流动遮罩叠层','flowmask'),('Distortion','纹理扰动叠层','distortlayer'),('Flipbook','序列帧叠层','flipbook'),('PingPong','往返UV叠层','pingpong')],
 'VertexAnimation':[('Flutter','高频颤动','fluttervertex'),('Ripple','径向顶点涟漪','ripplevertex'),('Bob','整体上下浮动','bobvertex'),('Bend','高度加权弯曲','bendvertex'),('CrossWind','双轴交叉风摆','crossvertex')]
}

def apply(g,c,kind,title):
    g.phase('extension','06 '+title,'原创可编辑扩展：'+title+'。程序图案使用 UV0；贴图型扩展需绑定实际资源。设备建议来自静态复杂度，未做 GPU 实机测速。')
    ui=c in ('UI','UIEffects');uv=g.uv();x=g.sw(uv,'x');y=g.sw(uv,'y')
    def value(out):
        o=next(o for o in g.plan['outputs'] if o['masterPort'] in out);return o['node'],o['port']
    def output(out,v):
        for o in g.plan['outputs']:
            if o['masterPort'] in out:o.update(node=v[0],port=v[1])
    color=value(('Color','Albedo','Base Color'))
    f=g.f;op=g.op;add=g.add;sub=g.sub;mul=g.mul;div=g.div;lerp=g.lerp
    one=f(1);zero=f(0)
    def sat(a):return op('SaturateNode',a)
    def sine(a):return op('SinOpNode',a)
    def absolute(a):return op('AbsOpNode',a)
    def frac(a):return op('FractNode',a)
    def smooth(a,lo,hi):return op('SmoothstepOpNode',a,lo,hi)
    def time():return mul(g.node('SimpleTimeNode'),f(.4,'_EffectSpeed','扩展动画速度',min=-4,max=4))
    def radial():return op('LengthOpNode',sub(uv,g.sw(g.v((.5,.5,0,0)),'xy')))
    pattern_frequency=None
    def stripe(axis=x):
        nonlocal pattern_frequency
        if pattern_frequency is None:pattern_frequency=f(60,'_PatternFrequency','图案频率',min=1,max=400)
        return add(mul(sine(mul(axis,pattern_frequency)),f(.5)),f(.5))
    def dotmask():
        cells=frac(mul(uv,f(35,'_SpotTiling','斑点网格密度',min=1,max=150)))
        distance=op('LengthOpNode',sub(cells,g.sw(g.v((.5,.5,0,0)),'xy')))
        radius=f(.18,'_SpotRadius','斑点半径',min=.01,max=.45)
        return sub(one,smooth(distance,radius,add(radius,f(.025))))
    def mask(moving=False):
        at=add(uv,mul(time(),g.sw(g.v((.06,.025,0,0)),'xy'))) if moving else uv
        return g.sw(g.texture('_EffectMask','扩展遮罩（线性）',at,'gray'),'x')
    def tint(m):
        tint=g.v((.4,.65,.3,1),'_EffectTint','扩展叠色',True);tint=tint if ui else g.sw(tint,'xyz')
        amount=f(.55,'_EffectAmount','扩展影响强度')
        output(('Color','Albedo','Base Color'),lerp(color,mul(color,tint),sat(mul(m,amount))))
    def coverage(m):
        if ui:output(('Color',),mul(color,lerp(g.v((1,1,1,0)),g.v((1,1,1,1)),sat(m))))
        else:output(('Alpha',),mul(value(('Alpha',)),sat(m)))
    if kind=='gradient':tint(smooth(y,f(.15,'_GradientStart','渐变起点'),f(.85,'_GradientEnd','渐变终点')))
    elif kind=='vertex':tint(g.sw(g.node('VertexColorNode'),'x'))
    elif kind=='stripes':tint(stripe())
    elif kind=='cross':tint(mul(stripe(),add(mul(sine(mul(y,f(95))),f(.5)),f(.5))))
    elif kind=='checker':
        tiling=f(12,'_CheckTiling','格纹密度',min=1,max=100);tint(absolute(sub(frac(mul(x,tiling)),frac(mul(y,tiling)))))
    elif kind=='mask':tint(mask())
    elif kind=='cracks':tint(sub(one,smooth(mask(),f(.2),f(.35))))
    elif kind=='flowmask':tint(mask(True))
    elif kind=='dots':tint(dotmask())
    elif kind=='ringtint':
        r=radial();tint(mul(smooth(r,f(.12),f(.16)),sub(one,smooth(r,f(.19),f(.23)))))
    elif kind=='radialbands':tint(add(mul(sine(mul(radial(),f(140,'_RingFrequency','环纹频率',min=1,max=400))),f(.5)),f(.5)))
    elif kind=='fresneltint':
        n=g.node('FresnelNode');g.wire(f(3,'_RimPower','掠射角指数',min=.1,max=10),n,'Power');tint(n)
    elif kind=='smoothmask':
        old=value(('Smoothness',));output(('Smoothness',),lerp(old,f(.9,'_EffectSmoothness','遮罩区光滑度'),mask()))
    elif kind in ('detailnormal','flownormal'):
        at=mul(uv,g.sw(g.v((12,1,0,0),'_EffectTiling','扩展法线平铺'),'xy'))
        if kind=='flownormal':at=add(at,mul(time(),g.sw(g.v((-.04,.03,0,0)),'xy')))
        detail=g.normal(g.texture('_EffectNormal','扩展法线',at,'bump'),f(.35,'_EffectNormalScale','扩展法线强度',max=2))
        output(('Normal',),op('BlendNormalsNode',value(('Normal',)),detail))
    elif kind=='coverage':coverage(smooth(y,f(.05,'_FadeStart','渐隐起点'),f(.65,'_FadeEnd','渐隐终点')))
    elif kind=='dotcoverage':coverage(lerp(f(.3),one,dotmask()))
    elif kind=='stripecoverage':coverage(lerp(f(.25),one,stripe()))
    elif kind=='maskcoverage':coverage(mask())
    elif kind=='diamondcoverage':
        a=absolute(sine(mul(add(x,y),f(100,'_DiamondFrequency','菱形密度',min=1,max=300))));b=absolute(sine(mul(sub(x,y),f(100))))
        coverage(lerp(f(.2),one,mul(a,b)))
    elif kind=='radialcoverage':
        r=radial();coverage(mul(smooth(r,f(.2),f(.23)),sub(one,smooth(r,f(.32),f(.35)))))
    elif kind=='softcoverage':coverage(sub(one,smooth(radial(),f(.05),f(.48))))
    elif kind=='beamcoverage':coverage(sub(one,smooth(absolute(sub(x,f(.5))),f(.05),f(.25))))
    elif kind=='framecoverage':
        a=mul(smooth(x,f(.03),f(.05)),sub(one,smooth(x,f(.95),f(.97))));b=mul(smooth(y,f(.03),f(.05)),sub(one,smooth(y,f(.95),f(.97))))
        coverage(sub(one,mul(a,b)))
    elif kind in ('pulse','pulsestripe'):
        pulse=add(mul(sine(time()),f(.4)),f(.6));tint(mul(pulse,stripe(y)) if kind=='pulsestripe' else pulse)
    elif kind=='wipecoverage':coverage(smooth(sub(frac(time()),x),f(-.02),f(.02)))
    elif kind=='flowgrid':tint(mul(stripe(add(x,time())),stripe(y)))
    elif kind=='pulsering':coverage(sub(one,smooth(absolute(sub(radial(),mul(frac(time()),f(.7)))),f(.015),f(.06))))
    elif kind in ('rotatelayer','distortlayer','flipbook','pingpong'):
        t=time()
        if kind=='rotatelayer':
            co=op('CosOpNode',t);si=sine(t);dx=sub(x,f(.5));dy=sub(y,f(.5))
            u=add(sub(mul(dx,co),mul(dy,si)),f(.5));v=add(add(mul(dx,si),mul(dy,co)),f(.5))
            coord=add(mul(u,g.sw(g.v((1,0,0,0)),'xy')),mul(v,g.sw(g.v((0,1,0,0)),'xy')))
        elif kind=='distortlayer':
            warp=g.sw(g.texture('_DistortionMap','扰动纹理（线性）',uv,'gray'),'xy');coord=add(uv,mul(sub(warp,g.sw(g.v((.5,.5,0,0)),'xy')),f(.08,'_DistortionAmount','扰动幅度',max=.3)))
        elif kind=='flipbook':
            columns=f(4);frame=op('FloorOpNode',mul(frac(t),f(16)));col=sub(frame,mul(op('FloorOpNode',div(frame,columns)),columns));row=op('FloorOpNode',div(frame,columns))
            offset=add(mul(col,g.sw(g.v((1,0,0,0)),'xy')),mul(row,g.sw(g.v((0,1,0,0)),'xy')));coord=div(add(uv,offset),columns)
        else:coord=add(uv,mul(sine(t),g.sw(g.v((.15,0,0,0)),'xy')))
        layer=g.sw(g.texture('_EffectLayer','扩展动画纹理',coord),'xyz');output(('Color',),lerp(color,layer,f(.5,'_EffectLayerBlend','动画叠层混合')))
    elif kind.endswith('vertex'):
        pos=g.node('PosVertexDataNode');py=g.sw(pos,'y');px=g.sw(pos,'x');t=time();amp=f(.04,'_EffectAmplitude','扩展顶点幅度',max=.5)
        if kind=='fluttervertex':wave=mul(sine(add(mul(py,f(30)),mul(t,f(8)))),amp);direction=(0,0,1,0)
        elif kind=='ripplevertex':wave=mul(sine(sub(mul(op('LengthOpNode',g.sw(pos,'xz')),f(8)),t)),amp);direction=(0,1,0,0)
        elif kind=='bobvertex':wave=mul(sine(t),amp);direction=(0,1,0,0)
        elif kind=='bendvertex':wave=mul(mul(sat(py),sat(py)),mul(sine(t),amp));direction=(1,0,0,0)
        else:wave=mul(sine(add(mul(px,f(5)),t)),amp);direction=(0,0,1,0)
        offset=mul(g.sw(g.v(direction),'xyz'),wave)
        old=next((o for o in g.plan['outputs'] if o['masterPort']=='Vertex Offset'),None)
        if old:output(('Vertex Offset',),add((old['node'],old['port']),offset))
        else:g.output(offset,'Vertex Offset','ForwardBase' if g.pipeline=='BuiltIn' else '')
    else:raise ValueError(kind)
    # Keep all expressions in named functional groups, and retain original limitations.
    g.plan['shaderName']='ASELibrary/'+g.pipeline+'/'+c+'/'+title

def main():
    entries=[]
    for p in ('BuiltIn','URP','HDRP'):
        jobs=[]
        for c,recipes in RECIPES.items():
            for key,title,kind in recipes:
                g,notes=base.original(p,c);apply(g,c,kind,title)
                ident='effect-'+p+'-'+c+'-'+key;path=OUT/(ident+'.json');base.write(path,g.plan)
                jobs.append({'id':ident,'planPath':str(path),'output':'Assets/ASELibrary031/'+c+'/'+p+'/'+key+'_ASE.shader'})
                entries.append({'id':ident,'familyId':c+'-'+key,'title':title,'effect':title+'；'+kind,'pipeline':p,'category':c,'origin':'OriginalEffect',
                    'notes':notes+' 原创基础扩展，不是原素材转换或完整专用 BSDF。','plan':str(path.relative_to(ROOT)).replace('\\','/'),'recipe':kind})
        base.write(OUT/('jobs-'+p+'.json'),{'jobs':jobs})
    base.write(OUT/'entries.json',entries)
    print('Native plans',len(entries),'families',len(entries)//3,'(original extensions, not independent source conversions)')
if __name__=='__main__':main()
