"""Collect only real successful ASE output, then derive auditable static target labels."""
from pathlib import Path
from collections import Counter,defaultdict
import json,shutil,hashlib,re
ROOT=Path(__file__).resolve().parents[1];E=ROOT/'Documentation~/Evidence/Library031'
PROJECTS={'BuiltIn':'Unity2022','URP':'UnityURP','HDRP':'UnityHDRP'}
def read(path):return json.loads((ROOT/path).read_text(encoding='utf-8-sig'))
def write(path,data):
    target=ROOT/path;target.parent.mkdir(parents=True,exist_ok=True);target.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def profile(entry,plan):
    nodes=plan.get('nodes',[]);samples=sum(n['type']=='SamplerNode' for n in nodes)
    text=(ROOT/entry['path']).read_text(encoding='utf-8-sig')
    models=sorted(set(re.findall(r'#pragma\s+target\s+([0-9.]+)',text)),key=float)
    shader_model=models[-1] if models else 'Unspecified'
    # Count graph sampling sites, NOT dynamic samples or GPU timings. Templates add work.
    if not nodes:
        samples=len(re.findall(r'(?:tex2D(?:lod|grad)?|SAMPLE_TEXTURE2D(?:_LOD|_GRAD)?)\s*\(',text))
    settings=plan.get('masterSettings',[])
    transparent=any(s.get('value')=='Transparent' for s in settings) or entry['category'] in ('Water','Hosiery','VFX','UI','UIEffects') or entry['id']=='original-BuiltIn-DeepWater'
    vertex=any(o.get('masterPort')=='Vertex Offset' for o in plan.get('outputs',[]))
    scene=any(n['type'] in ('ScreenDepthNode','ScreenColorNode','GrabScreenPosition') for n in nodes) or entry['id']=='original-BuiltIn-DeepWater'
    complex_bsdf=entry['pipeline']=='HDRP' and (entry['category'] in ('Skin','Hair','Fabric','Jade') or any(s.get('name')=='option:Material Type' and s.get('value') in ('Subsurface Scattering','Translucent') for s in settings))
    high=scene or complex_bsdf or samples>6 or entry['nativeNodeCount']>180
    medium=transparent or vertex or samples>2 or entry['nativeNodeCount']>55
    tier='High' if high else 'Medium' if medium else 'Low'
    devices=['PC'] if entry['pipeline']=='HDRP' or high else ['Pad','PC'] if samples>4 else ['Mobile','Pad','PC']
    basis=f"{samples} 个图内静态采样位置；{entry['nativeNodeCount']} 个原生节点"
    if transparent:basis+='；透明覆盖/叠加成本随屏幕占比增加'
    if vertex:basis+='；顶点计算随网格密度增加'
    if scene:basis+='；场景颜色/深度依赖或拷贝成本'
    if complex_bsdf:basis+='；HDRP 专用材质模型/SSS 宿主'
    basis+='。不包含模板隐含采样/灯光/Pass 工作量；不是指令数、动态采样次数或 GPU 测速。'
    entry.update(textureSampleSites=samples,transparent=transparent,vertexAnimation=vertex,performanceTier=tier,performanceBasis=basis,deviceValidation='NotBenchmarked',devices=devices)
    entry.update(shaderModel=shader_model,graphicsApiValidation='Windows D3D11',deviceRequirements='生成源码最高声明 target '+shader_model+'（不同 Pass/变体要求可能不同）；Mobile/Pad 候选需具备相应功能级别，未在 Android/iOS、Metal/Vulkan/GLES 编译或实测。')
    entry.setdefault('familyId',entry['category']+'-Foundation' if entry['origin']=='OriginalFoundation' else entry['id'])
    entry.setdefault('effect',entry['title'])
    aliases={'Skin':['皮肤','skin'],'Hair':['头发','毛发','hair'],'Eye':['眼球','眼睛','eye'],'Fabric':['衣服','布料','cloth','fabric'],
             'Hosiery':['丝袜','薄织物','stockings'],'Water':['水','water'],'Metal':['金属','metal'],'Stone':['石头','岩石','stone'],'Jade':['玉石','jade'],
             'UI':['界面','UI'],'UIEffects':['界面动效','UI'],'VFX':['特效','溶解','vfx'],'UVAnimation':['UV','动画'],'VertexAnimation':['顶点','风','vertex']}
    entry['keywords']=list(dict.fromkeys(aliases.get(entry['category'],[])+[entry['effect'],entry.get('recipe','')]))

catalog=read('.build~/Library031/base-catalog.json');entries=catalog['entries'];metadata=read('.build~/LibraryPlans031/entries.json')
results={}
for p in PROJECTS:
    data=read('Documentation~/Evidence/Library031/Build-'+p+'/results.json');assert data['completed'] and data['pipeline']==p
    for row in data['rows']:results[row['id']]=row
failures=[]
for m in metadata:
    row=results.get(m['id']);r=row['response'] if row else {};report=r.get('report') or {}
    if not(r.get('success') and report.get('status')=='Generated' and report.get('aseRoundTripPassed') and report.get('shaderCompiled')):
        failures.append({'id':m['id'],'error':r.get('error','missing result'),'blockers':report.get('blockers',[])});continue
    assert report['layoutApplied'] and report['commentCount']>0 and report['customExpressionCount']==0
    plan=read(m['plan']);assert report['shaderName']==plan['shaderName'],('Stale generation result',m['id'])
    source=ROOT/'.validation'/PROJECTS[m['pipeline']]/report['outputPath']
    target=Path('Samples~/ShaderLibrary')/m['category']/m['pipeline']/(m['id']+'.shader');(ROOT/target).parent.mkdir(parents=True,exist_ok=True);shutil.copy2(source,ROOT/target)
    entry={k:v for k,v in m.items() if k!='plan'}
    entry['effect']=m['title']
    entry.update({k:report[k] for k in ('aseRoundTripPassed','shaderCompiled','visualComparisonPassed','layoutApplied','nativeNodeCount','customExpressionCount','commentCount','unityVersion','aseVersion','templateGuid','status')})
    entry.update(path=target.as_posix(),sha256=sha(source),source='Original native-node effect extension',sourceSha256='',license='Original plugin sample',
                 evidence='Documentation~/Evidence/Library031/Build-'+m['pipeline']+'/results.json',dependencies=['Texture-based effects require user textures; normal maps must be imported as NormalMap. HDRP SSS requires a registered Diffusion Profile.'] if m['category'] in ('Skin','Jade') and m['pipeline']=='HDRP' else ['Texture-based effects require matching textures; vertex effects require suitable mesh subdivisions.'])
    profile(entry,plan);entries.append(entry)
local={r.get('id'):r for r in read('Documentation~/Evidence/LocalLibrary030/local-adaptation-plans.json')['rows'] if r.get('id')}
for e in entries:
    if e['origin']=='OriginalEffect':continue
    if e['origin']=='OriginalFoundation':plan=read('.build~/LibraryPlans030/'+e['id']+'.json')
    elif e['id'] in local:plan=read(local[e['id']]['plan'])
    else:plan={}
    profile(e,plan)
families=defaultdict(list)
for e in entries:families[e['familyId']].append(e)
coverage=[{'familyId':key,'title':items[0]['title'],'category':items[0]['category'],'pipelines':{p:next(({'id':e['id'],'status':'Generated'} for e in items if e['pipeline']==p),{'status':'RequiresAdapter','reason':'No verified equivalent target implementation; no silent BSDF or render-state substitution.'}) for p in PROJECTS}} for key,items in sorted(families.items())]
catalog.update(version='0.3.1',scope='Original families have three verified pipeline variants. Legacy source adaptations and DeepWater retain explicit pipeline gaps. Device labels and complexity are static recommendations, not hardware measurements.',entries=entries)
write('Editor/Resources/ASEShaderLibraryCatalog.json',catalog)
write('Documentation~/Evidence/Library031/family-coverage.json',{'families':coverage})
write('Documentation~/Evidence/Library031/library-manifest.json',{'artifacts':len(entries),'families':len(families),'completeThreePipelineFamilies':sum(len({e['pipeline'] for e in v})==3 for v in families.values()),'byPipeline':dict(Counter(e['pipeline'] for e in entries)),'byTier':dict(Counter(e['performanceTier'] for e in entries)),'failures':failures,'entries':entries})
write('Documentation~/Evidence/Library031/static-profile-policy.json',{'hardwareBenchmarked':False,'rules':{'High':'scene input/copy dependency OR HDRP character/SSS model OR >6 sampling sites OR >180 native nodes','Medium':'transparent OR vertex animation OR >2 sampling sites OR >55 native nodes','Low':'otherwise','HDRP':'PC target only; no mobile support assertion','OtherDevices':'High -> PC; otherwise >4 sites -> Pad/PC; remaining -> Mobile/Pad/PC'},'notes':'Sampling counts are static graph sites, not dynamic samples/instructions. Template lights, hidden samples, passes, resolution, overdraw and hardware are not measured.'})
lines=['# ASE 着色器库索引（0.3.1）','',f"{len(entries)} 个管线文件；{len(families)} 个材质方案。完整三管线方案与补充单管线图分开记录。",'',
       '低/中/高为静态复杂度，不是 GPU 测速。设备标签为建议目标，可能重叠。批量生成会为原创系列配置原创小型示例纹理；原图适配需要源资源。','']
for category in sorted({e['category'] for e in entries}):
    lines+=['## '+category,'','| 材质方案 | Built-in | URP | HDRP |','| --- | --- | --- | --- |']
    for key,items in sorted(families.items()):
        if items[0]['category']!=category:continue
        columns=[]
        for pipeline in PROJECTS:
            entry=next((e for e in items if e['pipeline']==pipeline),None)
            columns.append(('低' if entry['performanceTier']=='Low' else '中' if entry['performanceTier']=='Medium' else '高')+' / '+','.join(entry['devices']) if entry else '待适配')
        lines.append('| '+items[0]['title'].replace('|','/')+' | '+' | '.join(columns)+' |')
    lines.append('')
(ROOT/'Documentation~/ShaderLibraryIndex.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
print('Collected',len(entries),'pipeline artifacts,',len(families),'families;',len(failures),'failed plans')
if failures:raise SystemExit('Failed jobs are recorded and not included in generated counts.')
