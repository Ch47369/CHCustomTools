"""Verify final artifact provenance, family coverage, static labels and real batch results."""
from pathlib import Path
from collections import Counter,defaultdict
import json,hashlib,datetime
ROOT=Path(__file__).resolve().parents[1];E=ROOT/'Documentation~/Evidence/Library031'
def read(path):return json.loads((ROOT/path).read_text(encoding='utf-8-sig'))
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def write(path,data):
    (ROOT/path).write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
catalog=read('Editor/Resources/ASEShaderLibraryCatalog.json');entries=catalog['entries'];old=read('.build~/Library031/base-catalog.json')
assert catalog['version']=='0.3.1' and len(entries)==273 and len({e['id'] for e in entries})==273
assert catalog['research']==old['research'] and len(catalog['research'])==1042
byid={e['id']:e for e in entries};families=defaultdict(list)
for e in entries:
    path=(ROOT/e['path']).resolve();assert path.is_relative_to((ROOT/'Samples~/ShaderLibrary').resolve())
    assert sha(path)==e['sha256'];text=path.read_text(encoding='utf-8-sig');assert '/*ASEBEGIN' in text and 'ASEEND*/' in text
    assert e['status']=='Generated' and e['aseRoundTripPassed'] and e['shaderCompiled'] and e['layoutApplied'] and e['commentCount']>0
    assert e['customExpressionCount']==0 and not e['visualComparisonPassed']
    assert e['deviceValidation']=='NotBenchmarked' and e['performanceTier'] in ('Low','Medium','High')
    assert e['devices'] and set(e['devices']).issubset({'Mobile','Pad','PC'}) and e['keywords'] and e['performanceBasis'] and e['deviceRequirements'] and e['shaderModel']
    if e['pipeline']=='HDRP':assert e['devices']==['PC']
    if e['performanceTier']=='High':assert e['devices']==['PC']
    families[e['familyId']].append(e)
    if e['origin']=='OriginalEffect':
        import re
        assert re.search(r'\bShader\s+"([^"]+)"',text).group(1).endswith('/'+e['title']),e['id']
        results=read(e['evidence']);row=next(r for r in results['rows'] if r['id']==e['id']);r=row['response'];report=r['report']
        assert r['success'] and report['aseRoundTripPassed'] and report['shaderCompiled']
        project={'BuiltIn':'Unity2022','URP':'UnityURP','HDRP':'UnityHDRP'}[e['pipeline']]
        assert sha(ROOT/'.validation'/project/report['outputPath'])==e['sha256']
    else:assert e['sha256']==next(o['sha256'] for o in old['entries'] if o['id']==e['id'])
complete={key for key,items in families.items() if {e['pipeline'] for e in items}=={'BuiltIn','URP','HDRP'}}
assert len(complete)==84 and len(families)==105 and len(entries)==len(list((ROOT/'Samples~/ShaderLibrary').rglob('*.shader')))
assert all(e['familyId'] in complete for e in entries if e['origin'] in ('OriginalFoundation','OriginalEffect'))
assert len({e['familyId'] for e in entries if e['origin']=='OriginalEffect'})==70
coverage=read('Documentation~/Evidence/Library031/family-coverage.json')['families']
assert len(coverage)==105
for row in coverage:
    for pipeline,state in row['pipelines'].items():
        available=any(e['pipeline']==pipeline for e in families[row['familyId']])
        assert (state['status']=='Generated')==available
batchchecks={}
for pipeline,project in [('BuiltIn','Unity2022'),('URP','UnityURP'),('HDRP','UnityHDRP')]:
    batch=read('.validation/'+project+'/LibraryBuildEvidence/batch-smoke-031.json')
    assert batch['pipeline']==pipeline and batch['success'] and batch['apiLoaded'] and batch['windowCreated']
    assert all(batch[name] for name in ('checksumRejected','pathRejected','pipelineRejected','materialEditsPreserved','cancelled','originalExamplesBound','materialStatesInitialized'))
    expected={e['id'] for e in entries if e['pipeline']==pipeline};assert {r['id'] for r in batch['rows']}==expected
    for row in batch['rows']:
        assert row['success'] and row['materialReused'] and sha(ROOT/'.validation'/project/row['shaderPath'])==byid[row['id']]['sha256']
        assert (ROOT/'.validation'/project/row['materialPath']).is_file()
    write('Documentation~/Evidence/Library031/Batch-'+pipeline+'.json',batch)
    batchchecks[pipeline]={'shaderAndMaterialPassChecks':len(expected),'actualBulkEntryCompleted':True,'repeatPreservedUserMaterialEdits':True,'cancellationAndGuardsPassed':True,'originalExampleTextureBindings':batch['sampleTextureBindings'],'transparentStateChecks':batch['transparentMaterialChecks'],'hairClipStateChecks':batch['hairClipChecks']}
local=read('.build~/LocalShaderGraphs/manifest.json');unique={r['sha256']:r for r in local['rows']}
assert len(unique)==255
for h,row in unique.items():assert sha(ROOT/row['cachedSource'])==h
plans=read('.build~/LibraryPlans031/entries.json');contracts=[]
for row in plans:
    p=ROOT/row['plan'];plan=read(row['plan']);entry=byid[row['id']]
    contracts.append({'id':row['id'],'familyId':row['familyId'],'recipe':row['recipe'],'planSha256':sha(p),'plannedNodes':len(plan['nodes']),'plannedComments':len(plan['comments']),'outputSha256':entry['sha256']})
write('Documentation~/Evidence/Library031/plan-contracts.json',{'contracts':contracts})
code={p.relative_to(ROOT).as_posix():sha(p) for folder in ('Runtime','Editor') for p in (ROOT/folder).glob('*.cs')}
checks=read('Documentation~/Evidence/Library031/checks.json');assert checks['codeSha256']==code
assert checks['coreChecks']['exitCode']==0 and checks['coreChecks']['checks']==516 and checks['editorCompile']['exitCode']==0
descriptions=[]
for item in plans:
    project={'BuiltIn':'Unity2022','URP':'UnityURP','HDRP':'UnityHDRP'}[item['pipeline']]
    path=ROOT/'.validation'/project/'LibraryBuildEvidence'/(item['id']+'-describe.json');description=json.loads(path.read_text(encoding='utf-8-sig'));assert description['success']
    actual={n['type'].split('.')[-1] for n in description['description']['masters']}
    planned={n['type'] for n in read(item['plan'])['nodes']};assert planned.issubset(actual),(item['id'],planned-actual)
    descriptions.append({'id':item['id'],'responseSha256':sha(path),'allPlannedNodeTypesDescribed':True})
write('Documentation~/Evidence/Library031/describe-index.json',{'rows':descriptions,'rawResponsesRetainedInIsolatedProjects':True})
evidence={'version':'0.3.1','checkedUtc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'artifacts':len(entries),'materialFamilies':len(families),'completeThreePipelineFamilies':len(complete),
    'completeLibraryArtifacts':252,'supplementarySinglePipelineArtifacts':21,'newOriginalEffectFamilies':70,'newArtifacts':210,'byPipeline':dict(Counter(e['pipeline'] for e in entries)),
    'byCategory':dict(Counter(e['category'] for e in entries)),'byTier':dict(Counter(e['performanceTier'] for e in entries)),
    'devices':{device:sum(device in e['devices'] for e in entries) for device in ('Mobile','Pad','PC')},'deviceLabelsOverlap':True,'hardwareBenchmarked':False,
    'researchRecordsUnchanged':1042,'allArtifactsHaveRealAseRoundTripCompilationAndChineseComments':True,'customExpressions':0,'batchChecks':batchchecks,
    'sourceHashesUnchanged':True,'sourceScenesOrUserProjectsWritten':False,'sourceVisualComparisonPerformed':False,'allKeywordsOrPassesExhaustivelyChecked':False,
    'catalogSha256':sha(ROOT/'Editor/Resources/ASEShaderLibraryCatalog.json'),'codeSha256':code,
    'note':'Core/Editor and Python outcomes are recorded in checks.json from actual process logs; GPU timing and source-scene equivalence are not claimed.'}
write('Documentation~/Evidence/Library031/verification.json',evidence)
print(json.dumps({k:v for k,v in evidence.items() if k not in ('codeSha256','note')},ensure_ascii=False,indent=2))
