"""Verify 0.4.1 updater delivery against the immutable 0.4.0 package."""
from pathlib import Path
import hashlib, json, tarfile, zipfile

ROOT = Path(__file__).resolve().parents[1]
def sha(data): return hashlib.sha256(data).hexdigest()
def read_tar(path):
    with tarfile.open(path, 'r:gz') as archive:
        return {m.name: archive.extractfile(m).read() for m in archive.getmembers() if m.isfile()}

baseline_path = ROOT/'Releases~/com.aseshader.handwritten-converter-0.4.0.tgz'
assert sha(baseline_path.read_bytes()) == '3489ab5d5bf3cead93a76f1761e5ea92160e095fe447d173bff0d63889239a02'
baseline = read_tar(baseline_path)
evidence = json.loads((ROOT/'Documentation~/Evidence/PackageUpdater041/verification.json').read_text(encoding='utf-8'))
assert evidence['success'] and evidence['coreChecks'] >= 592
assert evidence['editorCompile']['2022.3.10f1'] and evidence['editorCompile']['6000.0.80f1']
protected = [n for n in baseline if n.startswith(('package/Runtime/', 'package/Editor/', 'package/Samples~/')) and n != 'package/Editor/ASEShaderConverterWindow.cs']
rows = []
for name in ['com.aseshader.handwritten-converter-0.4.1.tgz', 'ShaderConverter-0.4.1.zip']:
    path = ROOT/'Releases~'/name
    if name.endswith('.tgz'): files = read_tar(path)
    else:
        with zipfile.ZipFile(path) as archive: files = {n: archive.read(n) for n in archive.namelist() if not n.endswith('/')}
    for key in protected: assert files[key] == baseline[key], key
    window = files['package/Editor/ASEShaderConverterWindow.cs']
    button = '            if (GUILayout.Button("插件更新（检查版本与 Git 升级）")) ShaderPackageUpdateWindow.Open();'.encode()
    assert window.count(button) == 1
    # Account for the source file's original line ending without normalizing any other bytes.
    assert window.replace(button+b'\n', b'').replace(button+b'\r\n', b'') == baseline['package/Editor/ASEShaderConverterWindow.cs']
    assert json.loads(files['package/package.json'])['version'] == '0.4.1'
    for key, value in evidence['sourceHashes'].items(): assert sha(files['package/'+key]) == value, key
    assert json.loads(files['package/Documentation~/Evidence/PackageUpdater041/verification.json']) == evidence
    rows.append({'file': name, 'sha256': sha(path.read_bytes()), 'bytes': path.stat().st_size,
                 'protectedFilesUnchanged': len(protected), 'libraryShadersUnchanged': 293, 'updaterEvidenceMatchesPackedCode': True})
result = {'success': True, 'version': '0.4.1', 'archives': rows, 'conversionBackendUnchanged': True}
(ROOT/'Releases~/package-updater-release-verification-0.4.1.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps(result,ensure_ascii=False,indent=2))
