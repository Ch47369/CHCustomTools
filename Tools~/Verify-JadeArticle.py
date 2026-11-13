"""Validate the current jade release without replacing historical evidence."""
from pathlib import Path
import json,hashlib,struct,tarfile
ROOT=Path(__file__).resolve().parents[1];E=ROOT/'Documentation~/Evidence/JadeArticle036';CACHE=ROOT/'.build~/JadeReference036'
HOSTS={'BuiltIn':'Unity2022','URP':'UnityURP','HDRP':'UnityHDRP'}
def read(p):return json.loads((ROOT/p).read_text(encoding='utf-8-sig'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def write(p,v):p.write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
def main():
    catalog=read('Editor/Resources/ASEShaderLibraryCatalog.json');baseline=read(CACHE/'baseline-catalog.json');review=read(E/'source-review.json');rows=[];maximum=0
    release=ROOT/'Releases~/com.aseshader.handwritten-converter-0.3.5.tgz'
    assert sha(release)=='9ef6ba50880083f80b1f89a357f793d39752614e227b62622f8c15fedb2f2941'
    with tarfile.open(release) as archive:assert json.load(archive.extractfile('package/Editor/Resources/ASEShaderLibraryCatalog.json'))==baseline
    assert catalog['version']=='0.3.6' and review['codeSha256']=='a9cc314b7587c26e32c17e12fd87f0a8dffb19447ad5528a1522e33dac99993f'
    assert sha(CACHE/'reference-function.hlsl.txt')==review['codeSha256']
    for old in baseline['entries']:
        new=next(e for e in catalog['entries'] if e['id']==old['id']);assert old==new and sha(ROOT/new['path'])==old['sha256'],old['id']
    assert all(next(c for c in catalog['familyContracts'] if c['familyId']==old['familyId'])==old for old in baseline['familyContracts'])
    assert all(next(r for r in catalog['research'] if r['id']==old['id'])==old for old in baseline['research'])
    for p,host in HOSTS.items():
        folder=ROOT/'.validation'/host/'LibraryBuildEvidence';e=next(e for e in catalog['entries'] if e['id']=='jade-article-'+p)
        assert sha(ROOT/e['path'])==e['sha256'] and e['aseRoundTripPassed'] and e['shaderCompiled'] and e['customExpressionCount']==0 and not e['visualComparisonPassed']
        r=read(folder/'jade-validation-036.json');b=read(folder/'jade-batch-036.json')
        assert r['success'] and r['pipeline']==p and r['colorSpace']=='Linear' and len(r['formula'])==14 and r['realCamera'] and not r['originalSceneEquivalent']
        assert b['success'] and b['apiLoaded'] and b['windowOpened'] and b['editsPreserved'] and b['keywordInitialized']
        maximum=max(maximum,max(x['maxError'] for x in r['formula']))
        rows.append({'pipeline':p,'nativeNodes':e['nativeNodeCount'],'comments':e['commentCount'],'formulaStates':len(r['formula']),'maxFormulaError':max(x['maxError'] for x in r['formula']),'realCameraPassed':True,'sceneChangedPixels':r['sceneChangedPixels'],'sceneLightChangedPixels':r['sceneLightChangedPixels'],'installAndReusePassed':True})
        write(E/('Build-'+p)/'jade-batch-036.json',b)
    crosses=[]
    states=read(ROOT/'.validation/Unity2022/LibraryBuildEvidence/jade-validation-036.json')['formula']
    for p in ('URP','HDRP'):
        for state in states:
            name=state['state'];a=(ROOT/'.validation/Unity2022/LibraryBuildEvidence/JadeArticle036'/(name+'.rgba32f')).read_bytes();b=(ROOT/'.validation'/HOSTS[p]/'LibraryBuildEvidence/JadeArticle036'/(name+'.rgba32f')).read_bytes();assert len(a)==len(b)
            error=max(abs(x-y) for (x,),(y,) in zip(struct.iter_unpack('<f',a),struct.iter_unpack('<f',b)));assert error<.0001,(p,name,error)
            crosses.append({'pipeline':p,'state':name,'maxChannelDifference':error})
    core=(E/'core-checks.txt').read_text(encoding='utf-8-sig');editor=(E/'editor-compile.txt').read_text(encoding='utf-8-sig')
    assert 'PASS: 540 checks' in core and ('0 个警告' in editor or '0 Warning(s)' in editor) and ('0 个错误' in editor or '0 Error(s)' in editor)
    result={'success':True,'version':'0.3.6','source':review['url'],'scope':'Article core function plus newly authored Lit integration; fixed formula fixture comparisons and actual-camera behavior. No original complete material/scene equivalence or benchmark claim.','originalSceneEquivalent':False,'originalCompleteShaderAvailable':False,'rows':rows,'maxFormulaError':maximum,'crossPipelineFormulaPairs':len(crosses),'crossPipelineFormulaMaxDifference':max(c['maxChannelDifference'] for c in crosses),'oldArtifactsUnchanged':len(baseline['entries']),'baselineReleaseSha256':sha(release),'oldContractsAndResearchPreserved':True,'coreChecks':540,'editorCompileWarnings':0,'editorCompileErrors':0}
    write(E/'cross-pipeline-formula.json',crosses);write(E/'verification.json',result);print(json.dumps(result,ensure_ascii=False,indent=2))
if __name__=='__main__':main()
