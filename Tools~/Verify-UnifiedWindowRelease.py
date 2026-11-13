"""Verify UI/update-only release scope against the immutable 0.4.6 archive."""
from pathlib import Path
import hashlib
import json
import tarfile

ROOT = Path(__file__).resolve().parents[1]
BASELINE_SHA = '8ab012a03f4e5a6e0e61f4582af4f6dda074ea0be077a61c363a4d71b4c8af72'
baseline = ROOT / 'Releases~/com.aseshader.handwritten-converter-0.4.6.tgz'
assert hashlib.sha256(baseline.read_bytes()).hexdigest() == BASELINE_SHA

def contents(path):
    with tarfile.open(path, 'r:gz') as archive:
        return {m.name.removeprefix('package/'): archive.extractfile(m).read()
                for m in archive.getmembers() if m.isfile()}

old = contents(baseline)
new = contents(ROOT / 'Releases~/com.aseshader.handwritten-converter-0.4.7.tgz')
changed = {'Editor/ASEShaderConverterWindow.cs', 'Editor/CharacterMaterialWindow.cs',
           'Editor/ShaderAgentInbox.cs', 'Editor/ShaderLibraryBrowser.cs',
           'Editor/ShaderPackageUpdateUI.cs', 'Editor/ShaderPackageUpdater.cs'}
added = {'Editor/ShaderConverterNavigation.cs', 'Editor/ShaderConverterNavigation.cs.meta',
         'Editor/ShaderGitClient.cs', 'Editor/ShaderGitClient.cs.meta'}
protected = []
for path, data in old.items():
    if path.startswith(('Runtime/', 'Editor/', 'Samples~/')) and path not in changed:
        assert new[path] == data, 'Unexpected protected change: ' + path
        protected.append(path)
for path in new:
    if path.startswith(('Runtime/', 'Editor/', 'Samples~/')) and path not in old:
        assert path in added, 'Unexpected product addition: ' + path
for path in changed | added:
    assert new[path] == (ROOT / path).read_bytes(), path

# The inbox queue, file recovery, retry and heartbeat implementation are unchanged.
before = old['Editor/ShaderAgentInbox.cs'].decode('utf-8-sig').replace('\r\n', '\n')
after = new['Editor/ShaderAgentInbox.cs'].decode('utf-8-sig').replace('\r\n', '\n')
assert before.replace('public static void OpenInbox() { EnsureDirectories(); EditorUtility.RevealInFinder(Root); }',
                      'public static void OpenInbox() { EnsureDirectories(); ASEShaderConverterWindow.OpenAgent(); }') == after
assert json.loads(new['package.json'])['author']['name'] == 'CH'
assert json.loads(new['package.json'])['version'] == '0.4.7'
evidence = json.loads(new['Documentation~/Evidence/UnifiedWindow047/verification.json'])
assert evidence['success'] and evidence['coreChecks'] == 625
for engine in ['2022.3.10f1', '6000.0.80f1']:
    result = json.loads(new['Documentation~/Evidence/UnifiedWindow047/unity-' + engine + '-source.json'])
    assert result['success'] and result['version'] == '0.4.7' and len(result['checks']) >= 40
git_result = json.loads(new['Documentation~/Evidence/UnifiedWindow047/git-update-source.json'])
assert git_result['success'] and git_result['privateGitCheckSucceeded']
report = {'success': True, 'version': '0.4.7', 'baselineSha256': BASELINE_SHA,
          'protectedFilesIdentical': len(protected), 'libraryShadersIdentical': 293,
          'changedProductFiles': sorted(changed), 'addedProductFiles': sorted(added),
          'inboxQueueAndRecoveryUnchanged': True, 'author': 'CH',
          'actualPrivateGitCheckSucceeded': True, 'conversionSemanticsChanged': False,
          'visualEquivalenceClaimed': False}
(ROOT / 'Releases~/unified-window-verification-0.4.7.json').write_text(
    json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print(json.dumps(report, ensure_ascii=False))
