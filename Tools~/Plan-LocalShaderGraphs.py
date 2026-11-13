"""Explicit, conservative Shader Graph -> native ASE plan adapter for inspected local graphs.
Produces ordinary plugin plans only. Unsupported models/options/nodes remain blocked.
Generated adaptations require source texture re-binding and visual validation.
"""
from pathlib import Path
import json,re,sys,importlib.util

ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('library_plans',Path(__file__).with_name('Build-ShaderLibraryPlans.py'));lib=importlib.util.module_from_spec(spec);spec.loader.exec_module(lib)
Graph=lib.Graph
OUT=ROOT/'.build~/LocalGraphPlans030'
DESC=ROOT/'.validation/UnityHDRP/LibraryBuildEvidence'
def write(p,v):lib.write(p,v)
def objects(text):
    dec=json.JSONDecoder();out=[];i=0
    while i<len(text):
        while i<len(text) and text[i].isspace():i+=1
        if i==len(text):break
        o,i=dec.raw_decode(text,i);out.append(o)
    return out
def short(n):return n.get('m_Type','').split('.')[-1]
def vector(v):
    if isinstance(v,list):return v
    if isinstance(v,dict):return [v[k] for k in ('x','y','z','w') if k in v] or [v[k] for k in ('r','g','b','a') if k in v]
    return [float(v)] if v is not None else [0.0]
class Blocked(Exception):pass

def phase_groups(plan):
    # Preserve functional groups while splitting only re-entries along the DAG.
    # Every edge between distinct groups advances the phase, so ASE layout does
    # not need to split the whole graph into hundreds of single-node comments.
    nodes={n['id']:n for n in plan['nodes']};parents={id:[] for id in nodes};levels={};active=set()
    for wire in plan['wires']:parents[wire['to']].append(wire['from'])
    def level(id):
        if id in levels:return levels[id]
        if id in active:raise Blocked('Cyclic presentation dependency.')
        active.add(id);value=max((level(p)+(nodes[p]['group']!=nodes[id]['group']) for p in parents[id]),default=0);active.remove(id);levels[id]=value;return value
    descriptions={c['id']:c for c in plan['comments']};comments={}
    for id in nodes:level(id)
    for id,node in nodes.items():
        phase=level(id);group=node['group'];key=group+'-phase-'+str(phase)
        description=descriptions.get(group,{'title':'原生运算与采样','text':'按数据依赖连接的原生节点。资源与原场景画面另行核对。'})
        node['group']=key
        comments.setdefault(key,{'id':key,'title':description['title']+' · 阶段 '+str(phase+1),'text':description['text']})
    plan['comments']=list(comments.values())

class Convert:
    def __init__(self,row):
        self.row=row;self.obs=objects((ROOT/row['cachedSource']).read_text(encoding='utf-8-sig'));self.root=self.obs[0];self.ids={n.get('m_ObjectId'):n for n in self.obs};self.cache={};self.properties={};self.assets=[];self.active=set()
        if 'm_SerializableNodes' in self.root:raise Blocked('Legacy master-node graph needs version migration and a model adapter.')
        self.nodes=[self.ids[x['m_Id']] for x in self.root.get('m_Nodes',[])];self.edges={(e['m_InputSlot']['m_Node']['m_Id'],e['m_InputSlot']['m_SlotId']):(e['m_OutputSlot']['m_Node']['m_Id'],e['m_OutputSlot']['m_SlotId']) for e in self.root.get('m_Edges',[])}
        if self.root.get('m_Keywords'):raise Blocked('Keyword definitions and branches have not been mapped.')
        targets=[self.ids[x['m_Id']] for x in self.root.get('m_ActiveTargets',[])];target=next((t for t in targets if 'HighDefinition' in t.get('m_Type','')),None)
        if not target:raise Blocked('This adapter requires an explicit HDRP active target.')
        self.target=short(self.ids[target['m_ActiveSubTarget']['m_Id']]);self.data={};self.inactive=[]
        # Official HDRP 14 HDTarget.GetDataOfType<T> uses FirstOrDefault; preserve first duplicate.
        for d in target.get('m_Datas',[]):
            o=self.ids[d['m_Id']];self.data.setdefault(short(o),o)
        names={'HDLitSubTarget':lib.LIT['HDRP'],'HDUnlitSubTarget':lib.UNLIT['HDRP'],'HairSubTarget':'e4fe21624ace6de4b9fbaabdda0c51de','FabricSubTarget':'41e04be03f2c20941bc749271be1c937'}
        if self.target not in names:raise Blocked('No equivalent ASE template adapter for '+self.target+'; model not downgraded.')
        category=next((c for c in row['categories'] if c in lib.TITLES),'Metal')
        self.g=Graph('HDRP',category,self.target=='HDUnlitSubTarget');self.g.plan['templateGuid']=names[self.target];self.g.plan['shaderName']='ASELibrary/HDRP/LocalAdaptations/'+Path(row['path']).stem+'_'+row['sha256'][:8]
        self.g.phase('properties','01 原图属性与资源','按原 Shader Graph 属性名建立 ASE 原生参数；外部纹理默认 GUID 单独列在依赖清单，未绑定资源与原场景画面尚未验证。')
        self.description=json.loads((DESC/('template-'+names[self.target]+'.json')).read_text(encoding='utf-8-sig'))['description'];self.choices={x['name'][7:]:x['value'].split('|') for x in self.description['options']}
        self.settings()
    def option(self,name,value,required=True):
        if name not in self.choices or value not in self.choices[name]:
            if required:raise Blocked('Template option unavailable: '+name+'='+value)
            return
        # no duplicate settings; order is intentional for dependent ASE option actions.
        self.g.option(name,value)
    def settings(self):
        s=self.data.get('SystemData',{});b=self.data.get('BuiltinData',{});l=self.data.get('LightingData',{})
        for key in ['m_Tessellation','m_DOTSInstancing','m_CustomVelocity']:
            if s.get(key):raise Blocked('Unadapted system feature '+key)
        for key in ['m_Distortion','m_AddPrecomputedVelocity','m_AlphaToMask','m_ConservativeDepthOffset']:
            if b.get(key):raise Blocked('Unadapted built-in feature '+key)
        if s.get('m_SortPriority',0)!=0:raise Blocked('Transparent queue priority needs explicit render-state adapter.')
        transparent=s.get('m_SurfaceType',0)==1;self.alpha=bool(s.get('m_AlphaTest'));self.subsurface=False
        self.option('Surface Type','Transparent' if transparent else 'Opaque')
        if transparent:
            blend=s.get('m_BlendMode',0)
            if blend!=0:raise Blocked('Non-alpha transparent blend requires reviewed target mapping.')
            if s.get('m_RenderingPass',4) not in (4,):raise Blocked('Non-default transparent rendering pass requires review.')
            if self.target=='FabricSubTarget' and b.get('m_BackThenFrontRendering'):raise Blocked('Fabric back-then-front rendering not exposed by installed ASE template.')
            for key,name in [('m_BackThenFrontRendering','  Back Then Front Rendering'),('m_TransparentDepthPrepass','  Transparent Depth Prepass'),('m_TransparentDepthPostpass','  Transparent Depth Postpass'),('m_TransparentWritesMotionVec','  Transparent Writes Motion Vectors')]:
                if name in self.choices:self.option(name,str(bool(b.get(key,False))).lower())
                elif b.get(key):raise Blocked('Missing transparent feature '+key)
            self.option('  ZWrite' if self.target=='HDLitSubTarget' else '  Depth Write',str(bool(s.get('m_ZWrite'))).lower())
            self.option('  Z Test' if self.target=='HDLitSubTarget' else '  Depth Test',{0:'Disabled',1:'Never',2:'Less',3:'Equal',4:'Less Equal',5:'Greater',6:'Not Equal',7:'Greater Equal',8:'Always'}[s.get('m_ZTest',4)])
            if self.target=='HDUnlitSubTarget':self.option('  Blending Mode','Alpha');self.option('  Receive Fog',str(bool(b.get('m_TransparencyFog',True))).lower())
        ds=s.get('m_DoubleSidedMode',0);self.option('Double-Sided',str(ds!=0).lower() if self.target=='HDUnlitSubTarget' else ['Disabled','Enabled','Flipped Normals','Mirrored Normals'][ds])
        self.option('Alpha Clipping','Material Toggle' if self.alpha else 'Force Off')
        self.option('  Use Shadow Threshold','Material Toggle' if b.get('m_AlphaTestShadow') else 'Force Off')
        if self.target=='HDLitSubTarget':
            d=self.data.get('HDLitData',{});model=d.get('m_MaterialType',0);self.subsurface=model==1
            if d.get('m_ClearCoat') or d.get('m_RayTracing') or d.get('m_RefractionModel'):raise Blocked('Coat/ray-tracing/refraction material extension requires a dedicated adapter.')
            self.option('Material Type',{0:'Standard',1:'Subsurface Scattering',2:'Anisotropy',3:'Iridescence',4:'Specular Color',5:'Translucent'}[model])
            self.option('  Energy Conserving Specular',str(bool(d.get('m_EnergyConservingSpecular',True))).lower())
            if model in (1,5):self.option('  Transmission',str(bool(d.get('m_SSSTransmission',True))).lower())
        if self.target=='FabricSubTarget':
            d=self.data.get('FabricData',{});self.subsurface=bool(d.get('m_SubsurfaceScattering'));self.option('Material Type','Silk' if d.get('m_MaterialType') else 'Cotton Wool');self.option('Transmission',str(bool(d.get('m_Transmission'))).lower());self.option('  Subsurface Scattering',str(self.subsurface).lower());self.option('Energy Conserving Specular',str(bool(d.get('m_EnergyConservingSpecular',True))).lower())
        if self.target=='HairSubTarget':
            d=self.data.get('HairData',{});
            if d.get('m_MaterialType',0)!=0:raise Blocked('Physical strand hair host/scattering adapter required.')
            self.option('Material Type','Approximate')
            # In the inspected ASE 1.9.9.13 template Strands + Approximate adds
            # _USE_LIGHT_FACING_NORMAL while disabling advanced scattering. It
            # does not generate geometry. This matches this source boolean.
            self.option('Geometry Type','Strands' if d.get('m_UseLightFacingNormal') else 'Card')
            if d.get('m_UseLightFacingNormal'):self.option('  Scattering Mode','Approximate')
        if l:
            if l.get('m_NormalDropOffSpace',0)!=0:raise Blocked('Non-tangent normal dropoff requires an explicit source-space adapter.')
            if l.get('m_OverrideBakedGI'):raise Blocked('Baked GI override outputs need a dedicated mapping.')
            name='  Blend Preserves Specular' if self.target=='FabricSubTarget' else '  Preserve Specular Lighting' if self.target=='HairSubTarget' else '    Blend Preserves Specular'
            if transparent:self.option(name,str(bool(l.get('m_BlendPreserveSpecular',True))).lower())
            self.option('Receive Decals',('Material Toggle' if l.get('m_ReceiveDecals',True) else 'Force Off') if self.target=='HDLitSubTarget' else str(bool(l.get('m_ReceiveDecals',True))).lower())
            self.option('Receives SSR' if self.target=='FabricSubTarget' else 'Receive SSR',str(bool(l.get('m_ReceiveSSR',True))).lower())
            mode=l.get('m_SpecularOcclusionMode',0);self.option('Specular Occlusion Mode',{0:'Off',1:'From AO',2:'From AO And Bent Normal',3:'Custom'}[mode])
            if l.get('m_SpecularAA'):raise Blocked('Specular AA thresholds require explicit output mapping.')
        if b.get('m_DepthOffset'):self.option('  Depth Offset' if self.target=='HDLitSubTarget' else 'Depth Offset','true')
        if b.get('m_SupportLodCrossFade') or s.get('m_SupportLodCrossFade'):self.option('LOD CrossFade','true')
    def slots(self,n):return [self.ids[s['m_Id']] for s in n.get('m_Slots',[])]
    def slot(self,n,id):return next(s for s in self.slots(n) if s['m_Id']==id)
    def slotwidth(self,n,id,trail=None):
        trail=set() if trail is None else trail
        key=(n['m_ObjectId'],id)
        if key in trail:raise Blocked('Cyclic slot type resolution.')
        trail=trail|{key};s=self.slot(n,id);typ=short(s)
        if typ in ('DynamicVectorMaterialSlot','DynamicValueMaterialSlot'):
            widths=[]
            for inp in self.slots(n):
                if inp.get('m_SlotType')==0 and short(inp)==typ and (n['m_ObjectId'],inp['m_Id']) in self.edges:
                    src,port=self.edges[n['m_ObjectId'],inp['m_Id']];widths.append(self.slotwidth(self.ids[src],port,trail))
            # Shader Graph 14 selects minimum vector width excluding scalar promotion.
            return min([w for w in widths if w>1],default=1)
        for prefix,width in [('Vector1',1),('Boolean',1),('Vector2',2),('UV',2),('Vector3',3),('Normal',3),('Tangent',3),('Position',3),('ViewDirection',3),('Vector4',4),('ColorRGB',3),('ColorRGBA',4)]:
            if typ.startswith(prefix):return width
        raise Blocked('Slot dimension adapter unavailable for '+typ)
    def const(self,value,width=None):
        v=vector(value)
        if not v:raise Blocked('Dynamic matrix-backed value needs resolved Shader Graph slot dimensions; not guessed as a vector.')
        if width:v=(v+[0]*width)[:width]
        if len(v)==1:return self.g.f(v[0])
        node=self.g.v(v);return self.g.sw(node,'xyzw'[:len(v)]) if len(v)<4 else node
    def input(self,n,id,width=None):
        key=(n['m_ObjectId'],id)
        slot=self.slot(n,id);typ=short(slot)
        if typ in ('DynamicValueMaterialSlot','DynamicVectorMaterialSlot'):width=width or self.slotwidth(n,id)
        if key in self.edges:
            src,port=self.edges[key];value=self.output(src,port)
            if width:
                before=self.slotwidth(self.ids[src],port)
                if before>width:value=self.g.sw(value,'xyzw'[:width])
            return value
        if typ=='UVMaterialSlot':
            return self.g.node('TextureCoordinatesNode',settings=[{'name':'m_textureCoordChannel','value':str(slot.get('m_Channel',0))}])
        if 'Texture' in typ or 'Sampler' in typ:raise Blocked('Unbound implicit resource slot '+typ)
        value=slot.get('m_Value',slot.get('m_DefaultValue',0))
        if typ=='DynamicValueMaterialSlot':
            if not isinstance(value,dict) or width is None:raise Blocked('Matrix multiply is not adapted.')
            value=[value['e0'+str(i)] for i in range(width)]
        return self.const(value,width)
    def prop(self,p):
        if p['m_ObjectId'] in self.properties:return self.properties[p['m_ObjectId']]
        name=p.get('m_OverrideReferenceName') or p.get('m_DefaultReferenceName');type=short(p);kw={'propertyName':name,'displayName':p.get('m_Name',name)}
        if not name or not re.match(r'^[A-Za-z_]\w*$',name):raise Blocked('Property reference name invalid or unavailable.')
        if p.get('m_Hidden'):kw['settings']=[{'name':'attribute:HideInInspector','value':'true'}]
        if type=='Texture2DShaderProperty':
            defaults={0:'white',1:'black',2:'gray',3:'bump',4:'linearGrey',5:'red'}
            default=defaults.get(p.get('m_DefaultType',0))
            if default is None:raise Blocked('Unknown source texture default type.')
            if not p.get('useTilingAndOffset',False):kw.setdefault('settings',[]).append({'name':'attribute:NoScaleOffset','value':'true'})
            value=p.get('m_Value',{});guid=value.get('m_Guid','')
            serialized=value.get('m_SerializedTexture','')
            if serialized:
                try:guid=json.loads(serialized).get('texture',{}).get('guid',guid)
                except Exception:pass
            if guid:self.assets.append({'property':name,'guid':guid,'status':'RequiresSourceAssetBinding'})
            n=self.g.node('TexturePropertyNode',propertyKind='2D',value='"'+default+'" {}',**kw)
        elif type in ('Vector1ShaderProperty','BooleanShaderProperty'):
            n=self.g.node('RangedFloatNode',propertyKind='Range' if p.get('m_FloatType')==1 else 'Float',value=str(float(p.get('m_Value',0))),rangeMin=p.get('m_RangeValues',{}).get('x',0),rangeMax=p.get('m_RangeValues',{}).get('y',1),**kw)
        elif type in ('ColorShaderProperty','Vector2ShaderProperty','Vector3ShaderProperty','Vector4ShaderProperty'):
            values=vector(p.get('m_Value',{}));values=(values+[0]*4)[:4];n=self.g.node('ColorNode' if type=='ColorShaderProperty' else 'Vector4Node',propertyKind='Color' if type=='ColorShaderProperty' else 'Vector',value='('+','.join(str(v) for v in values)+')',**kw)
            if type in ('Vector2ShaderProperty','Vector3ShaderProperty'):n=self.g.sw(n,'xy' if type=='Vector2ShaderProperty' else 'xyz')
        else:raise Blocked('Property type not adapted: '+type)
        self.properties[p['m_ObjectId']]=n;return n
    def output(self,id,port):
        key=(id,port)
        if key in self.cache:return self.cache[key]
        if key in self.active:raise Blocked('Cyclic source graph.')
        self.active.add(key);n=self.ids[id];type=short(n);g=self.g
        old=g.group;group=n.get('m_Group',{}).get('m_Id','');g.group='source-'+group if group else 'math'
        if type=='PropertyNode':out=self.prop(self.ids[n['m_Property']['m_Id']])
        elif type in ('Vector1Node','Vector2Node','Vector3Node','Vector4Node','BooleanNode','ColorNode'):
            inputs=[s for s in self.slots(n) if s.get('m_SlotType')==0]
            if inputs and any((id,s['m_Id']) in self.edges for s in inputs):
                out=g.node('DynamicAppendNode',outputType='FLOAT'+str(len(inputs)))
                for j,s in enumerate(inputs):g.wire(self.input(n,s['m_Id'],1),out,j)
            else:out=self.const(n.get('m_Value',0))
        elif type=='UVNode':out=g.node('TextureCoordinatesNode',settings=[{'name':'m_textureCoordChannel','value':str(n.get('m_OutputChannel',0))}])
        elif type=='VertexColorNode':out=g.node('VertexColorNode')
        elif type=='ViewDirectionNode':out=g.node('ViewDirInputsCoordNode',settings=[{'name':'m_viewDirSpace','value':{0:'Object',1:'View',2:'World',3:'Tangent'}[n.get('m_Space',2)]}])
        elif type=='NormalizeNode':out=g.op('NormalizeNode',self.input(n,0))
        elif type=='SampleTexture2DNode':
            if n.get('m_MipSamplingMode',0)!=0 or n.get('m_NormalMapSpace',0)!=0:raise Blocked('Non-default mip or object-space normal sampler not adapted.')
            if (id,3) in self.edges:raise Blocked('Custom sampler state not adapted.')
            sampler=g.node('SamplerNode');g.wire(self.input(n,1),sampler,'Tex');g.wire(self.input(n,2),sampler,'UV')
            if n.get('m_TextureType')==1:
                out=g.normal(sampler,g.f(1))
                if port in (4,5,6):out=g.sw(out,{4:'x',5:'y',6:'z'}[port])
                elif port==7:out=g.f(1)
            else:out=(sampler[0],str({0:0,4:1,5:2,6:3,7:4}[port]))
        elif type=='SplitNode':out=g.sw(self.input(n,0),{1:'x',2:'y',3:'z',4:'w'}[port])
        elif type=='TilingAndOffsetNode':out=g.add(g.mul(self.input(n,0),self.input(n,1,2)),self.input(n,2,2))
        elif type=='BranchNode':
            predicate=self.input(n,0,1);cmp=g.node('ConditionalIfNode');g.wire(predicate,cmp,0);g.wire(g.f(0),cmp,1);g.wire(self.input(n,1),cmp,2);g.wire(self.input(n,2),cmp,3);g.wire(self.input(n,1),cmp,4);out=cmp
        elif type=='NormalStrengthNode':
            value=self.input(n,0,3);strength=self.input(n,1,1);xy=g.mul(g.sw(value,'xy'),strength);z=g.lerp(g.f(1),g.sw(value,'z'),g.op('SaturateNode',strength));out=g.node('DynamicAppendNode',outputType='FLOAT3');g.wire(g.sw(xy,'x'),out,0);g.wire(g.sw(xy,'y'),out,1);g.wire(z,out,2)
        elif type=='NormalBlendNode':
            if n.get('m_BlendMode',0)!=0:raise Blocked('Reoriented normal blend needs reviewed mode mapping.')
            out=g.op('BlendNormalsNode',self.input(n,0,3),self.input(n,1,3))
        elif type=='BlendNode':
            a=self.input(n,0);b=self.input(n,1);mode=n.get('m_BlendMode',15)
            if mode==1:blended=g.op('SimpleMinOpNode',a,b)
            elif mode==10:blended=g.add(a,b)
            elif mode==13:blended=g.mul(a,b)
            elif mode==15:
                # Overlay formula with component-wise step; no vector If predicate.
                low=g.mul(g.f(2),g.mul(a,b));high=g.sub(g.f(1),g.mul(g.f(2),g.mul(g.sub(g.f(1),a),g.sub(g.f(1),b))))
                blended=g.lerp(low,high,g.op('StepOpNode',g.f(.5),a))
            else:raise Blocked('Blend mode needs explicit semantic adapter: '+str(mode))
            out=g.lerp(a,blended,self.input(n,3,1))
        elif type=='SaturationNode':
            value=self.input(n,0,3);luma=g.op('DotProductOpNode',value,self.const([.2126729,.7151522,.0721750]));out=g.add(luma,g.mul(self.input(n,1,1),g.sub(value,luma)))
        elif type=='FresnelNode':
            if any((id,p) not in self.edges for p in (0,1)):raise Blocked('Implicit bound Fresnel normal/view slots need explicit coordinate-space adapters.')
            normal=self.input(n,0,3);view=self.input(n,1,3)
            out=g.op('PowerNode',g.sub(g.f(1),g.op('SaturateNode',g.op('DotProductOpNode',g.op('NormalizeNode',normal),g.op('NormalizeNode',view)))),self.input(n,2,1))
        elif type in ('AddNode','SubtractNode','MultiplyNode','DivideNode','LerpNode','PowerNode','MaximumNode','MinimumNode','DotProductNode','ClampNode','SaturateNode','OneMinusNode','NegateNode','AbsoluteNode','NormalizeNode','SquareRootNode','SineNode','FractionNode','SmoothstepNode','StepNode'):
            mapping={'AddNode':'SimpleAddOpNode','SubtractNode':'SimpleSubtractOpNode','MultiplyNode':'SimpleMultiplyOpNode','DivideNode':'SimpleDivideOpNode','LerpNode':'LerpOp','PowerNode':'PowerNode','MaximumNode':'SimpleMaxOpNode','MinimumNode':'SimpleMinOpNode','DotProductNode':'DotProductOpNode','ClampNode':'ClampOpNode','SaturateNode':'SaturateNode','AbsoluteNode':'AbsOpNode','NormalizeNode':'NormalizeNode','SquareRootNode':'SqrtOpNode','SineNode':'SinOpNode','FractionNode':'FractNode','SmoothstepNode':'SmoothstepOpNode','StepNode':'StepOpNode'}
            args=[self.input(n,s['m_Id']) for s in self.slots(n) if s.get('m_SlotType')==0]
            if type=='OneMinusNode':out=g.sub(g.f(1),args[0])
            elif type=='NegateNode':out=g.mul(g.f(-1),args[0])
            elif type=='SmoothstepNode':out=g.op(mapping[type],args[2],args[0],args[1])
            else:out=g.op(mapping[type],*args)
        elif type=='PreviewNode':out=self.input(n,0)
        elif type=='TimeNode':out=(g.node('SimpleTimeNode')[0],str({0:0,1:1,2:2,3:3,4:4}[port]))
        else:raise Blocked('Native semantic adapter not implemented for '+type)
        g.group=old;self.active.remove(key);self.cache[key]=out;return out
    def run(self):
        g=self.g;mapping={'BaseColor':'Base Color','NormalTS':'Normal','BentNormal':'Bent Normal','Smoothness':'Smoothness','Occlusion':'Occlusion','Alpha':'Alpha','AlphaClipThreshold':'Alpha Clip Threshold','Emission':'Emission','Metallic':'Metallic','Specular':'Specular','SubsurfaceMask':'Subsurface Mask','Thickness':'Thickness','DiffusionProfileHash':'Diffusion Profile','Anisotropy':'Anisotropy','TangentTS':'Tangent','DepthOffset':'Depth Offset','AlphaClipThresholdShadow':'Alpha Clip Threshold Shadow','AlphaClipThresholdDepthPrepass':'Alpha Clip Threshold Depth Prepass','AlphaClipThresholdDepthPostpass':'Alpha Clip Threshold Depth Postpass','SpecularOcclusion':'Specular Occlusion'}
        if self.target=='HDUnlitSubTarget':mapping={'BaseColor':'Color','Alpha':'Alpha','AlphaClipThreshold':'Alpha Clip Threshold','Emission':'Emission'}
        if self.target=='HairSubTarget':mapping.update({'HairStrandDirection':'Hair Strand Direction','Transmittance':'Transmittance','RimTransmissionIntensity':'Rim Transmission Intensity','SpecularTint':'Specular Tint','SpecularShift':'Specular Shift','SecondarySpecularTint':'Secondary Specular Tint','SecondarySmoothness':'Secondary Smoothness','SecondarySpecularShift':'Secondary Specular Shift'})
        main='ForwardOnly' if self.target in ('FabricSubTarget','HairSubTarget') else ''
        for n in self.nodes:
            if short(n)!='BlockNode':continue
            desc=n.get('m_SerializedDescriptor','');name=desc.split('.')[-1];connected=(n['m_ObjectId'],0) in self.edges
            if desc.startswith('VertexDescription.'):
                if connected:raise Blocked('Connected vertex stage '+desc+' needs reviewed absolute/relative and normal/tangent mapping.')
                continue
            if name.startswith('AlphaClipThreshold') and not self.alpha:continue
            if name not in mapping:
                if connected:raise Blocked('Unmapped active output '+desc)
                continue
            if not connected and name in ('BentNormal','TangentTS','Anisotropy','SpecularOcclusion','DepthOffset'):continue
            if not self.subsurface and name in ('DiffusionProfileHash','SubsurfaceMask','Thickness') and not connected:continue
            if name=='DiffusionProfileHash' and connected:raise Blocked('Diffusion Profile asset/hash binding requires a dedicated adapter; not replaced with an arbitrary float.')
            inactive=(self.target=='FabricSubTarget' and name=='Thickness' and not self.data.get('FabricData',{}).get('m_Transmission'))
            if self.target=='HDLitSubTarget':
                model=self.data.get('HDLitData',{}).get('m_MaterialType',0)
                if name=='Specular' and model!=4:inactive=True
                if name=='Metallic' and model==4:inactive=True
            if name in ('AlphaClipThresholdDepthPrepass','AlphaClipThresholdDepthPostpass'):
                builtin=self.data.get('BuiltinData',{});inactive=not(self.data.get('SystemData',{}).get('m_SurfaceType')==1 and builtin.get('m_TransparentDepthPrepass' if name.endswith('Prepass') else 'm_TransparentDepthPostpass'))
            if inactive:
                value=self.input(n,0);self.inactive.append({'descriptor':desc,'connected':connected,'retainedNode':value[0],'reason':'Source render feature disabled; preserved as an unconnected native branch.'})
                continue
            targetpass=main
            # ASE exposes transparent threshold ports on the main ForwardOnly master;
            # its linked depth passes consume those values internally.
            g.output(self.input(n,0),mapping[name],targetpass)
        # Retain even unused blackboard properties; non-texture property nodes may be shared by identity.
        for p in self.root.get('m_Properties',[]):self.prop(self.ids[p['m_Id']])
        groups=[(x['m_Id'],self.ids[x['m_Id']]) for x in self.root.get('m_GroupDatas',self.root.get('m_Groups',[]))]
        for id,data in groups:g.plan['comments'].append({'id':'source-'+id,'title':'原图功能区 · '+data.get('m_Title',''),'text':'来自原 Shader Graph 的功能分组。按依赖重新排列，原始运算连线、参数和阶段须按转换报告核对；外部资源待绑定。'})
        g.plan['comments'].append({'id':'math','title':'02 原生运算与采样','text':'用 ASE 原生数学/纹理节点重建已适配分支。默认资源、灯光环境、帧设置和原场景画面另行验证；编译通过不代表效果等价。'})
        phase_groups(g.plan)
        return g.plan,self.assets

def main():
    m=json.loads((ROOT/'.build~/LocalShaderGraphs/manifest.json').read_text(encoding='utf-8'));unique={r['sha256']:r for r in m['rows'] if r['kind']=='shadergraph'};rows=[];jobs=[]
    for sha,row in unique.items():
        result={'sha256':sha,'path':row['path'],'categories':row['categories'],'status':'RequiresAdapter','blockers':[],'assetBindings':[]}
        try:
            c=Convert(row);plan,assets=c.run();id='local-HDRP-'+sha[:12];path=OUT/(id+'.json');write(path,plan)
            jobs.append({'id':id,'planPath':str(path),'output':'Assets/ASELibrary030/LocalAdaptations/HDRP/'+Path(row['path']).stem+'_'+sha[:8]+'_ASE.shader'})
            result.update(status='PlannedAdaptation',id=id,assetBindings=assets,inactiveOutputs=c.inactive,plan=str(path.relative_to(ROOT)),sourceConversionComplete=False,visualComparisonPassed=False)
        except Exception as e:result['blockers'].append(str(e))
        rows.append(result)
    write(OUT/'jobs-HDRP.json',{'jobs':jobs});write(ROOT/'Documentation~/Evidence/LocalLibrary030/local-adaptation-plans.json',{'rows':rows,'plannedCount':len(jobs),'generatedCount':0,'note':'A plan is not a generated graph; all external source assets and visual equivalence remain unvalidated.'})
    print('Local graphs:',len(rows),'planned adaptations:',len(jobs),'blocked:',len(rows)-len(jobs))

if __name__=='__main__':main()
