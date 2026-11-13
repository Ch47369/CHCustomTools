"""Audit same-source pipeline variants independently of artifact/file counts.

This tool reads native plans and cached source data, never executes reference code.
Mapped is a reviewed feature mapping, not a rendered-equivalence claim.
"""
from pathlib import Path
from collections import defaultdict, Counter
import importlib.util, json, hashlib

ROOT=Path(__file__).resolve().parents[1]
E=ROOT/'Documentation~/Evidence/CrossPipeline032'
PIPES=('BuiltIn','URP','HDRP')

def load_module(name,file):
    spec=importlib.util.spec_from_file_location(name,ROOT/'Tools~'/file)
    module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module);return module

def read(path):return json.loads((ROOT/path).read_text(encoding='utf-8-sig'))
def write(path,data):
    path=ROOT/path;path.parent.mkdir(parents=True,exist_ok=True)
    path.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')

def computation(plan):
    """Canonical reachable computations, ignoring node IDs and presentation.

    Keep port IDs, property identity/defaults, sampler/coordinate settings and
    vertex vs fragment output identities. It does NOT compare BSDF templates.
    ScreenColor's inverse exposure is reviewed separately as a host mapping.
    """
    nodes={n['id']:n for n in plan['nodes']};incoming=defaultdict(list);cache={}
    for w in plan['wires']:incoming[w['to']].append(w)
    def signature(ident):
        if ident in cache:return cache[ident]
        n=nodes[ident]
        value={k:v for k,v in n.items() if k not in ('id','group','label','displayName','position','settings') and v not in ('',None,[])}
        value['settings']=[s for s in n.get('settings',[]) if not(n['type']=='ScreenColorNode' and s['name']=='m_exposure')]
        value['inputs']=sorted([(w['toPort'],w['fromPort'],signature(w['from'])) for w in incoming[ident]])
        result=hashlib.sha256(json.dumps(value,sort_keys=True,ensure_ascii=True).encode()).hexdigest();cache[ident]=result;return result
    aliases={'Albedo':'Base Color','Normal WS':'Normal','World Normal':'Normal'}
    return {aliases.get(o['masterPort'],o['masterPort']):{'port':o['port'],'hash':signature(o['node'])} for o in plan['outputs']}

def local_gaps(convert,pipeline):
    if pipeline=='HDRP':return []
    d=convert.data;s=d.get('SystemData',{});b=d.get('BuiltinData',{});l=d.get('LightingData',{});gaps=[]
    if convert.target=='HairSubTarget':gaps.append('缺少与原 HDRP Hair 双高光叶、发丝方向、透射及散射模型对应的目标管线适配器；不能用普通 Lit 代替。')
    if convert.target=='FabricSubTarget':
        gaps.append('缺少原 Fabric Cotton/Wool 的 Charlie/Sheen BSDF 适配器。')
        if d.get('FabricData',{}).get('m_Transmission'):gaps.append('原布料 Thickness/Transmission 未实现对应透射光照。')
    model=d.get('HDLitData',{}).get('m_MaterialType',0)
    if convert.target=='HDLitSubTarget' and model==1:gaps.append('原图使用 SSS/Transmission 和 Diffusion Profile；目标缺少扩散宿主及厚度散射实现。')
    if l.get('m_ReceiveSSR',True) and l:gaps.append('原图启用 Receive SSR；目标尚未提供并验证对应屏幕反射宿主。')
    if l.get('m_ReceiveDecals',True) and l:gaps.append('原图接收 Decals；'+('Built-in 尚无对应贴花宿主。' if pipeline=='BuiltIn' else 'URP Decal Renderer Feature 与图的接收路径尚未接入验证。'))
    if l.get('m_SpecularOcclusionMode',0):gaps.append('原图 Specular Occlusion 模式尚未显式映射。')
    if b.get('m_DepthOffset'):gaps.append('原图 Depth Offset 未映射到深度/阴影/透明 Pass。')
    if b.get('m_AlphaTestShadow'):gaps.append('原图独立阴影裁剪阈值与透明裁剪需目标模板验证。')
    if b.get('m_TransparentDepthPostpass'):gaps.append('原图透明深度后处理 Pass 尚未移植。')
    if b.get('m_TransparentDepthPrepass'):gaps.append('原图透明深度预处理 Pass 尚未移植。')
    if s.get('m_DoubleSidedMode',0) in (2,3):gaps.append('原图双面法线翻转/镜像及发丝光照朝向尚未验证。')
    if convert.target=='HDUnlitSubTarget':
        gaps.append('HDRP 透明雾与材质可切换裁剪尚未映射到目标 Unlit 模板；保留原 Alpha 与阈值。')
    if not gaps:gaps.append('原图全部输出和渲染状态尚未提交目标模板、保存重载和编译验证。')
    return gaps

def main():
    global E
    catalog=read('Editor/Resources/ASEShaderLibraryCatalog.json')
    if catalog['version']=='0.3.3':E=ROOT/'Documentation~/Evidence/PublicLibrary033'
    elif catalog['version']=='0.3.4':E=ROOT/'Documentation~/Evidence/LibraryUI034/RecomputedContracts'
    elif catalog['version']=='0.3.5':E=ROOT/'Documentation~/Evidence/Showcase035/RecomputedContracts'
    elif catalog['version']=='0.3.6':E=ROOT/'Documentation~/Evidence/JadeArticle036/RecomputedContracts'
    foundation=load_module('foundation032','Build-ShaderLibraryPlans.py')
    local=load_module('local032','Plan-LocalShaderGraphs.py')
    water=load_module('water032','Build-DepthWaterPlan.py')
    metadata={r['id']:r for r in read('.build~/LibraryPlans031/entries.json')}
    public_metadata={r['id']:r for r in read('.build~/PublicLibrary033/entries.json')} if (ROOT/'.build~/PublicLibrary033/entries.json').exists() else {}
    showcase_metadata={r['id']:r for r in read('.build~/Showcase035/entries.json')} if (ROOT/'.build~/Showcase035/entries.json').exists() else {}
    jade_metadata={r['id']:r for r in read('.build~/JadeReference036/entries.json')} if (ROOT/'.build~/JadeReference036/entries.json').exists() else {}
    local_index={r.get('id'):r for r in read('Documentation~/Evidence/LocalLibrary030/local-adaptation-plans.json')['rows'] if r.get('id')}
    sources={r['sha256']:r for r in read('.build~/LocalShaderGraphs/manifest.json')['rows'] if r['kind']=='shadergraph'}
    families=defaultdict(list)
    for entry in catalog['entries']:families[entry.get('familyId',entry['id'])].append(entry)
    contracts=[];signatures=[]
    for family,entries in sorted(families.items()):
        first=entries[0];origin=first['origin'];category=first['category'];plans={};targets=[]
        shared=['原生计算分支与同名材质属性','ASE 可编辑节点、功能分组与中文气泡注释']
        identity='OriginalRecipe:'+family
        for entry in entries:
            if origin=='OriginalFoundation':plan=read('.build~/LibraryPlans030/'+entry['id']+'.json')
            elif origin=='OriginalEffect':plan=read(metadata[entry['id']]['plan'])
            elif origin=='OriginalValidatedWater':plan=water.build_plan(entry['pipeline'])
            elif origin=='PublicSourceAdaptation':plan=read(public_metadata[entry['id']]['plan'])
            elif origin=='ReviewedMaterialAdaptation':plan=read(showcase_metadata[entry['id']]['plan'])
            elif origin=='ReviewedArticleAdaptation':plan=read(jade_metadata[entry['id']]['plan'])
            else:plan=read(local_index[entry['id']]['plan'])
            plans[entry['pipeline']]=plan
        if origin=='OriginalValidatedWater':
            identity='OriginalPlan:Tools~/Build-DepthWaterPlan.py'
            shared+=['世界空间三向顶点波浪及解析法线','双层流动细波纹','RGB 指数深度吸收与浅深水色','Fresnel 透射','浅岸泡沫','水底世界坐标焦散','屏幕折射与散射','八组本地功能关键词']
        convert=None
        if origin=='PublicSourceAdaptation':
            identity='ShaderSHA256:'+first['sourceSha256']
            shared+=['同一份 MIT 源码的显式输入图像滤镜计算','原 uniform 名称与纹理采样坐标','RGBA、Cull Off / ZWrite Off / ZTest Always / Blend Off']
            if first.get('recipe')=='Mirror':shared+=['全局 SYMMETRY_ON multi_compile 两个变体']
        if origin=='ReviewedMaterialAdaptation':
            identity='ShaderSHA256:'+first['sourceSha256']
            shared+=['同一 MIT 流麻源码的完整 Unlit 正向效果','切线视线顶点归一化插值与片元再次归一化','原始 RG 法线反射视差','三层 1–15 次向上取整迭代、累计色带 UV/LOD0 与衰减 max','原 Spark += max(Spark,Layer) 与原始 UV 裁剪','原 Float/Range/Color/Vector/2D 与 HDR 属性']
        if origin=='ReviewedArticleAdaptation':
            identity='ArticleFunctionSHA256:'+first['sourceSha256']
            shared+=['文章核心逻辑光源距离公式；完整原材质未提供','归一化的 World→Object 光方向与局部位置','距离指数、两次 saturate 及中间 remap','补充标准 Lit 表面和核心 Emission，非扩散 BSDF']
        if origin=='LocalGraphAdaptation':
            row=local_index[first['id']];identity='ShaderGraphSHA256:'+row['sha256'];convert=local.Convert(sources[row['sha256']])
            shared+=['原 Shader Graph 计算、黑板参数及外部资源绑定身份','原模型 '+convert.target]
        sig={p:computation(plan) for p,plan in plans.items()}
        shared_outputs=set.intersection(*(set(v) for v in sig.values()))
        differing=[name for name in sorted(shared_outputs) if len({json.dumps(v[name],sort_keys=True) for v in sig.values()})>1]
        signatures.append({'familyId':family,'evaluatedPipelines':list(sig),'allThreePlansPresent':set(sig)==set(PIPES),'sharedOutputComputationsMatch':not differing,'differingOutputs':differing,'outputs':sig})
        for pipeline in PIPES:
            entry=next((e for e in entries if e['pipeline']==pipeline),None);gaps=[];hosts=[]
            if convert:
                gaps=local_gaps(convert,pipeline)
                hosts=['必须重新绑定原图贴图/扩散资源；未复制原项目素材。']
            elif origin=='ReviewedArticleAdaptation':
                hosts=first['dependencies']+['功能映射仅覆盖文章核心函数与补充 Lit 整合，不要求或宣称 HDRP 体积/扩散 SSS。']
            elif category in ('Hair','Fabric','Skin','Jade'):
                if pipeline!='HDRP':
                    gaps.append({'Hair':'现有版本只实现发卡覆盖/PBR，缺少 HDRP Hair 的发丝方向、专用高光与散射。',
                                 'Fabric':'现有版本只实现织纹/PBR，缺少 HDRP Fabric 的 Charlie/Sheen 材质模型。',
                                 'Skin':'现有版本只实现肤色/微表面，缺少 HDRP SSS、Transmission 与 Diffusion Profile 宿主。',
                                 'Jade':'现有版本只实现玉石表面色/微法线，缺少 HDRP SSS、厚度透射与扩散宿主。'}[category])
                elif category in ('Skin','Jade'):hosts=['需要注册 Diffusion Profile 并启用相机/帧设置中的 SSS/Transmission。']
            elif origin=='OriginalValidatedWater':
                hosts=['水面为细分水平网格；水底需为不透明物体并写入深度；颜色 Alpha 不作为不透明度旋钮。']
                if pipeline=='BuiltIn':hosts+=['相机 Depth Texture、GrabPass 与 Reflection Probe。']
                elif pipeline=='URP':hosts+=['启用 Opaque Texture 与 Depth Texture；Renderer 的 Copy Depth 设 After Opaques 或 Force Prepass，不能等到透明之后；Reflection Probe；只采样不透明物体背景。']
                else:
                    hosts+=['HDRP Color Pyramid 与深度缓冲；默认透明渲染阶段；去预曝光后输入 Emission；Reflection Probe。']
                    gaps+=['Built-in/URP 的独立高光开关和独立环境反射开关在 HDRP 尚无对应材质控制；默认均开启。']
            elif category=='Eye':hosts=['此原创方案范围为虹膜/瞳孔及表面色；三目标均未实现专用角膜 Eye BSDF。']
            if origin=='PublicSourceAdaptation':
                hosts=['显式输入图像滤镜，需宿主用 Graphics.Blit 或等价全屏绘制提供 _MainTex；无自动相机注入或原 C# 宿主移植。输入输出共享相同色彩编码，宿主处理目标纹理方向、XR/动态分辨率和曝光阶段。']
                if first.get('recipe')=='AnalogGlitch':hosts+=['动画宿主需供应 _ScanLineJitter、_VerticalJump、_HorizontalShake、_ColorDrift；图保留 _Time.x。']
                if first.get('recipe')=='DigitalGlitch':hosts+=['必须供应 _NoiseTex 和历史帧 _TrashTex；图本身不生成噪声、不捕获历史帧。']
                if first.get('recipe')=='Mirror':hosts+=['_Divisor 大于 0；SYMMETRY_ON 是全局关键词，可用 Shader.EnableKeyword 控制。']
            if origin=='ReviewedMaterialAdaptation':hosts=first['dependencies']+['功能映射仅限显式 Unlit 正向 Pass，不等于原场景或后备阴影 Pass 等价；原掠射角分母奇点保留。']
            if differing:gaps+=['共同输出计算不一致，需人工审查：'+', '.join(differing)]
            status='RequiresAdapter' if entry is None else 'FeatureGap' if gaps else 'Mapped'
            targets.append({'pipeline':pipeline,'entryId':entry['id'] if entry else '', 'status':status,'gaps':gaps,'hostRequirements':hosts,
                            'evidence':entry['evidence'] if entry else 'Documentation~/Evidence/CrossPipeline032/family-contracts.json'})
        contracts.append({'familyId':family,'sourceIdentity':identity,'comparisonStatus':'NotCompared','sharedFeatures':shared,'targets':targets})
    catalog['familyContracts']=contracts
    catalog['scope']='Each family tracks the same source/recipe across Built-in, URP and HDRP. Artifact existence, feature gaps, host requirements and visual comparison are separate states. Mapped does not mean rendered equivalence.'
    write('Editor/Resources/ASEShaderLibraryCatalog.json',catalog)
    write(E.relative_to(ROOT)/'family-contracts.json',{'families':contracts})
    write(E.relative_to(ROOT)/'computation-signatures.json',{'scope':'Reachable native computation only; BSDF/pass/host contracts reviewed separately. Not rendered equivalence.','families':signatures})
    summary={'artifacts':len(catalog['entries']),'families':len(families),'threeArtifactFamilies':sum(set(e['pipeline'] for e in es)==set(PIPES) for es in families.values()),
             'threeMappedTargetFamilies':sum(all(t['status']=='Mapped' for t in c['targets']) for c in contracts),'targetStates':dict(Counter(t['status'] for c in contracts for t in c['targets'])),
             'visualEquivalenceFamilies':0,'originalLocalGraphsStillBlocked':80,'researchRecordsAreNotGeneratedShaders':len(catalog['research'])}
    write(E.relative_to(ROOT)/'summary.json',summary)
    lines=['# 同一 Shader 的三管线对应表','', '每一行对应同一个原创方案或同一份原图哈希。已映射仅表示计算/功能审查，仍需画面对比；有缺口和缺失版本不能计作功能齐全。','',
           '| 同源方案 | Built-in | URP | HDRP |','| --- | --- | --- | --- |']
    labels={'Mapped':'已生成 / 功能映射','FeatureGap':'已生成 / 有功能缺口','RequiresAdapter':'待适配 / 未生成'}
    for c in contracts:
        title=families[c['familyId']][0]['title'].replace('|','/')
        lines.append('| '+title+' | '+' | '.join(labels[t['status']] for t in c['targets'])+' |')
    lines+=['','详细缺口、共同功能和宿主条件见插件中展开的每个方案，以及 Evidence/CrossPipeline032/family-contracts.json。']
    (ROOT/'Documentation~/CrossPipelineLibrary.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
    index=['# ASE 着色器库索引（'+catalog['version']+'）','',f"{summary['artifacts']} 份管线文件、{summary['families']} 个同源方案；三份文件齐备 {summary['threeArtifactFamilies']} 项，三目标功能已映射 {summary['threeMappedTargetFamilies']} 项，画面等价尚未确认。",'',
           '状态与缺口详见 [三管线对应表](CrossPipelineLibrary.md)。低/中/高为静态复杂度，设备为建议目标，未实机测速。','']
    by_family={c['familyId']:c for c in contracts}
    for category in sorted({e['category'] for e in catalog['entries']}):
        index+=['## '+category,'','| 同源材质方案 | Built-in | URP | HDRP |','| --- | --- | --- | --- |']
        for family,entries in sorted(families.items()):
            if entries[0]['category']!=category:continue
            cols=[]
            for t in by_family[family]['targets']:
                entry=next((e for e in entries if e['pipeline']==t['pipeline']),None)
                cols.append(labels[t['status']]+('；'+{'Low':'低','Medium':'中','High':'高'}.get(entry['performanceTier'],'未分级')+' / '+','.join(entry['devices']) if entry else ''))
            index.append('| '+entries[0]['title'].replace('|','/')+' | '+' | '.join(cols)+' |')
        index.append('')
    (ROOT/'Documentation~/ShaderLibraryIndex.md').write_text('\n'.join(index)+'\n',encoding='utf-8')
    print(json.dumps(summary,ensure_ascii=True))

if __name__=='__main__':main()
