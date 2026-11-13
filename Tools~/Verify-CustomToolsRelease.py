"""Check unified collection delivery against immutable Shader 0.4.7 and imported audio provenance."""
from pathlib import Path
import hashlib
import json
import tarfile

ROOT = Path(__file__).resolve().parents[1]
VERSION = json.loads((ROOT / 'package.json').read_text(encoding='utf-8-sig'))['version']
BASELINE_SHA = '8f95611f89a7c75398a05f46d0ff08b8f86f027885abbecac5a6d795e01cadc9'
baseline = ROOT / 'Releases~/com.aseshader.handwritten-converter-0.4.7.tgz'
assert hashlib.sha256(baseline.read_bytes()).hexdigest() == BASELINE_SHA

def contents(path):
    with tarfile.open(path, 'r:gz') as archive:
        return {m.name.removeprefix('package/'): archive.extractfile(m).read()
                for m in archive.getmembers() if m.isfile()}

old = contents(baseline)
new = contents(ROOT / ('Releases~/com.aseshader.handwritten-converter-' + VERSION + '.tgz'))
changed = {'Editor/ASEShaderConverterWindow.cs', 'Editor/ShaderConverterNavigation.cs',
           'Editor/ShaderPackageUpdateUI.cs', 'Editor/ShaderPackageUpdater.cs', 'Editor/ShaderGitClient.cs',
           'Runtime/ShaderPackageUpdatePolicy.cs'}
measurementRelease = tuple(map(int, VERSION.split('.'))) >= (0, 5, 0)
pathRelease = tuple(map(int, VERSION.split('.'))) >= (0, 6, 0)
if pathRelease:
    changed.add('Editor/ASEShaderConverter.Editor.asmdef')
if measurementRelease:
    changed.update({'Editor/ShaderLibraryBrowser.cs', 'Editor/VFX/VfxResourceOrganizerPanel.cs'})
protected = []
added = []
for path, data in old.items():
    if path.startswith(('Runtime/', 'Editor/', 'Samples~/')) and path not in changed:
        assert new[path] == data, 'Unexpected protected change: ' + path
        protected.append(path)
for path, data in new.items():
    if path.startswith(('Runtime/', 'Editor/', 'Samples~/')):
        if path not in old:
            assert path.startswith('Editor/VFX/') or (measurementRelease and (path.startswith('Editor/Measurement/') or path == 'Editor/Measurement.meta')) or (pathRelease and (path.startswith(('Runtime/PathTools/', 'Editor/PathTools/')) or path in {'Runtime/PathTools.meta', 'Editor/PathTools.meta'})) or path in {'Editor/VFX.meta', 'Editor/ShaderGitHubClient.cs', 'Editor/ShaderGitHubClient.cs.meta'}, path
            added.append(path)
        assert data == (ROOT / path).read_bytes(), path
meta = json.loads(new['package.json'])
assert meta['displayName'] == 'CH自定义工具集' and meta['author']['name'] == 'CH'
assert meta['version'] == VERSION and meta['unity'] == '2022.3'
assert meta['name'] == 'com.aseshader.handwritten-converter'
assert set(meta['dependencies']) == {'com.unity.modules.' + m for m in ['animation', 'audio', 'imgui', 'jsonserialize', 'particlesystem', 'unitywebrequest'] + (['physics'] if measurementRelease else [])}
provenance = json.loads(new['Documentation~/Evidence/CustomTools048/audio-provenance.json'])
assert provenance['commit'] == '1408814cdfb53dc58c507c0d992c0bb42d44f538'
algorithms = ['RhythmAnalyzer.cs', 'RhythmAudioImport.cs', 'RhythmAudioPreview.cs', 'RhythmCurveClipboard.cs',
              'RhythmCurveExport.cs', 'RhythmCurveProfile.cs', 'RhythmEffectTiming.cs', 'VfxResourceOrganizer.cs', 'CHToolEnglish.cs']
for name in algorithms:
    imported = new['Editor/VFX/' + name].decode('utf-8-sig').replace('\r\n', '\n').replace('namespace CH.CustomTools.VFX', 'namespace AudioRhythmCurves')
    source = next(x for x in provenance['files'] if x['source'] == name)
    assert hashlib.sha256(imported.encode()).hexdigest() == source['normalizedSourceSha256'], name
evidence = json.loads(new['Documentation~/Evidence/CustomTools048/verification.json'])
assert evidence['success'] and evidence['coreChecks'] == 629
for engine in ['2022.3.10f1', '6000.0.80f1']:
    for mode, minimum in [('source', 62), ('coexistence', 63)]:
        result = json.loads(new['Documentation~/Evidence/CustomTools048/unity-' + engine + '-' + mode + '.json'])
        assert result['status'] == 'Passed' and result['version'] == '0.4.8' and result['count'] >= minimum
report = {'success': True, 'version': VERSION, 'baselineSha256': BASELINE_SHA,
          'protectedFilesIdentical': len(protected), 'libraryShadersIdentical': 293,
          'changedProductFiles': sorted(changed), 'addedProductFiles': sorted(added),
          'audioAlgorithmsAndModelsPreservedApartFromNamespace': algorithms,
          'inboxQueueAndRecoveryUnchanged': True, 'conversionSemanticsChanged': False,
          'visualEquivalenceClaimed': False, 'author': 'CH'}
if VERSION == '0.4.9':
    previous = ROOT / 'Releases~/com.aseshader.handwritten-converter-0.4.8.tgz'
    assert hashlib.sha256(previous.read_bytes()).hexdigest() == '89de508e9c33d47998fedb50845fa9e3664a78b81b13d20969c63cdd544828f6'
    previousFiles = contents(previous)
    changedFrom048 = sorted(path for path, data in previousFiles.items()
                            if path.startswith(('Runtime/', 'Editor/', 'Samples~/')) and new[path] != data)
    assert changedFrom048 == ['Editor/ShaderGitHubClient.cs'], changedFrom048
    report['changedProductFilesFrom048'] = changedFrom048
    report['allIntegratedVfxFilesIdenticalTo048'] = True
(ROOT / ('Releases~/custom-tools-verification-' + VERSION + '.json')).write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print(json.dumps(report, ensure_ascii=False))
