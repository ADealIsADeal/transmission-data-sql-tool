    // Heartbeat uses its own catalog, selections, search and event bindings.
    const heartbeat=JSON.parse(document.getElementById('heartbeatCatalog').textContent);
    const hbQueries=Object.fromEntries(heartbeat.queries.map(q=>[q.id,q]));
    const hbStages=Object.fromEntries(heartbeat.stages.map(s=>[s.id,s]));
    const hbState={tab:'table',table:heartbeat.stages.find(s=>s.layer==='DWD'&&s.direction==='download').id,field:'dcdn_download_bytes'};
    function hbSourceButton(stage,line=1,label='查看线上 SQL'){return `<button class="source-link" data-hb-source="${stage}" data-hb-line="${line}">${esc(label)} · 第 ${line} 行</button>`}
    function bindHeartbeat(root){
      $$('[data-hb-source]',root).forEach(b=>b.onclick=()=>{
        const s=hbStages[b.dataset.hbSource],line=+b.dataset.hbLine;
        $('#infoDialogTitle').textContent=s.label+' · 线上 SQL';
        $('#infoDialogBody').innerHTML=`<p class="source-caption">${esc(s.file)}</p><code class="source-table-name">${esc(s.table)}</code><a class="source-link" href="${s.file.split('/').map(encodeURIComponent).join('/')}" download>下载本表 SQL</a><pre class="production-sql numbered-sql"><code>${sqlToHtml(s.sql).split('\n').map((row,i)=>`<span class="source-code-line ${i+1===line?'source-highlight':''}"><i>${i+1}</i>${row||' '}</span>`).join('')}</code></pre>`;
        $('#infoDialog').showModal();requestAnimationFrame(()=>$('.source-highlight',$('#infoDialogBody'))?.scrollIntoView({block:'center'}));
      });
      $$('[data-hb-table]',root).forEach(b=>b.onclick=()=>{hbState.table=b.dataset.hbTable;$('#hbFieldTable').value=hbState.table;renderHeartbeat()});
      $$('[data-hb-field]',root).forEach(b=>b.onclick=()=>{hbState.field=b.dataset.hbField;renderHeartbeatFields()});
    }
    function hbTrace(field){
      const nodes=[],external=[],visited=new Set();
      function visit(qid,f){const key=qid+'.'+f;if(visited.has(key))return;visited.add(key);
        const q=hbQueries[qid];if(!q){external.push({table:qid,field:f});return}
        const c=q.columns[f];if(!c)return;
        nodes.push({stage:q.stage,field:f,...c});c.refs.forEach(r=>visit(r.query,r.field));
      }
      visit(hbStages[hbState.table].queries[0],field);return {nodes,external};
    }
    function renderHeartbeat(){
      const selected=hbStages[hbState.table],search=$('#hbTableSearch').value.trim().toLowerCase();
      const layers=['ODS','DWD','DWS','ADS'];
      const source=heartbeat.stages.find(s=>s.layer==='ODS').upstream[0];
      $('#hbGraph').innerHTML=`<div class="hb-origin"><span class="tag">PRE · 原始事件</span><code>${esc(source)}</code><small>共享来源，按事件名分别进入下行与上行链路 · 未提供该表加工 SQL</small></div>${['download','upload'].map(direction=>`<section class="hb-lane"><h3>${direction==='download'?'下行 · 下载任务':'上行 · 上传用户'} <small>${direction==='download'?'4660 / 10015':'4686 / 10016'}</small></h3><div class="hb-lane-nodes">${layers.map((layer,i)=>{const s=heartbeat.stages.find(x=>x.direction===direction&&x.layer===layer),match=search&&`${s.label} ${s.table}`.toLowerCase().includes(search);return `${i?'<span class="hb-arrow" aria-hidden="true">→</span>':''}<button class="graph-node ${s.id===selected.id?'active':''} ${match?'hb-match':''}" style="--node:${typeColor[layer.toLowerCase()]||'#64748b'}" data-hb-table="${s.id}"><span class="tag">${layer}</span><strong>${esc(s.label)}</strong><code>${esc(s.id)}</code><small>${Object.keys(hbQueries[s.queries[0]].columns).length} 个字段 · 每日分区</small></button>`}).join('')}</div></section>`).join('')}`;
      const upstream=selected.upstream,downstream=heartbeat.stages.filter(s=>s.upstream.includes(selected.table));
      $('#hbTableDetail').innerHTML=`<h2>${esc(selected.label)}</h2><code class="source-table-name">${esc(selected.table)}</code><p class="table-description">${esc(selected.note)}</p>${hbSourceButton(selected.id)}<h3>上游表</h3>${upstream.map(t=>{const s=heartbeat.stages.find(x=>x.table===t);return s?`<button class="table-related" data-hb-table="${s.id}"><strong>${esc(s.label)}</strong><code>${esc(t)}</code></button>`:`<p class="source-caption">${esc(t)}<br>未提供加工 SQL</p>`}).join('')}<h3>下游表</h3>${downstream.map(s=>`<button class="table-related" data-hb-table="${s.id}"><strong>${esc(s.label)}</strong><code>${esc(s.table)}</code></button>`).join('')||'<p class="source-caption">当前目录中无下游任务</p>'}<button class="btn small" id="hbExploreFields">查看本表字段血缘</button>`;
      bindHeartbeat($('#hbTableView'));
      $('#hbExploreFields').onclick=()=>setHeartbeatTab('field');
      renderHeartbeatFields();
    }
    function renderHeartbeatFields(){
      const s=hbStages[hbState.table],root=hbQueries[s.queries[0]],search=$('#hbFieldSearch').value.trim().toLowerCase();
      const fields=Object.keys(root.columns).filter(f=>!search||`${f} ${s.schema[f]?.comment||''} ${root.columns[f].expression}`.toLowerCase().includes(search));
      if(!fields.includes(hbState.field))hbState.field=fields[0]||'';
      $('#hbFieldCount').textContent=`${fields.length} 个字段`;
      $('#hbFieldRows').innerHTML=fields.map(f=>`<tr class="${f===hbState.field?'selected-field':''}"><td><button class="field-select" data-hb-field="${f}" aria-pressed="${f===hbState.field}"><strong>${esc(s.schema[f]?.comment?.split(/[，；]/)[0]||f)}</strong><code>${esc(f)}</code></button></td></tr>`).join('')||'<tr><td>没有匹配字段</td></tr>';
      const f=hbState.field;
      if(!f){$('#hbFieldDetail').innerHTML='<p class="source-caption">请选择或搜索字段。</p>';return}
      const trace=hbTrace(f),col=root.columns[f];
      $('#hbFieldDetail').innerHTML=`<h2>${esc(f)}</h2><p class="source-caption">${esc(s.schema[f]?.comment||'SQL 输出字段')} · ${esc(s.schema[f]?.type||'未声明类型')}</p><h3>当前层表达式</h3>${sqlPanel(col.expression)}${hbSourceButton(s.id,col.line)}<h3>字段血缘 <small>从原始来源到当前层</small></h3><div class="production-origin">${trace.external.map(x=>`<code>${esc(x.table)}.${esc(x.field)}</code>`).join('<br>')||'由 SQL 常量或系统函数生成，无直接原始字段。'}</div>${[...new Set(trace.nodes.map(n=>n.stage))].reverse().map(id=>`<details class="production-step" open><summary>${esc(hbStages[id].label)}</summary>${trace.nodes.filter(n=>n.stage===id).sort((a,b)=>a.line-b.line).map(n=>`<div class="production-expression"><b>${esc(n.field)}</b>${sqlPanel(n.expression)}${n.note?`<p class="source-caption">${esc(n.note)}</p>`:''}${hbSourceButton(id,n.line)}</div>`).join('')}</details>`).join('')}<p class="source-caption">血缘展示字段值的直接依赖；去重、过滤及分组条件请查看各层完整 SQL。</p>`;
      bindHeartbeat($('#hbFieldView'));
    }
    function setHeartbeatTab(tab){hbState.tab=tab;$$('[data-hb-tab]').forEach(b=>b.classList.toggle('active',b.dataset.hbTab===tab));$('#hbTableView').classList.toggle('hidden',tab!=='table');$('#hbFieldView').classList.toggle('hidden',tab!=='field');renderHeartbeat()}
    function initHeartbeat(){
      $('#hbFieldTable').innerHTML=heartbeat.stages.slice().sort((a,b)=>a.direction.localeCompare(b.direction)||['ODS','DWD','DWS','ADS'].indexOf(a.layer)-['ODS','DWD','DWS','ADS'].indexOf(b.layer)).map(s=>`<option value="${s.id}">${esc(s.label)}</option>`).join('');
      $('#hbFieldTable').value=hbState.table;
      $('#hbFieldTable').onchange=()=>{hbState.table=$('#hbFieldTable').value;renderHeartbeat()};
      $('#hbTableSearch').oninput=renderHeartbeat;$('#hbFieldSearch').oninput=renderHeartbeatFields;
      $$('[data-hb-tab]').forEach(b=>b.onclick=()=>setHeartbeatTab(b.dataset.hbTab));
      renderHeartbeat();
    }
