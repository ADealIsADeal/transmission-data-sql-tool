"""Regression checks for source fidelity and heartbeat-specific field dependencies."""
import hashlib
import unittest
from pathlib import Path
from build_catalog import build, ROOT

class HeartbeatCatalogTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.catalog=build()
        cls.stages={s['id']:s for s in cls.catalog['stages']}
        cls.queries={q['id']:q for q in cls.catalog['queries']}
    def test_original_files_and_line_numbers(self):
        self.assertEqual(len(self.stages),8)
        for s in self.stages.values():
            source=ROOT/s['file']
            self.assertEqual(s['sql'],source.read_text())
            self.assertEqual(s['sha256'],hashlib.sha256(source.read_bytes()).hexdigest())
        for q in self.queries.values():
            lines=self.stages[q['stage']]['sql'].splitlines()
            for c in q['columns'].values():self.assertIn(c['expression'].splitlines()[0],lines[c['line']-1])
    def test_unpivot_flow_sources(self):
        for s in self.stages.values():
            if s['layer']!='DWS':continue
            q=self.queries[s['queries'][1]]
            for f in ['flow_value','flow_type']:
                self.assertEqual({r['field'] for r in q['columns'][f]['refs']},set(s['unpivot']['fields']))
                self.assertEqual(len(q['columns'][f]['refs']),6)
    def test_dcdn_subtracts_pcdn(self):
        q=self.queries['dwd_xlyun_transfer_heartbeat_record_download_d_inc:1']
        self.assertEqual({r['field'] for r in q['columns']['dcdn_download_bytes']['refs']},{'dcdn_download_bytes','pcdn_peer_bytes'})
    def test_all_dependencies_resolve_without_crossing_spaces(self):
        def visit(qid,field,path):
            self.assertNotIn((qid,field),path)
            if qid not in self.queries:
                self.assertEqual(qid,'dw_xlyun.pre_xlyun_transfer_log_t_30733_event_h_inc')
                self.assertEqual(field,'content');return
            q=self.queries[qid];self.assertIn(field,q['columns'])
            for r in q['columns'][field]['refs']:visit(r['query'],r['field'],path|{(qid,field)})
        for s in self.stages.values():
            for f in self.queries[s['queries'][0]]['columns']:visit(s['queries'][0],f,set())
    def test_static_partition_is_constant(self):
        for s in self.stages.values():
            self.assertEqual(self.queries[s['queries'][0]]['columns']['ds']['refs'],[])

if __name__=='__main__': unittest.main()
