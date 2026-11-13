"""Package only real ASE output backed by successful Unity/ASE generation reports.
References are metadata only; no original third-party shader implementation is copied.
"""
from pathlib import Path
import json,hashlib,shutil,re
ROOT=Path(__file__).resolve().parents[1];E=ROOT/'Documentation~/Evidence/LocalLibrary030'
def read(path):return json.loads((ROOT/path).read_text(encoding='utf-8-sig'))
def write(path,data):
    p=ROOT/path;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
entries=[];research=[];results={}
projects={'BuiltIn':'.validation/Unity2022','URP':'.validation/UnityURP','HDRP':'.validation/UnityHDRP'}
for p in projects:
    for row in read('Documentation~/Evidence/LocalLibrary030/Original-'+p+'/results.json')['rows']:results[row['id']]=row
for row in read('Documentation~/Evidence/LocalLibrary030/Local-HDRP/results.json')['rows']:
    if row['id'].startswith('original-') and row['response']['success']:results[row['id']]=row
localresults=E/'Local-HDRP-final/results.json'
if localresults.exists():
    final=read(str(localresults.relative_to(ROOT)));assert final['completed']
    for row in final['rows']:results[row['id']]=row
def artifact(meta,row):
    response=row['response'];report=response.get('report') or {}
    if not(response['success'] and report['status']=='Generated' and report['aseRoundTripPassed'] and report['shaderCompiled']):return
    assert report['layoutApplied'] and report['commentCount']>0 and report['customExpressionCount']==0
    src=ROOT/projects[meta['pipeline']]/report['outputPath'];assert src.is_file()
    data=src.read_bytes();assert b'/*ASEBEGIN' in data and b'ASEEND*/' in data
    dest=Path('Samples~/ShaderLibrary')/meta['category']/meta['pipeline']/(meta['id']+'.shader')
    (ROOT/dest).parent.mkdir(parents=True,exist_ok=True);shutil.copy2(src,ROOT/dest)
    entry={**meta,**{k:report[k] for k in ['aseRoundTripPassed','shaderCompiled','visualComparisonPassed','layoutApplied','nativeNodeCount','customExpressionCount','commentCount','unityVersion','aseVersion','templateGuid','status']},
           'path':dest.as_posix(),'sha256':sha(ROOT/dest)};entries.append(entry)
for m in read('.build~/LibraryPlans030/entries.json'):
    m.pop('plan',None);m.update(source='Original native ASE material foundation',sourceSha256='',license='Original plugin sample',evidence='Documentation~/Evidence/LocalLibrary030/Original-'+m['pipeline']+'/results.json',dependencies=['Supply material textures and suitable geometry; HDRP SSS requires a registered Diffusion Profile.'] if m['category'] in ('Skin','Jade') and m['pipeline']=='HDRP' else [])
    if m['id'] in ('original-HDRP-Skin','original-HDRP-Jade'):m['evidence']='Documentation~/Evidence/LocalLibrary030/Local-HDRP/results.json'
    artifact(m,results[m['id']])
localplans=read('Documentation~/Evidence/LocalLibrary030/local-adaptation-plans.json')
for m in localplans['rows']:
    if m.get('id') not in results:continue
    dependencies=['Source material textures and host/frame settings require rebinding; compare with the original scene.']+[x['property']+' GUID '+x['guid'] for x in m['assetBindings']]
    notes='原 Shader Graph 的显式原生节点适配；外部资源、原材质参数、原场景及视觉等价未验证。'
    if m.get('inactiveOutputs'):notes+=' 源材质已禁用的输出分支保留为断开节点，详见证据中的 inactiveOutputs。'
    category=next((c for c in m['categories'] if c in ['Eye','Hair','Fabric','Skin','Water','Stone','Metal','VFX','UVAnimation']), 'Hair' if 'demoteam.hair' in m['path'] else 'General')
    artifact({'id':m['id'],'title':Path(m['path']).stem+' · 原图适配 '+m['sha256'][:8],'pipeline':'HDRP','category':category,
              'origin':'LocalGraphAdaptation','source':m['path'],'sourceSha256':m['sha256'],'license':'User supplied project reference; personal workspace package. Original asset terms remain applicable.',
              'notes':notes,'evidence':'Documentation~/Evidence/LocalLibrary030/Local-HDRP-final/results.json','dependencies':dependencies},results[m['id']])
# Original full Built-in water; preserve the exact historically verified shader bytes.
water=read('Documentation~/Evidence/FullValidation028/Smoke/Water/water-conversion.json')
report=water['report'];waterSource=ROOT/'.validation/DeepZoom2022/Assets/Shaders/DeepWater_ASE.shader'
assert water['success'] and report['aseRoundTripPassed'] and report['shaderCompiled']
destination=Path('Samples~/ShaderLibrary/Water/BuiltIn/original-BuiltIn-DeepWater.shader');(ROOT/destination).parent.mkdir(parents=True,exist_ok=True);shutil.copy2(waterSource,ROOT/destination)
entries.append({'id':'original-BuiltIn-DeepWater','title':'DeepWater 深度吸收 / 折射 / 焦散','category':'Water','pipeline':'BuiltIn','origin':'OriginalValidatedWater',
    'path':destination.as_posix(),'sha256':sha(waterSource),'sourceSha256':'','source':'Original DeepWater native ASE plan','license':'Original plugin sample',
    'notes':'完整 Built-in 深度水。导入后等待脚本编译，再运行 Water/Create supporting assets 生成贴图、网格、预制体与深度组件。历史 22 组开关编译/隔离渲染通过；未验证用户原场景、URP/HDRP 或水下视角。',
    'dependencies':['Built-in camera depth and opaque bottom geometry','Water/Create supporting assets after import; color alpha does not control opacity'],
    'evidence':'Documentation~/Evidence/FullValidation028/Smoke/Water/water-conversion.json',**{k:report[k] for k in ['aseRoundTripPassed','shaderCompiled','visualComparisonPassed','layoutApplied','nativeNodeCount','customExpressionCount','commentCount','unityVersion','aseVersion','templateGuid','status']}})
# Research includes the frozen public corpus, later character research and local unique sources.
seen=set()
for filename in ['Documentation~/Evidence/RuleResearch026/public-corpus-analysis.json','Documentation~/Evidence/CharacterMaterials029/Analysis/public-corpus-analysis.json','Documentation~/Evidence/RuleResearch026/user-reference-analysis.json']:
    dataset=read(filename)
    for m in dataset.get('files',[]):
        identity=(m.get('repository',''),m['path'],m['sha256'])
        if identity in seen:continue
        seen.add(identity);research.append({'id':'reference-'+hashlib.sha256('|'.join(identity).encode()).hexdigest()[:20],'title':Path(m['path']).name,'source':m.get('url') or m['path'],'sha256':m['sha256'],
            'kind':Path(m['path']).suffix.lstrip('.'),'pipeline':m.get('sourcePipeline','Unknown'),'license':m.get('license','User reference; not redistributed'),
            'categories':m.get('knowledge',{}).get('materialCategories',[]),'status':'HistoricalAnalysis / '+m['status'],
            'evidence':filename,'blockers':m.get('blockers',[])+['Reference code is not included. Planning/analysis is not generic ASE generation or visual equivalence.']})
local=read('.build~/LocalShaderGraphs/manifest.json');unique={}
core={r['sha256']:r for r in read('Documentation~/Evidence/LocalLibrary030/core-analysis.json')['rows']}
for m in local['rows']:unique.setdefault(m['sha256'],m)
for h,m in unique.items():
    plan=next((x for x in localplans['rows'] if x['sha256']==h),{});generated=next((x for x in entries if x.get('sourceSha256')==h),None)
    blockers=plan.get('blockers',[])
    analyses=core[h]['analyses']
    if not blockers and analyses and not generated:
        graph=analyses[0]['knowledge']['graph']
        if graph['present']:
            blockers=['Existing ASE '+graph['version']+'; graph dependencies require actual template/function resolution and reload before packaging.',
                      'Template GUIDs: '+', '.join(graph['templateGuids']),'Function GUIDs: '+', '.join(graph['functionGuids']),
                      'Original Custom Expression count: '+str(graph['customExpressionCount'])]
        else:blockers=[a['report']['pipeline']+': '+b for a in analyses for b in a['report']['blockers']][:9]
    research.append({'id':'local-'+h[:20],'title':Path(m['path']).name,'source':m['origin']+': '+m['path'],'sha256':h,'kind':m['kind'],'pipeline':m['pipeline'],'license':m['license'],'categories':m['categories'],
        'status':'GeneratedAdaptation / RequiresSourceAssets' if generated else 'RequiresAdapter' if m['kind'] in ('shader','shadergraph') else 'Inventoried',
        'evidence':'Documentation~/Evidence/LocalLibrary030/core-analysis.json','blockers':blockers or ['Inspect dependencies, source materials and model-specific target adapters. Source equivalence remains unvalidated.']})
historical={}
for pipeline in ['BuiltIn','URP','HDRP']:
    for row in read('Documentation~/Evidence/FullValidation028/'+pipeline+'/results.json')['rows']:
        historical.setdefault(row['sha256'],[]).append(row)
for record in research:
    rows=historical.get(record['sha256'],[])
    if not rows:continue
    passed=[r for r in rows if r['shaderCompiled'] and (r['graphRoundTrip'] or r['graphLoaded'])]
    if passed:record['status']='HistoricalValidated: '+'; '.join(r['pipeline']+' '+r['status'] for r in passed)
    record['blockers'].append('Historical actual validation: '+'; '.join(r['pipeline']+'='+r['status']+', ASE round-trip='+str(r['graphRoundTrip'])+', compiled='+str(r['shaderCompiled'])+', fixture compared='+str(r['fixtureCompared']) for r in rows))
    record['blockers'].append('Historical evidence: Documentation~/Evidence/FullValidation028/<pipeline>/results.json. Existing graph migration and fixed fixtures do not establish handwritten conversion or original-scene equivalence; research rows do not imply an importable library artifact.')
write('Editor/Resources/ASEShaderLibraryCatalog.json',{'version':'0.3.0','scope':'Per-entry ASE round-trip and shader compilation. No source scene equivalence or AAA quality certification. Raw reference sources are excluded.','entries':entries,'research':research})
write('Documentation~/Evidence/LocalLibrary030/library-manifest.json',{'generatedArtifacts':len(entries),'researchRecords':len(research),'entries':entries})
if localresults.exists():
    byid={r['id']:r for r in final['rows']}
    for row in localplans['rows']:
        result=byid.get(row.get('id'));row['actualGenerationStatus']=result['response'].get('report',{}).get('status','Failed') if result else 'NotGenerated'
        row['aseGenerated']=any(e['sourceSha256']==row['sha256'] for e in entries)
        if result and not result['response']['success']:row['generationBlockers']=result['response'].get('report',{}).get('blockers',[])+[result['response'].get('error','')]
    localplans['generatedCount']=sum(r['aseGenerated'] for r in localplans['rows']);write('Documentation~/Evidence/LocalLibrary030/local-adaptation-plans.json',localplans)
print('Artifacts',len(entries),'research records',len(research))
keep={e['path'] for e in entries};folder=(ROOT/'Samples~/ShaderLibrary').resolve()
for path in folder.rglob('*.shader'):
    if path.relative_to(ROOT).as_posix() not in keep:
        assert path.resolve().is_relative_to(folder)
        path.unlink()
        meta=Path(str(path)+'.meta')
        if meta.exists():meta.unlink()
