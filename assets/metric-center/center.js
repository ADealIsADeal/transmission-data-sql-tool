    const production=JSON.parse(document.getElementById('productionCatalog').textContent);
    const productionQueries=Object.fromEntries(production.queries.map(q=>[q.id,q]));
    const productionScope="PC 任务结束事件；移动端 eventstatus='2'。按 platform、seqid、parent_id、file_url、peer_id 取当日 ts 最新记录。分片 DWS 保留六端 download / withdraw，排除 bt_main、magnet；子任务按当日五个键聚合。";
    const metricNotes={
      seq_total:['任务结束记录经分片去重、业务过滤后，统计分片 DWS 记录数。','同一分片在同一天按 platform、seqid、parent_id、file_url、peer_id 去重，取 ts 最新记录；跨天按日记录累计。'],
      avg_global_speed:['分片 DWS 的 global_speed 算术平均值，单位 KB/s，包含 0。','小时层仅保留上报速度大于 0 的值；统一 DWD 转 bigint；分片 DWS 除以 1024，NULL 转为 0，因此分片平均速度包含这些 0。'],
      seq_zero_speed_total:['下载时长 > 10 秒且原始接收量 = 0 的分片数。','零速判定发生在分片 DWS 内层：download_time > 10 and recv_bytes = 0。原始 recv_bytes 为 NULL 时不计零速，不能使用外层补 0 后的值重新判定。'],
      seq_zero_speed_rate:['零速分片数 / 分片数。','分子、分母均来自相同日期和筛选范围的分片 DWS。'],
      seq_fail_total:["最终结果为 failure 或 fail 的分片数。","seq_fail 由 final_result in ('failure', 'fail') 生成；其余结果不计失败。"],
      seq_fail_rate:['失败分片数 / 分片数。','分子、分母均来自相同日期和筛选范围的分片 DWS。'],
      cnt_sub_task:['按 platform、action_type、peerid、parentid、download_url 聚合后的子任务记录数。',"每天聚合；peerid、parentid、download_url 的 NULL 先转为 'N/A'。跨天累计的是每日子任务记录数，并非跨天重新按五键去重。"],
      avg_global_speed_sub_task:['先对每个子任务的非零分片速度取平均，再对子任务速度取平均，单位 KB/s。','子任务层 avg(if(global_speed is not null and global_speed <> 0, global_speed, null))；全部为 0 或 NULL 的子任务速度为 NULL，不参与最终 avg。每个有效子任务等权，不按分片数或时长加权。'],
      zero_speed_cnt_sub_task:['全部分片都被标记为零速的子任务数。',"sum(if(seq_zero_speed='1',1,0)) = count(1) 才标记为 '1'；只要有一个分片未被标记为零速，子任务就不计零速。"],
      task_zero_speed_rate:['零速子任务数 / 子任务数。','子任务零速要求全部分片零速；分子、分母使用同一子任务 DWS 范围。'],
      fail_cnt_sub_task:['最后一条分片被标记为失败的子任务数。','子任务 seq_fail = max_by(seq_fail, ts)，按 ts 取末条状态；并非任意分片失败就算子任务失败。ts 并列时 SQL 未指定次级排序。'],
      task_fail_rate:['失败子任务数 / 子任务数。','失败状态取子任务末条分片；分子、分母使用同一子任务 DWS 范围。'],
      sum_p2p_bytes_sub_task:['子任务 phub_bytes 与 tracker_bytes 相加后求和，单位 Byte。','分片层这两个字段 NULL 转 0，子任务层分别按分片求和；指标查询再次 ifnull 后相加。P2P 此处只包含 Phub 与 Tracker。'],
      sum_all_bytes_sub_task:['子任务 all_bytes 求和，单位 Byte。','分片 DWS 对 all_bytes 的 NULL 转 0，子任务层 sum(all_bytes)；指标对入选子任务再次求和。'],
      p2p_byte_rate_sub_task:['P2P 流量 / 总流量。','先汇总 Phub + Tracker 和 all_bytes，再相除；不对单个子任务的占比取平均。'],
      total_peer_users:['子任务 DWS 中按 peerid 去重的用户数。',"count(distinct peerid)；上游将 NULL peerid 归为 'N/A'，因此存在这类记录时会计为一个用户。默认数据含下载和取回，单看下载需筛选 action_type='download'。"],
      fail_peer_users:['至少有一个失败子任务的用户数，按 peerid 去重。','先按子任务末条分片判定失败，再对这些子任务的 peerid 去重；同一用户其他成功子任务不影响计入。'],
      fail_peer_user_rate:['失败用户数 / 下载用户数。','分子为至少有一个失败子任务的去重 peerid；分母为相同范围全部去重 peerid。跨天应对整个日期范围重新去重，不能累加每日用户数。'],
      zero_speed_peer_users:['至少有一个零速子任务的用户数，按 peerid 去重。','零速子任务要求全部分片都零速；用户只需有一个这样的子任务即可计入，并非用户全部子任务都零速。'],
      zero_speed_peer_user_rate:['零速用户数 / 下载用户数。','分子为至少有一个零速子任务的去重 peerid；分母为相同范围全部去重 peerid。跨天重新去重，不能累加每日用户数。']
    };
    function metricSummary(m){return metricNotes[m.id][0]}
    function metricSourceFields(m){
      const expression=(m.grain==='seq'?seqSql:taskSql)[m.id];
      return [...new Set([...expression.matchAll(/\b[bt]\.([a-z_]+)/g)].map(x=>x[1]))];
    }
    function metricCalculationSql(m){
      const expression=(m.grain==='seq'?seqSql:taskSql)[m.id].replace(/\b[bt]\./g,'');
      return `-- 基于线上 DWS 字段的指标查询；不是源文件中的 ADS SQL\n-- 日期格式 YYYYMMDD；默认包含下载与取回，可追加业务筛选\n-- 占比返回 0～1，展示百分比时乘以 100\nSELECT\n    ${expression}\nFROM ${m.sourceTable}\nWHERE ds = '\${date}';`;
    }
    function renderMetrics(){
      const q=$('#metricSearch').value.trim().toLowerCase(),cat=$('#metricCategory').value,grain=$('#metricGrain').value;
      const groups=['seq','task','user','untagged'];
      const order=['seq_total','avg_global_speed','seq_zero_speed_total','seq_zero_speed_rate','seq_fail_total','seq_fail_rate','cnt_sub_task','avg_global_speed_sub_task','zero_speed_cnt_sub_task','task_zero_speed_rate','fail_cnt_sub_task','task_fail_rate','total_peer_users','zero_speed_peer_users','zero_speed_peer_user_rate','fail_peer_users','fail_peer_user_rate','sum_all_bytes_sub_task','sum_p2p_bytes_sub_task','p2p_byte_rate_sub_task'];
      const list=metrics.filter(m=>(!grain||metricDisplayGroup(m)===grain)&&(!cat||m.category===cat)&&(!q||`${m.cn} ${m.id} ${metricSummary(m)}`.toLowerCase().includes(q)))
        .sort((a,b)=>groups.indexOf(metricDisplayGroup(a))-groups.indexOf(metricDisplayGroup(b))||order.indexOf(a.id)-order.indexOf(b.id));
      $('#metricRows').innerHTML=`<table class="metric-overview"><thead><tr><th>指标名称</th><th>统计对象</th><th>指标口径</th><th><span class="sr-only">操作</span></th></tr></thead><tbody>${list.length?list.map(m=>`<tr><th scope="row"><button class="metric-name-link" data-detail="${m.id}">${esc(m.cn)}</button></th><td><span class="tag ${m.grain}">${m.grain==='seq'?'分片':m.grain==='user'?'用户':'子任务'}</span></td><td>${esc(metricSummary(m))}</td><td><button class="metric-detail-link" data-detail="${m.id}" aria-label="查看${esc(m.cn)}详情">详情 <span aria-hidden="true">↗</span></button></td></tr>`).join(''):'<tr><td colspan="4" class="metric-empty">没有找到符合条件的指标，试试其他关键词或筛选条件。</td></tr>'}</tbody></table>`;
      $('#metricResultCount').textContent=`${list.length} 个指标`;
      $$('[data-detail]',$('#metricRows')).forEach(b=>b.onclick=()=>openMetric(b.dataset.detail));
    }
    function sqlPanel(sql){return `<pre class="production-sql"><code>${sqlToHtml(sql)}</code></pre>`}
    function sourceButton(stage,line,label='查看线上 SQL'){return `<button class="source-link" data-source-stage="${stage}" data-source-line="${line}">${esc(label)} · 第 ${line-production.stages[stage].line+1} 行</button>`}
    function bindProduction(root){
      $$('[data-source-stage]',root).forEach(b=>b.onclick=()=>openProductionSql(+b.dataset.sourceStage,+b.dataset.sourceLine));
      $$('[data-prod-field]',root).forEach(b=>b.onclick=()=>{
        if($('#metricDialog').open)$('#metricDialog').close();
        state.selectedField=b.dataset.prodField;$('#fieldGrain').value=b.dataset.prodGrain||'task';$('#fieldSearch').value='';$('#fieldFamily').value='';showPage('lineage');showFieldTab();renderFields();
      });
    }
    function openProductionSql(stage,line){
      const item=production.stages[stage];$('#infoDialogTitle').textContent=`${item.label} · 线上加工 SQL`;
      $('#infoDialogBody').innerHTML=`<p class="source-caption">${esc(item.table.split('.').pop())}.sql · 独立表加工 SQL</p><code class="source-table-name">${esc(item.table)}</code><a class="source-link" href="assets/metric-center/sql/${encodeURIComponent(item.table.split('.').pop())}.sql" download>下载本表 SQL</a><pre class="production-sql numbered-sql"><code>${item.sql.split('\n').map((row,i)=>`<span class="source-code-line ${item.line+i===line?'source-highlight':''}" data-line="${item.line+i}"><i>${i+1}</i>${esc(row)||' '}</span>`).join('')}</code></pre>`;
      $('#infoDialog').showModal();requestAnimationFrame(()=>$('.source-highlight',$('#infoDialogBody'))?.scrollIntoView({block:'center'}));
    }
    function openMetric(id){
      const m=metricById(id),stage=m.grain==='seq'?1:0,grain=m.grain==='seq'?'seq':'task',used=metricSourceFields(m);state.currentMetric=id;
      const relevant=used.length?used:['seqid','parentid','download_url','peerid','platform','action_type'];
      $('#metricDialogTitle').textContent=m.cn;$('#metricDialogSub').textContent=`${m.id} · ${m.unit}`;
      $('#metricDialogBody').innerHTML=`<div class="metric-detail-lead">${esc(metricSummary(m))}</div>
        <div class="metric-detail-tabs" role="tablist" aria-label="指标详情"><button role="tab" aria-selected="true" aria-controls="metric-tab-definition" id="metric-tab-button-definition" data-metric-tab="definition" class="active">口径说明</button><button role="tab" aria-selected="false" aria-controls="metric-tab-sql" id="metric-tab-button-sql" data-metric-tab="sql">计算 SQL</button><button role="tab" aria-selected="false" aria-controls="metric-tab-source" id="metric-tab-button-source" data-metric-tab="source">来源与血缘</button></div>
        <section id="metric-tab-definition" role="tabpanel" aria-labelledby="metric-tab-button-definition" data-metric-panel="definition">
          <div class="metric-explanation"><h3>如何计算</h3><p>${esc(metricNotes[m.id][1])}</p>${m.ratio?'<p>分母为 0 返回 NULL；SQL 返回小数比例，百分比展示时乘以 100。</p>':''}${m.grain==='user'?"<p>peerid 的 NULL 在子任务层转为 N/A，计数时会作为一个去重值。</p>":''}</div>
          <div class="metric-explanation"><h3>数据范围</h3><p>${esc(productionScope)}</p><p>线上 DWS 加工与当前自助取数均不限制 1TB；使用时应保持分子、分母的日期和业务筛选一致。</p></div>
          <div class="source-note">依据：血缘更新.sql。字段加工来自线上原文；指标聚合沿用当前指标定义，源文件不含最终 ADS 聚合。</div>
        </section>
        <section id="metric-tab-sql" role="tabpanel" aria-labelledby="metric-tab-button-sql" data-metric-panel="sql" hidden><p class="source-caption">单日期基础查询，可替换日期并追加业务条件。</p><button class="btn small" id="copyMetricSql">复制 SQL</button>${sqlPanel(metricCalculationSql(m))}</section>
        <section id="metric-tab-source" role="tabpanel" aria-labelledby="metric-tab-button-source" data-metric-panel="source" hidden><h3>直接来源</h3><code class="source-table-name">${esc(m.sourceTable)}</code>${sourceButton(stage,production.stages[stage].line,'查看完整加工 SQL')}<h3>字段加工与上游</h3><div class="metric-source-fields">${relevant.map(f=>{const col=productionQueries[stage===1?'1:0':'0:0'].columns[f];return col?`<div class="metric-source-field"><button class="source-link" data-prod-field="${f}" data-prod-grain="${grain}">${esc(f)} → 字段血缘</button>${sqlPanel(col.expression)}${sourceButton(stage,col.line)}</div>`:''}).join('')}</div></section>`;
      $$('[data-metric-tab]',$('#metricDialogBody')).forEach(b=>b.onclick=()=>{
        $$('[data-metric-tab]',$('#metricDialogBody')).forEach(x=>{x.classList.toggle('active',x===b);x.setAttribute('aria-selected',String(x===b))});
        $$('[data-metric-panel]',$('#metricDialogBody')).forEach(x=>x.hidden=x.dataset.metricPanel!==b.dataset.metricTab);
      });
      $('#copyMetricSql').onclick=async()=>{try{await navigator.clipboard.writeText(metricCalculationSql(m));$('#copyMetricSql').textContent='已复制'}catch{$('#copyMetricSql').textContent='请选中下方 SQL 复制'}};
      bindProduction($('#metricDialogBody'));$('#metricDialog').showModal();
    }
    const fieldNames={peerid:'传输用户标识',parentid:'主任务 ID',gcid:'资源 GCID',download_url:'下载 URL',seqid:'分片 ID',user_id:'用户 ID',guid:'设备 ID',is_c_type:'是否 C 类',vip_type:'会员类型',server_room:'采集机房',carrier:'运营商',province:'省份',country:'国家',city:'城市',country_name:'国家名占位列',global_speed:'实跑速度',global_speed_target:'目标配速',global_speed_max_in_window:'窗口最大速度',recv_bytes:'接收量',seq_zero_speed:'零速标记',seq_fail:'失败标记',ts:'记录时间',download_time:'下载时长',eventstatus:'任务状态',task_type:'任务类型',phub_bytes:'Phub 流量',tracker_bytes:'Tracker 流量',all_bytes:'总流量',origin_bytes:'原始资源流量',server_bytes:'镜像流量',dcdn_bytes:'DCDN 流量',pcdn_bytes:'PCDN 流量',bonus_bytes:'Bonus 流量',target_speed_range:'目标配速区间',final_result:'下载结果',platform:'平台',action_type:'行为',ds:'日期',is_collect:'是否采集',is_hfk:'黄反库标记',phub_res_peer:'Phub 资源 Peer 数',file_size:'文件大小',is_file_size_over_10mb:'文件是否 ≥ 10MB'};
    function fieldFamily(id){return /bytes$/.test(id)?'流量':/speed|time|ending_span|buffer_fail/.test(id)?'速度质量':/result|fail|error|country|province|city|carrier/.test(id)?'结果地域':/peerid|parentid|seqid|user_id|guid|platform|action_type|^ds$/.test(id)?'标识行为':/vip|is_c|collect|hfk|gcid|resource|phub_res/.test(id)?'资源用户':'任务属性'}
    function fieldRule(col){
      if(!col)return '该层未输出';const e=col.body.toLowerCase();
      if(e.includes('sum(if(seq_zero_speed'))return '全部分片零速';
      if(e.includes('max_by'))return '按时间取末条';if(e.includes('min_by'))return '按时间取首条';
      if(e.includes('avg('))return '非零值取平均';if(e.includes('sum('))return '分片求和';if(e.includes('max('))return '取最大值';
      if(e.includes('/ 1024'))return '÷ 1024，空值补 0';if(e.includes('coalesce'))return '空值处理';
      if(e.includes('case')||e.includes('if('))return '条件派生';if(e.includes('null')||/^'/.test(e))return '固定值';
      if(/^[\w.]+$/.test(e))return '直接传递';return '表达式加工';
    }
    function productionField(id){const schema=production.stages[0].schema[id]||production.stages[1].schema[id]||{};return {id,cn:fieldNames[id]||schema.comment?.replace(/【[^】]*】/g,'').split(/[，,；;（(]/)[0]||id,comment:schema.comment||'SQL SELECT 输出列',type:schema.type||'未在 DDL 注释中声明',family:fieldFamily(id)}}
    function fieldTrace(id,grain){
      const visited=new Set(),nodes=[],external=[];
      function visit(qid,field){const key=qid+'.'+field;if(visited.has(key))return;visited.add(key);
        const query=productionQueries[qid];if(!query){external.push({table:qid,field});return}
        const col=query.columns[field];if(!col)return;
        nodes.push({query:qid,stage:query.stage,field,...col});col.refs.forEach(r=>visit(r.query,r.field));
      }
      visit(grain==='seq'?'1:0':'0:0',id);return {nodes,external};
    }
    function renderFields(){
      const q=$('#fieldSearch').value.trim().toLowerCase(),fam=$('#fieldFamily').value,grain=$('#fieldGrain').value,root=productionQueries[grain==='seq'?'1:0':'0:0'];
      const list=Object.keys(root.columns).map(productionField).filter(f=>(!fam||f.family===fam)&&(!q||`${f.id} ${f.cn} ${f.comment} ${JSON.stringify(fieldTrace(f.id,grain))}`.toLowerCase().includes(q)));
      if(!list.some(f=>f.id===state.selectedField))state.selectedField=list[0]?.id||'';
      $('#fieldRows').innerHTML=list.length?list.map(f=>`<tr class="${f.id===state.selectedField?'selected-field':''}"><td><button class="field-select" data-field="${f.id}" aria-pressed="${f.id===state.selectedField}"><strong>${esc(f.cn)}</strong><code>${esc(f.id)}</code></button></td><td>${esc(fieldRule(root.columns[f.id]))}</td></tr>`).join(''):'<tr><td colspan="2" class="metric-empty">没有匹配字段</td></tr>';
      $('#fieldResultCount').textContent=`${list.length} 个字段`;
      $$('[data-field]',$('#fieldRows')).forEach(b=>b.onclick=()=>{state.selectedField=b.dataset.field;renderFields()});renderFieldDetail();
      const selected=$('.selected-field',$('#fieldRows')),pane=$('#fieldLineage .field-list');if(selected&&pane){const y=selected.offsetTop;if(y<pane.scrollTop||y+selected.offsetHeight>pane.scrollTop+pane.clientHeight)pane.scrollTop=Math.max(0,y-pane.clientHeight/2)}
    }
    function renderFieldDetail(){
      const id=state.selectedField,grain=$('#fieldGrain').value;
      if(!id){$('#fieldDetailPanel').innerHTML='<p class="source-caption">请选择或搜索字段。</p>';return}
      const f=productionField(id),trace=fieldTrace(id,grain),root=productionQueries[grain==='seq'?'1:0':'0:0'].columns[id];
      const used=metrics.filter(m=>metricSourceFields(m).includes(id));
      const steps=[...new Set(trace.nodes.map(n=>n.stage))].sort((a,b)=>b-a);
      $('#fieldDetailPanel').innerHTML=`<div class="field-detail-heading"><div><h2>${esc(f.cn)}</h2><code>${esc(id)}</code></div><span class="tag">${grain==='seq'?'分片':'子任务'} DWS</span></div><p class="source-caption">${esc(f.comment)} · 类型注释：${esc(f.type)}</p>
        <h3>当前层加工</h3>${sqlPanel(root.expression)}${sourceButton(grain==='seq'?1:0,root.line)}
        <h3>字段血缘 <small>从原始来源到当前层</small></h3>
        <div class="production-origin">${trace.external.length?trace.external.map(x=>`<div><code>${esc(x.table)}.${esc(x.field)}</code></div>`).join(''):'由 SQL 固定值或常量生成，无直接原始字段。'}</div>
        <div class="production-chain">${steps.map(stage=>{const ns=trace.nodes.filter(n=>n.stage===stage).sort((a,b)=>a.line-b.line),item=production.stages[stage];return `<details class="production-step" ${stage<2?'open':''}><summary><span>${item.label}</span><small>${ns.length} 项相关表达式</small></summary><code class="source-table-name">${esc(item.table)}</code>${ns.map(n=>`<div class="production-expression"><b>${esc(n.field)}</b>${sqlPanel(n.expression)}${sourceButton(stage,n.line)}<p class="source-caption">输入：${n.refs.map(r=>esc(r.field)).join('、')||'固定值 / 常量'}</p></div>`).join('')}</details>`}).join('')}</div>
        <details class="field-context"><summary>过滤、去重与关联条件</summary><p>${esc(productionScope)}</p><p>关联字段的匹配键、维表筛选与 SQL 上下文可在各层完整 SQL 中查看；上方链路展示字段值的直接依赖。</p>${steps.map(stage=>sourceButton(stage,production.stages[stage].line,production.stages[stage].label)).join('')}</details>
        <h3>直接用于指标</h3><div class="field-used-metrics">${used.map(m=>`<button class="source-link" data-metric-link="${m.id}">${esc(m.cn)}</button>`).join('')||'<span class="source-caption">当前指标未直接引用，可用于维度、筛选或上游加工。</span>'}</div>`;
      bindProduction($('#fieldDetailPanel'));bindCrossLinks($('#fieldDetailPanel'));$('#fieldDetailPanel').scrollTop=0;
    }
    function renderLogic(){
      const q=$('#logicSearch').value.trim().toLowerCase();
      $('#tableLogicGrid').innerHTML=production.stages.filter(s=>!q||`${s.table} ${s.label} ${s.sql}`.toLowerCase().includes(q)).slice().reverse().map(s=>`<article class="card table-logic-card"><div class="table-logic-head"><h2>${s.label}</h2><code>${esc(s.table)}</code></div><div class="table-logic-body">${sourceButton(s.id,s.line,'展开线上完整 SQL')}<p class="source-caption">${esc(s.table.split('.').pop())}.sql · ${s.sql.split('\n').length} 行 SQL 原文</p></div></article>`).join('')||'<p>没有找到匹配的加工 SQL。</p>';
      $('#logicGrid').innerHTML='';bindProduction($('#tableLogicGrid'));
    }
