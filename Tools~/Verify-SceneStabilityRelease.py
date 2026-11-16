"""Verify an explicit 0.6.5 package overlay while preserving all protected 0.6.4 bytes."""
from pathlib import Path
import tarfile,hashlib,json,argparse
p=argparse.ArgumentParser();p.add_argument('--package-root',type=Path);args=p.parse_args()
ROOT=Path(__file__).resolve().parents[1];SOURCE=args.package_root or ROOT

def files(path):
 with tarfile.open(path,'r:gz') as t:return {m.name.removeprefix('package/'):t.extractfile(m).read() for m in t.getmembers() if m.isfile()}
baseline=ROOT/'Releases~/com.aseshader.handwritten-converter-0.6.4.tgz';assert hashlib.sha256(baseline.read_bytes()).hexdigest()=='42a8372a7f283c28e5508eee2433f726cfb30bb075e4ea426141818d00d02a97'
archive=ROOT/'Releases~/com.aseshader.handwritten-converter-0.6.5.tgz';old=files(baseline);new=files(archive)
allowed={'AGENTS.md','README.md','package.json','Documentation~/PathTools.md','Documentation~/CustomTools.md','Documentation~/SceneMeasurement.md','Editor/CHSceneVisuals.cs','Editor/Measurement/DmSceneTool.cs','Editor/PathTools/PathAuthoringPreview.cs','Editor/VFX/RhythmCurvePanel.cs','Tests/UnityPathPreviewSmoke.cs','Tools~/Run-ToolMenus.ps1','Tests/UnityPathVisibilitySmoke.cs','Tests/UnitySceneToolsSmoke.cs','Tests/UnityPathInsertionSmoke.cs'}
changed=sorted(n for n,d in old.items() if new.get(n)!=d);assert set(changed)==allowed,changed;assert set(old)<=set(new)
added=sorted(set(new)-set(old));newcode={'Tests/UnitySceneStabilitySmoke.cs','Tests/UnitySceneStabilitySmoke.cs.meta','Tools~/Collect-SceneStability.py','Tools~/Verify-SceneStabilityRelease.py','Editor/Resources/CHSceneStroke.shader','Editor/Resources/CHSceneStroke.shader.meta','Tests/CHValidationInput.cs','Tests/CHValidationInput.cs.meta'}
assert all(n.startswith('Documentation~/Evidence/SceneStability065/') or n in newcode for n in added),added
assert not any('Backend' in n or 'SidebarLine' in n for n in new)
for name,data in new.items():assert data==(SOURCE/name).read_bytes(),name
for name,data in old.items():
 if name.startswith(('Runtime/','Samples~/')) or (name.startswith('Editor/') and name not in allowed):assert new[name]==data,name
# Audio implementation is byte-identical after removing exactly the two requested UI lines.
audio='Editor/VFX/RhythmCurvePanel.cs'
assert new[audio]==old[audio].replace('                GUILayout.Label(CHToolLanguage.Text("把声音的强弱、频段与起音，转成可编辑的特效曲线。"), hintStyle);\r\n                GUILayout.Space(8);\r\n'.encode(),b'')
evidence=json.loads(new['Documentation~/Evidence/SceneStability065/verification.json']);assert evidence['success'] and evidence['totalChecks']>=140
result={'version':'0.6.5','success':True,'baselineSha256':hashlib.sha256(baseline.read_bytes()).hexdigest(),'tarballSha256':hashlib.sha256(archive.read_bytes()).hexdigest(),'packagedFilesMatchSource':len(new),'changedBaselineFiles':changed,'addedFiles':added,'runtimeAnd293GraphsPreserved':True,'audioVfxAlgorithmsAndUpdaterPreserved':True,'sourceChecks':evidence['totalChecks']}
output=ROOT/'Releases~/scene-stability-release-verification-0.6.5.json';output.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8');print(json.dumps(result,ensure_ascii=False))
