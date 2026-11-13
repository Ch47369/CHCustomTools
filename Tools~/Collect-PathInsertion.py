"""Collect real Scene Ctrl-click, shape preservation and handle drag checks."""
from pathlib import Path
import argparse,json,hashlib
ROOT=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('--tarballs',action='store_true');args=p.parse_args()
mode='FinalTarballs' if args.tarballs else 'Source';results=[]
for engine in ('2022','Unity6'):
    project=ROOT/'.validation'/f'PathInsertion061-Shader-{engine}-{mode}'
    data=json.loads((project/'Artifacts/path-insertion.json').read_text(encoding='utf-8-sig'))
    assert data['status']=='Passed' and data['count']>=63 and data['version']=='0.6.1',data
    if args.tarballs:
        lock=json.loads((project/'Packages/packages-lock.json').read_text(encoding='utf-8-sig'))['dependencies']['com.aseshader.handwritten-converter'];assert lock['source']=='local-tarball'
    results.append(data)
report={'success':True,'version':'0.6.1','mode':mode,'coreChecks':629,'totalChecks':sum(x['count'] for x in results),'results':results}
if args.tarballs:
    archive=ROOT/'Releases~/com.aseshader.handwritten-converter-0.6.1.tgz';report['tarballSha256']=hashlib.sha256(archive.read_bytes()).hexdigest()
    target=ROOT/'Releases~/path-insertion-tarball-install-0.6.1.json'
else:
    folder=ROOT/'Documentation~/Evidence/PathInsertion061';folder.mkdir(parents=True,exist_ok=True)
    for data in results:(folder/(data['unity']+'.json')).write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    target=folder/'verification.json'
target.write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8');print(json.dumps({'success':True,'checks':report['totalChecks'],'output':str(target)}))
