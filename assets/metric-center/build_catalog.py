"""Extract exact SELECT expressions and source locations; no SQL is executed."""
from pathlib import Path
import re,json,hashlib,argparse,runpy
ROOT=Path(__file__).resolve().parents[2]
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--source',type=Path,default=ROOT/'SQL/任务结束上报',help='线上 SQL 目录（默认仓库 SQL/任务结束上报）')
args=parser.parse_args()
source_files = list(args.source.glob('*.sql'))
order = ['dws_xlyun_transfer_download_sub_task_d_inc', 'dws_xlyun_transfer_download_seqid_d_inc', 'dwd_xlyun_transfer_seqid_platform_d_inc', 'dwd_xlyun_transfer_seqid_platform_dedup_d_inc', 'dwd_xlyun_transfer_log_h_inc', 'dwd_xlyun_transfer_pc_log_h_inc']
sources=[]
for table in order:
    matches=[p for p in source_files if re.search(r'insert\s+overwrite\s+(?:table\s+)?dw_xlyun\.'+table+r'\b',p.read_text(),re.I)]
    if len(matches)!=1: raise ValueError(f'{table}: expected one source, got {matches}')
    sources.append(matches[0])
sql=''.join(p.read_text()+'\n' for p in sources)
# Mask comments and quoted strings while preserving character positions and line numbers.
def mask(s):
    return re.sub(r"--[^\n]*|/\*[\s\S]*?\*/|'(?:\\.|''|[^'\\])*'|\"(?:\\.|[^\"\\])*\"",lambda m:''.join('\n' if c=='\n' else ' ' for c in m[0]),s)
masked=mask(sql)
headers=list(re.finditer(r'--  FILE:\s+(\S+)',sql))
labels=['子任务 DWS','分片 DWS','统一 DWD','分片去重 DWD','移动端小时 DWD','PC 小时 DWD']
stages=[];queries=[]
for si,h in enumerate(headers):
    start=h.end();end=headers[si+1].start() if si+1<len(headers) else len(sql)
    tokens=[];depth=0
    for t in re.finditer(r'\b\w+\b|[(),;]',masked[start:end]):
        if t[0]==')':depth-=1
        tokens.append((t[0].lower(),start+t.start(),start+t.end(),depth))
        if t[0]=='(':depth+=1
    stage_queries=[]
    for ti,t in enumerate(tokens):
        if t[0]!='select':continue
        stop=next((j for j in range(ti+1,len(tokens)) if tokens[j][0]=='from' and tokens[j][3]==t[3]),None)
        if stop is None:continue
        cuts=[t[2]]+[x[1] for x in tokens[ti+1:stop] if x[0]==',' and x[3]==t[3]]+[tokens[stop][1]]
        cols={}
        for a,b in zip(cuts,cuts[1:]):
            while a<b and (sql[a].isspace() or sql[a]==','):a+=1
            raw=sql[a:b].strip();clean=mask(raw).strip()
            alias=re.search(r'\bas\s+(\w+)\s*$',clean,re.I)
            if alias:name=alias[1];body=raw[:alias.start()].strip()
            elif re.fullmatch(r'(?:\w+\.)?\w+',clean):name=clean.split('.')[-1];body=raw
            else:
                alias=re.search(r'\s+(\w+)\s*$',clean)
                if not alias:raise ValueError(raw)
                name=alias[1];body=raw[:alias.start()].strip()
            cols[name]={'expression':raw,'body':body,'line':sql.count('\n',0,a)+1}
        qi=len(stage_queries);qid=f'{si}:{qi}'
        stage_queries.append(qid)
        queries.append({'id':qid,'stage':si,'columns':cols})
    # Only the executable statement, excluding commented DDL.
    active=[t for t in tokens if t[0] in ('with','insert')]
    a=active[0][1];b=next(t[2] for t in tokens if t[0]==';' and t[1]>a)
    table=re.search(r'insert\s+overwrite\s+(?:table\s+)?([\w.]+)',masked[a:b],re.I)[1]
    ddl={m[1]:{'type':m[2],'comment':m[3]} for m in re.finditer(r"--\s*,?\s*(\w+)\s+([\w]+(?:\([^)]*\))?)\s+comment\s+'([^']*)'",sql[start:end],re.I)}
    stages.append({'id':si,'label':labels[si],'table':table,'sql':sql[a:b],'line':sql.count('\n',0,a)+1,'queries':stage_queries,'schema':ddl})
print([(s['label'],s['queries']) for s in stages])
for q in queries:print(q['id'],len(q['columns']),list(q['columns'])[:3])
# Explicit relation bindings from FROM/JOIN clauses in the supplied SQL.
bindings={
 '0:0':{'_':['1:0']},
 '1:0':{'download':['1:1'],'gcid':['1:2'],'_':['1:1']},
 '1:1':{'_':['2:2']},'1:2':{'_':['dw_xlyun.dim_xlyun_transfer_mp_gcid_info_d_inc']},
 '2:0':{'d':['3:2'],'hfk':['2:1']},'2:1':{'_':['dw_xlyun.dim_xlyun_transfer_gcid_forbidden_hfk_d_inc']},
 '2:2':{'joined':['2:0'],'dim_pub1':['2:3'],'dim_pub2':['2:4']},
 '2:3':{'_':['dw_xlyun.dim_pub_sundry_manual_full']},'2:4':{'_':['dw_xlyun.dim_pub_sundry_manual_full']},
 '3:0':{'_':['5:0']},'3:1':{'_':['4:0']},'3:2':{'ranked':['3:0','3:1']},
 '4:0':{'raw':['4:1'],'_':['4:1']},'4:1':{'_':['complat_odl.stat_heartbeat']},
 '5:0':{'raw':['5:1'],'_':['5:1']},'5:1':{'_':['complat_odl.stat_event']}
}
assert set(bindings)=={q['id'] for q in queries}
qmap={q['id']:q for q in queries}
keywords=set('case when then else end as cast string bigint int decimal null true false and or not is in distinct over partition by order desc asc like rlike between regexp rows range current row preceding following date timestamp double float boolean array map struct'.split())
for q in queries:
    q['bindings']=bindings[q['id']]
    for name,col in q['columns'].items():
        code=mask(col['body']);refs=[]
        for m in re.finditer(r'\b([a-zA-Z_]\w*)(?:\.([a-zA-Z_]\w*))?',code):
            word,field=m[1],m[2]
            if not field and (word.lower() in keywords or re.match(r'\s*\(',code[m.end():])):continue
            targets=q['bindings'].get(word if field else '_',[])
            if not targets and not field:
                targets=[x for xs in q['bindings'].values() for x in xs if x in qmap and word in qmap[x]['columns']]
            for target in targets:
                f=field or word
                if target in qmap and f not in qmap[target]['columns']:continue
                ref={'query':target,'field':f}
                if ref not in refs:refs.append(ref)
        col['refs']=refs
# Keep complete source files, including headers and DDL; line numbers are file-local.
for stage, source in zip(stages, sources):
    offset=sum(p.read_text().count('\n')+1 for p in sources[:stage['id']])
    for q in queries:
        if q['stage']==stage['id']:
            for col in q['columns'].values(): col['line']-=offset
    stage['sql']=source.read_text()
    stage['line']=1
    stage['file']='SQL/任务结束上报/'+source.name
    stage['sha256']=hashlib.sha256(source.read_bytes()).hexdigest()
    # Legacy download URLs remain byte-identical to the canonical source.
    (ROOT/'assets/metric-center/sql'/(stage['table'].split('.')[-1]+'.sql')).write_bytes(source.read_bytes())
result={'file':'SQL/任务结束上报/', 'sha256':hashlib.sha256(sql.encode()).hexdigest(),'stages':stages,'queries':queries,'fields':list(dict.fromkeys([*qmap['0:0']['columns'],*qmap['1:0']['columns']]))}
(ROOT/'assets/metric-center/catalog.json').write_text(json.dumps(result,ensure_ascii=False,indent=2))
heartbeat=runpy.run_path(str(ROOT/'assets/heartbeat/build_catalog.py'))['build']()
page=ROOT/'传输库血缘与自助取数.html';html=page.read_text()
html=re.sub(r'<script type="application/json" id="heartbeatCatalog">[\s\S]*?</script>\s*','',html)
heartbeat_block='<script type="application/json" id="heartbeatCatalog">'+json.dumps(heartbeat,ensure_ascii=False).replace('<','\\u003c')+'</script>'
html=html.replace('  <script>','  '+heartbeat_block+'\n  <script>',1)
block='<script type="application/json" id="productionCatalog">'+json.dumps(result,ensure_ascii=False).replace('<','\\u003c')+'</script>'
html=re.sub(r'<script type="application/json" id="productionCatalog">[\s\S]*?</script>\s*','',html)
html=html.replace('  <script>','  '+block+'\n  <script>',1)
whitepaper=json.loads((ROOT/'assets/metric-center/whitepaper.json').read_text())
overrides_path=ROOT/'assets/metric-center/metric-overrides.json'
if overrides_path.exists():
    overrides=json.loads(overrides_path.read_text())['metrics']
    known={metric['name'] for metric in whitepaper['metrics']}
    if set(overrides)-known: raise ValueError('Unknown metric overrides: '+str(set(overrides)-known))
    for metric in whitepaper['metrics']:
        metric.update(overrides.get(metric['name'],{}))
html=re.sub(r'<script type="application/json" id="whitepaperCatalog">[\s\S]*?</script>\s*','',html)
whitepaper_block='<script type="application/json" id="whitepaperCatalog">'+json.dumps(whitepaper,ensure_ascii=False).replace('<','\\u003c')+'</script>'
html=html.replace('  <script>','  '+whitepaper_block+'\n  <script>',1)
runtime=(ROOT/'assets/metric-center/center.js').read_text()+(ROOT/'assets/metric-center/whitepaper.js').read_text()+(ROOT/'assets/heartbeat/heartbeat.js').read_text()+(ROOT/'assets/metric-center/canvas-pan.js').read_text()
style=(ROOT/'assets/metric-center/center.css').read_text()+(ROOT/'assets/metric-center/whitepaper.css').read_text()+(ROOT/'assets/heartbeat/heartbeat.css').read_text()
html=re.sub(r'    // BEGIN GENERATED METRIC CENTER[\s\S]*?    // END GENERATED METRIC CENTER',lambda m:'    // BEGIN GENERATED METRIC CENTER\n'+runtime+'    // END GENERATED METRIC CENTER',html)
html=re.sub(r'    /\* BEGIN GENERATED METRIC CENTER \*/[\s\S]*?    /\* END GENERATED METRIC CENTER \*/',lambda m:'    /* BEGIN GENERATED METRIC CENTER */\n'+style+'    /* END GENERATED METRIC CENTER */',html)
# Both spaces share the same selectors, including responsive and dark styles.
style_end=html.index('</style>')
shared_css=html[:style_end]
for original, counterpart in {'page-lineage':'page-heartbeat','tableLineage':'hbTableView','fieldLineage':'hbFieldView','tableDetailPanel':'hbTableDetail','fieldDetailPanel':'hbFieldDetail'}.items():
    shared_css=re.sub(r'(?<!:is\()#'+original+r'\b', ':is(#'+original+',#'+counterpart+')', shared_css)
html=shared_css+html[style_end:]
theme_style=(ROOT/'assets/theme.css').read_text()
theme_script=(ROOT/'assets/theme.js').read_text()
def embed_theme(document):
    document=re.sub(r'<style id="app-theme-style">[\s\S]*?</style>\s*','',document)
    document=re.sub(r'<script id="app-theme-script">[\s\S]*?</script>\s*','',document)
    return document.replace('</head>','<style id="app-theme-style">'+theme_style+'</style>\n<script id="app-theme-script">'+theme_script+'</script>\n</head>')
html=embed_theme(html)
page.write_text(html)
(ROOT/'app.html').write_text(html)
index=ROOT/'index.html'
index.write_text(embed_theme(index.read_text()))

# Version iframe URLs when the embedded application changes.
version=hashlib.sha256(html.encode()).hexdigest()[:12]
for name in ['自助取数.html','指标中心.html','数据血缘.html','平台导航.html','常用工具.html']:
    entry=ROOT/name
    entry.write_text(re.sub(r'src="app\.html(?:\?v=[a-zA-Z0-9]+)?"', 'src="app.html?v='+version+'"', entry.read_text()))
