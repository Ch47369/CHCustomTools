"""Collect successful isolated Unity validation evidence without copying source shaders."""
import hashlib
import json
import shutil
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / 'Documentation~/Evidence/FullValidation028'


def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def write(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')


def main():
    inventory = read(ROOT / '.build~/ValidationRuns/inventory.json')
    assert len(inventory['inputs']) == 457
    for item in inventory['inputs']:
        assert digest(Path(item['path'])) == item['sha256'], item['id']
    write(DEST / 'inventory.json', {'inputs': [{k: x[k] for k in ('id', 'group', 'sha256')} for x in inventory['inputs']]})
    sources = {
        'BuiltIn': ('Unity2022', ['environment.json', 'template.json', 'conversion.json', 'native-math.json', 'custom-loop.json', 'texture-pixel-comparison.txt', 'math-pixel-comparison.txt', 'loop-pixel-comparison.txt']),
        'URP': ('UnityURP', ['conversion.json', 'automatic.json', 'environment.json', 'template.json', 'urp-texture-pixel-comparison.txt']),
        'HDRP': ('UnityHDRP', ['conversion.json', 'environment.json', 'template.json']),
        'Reviewed': ('DeepZoom2022', ['normal-environment.json', 'normal-Normal360-conversion.json', 'normal-NormalImagePanZoom-conversion.json', 'normal-pixels.txt', 'normal-smoke-result.txt', 'array-environment.json', 'array-conversion.json', 'array-pixels.txt', 'array-smoke-result.txt', 'ui-environment.json', 'ui-template.json', 'ui-conversion.json', 'ui-no-presentation.json', 'ui-pixels.txt', 'presentation-smoke-result.txt']),
        'Water': ('DeepZoom2022', ['water-environment.json', 'water-template.json', 'water-conversion.json', 'water-assets.json', 'water-variants.json', 'water-validation-result.txt']),
    }
    artifacts = []
    for group, (project, names) in sources.items():
        target = DEST / 'Smoke' / group
        target.mkdir(parents=True, exist_ok=True)
        for name in names:
            source = ROOT / '.validation' / project / name
            assert source.is_file(), str(source)
            shutil.copyfile(source, target / name)
            artifacts.append({'file': str((target / name).relative_to(DEST)), 'sha256': digest(source), 'sourceModifiedUtc': datetime.fromtimestamp(source.stat().st_mtime, timezone.utc).isoformat()})
    logs = {
        'Unity2022.log': 'ASE_CONVERTER_SMOKE_PASS',
        'UnityURP-current.log': 'ASE_CONVERTER_SRP_SMOKE_PASS: URP',
        'UnityHDRP-current.log': 'ASE_CONVERTER_SRP_SMOKE_PASS: HDRP',
        'Normal-retry.log': 'ASE_NORMAL_SMOKE_PASS: 258; cases=49',
        'Array-current.log': 'ASE_ARRAY_SMOKE_PASS: 34',
        'Presentation-current.log': 'ASE_PRESENTATION_SMOKE_PASS: 139',
        'Water-final.log': 'ASE_WATER_VALIDATION_PASS: 22',
        'BuiltIn-full-complete.log': 'ASE_FULL_VALIDATION_COMPLETE: BuiltIn rows=457',
        'URP-full-complete.log': 'ASE_FULL_VALIDATION_COMPLETE: URP rows=457',
        'HDRP-full-complete.log': 'ASE_FULL_VALIDATION_COMPLETE: HDRP rows=457',
    }
    markers = []
    for name, marker in logs.items():
        path = ROOT / '.build~/ValidationRuns' / name
        contents = path.read_text(encoding='utf-8-sig', errors='replace')
        assert marker in contents, name
        markers.append({'log': str(path.relative_to(ROOT)), 'sha256': digest(path), 'marker': marker})
    summary = read(DEST / 'summary.json')
    for target in summary['targets']:
        assert target['inputs'] == 457 and target['sourceHashMismatches'] == 0 and target['errors'] == 0
    for pipeline in ('BuiltIn', 'URP', 'HDRP'):
        provenance = read(DEST / pipeline / 'provenance.json')
        if isinstance(provenance, dict):
            provenance = [provenance]
        assert len(provenance) == 1 and provenance[0]['harnessSha256'] == digest(ROOT / 'Tests/UnityFullValidation.cs')
    water = read(DEST / 'Smoke/Water/water-variants.json')
    assert water['success'] and len(water['variants']) == 22 and all(x['compiled'] for x in water['variants'])
    write(DEST / 'verification.json', {
        'checkedUtc': datetime.now(timezone.utc).isoformat(),
        'sourceHashesMatched': 457, 'targetAssessments': 1371,
        'unity': '2022.3.10f1', 'ase': '1.9.9.13', 'srp': '14.0.8', 'graphicsApi': 'Direct3D11',
        'logMarkers': markers, 'smokeArtifacts': artifacts,
        'harnessSha256': digest(ROOT / 'Tests/UnityFullValidation.cs'),
        'waterHarnessSha256': digest(ROOT / 'Tests/UnityWaterValidation.cs'),
        'limits': ['Blocked inputs were not generated.', 'Existing ASE graphs are migration, not handwritten conversion.', 'Fixtures do not prove original-scene, all-keyword, all-platform equivalence.', 'No GPU performance benchmark or new release tarball.']
    })
    print('PASS: 457 original hashes; 1371 target assessments; 10 Unity completion markers; 22 water variants; evidence provenance checked.')


if __name__ == '__main__':
    main()
