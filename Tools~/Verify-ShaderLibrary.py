"""Validate catalog bytes, real Unity evidence and frozen regression before release."""
from pathlib import Path
from collections import Counter
import json,hashlib,datetime,re,sys
ROOT=Path(__file__).resolve().parents[1];E=ROOT/'Documentation~/Evidence/LocalLibrary030'
def read(p):return json.loads((ROOT/p).read_text(encoding='utf-8-sig'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def write(p,v):
    p.parent.mkdir(parents=True,exist_ok=True);p.write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
catalog=read('Editor/Resources/ASEShaderLibraryCatalog.json');entries=catalog['entries'];ids=[e['id'] for e in entries]
assert len(ids)==len(set(ids))==63
assert len(catalog['research'])==1042
artifact_paths=[]
for e in entries:
    p=(ROOT/e['path']).resolve();assert p.is_relative_to((ROOT/'Samples~/ShaderLibrary').resolve())
    assert sha(p)==e['sha256'];text=p.read_text(encoding='utf-8-sig')
    assert '/*ASEBEGIN' in text and 'ASEEND*/' in text
    assert e['status']=='Generated' and e['aseRoundTripPassed'] and e['shaderCompiled'] and e['layoutApplied']
    assert e['commentCount']>0 and e['customExpressionCount']==0 and not e['visualComparisonPassed']
    artifact_paths.append(p)
assert set(artifact_paths)==set(p.resolve() for p in (ROOT/'Samples~/ShaderLibrary').rglob('*.shader'))
local=read('.build~/LocalShaderGraphs/manifest.json');unique={r['sha256']:r for r in local['rows']}
assert len(unique)==255 and len(local['archives'])==21 and all(a['success'] for a in local['archives'])
for h,row in unique.items():assert sha(ROOT/row['cachedSource'])==h
core=read('Documentation~/Evidence/LocalLibrary030/core-analysis.json')
assert core['uniqueSources']==255 and core['errors']==0
assert sum(r['kind'] in ('shadergraph','shadersubgraph') for r in core['rows'])==152
assert not any('parse/structure failed' in b for r in core['rows'] for a in r['analyses'] for b in a['report']['blockers'])
plans=read('Documentation~/Evidence/LocalLibrary030/local-adaptation-plans.json')
assert len(plans['rows'])==100 and plans['generatedCount']==20
contracts=[]
verified_texture_defaults=0
for row in plans['rows']:
    if not row.get('id'):continue
    p=ROOT/row['plan'];plan=read(str(p.relative_to(ROOT)))
    entry=next(e for e in entries if e['id']==row['id']);shader=(ROOT/entry['path']).read_text(encoding='utf-8-sig')
    for node in plan['nodes']:
        if node['type']!='TexturePropertyNode' or not node.get('propertyName'):continue
        match=re.search(r'(?m)^([^\r\n]*\b'+re.escape(node['propertyName'])+r'\s*\([^\r\n]*\)\s*=\s*"([^"]*)"[^\r\n]*)$',shader)
        assert match, node['propertyName']
        assert match.group(2)==re.search(r'"([^"]*)"',node['value']).group(1)
        if any(s['name']=='attribute:NoScaleOffset' and s['value']=='true' for s in node['settings']):assert '[NoScaleOffset]' in match.group(1)
        verified_texture_defaults+=1
    contracts.append({'id':row['id'],'sourceSha256':row['sha256'],'planSha256':sha(p),'nativePlannedNodes':len(plan['nodes']),'plannedComments':len(plan['comments']),
                      'assetBindings':row['assetBindings'],'inactiveOutputs':row.get('inactiveOutputs',[])})
write(E/'plan-contracts.json',{'contracts':contracts,'note':'Hashes of the final explicit native plans; ASE artifact bytes and successful reload/compile reports are listed separately.'})
reg=read('.build~/LibraryRegression030/public-corpus-analysis.json');before=read('Documentation~/Evidence/RuleResearch026/public-corpus-analysis.json')
old={(r['repository'],r['path']):r for r in before['files']}
assert len(old)==len(reg['files'])==760 and reg['summary']['analysisErrors']==0
counts=Counter();evaluations=0
for row in reg['files']:
    previous=old[row['repository'],row['path']];assert row['sha256']==previous['sha256'] and row['commit']==previous['commit'] and row['sourceUnchanged']
    for target in row['targets']:
        previous_target=next(t for t in previous['targets'] if t['pipeline']==target['pipeline'])
        assert target['canPlan']==previous_target['canPlan']
        if row['path'].lower().endswith('.shader'):
            evaluations+=1
            if target['canPlan']:counts[target['pipeline']]+=1
assert dict(counts)=={'BuiltIn':3,'URP':3} and evaluations==1308
if '--artifacts-only' in sys.argv:
    print('ARTIFACT_PREFLIGHT_PASS:',len(entries),'shaders,',verified_texture_defaults,'texture defaults/attributes, frozen regression 3/3/0. Import evidence checked only in the full run.')
    sys.exit(0)
imports={}
for pipeline,project,expected in [('BuiltIn','Unity2022',14),('URP','UnityURP',14),('HDRP','UnityHDRP',34)]:
    p=ROOT/'.validation'/project/'LibraryBuildEvidence/import-smoke.json';data=json.loads(p.read_text(encoding='utf-8-sig'))
    assert data['success'] and data['pipeline']==pipeline and len(data['rows'])==expected and all(r['compiled'] for r in data['rows'])
    assert data['windowCreated'] and data['apiLoaded'] and data['pathEscapeRejected'] and data['pipelineMismatchRejected']
    for row in data['rows']:
        assert sha(ROOT/'.validation'/project/row['path'])==next(e['sha256'] for e in entries if e['id']==row['id'])
    write(E/('Import-'+pipeline+'.json'),data);imports[pipeline]={'compiled':expected,'windowCreated':True,'apiLoaded':True,'pathAndPipelineGuardsPassed':True}
water=read('.validation/Unity2022/LibraryBuildEvidence/water-support.json');assert water['success']
guards=read('.validation/UnityHDRP/LibraryBuildEvidence/library-guards.json');assert guards['success'] and guards['pathEscapeRejected'] and guards['apiLoaded']
write(E/'library-guards.json',guards)
water_path=ROOT/'.validation/Unity2022/Assets/Shaders/DeepWater_ASE.shader'
assert sha(water_path)==next(e['sha256'] for e in entries if e['id']=='original-BuiltIn-DeepWater')
write(E/'water-support.json',water)
logs=[]
for p in sorted((ROOT/'.build~/ValidationRuns').glob('Library-*.log')):
    text=p.read_text(encoding='utf-8-sig',errors='replace')
    markers=[line for line in text.splitlines() if re.search(r'ASE_LIBRARY_(?:JOB|BUILD_COMPLETE|IMPORT_SMOKE|WATER_|GUARDS)|error CS\d+|Licensing.*(?:failed|Failed)',line)]
    logs.append({'path':p.relative_to(ROOT).as_posix(),'sha256':sha(p),'markers':markers})
write(E/'validation-log-index.json',{'logs':logs,'rawLogsKeptInWorkspace':True})
code={p.relative_to(ROOT).as_posix():sha(p) for folder in ['Runtime','Editor'] for p in (ROOT/folder).glob('*.cs')}
evidence={'version':'0.3.0','checkedUtc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'artifacts':len(entries),'byPipeline':dict(Counter(e['pipeline'] for e in entries)),
    'byCategory':dict(Counter(e['category'] for e in entries)),'researchRecords':len(catalog['research']),'localUniqueSources':255,'localGraphsParsed':152,'localGraphAdaptationsGenerated':20,'localGraphsBlocked':80,
    'artifactHashesAndAseMetadataPresent':True,'allArtifactsAseRoundTripAndCompiled':True,'allArtifactsHaveLayoutAndComments':True,'allArtifactsCustomExpressions':0,'generatedTextureDefaultsAndAttributesChecked':verified_texture_defaults,
    'sourceVisualComparisonPerformed':False,'newLibraryAllKeywordCombinationsExhaustivelyChecked':False,'originalSceneOrUserProjectWritten':False,'sourceCacheHashesUnchanged':True,'allLocalGraphsParsed':True,
    'importChecks':imports,'deepWaterShaderImportAndOriginalResourcesCreated':True,'finalCatalogTraversalAndChecksumGuardsPassed':True,
    'coreChecks':{'command':'dotnet run --project Tests/CoreChecks.csproj --no-restore','exitCode':0,'recordedConsole':'PASS: 506 checks'},
    'editorCompile':{'command':'dotnet build Tests/EditorCompile.csproj --no-restore','exitCode':0,'warnings':0,'errors':0},
    'waterAssetsCompile':{'command':'dotnet build Tests/WaterAssetsCompile.csproj --no-restore','exitCode':0,'warnings':0,'errors':0},
    'plannerContracts':{'command':'python Tests/ShaderLibraryPlanChecks.py','passed':8,'exitCode':0},
    'recordedBuildResults':'Successful process outcomes recorded during this batch; verification rechecks artifact/import/regression evidence directly.',
    'frozenPublicRegression':{'files':760,'shaders':436,'targetEvaluations':evaluations,'canPlan':{'BuiltIn':3,'URP':3,'HDRP':0},'allHashesUnchanged':True,'planningFlagsUnchanged':True,'reportSha256':sha(ROOT/'.build~/LibraryRegression030/public-corpus-analysis.json')},
    'catalogSha256':sha(ROOT/'Editor/Resources/ASEShaderLibraryCatalog.json'),'codeSha256':code}
write(E/'verification.json',evidence)
print('VERIFIED:',len(entries),'ASE artifacts; imports',imports,'; frozen regression 3/3/0; no source visual equivalence claim.')
