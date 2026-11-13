"""Inspect both delivery archives without extracting or executing their contents."""
from pathlib import Path,PurePosixPath
import json,hashlib,tarfile,zipfile
ROOT=Path(__file__).resolve().parents[1]
meta=json.loads((ROOT/'package.json').read_text(encoding='utf-8-sig'));version=meta['version']
catalog=json.loads((ROOT/'Editor/Resources/ASEShaderLibraryCatalog.json').read_text(encoding='utf-8-sig'))
raw={r['sha256'] for r in catalog['research']};checks=[]
zip_prefix='ShaderConverter' if meta['displayName']=='Shader转换器' else 'ASEShaderConverter'
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
        assert hashlib.sha256(data).hexdigest() not in raw,'Raw reference source included: '+name
    assert json.loads(files['package/package.json'])['version']==version
    packed_catalog=json.loads(files['package/Editor/Resources/ASEShaderLibraryCatalog.json'])
    assert packed_catalog==catalog
    assert len([p for p in files if p.startswith('package/Samples~/ShaderLibrary/') and p.endswith('.shader')])==len(catalog['entries'])
    for entry in catalog['entries']:assert hashlib.sha256(files['package/'+entry['path']]).hexdigest()==entry['sha256']
    for folder in ['Runtime','Editor']:
        for source in (ROOT/folder).glob('*.cs'):assert files['package/'+source.relative_to(ROOT).as_posix()]==source.read_bytes()
    checks.append({'file':archive.name,'bytes':archive.stat().st_size,'sha256':hashlib.sha256(archive.read_bytes()).hexdigest(),'files':len(files),
        'libraryShaderCount':len(catalog['entries']),'allCatalogAndSourceHashesMatch':True,'referenceSourcesAndAseSourcesExcluded':True,'buildCachesAndPythonBytecodeExcluded':True})
output=ROOT/'Releases~'/('release-verification-'+version+'.json');output.write_text(json.dumps({'version':version,'archives':checks},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps(checks,ensure_ascii=False,indent=2))
