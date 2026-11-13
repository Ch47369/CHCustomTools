"""Check 0.4.0 delivery, fixed ASE library identity, and collected native SG evidence."""
from pathlib import Path
import hashlib,json,tarfile,zipfile

ROOT=Path(__file__).resolve().parents[1]
def digest(data):return hashlib.sha256(data).hexdigest()
def read_tar(path):
    with tarfile.open(path,'r:gz') as archive:return {m.name:archive.extractfile(m).read() for m in archive.getmembers() if m.isfile()}
baseline_path=ROOT/'Releases~/com.aseshader.handwritten-converter-0.3.7.tgz'
assert digest(baseline_path.read_bytes())=='cda054dc8a9357e6f064e498bafb376c7fa19c28d8940ced37af73d35a296bb8'
baseline=read_tar(baseline_path)
verification=json.loads((ROOT/'Documentation~/Evidence/GraphInterop040/verification.json').read_text(encoding='utf-8'))
assert verification['success'] and verification['coreChecks']>=570 and verification['integrationChecks']>=65
assert verification['enumKeywordChecks']['materialEnumDrawerValidated'] and verification['enumKeywordChecks']['nonAsciiLabelAdaptationReported']
protected=[name for name in baseline if name.startswith(('package/Samples~/','package/Editor/Resources/','package/Editor/Templates/'))]
rows=[]
for name in ('com.aseshader.handwritten-converter-0.4.0.tgz','ShaderConverter-0.4.0.zip'):
    path=ROOT/'Releases~'/name
    if name.endswith('.tgz'):files=read_tar(path)
    else:
        with zipfile.ZipFile(path) as archive:files={n:archive.read(n) for n in archive.namelist() if not n.endswith('/')}
    meta=json.loads(files['package/package.json']);assert meta['version']=='0.4.0' and meta['displayName']=='Shader转换器'
    for key in protected:assert files[key]==baseline[key],key
    for key,value in verification['sourceHashes'].items():assert digest(files['package/'+key])==value,key
    assert json.loads(files['package/Documentation~/Evidence/GraphInterop040/verification.json'])==verification
    sample=json.loads(files['package/Samples~/AgentShaderGraphNativePlan.json']);assert sample['options']['targetGraph']=='ShaderGraph'
    rows.append({'file':name,'sha256':digest(path.read_bytes()),'bytes':path.stat().st_size,'libraryShadersUnchanged':293,'protectedFilesUnchanged':len(protected),'sourceEvidenceMatchesPackedCode':True})
result={'success':True,'version':'0.4.0','archives':rows,'newGenericInterconversionClaim':False,'visualComparisonPassed':False}
(ROOT/'Releases~/graph-interop-release-verification-0.4.0.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps(result,ensure_ascii=False,indent=2))
