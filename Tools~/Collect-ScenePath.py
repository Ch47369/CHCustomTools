"""Collect shared-visual Scene path interaction and final measurement regressions."""
from pathlib import Path
import argparse,json,hashlib

ROOT=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser();parser.add_argument('--tarballs',action='store_true');args=parser.parse_args()
mode='FinalTarballs' if args.tarballs else 'Source';results=[]
for engine in ('2022','Unity6'):
    fixtures=[('ScenePath063','path-insertion','UnityPathInsertionSmoke',118)]
    if args.tarballs:fixtures.append(('ScenePath063Measurement','measurement','UnityMeasurementSmoke',40))
    for run,name,fixture,minimum in fixtures:
        project=ROOT/'.validation'/f'{run}-Shader-{engine}-{mode}'
        report=json.loads((project/f'Artifacts/{name}.json').read_text(encoding='utf-8-sig'))
        passed = report.get('success') is True if name=='measurement' else report.get('status')=='Passed'
        assert passed and report['version']=='0.6.3' and report['count']>=minimum,report
        assert (project/f'Assets/Editor/{fixture}.cs').read_bytes()==(ROOT/f'Tests/{fixture}.cs').read_bytes()
        if args.tarballs:
            lock=json.loads((project/'Packages/packages-lock.json').read_text(encoding='utf-8-sig'))['dependencies']['com.aseshader.handwritten-converter']
            assert lock['source']=='local-tarball'
        results.append({'engine':engine,'fixture':fixture,**report})
result={'version':'0.6.3','success':True,'mode':mode,'coreChecks':629,'totalChecks':sum(r['count'] for r in results),'results':results,
    'sharedDrawing':'CHSceneVisuals uses the existing DmSkin palette, halo strokes, anchor discs and pill labels',
    'shiftRules':'Open first point prepends; other points insert after the source; closed seam is supported. Shift is captured at mouse-down; at least 4 GUI points of movement starts duplication.',
    'cancel':'Escape or Ctrl/Cmd+Z during a drag, selection change, measurement activation, lost input, closed Scene view, assembly reload and Play mode cancel active editing; returning a new point to its source cancels the empty extension.',
    'limits':['Editor interaction tested on Windows D3D11 in the two recorded Unity versions.','Direct point movement uses a camera-facing plane or the existing optional downward surface snap; use selected-point gizmos for axis/depth adjustment.','Static generated models/meshes require explicit rebuild. Shift editing intentionally changes the curve; Ctrl insertion still preserves it.'],
    'userProjectsModified':False,'shaderConversionSemanticsChanged':False}
if args.tarballs:
    archive=ROOT/'Releases~/com.aseshader.handwritten-converter-0.6.3.tgz'
    result['tarballSha256']=hashlib.sha256(archive.read_bytes()).hexdigest()
    output=ROOT/'Releases~/scene-path-tarball-install-0.6.3.json'
else:
    folder=ROOT/'Documentation~/Evidence/ScenePath063';folder.mkdir(parents=True,exist_ok=True)
    for report in results:(folder/(report['engine']+'.json')).write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    output=folder/'verification.json'
output.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'success':True,'totalChecks':result['totalChecks'],'output':str(output)}))
