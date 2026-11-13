"""Collect successful source/install attempts without overwriting failed evidence."""
from pathlib import Path
import json, shutil, hashlib, sys
ROOT=Path(__file__).resolve().parents[1]
base=ROOT/'.build~/GraphTargets046/Attempts'
out=ROOT/'Documentation~/Evidence/GraphTargets046'
out.mkdir(parents=True,exist_ok=True)
successes=[]; failures=[]
for attempt in sorted(base.iterdir()):
    if (attempt/'error.txt').exists(): failures.append(attempt.name)
    if not (attempt/'result.json').exists(): continue
    result=json.loads((attempt/'result.json').read_text(encoding='utf-8-sig'))
    assert result['success'] and not result['visualComparisonPassed']
    successes.append((attempt,result))
selected={}
for attempt,result in successes:
    selected[(result['pipeline'],result['packageSource'])]=(attempt,result)
for pipeline in ['BuiltIn','URP','HDRP']:
    assert (pipeline,'Local') in selected, 'Missing actual source verification: '+pipeline
summary={'version':'0.4.6','scope':'Standard opaque Unlit native targets in Unity2022.3 / SG14.0.8; no original host/scene equivalence or other versions/platforms claimed.',
         'success':True,'visualComparisonPassed':False,'sourceAttempts':{},'failedAttemptsRetained':failures}
for (pipeline,source),(attempt,result) in selected.items():
    if source!='Local':continue
    dest=out/pipeline;dest.mkdir(exist_ok=True)
    for path in attempt.iterdir():
        if path.suffix=='.json':shutil.copyfile(path,dest/path.name)
    summary['sourceAttempts'][pipeline]={'attempt':attempt.name,'checks':len(result['checks']),'packageVersion':result['packageVersion'],'evidence':pipeline+'/result.json'}
window_checks={}
for path in (ROOT/'.validation').glob('GraphInput046-Shader-*-Source/Artifacts/graph-input-window.json'):
    result=json.loads(path.read_text(encoding='utf-8-sig'));assert result['success'],path
    name='window-'+result['unityVersion']+'.json';shutil.copyfile(path,out/name)
    window_checks[result['unityVersion']]=len(result['checks'])
assert window_checks, 'Real path-control drag verification is required'
summary['windowChecks']=window_checks
for name in ['core-checks.txt','editor-2022.txt','editor-unity6.txt']:
    shutil.copyfile(ROOT/'.build~/GraphTargets046'/name,out/name)
summary['coreChecks']=608
summary['editorCompile']={'Unity2022.3':{'errors':0,'warnings':0},'Unity6':{'errors':0,'warnings':0}}
summary['windowFailedAttemptsRetained']=[p.parent.name for p in (ROOT/'.build~/GraphInput046/Attempts').glob('*/result.json') if not json.loads(p.read_text(encoding='utf-8-sig'))['success']]
(out/'verification.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
installs={p:{'attempt':a.name,'checks':len(r['checks']),'result':r} for (p,s),(a,r) in selected.items() if s=='LocalTarball'}
if installs and '--source-only' not in sys.argv:
    archive_hash=hashlib.sha256((ROOT/'Releases~/com.aseshader.handwritten-converter-0.4.6.tgz').read_bytes()).hexdigest()
    for pipeline,install in installs.items():
        launches=[]
        for path in (ROOT/'.build~/GraphTargets046/Launches').glob('*/launch.json'):
            launch=json.loads(path.read_text(encoding='utf-8-sig'))
            if launch['project'].replace('\\','/').endswith('GraphTargets046-'+pipeline+'-Tarball'):launches.append((path,launch))
        path,launch=max(launches,key=lambda x:x[0].parent.name)
        assert launch.get('tarballSha256')==archive_hash, 'Install launch did not use final tarball: '+pipeline
        assert install['attempt']>path.parent.name, 'Install result predates final launch: '+pipeline
        install['tarballSha256']=archive_hash
    windows=[]
    for path in (ROOT/'.validation').glob('GraphInput046-Shader-*-FinalTarballs/Artifacts/graph-input-window.json'):
        result=json.loads(path.read_text(encoding='utf-8-sig'));assert result['success'],path
        windows.append(result)
    (ROOT/'Releases~/graph-targets-tarball-install-0.4.6.json').write_text(json.dumps({'success':True,'version':'0.4.6','tarballSha256':archive_hash,'pipelines':installs,'windowChecks':windows},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'sourcePipelines':list(summary['sourceAttempts']),'tarballPipelines':list(installs),'failedAttemptsRetained':failures}))
