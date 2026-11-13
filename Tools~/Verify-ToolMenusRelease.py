"""Check 0.4.3 menu delivery against the fixed 0.4.2 package, preserving core/library bytes."""
from pathlib import Path
import hashlib
import json
import tarfile

root = Path(__file__).resolve().parents[1]

def read_archive(path):
    with tarfile.open(path, 'r:gz') as archive:
        return {m.name.removeprefix('package/'): archive.extractfile(m).read()
                for m in archive if m.isfile()}

old_path = root / 'Releases~/com.aseshader.handwritten-converter-0.4.2.tgz'
assert hashlib.sha256(old_path.read_bytes()).hexdigest() == '6074b84bb091df31ca9991f96b70dafbf009442b27cc82f2121ea3bab6accde0'
old = read_archive(old_path)
new_path = root / 'Releases~/com.aseshader.handwritten-converter-0.4.3.tgz'
new = read_archive(new_path)
allowed_editor = {'Editor/ASEShaderConverterWindow.cs', 'Editor/CHToolLanguage.cs',
                  'Editor/ShaderAgentInbox.cs', 'Editor/ShaderLibraryBrowser.cs',
                  'Editor/ShaderPackageUpdateUI.cs'}
protected = {p for p in old if p.startswith(('Runtime/', 'Samples~/', 'Editor/')) and p not in allowed_editor}
assert protected == {p for p in new if p.startswith(('Runtime/', 'Samples~/', 'Editor/')) and p not in allowed_editor}
for path in protected:
    assert old[path] == new[path], path
for path in allowed_editor:
    assert new[path] == (root / path).read_bytes(), path
manifest = json.loads(new['package.json'])
assert manifest['author']['name'] == 'CH' and manifest['version'] == '0.4.3'
evidence = root / 'Documentation~/Evidence/ToolMenus043'
results = {p.stem: json.loads(p.read_text(encoding='utf-8-sig')) for p in evidence.glob('unity-*.json')}
assert len(results) >= 3 and all(r['success'] for r in results.values())
result = {'success': True, 'version': '0.4.3', 'author': 'CH',
          'protectedFilesByteIdentical': len(protected),
          'libraryShaderCount': sum(p.startswith('Samples~/ShaderLibrary/') and p.endswith('.shader') for p in new),
          'tarballSha256': hashlib.sha256(new_path.read_bytes()).hexdigest(),
          'installedMenuChecks': {name: len(r['checks']) for name, r in results.items()},
          'conversionSemanticsChanged': False}
(root / 'Releases~/tool-menus-verification-0.4.3.json').write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print(json.dumps(result, ensure_ascii=False, indent=2))
