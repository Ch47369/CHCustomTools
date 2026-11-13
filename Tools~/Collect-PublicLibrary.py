"""Identity-check actual ASE reports; merge successful reviewed source graphs.
Never promote a download, plan, stale result, or merely compiled source to Generated.
"""
from pathlib import Path
from collections import Counter
import json,hashlib,shutil,re
ROOT=Path(__file__).resolve().parents[1];E=ROOT/'Documentation~/Evidence/PublicLibrary033'
HOSTS={'BuiltIn':'Unity2022','URP':'UnityURP','HDRP':'UnityHDRP'}
def read(p):return json.loads((ROOT/p).read_text(encoding='utf-8-sig'))
def write(p,o):p=ROOT/p;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(json.dumps(o,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()

def main():
    catalog=read('Editor/Resources/ASEShaderLibraryCatalog.json');metadata=read('.build~/PublicLibrary033/entries.json');manifest=read('.build~/ShaderCorpus/Library033/manifest-library033.json')
    results={};verified=[]
    for p,host in HOSTS.items():
        evidence=E/('Build-'+p);evidence.mkdir(parents=True,exist_ok=True)
        source=ROOT/'.validation'/host/'LibraryBuildEvidence';result=read(source/'results.json');log=ROOT/'.build~/PublicLibrary033'/('build-'+p+'.log')
        assert result['completed'] and result['pipeline']==p and len(result['rows'])==4
        assert 'ASE_LIBRARY_BUILD_COMPLETE '+p in log.read_text(encoding='utf-8-sig')
        for row in result['rows']:
            assert row['id'].startswith('public-'+p+'-');results[row['id']]=row
        for file in [source/'results.json',source/'probe.json']+list(source.glob('public-'+p+'*-describe.json')):shutil.copy2(file,evidence/file.name)
    assert set(results)=={r['id'] for r in metadata}
    for m in metadata:
        row=results[m['id']];response=row['response'];report=response.get('report') or {};plan=read(m['plan'])
        assert response['success'] and report['status']=='Generated' and report['aseRoundTripPassed'] and report['shaderCompiled'],(m['id'],response.get('error'),report.get('blockers'))
        assert report['shaderName']==plan['shaderName'] and row['output']==report['outputPath']
        assert report['layoutApplied'] and report['commentCount']>=4 and report['customExpressionCount']==0
        source=ROOT/'.validation'/HOSTS[m['pipeline']]/report['outputPath'];assert source.is_file()
        output=Path('Samples~/ShaderLibrary')/m['category']/m['pipeline']/(m['id']+'.shader');(ROOT/output).parent.mkdir(parents=True,exist_ok=True)
        text=source.read_text(encoding='utf-8-sig');assert '/*ASEBEGIN' in text and plan['shaderName'] in text
        for state in ('Cull Off','ZWrite Off','ZTest Always','Blend Off'):assert state in text
        if m['recipe']=='Mirror':assert re.search(r'#pragma\s+multi_compile\s+[^\n]*\bSYMMETRY_ON\b',text) and 'multi_compile_local' not in text
        shutil.copy2(source,ROOT/output)
        entry={k:v for k,v in m.items() if k not in ('plan','sourceRepository','sourcePath','sourceCommit')}
        entry.update({k:report[k] for k in ('aseRoundTripPassed','shaderCompiled','visualComparisonPassed','layoutApplied','nativeNodeCount','customExpressionCount','commentCount','unityVersion','aseVersion','templateGuid','status')})
        samples=sum(n['type']=='SamplerNode' for n in plan['nodes']);models=re.findall(r'#pragma\s+target\s+([0-9.]+)',text)
        entry.update(path=output.as_posix(),sha256=sha(source),evidence='Documentation~/Evidence/PublicLibrary033/Build-'+m['pipeline']+'/results.json',
            textureSampleSites=samples,transparent=False,vertexAnimation=False,performanceTier='Low' if samples==1 else 'Medium',deviceValidation='NotBenchmarked',
            devices=['PC'] if m['pipeline']=='HDRP' else ['Mobile','Pad','PC'],shaderModel=max(models,key=float),graphicsApiValidation='Windows D3D11',
            performanceBasis=f'{samples} 个静态图内采样位置；{report["nativeNodeCount"]} 个原生节点；全屏成本随输出分辨率增加，历史帧/宿主成本另计。非 GPU 测速。',
            deviceRequirements='模板 target 3.0；Mobile/Pad 为静态候选，未在 Android/iOS、Metal/Vulkan/GLES、XR 或动态分辨率验证。',
            notes='逐源码审核的 MIT 显式输入图像滤镜。生成 Shader 与材质后需绑定输入纹理；不自动改变场景或注入相机，不含原 C# 宿主。原宿主 uniform 以同名材质参数暴露，默认值为插件示例预设。',
            keywords=[m['recipe'],m['title'],'滤镜','后处理','图像','image','filter','Kino','MIT'],
            dependencies=['编辑图需保留插件 Editor/Templates/ImageFilter'+m['pipeline']+'.shader。','调用者提供 _MainTex，并保证输入/输出采用相同色彩编码、纹理方向和目标平台全屏绘制。'])
        if m['recipe']=='DigitalGlitch':entry['dependencies']+=['需提供 _NoiseTex、历史帧 _TrashTex；不自动生成噪声或捕获历史帧。']
        if m['recipe']=='AnalogGlitch':entry['dependencies']+=['外部动画参数积分由调用者提供；_Time.x 由秒/20 保留。']
        if m['recipe']=='Mirror':entry['keywords']+=['万花筒','镜像','kaleidoscope','symmetry'];entry['dependencies']+=['_Divisor > 0；SYMMETRY_ON 使用全局 multi_compile。']
        verified.append(entry)
    # All four sources require all three successful variants before this batch is merged.
    assert len(verified)==12 and Counter(e['pipeline'] for e in verified)=={'BuiltIn':4,'URP':4,'HDRP':4}
    ids={e['id'] for e in verified};catalog['entries']=[e for e in catalog['entries'] if e['id'] not in ids]+verified
    core=read(E/'CoreAnalysis/public-corpus-analysis.json')
    assert core['summary']['analysisErrors']==0 and len(core['files'])==41
    core_by_sha={r['sha256']:r for r in core['files']}
    baseline=ROOT/'.build~/PublicLibrary033/base-catalog.json'
    if not baseline.exists():write(baseline,catalog)
    # Identity records may share source bytes. Preserve every existing id; a
    # sha-keyed dictionary would silently remove distinct historical identities.
    existing=catalog['research'];existing_ids={r['id'] for r in existing}
    historical=read(baseline)['research'];historical_ids={r['id'] for r in historical}
    existing += [r for r in historical if r['id'] not in existing_ids]
    analysis=[]
    for repository in manifest['repositories']:
        for file in repository['files']:
            adapted=any(e['sourceSha256']==file['sha256'] for e in verified)
            text=Path(file['localPath']).read_text(encoding='utf-8-sig');model=re.search(r'#pragma\s+surface\s+\w+\s+(\w+)',text)
            blockers=[] if adapted else ['该输入未建立逐源码三管线图计划，未执行该输入的 ASE 保存重载/编译。','Surface 光照模型 '+(model[1] if model else 'unknown')+'、附加 Pass/阴影及编译指令必须显式适配，不能直接替换普通 Lit。']
            if not adapted:blockers+=list(dict.fromkeys(b for t in core_by_sha[file['sha256']]['targets'] for b in t['blockers']))
            category='UVAnimation' if file['path'].endswith('/Mirror.shader') else 'VFX' if adapted else 'Metal' if re.search('Metal|Specular|Standard',Path(file['path']).name) else 'General'
            license='MIT (notice embedded in selected shader)' if adapted else repository['license']
            normalization=None
            prior=[r for r in historical if r['source']==file['url'] and r['sha256']!=file['sha256']]
            if prior:
                raw=Path(file['localPath']).read_bytes();crlf=raw.replace(b'\r\n',b'\n').replace(b'\n',b'\r\n')
                assert all(hashlib.sha256(crlf).hexdigest()==r['sha256'] for r in prior),('Changed source identity needs a separate reviewed revision',file['url'])
                normalization={'rawDownloadSha256':file['sha256'],'historicalCrlfSha256':prior[0]['sha256'],'difference':'LF versus CRLF only; same fixed commit/path, not an additional source identity'}
                existing[:]=[r for r in existing if not(r['id'].startswith('public033-') and r['id'] not in historical_ids and r['source']==file['url'])]
                matching=[r for r in existing if r['id'] in {h['id'] for h in prior}]
            else:matching=[r for r in existing if r['sha256']==file['sha256']]
            if not matching:
                matching=[{'id':'public033-'+file['sha256'][:16],'title':Path(file['path']).stem,'source':file['url'],'sha256':file['sha256'],'kind':'shader','pipeline':'BuiltIn'}];existing.extend(matching)
            for record in matching:
                record.update(license=license,status='ReviewedLibraryPlans' if adapted else 'RequiresAdapter',evidence='Documentation~/Evidence/PublicLibrary033/source-analysis.json',categories=list(dict.fromkeys(record.get('categories',[])+[category])),blockers=blockers)
            record=matching[0]
            analysis.append({'sha256':file['sha256'],'source':file['url'],'path':file['path'],'license':license,'status':record['status'],'categories':record['categories'],
                             'sourceModel':model[1] if model else 'ExplicitUnlitImageFilter','byteNormalization':normalization,'automaticAnalysis':core_by_sha[file['sha256']]['targets'],
                             'targets':[{ 'pipeline':p,'status':'Generated' if adapted else 'RequiresAdapter','blockers':blockers} for p in HOSTS]})
    catalog.update(version='0.3.3',research=existing)
    write('Editor/Resources/ASEShaderLibraryCatalog.json',catalog)
    write(E/'source-analysis.json',{'downloadedFiles':len(analysis),'adaptedSources':4,'remainingNewSources':37,'rows':analysis})
    write(E/'library-entries.json',{'entries':verified})
    print(json.dumps({'artifacts':len(catalog['entries']),'families':len({e['familyId'] for e in catalog['entries']}),'research':len(catalog['research']),'newGeneratedArtifacts':len(verified)}))
if __name__=='__main__':main()
