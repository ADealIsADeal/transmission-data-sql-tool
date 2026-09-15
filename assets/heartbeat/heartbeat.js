    // Heartbeat uses its own catalog, selections, search and event bindings.
    const heartbeat=JSON.parse(document.getElementById('heartbeatCatalog').textContent);
    const hbQueries=Object.fromEntries(heartbeat.queries.map(q=>[q.id,q]));
    const hbStages=Object.fromEntries(heartbeat.stages.map(s=>[s.id,s]));
    const hbState={tab:'table',table:heartbeat.stages.find(s=>s.layer==='DWD'&&s.direction==='download').id,field:'dcdn_download_bytes'};
    hbState.fieldTable=hbState.table;
    const hbTables=heartbeat.stages.map(s=>({...s,cn:s.label,name:s.table,type:s.layer.toLowerCase(),layer:['PRE','ODS','DWD','DWS','ADS'].indexOf(s.layer),grain:s.layer==='ODS'?'上报事件':s.layer==='DWD'?'去重上报':s.layer==='DWS'?(s.direction==='download'?'任务 × 5 分钟 × 流量类别':'用户 × 5 分钟 × 流量类别'):'业务维度 × 5 分钟',frequency:'每日',up:s.upstream.map(t=>t.split('.').pop()),down:heartbeat.stages.filter(x=>x.upstream.includes(s.table)).map(x=>x.id)}));
    const hbRawName=heartbeat.stages.find(s=>s.layer==='ODS').upstream[0];
    hbTables.unshift({id:hbRawName.split('.').pop(),name:hbRawName,cn:'心跳原始事件日志',type:'raw',layer:0,grain:'事件上报',frequency:'小时',up:[],down:heartbeat.stages.filter(s=>s.layer==='ODS').map(s=>s.id),note:'共享原始 JSON 来源；下行事件 4660/10015，上行事件 4686/10016。当前目录未提供该表加工 SQL。'});
    const hbTableById=id=>hbTables.find(t=>t.id===id);
    const hbFieldFamily=id=>/bytes|traffic_category/.test(id)?'流量':/time|duration/.test(id)?'速度质量':/country|province|city|carrier/.test(id)?'结果地域':/vip|gcid|nat_type/.test(id)?'资源用户':/id$|seq|platform|purpose|status|^ds$/.test(id)?'标识行为':'任务属性';
    function hbFieldName(s,f){return ({task_id:'任务 ID',sub_task_id:'子任务 ID',peer_id:'节点 ID',app_seq_id:'任务 ID',traceid:'行为 ID',record_seq:'上报序号',task_purpose:'任务用途',initial_cfg_strategy_name:'启动配置策略',task_cfg_strategy_name:'任务配置策略',dcdn_download_bytes:'DCDN 流量',pcdn_peer_bytes:'PCDN 流量',origin_bytes3d:'三方原始流量',origin_bytes_xl:'迅雷原始流量',download_bytes_current:'下行流量',upload_bytes_current:'上行流量',duration_current:'周期时长',server_time_5min:'5 分钟区间',service_name:'产品名称'})[f]||fieldNames[f]||s.schema[f]?.comment?.split(/[，,；;（(]/)[0]||f}
    function hbSourceButton(stage,line=1,label='查看线上 SQL'){return `<button class="source-link" data-hb-source="${stage}" data-hb-line="${line}">${esc(label)} · 第 ${line} 行</button>`}
    function bindHeartbeat(root){
      $$('[data-hb-source]',root).forEach(b=>b.onclick=()=>{
        const s=hbStages[b.dataset.hbSource],line=+b.dataset.hbLine;
        $('#infoDialogTitle').textContent=s.label+' · 线上 SQL';
        $('#infoDialogBody').innerHTML=`<p class="source-caption">${esc(s.file)}</p><code class="source-table-name">${esc(s.table)}</code><a class="source-link" href="${s.file.split('/').map(encodeURIComponent).join('/')}" download>下载本表 SQL</a><pre class="production-sql numbered-sql"><code>${sqlToHtml(s.sql).split('\n').map((row,i)=>`<span class="source-code-line ${i+1===line?'source-highlight':''}"><i>${i+1}</i>${row||' '}</span>`).join('')}</code></pre>`;
        $('#infoDialog').showModal();requestAnimationFrame(()=>$('.source-highlight',$('#infoDialogBody'))?.scrollIntoView({block:'center'}));
      });
      $$('[data-hb-table]',root).forEach(b=>b.onclick=()=>{hbState.table=b.dataset.hbTable;if(hbStages[hbState.table]){hbState.fieldTable=hbState.table;$('#hbFieldTable').value=hbState.fieldTable;}renderHeartbeat()});
      $$('[data-hb-field]',root).forEach(b=>b.onclick=()=>{hbState.field=b.dataset.hbField;renderHeartbeatFields()});
    }
    function hbTrace(field){
      const nodes=[],external=[],visited=new Set();
      function visit(qid,f){const key=qid+'.'+f;if(visited.has(key))return;visited.add(key);
        const q=hbQueries[qid];if(!q){external.push({table:qid,field:f});return}
        const c=q.columns[f];if(!c)return;
        nodes.push({stage:q.stage,field:f,...c});c.refs.forEach(r=>visit(r.query,r.field));
      }
      visit(hbStages[hbState.fieldTable].queries[0],field);return {nodes,external};
    }
    function renderHeartbeat(){
      const selected=hbTableById(hbState.table),search=$('#hbTableSearch').value.trim().toLowerCase(),direction=$('#hbDirection').value,depth=+$('#hbDepth').value;
      let allowed=new Set(hbTables.map(t=>t.id));
      if(direction!=='all'){allowed=new Set([selected.id]);let frontier=[selected.id];for(let i=0;i<depth;i++){frontier=[...new Set(frontier.flatMap(id=>hbTableById(id)[direction==='up'?'up':'down']))];frontier.forEach(id=>allowed.add(id))}}
      const list=hbTables.filter(t=>allowed.has(t.id)),layers=[...new Set(list.map(t=>t.layer))].sort((a,b)=>a-b),titles=['原始日志','上报明细','心跳去重','主题聚合','看板应用'];
      const node=t=>`<button class="graph-node ${t.id===selected.id?'active':''}" style="--node:${typeColor[t.type]||'#64748b'};${search&&`${t.cn} ${t.name}`.toLowerCase().includes(search)?'box-shadow:0 0 0 4px #fbbf24;':''}" data-hb-table="${t.id}"><span class="tag">${t.type.toUpperCase()}</span><strong>${esc(t.cn)}</strong><code>${esc(t.name.split('.').pop())}</code><small>${esc(t.grain)} · ${t.frequency}</small></button>`;
      $('#hbGraph').innerHTML=`<div class="lineage-flow-grid" style="grid-template-columns:repeat(${Math.max(0,layers.length-1)},minmax(160px,1fr) 34px) minmax(160px,1fr);min-width:${layers.length*160+Math.max(0,layers.length-1)*34}px">${layers.map((layer,i)=>`<div class="lineage-main-title" style="grid-column:${i*2+1}">${titles[layer]}</div><div class="lineage-main-layer" style="grid-column:${i*2+1}">${list.filter(t=>t.layer===layer).map(node).join('')}</div>${i?`<div class="lineage-main-arrow" style="grid-column:${i*2}">→</div>`:''}`).join('')}</div>`;
      const stage=hbStages[selected.id],related=ids=>ids.length?ids.map(id=>{const t=hbTableById(id),hasSql=!!hbStages[id];return `<button class="table-related" ${hasSql?`data-hb-source="${id}" data-hb-line="1" aria-label="查看${esc(t.cn)}线上 SQL"`:'disabled'}><strong>${esc(t.cn)}</strong><code>${esc(t.name.split('.').pop())}</code><small>${hasSql?'查看线上 SQL':'未提供加工 SQL'}</small></button>`}).join(''):'<p class="table-no-related">无</p>';
      $('#hbTableDetail').innerHTML=`<div class="table-detail-title"><span class="tag">${selected.type.toUpperCase()}</span><h2>${esc(selected.cn)}</h2><code>${esc(selected.name.split('.').pop())}</code></div><div class="table-current-sql">${stage?`<button class="btn" data-hb-source="${stage.id}" data-hb-line="1">查看当前表 SQL</button>`:'<span class="source-caption">当前表未提供加工 SQL</span>'}</div><p class="table-description">${esc(selected.note)}</p><dl class="table-facts"><div><dt>数据粒度</dt><dd>${esc(selected.grain)}</dd></div><div><dt>更新频率</dt><dd>${selected.frequency}</dd></div></dl><section class="table-relations"><h3>上游表 <span>${selected.up.length}</span></h3>${related(selected.up)}</section><section class="table-relations"><h3>下游表 <span>${selected.down.length}</span></h3>${related(selected.down)}</section><div class="side-links"><button class="btn small" data-hb-direction="up">仅看上游</button><button class="btn small" data-hb-direction="down">仅看下游</button></div>`;
      bindHeartbeat($('#hbTableView'));
      $$('[data-hb-direction]').forEach(b=>b.onclick=()=>{$('#hbDirection').value=b.dataset.hbDirection;renderHeartbeat()});
      renderHeartbeatFields();
    }
    function renderHeartbeatFields(){
      const s=hbStages[hbState.fieldTable],root=hbQueries[s.queries[0]],search=$('#hbFieldSearch').value.trim().toLowerCase(),family=$('#hbFieldFamily').value;
      const fields=Object.keys(root.columns).filter(f=>(!family||hbFieldFamily(f)===family)&&(!search||`${f} ${s.schema[f]?.comment||''} ${JSON.stringify(hbTrace(f))}`.toLowerCase().includes(search)));
      if(!fields.includes(hbState.field))hbState.field=fields[0]||'';
      $('#hbFieldCount').textContent=`${fields.length} 个字段`;
      $('#hbFieldRows').innerHTML=fields.map(f=>`<tr class="${f===hbState.field?'selected-field':''}"><td><button class="field-select" data-hb-field="${f}" aria-pressed="${f===hbState.field}"><strong>${esc(hbFieldName(s,f))}</strong><code>${esc(f)}</code></button></td><td>${esc(fieldRule(root.columns[f]))}</td></tr>`).join('')||'<tr><td colspan="2" class="metric-empty">没有匹配字段</td></tr>';
      const f=hbState.field;
      if(!f){$('#hbFieldDetail').innerHTML='<p class="source-caption">请选择或搜索字段。</p>';return}
      const trace=hbTrace(f),col=root.columns[f];
      $('#hbFieldDetail').innerHTML=`<div class="field-detail-heading"><div><h2>${esc(hbFieldName(s,f))}</h2><code>${esc(f)}</code></div><span class="tag">${esc(s.label)}</span></div><p class="source-caption">${esc(s.schema[f]?.comment||'SQL SELECT 输出列')} · 类型注释：${esc(s.schema[f]?.type||'未在 DDL 注释中声明')}</p><h3>当前层加工</h3>${sqlPanel(col.expression)}${hbSourceButton(s.id,col.line)}<h3>字段血缘 <small>从原始来源到当前层</small></h3><div class="production-origin">${trace.external.map(x=>`<code>${esc(x.table)}.${esc(x.field)}</code>`).join('<br>')||'由 SQL 常量或系统函数生成，无直接原始字段。'}</div><div class="production-chain">${[...new Set(trace.nodes.map(n=>n.stage))].reverse().map(id=>`<details class="production-step" ${id===s.id?'open':''}><summary><span>${esc(hbStages[id].label)}</span><small>${trace.nodes.filter(n=>n.stage===id).length} 项相关表达式</small></summary><code class="source-table-name">${esc(hbStages[id].table)}</code>${trace.nodes.filter(n=>n.stage===id).sort((a,b)=>a.line-b.line).map(n=>`<div class="production-expression"><b>${esc(n.field)}</b>${sqlPanel(n.expression)}${n.note?`<p class="source-caption">${esc(n.note)}</p>`:''}${hbSourceButton(id,n.line)}<p class="source-caption">输入：${n.refs.map(r=>esc(r.field)).join('、')||'固定值 / 常量'}</p></div>`).join('')}</details>`).join('')}</div><details class="field-context"><summary>过滤、去重与关联条件</summary><p>${esc(s.note)}</p><p>上方链路展示字段值的直接依赖；过滤和分组条件可在各层完整 SQL 中查看。</p>${[...new Set(trace.nodes.map(n=>n.stage))].map(id=>hbSourceButton(id,1,hbStages[id].label)).join('')}</details>`;
      bindHeartbeat($('#hbFieldView'));$('#hbFieldDetail').scrollTop=0;
      const selected=$('.selected-field',$('#hbFieldRows')),pane=$('#hbFieldView .field-list');if(selected&&pane){const y=selected.offsetTop;if(y<pane.scrollTop||y+selected.offsetHeight>pane.scrollTop+pane.clientHeight)pane.scrollTop=Math.max(0,y-pane.clientHeight/2)}
    }
    function setHeartbeatTab(tab){hbState.tab=tab;$$('[data-hb-tab]').forEach(b=>b.classList.toggle('active',b.dataset.hbTab===tab));$('#hbTableView').classList.toggle('hidden',tab!=='table');$('#hbFieldView').classList.toggle('hidden',tab!=='field');renderHeartbeat()}
    function initHeartbeat(){
      $('#hbFieldTable').innerHTML=heartbeat.stages.slice().sort((a,b)=>a.direction.localeCompare(b.direction)||['ODS','DWD','DWS','ADS'].indexOf(a.layer)-['ODS','DWD','DWS','ADS'].indexOf(b.layer)).map(s=>`<option value="${s.id}">${esc(s.label)}</option>`).join('');
      $('#hbFieldTable').value=hbState.fieldTable;
      $('#hbFieldTable').onchange=()=>{hbState.fieldTable=$('#hbFieldTable').value;renderHeartbeatFields()};
      ['hbTableSearch','hbDirection','hbDepth'].forEach(id=>$('#'+id).oninput=renderHeartbeat);['hbFieldSearch','hbFieldFamily'].forEach(id=>$('#'+id).oninput=renderHeartbeatFields);
      $('#hbFullscreen').onclick=()=>{const c=$('#hbCanvas');c.classList.toggle('fullscreen');$('#hbFullscreen').textContent=c.classList.contains('fullscreen')?'退出全屏':'全屏查看'};
      $$('[data-hb-tab]').forEach(b=>b.onclick=()=>setHeartbeatTab(b.dataset.hbTab));
      renderHeartbeat();
    }
