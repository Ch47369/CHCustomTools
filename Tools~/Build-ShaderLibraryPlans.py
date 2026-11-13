"""Original editable material foundations; not claimed as conversions of reference projects.
ASE creates all graphs/metadata from these plans. No ASE source/metadata is copied here.
"""
from pathlib import Path
import json

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'.build~/LibraryPlans030'
LIT={'BuiltIn':'ed95fe726fd7b4644bb42f4d1ddd2bcd','URP':'94348b07e5e8bab40bd6c8a1e3df54cd','HDRP':'53b46d85872c5b24c8f4f0a1c3fe4c87'}
UNLIT={'BuiltIn':'0770190933193b94aaa3065e307002fa','URP':'2992e84f91cbeb14eab234972e07ea9d','HDRP':'7f5cb9c3ea6481f469fdd856555439ef'}
TITLES={'Skin':'皮肤微表面','Hair':'发卡覆盖','Eye':'虹膜瞳孔','Fabric':'织物基础','Hosiery':'丝袜覆盖与织纹','Water':'流动水面基础','Metal':'金属粗糙度','Stone':'岩石细节','Jade':'玉石透射基础','UI':'界面纹理','UIEffects':'界面流光','VFX':'溶解与边缘','UVAnimation':'双层UV流动','VertexAnimation':'顶点风摆'}

def write(p,o):p.parent.mkdir(parents=True,exist_ok=True);p.write_text(json.dumps(o,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')

class Graph:
    def __init__(self,pipeline,category,unlit=False):
        self.pipeline=pipeline;self.category=category;self.group='inputs';self.serial=0
        self.plan={'schemaVersion':1,'shaderName':'ASELibrary/'+pipeline+'/'+category+'/'+TITLES[category], 'pipeline':pipeline,'surface':'Unlit' if unlit else 'Lit','templateGuid':(UNLIT if unlit else LIT)[pipeline],
                   'nodes':[],'wires':[],'outputs':[],'masterSettings':[],'presentation':{'autoLayout':True,'addComments':True,'useRegisters':True,'longWireDistance':1600,'maxRegisters':32},'comments':[]}
    def phase(self,id,title,text):
        self.group=id;self.plan['comments'].append({'id':id,'title':title,'text':text})
    def node(self,type,**kw):
        self.serial+=1;n={'id':'n'+str(self.serial),'type':type,'group':self.group,'label':kw.get('displayName',type),'settings':[],'customInputs':[],**kw};self.plan['nodes'].append(n);return n['id'],'0'
    def wire(self,src,dst,port=0):self.plan['wires'].append({'from':src[0],'fromPort':str(src[1]),'to':dst[0],'toPort':str(port)})
    def op(self,type,*args,**kw):
        n=self.node(type,**kw)
        for i,a in enumerate(args):self.wire(a,n,i)
        return n
    def f(self,value,name=None,title=None,min=0,max=1):return self.node('RangedFloatNode',value=str(value),propertyName=name or '',displayName=title or name or '',propertyKind='Range' if name else 'Float',rangeMin=min,rangeMax=max)
    def v(self,value,name=None,title=None,color=False):
        vals=list(value)+[0]*4;return self.node('ColorNode' if color else 'Vector4Node',value='('+','.join(str(x) for x in vals[:4])+')',propertyName=name or '',displayName=title or name or '',propertyKind='Color' if color else 'Vector')
    def sw(self,a,mask):return self.op('SwizzleNode',a,swizzle=mask,outputType='FLOAT' if len(mask)==1 else 'FLOAT'+str(len(mask)))
    def add(self,a,b):return self.op('SimpleAddOpNode',a,b)
    def sub(self,a,b):return self.op('SimpleSubtractOpNode',a,b)
    def mul(self,a,b):return self.op('SimpleMultiplyOpNode',a,b)
    def div(self,a,b):return self.op('SimpleDivideOpNode',a,b)
    def lerp(self,a,b,t):return self.op('LerpOp',a,b,t)
    def uv(self):return self.node('TextureCoordinatesNode',settings=[{'name':'m_textureCoordChannel','value':'0'}])
    def texture(self,name,title,uv,default='white'):
        t=self.node('TexturePropertyNode',propertyName=name,displayName=title,propertyKind='2D',value='"'+default+'" {}',settings=[{'name':'attribute:NoScaleOffset','value':'true'}]);s=self.node('SamplerNode');self.wire(t,s,'Tex');self.wire(uv,s,'UV');return s
    def normal(self,sample,scale):return self.op('UnpackScaleNormalNode',sample,scale)
    def option(self,name,value):self.plan['masterSettings'].append({'name':'option:'+name,'value':value})
    def output(self,node,port,passname=''):self.plan['outputs'].append({'node':node[0],'port':node[1],'masterPort':port,'pass':passname})

def original(p,c):
    unlit=c in {'UI','UIEffects','VFX','UVAnimation'}
    g=Graph(p,c,unlit);g.phase('inputs','01 输入与资源','原创材质基础，不是樱花兔或网络素材的等价转换。基色按 sRGB 导入，遮罩按 Linear，法线按 NormalMap；需要按实际模型补齐贴图。')
    uv=g.uv();base=g.v((.65,.42,.32,1) if c=='Skin' else (.2,.45,.6,1), '_BaseColor','基色 / Base Color',True)
    if c in {'UI','UIEffects'}:
        g.plan['templateGuid']='eab467e6cd0b4d27ab8e9e434d8c30e3';tex=g.texture('_LibraryTex','图像纹理',uv);color=g.mul(tex,base)
        if c=='UIEffects':
            g.phase('effect','02 流光带','UV.x 与时间控制流光位置，带宽控制平滑边缘；模板保留顶点色、Tint、Stencil、矩形裁剪和 GUI 深度。')
            time=g.node('SimpleTimeNode');speed=g.f(.2,'_Speed','流光速度',min=-2,max=2)
            center=g.op('FractNode',g.mul(time,speed));distance=g.op('AbsOpNode',g.sub(g.sw(uv,'x'),center));width=g.f(.08,'_Width','流光带宽',min=.001,max=.4)
            band=g.op('SaturateNode',g.sub(g.f(1),g.div(distance,width)));glow=g.v((.7,.9,1,0),'_Shine','流光颜色',True);color=g.add(color,g.mul(glow,band))
        g.output(color,'Color','UI');return g, 'Canvas 基础；硬矩形裁剪，不提供软 RectMask2D 或字体 SDF。'
    g.phase('mapping','02 坐标与纹理','纹理对象靠近采样器；UV 动画在片元使用。细节频率和幅度需要按模型真实尺寸调节。')
    if c in {'Water','UVAnimation'}:
        time=g.node('SimpleTimeNode');speed=g.sw(g.v((.03,.015,0,0),'_FlowSpeed','流动速度'),'xy');shift=g.mul(time,speed);uv=g.add(uv,shift)
    tex=g.texture('_BaseMap','基色纹理',uv);color=g.mul(g.sw(tex,'xyz'),g.sw(base,'xyz'));alpha=g.mul((tex[0],'4'),g.sw(base,'w'))
    smooth=g.f(.45,'_Smoothness','光滑度');metal=g.f(1 if c=='Metal' else 0,'_Metallic','金属度');normal=None
    if not unlit:
        ntex=g.texture('_NormalMap','法线纹理',uv,'bump');strength=g.f(1,'_NormalScale','法线强度',max=3);normal=g.normal(ntex,strength)
    g.phase('material','03 材质计算','按独立参数计算材质响应；所有连线由 ASE 原生节点创建。下方注释说明本示例与完整专用材质的差距。')
    notes='原创基础示例；尚未和参考项目画面比较，也没有 GPU 基准。'
    if c=='Eye':
        center=g.sw(g.v((.5,.5,0,0),'_IrisCenter','虹膜中心'),'xy');dist=g.op('LengthOpNode',g.sub(uv,center));radius=g.f(.18,'_IrisRadius','虹膜半径',min=.01,max=.5)
        edge=g.f(.01,'_EdgeSoftness','遮罩边缘',min=.001,max=.1);iris=g.sub(g.f(1),g.op('SmoothstepOpNode',dist,radius,g.add(radius,edge)))
        iriscolor=g.sw(g.v((.05,.2,.12,1),'_IrisColor','虹膜颜色',True),'xyz');sclera=g.sw(g.v((.8,.78,.72,1),'_ScleraColor','巩膜颜色',True),'xyz');color=g.lerp(sclera,iriscolor,iris)
        pupil=g.f(.06,'_PupilRadius','瞳孔半径',min=.001,max=.2);pupilmask=g.sub(g.f(1),g.op('SmoothstepOpNode',dist,pupil,g.add(pupil,edge)));color=g.lerp(color,g.sw(g.v((0,0,0,1)),'xyz'),pupilmask);smooth=g.f(.9)
        notes='虹膜/瞳孔可编辑基础；没有角膜外壳、虹膜视差或专用 Eye BSDF，不是参考 Eye 图的替代品。'
    if c=='Hair':
        coverage=g.f(.5,'_Cutoff','发卡裁剪阈值');g.output(coverage,'Alpha Clip Threshold','ForwardOnly' if p=='HDRP' else 'ForwardBase' if p=='BuiltIn' else '')
        g.option('Alpha Clipping','Material Toggle' if p in ('HDRP','URP') else 'true');g.option('Double-Sided' if p=='HDRP' else 'Two Sided','Mirrored Normals' if p=='HDRP' else 'On')
        if p=='HDRP':g.plan['templateGuid']='e4fe21624ace6de4b9fbaabdda0c51de';g.option('Material Type','Approximate');g.option('Geometry Type','Card');g.output(g.v((0,1,0,0)),'Hair Strand Direction','ForwardOnly')
        else:notes='发卡覆盖与 PBR 基础；未实现 HDRP Hair 双叶/发丝散射，不表示跨管线毛发等价。'
    if c=='Fabric':
        detailuv=g.mul(uv,g.f(20,'_WeaveTiling','织纹密度',min=1,max=100));detail=g.texture('_WeaveNormal','织纹法线',detailuv,'bump');normal=g.op('BlendNormalsNode',normal,g.normal(detail,g.f(.35,'_WeaveStrength','织纹强度')))
        if p=='HDRP':g.plan['templateGuid']='41e04be03f2c20941bc749271be1c937';g.option('Material Type','Cotton Wool')
        else:notes='织纹法线与 PBR 基础；不等价于 HDRP Charlie/Sheen 或丝绸 BSDF。'
    if c=='Hosiery':
        g.phase('coverage','04 织纹与视角覆盖','覆盖率随掠射角增加；正交织纹仅为可编辑近似，不是微纤维物理散射。需独立丝袜外层网格，皮肤另用皮肤材质；检查交叠、排序与远距摩尔纹。')
        x=g.sw(uv,'x');y=g.sw(uv,'y');freq=g.f(120,'_WeaveFrequency','织纹频率',min=1,max=600)
        stripex=g.op('AbsOpNode',g.op('SinOpNode',g.mul(g.mul(x,freq),g.f(6.28318530718))));stripey=g.op('AbsOpNode',g.op('SinOpNode',g.mul(g.mul(y,freq),g.f(6.28318530718))))
        weave=g.mul(stripex,stripey);density=g.f(.45,'_Density','纤维覆盖密度');fresnel=g.node('FresnelNode');g.wire(g.f(3),fresnel,'Power')
        coverage=g.op('SaturateNode',g.add(density,g.mul(g.sub(g.f(1),density),fresnel)));alpha=g.mul(alpha,g.mul(coverage,g.lerp(g.f(.7),g.f(1),weave)));smooth=g.f(.65)
        g.option('Surface Type' if p=='HDRP' else 'Surface','Transparent');notes='丝袜覆盖与织纹近似；需要独立外层网格，未验证皮肤叠层、透明排序、拉伸与远距过滤。'
    if c in {'Skin','Jade'}:
        micro=g.texture('_MicroNormal','微法线',g.mul(uv,g.f(15,'_MicroTiling','微法线密度',min=1,max=100)),'bump');normal=g.op('BlendNormalsNode',normal,g.normal(micro,g.f(.2,'_MicroStrength','微法线强度')))
        if p=='HDRP':
            g.option('Material Type','Subsurface Scattering');g.option('  Transmission','true');g.output(g.f(1,'_SubsurfaceMask','次表面遮罩'),'Subsurface Mask');g.output(g.f(.5,'_Thickness','厚度'),'Thickness')
            g.output(g.node('DiffusionProfileNode',propertyName='_DiffusionProfile',displayName='扩散轮廓 / Diffusion Profile',propertyKind='DiffusionProfile'),'Diffusion Profile')
            notes='使用 HDRP SSS/Transmission 模板；仍需项目绑定实际 Diffusion Profile 并开启相机/帧设置，默认未绑定不代表散射已显示。'
        else:notes='肤色/微表面基础；无屏幕空间 SSS、扩散宿主或完整玉石体积散射。'
    if c=='Stone':
        detail=g.texture('_DetailNormal','岩石细节法线',g.mul(uv,g.f(8,'_DetailTiling','细节密度',min=1,max=80)),'bump');normal=g.op('BlendNormalsNode',normal,g.normal(detail,g.f(.5,'_DetailStrength','细节法线强度')));smooth=g.f(.2)
    if c=='VFX':
        noise=g.texture('_DissolveMap','溶解纹理（线性）',uv);threshold=g.f(.4,'_Dissolve','溶解进度');width=g.f(.04,'_EdgeWidth','溶解边缘宽度',min=.001,max=.2)
        mask=g.op('SmoothstepOpNode',(noise[0],'1'),threshold,g.add(threshold,width));edge=g.op('SaturateNode',g.sub(mask,g.op('SmoothstepOpNode',(noise[0],'1'),g.add(threshold,width),g.add(threshold,g.mul(width,g.f(2))))))
        color=g.add(color,g.mul(g.sw(g.v((1,.15,.02,1),'_EdgeColor','边缘颜色',True),'xyz'),edge));alpha=g.mul(alpha,mask);g.option('Surface Type' if p=='HDRP' else 'Surface','Transparent')
    if c=='VertexAnimation':
        g.phase('vertex','04 顶点风摆','在顶点阶段用物体位置与时间计算偏移；需网格细分。此示例不包含骨骼、布料模拟或完整风场，运动矢量需目标场景检查。')
        pos=g.node('PosVertexDataNode');time=g.node('SimpleTimeNode');phase=g.add(g.mul(g.sw(pos,'y'),g.f(2,'_WaveScale','空间频率',max=20)),g.mul(time,g.f(1,'_WindSpeed','风速',max=10)));wave=g.mul(g.op('SinOpNode',phase),g.f(.08,'_Amplitude','风摆幅度',max=.5));offset=g.mul(g.sw(g.v((1,0,0,0),'_WindDirection','物体空间风向'),'xyz'),wave);g.output(offset,'Vertex Offset','ForwardBase' if p=='BuiltIn' else '')
    if c=='Water':
        color=g.lerp(g.sw(g.v((.01,.12,.15,1),'_DeepTint','水色',True),'xyz'),color,g.f(.25));alpha=g.f(.65,'_Opacity','水面不透明度');smooth=g.f(.9)
        g.option('Surface Type' if p=='HDRP' else 'Surface','Transparent');notes='双层流动坐标水色基础，无场景深度、折射或模拟；完整 Built-in DeepWater 另列，不能视为 SRP 等价移植。'
    if c=='UVAnimation':
        layer=g.texture('_LayerMap','第二层纹理',g.sub(g.uv(),g.mul(g.node('SimpleTimeNode'),g.sw(g.v((.02,-.025,0,0),'_LayerSpeed','第二层速度'),'xy'))));color=g.lerp(color,g.sw(layer,'xyz'),g.f(.5,'_LayerBlend','双层混合'))
    g.phase('output','05 输出与验证',notes+' 图由 ASE 保存并重载后才允许入库；编译通过不代表参考画面等价。')
    main='ForwardBase' if p=='BuiltIn' and not unlit else ''
    if c in {'Hair','Fabric'} and p=='HDRP':main='ForwardOnly'
    g.output(color,'Color' if unlit else 'Albedo' if p=='BuiltIn' else 'Base Color',main)
    g.output(alpha,'Alpha',main)
    if not unlit:
        g.output(normal,'Normal',main);g.output(smooth,'Smoothness',main)
        if not (p=='HDRP' and c in {'Hair','Fabric','Skin','Jade'}):g.output(metal,'Metallic',main)
    if unlit and p in {'BuiltIn','URP'}:g.option('  Keep Alpha','true');g.option('Cast Shadows','false')
    return g,notes

def main():
    entries=[]
    for p in ['BuiltIn','URP','HDRP']:
        jobs=[]
        for c,title in TITLES.items():
            g,notes=original(p,c);id='original-'+p+'-'+c;path=OUT/(id+'.json');write(path,g.plan)
            jobs.append({'id':id,'planPath':str(path),'output':'Assets/ASELibrary030/'+c+'/'+p+'/'+c+'_ASE.shader'})
            entries.append({'id':id,'title':title,'pipeline':p,'category':c,'origin':'OriginalFoundation','notes':notes,'plan':str(path.relative_to(ROOT))})
        write(OUT/('jobs-'+p+'.json'),{'jobs':jobs})
    write(OUT/'entries.json',entries);print('Original plans:',len(entries),'(14 categories x 3 pipelines); no conversion-equivalence claim.')

if __name__=='__main__':main()
