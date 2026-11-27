"""Inspect both delivery archives without extracting or executing their contents."""
from pathlib import Path,PurePosixPath
import json,hashlib,tarfile,zipfile
ROOT=Path(__file__).resolve().parents[1]
meta=json.loads((ROOT/'package.json').read_text(encoding='utf-8-sig'));version=meta['version']
checks=[]
archive_files=[]
zip_prefix='CHCustomTools' if meta['displayName']=='CH自定义工具集' else 'ShaderConverter' if meta['displayName']=='Shader转换器' else 'ASEShaderConverter'
paths=[ROOT/'Releases~'/(meta['name']+'-'+version+'.tgz'),ROOT/'Releases~'/(zip_prefix+'-'+version+'.zip')]
for archive in paths:
    if archive.suffix=='.tgz':
        with tarfile.open(archive,'r:gz') as tar:
            assert all(not (m.issym() or m.islnk()) for m in tar.getmembers())
            files={m.name:tar.extractfile(m).read() for m in tar.getmembers() if m.isfile()}
    else:
        with zipfile.ZipFile(archive) as z:files={name:z.read(name) for name in z.namelist() if not name.endswith('/')}
    for name,data in files.items():
        parts=PurePosixPath(name).parts
        assert parts[0]=='package' and '..' not in parts
        assert not set(parts).intersection({'AmplifyShaderEditor','.validation','.build~','bin','bin~','obj','obj~','__pycache__'})
        assert not name.endswith(('.pyc','.shadergraph','.shadersubgraph'))
    assert json.loads(files['package/package.json'])['version']==version
    assert 'package/Editor/Resources/ASEShaderLibraryCatalog.json' not in files
    assert 'package/Editor/Resources/ASEShaderLibraryCatalog.json.meta' not in files
    assert not any(p.startswith('package/Samples~/ShaderLibrary/') for p in files)
    archive_files.append(files)
    for folder in ['Runtime','Editor']:
        for source in (ROOT/folder).rglob('*.cs'):assert files['package/'+source.relative_to(ROOT).as_posix()]==source.read_bytes()
    checks.append({'file':archive.name,'bytes':archive.stat().st_size,'sha256':hashlib.sha256(archive.read_bytes()).hexdigest(),'files':len(files),
        'libraryShaderCount':0,'bundledLibraryRemoved':True,'allSourceHashesMatch':True,'asePackageSourcesExcluded':True,'buildCachesAndPythonBytecodeExcluded':True})
assert archive_files[0]==archive_files[1], 'Delivery contents differ'
output=ROOT/'Releases~'/('release-verification-'+version+'.json');output.write_text(json.dumps({'version':version,'archives':checks},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps(checks,ensure_ascii=False,indent=2))
