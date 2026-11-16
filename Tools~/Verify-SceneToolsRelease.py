"""Protect all 0.6.3 runtime/library/updater bytes during explicit Scene editor changes."""
from pathlib import Path
import tarfile,hashlib,json,argparse
p=argparse.ArgumentParser();p.add_argument("--package-root",type=Path);args=p.parse_args()
ROOT=Path(__file__).resolve().parents[1]
def files(path):
    with tarfile.open(path,'r:gz') as t:return {m.name.removeprefix('package/'):t.extractfile(m).read() for m in t.getmembers() if m.isfile()}
baseline=ROOT/'Releases~/com.aseshader.handwritten-converter-0.6.3.tgz';assert hashlib.sha256(baseline.read_bytes()).hexdigest()=='13a0eafeafd588556a05af318d5cdf9acf5ae2036ba0bb944513d2b0d8f049d0'
archive=ROOT/'Releases~/com.aseshader.handwritten-converter-0.6.4.tgz';old=files(baseline);new=files(archive)
SOURCE=args.package_root or ROOT
allowed={'AGENTS.md','README.md','package.json','Documentation~/PathTools.md','Documentation~/CustomTools.md','Documentation~/SceneMeasurement.md','Editor/Measurement/DmSceneTool.cs','Editor/Measurement/MeasurementPanel.cs','Editor/PathTools/PathAuthoring.cs','Editor/PathTools/PathEditors.cs','Editor/PathTools/PathPointDrag.cs','Editor/PathTools/PathPointInsertion.cs','Editor/PathTools/PathToolsPanel.cs','Editor/ShaderConverterNavigation.cs','Tests/UnityPathInsertionSmoke.cs','Tests/UnityCustomToolsSmoke.cs','Tools~/Run-ToolMenus.ps1'}
changed=sorted(name for name,data in old.items() if new.get(name)!=data);assert set(changed)==allowed,changed
assert set(old)<=set(new)
added=sorted(set(new)-set(old))
newcode={'Editor/CHSceneToolSettings.cs','Editor/CHSceneToolSettings.cs.meta','Editor/PathTools/PathSceneTool.cs','Editor/PathTools/PathSceneTool.cs.meta','Editor/PathTools/PathKnotEditing.cs','Editor/PathTools/PathKnotEditing.cs.meta','Editor/PathTools/PathAuthoringPreview.cs','Editor/PathTools/PathAuthoringPreview.cs.meta','Tests/UnityPathPreviewSmoke.cs','Tests/UnityPathPreviewSmoke.cs.meta','Tests/UnitySceneToolsSmoke.cs','Tests/UnitySceneToolsSmoke.cs.meta','Tests/UnityPathVisibilitySmoke.cs','Tests/UnityPathVisibilitySmoke.cs.meta','Tools~/Collect-SceneTools.py','Tools~/Verify-SceneToolsRelease.py'}
assert all(n.startswith('Documentation~/Evidence/SceneTools064/') or n in newcode for n in added),added
assert not any('Backend' in n for n in new)
for name,data in new.items():assert data==(SOURCE/name).read_bytes(),name
for name,data in old.items():
    if name.startswith(('Runtime/','Samples~/','Editor/VFX/')) or (name.startswith('Editor/') and name not in allowed):assert new[name]==data,name
assert new['Editor/Measurement/DmSceneTool.cs'].replace(b'                if (value) CH.CustomTools.Paths.Editor.PathSceneTool.Active = false;\r\n',b'')==old['Editor/Measurement/DmSceneTool.cs']
assert new['Editor/PathTools/PathAuthoring.cs'].replace(b'Stop(); PathAuthoringPreview.Stop(); if (target == null',b'Stop(); if (target == null')==old['Editor/PathTools/PathAuthoring.cs']
assert new['Editor/Measurement/MeasurementPanel.cs']==old['Editor/Measurement/MeasurementPanel.cs'].replace(b'public void Deactivate() { if(initialized){DmSceneTool.Active=false;DmStore.Flush();} }',b'public void Deactivate() { DmSceneTool.Active=false; if(initialized)DmStore.Flush(); }')
evidence=json.loads(new['Documentation~/Evidence/SceneTools064/verification.json']);assert evidence['success'] and evidence['totalChecks']>=240
result={'version':'0.6.4','success':True,'baselineSha256':hashlib.sha256(baseline.read_bytes()).hexdigest(),'tarballSha256':hashlib.sha256(archive.read_bytes()).hexdigest(),'packagedFilesMatchSource':len(new),'changedBaselineFiles':changed,'addedFiles':added,'runtimeAnd293GraphsPreserved':True,'audioVfxAndUpdaterPreserved':True,'measurementChanges':'Competing path mode is disabled; closing an uninitialised panel also disables measurement','sourceChecks':evidence['totalChecks']}
output=ROOT/'Releases~/scene-tools-release-verification-0.6.4.json';output.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8');print(json.dumps(result,ensure_ascii=False))
