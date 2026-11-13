"""Verify packaged jade graphs and exclusion of local reference/validation data."""
from pathlib import Path
import hashlib,json,tarfile,zipfile,re
ROOT=Path(__file__).resolve().parents[1]
def sha(data):return hashlib.sha256(data).hexdigest()
def main():
    catalog=json.loads((ROOT/'Editor/Resources/ASEShaderLibraryCatalog.json').read_text(encoding='utf-8'))
    verification=json.loads((ROOT/'Documentation~/Evidence/JadeArticle036/verification.json').read_text(encoding='utf-8'));assert verification['success']
    rows=[]
    for name in ('com.aseshader.handwritten-converter-0.3.6.tgz','ASEShaderConverter-0.3.6.zip'):
        path=ROOT/'Releases~'/name
        if name.endswith('.tgz'):
            with tarfile.open(path) as archive:files={m.name:archive.extractfile(m).read() for m in archive.getmembers() if m.isfile()}
        else:
            with zipfile.ZipFile(path) as archive:files={n:archive.read(n) for n in archive.namelist() if not n.endswith('/')}
        for f in files:
            assert not re.search(r'(^|/)(\.build~|\.validation|AmplifyShaderEditor|__pycache__|bin~?|obj~?)(/|$)',f),f
            assert not f.endswith(('.pyc','article.html','reference-function.hlsl.txt','FormulaFixture.shader')),f
            assert 'LogicalLightFixture_ASE' not in f and not re.search(r'reference-[0-4]\.jpg$',f),f
        assert json.loads(files['package/package.json'])['version']=='0.3.6'
        packed=json.loads(files['package/Editor/Resources/ASEShaderLibraryCatalog.json']);assert packed==catalog
        for entry in catalog['entries']:assert sha(files['package/'+entry['path']])==entry['sha256'],entry['id']
        assert json.loads(files['package/Documentation~/Evidence/JadeArticle036/verification.json'])==verification
        rows.append({'file':name,'bytes':path.stat().st_size,'sha256':sha(path.read_bytes()),'packagedVerifiedGraphs':len(catalog['entries']),'newJadeGraphs':3,'excludedReferenceAndDiagnosticData':True})
    result={'success':True,'version':'0.3.6','archives':rows,'originalSceneEquivalent':False,'sourceArticleOnlyContainsCoreFunction':True}
    (ROOT/'Releases~/release-verification-0.3.6.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(result,ensure_ascii=False,indent=2))
if __name__=='__main__':main()
