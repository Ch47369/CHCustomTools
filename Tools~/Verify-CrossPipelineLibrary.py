"""Verify correspondence, all delivered hashes, and fresh public-entry evidence."""
from pathlib import Path
from collections import Counter
import json,hashlib
ROOT=Path(__file__).resolve().parents[1]
def read(path):return json.loads((ROOT/path).read_text(encoding='utf-8-sig'))
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
catalog=read('Editor/Resources/ASEShaderLibraryCatalog.json');entries=catalog['entries'];contracts=catalog['familyContracts']
version=catalog['version'];assert version==read('package.json')['version'] and version in ('0.3.2','0.3.3')
expanded=version=='0.3.3';E=ROOT/('Documentation~/Evidence/PublicLibrary033' if expanded else 'Documentation~/Evidence/CrossPipeline032')
total=287 if expanded else 275;families=109 if expanded else 105;mapped=64 if expanded else 60;complete=89 if expanded else 85
counts={'BuiltIn':89,'URP':89,'HDRP':109} if expanded else {'BuiltIn':85,'URP':85,'HDRP':105}
assert len(entries)==total and len({e['id'] for e in entries})==total
assert Counter(e['pipeline'] for e in entries)==counts
assert len(contracts)==families and len({c['familyId'] for c in contracts})==families
entry_by_id={e['id']:e for e in entries}
for e in entries:
    assert e['status']=='Generated' and e['aseRoundTripPassed'] and e['shaderCompiled'] and e['layoutApplied']
    assert e['customExpressionCount']==0 and e['commentCount']>0
    path=ROOT/e['path'];assert sha(path)==e['sha256']
    text=path.read_text(encoding='utf-8-sig');assert '/*ASEBEGIN' in text and 'ASEEND*/' in text
assert set(c['familyId'] for c in contracts)==set(e['familyId'] for e in entries)
for c in contracts:
    assert len(c['targets'])==3 and {t['pipeline'] for t in c['targets']}=={'BuiltIn','URP','HDRP'}
    for t in c['targets']:
        if t['status']=='RequiresAdapter':assert not t['entryId'] and t['gaps']
        else:
            e=entry_by_id[t['entryId']];assert e['familyId']==c['familyId'] and e['pipeline']==t['pipeline']
            assert t['status']==('FeatureGap' if t['gaps'] else 'Mapped')
    assert c['sourceIdentity'] and c['comparisonStatus']=='NotCompared'
assert sum(all(t['status']=='Mapped' for t in c['targets']) for c in contracts)==mapped
assert Counter(t['status'] for c in contracts for t in c['targets'])=={'Mapped':238 if expanded else 226,'FeatureGap':49,'RequiresAdapter':40}
water_checks=[];batch_checks=[]
for p,n in counts.items():
    b=read(E.relative_to(ROOT)/('Batch-'+p+'.json'))
    assert b['success'] and b['pipeline']==p and len(b['rows'])==n
    assert b['correspondenceContractCount']==families and b['mappedFamilyCount']==mapped
    assert b['waterKeywordChecks']==8 and b['waterTextureBindings']==2
    assert b['materialEditsPreserved'] and b['cancelled'] and b['materialStatesInitialized']
    assert all(i['success'] for i in b['rows'])
    batch_checks.append({'pipeline':p,'materials':n,'waterKeywords':8,'waterTextures':2})
for p in ('URP','HDRP'):
    r=read(Path('Documentation~/Evidence/CrossPipeline032')/('Water-'+p+'.json'))
    assert r['success'] and r['pipeline']==p and not r['visualEquivalence'] and len(r['checks'])==13
    assert all(c['compiled'] for c in r['checks'])
    for name in ('Without_DEPTH','Without_CAUSTICS','DensityHigh'):assert next(c for c in r['checks'] if c['name']==name)['changedPixels']>=32
    copy=next(c for c in r['checks'] if c['name']=='OpaqueBedReference');assert copy['meanDifference']<=.015
    water_checks.append({'pipeline':p,'states':13,'sceneTransmissionMeanDifference':copy['meanDifference'],'depthAndDensityVisible':True})
signatures=read(E.relative_to(ROOT)/'computation-signatures.json')['families']
assert len(signatures)==families and sum(s['allThreePlansPresent'] for s in signatures)==complete
assert all(s['sharedOutputComputationsMatch'] for s in signatures)
filter_checks=[]
if expanded:
    checks=read(E.relative_to(ROOT)/'checks.json')
    assert checks['coreChecks']==523 and checks['editorCompile']=={'warnings':0,'errors':0} and checks['pythonCorrespondenceTests']==6
    public=read(E.relative_to(ROOT)/'library-entries.json')['entries'];assert len(public)==12
    for p in counts:
        build=read(E.relative_to(ROOT)/('Build-'+p)/'results.json');assert build['completed'] and build['pipeline']==p and len(build['rows'])==4
        for row in build['rows']:
            report=row['response']['report'];entry=entry_by_id[row['id']]
            assert row['response']['success'] and report['status']=='Generated' and report['aseRoundTripPassed'] and report['shaderCompiled']
            assert report['shaderName']=='ASELibrary/'+p+'/PublicFilters/'+entry['recipe']
        evidence=read(E.relative_to(ROOT)/('Filters-'+p+'.json'))
        assert evidence['success'] and evidence['pipeline']==p and len(evidence['checks'])==13
        assert not evidence['cameraIntegration'] and not evidence['crossPipelineVisualEquivalence']
        assert all(c['compiled'] for c in evidence['checks'])
        assert sum(c['oracleCompared'] for c in evidence['checks'])==12
        assert all(c['meanError']<=.002 for c in evidence['checks'] if c['oracleCompared'])
        assert next(c for c in evidence['checks'] if c['state']=='GlobalSymmetryTrue')['changedPixels']>=32
        filter_checks.append({'pipeline':p,'states':13,'oracleStates':12,'maxMeanError':max(c['meanError'] for c in evidence['checks']),'globalKeywordValidated':True})
    research=read(E.relative_to(ROOT)/'source-analysis.json');assert len(research['rows'])==41 and research['adaptedSources']==4 and research['remainingNewSources']==37
    assert len(catalog['research'])==1079
result={'success':True,'version':version,'artifacts':total,'families':families,'threeArtifactFamilies':complete,'threeMappedTargetFamilies':mapped,
        'crossPipelineVisualEquivalenceProven':False,'batchChecks':batch_checks,'waterFixtureChecks':water_checks,
        'coreChecks':523,'editorCompile':'0 warnings / 0 errors','pythonCorrespondenceTests':6 if expanded else 4,
        'allArtifactHashesAndContractsVerified':True,'sourceProjectsModified':False,
        'remaining':{'missingPipelineVersions':40,'existingVersionsWithKnownFeatureGaps':49,'localSourceGraphsStillBlocked':80}}
if expanded:result.update(publicFilterChecks=filter_checks,newDownloadedFiles=41,newResearchIdentities=37,newSourceFamilies=4,newGeneratedArtifacts=12,newSourcesRequiringAdapter=37,waterChecksAreHistorical032=True)
(E/'verification.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps(result,ensure_ascii=True))
