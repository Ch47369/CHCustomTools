"""Collect fresh public-entry/filter evidence without distributing editor logs."""
from pathlib import Path
import json,hashlib,shutil,re
ROOT=Path(__file__).resolve().parents[1];E=ROOT/'Documentation~/Evidence/PublicLibrary033';CACHE=ROOT/'.build~/PublicLibrary033'
HOSTS={'BuiltIn':'Unity2022','URP':'UnityURP','HDRP':'UnityHDRP'}
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def write(p,o):p.write_text(json.dumps(o,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
def read_log(p):
    data=p.read_bytes();return data.decode('utf-16' if data.startswith((b'\xff\xfe',b'\xfe\xff')) else 'utf-8-sig',errors='replace')
catalog=read(ROOT/'Editor/Resources/ASEShaderLibraryCatalog.json');assert catalog['version']=='0.3.3'
baseline=read(CACHE/'base-catalog.json');assert {r['id'] for r in baseline['research']}<={r['id'] for r in catalog['research']}
images=[];fixtures=[]
for pipeline,host in HOSTS.items():
    project=ROOT/'.validation'/host;source=project/'LibraryBuildEvidence';count=sum(e['pipeline']==pipeline for e in catalog['entries'])
    batch=read(source/'batch-smoke-031.json');filters=read(source/'public-filters-033.json')
    assert batch['success'] and batch['pipeline']==pipeline and len(batch['rows'])==count and all(r['success'] for r in batch['rows'])
    assert batch['correspondenceContractCount']==109 and batch['mappedFamilyCount']==64
    assert filters['success'] and filters['pipeline']==pipeline and len(filters['checks'])==13
    assert 'ASE_PUBLIC_FILTER_SMOKE '+pipeline+' True 13' in (CACHE/('filters-'+pipeline+'.log')).read_text(encoding='utf-8-sig')
    assert 'ASE_LIBRARY_BATCH_SMOKE '+pipeline+' True '+str(count) in (CACHE/('batch-'+pipeline+'.log')).read_text(encoding='utf-8-sig')
    shutil.copy2(source/'batch-smoke-031.json',E/('Batch-'+pipeline+'.json'));shutil.copy2(source/'public-filters-033.json',E/('Filters-'+pipeline+'.json'))
    for check in filters['checks']:
        path=project/check['image'];target=E/('Filters-'+pipeline)/path.name;target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(path,target)
        images.append({'pipeline':pipeline,'id':check['id'],'state':check['state'],'path':target.relative_to(ROOT).as_posix(),'sha256':sha(target)})
    fixtures.append({'pipeline':pipeline,'states':13,'oracleStates':sum(c['oracleCompared'] for c in filters['checks']),'maximumMeanError':max(c['meanError'] for c in filters['checks']),
                     'sameShaderIdentity':all(c['id'].startswith('public-'+pipeline+'-') for c in filters['checks'])})
    for harness in ('UnityLibraryBuild.cs','UnityLibraryBatchSmoke.cs','UnityPublicFilterSmoke.cs'):
        assert sha(ROOT/'Tests'/harness)==sha(project/'Assets/Editor'/harness),('Harness changed after validation',pipeline,harness)
check_names=('core-checks.log','editor-compile.log','python-checks.log');check_logs={n:read_log(CACHE/n) for n in check_names}
assert 'PASS: 523 checks' in check_logs['core-checks.log']
assert re.search(r'0\s+个警告',check_logs['editor-compile.log']) and re.search(r'0\s+个错误',check_logs['editor-compile.log'])
assert 'Ran 6 tests' in check_logs['python-checks.log'] and 'OK' in check_logs['python-checks.log']
write(E/'checks.json',{'coreChecks':523,'editorCompile':{'warnings':0,'errors':0},'pythonCorrespondenceTests':6,'logs':[{'path':(CACHE/n).relative_to(ROOT).as_posix(),'sha256':sha(CACHE/n)} for n in check_names]})
logs=[]
for log in sorted(CACHE.rglob('*.log')):
    text=read_log(log);logs.append({'path':log.relative_to(ROOT).as_posix(),'sha256':sha(log),'bytes':log.stat().st_size,
        'licenseLaunchFailure':'No valid Unity Editor license found' in text,'generationCompleted':'ASE_LIBRARY_BUILD_COMPLETE' in text,
        'filterPassed':bool('ASE_PUBLIC_FILTER_SMOKE' in text and 'True 13' in text),'batchPassed':bool('ASE_LIBRARY_BATCH_SMOKE' in text and ' True ' in text),
        'hasCompilationOrGenerationDiagnostics':'Exception:' in text or 'Shader error' in text or 'error CS' in text})
write(E/'validation-log-index.json',{'logsRemainInNonDistributedCache':True,'logs':logs,'harnesses':[{'path':'Tests/'+name,'sha256':sha(ROOT/'Tests'/name)} for name in ('UnityLibraryBuild.cs','UnityLibraryBatchSmoke.cs','UnityPublicFilterSmoke.cs')]})
write(E/'fixture-images.json',{'images':images,'checks':fixtures,'scope':'Explicit textures and raw floating RT readback. No camera injection, actual history capture, mobile benchmark, or original-scene equivalence.'})
print(json.dumps({'batchCounts':{p:sum(e['pipeline']==p for e in catalog['entries']) for p in HOSTS},'filters':fixtures,'images':len(images),'historicalResearchIdsPreserved':True},ensure_ascii=True))
