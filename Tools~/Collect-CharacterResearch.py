"""Cache selected installed HDRP reference data and collect character evidence; never import/execute sources."""
from pathlib import Path
from datetime import datetime, timezone
import hashlib
import json
import shutil
import sys

ROOT=Path(__file__).resolve().parents[1]
CORPUS=ROOT/'.build~/ShaderCorpus'
DEST=ROOT/'Documentation~/Evidence/CharacterMaterials029'
PACKAGE=ROOT/'.validation/UnityHDRP/Library/PackageCache/com.unity.render-pipelines.high-definition@14.0.8'


def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def write(path,value):
    path.parent.mkdir(parents=True,exist_ok=True)
    path.write_text(json.dumps(value,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def snapshot():
    package=read(PACKAGE/'package.json')
    assert package['version']=='14.0.8'
    paths=['Eye/Eye.hlsl','Eye/Eye.cs.hlsl','Eye/EyeUtils.hlsl','Eye/EyeCausticLUT.hlsl',
           'Hair/Hair.hlsl','Hair/Hair.cs.hlsl','Hair/PreIntegratedAzimuthalScattering.hlsl',
           'Fabric/Fabric.hlsl','Fabric/Fabric.cs.hlsl','Fabric/FabricReference.hlsl','Fabric/CharlieConvolve.shader',
           'Lit/Lit.hlsl','Lit/LitData.hlsl','Lit/Lit.shader',
           'SubsurfaceScattering/SubsurfaceScattering.hlsl','SubsurfaceScattering/CombineLighting.shader']
    files=[]
    for relative in paths:
        source=PACKAGE/'Runtime/Material'/relative
        assert source.is_file(),relative
        member='Runtime/Material/'+relative
        cached='InstalledHDRP14.0.8/'+member
        target=CORPUS/'Unity-Technologies--Graphics'/cached
        target.parent.mkdir(parents=True,exist_ok=True)
        shutil.copyfile(source,target)
        files.append({'path':cached,'sha256':sha(source),'bytes':source.stat().st_size,'localPath':str(target),
                      'url':'https://packages.unity.com/com.unity.render-pipelines.high-definition/-/com.unity.render-pipelines.high-definition-14.0.8.tgz',
                      'archiveMember':member,'origin':'Installed official package; not fetched Git HEAD'})
    license_text=(PACKAGE/'LICENSE.md').read_text(encoding='utf-8-sig')
    assert 'Unity Companion License' in license_text
    public=read(CORPUS/'manifest-characters029.json')
    record={'repository':'Unity-Technologies/Graphics','commit':'','package':'com.unity.render-pipelines.high-definition','packageVersion':'14.0.8',
            'license':'Unity Companion License','licenseSha256':sha(PACKAGE/'LICENSE.md'),'packageJsonSha256':sha(PACKAGE/'package.json'),
            'success':True,'transport':'Read-only installed official Unity package snapshot; no Git commit asserted',
            'evaluationRole':'InstalledVersionReference','files':files}
    combined={'schemaVersion':1,'checkedUtc':datetime.now(timezone.utc).isoformat(),
              'purpose':'Character source research. Cached sources never executed, imported or distributed.',
              'repositories':public['repositories']+[record]}
    write(CORPUS/'manifest-character-reference029.json',combined)
    # Persist identifiers, hashes, origin, license and failure evidence, not source code.
    manifest_copy=json.loads(json.dumps(combined))
    for repo in manifest_copy['repositories']:
        for file in repo.get('files',[]):file.pop('localPath',None)
    write(DEST/'sources.json',manifest_copy)
    print('Character source snapshot:',sum(len(r.get('files',[])) for r in combined['repositories'] if r.get('success')),'files; installed HDRP reference:',len(files))


def collect():
    source=ROOT/'.validation/UnityHDRP/CharacterLibraryEvidence'
    result=(source/'result.txt').read_text(encoding='utf-8-sig')
    assert result.startswith('PASS:')
    rules=read(source/'rules.json')['ruleLibrary']
    assert rules['version']=='0.2.9' and len(rules['characterProfiles'])==4
    target=DEST/'UnityHDRP'
    target.mkdir(parents=True,exist_ok=True)
    for file in source.iterdir():
        if file.suffix in ('.json','.txt'):shutil.copyfile(file,target/file.name)
    log=ROOT/'.build~/ValidationRuns/Character-library-final2.log'
    assert 'ASE_CHARACTER_LIBRARY_SMOKE_PASS' in log.read_text(encoding='utf-8-sig',errors='replace')
    probe=read(source/'probe.json')['environment']
    templates=[dict(name=t['name'],guid=t['guid'],ready=t['ready']) for t in probe['templates'] if 'HDRP' in t['path']]
    evidence={'checkedUtc':datetime.now(timezone.utc).isoformat(),'unity':probe['unityVersion'],'ase':probe['aseVersion'],'pipeline':probe['activePipeline'],
              'profileCount':4,'categoryCount':len(rules['categories']),'ruleCount':len(rules['rules']),
              'templates':templates,'eyeTemplatePresent':any('eye' in t['name'].lower() for t in templates),
              'aseGenerationPerformed':False,'characterShaderCompilationPerformed':False,'characterVisualComparisonPerformed':False,'gpuBenchmarked':False,
              'log':{'path':str(log.relative_to(ROOT)),'sha256':sha(log),'marker':'ASE_CHARACTER_LIBRARY_SMOKE_PASS'},
              'codeHashes':{str(p.relative_to(ROOT)):sha(p) for p in [ROOT/'Runtime/CharacterMaterialLibrary.cs',ROOT/'Runtime/ShaderRuleLibrary.cs',ROOT/'Editor/CharacterMaterialWindow.cs',ROOT/'Tests/UnityCharacterLibrarySmoke.cs']},
              'result':result}
    write(DEST/'verification.json',evidence)
    print('PASS: four profiles and blocked analysis through Unity API; Hair/Fabric/Lit descriptions persisted; no generated character shader claim.')


if __name__=='__main__':
    if len(sys.argv)>1 and sys.argv[1]=='--collect':collect()
    else:snapshot()
