"""Collect verified ASE material graphs, preserving all 0.3.5 artifacts/evidence."""
from pathlib import Path
from collections import Counter,defaultdict
import hashlib,json,re,shutil,importlib.util
ROOT=Path(__file__).resolve().parents[1];CACHE=ROOT/'.build~/JadeReference036';E=ROOT/'Documentation~/Evidence/JadeArticle036'
HOSTS={'BuiltIn':'Unity2022','URP':'UnityURP','HDRP':'UnityHDRP'}
def read(p):return json.loads((ROOT/p).read_text(encoding='utf-8-sig'))
def write(p,v):p=ROOT/p;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def main():
    catalog=read('Editor/Resources/ASEShaderLibraryCatalog.json');baseline=read(CACHE/'baseline-catalog.json');metadata=read(CACHE/'entries.json');review=read(E/'source-review.json')
    for entry in baseline['entries']:assert sha(ROOT/entry['path'])==entry['sha256'],entry['id']
    spec=importlib.util.spec_from_file_location('jade_contracts',ROOT/'Tools~/Build-CrossPipelineContracts.py');contracts=importlib.util.module_from_spec(spec);spec.loader.exec_module(contracts)
    entries=[];signatures={}
    for m in metadata:
        p=m['pipeline'];host=ROOT/'.validation'/HOSTS[p];folder=host/'LibraryBuildEvidence';build=read(folder/'results.json')
        assert build['completed'] and build['pipeline']==p and len(build['rows'])==2
        for row in build['rows']:
            r=row['response'];q=r['report'];assert r['success'] and q['status']=='Generated' and q['aseRoundTripPassed'] and q['shaderCompiled'],(p,r.get('error'))
            assert q['customExpressionCount']==0 and q['layoutApplied'] and q['commentCount']==5
        row=next(r for r in build['rows'] if r['id']==m['id']);q=row['response']['report'];plan=read(m['plan']);source=host/row['output'];text=source.read_text(encoding='utf-8-sig')
        assert '/*ASEBEGIN' in text and plan['shaderName'] in text and 'CustomExpressionNode' not in text
        validation=read(folder/'jade-validation-036.json');assert validation['success'] and validation['pipeline']==p and len(validation['formula'])==14
        assert all(r['checkedPixels']>100 and r['maxError']<.0001 for r in validation['formula'])
        assert validation['realCamera'] and validation['sceneChangedPixels']>100 and validation['sceneLightChangedPixels']>100
        target=Path('Samples~/ShaderLibrary/Jade')/p/'FangmuLogicalLight_ASE.shader';(ROOT/target).parent.mkdir(parents=True,exist_ok=True);shutil.copy2(source,ROOT/target)
        (ROOT/target).with_suffix('.shader.meta').write_text('fileFormatVersion: 2\nguid: '+hashlib.sha256(m['id'].encode()).hexdigest()[:32]+'\n',encoding='utf-8')
        out=E/('Build-'+p);out.mkdir(parents=True,exist_ok=True)
        for name in ('results.json','probe.json',m['id']+'-describe.json',m['id']+'-fixture-describe.json','jade-validation-036.json'):shutil.copy2(folder/name,out/name)
        conn=host/'Library/ASEShaderConverter/Agent/connection.json'
        if conn.exists():shutil.copy2(conn,out/'connection.json')
        imageout=E/('Render-'+p);imageout.mkdir(parents=True,exist_ok=True)
        for image in validation['images']:shutil.copy2(host/image,imageout/Path(image).name)
        entry={k:v for k,v in m.items() if k!='plan'}
        entry.update({k:q[k] for k in ('aseRoundTripPassed','shaderCompiled','visualComparisonPassed','layoutApplied','nativeNodeCount','customExpressionCount','commentCount','unityVersion','aseVersion','templateGuid','status')})
        model=max(re.findall(r'#pragma\s+target\s+([0-9.]+)',text),key=float)
        entry.update(path=target.as_posix(),sha256=sha(source),evidence='Documentation~/Evidence/JadeArticle036/Build-'+p+'/results.json',
            effect='逻辑光源点 / 局部距离透光 / 指数与通道饱和 / 标准 Lit 抛光表面',
            notes='按文章核心函数显式建图；世界光方向变换到局部并归一化，保留减号、距离/指数、第一次 saturate、remap、乘色后的第二次 saturate。文章未提供完整 Shader；Lit 表面与 Emission 接法、参数默认值为补充实现，不声称作者原材质或场景等价。支持场景主方向光或手动方向。不是 HDRP 扩散 SSS/真实厚度散射。',
            textureSampleSites=0,transparent=False,vertexAnimation=False,performanceTier='Medium',deviceValidation='NotBenchmarked',devices=['PC'] if p=='HDRP' else ['Mobile','Pad','PC'],shaderModel=model,graphicsApiValidation='Windows D3D11',
            performanceBasis='核心图无纹理采样或循环；原生方向变换、distance、pow、remap、saturate，外加标准 Lit 宿主。0 仅为显式图采样位置，Lit 的阴影/环境反射等成本另计；未做 GPU/移动端测速。',
            deviceRequirements='需要支持当前模板 Shader Model '+model+' 的设备及兼容 ASE/管线；Mobile/Pad 为硬件能力候选，Android/iOS/Metal/Vulkan/GLES 尚未验证。HDRP 仅 PC。',
            keywords=['玉石','方木君','逻辑光源','文章方案','透光','jade','logical light','SSS近似'],
            dependencies=['正版 ASE 与对应管线标准 Lit 模板。无需作者模型或额外深度/散射贴图。','网格中心是局部原点，偏心模型用 _JadeOffset 修正；仅静态网格验证，骨骼、顶点变形、XR 未验证。','DepthDistance+LightDistance>0，MaxDist>MinDist，Pow>0；方向非零、物体变换可逆；未偷偷给原公式加 epsilon。','场景模式需要一盏主方向光；HDRP 读取第一方向光。无灯光或需要精确指定方向时关闭 _JADE_SCENE_LIGHT 并提供 _JadeMainLightWS。','新材质会同步 Float 与 _JADE_SCENE_LIGHT_ON 关键词；复用材质保留用户修改。运行时改开关需同步关键词。','核心函数不接灯色、强度、阴影、法线；本次将它作为 Emission，场景照明/阴影只影响补充 Lit 表面。'])
        entries.append(entry);signatures[p]=contracts.computation(plan)
    assert len({json.dumps(v,sort_keys=True) for v in signatures.values()})==1
    ids={e['id'] for e in entries};catalog['entries']=[e for e in catalog['entries'] if e['id'] not in ids]+entries
    contract={'familyId':'Fangmu-LogicalLight-Jade','sourceIdentity':'ArticleFunctionSHA256:'+review['codeSha256'],'comparisonStatus':'NotCompared','sharedFeatures':['同一文章核心函数与原参数名称','World→Object 方向变换后归一化；局部网格位置','逻辑光源减号、距离、pow、两次 saturate 与中间 remap','标准 Lit 表面与可调核心 Emission 为补充实现','场景主方向光/手动世界方向选择；不透明','原生节点与五组中文气泡'],'targets':[{'pipeline':e['pipeline'],'entryId':e['id'],'status':'Mapped','gaps':[],'hostRequirements':e['dependencies']+['Mapped 仅覆盖声明的核心公式和补充材质，不代表完整原材质或管线 BSDF 一致。'],'evidence':e['evidence']} for e in entries]}
    catalog['familyContracts']=[c for c in catalog['familyContracts'] if c['familyId']!=contract['familyId']]+[contract]
    researchid='article-fangmu-jade-a9cc314b'
    catalog['research']=[r for r in catalog['research'] if r['id']!=researchid]+[{'id':researchid,'title':review['title']+' · 方木君','source':review['url'],'sha256':review['codeSha256'],'kind':'ArticleCoreFunction','pipeline':'URP','license':review['license'],'status':'ReviewedLibraryPlans','categories':['Jade'],'blockers':['文章仅公开核心函数；完整 Shader、默认值、资源与原场景未知。','已显式适配核心和补充 Lit 材质；不是通用 HLSL 自动规划规则。'],'evidence':'Documentation~/Evidence/JadeArticle036/source-review.json'}]
    catalog['version']='0.3.6';write('Editor/Resources/ASEShaderLibraryCatalog.json',catalog)
    write(E/'library-entries.json',{'entries':entries});write(E/'family-contract.json',contract);write(E/'computation-signatures.json',{'sameReachableComputation':True,'outputs':signatures,'scope':'Same explicit graph math; standard Lit BSDFs may differ.'})
    families=defaultdict(list)
    for e in catalog['entries']:families[e['familyId']].append(e)
    summary={'version':'0.3.6','artifacts':len(catalog['entries']),'families':len(families),'pipelines':dict(Counter(e['pipeline'] for e in catalog['entries'])),'threeArtifactFamilies':sum(set(e['pipeline'] for e in es)==set(HOSTS) for es in families.values()),'threeMappedTargetFamilies':sum(all(t['status']=='Mapped' for t in c['targets']) for c in catalog['familyContracts']),'targetStates':dict(Counter(t['status'] for c in catalog['familyContracts'] for t in c['targets'])),'researchRecords':len(catalog['research']),'oldArtifactsUnchanged':len(baseline['entries']),'oldGraphBlockers':80,'newIndependentEffects':1,'newArtifacts':3}
    write(E/'summary.json',summary)
    print(json.dumps(summary,ensure_ascii=False))
if __name__=='__main__':main()
