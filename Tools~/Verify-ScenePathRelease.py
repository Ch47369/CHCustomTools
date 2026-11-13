"""Protect all 0.6.2 runtimes, library graphs and measurement behavior during Scene UI changes."""
from pathlib import Path
import hashlib,json,tarfile,re

ROOT=Path(__file__).resolve().parents[1]
baseline=ROOT/'Releases~/com.aseshader.handwritten-converter-0.6.2.tgz'
assert hashlib.sha256(baseline.read_bytes()).hexdigest()=='078a5018004acf5baae41c04a81a759bcd1bac418ddd82981d31a37f9d9bd0a7'
def files(path):
    with tarfile.open(path,'r:gz') as archive:
        return {m.name.removeprefix('package/'):archive.extractfile(m).read() for m in archive.getmembers() if m.isfile()}
old=files(baseline);archive=ROOT/'Releases~/com.aseshader.handwritten-converter-0.6.3.tgz';new=files(archive)
allowed={'AGENTS.md','README.md','package.json','Documentation~/PathTools.md','Documentation~/CustomTools.md','Editor/Measurement/DmSceneTool.cs','Editor/PathTools/PathEditors.cs','Editor/PathTools/PathPointInsertion.cs','Tests/UnityPathInsertionSmoke.cs'}
changed=sorted(n for n,b in old.items() if new.get(n)!=b);assert set(changed)==allowed,changed
assert set(old)<=set(new)
added=sorted(set(new)-set(old))
assert all(n.startswith('Documentation~/Evidence/ScenePath063/') or n in {'Editor/CHSceneVisuals.cs','Editor/CHSceneVisuals.cs.meta','Editor/PathTools/PathPointDrag.cs','Editor/PathTools/PathPointDrag.cs.meta','Tools~/Collect-ScenePath.py','Tools~/Verify-ScenePathRelease.py'} for n in added),added
assert all(new[n]==b for n,b in old.items() if n.startswith(('Runtime/','Samples~/','Editor/VFX/')))
assert all(new[n]==b for n,b in old.items() if n.startswith('Editor/') and n not in allowed)
assert not any('Backend' in n for n in new)
for name,data in new.items():assert data==(ROOT/name).read_bytes(),name
def measurement_behavior(data):
    text=data.decode('utf-8-sig')
    for signature in ['static void DrawDimensionLine(', 'static void DrawAnchor(', 'static Rect DrawPillGui(', 'static Rect DrawPillAt(']:
        if signature not in text:continue
        start=text.index(signature);brace=text.index('{',start);end=brace+1;depth=1
        while depth:
            if text[end]=='{':depth+=1
            elif text[end]=='}':depth-=1
            end+=1
        text=text[:start]+text[end:]
    text=re.sub(r'/\*.*?\*/|//[^\r\n]*','',text,flags=re.S)
    return re.sub(r'\s+','',text)
assert measurement_behavior(old['Editor/Measurement/DmSceneTool.cs'])==measurement_behavior(new['Editor/Measurement/DmSceneTool.cs'])
evidence=json.loads(new['Documentation~/Evidence/ScenePath063/verification.json']);assert evidence['success'] and evidence['totalChecks']>=236
result={'version':'0.6.3','success':True,'baselineVersion':'0.6.2','baselineSha256':hashlib.sha256(baseline.read_bytes()).hexdigest(),'tarballSha256':hashlib.sha256(archive.read_bytes()).hexdigest(),'packagedFilesMatchSource':len(new),'changedBaselineFiles':changed,'addedFiles':added,'allRuntimeAnd293GraphsAndAudioVfxPreserved':True,'measurementOnlySharedDrawingMethodsChanged':True,'githubUpdaterPreserved':True,'shaderSemanticsChanged':False,'sourceSceneChecks':evidence['totalChecks']}
output=ROOT/'Releases~/scene-path-release-verification-0.6.3.json';output.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8');print(json.dumps(result,ensure_ascii=False))
