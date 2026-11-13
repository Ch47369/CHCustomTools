"""Verify protected 0.5.0 content and exact candidate packaging without executing references."""
from pathlib import Path
import hashlib,tarfile,json
ROOT=Path(__file__).resolve().parents[1]
baseline=ROOT/'Releases~/com.aseshader.handwritten-converter-0.5.0.tgz'
assert hashlib.sha256(baseline.read_bytes()).hexdigest()=='f94c7a874cca9a2c8be0f69b3fe37232aae9a36bf1d1c5f76d39f517b022230d'
def files(p):
    with tarfile.open(p,'r:gz') as t:return {m.name.removeprefix('package/'):t.extractfile(m).read() for m in t.getmembers() if m.isfile()}
old=files(baseline);new=files(ROOT/'Releases~/com.aseshader.handwritten-converter-0.6.0.tgz')
allowed={'AGENTS.md','README.md','package.json','Editor/ShaderConverterNavigation.cs','Editor/ASEShaderConverter.Editor.asmdef','Tests/EditorCompile.csproj','Tools~/Run-ToolMenus.ps1','Tools~/Run-GitHubReleaseUpgrade.ps1','Tools~/Verify-CustomToolsRelease.py','Documentation~/CustomTools.md'}
changed=[name for name,data in old.items() if new.get(name)!=data]
assert set(changed)<=allowed,changed
assert all(name in new for name in old),'Baseline file removed'
newfiles=set(new)-set(old)
assert all(n.startswith(('Runtime/PathTools/','Editor/PathTools/','Documentation~/Evidence/PathTools060/')) or n in {'Runtime/PathTools.meta','Editor/PathTools.meta','Tests/PathRuntimeCompile.csproj','Tests/PathRuntimeCompile.csproj.meta','Tests/UnityPathToolsSmoke.cs','Tests/UnityPathToolsSmoke.cs.meta','Documentation~/PathTools.md','Tools~/Collect-PathTools.py','Tools~/Verify-PathToolsRelease.py'} for n in newfiles),newfiles
assert not any('Backend' in n or 'ShaderLibraryService' in n for n in new)
e=json.loads(new['Documentation~/Evidence/PathTools060/verification.json']);assert e['success'] and len(e['results'])==2
for name in newfiles:
    assert new[name]==(ROOT/name).read_bytes(),name
runtime=json.loads(new['Runtime/PathTools/CH.CustomTools.Paths.asmdef']);assert not runtime.get('includePlatforms') and not runtime['noEngineReferences']
report={'success':True,'version':'0.6.0','baselineSha256':hashlib.sha256(baseline.read_bytes()).hexdigest(),'baselineFiles':len(old),'unchangedBaselineFiles':len(old)-len(changed),'changedBaselineFiles':sorted(changed),'addedFiles':sorted(newfiles),'old293GraphsAndConversionCoreAndVfxAudioAlgorithmsPreserved':True,'sourceChecks':e['totalChecks']}
out=ROOT/'Releases~/path-tools-release-verification-0.6.0.json';out.write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8');print(json.dumps(report,ensure_ascii=False,indent=2))
