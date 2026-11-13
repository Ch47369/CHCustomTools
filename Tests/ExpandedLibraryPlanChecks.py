"""Plan contracts: real connected additions, no renamed/color-only duplicates, no cycles."""
import unittest,importlib.util,json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('expanded',ROOT/'Tools~/Build-ExpandedLibrary.py')
lib=importlib.util.module_from_spec(spec);spec.loader.exec_module(lib)

class Recipes(unittest.TestCase):
    def test_every_recipe_three_targets_and_connected_changes(self):
        signatures={}
        for category,recipes in lib.RECIPES.items():
            for pipeline in ('BuiltIn','URP','HDRP'):
                for key,title,kind in recipes:
                    with self.subTest(category=category,pipeline=pipeline,key=key):
                        graph,_=lib.base.original(pipeline,category);old=json.loads(json.dumps(graph.plan));lib.apply(graph,category,kind,title);plan=graph.plan
                        self.assertGreater(len(plan['nodes']),len(old['nodes']))
                        old_outputs={(o['masterPort'],o['pass']):(o['node'],o['port']) for o in old['outputs']}
                        changed=[o['node'] for o in plan['outputs'] if old_outputs.get((o['masterPort'],o['pass']))!=(o['node'],o['port'])]
                        self.assertTrue(changed,'Changing colors/defaults or renaming is not a new effect')
                        properties=[n['propertyName'] for n in plan['nodes'] if n.get('propertyName')]
                        self.assertEqual(len(properties),len(set(properties)),'Duplicate property declarations')
                        incoming={n['id']:[] for n in plan['nodes']}
                        for wire in plan['wires']:
                            self.assertIn(wire['from'],incoming);self.assertIn(wire['to'],incoming);incoming[wire['to']].append(wire['from'])
                        active=set();visiting=set()
                        def visit(node):
                            self.assertNotIn(node,visiting,'Graph cycle')
                            if node in active:return
                            visiting.add(node)
                            for src in incoming[node]:visit(src)
                            visiting.remove(node);active.add(node)
                        for node in changed:visit(node)
                        self.assertTrue(any(n['group']=='extension' and n['id'] in active for n in plan['nodes']))
                        self.assertTrue(all(n['type']!='CustomExpressionNode' for n in plan['nodes']))
                        # Structural operations/edges/output mappings distinguish recipes in a category.
                        signature=json.dumps([[n['type'] for n in plan['nodes']],plan['wires'],plan['outputs']],sort_keys=True)
                        identity=(category,pipeline)
                        self.assertNotIn(signature,signatures.setdefault(identity,set()),'Duplicate graph structure counted twice')
                        signatures[identity].add(signature)
    def test_research_source_not_used_as_recipe(self):
        self.assertEqual(sum(len(r) for r in lib.RECIPES.values()),70)
        self.assertEqual(len(lib.RECIPES),14)

if __name__=='__main__':unittest.main()
