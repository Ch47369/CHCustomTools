"""Read only project versions/material-to-shader identities. Never imports project code."""
from pathlib import Path,PurePosixPath
import json,hashlib,re,os,zipfile,subprocess,importlib.util
ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('research',ROOT/'Tools~/Research-LocalShaderGraphs.py');r=importlib.util.module_from_spec(spec);spec.loader.exec_module(r)
m=json.loads((r.CACHE/'manifest.json').read_text(encoding='utf-8-sig'));source=Path(m['sourceRoot']);rows=[]
def wanted(path):return path.suffix.lower()=='.mat' or path.name=='ProjectVersion.txt' or (path.name=='manifest.json' and path.parent.name=='Packages')
def consume(origin,name,data):
    text=data.decode('utf-8-sig',errors='replace');p=PurePosixPath(name)
    row={'origin':origin,'path':name,'sha256':hashlib.sha256(data).hexdigest()}
    if p.suffix.lower()=='.mat':
        found=re.search(r'm_Shader:\s*\{[^}]*guid:\s*([a-f0-9]{32})',text)
        matname=re.search(r'^  m_Name: (.*)$',text,re.M)
        name=matname.group(1) if matname else p.stem
        if name.startswith('"'):
            try:name=json.loads(name)
            except ValueError:pass
        row.update(kind='MaterialBinding',name=name,shaderGuid=found.group(1) if found else '',categories=r.categories(p.stem+' '+name,''))
    elif p.name=='ProjectVersion.txt':row.update(kind='ProjectVersion',version=text.strip())
    else:
        try:row.update(kind='PackageVersions',dependencies={k:v for k,v in json.loads(text).get('dependencies',{}).items() if 'render-pipelines' in k or 'shadergraph' in k})
        except ValueError:row.update(kind='InvalidManifest')
    rows.append(row)
for directory,dirs,files in os.walk(source):
    dirs[:]=[d for d in dirs if d not in r.SKIP]
    for name in files:
        p=Path(directory)/name
        if wanted(p):consume('Unpacked',p.relative_to(source).as_posix(),p.read_bytes())
for archive in sorted(source.iterdir()):
    if archive.suffix.lower()=='.zip':
        with zipfile.ZipFile(archive) as z:
            for name in z.namelist():
                p=PurePosixPath(name)
                if wanted(p) and not r.SKIP.intersection(p.parts):consume(archive.name,name,z.read(name))
    elif archive.suffix.lower()=='.7z':
        names=re.findall(r'^Path = (.+)$',subprocess.run(['C:/Program Files/7-Zip/7z.exe','l','-slt','-sccUTF-8',str(archive)],capture_output=True,encoding='utf-8',check=True).stdout,re.M)
        for name in names:
            p=PurePosixPath(name.replace('\\','/'))
            if wanted(p) and not r.SKIP.intersection(p.parts):consume(archive.name,p.as_posix(),subprocess.run(['C:/Program Files/7-Zip/7z.exe','x','-so',str(archive),name],capture_output=True,check=True).stdout)
    else:continue
    print(archive.name,flush=True)
for row in m['rows']:
    if row['kind'] in ('shadergraph','shadersubgraph'):row['graph']=r.graph_info((ROOT/row['cachedSource']).read_text(encoding='utf-8-sig'))
    matches=[x for x in rows if x['kind']=='MaterialBinding' and x['origin']==row['origin'] and x['shaderGuid'] and x['shaderGuid']==row['guid']]
    row['materialNames']=sorted({x['name'] for x in matches})
    if any('Hosiery' in x['categories'] for x in matches):row['categories']=sorted(set(row['categories']+['Hosiery','Fabric']))
r.write(r.CACHE/'manifest.json',m)
portable=json.loads(json.dumps(m));portable.pop('sourceRoot')
for row in portable['rows']:row.pop('cachedSource',None)
r.write(r.EVIDENCE/'local-source-research.json',portable)
r.write(r.EVIDENCE/'project-material-metadata.json',{'sourceReadOnly':True,'rows':rows,'materialCount':sum(x['kind']=='MaterialBinding' for x in rows),'hosieryMatches':[x for x in rows if 'Hosiery' in x.get('categories',[])]})
print('metadata',len(rows),'hosiery',[x['name'] for x in rows if 'Hosiery' in x.get('categories',[])])
