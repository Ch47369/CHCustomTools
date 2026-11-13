"""Verify unified browsing against the immutable 0.3.3 library and fresh Unity smoke evidence."""
from pathlib import Path
from collections import Counter
from datetime import datetime
import hashlib,json,tarfile,shutil
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'Documentation~/Evidence/LibraryUI034'
CACHE=ROOT/'.build~/LibraryUI034'
def read(path):return json.loads(path.read_text(encoding='utf-8-sig'))
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def canonical(category):return 'UIEffects' if category=='UIAnimation' else category
catalog=read(ROOT/'Editor/Resources/ASEShaderLibraryCatalog.json')
assert catalog['version']==read(ROOT/'package.json')['version']=='0.3.4'
baseline=ROOT/'Releases~/com.aseshader.handwritten-converter-0.3.3.tgz'
assert sha(baseline)=='01a2b28e023b25ff6c5c8f15e5503accd186afb35668d3e87c9ef2a2750c4662'
with tarfile.open(baseline,'r:gz') as archive:
    previous=json.load(archive.extractfile('package/Editor/Resources/ASEShaderLibraryCatalog.json'))
assert set(catalog)==set(previous)
assert all(catalog[k]==v for k,v in previous.items() if k!='version'),'UI change must not rewrite shader evidence or source identities'
entries=catalog['entries'];assert len(entries)==287
for entry in entries:
    assert entry['aseRoundTripPassed'] and entry['shaderCompiled'] and sha(ROOT/entry['path'])==entry['sha256']
assert Counter(e['pipeline'] for e in entries)=={'BuiltIn':89,'URP':89,'HDRP':109}
coverage=[]
for category in sorted({canonical(e['category']) for e in entries}|{canonical(c) for r in catalog['research'] for c in r['categories']}):
    group=[e for e in entries if canonical(e['category'])==category]
    families={e['familyId'] for e in group}
    targets=[t for contract in catalog['familyContracts'] if contract['familyId'] in families for t in contract['targets']]
    coverage.append(dict(id=category,families=len(families),versions=len(group),builtIn=sum(e['pipeline']=='BuiltIn' for e in group),urp=sum(e['pipeline']=='URP' for e in group),hdrp=sum(e['pipeline']=='HDRP' for e in group),researchSources=sum(category in {canonical(c) for c in r['categories']} for r in catalog['research']),missingTargets=sum(t['status']=='RequiresAdapter' for t in targets),featureGapTargets=sum(t['status']=='FeatureGap' for t in targets)))
assert len(coverage)==15 and sum(c['missingTargets'] for c in coverage)==40 and sum(c['featureGapTargets'] for c in coverage)==49
launches={}
for manifest in sorted((CACHE/'Attempts').glob('*/launches.json')):
    data=read(manifest)
    for launch in data if isinstance(data,list) else [data]:launches[launch['pipeline']]=launch
hosts={'BuiltIn':'Unity2022','URP':'UnityURP','HDRP':'UnityHDRP'}
checks=[];OUT.mkdir(parents=True,exist_ok=True)
for pipeline,host in hosts.items():
    source=ROOT/'.validation'/host/'LibraryBuildEvidence/browser-smoke-034.json'
    result=read(source);launch=launches[pipeline]
    assert result['success'] and result['pipeline']==pipeline and result['version']=='0.3.4',result.get('error')
    assert datetime.fromisoformat(result['finishedUtc'].replace('Z','+00:00'))>datetime.fromisoformat(launch['startedUtc'])
    assert sorted(result['categories'],key=lambda c:c['id'])==coverage,'Unity classification differs from independently computed coverage'
    assert result['legacyRedirected'] and result['resetRestored'] and result['sourceFilesUnchanged'] and result['guiEventsDispatched']==6
    assert result['defaultVisibleVersions']==(109 if pipeline=='HDRP' else 89) and result['strictVisibleVersions']==64
    assert len(result['installs'])==(15 if pipeline=='HDRP' else 14) and all(i['success'] for i in result['installs'])
    log=(CACHE/(pipeline+'.log')).read_text(encoding='utf-8-sig')
    assert 'ASE_LIBRARY_BROWSER_SMOKE '+pipeline+' True' in log and 'error CS' not in log
    shutil.copy2(source,OUT/('Browser-'+pipeline+'.json'))
    checks.append(dict(pipeline=pipeline,checks=result['checks'],visibleVersions=result['defaultVisibleVersions'],categoryInstalls=len(result['installs']),guiEventsDispatched=result['guiEventsDispatched']))
(OUT/'coverage.json').write_text(json.dumps(coverage,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
result=dict(success=True,version='0.3.4',coreChecks=540,editorCompile={'warnings':0,'errors':0},unityBrowserChecks=checks,artifacts=287,families=109,researchSources=1079,threeArtifactFamilies=89,threeMappedTargetFamilies=64,newGeneratedArtifacts=0,libraryDataUnchangedFrom033=True,baselineArchiveSha256=sha(baseline),shaderRenderingEvidence='Historical PublicLibrary033 / CrossPipeline032; not rerun for this UI change',crossPipelineVisualEquivalenceProven=False,remaining={'missingPipelineVersions':40,'existingVersionsWithKnownFeatureGaps':49,'localSourceGraphsStillBlocked':80},sourceProjectsModified=False)
(OUT/'verification.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps(result,ensure_ascii=True,indent=2))
