"""Check 0.4.5 inline updates against the fixed 0.4.4 package, preserving core/library bytes."""
from pathlib import Path
import hashlib
import json
import tarfile

root = Path(__file__).resolve().parents[1]

def read_archive(path):
    with tarfile.open(path, 'r:gz') as archive:
        return {m.name.removeprefix('package/'): archive.extractfile(m).read()
                for m in archive if m.isfile()}

old_path = root / 'Releases~/com.aseshader.handwritten-converter-0.4.4.tgz'
assert hashlib.sha256(old_path.read_bytes()).hexdigest() == '6121769e137a645f41aa8f61b8205fceda9046eb3b15bd528f4bc6f35f729126'
old = read_archive(old_path)
new_path = root / 'Releases~/com.aseshader.handwritten-converter-0.4.5.tgz'
new = read_archive(new_path)
allowed_editor = {'Editor/ASEShaderConverterWindow.cs', 'Editor/ShaderPackageUpdateUI.cs'}
protected = {p for p in old if p.startswith(('Runtime/', 'Samples~/', 'Editor/')) and p not in allowed_editor}
assert protected == {p for p in new if p.startswith(('Runtime/', 'Samples~/', 'Editor/')) and p not in allowed_editor}
for path in protected:
    assert old[path] == new[path], path
for path in allowed_editor:
    assert new[path] == (root / path).read_bytes(), path
manifest = json.loads(new['package.json'])
assert manifest['author']['name'] == 'CH' and manifest['version'] == '0.4.5'
evidence = root / 'Documentation~/Evidence/InlineUpdates045'
results = {p.stem: json.loads(p.read_text(encoding='utf-8-sig')) for p in evidence.glob('unity-*.json')}
assert len(results) >= 1 and all(r['success'] for r in results.values())
result = {'success': True, 'version': '0.4.5', 'author': 'CH',
          'protectedFilesByteIdentical': len(protected),
          'libraryShaderCount': sum(p.startswith('Samples~/ShaderLibrary/') and p.endswith('.shader') for p in new),
          'tarballSha256': hashlib.sha256(new_path.read_bytes()).hexdigest(),
          'inlineUpdateChecks': {name: len(r['checks']) for name, r in results.items()},
          'conversionSemanticsChanged': False}
(root / 'Releases~/inline-update-verification-0.4.5.json').write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print(json.dumps(result, ensure_ascii=False, indent=2))
