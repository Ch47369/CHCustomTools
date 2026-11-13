"""Audit the new native targets while preserving all other runtime/editor/library bytes."""
from pathlib import Path
import tarfile,json,hashlib
ROOT=Path(__file__).resolve().parents[1]
baseline=ROOT/'Releases~/com.aseshader.handwritten-converter-0.4.5.tgz'
assert hashlib.sha256(baseline.read_bytes()).hexdigest()=='c6f276b721d3ddd8ed22898650facc3ded342745d68c2356961711d74871246a'
def read(path):
    with tarfile.open(path,'r:gz') as t:return {m.name.removeprefix('package/'):t.extractfile(m).read() for m in t.getmembers() if m.isfile()}
old=read(baseline);new=read(ROOT/'Releases~/com.aseshader.handwritten-converter-0.4.6.tgz')
allowed={'Runtime/ASEShaderConversionCore.cs','Runtime/ShaderGraphNativePlan.cs','Editor/ASEShaderConverterWindow.cs','Editor/ShaderGraphEditorBridge.cs','Editor/ShaderConverterApi.cs'}
protected=[]
for path,data in old.items():
    if path.startswith(('Runtime/','Editor/','Samples~/')) and path not in allowed:
        assert new[path]==data,'Unexpected protected change: '+path
        protected.append(path)
for path in allowed: assert new[path]==(ROOT/path).read_bytes()
evidence=json.loads(new['Documentation~/Evidence/GraphTargets046/verification.json'])
assert evidence['success'] and set(evidence['sourceAttempts'])=={'BuiltIn','URP','HDRP'}
for target in evidence['sourceAttempts']:
    result=json.loads(new['Documentation~/Evidence/GraphTargets046/'+target+'/result.json'])
    assert result['success'] and result['pipeline']==target and not result['visualComparisonPassed']
report={'success':True,'version':'0.4.6','baselineSha256':hashlib.sha256(baseline.read_bytes()).hexdigest(),'protectedFilesIdentical':len(protected),'changedProductFiles':sorted(allowed),'libraryShadersIdentical':293,'actualSourcePipelines':list(evidence['sourceAttempts']),'visualComparisonPassed':False}
(ROOT/'Releases~/graph-targets-verification-0.4.6.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps(report,ensure_ascii=False))
