"""Read local projects/archives as data. Cache selected sources only inside this workspace.
Does not execute/import project code, modify projects, or distribute their source graphs.
"""
from pathlib import Path, PurePosixPath
from collections import Counter
import argparse, hashlib, json, re, subprocess, zipfile

ROOT=Path(__file__).resolve().parents[1]
CACHE=ROOT/'.build~/LocalShaderGraphs'
EVIDENCE=ROOT/'Documentation~/Evidence/LocalLibrary030'
EXT={'.shadergraph','.shadersubgraph','.shader','.hlsl','.cginc','.compute'}
SKIP={'Library','Temp','Logs','obj','.git','PackageCache','ShaderCache'}

def write(path,value):
    path.parent.mkdir(parents=True,exist_ok=True)
    path.write_text(json.dumps(value,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')

def objects(text):
    dec=json.JSONDecoder();result=[];i=0
    while i<len(text):
        while i<len(text) and text[i].isspace():i+=1
        if i==len(text):break
        obj,i=dec.raw_decode(text,i);result.append(obj)
    return result

def categories(name,text):
    signals=[('Hosiery',r'stocking|hosiery|pantyhose|丝袜|tights'),('Skin',r'\bskin\b|skin_|subsurface|diffusionprofile|皮肤'),
             ('Hair',r'hair|\bfur\b|strand|毛发'),('Eye',r'\beye\b|iris|cornea|sclera|眼球'),('Fabric',r'fabric|cloth|silk|cotton|wool|sheen|布料|丝袜|stocking'),
             ('Water',r'water|海水'),('Metal',r'metal|anisotrop'),('Stone',r'rock|stone|triplanar|terrain'),('Jade',r'jade|玉石'),
             ('UI',r'\bui\b|stencil'),('UIAnimation',r'ui.*(?:anim|flow|dissolve)'),('VFX',r'particle|effect|dissolve|fog|cloud|distort'),
             ('UVAnimation',r'tiling|panner|flow|uv.*anim'),('VertexAnimation',r'displace|wobble|deform|wind')]
    scan=name+' '+text
    return [cat for cat,pattern in signals if re.search(pattern,scan,re.I)] or ['General']

def graph_info(text):
    obs=objects(text);graph=obs[0];lookup={o.get('m_ObjectId'):o for o in obs}
    if 'm_SerializableNodes' in graph:
        def nested(key):
            return [{**json.loads(x['JSONnodeData']),'m_Type':x.get('typeInfo',{}).get('fullName','')} for x in graph.get(key,[])]
        nodes=nested('m_SerializableNodes');props=nested('m_SerializedProperties')
        return {'format':'LegacyNestedJson','nodeCount':len(nodes),'edgeCount':len(graph.get('m_SerializableEdges',[])),
                'nodeTypes':dict(Counter(n.get('m_Type','').split('.')[-1] for n in nodes)),
                'properties':[{'name':p.get('m_Name'),'reference':p.get('m_OverrideReferenceName') or p.get('m_DefaultReferenceName'),'type':p.get('m_Type','').split('.')[-1]} for p in props],
                'targets':[],'blocks':[],'dependencies':[], 'keywordCount':len(graph.get('m_SerializedKeywords',[])),
                'groupCount':len(graph.get('m_Groups',[])),'noteCount':len(graph.get('m_StickyNotes',[]))}
    nodes=[lookup.get(x.get('m_Id'),{}) for x in graph.get('m_Nodes',[])]
    props=[lookup.get(x.get('m_Id'),{}) for x in graph.get('m_Properties',[])]
    targets=[o for o in obs if o.get('m_Type','').endswith(('Target','SubTarget','SystemData','BuiltinData','LightingData','LitData','HairData','FabricData','StackLitData'))]
    dependencies=[]
    for n in nodes:
        if n.get('m_Type','').endswith(('SubGraphNode','CustomFunctionNode')):
            dependencies.append({k:v for k,v in n.items() if k in ['m_Type','m_Name','m_FunctionName','m_FunctionSource','m_FunctionBody','m_SerializedSubGraph','m_SourceType']})
    # Function bodies remain in cache; the distributable report only records presence/hash.
    for d in dependencies:
        if d.get('m_FunctionBody'):
            d['functionBodySha256']=hashlib.sha256(d.pop('m_FunctionBody').encode()).hexdigest()
    edges=graph.get('m_Edges',[])
    inputs={}
    for e in edges:
        inp=e.get('m_InputSlot',{});inputs.setdefault(inp.get('m_Node',{}).get('m_Id'),[]).append(inp.get('m_SlotId'))
    blocks=[{'descriptor':n.get('m_SerializedDescriptor',n.get('m_Name','')),'connected':n.get('m_ObjectId') in inputs} for n in nodes if n.get('m_Type','').endswith('BlockNode')]
    return {'formatVersion':graph.get('m_SGVersion'), 'objectCount':len(obs),'nodeCount':len(nodes),'edgeCount':len(edges),
            'nodeTypes':dict(Counter(n.get('m_Type','').split('.')[-1] for n in nodes)),
            'properties':[{'name':p.get('m_Name'),'reference':p.get('m_OverrideReferenceName') or p.get('m_DefaultReferenceName'),'type':p.get('m_Type','').split('.')[-1],
                           'exposed':p.get('m_GeneratePropertyBlock',True)} for p in props],
            'targets':targets,'blocks':blocks,'dependencies':dependencies,
            'keywordCount':len(graph.get('m_Keywords',[])),'groupCount':len(graph.get('m_GroupDatas',graph.get('m_Groups',[]))),
            'noteCount':len(graph.get('m_StickyNoteDatas',[]))}

def main():
    parser=argparse.ArgumentParser();parser.add_argument('source');parser.add_argument('--sevenzip',default='C:/Program Files/7-Zip/7z.exe');args=parser.parse_args()
    source=Path(args.source).resolve();assert source.is_dir()
    CACHE.mkdir(parents=True,exist_ok=True)
    rows=[];archives=[];seen=set()
    def consume(origin,member,data,meta=b''):
        suffix=PurePosixPath(member).suffix.lower()
        if suffix not in EXT:return
        sha=hashlib.sha256(data).hexdigest();identity=(origin,member,sha)
        if identity in seen:return
        seen.add(identity)
        target=CACHE/'sources'/(sha+suffix);target.parent.mkdir(exist_ok=True);target.write_bytes(data)
        text=data.decode('utf-8-sig',errors='replace');guid=re.search(r'^guid:\s*(\w+)',meta.decode('utf-8-sig',errors='replace'),re.M)
        row={'id':'local-'+hashlib.sha256((origin+':'+member).encode()).hexdigest()[:16],'origin':origin,'path':member,'sha256':sha,'bytes':len(data),'guid':guid.group(1) if guid else '',
             'cachedSource':str(target.relative_to(ROOT)),'categories':categories(member,''),'kind':suffix[1:],'status':'ResearchOnly','license':'Local user reference; redistribution terms not asserted',
             'pipeline':'HDRP' if 'HighDefinition' in text or 'HDRenderPipeline' in text else 'URP' if 'Universal' in text or 'UniversalPipeline' in text else 'Unknown',
             'targets':[{'pipeline':p,'status':'RequiresAdapter','reason':'Source graph/HLSL semantics, dependencies, template and host must be mapped and validated.'} for p in ['BuiltIn','URP','HDRP']]}
        try:
            if suffix in {'.shadergraph','.shadersubgraph'}:
                row['graph']=graph_info(text)
                # Categories derive from declared properties/blocks/targets, not every symbol in serialized implementation.
                semantic=' '.join(str(p.get('name',''))+' '+str(p.get('reference','')) for p in row['graph']['properties'])
                row['categories']=categories(PurePosixPath(member).stem,semantic)
            else:
                row['aseGraph']='/*ASEBEGIN' in text and 'ASEEND*/' in text
                row['includes']=re.findall(r'#\s*include\s*["<]([^">]+)',text)
                row['passCount']=len(re.findall(r'\bPass\s*\{',text))
        except Exception as e:row['analysisError']=str(e)
        rows.append(row)
    # Unpacked trees only; don't recurse into caches or imported library data.
    import os
    for directory,dirs,files in os.walk(source):
        dirs[:]=[d for d in dirs if d not in SKIP]
        for name in files:
            p=Path(directory)/name
            if p.suffix.lower() not in EXT:continue
            meta=Path(str(p)+'.meta')
            consume('Unpacked',p.relative_to(source).as_posix(),p.read_bytes(),meta.read_bytes() if meta.is_file() else b'')
    for archive in sorted(source.iterdir()):
        if archive.suffix.lower() not in {'.zip','.7z'}:continue
        count=0;error=''
        try:
            if archive.suffix.lower()=='.zip':
                with zipfile.ZipFile(archive) as z:
                    names=set(z.namelist())
                    for name in sorted(names):
                        path=PurePosixPath(name)
                        if path.suffix.lower() not in EXT or SKIP.intersection(path.parts):continue
                        assert not path.is_absolute() and '..' not in path.parts
                        consume(archive.name,name,z.read(name),z.read(name+'.meta') if name+'.meta' in names else b'');count+=1
            else:
                # No executable project data is extracted. 7-Zip reads only these explicit members.
                result=subprocess.run([args.sevenzip,'l','-slt','-sccUTF-8',str(archive)],capture_output=True,encoding='utf-8',errors='replace',check=True)
                names=re.findall(r'^Path = (.+)$',result.stdout,re.M)
                for name in names:
                    path=PurePosixPath(name.replace('\\','/'))
                    if path.suffix.lower() not in EXT or SKIP.intersection(path.parts):continue
                    assert not path.is_absolute() and '..' not in path.parts
                    data=subprocess.run([args.sevenzip,'x','-so',str(archive),name],capture_output=True,check=True).stdout
                    meta=b''
                    if name+'.meta' in names:meta=subprocess.run([args.sevenzip,'x','-so',str(archive),name+'.meta'],capture_output=True,check=True).stdout
                    consume(archive.name,path.as_posix(),data,meta);count+=1
        except Exception as e:error=str(e)
        archives.append({'name':archive.name,'bytes':archive.stat().st_size,'selectedSourceFiles':count,'success':not error,'error':error})
        print(archive.name,count,error,flush=True)
    unique={r['sha256'] for r in rows}
    manifest={'schemaVersion':1,'sourceRoot':str(source),'archives':archives,'entryCount':len(rows),'uniqueContentCount':len(unique),'kinds':dict(Counter(r['kind'] for r in rows)),
              'sourceFilesModified':False,'projectCodeExecutedOrImported':False,'rows':rows}
    write(CACHE/'manifest.json',manifest)
    portable=json.loads(json.dumps(manifest));portable.pop('sourceRoot')
    for r in portable['rows']:r.pop('cachedSource',None)
    write(EVIDENCE/'local-source-research.json',portable)
    print('TOTAL',manifest['entryCount'],'unique',len(unique),manifest['kinds'],flush=True)

if __name__=='__main__':main()
