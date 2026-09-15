"""Build the isolated heartbeat catalog. Supports the supplied nested SELECT/UNPIVOT tasks.
Fail closed when query structure changes; SQL is never executed.
"""
from pathlib import Path
import hashlib, json, re
ROOT = Path(__file__).resolve().parents[2]
def mask(sql):
    return re.sub(r'''--[^\n]*|/\*[\s\S]*?\*/|'(?:\\.|''|[^'\\])*'|"(?:\\.|""|[^"\\])*"''', lambda m: ''.join('\n' if c == '\n' else ' ' for c in m[0]), sql)
def build():
    stages, queries = [], []
    for source in sorted((ROOT/'SQL/心跳上报').glob('*.sql')):
        sql = source.read_text(); code = mask(sql)
        target = re.search(r'insert\s+overwrite\s+table\s+([\w.]+)', code, re.I)
        if not target: raise ValueError(f'No INSERT target: {source}')
        table = target[1]; sid = table.split('.')[-1]; layer = sid.split('_')[0].upper()
        direction = 'download' if 'download' in sid else 'upload'
        tokens=[]; depth=0
        for t in re.finditer(r'\b\w+\b|[(),;]',code):
            if t[0] == ')': depth-=1
            tokens.append((t[0].lower(), t.start(), t.end(), depth))
            if t[0] == '(': depth+=1
        selects=[i for i,t in enumerate(tokens) if t[0]=='select']
        if len(selects)!=2: raise ValueError(f'Review query bindings: {source}')
        stage_queries=[]
        for qi,ti in enumerate(selects):
            t=tokens[ti]
            stop=next(i for i in range(ti+1,len(tokens)) if tokens[i][0]=='from' and tokens[i][3]==t[3])
            cuts=[t[2]]+[x[1] for x in tokens[ti+1:stop] if x[0]==',' and x[3]==t[3]]+[tokens[stop][1]]
            cols={}
            for a,b in zip(cuts,cuts[1:]):
                while a<b and (sql[a].isspace() or sql[a]==','): a+=1
                raw=sql[a:b].strip(); clean=mask(raw).strip()
                alias=re.search(r'\bas\s+(\w+)\s*$',clean,re.I)
                if alias: name=alias[1]; body=raw[:alias.start()].strip()
                elif re.fullmatch(r'\w+',clean): name=clean; body=raw
                else: raise ValueError(f'Unsupported output: {source}: {raw}')
                if name in cols: raise ValueError(f'Duplicate field {name}')
                cols[name]={'expression':raw,'body':body,'line':sql.count('\n',0,a)+1,'refs':[]}
            qid=f'{sid}:{qi}';stage_queries.append(qid)
            queries.append({'id':qid,'stage':sid,'columns':cols})
        upstream=re.findall(r'\b(?:from|join)\s+([\w]+\.[\w]+)',code,re.I)
        if len(upstream)!=1 or re.search(r'\b(join|union|with)\b',code,re.I):
            raise ValueError(f'Review source bindings: {source}')
        schema={m[1]:{'type':m[2],'comment':m[3]} for m in re.finditer(r"--\s*,?\s*`?(\w+)`?\s+([\w]+(?:<[^>]+>)?)\s+comment\s*'([^']*)'",sql,re.I)}
        up=re.search(r'\bUNPIVOT\s*\(\s*(\w+)\s+FOR\s+(\w+)\s+IN\s*\((.*?)\)\s*\)',code,re.I|re.S)
        unpivot=None
        if up:
            pairs=re.findall(r'(\w+)\s+as\s+(\w+)',up[3],re.I)
            if len(pairs)!=6: raise ValueError(f'Review UNPIVOT: {source}')
            unpivot={'value':up[1],'type':up[2],'fields':[p[0] for p in pairs], 'mapping':dict(pairs),'expression':sql[up.start():up.end()],'line':sql.count('\n',0,up.start())+1}
        desc={'ODS':'解析原始 JSON 上报；下行事件 4660/10015，上行事件 4686/10016，按日期读取。',
              'DWD':'按上报键取 server_time 最新记录；过滤流量异常值（各字段 ≤ 10 TiB）及 service_id 白名单，解析地域、会员和平台。',
              'DWS':'按 5 分钟、流量类别及业务维度聚合；UNPIVOT 展开六类流量，仅保留 flow_value > 0，流量和 duration 分别求和。',
              'ADS':'按平台、产品、地域、会员及流量类别汇总 5 分钟流量与周期；读取前一天至当天分区，以 server_time_5min 归属日期筛选。'}[layer]
        if layer=='DWD': desc+= '下行 DCDN 流量扣除 PCDN；下行按 peer_id/app_seq_id/hash_info/traceid/record_seq 去重，上行按 peer_id/app_start_time/record_seq 去重。'
        label=('下行' if direction=='download' else '上行')+' '+{'ODS':'上报明细','DWD':'心跳明细','DWS':'任务聚合' if direction=='download' else '用户聚合','ADS':'带宽汇总'}[layer]+' '+layer
        stages.append({'id':sid,'table':table,'label':label,'layer':layer,'direction':direction,'sql':sql,'file':source.relative_to(ROOT).as_posix(),'sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'queries':stage_queries,'schema':schema,'upstream':upstream,'unpivot':unpivot,'note':desc})
    bytable={s['table']:s for s in stages}; qmap={q['id']:q for q in queries}
    keywords=set('case when then else end as cast string bigint int decimal null true false and or not is in distinct over partition by order desc asc like rlike between double float boolean'.split())
    for s in stages:
        # Static partition ds is an output too, but has no source field.
        if s['layer']=='ODS':
            m=re.search(r"partition\s*\(\s*(ds\s*=\s*'[^']*')\s*\)",s['sql'],re.I)
            qmap[s['queries'][0]]['columns']['ds']={'expression':m[1],'body':"'${date}'",'line':1,'refs':[]}
    for s in stages:
        upstream=s['upstream'][0]; upstream_q=bytable[upstream]['queries'][0] if upstream in bytable else upstream
        for qi,qid in enumerate(s['queries']):
            q=qmap[qid]; target=s['queries'][1] if qi==0 else upstream_q
            for name,col in q['columns'].items():
                if qi==1 and s['unpivot'] and name in (s['unpivot']['value'],s['unpivot']['type']):
                    u=s['unpivot']; col['expression']=u['expression'];col['body']=u['expression'];col['line']=u['line']
                    col['note']='UNPIVOT 将六个流量列转为类别和值；类别来自 AS 标签，值来自对应输入列。仅保留非空且大于 0 的流量。'
                    col['refs']=[{'query':upstream_q,'field':f} for f in u['fields']]
                    continue
                code=mask(col['body'])
                for m in re.finditer(r'\b([a-zA-Z_]\w*)\b',code):
                    f=m[1]
                    if f.lower() in keywords or re.match(r'\s*\(',code[m.end():]): continue
                    if target in qmap and f not in qmap[target]['columns']:
                        raise ValueError(f'Unresolved field: {qid}.{name} -> {target}.{f}')
                    ref={'query':target,'field':f}
                    if ref not in col['refs']:col['refs'].append(ref)
    result={'space':'heartbeat','file':'SQL/心跳上报/','stages':stages,'queries':queries}
    out=ROOT/'assets/heartbeat/catalog.json';out.write_text(json.dumps(result,ensure_ascii=False,indent=2))
    return result
if __name__=='__main__':
    c=build();print(f"Heartbeat: {len(c['stages'])} stages, {len(c['queries'])} queries")
