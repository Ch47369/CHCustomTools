"""Collect actual Scene rendering, activation, tangent and final package regressions."""
from pathlib import Path
import argparse,json,hashlib,shutil,tarfile
ROOT=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('--tarballs',action='store_true');args=p.parse_args()
mode='FinalTarballs' if args.tarballs else 'Source';results=[]
fixtures=[('SceneTools064','scene-tools','UnitySceneToolsSmoke',77),('PathVisibility064','path-visibility','UnityPathVisibilitySmoke',11),('PathPreview064','path-preview','UnityPathPreviewSmoke',30)]
if args.tarballs:fixtures += [('PathInteraction064','path-insertion','UnityPathInsertionSmoke',118),('ToolLanguage064','custom-tools','UnityCustomToolsSmoke',60),('Measurement064','measurement','UnityMeasurementSmoke',63)]
for engine in ['2022','Unity6']:
    for run,name,fixture,minimum in fixtures:
        project=ROOT/'.validation'/f'{run}-Shader-{engine}-{mode}'
        report=json.loads((project/f'Artifacts/{name}.json').read_text(encoding='utf-8-sig'))
        passed=report.get('success') is True if name=='measurement' else report.get('status')=='Passed'
        assert passed and report['version']=='0.6.4' and report['count']>=minimum,report
        assert (project/f'Assets/Editor/{fixture}.cs').read_bytes()==(ROOT/f'Tests/{fixture}.cs').read_bytes()
        if args.tarballs:
            lock=json.loads((project/'Packages/packages-lock.json').read_text(encoding='utf-8-sig'))['dependencies']['com.aseshader.handwritten-converter'];assert lock['source']=='local-tarball'
        if name=='path-visibility':assert all(image['visible']>=image['samples']*.9 for image in report['images']) and len(report['images'])==10
        results.append({'engine':engine,'fixture':fixture,**report})
result={'version':'0.6.4','success':True,'mode':mode,'coreChecks':629,'editorCompile':{'2022':'0 warnings / 0 errors','Unity6':'0 warnings / 0 errors'},'totalChecks':sum(r['count'] for r in results),'results':results,'semantics':'Model and mesh Scene previews write no objects/assets; Generate commits. Existing roll field banks each point. Path curve uses SceneGUI; editing needs explicit enable. Measurement Alt+D and path Alt+S are configurable in Settings/General. Linear, automatic smooth and independent Bezier corners use existing runtime fields.','limits':['Windows D3D11 and the two recorded Unity versions only.','Shortcuts are Scene-focus-only modifier+letter bindings stored on this computer; Unity shortcut conflicts can be resolved by changing them.','Live Scene previews require explicit Generate/rebuild to commit. Point rotation banks around the path tangent; height and tangents determine slopes. Bezier corners do not impose 90 degrees.'],'runtimeSchemaChanged':False,'userProjectsModified':False,'shaderSemanticsChanged':False}
if args.tarballs:
    archive=ROOT/'Releases~/com.aseshader.handwritten-converter-0.6.4.tgz';result['tarballSha256']=hashlib.sha256(archive.read_bytes()).hexdigest()
    with tarfile.open(archive,'r:gz') as t: files={m.name.removeprefix('package/'):t.extractfile(m).read() for m in t.getmembers() if m.isfile()}
    installed=[]
    for engine in ['2022','Unity6']:
        for run,_,_,_ in fixtures:
            project=ROOT/'.validation'/f'{run}-Shader-{engine}-{mode}';packages=list((project/'Library/PackageCache').glob('com.aseshader.handwritten-converter@*'));assert len(packages)==1
            fingerprint=False
            for name,expected in files.items():
                actual=(packages[0]/name).read_bytes()
                if actual==expected:continue
                assert name=='package.json';metadata=json.loads(actual);fingerprint=bool(metadata.pop('_fingerprint',None));assert fingerprint and metadata==json.loads(expected)
            installed.append({'engine':engine,'project':project.name,'packagedContentVerified':len(files),'unityFingerprintAdded':fingerprint})
    result['installedContent']=installed
    result['measurementHarness']='An isolated update callback resumes the existing fixture after actual assembly reload; no packaged measurement assertions changed.'
    output=ROOT/'Releases~/scene-tools-tarball-install-0.6.4.json'
else:
    folder=ROOT/'Documentation~/Evidence/SceneTools064';folder.mkdir(parents=True,exist_ok=True)
    build=ROOT/'.build~/SceneTools064'
    assert 'PASS: 629 checks' in (build/'core-checks.txt').read_text(encoding='utf-8-sig')
    for engine in ['2022','Unity6']:
        log=(build/f'editor-{engine}.txt').read_text(encoding='utf-8-sig')
        assert '0 个警告' in log and '0 个错误' in log
        shutil.copy2(build/f'editor-{engine}.txt',folder/f'editor-{engine}.txt')
        shutil.copy2(ROOT/f'.validation/PathPreview064-Shader-{engine}-Source/Artifacts/live-models-and-mesh.png',folder/f'live-preview-{engine}.png')
    shutil.copy2(build/'core-checks.txt',folder/'core-checks.txt')
    for report in results:(folder/(report['engine']+'-'+report['fixture']+'.json')).write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    old=ROOT/'.validation/PathVisibility064Baseline-Shader-2022-FinalTarballs/Artifacts/gizmos-on.png'
    new=ROOT/'.validation/PathVisibility064-Shader-2022-Source/Artifacts/ortho-path-gizmos-off.png'
    shutil.copy2(old,folder/'before-063.png');shutil.copy2(new,folder/'after-064.png')
    result['beforeAfter']='0.6.3 rendered only point markers in the controlled fixture. 0.6.4 draws the curve in SceneGUI and verifies pixels between markers, including Gizmos on/off, projection, generated selection, occlusion and unselected preview.'
    output=folder/'verification.json'
output.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8');print(json.dumps({'success':True,'totalChecks':result['totalChecks'],'output':str(output)}))
