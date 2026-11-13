"""Collect only real ASE output from the reviewed full glitter-source conversion.

Does not manufacture ASE metadata. Existing entries and historical contracts remain intact.
"""
from pathlib import Path
from collections import Counter,defaultdict
import json,hashlib,shutil,re,importlib.util
ROOT=Path(__file__).resolve().parents[1]
E=ROOT/'Documentation~/Evidence/Showcase035'
HOSTS={'BuiltIn':'Unity2022','URP':'UnityURP','HDRP':'UnityHDRP'}
def read(p):return json.loads((ROOT/p).read_text(encoding='utf-8-sig'))
def write(p,o):
    p=ROOT/p;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(json.dumps(o,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def main():
    catalog=read('Editor/Resources/ASEShaderLibraryCatalog.json');metadata=read('.build~/Showcase035/entries.json');verified=[];signatures={}
    spec=importlib.util.spec_from_file_location('contracts035',ROOT/'Tools~/Build-CrossPipelineContracts.py');contracts=importlib.util.module_from_spec(spec);spec.loader.exec_module(contracts)
    for m in metadata:
        p=m['pipeline'];host=ROOT/'.validation'/HOSTS[p];source=host/'LibraryBuildEvidence';evidence=E/('Build-'+p);evidence.mkdir(parents=True,exist_ok=True)
        batch=read(source/'results.json');assert batch['completed'] and batch['pipeline']==p and len(batch['rows'])==1
        row=batch['rows'][0];assert row['id']==m['id'];response=row['response'];report=response.get('report') or {};plan=read(m['plan'])
        assert response['success'] and report['status']=='Generated' and report['aseRoundTripPassed'] and report['shaderCompiled'],(p,response.get('error'))
        assert report['shaderName']==plan['shaderName'] and report['outputPath']==row['output']
        assert report['layoutApplied'] and report['commentCount']>=13 and report['customExpressionCount']==0
        generated=host/report['outputPath'];text=generated.read_text(encoding='utf-8-sig')
        assert '/*ASEBEGIN' in text and plan['shaderName'] in text
        for state in ('Cull Back','ZWrite On','ZTest LEqual','Blend Off','LOD 100','Fallback "Transparent/Cutout/VertexLit"'):assert state in text,(p,state)
        assert re.search(r'\[HDR\]\s*_SparkleColor',text)
        for name in ('_ShiningSpeed','_ShiningSpeed_02','_ShiningSpeed_03','_SparklePower'):assert re.search(re.escape(name)+r'\s*\([^\n]*,\s*Float\s*\)',text),(p,name)
        assert len([n for n in plan['nodes'] if n['type']=='ConditionalIfNode'])==45
        output=Path('Samples~/ShaderLibrary/VFX')/p/'LayeredParallaxGlitter_ASE.shader';(ROOT/output).parent.mkdir(parents=True,exist_ok=True);shutil.copy2(generated,ROOT/output)
        (ROOT/output).with_suffix('.shader.meta').write_text('fileFormatVersion: 2\nguid: '+hashlib.sha256(m['id'].encode()).hexdigest()[:32]+'\n',encoding='utf-8')
        for f in [source/'results.json',source/'probe.json',source/(m['id']+'-describe.json')]:shutil.copy2(f,evidence/f.name)
        samples=sum(n['type']=='SamplerNode' for n in plan['nodes']);assert samples==93
        entry={k:v for k,v in m.items() if k not in ('plan','sourceRepository','sourcePath','sourceCommit')}
        entry.update({k:report[k] for k in ('aseRoundTripPassed','shaderCompiled','visualComparisonPassed','layoutApplied','nativeNodeCount','customExpressionCount','commentCount','unityVersion','aseVersion','templateGuid','status')})
        entry.update(path=output.as_posix(),sha256=sha(generated),evidence='Documentation~/Evidence/Showcase035/Build-'+p+'/results.json',
            textureSampleSites=samples,transparent=False,vertexAnimation=False,performanceTier='High',deviceValidation='NotBenchmarked',devices=['PC'],shaderModel='4.5',graphicsApiValidation='Windows D3D11',
            performanceBasis=f'每层最多 15 次、三层共 45 次静态展开；图有 {samples} 个采样位置、{report["nativeNodeCount"]} 个原生节点。运行成本随编译器、迭代参数与屏幕覆盖率变化，未进行 GPU 测速。',
            deviceRequirements='PC / target 4.5 / UV0 + normal + tangent；仅 Windows D3D11 验证。Android/iOS、Metal/Vulkan/GLES、XR 和实际硬件性能未验证。',
            notes='MIT 原源码完整效果适配：原始 RG 法线反射视差、三层流动、累计色带 UV、LOD0、1–15 次向上取整迭代、衰减/max 聚合、轮廓裁剪。全部材质计算为原生节点，顶点视线插值由自有模板承载。源中仅声明或不参与输出的高光/边缘光等参数保留但不生效；不增加 PBR、抓屏、SSS。掠射角保留原 abs(reflect.z) 分母奇点。新材质初始化原创贴图与蓝青预设，另提供金橙/紫色预设。固定夹具对比不代表原场景等价。',
            keywords=['完整效果','源码适配','流麻','闪片','视差','三层','glitter','parallax','AspectURP','MIT'],
            dependencies=['编辑图需保留插件 Editor/Templates/ParallaxGlitter'+p+'.shader。','网格必须有 UV0、法线和切线；噪声/裁剪/原始 RG 法线使用 Default Linear 纹理，不能将法线设为 Unity NormalMap。','基色与色带采用 sRGB 色彩贴图；Iteration 合同范围 1–15，超范围不作行为保证。','保留原 cutout 不透明深度和 Fallback；本次功能映射/像素比较限定显式 Unlit 正向 Pass，不含后备阴影 Pass、XR 或整场景后处理一致性。'])
        verified.append(entry);signatures[p]=contracts.computation(plan)
    assert len(verified)==3 and len({json.dumps(s,sort_keys=True) for s in signatures.values()})==1
    ids={e['id'] for e in verified};catalog['entries']=[e for e in catalog['entries'] if e['id'] not in ids]+verified
    contract={'familyId':metadata[0]['familyId'],'sourceIdentity':'ShaderSHA256:'+metadata[0]['sourceSha256'],'comparisonStatus':'NotCompared',
        'sharedFeatures':['同一 MIT 源码完整 Unlit 正向效果','顶点 tangent view 归一化/插值与片元再次归一化','手动 RG 法线解码与反射视差','三层独立流动 / 每层 1–15 次向上取整迭代','累计色带 UV / 显式 LOD0 / pow-step-clamp 衰减 / 逐次 max','原 Spark += max(Spark,Layer) 合成与 MaskAlpha 原始 UV 裁剪','原属性 Float/Range/Color/Vector/2D 与 HDR 闪片色','原生节点、布局与中文气泡'],
        'targets':[{'pipeline':e['pipeline'],'entryId':e['id'],'status':'Mapped','gaps':[],'hostRequirements':e['dependencies']+['限定 Unlit 正向 Pass 功能映射；不等于整个原场景画面等价。'],'evidence':e['evidence']} for e in verified]}
    catalog['familyContracts']=[c for c in catalog['familyContracts'] if c['familyId']!=contract['familyId']]+[contract]
    matching=[r for r in catalog['research'] if r['sha256']==metadata[0]['sourceSha256'] or r['source']==metadata[0]['source']]
    assert matching,'Reviewed source must already have an identity; do not inflate research count'
    for r in matching:r.update(status='ReviewedLibraryPlans',license=metadata[0]['license'],evidence='Documentation~/Evidence/Showcase035/source-review.json',blockers=['此固定源码已通过显式原生计划收录；不代表通用自动转换器已支持其中全部 HLSL 语义。'])
    catalog['version']='0.3.5';write('Editor/Resources/ASEShaderLibraryCatalog.json',catalog)
    write(E/'library-entries.json',{'entries':verified});write(E/'family-contract.json',contract);write(E/'computation-signatures.json',{'sameReachableComputation':True,'outputs':signatures,'scope':'Same graph computation; independent host/visual checks required.'})
    families=defaultdict(list)
    for e in catalog['entries']:families[e['familyId']].append(e)
    summary={'version':catalog['version'],'artifacts':len(catalog['entries']),'families':len(families),'pipelines':dict(Counter(e['pipeline'] for e in catalog['entries'])),
        'threeArtifactFamilies':sum(set(e['pipeline'] for e in es)==set(HOSTS) for es in families.values()),'threeMappedTargetFamilies':sum(all(t['status']=='Mapped' for t in c['targets']) for c in catalog['familyContracts']),
        'targetStates':dict(Counter(t['status'] for c in catalog['familyContracts'] for t in c['targets'])),'researchRecords':len(catalog['research']),'originalLocalGraphsStillBlocked':80,'newIndependentEffects':1,'newArtifacts':3}
    write(E/'summary.json',summary)
    labels={'Mapped':'已生成 / 功能映射','FeatureGap':'已生成 / 有功能缺口','RequiresAdapter':'待适配 / 未生成'}
    cross=['# 同一 Shader 的三管线对应表','','每行对应同源方案。映射限定各条目声明的功能/宿主范围，固定夹具对比不能扩大为原场景等价。','','| 同源方案 | Built-in | URP | HDRP |','| --- | --- | --- | --- |']
    for c in catalog['familyContracts']:cross+=['| '+families[c['familyId']][0]['title'].replace('|','/')+' | '+' | '.join(labels[t['status']] for t in c['targets'])+' |']
    cross+=['','逐方案缺口与宿主见插件详情和目录 familyContracts；本轮新增证据见 Evidence/Showcase035。']
    (ROOT/'Documentation~/CrossPipelineLibrary.md').write_text('\n'.join(cross)+'\n',encoding='utf-8')
    index=['# ASE 着色器库索引（0.3.5）','',f"{summary['artifacts']} 份管线文件 / {summary['families']} 个同源方案；三份齐备 {summary['threeArtifactFamilies']}；三目标功能映射 {summary['threeMappedTargetFamilies']}。固定测试不等于原场景等价。",'','[三管线对应与缺口](CrossPipelineLibrary.md)。设备为静态建议，复杂度不是 GPU 测速。','']
    by_family={c['familyId']:c for c in catalog['familyContracts']}
    for category in sorted({e['category'] for e in catalog['entries']}):
        index+=['## '+category,'','| 同源方案 | Built-in | URP | HDRP |','| --- | --- | --- | --- |']
        for family,es in sorted(families.items()):
            if es[0]['category']!=category:continue
            cols=[]
            for p in HOSTS:
                t=next(t for t in by_family[family]['targets'] if t['pipeline']==p);e=next((e for e in es if e['pipeline']==p),None)
                cols.append(labels[t['status']]+('；'+e['performanceTier']+' / '+','.join(e['devices']) if e else ''))
            index+=['| '+es[0]['title'].replace('|','/')+' | '+' | '.join(cols)+' |']
        index+=['']
    (ROOT/'Documentation~/ShaderLibraryIndex.md').write_text('\n'.join(index)+'\n',encoding='utf-8')
    print(json.dumps(summary,ensure_ascii=False))
if __name__=='__main__':main()
