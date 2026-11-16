"""Verify the 0.6.6 overlay and preserve every unrelated 0.6.5 package byte."""
from pathlib import Path
import argparse,tarfile,hashlib,json
p=argparse.ArgumentParser();p.add_argument('--package-root',type=Path);a=p.parse_args()
r=Path(__file__).resolve().parents[1];source=a.package_root or r
def files(path):
 with tarfile.open(path,'r:gz') as t:return {m.name.removeprefix('package/'):t.extractfile(m).read() for m in t.getmembers() if m.isfile()}
baseline=r/'Releases~/com.aseshader.handwritten-converter-0.6.5.tgz'
assert hashlib.sha256(baseline.read_bytes()).hexdigest()=='ed4f4acfe0732209e360e834838bf41934f3c22ee612ce38305182b4d47e33ec'
archive=r/'Releases~/com.aseshader.handwritten-converter-0.6.6.tgz';old=files(baseline);new=files(archive)
allowed={'Editor/PathTools/'+n+'.cs' for n in ['PathSceneTool','PathPointInsertion','PathPointDrag','PathToolsPanel','PathEditors','PathKnotEditing']}
allowed.update(['README.md','AGENTS.md','package.json','Documentation~/PathTools.md','Documentation~/CustomTools.md','Tools~/Run-ToolMenus.ps1'])
changed=sorted(n for n,d in old.items() if new.get(n)!=d);assert set(changed)==allowed,changed;assert set(old)<=set(new)
added=sorted(set(new)-set(old));assert all(n.startswith('Documentation~/Evidence/PathEditing066/') or n in ['Tests/UnityPathEditingSmoke.cs','Tests/UnityPathEditingSmoke.cs.meta','Tools~/Verify-PathEditingRelease.py'] for n in added),added
for n,d in new.items():assert (source/n).read_bytes()==d,n
assert not any('Backend' in n or 'SidebarLine' in n for n in new)
for n,d in old.items():
 if n.startswith(('Runtime/','Samples~/','Editor/')) and n not in allowed:assert new[n]==d,n
result={'version':'0.6.6','success':True,'baselineSha256':hashlib.sha256(baseline.read_bytes()).hexdigest(),'tarballSha256':hashlib.sha256(archive.read_bytes()).hexdigest(),'packagedFilesMatchSource':len(new),'changedBaselineFiles':changed,'addedFiles':added,'allRuntimeAnd293GraphsPreserved':True,'measurementAudioVfxRenderingAndUpdaterPreserved':True}
(r/'Releases~/path-editing-release-verification-0.6.6.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8');print(json.dumps(result,ensure_ascii=False))
