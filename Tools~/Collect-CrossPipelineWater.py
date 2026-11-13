"""Collect only identity-checked real ASE outputs from isolated target hosts."""
from pathlib import Path
import copy,json,hashlib,shutil,re
ROOT=Path(__file__).resolve().parents[1]
def read(path):return json.loads((ROOT/path).read_text(encoding='utf-8-sig'))
def write(path,data):
    path=ROOT/path;path.parent.mkdir(parents=True,exist_ok=True);path.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
catalog=read('Editor/Resources/ASEShaderLibraryCatalog.json')
base=next(e for e in catalog['entries'] if e['id']=='original-BuiltIn-DeepWater')
base['familyId']='Water-DeepWater';base['vertexAnimation']=True
base['title']=base['effect']='DeepWater 深度吸收 / 折射 / 焦散'
base['notes']='完整世界坐标波浪、RGB 深度吸收、岸沫、焦散和屏幕折射；需要相机深度及不透明水底。颜色 Alpha 不作为不透明度旋钮。八组本地功能开关在新材质中初始化，宿主拷贝和灯光差异见三管线对应表。'
base['textureSampleSites']=5
base['performanceBasis']='5 个图内纹理采样位置、1 个场景颜色采样与场景深度读取；385 个原生节点；透明覆盖、场景拷贝与细分顶点成本。模板隐含工作另计，未做 GPU 测速。'
for p,project in [('URP','UnityURP'),('HDRP','UnityHDRP')]:
    evidence=f'Documentation~/Evidence/CrossPipeline032/Build-{p}/results.json';result=read(evidence)
    assert result['completed'] and result['pipeline']==p and len(result['rows'])==1
    row=result['rows'][0];assert row['id']==f'DeepWater-{p}'
    response=row['response'];report=response['report'];plan=read(f'.build~/CrossPipeline032/DeepWater-{p}.json')
    assert response['success'] and report['status']=='Generated' and report['aseRoundTripPassed'] and report['shaderCompiled']
    assert report['shaderName']==plan['shaderName'] and report['pipeline']==p
    assert report['layoutApplied'] and report['commentCount']>=9 and report['customExpressionCount']==0
    source=ROOT/'.validation'/project/report['outputPath'];target=f'Samples~/ShaderLibrary/Water/{p}/original-{p}-DeepWater.shader'
    (ROOT/target).parent.mkdir(parents=True,exist_ok=True);shutil.copy2(source,ROOT/target)
    e=copy.deepcopy(base);e.update(id=f'original-{p}-DeepWater',pipeline=p,path=target,evidence=evidence)
    e.update({k:report[k] for k in ('aseRoundTripPassed','shaderCompiled','visualComparisonPassed','layoutApplied','nativeNodeCount','customExpressionCount','commentCount','unityVersion','aseVersion','templateGuid','status')})
    e['sha256']=hashlib.sha256(source.read_bytes()).hexdigest()
    models=re.findall(r'#pragma\s+target\s+([0-9.]+)',source.read_text(encoding='utf-8-sig'));e['shaderModel']=max(models,key=float)
    e['deviceRequirements']='Windows D3D11 / target '+e['shaderModel']+'；PC 候选；移动设备及其他图形 API 尚未验证。'
    e['dependencies']=['细分水平水面网格；不透明水底必须写入深度。','URP Opaque Texture + Depth Texture + Copy Depth: After Opaques / Force Prepass + Reflection Probe。' if p=='URP' else 'HDRP Color Pyramid + Depth + Reflection Probe；默认透明阶段；HDRP 尚缺独立高光/环境反射开关。']
    catalog['entries']=[item for item in catalog['entries'] if item['id']!=e['id']]+[e]
catalog['version']='0.3.2'
write('Editor/Resources/ASEShaderLibraryCatalog.json',catalog)
print('Collected 2 additional pipeline artifacts; total',len(catalog['entries']))
