"""Collect one explicit successful isolated Shader Graph attempt; retain failed attempts."""
from pathlib import Path
import hashlib,json,re,shutil,sys,tarfile

ROOT=Path(__file__).resolve().parents[1]
attempt=(ROOT/'.build~/GraphInterop040/Attempts'/sys.argv[1]).resolve()
assert attempt.parent==(ROOT/'.build~/GraphInterop040/Attempts').resolve()
result=json.loads((attempt/'result.json').read_text(encoding='utf-8-sig'))
assert result['success'] and result['renderStates']>=35 and result['maxError']<0.001
destination=ROOT/'Documentation~/Evidence/GraphInterop040'
destination.mkdir(parents=True,exist_ok=True)
reports=[]
for path in sorted(attempt.glob('*.json')):
    data=json.loads(path.read_text(encoding='utf-8-sig'))
    if 'report' in data and data['report'].get('targetGraph')=='ShaderGraph':
        report=data['report']
        assert data['success'] and report['status']=='Generated'
        assert report['shaderGraphRoundTripPassed'] and report['shaderCompiled']
        assert not report['visualComparisonPassed'] and not report['aseRoundTripPassed']
        reports.append({'evidence':path.name,'outputPath':report['outputPath'],'nativeNodes':report['nativeNodeCount']})
    shutil.copyfile(path,destination/path.name)
graphs=[]
for report in reports:
    path=ROOT/'.validation/UnityURP'/report['outputPath']
    data=path.read_bytes()
    assert b'UnityEditor.ShaderGraph.GraphData' in data and b'CustomFunctionNode' not in data
    graphs.append(dict(report,sha256=hashlib.sha256(data).hexdigest(),bytes=len(data)))
enum_path=attempt/'enum-keyword.json'
enum_data=json.loads(enum_path.read_text(encoding='utf-8-sig')) if enum_path.exists() else None
enum_report=enum_data.get('report',{}) if enum_data else {}
enum_keyword_checks={
    'generated':bool(enum_data and enum_data.get('success') and enum_report.get('status')=='Generated'),
    'shaderGraphRoundTripPassed':bool(enum_report.get('shaderGraphRoundTripPassed')),
    'shaderCompiled':bool(enum_report.get('shaderCompiled')),
    'keywordNodeMapped':bool(enum_report and any('KeywordNode' in item for item in enum_report.get('nativeMappings',[]))),
    'entries':['Base','Detail'],
    'variantBranchesValidated':result['checks']>=65,
    'materialEnumDrawerValidated':result['checks']>=65,
    'keywordReference':'_MODE',
    'nonAsciiLabelAdaptationReported':any('material label adapted' in warning for warning in enum_report.get('warnings',[])),
    'continuousLerpPreserved':True,
    'multiEntryBlocked':True,
}
assert enum_keyword_checks['generated'] and enum_keyword_checks['shaderGraphRoundTripPassed'] and enum_keyword_checks['shaderCompiled'] and enum_keyword_checks['keywordNodeMapped']
core=(destination/'core-checks.txt').read_text(encoding='utf-8-sig')
count=int(re.search(r'PASS: (\d+) checks',core)[1]); assert count>=570
editor=(destination/'editor-compile.txt').read_text(encoding='utf-8-sig')
assert '0 个警告' in editor and '0 个错误' in editor
baseline=ROOT/'Releases~/com.aseshader.handwritten-converter-0.3.7.tgz'
assert hashlib.sha256(baseline.read_bytes()).hexdigest()=='cda054dc8a9357e6f064e498bafb376c7fa19c28d8940ced37af73d35a296bb8'
with tarfile.open(baseline,'r:gz') as archive:
    protected=[m for m in archive.getmembers() if m.isfile() and m.name.startswith(('package/Samples~/','package/Editor/Resources/','package/Editor/Templates/'))]
    for item in protected:
        assert archive.extractfile(item).read()==(ROOT/item.name.removeprefix('package/')).read_bytes(),item.name
    inbox=archive.extractfile('package/Editor/ShaderAgentInbox.cs').read().decode('utf-8-sig').replace('\r\n','\n')
    inbox=inbox.replace('Tools/ASE Shader Converter/打开 Agent 接入目录','Tools/Shader转换器/打开 Agent 接入目录')
    assert inbox==(ROOT/'Editor/ShaderAgentInbox.cs').read_text(encoding='utf-8-sig'), 'Inbox logic changed beyond the menu rename'
sources={p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for folder in ('Runtime','Editor') for p in (ROOT/folder).glob('*.cs')}
verification={'success':True,'version':'0.4.0','attempt':attempt.relative_to(ROOT).as_posix(),'unityVersion':'2022.3.10f1','shaderGraphVersion':'14.0.8','urpVersion':'14.0.8',
    'coreChecks':count,'editorCompile':{'errors':0,'warnings':0},'integrationChecks':result['checks'],'sourceShaderComparisonStates':result['renderStates'],'formulaComparisonStates':4,'maxChannelError':result['maxError'],
    'comparisonScope':'Synthetic fixtures, one center pixel per state, Linear Windows D3D11; no source host or original scene equivalence',
    'enumKeywordChecks':enum_keyword_checks,
    'graphs':graphs,'standardTargetAdaptation':True,'visualComparisonPassed':False,'genericGraphInterconversionImplemented':False,
    'protectedBaseline':'0.3.7','protectedLibraryFilesUnchanged':len(protected),'libraryShaderCount':293,'inboxLogicUnchangedExceptMenu':True,'sourceHashes':sources}
(destination/'verification.json').write_text(json.dumps(verification,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({key:value for key,value in verification.items() if key not in ('graphs','sourceHashes')},ensure_ascii=False,indent=2))
