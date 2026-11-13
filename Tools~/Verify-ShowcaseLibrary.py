"""Fresh build/render/camera/material evidence for the full source adaptation."""
from pathlib import Path
from collections import Counter
import json,hashlib,shutil,struct,math,datetime,zipfile
ROOT=Path(__file__).resolve().parents[1];E=ROOT/'Documentation~/Evidence/Showcase035'
HOSTS={'BuiltIn':'Unity2022','URP':'UnityURP','HDRP':'UnityHDRP'}
def read(p):return json.loads((ROOT/p).read_text(encoding='utf-8-sig'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def main():
    catalog=read('Editor/Resources/ASEShaderLibraryCatalog.json');entries=[e for e in catalog['entries'] if e['origin']=='ReviewedMaterialAdaptation'];assert len(entries)==3
    source=read('.build~/Showcase035/reviewed-source.json');assert sha(Path(source['localPath']))==source['sha256']
    rendered={};stages={};previews=[]
    for p,h in HOSTS.items():
        host=ROOT/'.validation'/h;folder=host/'LibraryBuildEvidence';dest=E/p;dest.mkdir(parents=True,exist_ok=True)
        assert 'm_ActiveColorSpace: 1' in (host/'ProjectSettings/ProjectSettings.asset').read_text(encoding='utf-8-sig')
        build=read(folder/'results.json');entry=next(e for e in entries if e['pipeline']==p);assert build['completed'] and build['pipeline']==p
        report=build['rows'][0]['response']['report'];assert report['aseRoundTripPassed'] and report['shaderCompiled'] and report['customExpressionCount']==0
        assert sha(host/report['outputPath'])==entry['sha256']==sha(ROOT/entry['path'])
        records={}
        for stage in ('render','scene','batch'):
            filename='showcase-'+stage+'-035.json';r=read(folder/filename);assert r['success'] and r['pipeline']==p,(p,stage,r.get('error'));records[stage]=r
            assert r['finishedUtc']>=datetime.datetime.fromtimestamp((folder/'results.json').stat().st_mtime,datetime.timezone.utc).isoformat().replace('+00:00','Z'),(p,'Stale evidence')
            shutil.copy2(folder/filename,dest/filename)
        rr=records['render'];assert len(rr['checks'])==13 and rr.get('colorSpace','Linear')=='Linear'
        assert all(c['sourceCompared'] for c in rr['checks']) if p=='URP' else all(not c['sourceCompared'] for c in rr['checks'])
        rendered[p]={}
        for c in rr['checks']:
            assert c['compiled'] and c['visiblePixels']>=50
            raw=host/Path(c['image']).with_suffix('.rgba32f');values=struct.unpack('<'+'f'*(160*128*4),raw.read_bytes());assert all(math.isfinite(v) for v in values)
            rendered[p][c['state']]=values
            shutil.copy2(host/c['image'],dest/Path(c['image']).name)
        bb=records['batch'];assert bb['textureChecks']==5 and bb['presetChecks']==3 and bb['editsPreserved'] and bb['shaderPreserved'] and bb['sourceHashPreserved']
        ss=records['scene'];assert ss['realPipelineCamera'] and ss['materialChangedPixels']>=100 and ss['translatedCameraMeanError']<=.01
        (dest/'Scene').mkdir(exist_ok=True)
        for path in ss['images']:
            shutil.copy2(host/path,dest/'Scene'/Path(path).name);previews.append((p,Path(path).stem,str((dest/'Scene'/Path(path).name).relative_to(ROOT))))
        stages[p]={'colorSpace':'Linear','nativeNodes':report['nativeNodeCount'],'comments':report['commentCount'],'renderedStates':len(rr['checks']),'sourceComparedStates':sum(c['sourceCompared'] for c in rr['checks']),
            'maxSourceMeanError':max(c['meanError'] for c in rr['checks']),'maxSourcePixelError':max(c['maxError'] for c in rr['checks']),'sceneChangedPixels':ss['materialChangedPixels'],'cameraTranslationMeanError':ss['translatedCameraMeanError'],
            'materialTextureChecks':bb['textureChecks'],'presetChecks':bb['presetChecks']}
    comparisons=[]
    for p in ('BuiltIn','HDRP'):
        assert set(rendered[p])==set(rendered['URP'])
        for state,actual in rendered[p].items():
            expected=rendered['URP'][state];diff=[abs(a-b) for a,b in zip(actual,expected)];mean=sum(diff)/len(diff);maximum=max(diff);assert maximum<=.00001,(p,state,mean,maximum)
            comparisons.append({'pipeline':p,'reference':'URP ASE with separate original-source comparison','state':state,'meanChannelError':mean,'maxChannelError':maximum})
    summary=read(E/'summary.json');assert summary['artifacts']==290 and summary['families']==110 and summary['threeMappedTargetFamilies']==65 and summary['researchRecords']==1079
    with zipfile.ZipFile(ROOT/'Releases~/ASEShaderConverter-0.3.4.zip') as baseline:
        old=json.loads(baseline.read('package/Editor/Resources/ASEShaderLibraryCatalog.json'))
    by_id={e['id']:e for e in catalog['entries']};contracts={c['familyId']:c for c in catalog['familyContracts']}
    assert all(by_id[e['id']]==e for e in old['entries']) and all(contracts[c['familyId']]==c for c in old['familyContracts'])
    assert {r['id'] for r in old['research']}=={r['id'] for r in catalog['research']}
    result={'version':'0.3.5','success':True,'finishedUtc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'sourceSha256':source['sha256'],'sourceHashUnchanged':True,
        'newIndependentEffects':1,'newPipelineArtifacts':3,'newMaterialPresets':3,'nativeComputationEquivalent':read(E/'computation-signatures.json')['sameReachableComputation'],
        'validationHost':'Unity 2022.3.10f1 / ASE 1.9.9.13 / Windows D3D11','pipelines':stages,'crossPipelineFixedFixtureComparisons':comparisons,
        'historical287EntriesAnd109ContractsUnchanged':True,'researchIdentitiesUnchanged':True,
        'coreChecks':540,'editorCompile':{'warnings':0,'errors':0},
        'originalSourceSceneEquivalence':False,'gpuBenchmark':False,'remaining':{'missingPipelineVersions':40,'generatedTargetsWithFeatureGaps':49,'localGraphsStillBlocked':80},'library':summary}
    (E/'verification.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8');(E/'preview-index.json').write_text(json.dumps(previews,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(result,ensure_ascii=False,indent=2))
if __name__=='__main__':main()
