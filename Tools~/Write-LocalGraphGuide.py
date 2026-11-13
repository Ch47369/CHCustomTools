"""Human-readable index from analyzed metadata and audited plans, without original source code."""
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[1]
def read(path):return json.loads((ROOT/path).read_text(encoding='utf-8-sig'))
plans=read('Documentation~/Evidence/LocalLibrary030/local-adaptation-plans.json');core=read('Documentation~/Evidence/LocalLibrary030/core-analysis.json');index={r['sha256']:r for r in core['rows']}
def cell(text):return str(text).replace('|',' / ').replace('\n',' ')
lines=['# 樱花兔本地图剖析索引（0.3.0）','',
       '这里按唯一内容 SHA-256 列出 100 张 Shader Graph 的分析和适配状态；52 个子图与其余 Shader/HLSL/Compute 的清点见本轮证据 JSON。名称相同的版本不合并成一张图。分析读取结构、属性、活动模型、状态、阶段及依赖，不执行工程脚本。','',
       '20 张适配图使用真实 ASE API 生成并保存重载/编译。原材质纹理、扩散资产、人物模型、灯光/曝光与源场景画面尚未验证；Generated 不表示原图完整生产效果已复现。其余图保留首个阻塞，不能将首个阻塞修复等同于其余语义也已适配。','',
       '| 原图路径 | 内容哈希前缀 | 活动模型 | 节点 / 属性 | 本版结果 |','| --- | --- | --- | --- | --- |']
for row in plans['rows']:
    review=index[row['sha256']]['analyses'][0]['knowledge']['sourceGraph']
    status='已生成，源资源/画面待验证' if row.get('aseGenerated') else '阻塞：'+('; '.join(row['blockers']) or '; '.join(row.get('generationBlockers',[])))
    lines.append('| '+' | '.join(map(cell,[row['path'],row['sha256'][:12],review['target'] or review['format'],str(review['nodeCount'])+' / '+str(len(review['properties'])),status]))+' |')
lines+=['','## 已生成图的输入、输出与状态','',
        '属性引用名、纹理默认白/黑/法线类型与 NoScaleOffset 声明保留。纹理 GUID 只是原工程依赖身份，没有把原始贴图打包进插件。SSS 还需正确的 Diffusion Profile 和 HDRP 帧设置；毛发需要实际网格/发丝宿主数据。源中已禁用的部分端口在适配图中保留为断开原生分支，下面单独列出。','',
        '需要按源材质恢复材质开关和数值。模板 Alpha Clipping=Material Toggle 时，新建材质仍需启用 Alpha Clipping / Shadow Threshold 等开关；图端口存在不能当作源材质关键词已初始化。当前库提供 Shader，不携带原项目材质实例。','']
for row in plans['rows']:
    if not row.get('aseGenerated'):continue
    plan=read(row['plan']);review=index[row['sha256']]['analyses'][0]['knowledge']['sourceGraph']
    lines+=['### '+Path(row['path']).stem+' · '+row['sha256'][:12],'',
            '原路径：`'+row['path']+'`。源模型：`'+review['target']+'`；源节点 '+str(review['nodeCount'])+'，属性 '+str(len(review['properties']))+'。','',
            'ASE 活动输出：'+ '、'.join('`'+o['masterPort']+'`' for o in plan['outputs'])+'。','',
            '模板状态：'+ '；'.join(s['name'].replace('option:','')+'='+s['value'] for s in plan['masterSettings'])+'。','',
            '功能阶段：'+ ' → '.join(c['title'] for c in plan['comments'])+'。','',
            '源属性：'+ '、'.join('`'+(p['reference'] or p['name'])+'`' for p in review['properties'])+'。','']
    if row.get('assetBindings'):lines+=['需重绑的默认资源：'+ '；'.join('`'+a['property']+'` → `'+a['guid']+'`' for a in row['assetBindings'])+'。','']
    else:lines+=['没有记录到图默认纹理 GUID；这不代表源材质无需纹理，材质实例的资源仍须手动绑定。','']
    if row.get('inactiveOutputs'):lines+=['源中禁用、保留断开计算的输出：'+ '、'.join('`'+o['descriptor']+'`' for o in row['inactiveOutputs'])+'。','']
lines+=['## 人物和布料的具体边界','',
        '- 皮肤：本批若干源使用 StackLit，当前 ASE 无匹配模板，保持阻塞。分类库中的皮肤是原创 Lit/SSS 基础，不能冒充这些 StackLit 皮肤的完整转换。','- 眼球：三版源图的活动模型为 Lit/SSS，包含视线/UV/虹膜及法线运算。适配器显式保留切线视线空间、采样与默认块数值；非活动 Specular 分支保留断开。没有专用 Eye BSDF 或角膜外壳/眼睑宿主的等价结论。',
        '- 毛发：原图透明、裁剪、双面、深度前后 Pass、阴影阈值、光照面向法线与各向异性参数分别映射。Strands + Approximate 在当前模板只是对应光照宏，不能证明生成真实发丝或迁移其仿真。','- 织物：按源 Cotton/Wool 或 Silk 模型选真实 Fabric 模板，分别保留 SSS、Transmission、厚度、透明及双面设置，未以普通 Lit 替代其 BSDF。','- 丝袜：原材质名称尚未明确匹配；当前库为独立原创覆盖/织纹近似，不能宣称已转换该工程的丝袜。','']
(ROOT/'Documentation~/LocalGraphAnalysis.md').write_text('\n'.join(lines),encoding='utf-8')
print('Wrote 100-source index and 20 generated-adaptation guides.')
