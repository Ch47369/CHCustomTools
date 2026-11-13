"""Protect the full 0.6.0 runtime, library, algorithms and historical evidence."""
from pathlib import Path
import json,tarfile,hashlib
ROOT=Path(__file__).resolve().parents[1]
baseline=ROOT/'Releases~/com.aseshader.handwritten-converter-0.6.0.tgz'
assert hashlib.sha256(baseline.read_bytes()).hexdigest()=='a37737a8436f40aa48658a5ef6518eac5b940cbd1919ebb15c68d1519ee8e9bd'
def files(path):
    with tarfile.open(path,'r:gz') as t:return {m.name.removeprefix('package/'):t.extractfile(m).read() for m in t.getmembers() if m.isfile()}
old=files(baseline);new=files(ROOT/'Releases~/com.aseshader.handwritten-converter-0.6.1.tgz')
allowed={'AGENTS.md','README.md','package.json','Editor/PathTools/PathEditors.cs','Documentation~/PathTools.md','Tools~/Run-ToolMenus.ps1','Tools~/Run-GitHubReleaseUpgrade.ps1'}
changed=sorted(n for n,b in old.items() if new.get(n)!=b);assert set(changed)<=allowed,changed
added=sorted(set(new)-set(old));assert all(n.startswith('Documentation~/Evidence/PathInsertion061/') or n in {'Editor/PathTools/PathPointInsertion.cs','Editor/PathTools/PathPointInsertion.cs.meta','Tests/UnityPathInsertionSmoke.cs','Tests/UnityPathInsertionSmoke.cs.meta','Tools~/Collect-PathInsertion.py','Tools~/Verify-PathInsertionRelease.py'} for n in added),added
assert all(n in new for n in old)
assert all(new[n]==b for n,b in old.items() if n.startswith(('Runtime/','Samples~/','Editor/Measurement/','Editor/VFX/')))
assert not any('Backend' in n for n in new)
e=json.loads(new['Documentation~/Evidence/PathInsertion061/verification.json']);assert e['success'] and e['totalChecks']>=126
report={'success':True,'version':'0.6.1','baselineSha256':hashlib.sha256(baseline.read_bytes()).hexdigest(),'baselineFiles':len(old),'unchangedBaselineFiles':len(old)-len(changed),'changedBaselineFiles':changed,'addedFiles':added,'allRuntimeAnd293GraphsAndAudioVfxMeasurementPreserved':True,'sourceChecks':e['totalChecks']}
out=ROOT/'Releases~/path-insertion-release-verification-0.6.1.json';out.write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8');print(json.dumps(report,ensure_ascii=False,indent=2))
