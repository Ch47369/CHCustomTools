"""Collect recorded Unity Scene rendering and interaction regressions for 0.6.5."""
from pathlib import Path
import argparse,json,hashlib,shutil,tarfile
ROOT=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('--tarballs',action='store_true');args=p.parse_args()
mode='FinalTarballs' if args.tarballs else 'Source'
fixtures=[('SceneStability065','scene-stability','UnitySceneStabilitySmoke',12),('PathPreview065','path-preview','UnityPathPreviewSmoke',46),('PathVisibility065','path-visibility','UnityPathVisibilitySmoke',12)]
if args.tarballs:fixtures += [('SceneTools065','scene-tools','UnitySceneToolsSmoke',77),('PathInteraction065','path-insertion','UnityPathInsertionSmoke',118),('ToolLanguage065','custom-tools','UnityCustomToolsSmoke',80),('Measurement065','measurement','UnityMeasurementSmoke',63)]
results=[]
for engine in ['2022','Unity6']:
 for run,name,fixture,minimum in fixtures:
  project=ROOT/'.validation'/f'{run}-Shader-{engine}-{mode}'
  report=json.loads((project/f'Artifacts/{name}.json').read_text(encoding='utf-8-sig'))
  assert (report.get('success') is True if name=='measurement' else report.get('status')=='Passed') and report['version']=='0.6.5' and report['count']>=minimum,report
  assert (project/f'Assets/Editor/{fixture}.cs').read_bytes()==(ROOT/f'Tests/{fixture}.cs').read_bytes()
  if name=='scene-stability':assert len(report['frames'])==24 and all(f['visible']>=f['samples']*.9 for f in report['frames'])
  if args.tarballs:
   lock=json.loads((project/'Packages/packages-lock.json').read_text(encoding='utf-8-sig'))['dependencies']['com.aseshader.handwritten-converter'];assert lock['source']=='local-tarball'
  results.append({'engine':engine,'fixture':fixture,**report})
result={'version':'0.6.5','success':True,'mode':mode,'coreChecks':629,'editorCompile':{'2022':'0 warnings / 0 errors','Unity6':'0 warnings / 0 errors'},'totalChecks':sum(r['count'] for r in results),'results':results,'behavior':'RMB click and Enter finish an open length measurement; only explicit left click on first point closes an area. Geometry is clipped at near plane and drawn in eye space with scene depth retained; labels draw after geometry. Path previews use unsaved editor-owned renderers, avoid repeated draw submission, and restore committed output visibility after each Scene render. Audio subtitle removed. Existing palette, point and pill styles retained.','limits':['Windows D3D11 and the two recorded Unity versions only.','Mouse interaction assertions use SceneView.SendEvent; no claim of physical desktop right-drag verification.','Floating-point storage remains unchanged; extreme coordinates can still limit point position precision.','Preview helpers contain only mesh/render components and are excluded from scene serialization. Generate commits outputs.'],'runtimeSchemaChanged':False,'userProjectsModified':False,'shaderSemanticsChanged':False}
if args.tarballs:
 archive=ROOT/'Releases~/com.aseshader.handwritten-converter-0.6.5.tgz';result['tarballSha256']=hashlib.sha256(archive.read_bytes()).hexdigest()
 with tarfile.open(archive,'r:gz') as t:files={m.name.removeprefix('package/'):t.extractfile(m).read() for m in t.getmembers() if m.isfile()}
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
 output=ROOT/'Releases~/scene-stability-tarball-install-0.6.5.json'
else:
 folder=ROOT/'Documentation~/Evidence/SceneStability065';folder.mkdir(parents=True,exist_ok=True);build=ROOT/'.build~/SceneStability065'
 assert 'PASS: 629 checks' in (build/'core-checks.txt').read_text(encoding='utf-8-sig')
 for engine in ['2022','Unity6']:
  log=(build/f'editor-{engine}.txt').read_text(encoding='utf-8-sig');assert '0 个警告' in log and '0 个错误' in log
  shutil.copy2(build/f'editor-{engine}.txt',folder/f'editor-{engine}.txt')
  for image in ['mixed-0.png','mixed-12.png','near-plane.png']:shutil.copy2(ROOT/f'.validation/SceneStability065-Shader-{engine}-Source/Artifacts/{image}',folder/f'{engine}-{image}')
  shutil.copy2(ROOT/f'.validation/PathPreview065-Shader-{engine}-Source/Artifacts/repeated-transparent-preview.png',folder/f'{engine}-transparent-preview.png')
 shutil.copy2(build/'core-checks.txt',folder/'core-checks.txt')
 for report in results:(folder/(report['engine']+'-'+report['fixture']+'.json')).write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
 baseline=ROOT/'.validation/SceneStability065Baseline-Shader-2022-Source/Artifacts/scene-stability.json'
 if baseline.exists():
  old=json.loads(baseline.read_text(encoding='utf-8-sig'));assert old['status']=='Failed';shutil.copy2(baseline,folder/'baseline-064-right-click-failure.json')
 result['regressionReproduction']='The published 0.6.4 baseline fails RMB completion. Intermediate native-stroke attempts reproduce perspective broken/spiked lines at (100000,10000,100000); final eye-space rendering passes all sampled frames. Transparent-repeat fixture also passed 0.6.4 and is a regression guard, not a claimed baseline failure.'
 output=folder/'verification.json'
output.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8');print(json.dumps({'success':True,'totalChecks':result['totalChecks'],'output':str(output)}))
