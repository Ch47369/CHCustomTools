"""Explicit native-node adaptation of the user-selected Fangmu jade article.

The article supplies one scattering function, not a complete material shader.
Reference HTML/images/code remain in .build~; only our ASE-authored outputs ship.
"""
from pathlib import Path
import hashlib,html,importlib.util,json,re
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'.build~/JadeReference036'; E=ROOT/'Documentation~/Evidence/JadeArticle036'
spec=importlib.util.spec_from_file_location('jade_base',ROOT/'Tools~/Build-ShaderLibraryPlans.py')
base=importlib.util.module_from_spec(spec);spec.loader.exec_module(base)
PIPES=('BuiltIn','URP','HDRP')
HOSTS={'BuiltIn':'Unity2022','URP':'UnityURP','HDRP':'UnityHDRP'}
URL='https://mp.weixin.qq.com/s/fzxGFhe5DofKpyauJSPypg'
REVIEWED_CODE_SHA256='a9cc314b7587c26e32c17e12fd87f0a8dffb19447ad5528a1522e33dac99993f'
def write(p,v):base.write(p,v)
def build(p,fixture=False):
    g=base.Graph(p,'Jade',fixture)
    g.plan['shaderName']='ASELibrary/'+p+'/Jade/FangmuLogicalLight'+('Fixture' if fixture else '')
    g.phase('inputs','01 文章核心参数与范围','参考：方木君《Unity移动端高性能玉石材质》。文章只提供散射函数；本图的 Lit 表面整合为补充实现。Offset、距离均为模型局部单位；DepthDistance + LightDistance > 0，MaxDist > MinDist，Pow > 0。')
    f=g.f;op=g.op;sw=g.sw;mul=g.mul;add=g.add;sub=g.sub;div=g.div
    offset=sw(g.v((0,0,0,0),'_JadeOffset','玉石中心偏移（局部空间）'),'xyz')
    lightdistance=f(1,'_JadeLightDistance','逻辑光源距离',min=0,max=5)
    depth=f(.5,'_JadeDepthDistance','玉石深度距离',min=.001,max=5)
    power=f(2,'_JadePow','距离衰减指数',min=.01,max=8)
    mindist=f(.1,'_JadeMinDist','透射映射下限',min=0,max=1)
    maxdist=f(.9,'_JadeMaxDist','透射映射上限',min=0,max=1)
    jade=sw(g.v((.09,.65,.3,1),'_JadeColor','玉石散射颜色',True),'xyz')
    manual=sw(g.v((.6,.5,-.6,0),'_JadeMainLightWS','手动光方向（世界空间，指向光源）'),'xyz')
    g.phase('light','02 世界光方向 → 局部空间','场景模式读取 ASE 原生主光方向：Built-in/URP 主方向光，HDRP 第一方向光。手动模式由调用者提供同语义方向。World→Object 后归一化，匹配 TransformWorldToObjectDir 的默认行为；不能当作位置变换，非等比缩放也保留此顺序。')
    direction=manual
    if not fixture:
        direction=g.node('StaticSwitch',propertyName='_JADE_SCENE_LIGHT',displayName='使用场景主方向光（关闭后手动）',propertyKind='Float',value='1')
        g.wire(g.node('WorldSpaceLightDirHlpNode'),direction,'True');g.wire(manual,direction,'False')
    light=op('TransformDirectionNode',direction,settings=[{'name':'m_from','value':'World'},{'name':'m_to','value':'Object'},{'name':'m_normalize','value':'true'}])
    lightpoint=sub(offset,mul(light,lightdistance))
    g.phase('distance','03 逻辑光源点与表面距离','保留原减号：lightPoint = Offset - normalize(WorldToObjectDir(L)) * LightDistance。片元局部位置由 ASE 插值读取，等价于在静态网格上把 posWS 变回局部空间。模型中心取网格原点，可用 Offset 修正；不是实时厚度或真实体积路径追踪。')
    pos=g.node('PosVertexDataNode');distance=op('DistanceOpNode',lightpoint,pos)
    normalized=div(distance,add(depth,lightdistance))
    g.phase('ramp','04 距离指数与两次饱和','严格保留 saturate(pow(distance / (DepthDistance + LightDistance), Pow))，再做 (Travel - MinDist)/(MaxDist - MinDist)，最后逐 RGB 通道 saturate(weight * JadeColor)。不能提前 saturate weight；不交换 exponent 与第一次 saturate，也不偷偷用 epsilon 改原公式。参数奇点需要使用者避免。')
    travel=op('SaturateNode',op('PowerNode',normalized,power))
    weight=div(sub(travel,mindist),sub(maxdist,mindist))
    result=op('SaturateNode',mul(weight,jade))
    if fixture:
        guid=hashlib.sha256(('jade-formula-fixture-'+p).encode()).hexdigest()[:32]
        g.plan['templateGuid']=guid
        g.phase('output','05 公式验证输出','仅供隔离浮点夹具：输出原核心 RGB 和 Alpha=1，不进入发布目录。和 CPU 参考逐像素比较，不能当作原完整材质或文章原场景等价。')
        rgba=op('DynamicAppendNode',sw(result,'x'),sw(result,'y'),sw(result,'z'),f(1),outputType='FLOAT4')
        g.output(rgba,'Color','Unlit')
    else:
        g.phase('surface','05 补充的抛光玉石表面','文章未提供完整材质着色代码。这里使用各管线的标准 Lit 表面接收照明/高光，核心散射作为可调 Emission；保持不透明、单面、深度写入。不是 HDRP 扩散轮廓 SSS、真实厚度散射，也未复原作者模型/贴图/环境。')
        surface=sw(g.v((.018,.055,.028,1),'_SurfaceColor','表面基色（补充）',True),'xyz')
        smooth=f(.88,'_Smoothness','表面光滑度（补充）')
        strength=f(.8,'_JadeStrength','散射贡献（补充）',min=0,max=3)
        main='ForwardBase' if p=='BuiltIn' else ''
        g.output(surface,'Albedo' if p=='BuiltIn' else 'Base Color',main)
        g.output(f(0),'Metallic',main);g.output(smooth,'Smoothness',main)
        g.output(mul(result,strength),'Emission',main);g.output(f(1),'Alpha',main)
    return g.plan
def main():
    text=(OUT/'article.html').read_text(encoding='utf-8');start=text.index('id="js_content"');end=text.index('<script',start)
    body=text[start:end];code=re.search(r'<code\b[^>]*>(.*?)</code>',body,re.S).group(1)
    code=html.unescape(re.sub(r'<[^>]+>','',re.sub(r'<br\s*/?>','\n',code))).replace('\xa0',' ')
    code='\n'.join(line.rstrip() for line in code.splitlines()).strip()+'\n'
    assert 'float3 SSSDiffuseColor(float3 posWS)' in code and 'TransformWorldToObjectDir(_MainLightPosition)' in code
    (OUT/'reference-function.hlsl.txt').write_bytes(code.encode('utf-8'))
    sha=hashlib.sha256(code.encode()).hexdigest()
    assert sha==REVIEWED_CODE_SHA256,'Article function changed; review before replacing plans/evidence'
    review={'title':'Unity移动端高性能玉石材质','author':'方木君','url':URL,'sourceKind':'ArticleCoreFunctionOnly','codeSha256':sha,'articleHtmlSha256':hashlib.sha256((OUT/'article.html').read_bytes()).hexdigest(),'license':'No explicit open-source license found in article; attributed technique reimplemented as native nodes; source text/images are excluded from distribution.','formulaPreserved':True,'fullOriginalMaterialAvailable':False,'originalSceneEquivalent':False,'limitations':['No original complete Shader, parameter defaults, mesh, textures or lighting setup supplied.','Logical distance is a geometric approximation, not measured thickness or physical volume transport.','DepthDistance + LightDistance must be positive, MaxDist > MinDist, Pow > 0, nonzero light direction, invertible model transform.','Core is independent of light color, intensity, shadows and normal, as in the published function. Lit integration is newly authored.','No mobile/Pad/GPU benchmarks; article title is not performance evidence.']}
    write(E/'source-review.json',review);write(OUT/'reviewed-source.json',review)
    entries=[]
    for p in PIPES:
        # Diagnostic host is authored locally, excluded from the distributed package.
        fspec=importlib.util.spec_from_file_location('jade_fixture_host',ROOT/'Tools~/Build-PublicLibrary.py')
        filters=importlib.util.module_from_spec(fspec);fspec.loader.exec_module(filters)
        fixturehost=filters.template(p).replace('Image Filter '+p,'Jade Formula Fixture '+p).replace('ZTest Always','ZTest LEqual')
        if p=='HDRP':
            # ASE's HDRP Transform Direction emits camera declarations even when
            # World->Object never reads them. Rename only the added, unused
            # diagnostic declarations; leave Unity's real camera globals intact.
            names=('unity_CameraProjection','unity_CameraInvProjection','unity_WorldToCamera','unity_CameraToWorld')
            fixturehost=fixturehost.replace('/*ase_globals*/','\n'.join('#define '+n+' jadeUnused_'+n for n in names)+'\n            /*ase_globals*/\n'+ '\n'.join('#undef '+n for n in names))
        fixturehost=fixturehost.replace('/*ase_pragma*/','#define GetWorldToObjectMatrix() unity_WorldToObject\n            /*ase_pragma*/')
        fixturepath=ROOT/'.validation'/HOSTS[p]/'Assets/JadeArticle036/FormulaFixture.shader'
        fixturepath.parent.mkdir(parents=True,exist_ok=True);fixturepath.write_text(fixturehost,encoding='utf-8')
        fixturepath.with_suffix('.shader.meta').write_text('fileFormatVersion: 2\nguid: '+hashlib.sha256(('jade-formula-fixture-'+p).encode()).hexdigest()[:32]+'\n',encoding='utf-8')
        jobs=[]
        for fixture in (False,True):
            ident='jade-article-'+p+('-fixture' if fixture else '');plan=build(p,fixture);path=OUT/(ident+'.json');write(path,plan)
            jobs.append({'id':ident,'planPath':str(path),'output':'Assets/JadeArticle036/'+p+'/LogicalLight'+('Fixture' if fixture else '')+'_ASE.shader'})
        write(OUT/('jobs-'+p+'.json'),{'jobs':jobs})
        entries.append({'id':'jade-article-'+p,'familyId':'Fangmu-LogicalLight-Jade','title':'逻辑光源玉石 · 方木君文章方案','category':'Jade','pipeline':p,'origin':'ReviewedArticleAdaptation','source':URL,'sourceSha256':sha,'license':review['license'],'plan':str((OUT/('jade-article-'+p+'.json')).relative_to(ROOT))})
    write(OUT/'entries.json',entries)
    print('3 material plans + 3 non-distributed formula fixtures; code SHA256',sha)
if __name__=='__main__':main()
