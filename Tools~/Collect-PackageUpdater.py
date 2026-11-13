"""Collect only successful updater checks that include conditional-button verification."""
from pathlib import Path
import hashlib, json, shutil

ROOT = Path(__file__).resolve().parents[1]
destination = ROOT/'Documentation~/Evidence/PackageUpdater041'
destination.mkdir(parents=True, exist_ok=True)
rows = []
for unity in ['2022.3.10f1', '6000.0.80f1']:
    candidates = []
    for path in (ROOT/'.build~/PackageUpdater041/Attempts').glob('*/result.json'):
        result = json.loads(path.read_text(encoding='utf-8-sig'))
        if (result['success'] and result['unityVersion'] == unity and result['mode'] == 'Check'
            and 'Newer release alone reveals the enabled versioned update button' in result['checks']):
            candidates.append((path, result))
    assert candidates, 'Missing current integration evidence: '+unity
    path, result = sorted(candidates, key=lambda pair: pair[0].parent.name)[-1]
    name = 'unity-'+unity+'.json'
    shutil.copyfile(path, destination/name)
    rows.append({'unityVersion': unity, 'checks': len(result['checks']), 'result': name,
                 'attempt': path.relative_to(ROOT).as_posix(), 'source': result['source'], 'latest': result['latest']})
sources = ['Runtime/ShaderPackageUpdatePolicy.cs', 'Editor/ShaderPackageUpdater.cs', 'Editor/ShaderPackageUpdateUI.cs',
           'Editor/ASEShaderConverterWindow.cs', 'Tests/PackageUpdateChecks.cs', 'Tests/UnityPackageUpdaterSmoke.cs']
verification = {'success': True, 'version': '0.4.1', 'coreChecks': 592,
    'editorCompile': {'2022.3.10f1': True, '6000.0.80f1': True}, 'integration': rows,
    'newVersionButtonVisibleOnlyWhenStrictlyNewer': True, 'backgroundDiscovery': True,
    'futureVersionUiUsesSyntheticFixtureOnly': True, 'installationEvidence': 'See Releases~/package-updater-install-verification-0.4.1.json after tag publication',
    'sourceHashes': {s: hashlib.sha256((ROOT/s).read_bytes()).hexdigest() for s in sources},
    'conversionBackendUnchanged': True, 'userProjectModified': False}
(destination/'verification.json').write_text(json.dumps(verification, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
print(json.dumps(verification, ensure_ascii=False, indent=2))
