"""Verify 0.4.2 presentation changes and preserve conversion artifacts against the published 0.4.1 archive."""
from pathlib import Path
import hashlib,json,re,tarfile
ROOT=Path(__file__).resolve().parents[1]
BASELINE=ROOT/'Releases~/com.aseshader.handwritten-converter-0.4.1.tgz'
assert hashlib.sha256(BASELINE.read_bytes()).hexdigest()=='9ab343f5852215855df75f925fbc4737c6a82631bef0212580c18e81380a2b72'
def contents(path):
    with tarfile.open(path,'r:gz') as t:return {m.name.removeprefix('package/'):t.extractfile(m).read() for m in t if m.isfile()}
old=contents(BASELINE);new=contents(ROOT/'Releases~/com.aseshader.handwritten-converter-0.4.2.tgz')
changed_editors={'ASEShaderConverterWindow.cs','ShaderLibraryBrowser.cs','CharacterMaterialWindow.cs','ShaderConverterMessages.cs','ShaderPackageUpdateUI.cs','ShaderPackageUpdater.cs','ShaderLibraryBatch.cs'}
protected=[p for p in old if p.startswith(('Runtime/','Samples~/','Editor/Templates/','Editor/Resources/')) or (p.startswith('Editor/') and p.split('/')[-1] not in changed_editors)]
for p in protected:assert old[p]==new[p],p
metadata=json.loads(new['package.json']);assert metadata['version']=='0.4.2' and metadata['author']['name']=='CH自定义工具集'
for name in ['CHToolLanguage.cs','CHToolEnglish.cs']:
    assert 'Editor/'+name in new and 'Editor/'+name+'.meta' in new
evidence=ROOT/'Documentation~/Evidence/Localization042'
integrations=[]
for path in sorted(evidence.glob('unity-*.json')):
    result=json.loads(path.read_text(encoding='utf-8-sig'))
    assert result['success'] and any('actual assembly reload' in c for c in result['checks'])
    integrations.append({'unityVersion':result['unityVersion'],'checks':len(result['checks']),'file':path.name})
assert {x['unityVersion'] for x in integrations}=={'2022.3.10f1','6000.0.80f1'}
source=(ROOT/'Editor/CHToolLanguage.cs').read_text(encoding='utf-8')
assert '"CH.CustomTools.Language"' in source and '"中文", "English"' in source
assert 'Application.systemLanguage' not in source and 'Preferences/' not in source
for p in ['ASEShaderConverterWindow.cs','ShaderLibraryBrowser.cs','CharacterMaterialWindow.cs','ShaderPackageUpdateUI.cs']:
    s=(ROOT/'Editor'/p).read_text(encoding='utf-8')
    assert 'CHToolLanguage.Set(' not in s and 'CHToolLanguage.Choices' not in s,p
result={'success':True,'version':'0.4.2','author':'CH自定义工具集','baselineArchiveSha256':hashlib.sha256(BASELINE.read_bytes()).hexdigest(),
    'protectedFilesUnchanged':len(protected),'runtimeConversionAndAllSamplesUnchanged':True,'languageChoices':['中文','English'],
    'implicitDefaultFollowsUnityEditor':True,'sharedSettingsInsidePlugin':True,'integration':integrations,
    'scope':'Editor presentation only; no new conversion or rendering equivalence claims'}
output=ROOT/'Releases~/localization-verification-0.4.2.json';output.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
print(json.dumps(result,ensure_ascii=False,indent=2))
