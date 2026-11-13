"""Collect real Unity source/install results. Keeps failed attempts in .build~ intact."""
from pathlib import Path
import argparse,json,hashlib,datetime
ROOT=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('--tarballs',action='store_true');args=p.parse_args()
mode='FinalTarballs' if args.tarballs else 'Source'
items=[]
for engine in ('2022','Unity6'):
    path=ROOT/'.validation'/f'PathTools060-Shader-{engine}-{mode}'/'Artifacts/path-tools.json'
    data=json.loads(path.read_text(encoding='utf-8-sig'))
    assert data['status']=='Passed' and data['count']>=95 and data['version']=='0.6.0',data
    items.append({'engine':engine,'report':path.relative_to(ROOT).as_posix(),'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),**data})
report={'version':'0.6.0','success':True,'mode':mode,'checkedUtc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'results':items,'totalChecks':sum(i['count'] for i in items),'limits':['Windows D3D11 only; no standalone Player build, hardware benchmark or arbitrary SRP version claim.','Static outputs require rebuild after path edits; rigid instancing, no model bending.','Tight bends can overlap; UV1 is an effect channel, not a lightmap atlas.']}
if args.tarballs:target=ROOT/'Releases~/path-tools-tarball-install-0.6.0.json'
else:
    evidence=ROOT/'Documentation~/Evidence/PathTools060';evidence.mkdir(parents=True,exist_ok=True)
    for i in items:(evidence/(i['engine']+'.json')).write_text(json.dumps(i,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    target=evidence/'verification.json'
target.write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8');print(json.dumps({'success':True,'path':str(target),'totalChecks':report['totalChecks']}))
