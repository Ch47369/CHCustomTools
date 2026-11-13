"""Prevent file-count and graph-renaming shortcuts in pipeline correspondence."""
import copy,importlib.util,unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def module(name,path):
    s=importlib.util.spec_from_file_location(name,ROOT/path);m=importlib.util.module_from_spec(s);s.loader.exec_module(m);return m
contracts=module('contracts_test','Tools~/Build-CrossPipelineContracts.py')
water=module('water_test','Tools~/Build-DepthWaterPlan.py')
public=module('public_test','Tools~/Build-PublicLibrary.py')

class CorrespondenceChecks(unittest.TestCase):
    def test_public_filters_preserve_computation_and_source_controls(self):
        for recipe in public.RECIPES:
            plans=[public.build_plan(p,recipe) for p in contracts.PIPES]
            self.assertEqual(contracts.computation(plans[0]),contracts.computation(plans[1]),recipe)
            self.assertEqual(contracts.computation(plans[0]),contracts.computation(plans[2]),recipe)
            for plan in plans:
                names=[n['propertyName'] for n in plan['nodes'] if n.get('propertyName')]
                self.assertEqual(len(names),len(set(names)))
                self.assertEqual(0,sum(n['type']=='CustomExpressionNode' for n in plan['nodes']))
                self.assertEqual('FLOAT4',next(n for n in plan['nodes'] if n['id']==plan['outputs'][0]['node']).get('outputType','FLOAT4'))
        mirror=public.build_plan('URP','Mirror')
        switch=next(n for n in mirror['nodes'] if n['type']=='StaticSwitch')
        self.assertEqual('SYMMETRY',switch['propertyName'])
        self.assertEqual([{'name':'keyword:GlobalMultiCompile','value':'true'}],switch['settings'])
        for p in contracts.PIPES:
            template=public.template(p)
            for state in ('Cull Off','ZWrite Off','ZTest Always','Blend Off'):
                self.assertIn(state,template)
            self.assertNotIn('Blend SrcAlpha',template)
    def test_public_source_review_is_hash_locked(self):
        self.assertEqual(set(public.RECIPES),set(public.REVIEWED))
        self.assertTrue(all(len(h)==64 for h in public.REVIEWED.values()))
    def test_water_shared_computation(self):
        plans=[water.build_plan(p) for p in contracts.PIPES]
        self.assertEqual(contracts.computation(plans[0]),contracts.computation(plans[1]))
        self.assertEqual(contracts.computation(plans[0]),contracts.computation(plans[2]))
        for plan in plans:
            self.assertEqual(8,sum(n['type']=='StaticSwitch' for n in plan['nodes']))
            self.assertIn('Vertex Offset',[o['masterPort'] for o in plan['outputs']])
            self.assertEqual(0,sum(n['type']=='CustomExpressionNode' for n in plan['nodes']))
    def test_change_to_depth_or_vertex_is_detected(self):
        original=water.build_plan('URP')
        for property in ('_Density','_Absorption','_WaveHeight','_FoamWidth'):
            changed=copy.deepcopy(original)
            next(n for n in changed['nodes'] if n.get('propertyName')==property)['value']='0'
            self.assertNotEqual(contracts.computation(original),contracts.computation(changed),property)
    def test_graph_renaming_does_not_change_identity(self):
        original=water.build_plan('HDRP');changed=copy.deepcopy(original)
        for n in changed['nodes']:n['id']='renamed_'+n['id'];n['label']='presentation'
        for w in changed['wires']:w['from']='renamed_'+w['from'];w['to']='renamed_'+w['to']
        for o in changed['outputs']:o['node']='renamed_'+o['node']
        self.assertEqual(contracts.computation(original),contracts.computation(changed))
    def test_target_options_preserve_world_normal_and_transparency(self):
        for p in ('URP','HDRP'):
            plan=water.build_plan(p);settings={s['name']:s['value'] for s in plan['masterSettings']}
            self.assertEqual('Transparent',settings['option:Surface' if p=='URP' else 'option:Surface Type'])
            self.assertIn('World Normal' if p=='URP' else 'Normal WS',[o['masterPort'] for o in plan['outputs']])
            self.assertEqual('World',settings['option:Fragment Normal Space' if p=='URP' else 'option:Normal Space'])
        hdrp=water.build_plan('HDRP')
        self.assertEqual([{'name':'m_exposure','value':'false'}],next(n for n in hdrp['nodes'] if n['type']=='ScreenColorNode')['settings'])

if __name__=='__main__':unittest.main()
