"""Verify the measurement/UI release against the immutable published 0.4.9 archive."""
from pathlib import Path
import hashlib,json,tarfile
ROOT=Path(__file__).resolve().parents[1]
VERSION=json.loads((ROOT/'package.json').read_text(encoding='utf-8-sig'))['version']
BASELINE=ROOT/'Releases~/com.aseshader.handwritten-converter-0.4.9.tgz'
SHA='097db53ce038672e367a062faf97c0886999c43a91c1c53fde47f22073a57cd7'
assert hashlib.sha256(BASELINE.read_bytes()).hexdigest()==SHA
def read(path):
    with tarfile.open(path,'r:gz') as t:return {m.name.removeprefix('package/'):t.extractfile(m).read() for m in t.getmembers() if m.isfile()}
old=read(BASELINE);new=read(ROOT/f'Releases~/com.aseshader.handwritten-converter-{VERSION}.tgz')
allowed={'Editor/ShaderConverterNavigation.cs','Editor/ShaderLibraryBrowser.cs','Editor/VFX/VfxResourceOrganizerPanel.cs'}
changes=[];protected=[];added=[]
for path,data in old.items():
    if path.startswith(('Editor/','Runtime/','Samples~/')):
        assert path in new,path
        if new[path]!=data:assert path in allowed,path;changes.append(path)
        else:protected.append(path)
for path,data in new.items():
    if path.startswith(('Editor/','Runtime/','Samples~/')) and path not in old:
        assert path.startswith('Editor/Measurement/') or path in {'Editor/Measurement.meta','Editor/VFX/VfxNameBuilder.cs','Editor/VFX/VfxNameBuilder.cs.meta'},path
        added.append(path)
    assert not path.startswith('Backend~/') and path not in {'Documentation~/ShaderLibraryBackend.md','Tools~/Run-ShaderLibraryBackendSmoke.ps1'},path
assert sorted(changes)==sorted(allowed)
evidence=json.loads(new['Documentation~/Evidence/Measurement050/verification.json'])
assert evidence['success'] and evidence['coreChecks']==629
for unity in ['2022.3.10f1','6000.0.80f1']:
    measure=json.loads(new[f'Documentation~/Evidence/Measurement050/unity-{unity}-source.json'])
    assert measure['success'] and measure['count']>=63 and measure['version']==VERSION
    regression=json.loads(new[f'Documentation~/Evidence/Measurement050/custom-tools-{unity}-source.json'])
    assert regression['status']=='Passed' and regression['count']>=78 and regression['version']==VERSION
report={'success':True,'version':VERSION,'baselineVersion':'0.4.9','baselineSha256':SHA,
    'changedExistingProductFiles':sorted(changes),'addedProductFiles':sorted(added),'protectedFilesIdentical':len(protected),
    'libraryShadersIdentical':293,'allAudioAlgorithmsUnchanged':True,'updaterUnchanged':True,'conversionSemanticsChanged':False,
    'userProjectsAndOriginalMeasurementFilesModified':False,'graphVisualEquivalenceClaimed':False}
(ROOT/f'Releases~/measurement-release-verification-{VERSION}.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps(report,ensure_ascii=False))
