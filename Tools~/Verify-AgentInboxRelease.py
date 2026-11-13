"""Check 0.3.7 archives and preserve the fixed 0.3.6 shader-library baseline."""
from pathlib import Path
import hashlib
import json
import tarfile
import zipfile

ROOT = Path(__file__).resolve().parents[1]
BASELINE_SHA = 'a8b329a09aa185cb34c844a051c0f6028e651689facd3b74ef9e16809f1f4ec2'


def sha(data):
    return hashlib.sha256(data).hexdigest()


def tar_files(path):
    with tarfile.open(path, 'r:gz') as archive:
        return {m.name: archive.extractfile(m).read() for m in archive.getmembers() if m.isfile()}


def main():
    baseline_path = ROOT / 'Releases~/com.aseshader.handwritten-converter-0.3.6.tgz'
    assert sha(baseline_path.read_bytes()) == BASELINE_SHA, 'Historical 0.3.6 tarball changed'
    baseline = tar_files(baseline_path)
    verification = json.loads((ROOT / 'Documentation~/Evidence/AgentInbox037/verification.json').read_text(encoding='utf-8'))
    assert verification['success'] and verification['coreChecks'] == 540
    assert verification['editorCompile'] == {'errors': 0, 'warnings': 0}
    assert verification['recoveryChecks'] >= 23
    catalog_key = 'package/Editor/Resources/ASEShaderLibraryCatalog.json'
    catalog = json.loads(baseline[catalog_key])
    rows = []
    for name in ('com.aseshader.handwritten-converter-0.3.7.tgz', 'ASEShaderConverter-0.3.7.zip'):
        path = ROOT / 'Releases~' / name
        if name.endswith('.tgz'):
            files = tar_files(path)
        else:
            with zipfile.ZipFile(path) as archive:
                files = {n: archive.read(n) for n in archive.namelist() if not n.endswith('/')}
        assert json.loads(files['package/package.json'])['version'] == '0.3.7'
        assert files[catalog_key] == baseline[catalog_key], 'Catalog/contracts/research changed'
        protected = [p for p in baseline if p.startswith(('package/Runtime/', 'package/Editor/', 'package/Samples~/'))
                     and p != 'package/Editor/ShaderAgentInbox.cs']
        for p in protected:
            assert files[p] == baseline[p], 'Unexpected material/library change: ' + p
        for entry in catalog['entries']:
            assert sha(files['package/' + entry['path']]) == entry['sha256'], entry['id']
        for p in ('Editor/ShaderAgentInbox.cs', 'Tests/UnityAgentInboxRecoverySmoke.cs'):
            assert files['package/' + p] == (ROOT / p).read_bytes()
        assert json.loads(files['package/Documentation~/Evidence/AgentInbox037/verification.json']) == verification
        rows.append({'file': name, 'bytes': path.stat().st_size, 'sha256': sha(path.read_bytes()),
                     'libraryShadersUnchanged': len(catalog['entries']), 'protectedFilesUnchanged': len(protected),
                     'catalogContractsResearchUnchanged': True})
    result = {'success': True, 'version': '0.3.7', 'baselineTarballSha256': BASELINE_SHA, 'archives': rows,
              'newShaderGraphs': 0, 'newVisualEquivalenceClaim': False}
    (ROOT / 'Releases~/agent-inbox-release-verification-0.3.7.json').write_text(
        json.dumps(result, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
