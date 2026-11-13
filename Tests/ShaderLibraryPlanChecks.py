"""Focused contracts for Shader Graph dynamic types and strict preservation of implicit bindings."""
from pathlib import Path
import importlib.util,unittest
root=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('planner',root/'Tools~/Plan-LocalShaderGraphs.py');p=importlib.util.module_from_spec(spec);spec.loader.exec_module(p)
class Widths(unittest.TestCase):
    def setup_graph(self,widths):
        c=p.Convert.__new__(p.Convert);c.ids={};c.edges={};refs=[]
        for index,width in enumerate(widths):
            node='input'+str(index);slot='slot'+str(index)
            c.ids[node]={'m_ObjectId':node,'m_Slots':[{'m_Id':slot}]};c.ids[slot]={'m_Id':0,'m_Type':'Vector'+str(width)+'MaterialSlot','m_SlotType':1}
            refs.append({'m_Id':'dynamic'+str(index)});c.ids['dynamic'+str(index)]={'m_Id':index,'m_Type':'DynamicValueMaterialSlot','m_SlotType':0};c.edges['multiply',index]=(node,0)
        c.ids['out']={'m_Id':2,'m_Type':'DynamicValueMaterialSlot','m_SlotType':1};refs.append({'m_Id':'out'})
        c.ids['multiply']={'m_ObjectId':'multiply','m_Slots':refs};return c
    def test_scalar_promotes(self):
        c=self.setup_graph([1,3]);self.assertEqual(c.slotwidth(c.ids['multiply'],2),3)
    def test_minimum_vector_width(self):
        c=self.setup_graph([4,2]);self.assertEqual(c.slotwidth(c.ids['multiply'],2),2)
    def test_unconnected_dynamic_defaults_to_scalar(self):
        c=self.setup_graph([]);self.assertEqual(c.slotwidth(c.ids['multiply'],2),1)
    def test_matrix_not_guessed(self):
        c=self.setup_graph([4,2]);c.ids['slot0']['m_Type']='Matrix4MaterialSlot'
        with self.assertRaises(p.Blocked):c.slotwidth(c.ids['multiply'],2)
    def test_matrix_serialized_constant_rows(self):
        c=self.setup_graph([3]);c.g=p.Graph('HDRP','Eye');c.ids['default']={'m_Id':1,'m_Type':'DynamicValueMaterialSlot','m_SlotType':0,'m_Value':{'e00':.2,'e01':.4,'e02':.6,'e03':.8}}
        c.ids['multiply']['m_Slots'].append({'m_Id':'default'});c.input(c.ids['multiply'],1)
        self.assertEqual(c.g.plan['nodes'][0]['value'],'(0.2,0.4,0.6,0)')
    def test_group_reentry_keeps_functional_frames(self):
        plan={'nodes':[{'id':str(i),'group':g} for i,g in enumerate(['math','math','iris','math','math'])],
              'wires':[{'from':str(i),'to':str(i+1)} for i in range(4)],'comments':[{'id':'math','title':'数学','text':'计算'},{'id':'iris','title':'虹膜','text':'虹膜遮罩'}]}
        p.phase_groups(plan)
        self.assertEqual(len(plan['comments']),3)
        self.assertEqual(plan['nodes'][0]['group'],plan['nodes'][1]['group'])
        self.assertNotEqual(plan['nodes'][0]['group'],plan['nodes'][3]['group'])
        self.assertEqual(plan['nodes'][3]['group'],plan['nodes'][4]['group'])
    def test_boolean_branch_accepts_negative_nonzero(self):
        for predicate,expected in [(-2,300),(0,100),(2,300)]:
            c=p.Convert.__new__(p.Convert);c.g=p.Graph('HDRP','Eye');c.ids={'branch':{'m_ObjectId':'branch','m_Type':'BranchNode','m_Group':{}}};c.cache={};c.active=set()
            c.input=lambda n,port,width=None:c.g.f({0:predicate,1:300,2:100}[port])
            result=c.output('branch',3);nodes={n['id']:n for n in c.g.plan['nodes']};wires={(w['to'],w['toPort']):w['from'] for w in c.g.plan['wires']}
            values={int(port):float(nodes[src]['value']) for (to,port),src in wires.items() if to==result[0]}
            actual=values[2 if values[0]>values[1] else 3 if values[0]==values[1] else 4]
            self.assertEqual(actual,expected)
    def test_source_texture_defaults_are_preserved(self):
        for kind,name in enumerate(['white','black','gray','bump','linearGrey','red']):
            c=p.Convert.__new__(p.Convert);c.g=p.Graph('HDRP','Eye');c.properties={};c.assets=[]
            c.prop({'m_ObjectId':'texture','m_Type':'Texture2DShaderProperty','m_DefaultReferenceName':'_IrisMask','m_DefaultType':kind,'m_Value':{},'useTilingAndOffset':False})
            node=c.g.plan['nodes'][0];self.assertEqual(node['value'],'"'+name+'" {}')
            self.assertIn({'name':'attribute:NoScaleOffset','value':'true'},node['settings'])
if __name__=='__main__':unittest.main()
