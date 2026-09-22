    // Whitepaper is the metric-center catalogue. The query builder retains its own schema.
    const whitepaper = JSON.parse(document.getElementById('whitepaperCatalog').textContent);
    const whitepaperReviews = {};
    let whitepaperView = 'metrics';
    function wpReview(m){return whitepaperReviews[m.name] || ''}
    function wpText(value){return value && value !== '-' ? esc(value) : '<span class="wp-muted">未填写</span>'}
    function wpLink(m){
      try {const u = new URL(m.url.trim());if(u.protocol !== 'https:')return '';}
      catch {return '';}
      return `<a class="wp-dashboard" href="${esc(m.url.trim())}" target="_blank" rel="noopener noreferrer">${esc(m.dashboard.trim())} ↗</a>`;
    }
    function wpGrain(m){return m.name.includes('用户') || m.name === '速度达标率' ? 'user' : m.name.includes('分片') || m.table.includes('seqid') ? 'seq' : 'task'}
    function wpGroupLabel(m){return {seq:'分片',task:'子任务',user:'用户'}[wpGrain(m)]}
    function wpTabButton(view,label){return `<button class="wp-view ${whitepaperView===view?'active':''}" data-wp-view="${view}" aria-pressed="${whitepaperView===view}">${label}</button>`}
    function wpInit(){
      const root = $('#page-metrics');
      root.innerHTML = `<div class="hero wp-hero"><div><div class="wp-eyebrow">传输中台 · 数据资产</div><h1>指标中心</h1><p>查口径、找看板，追溯每个指标的取数依据。</p></div><span class="wp-edition">任务结束上报</span></div>
        <div class="wp-stats"><div><strong>${whitepaper.metrics.length}</strong><span>指标</span></div><div><strong>${new Set(whitepaper.metrics.map(m=>m.category)).size}</strong><span>业务分类</span></div><div><strong>${new Set(whitepaper.metrics.filter(m=>m.bi==='✅').map(m=>m.dashboard.trim())).size}</strong><span>关联看板</span></div><div><strong>${whitepaper.dimensions.length}</strong><span>维度</span></div></div>
        <div class="wp-layout"><aside class="card wp-sidebar"><h2>业务分类</h2><nav id="wpCategories" aria-label="业务分类"></nav></aside>
        <div class="wp-main"><div id="wpViews" class="wp-views"></div>
        <div class="card toolbar wp-toolbar"><input id="metricSearch" type="search" aria-label="搜索指标或维度" placeholder="搜索指标、口径、来源字段或 SQL">
        <select id="metricCategory" aria-label="业务分类" hidden><option value="">全部业务分类</option>${[...new Set(whitepaper.metrics.map(m=>m.category))].map(c=>`<option>${esc(c)}</option>`).join('')}</select>
        <select id="metricGrain" aria-label="统计对象"><option value="">全部统计对象</option><option value="seq">分片</option><option value="task">子任务</option><option value="user">用户</option></select>
        <select id="wpDashboard" aria-label="关联看板"><option value="">全部看板</option><option value="none">未纳入看板</option>${[...new Set(whitepaper.metrics.filter(m=>m.bi==='✅').map(m=>m.dashboard.trim()))].map(d=>`<option>${esc(d)}</option>`).join('')}</select>
        <select id="wpTable" aria-label="来源表"><option value="">全部来源表</option>${[...new Set(whitepaper.metrics.map(m=>m.table))].map(t=>`<option value="${esc(t)}">${t.includes('dispatch')?'调度表':t.includes('sub_task')?'子任务表':'分片表'}</option>`).join('')}</select>
        <button class="btn small" id="wpReset">重置</button></div>
        <div class="wp-results"><span id="metricResultCount" aria-live="polite"></span><label id="wpReviewLabel"><input type="checkbox" id="wpReviewOnly"> 仅看待核对项 <span>${whitepaper.metrics.filter(wpReview).length}</span></label></div>
        <div class="card metric-table-wrap" id="metricRows"></div><p class="wp-footer">SQL 日期使用 &#36;{date} 占位符，格式为 yyyyMMdd。</p></div></div>`;
      ['metricSearch','metricCategory','metricGrain','wpDashboard','wpTable','wpReviewOnly'].forEach(id=>$('#'+id).addEventListener('input',renderMetrics));
      $('#wpReset').onclick=()=>{['metricSearch','metricCategory','metricGrain','wpDashboard','wpTable'].forEach(id=>$('#'+id).value='');$('#wpReviewOnly').checked=false;renderMetrics()};
    }
    function renderMetrics(){
      if(!$('#wpCategories'))wpInit();
      const q=$('#metricSearch').value.trim().toLowerCase(), category=$('#metricCategory').value;
      $('#wpViews').innerHTML=wpTabButton('metrics','指标目录')+wpTabButton('dimensions','维度字典');
      $$('[data-wp-view]').forEach(b=>b.onclick=()=>{whitepaperView=b.dataset.wpView;renderMetrics()});
      const isMetric=whitepaperView==='metrics';
      $('#wpCategories').innerHTML=['',...new Set(whitepaper.metrics.map(m=>m.category))].map(c=>`<button data-wp-category="${esc(c)}" class="${c===category&&isMetric?'active':''}" aria-pressed="${c===category&&isMetric}"><span>${esc(c||'全部指标')}</span><span>${whitepaper.metrics.filter(m=>!c||m.category===c).length}</span></button>`).join('');
      $$('[data-wp-category]').forEach(b=>b.onclick=()=>{whitepaperView='metrics';$('#metricCategory').value=b.dataset.wpCategory;renderMetrics()});
      ['metricGrain','wpDashboard','wpTable','wpReviewLabel'].forEach(id=>$('#'+id).hidden=!isMetric);
      const matches=m=>!q||Object.entries(m).filter(([k])=>!['cells','row','id'].includes(k)).map(([,v])=>v).join(' ').toLowerCase().includes(q);
      const list=isMetric?whitepaper.metrics.filter(m=>matches(m)&&(!category||m.category===category)&&(!$('#metricGrain').value||wpGrain(m)===$('#metricGrain').value)&&(!$('#wpTable').value||m.table===$('#wpTable').value)&&(!$('#wpReviewOnly').checked||wpReview(m))&&(!$('#wpDashboard').value||($('#wpDashboard').value==='none'?m.bi!=='✅':m.bi==='✅'&&m.dashboard.trim()===$('#wpDashboard').value))):whitepaper.dimensions.filter(matches);
      $('#metricResultCount').textContent=isMetric?`${category||'全部指标'} · ${list.length} / ${whitepaper.metrics.length} 项`:`维度字典 · ${list.length} / ${whitepaper.dimensions.length} 项`;
      $('#metricRows').innerHTML=isMetric?`<table class="wp-table"><thead><tr><th>指标名称 / 分类</th><th>指标口径</th><th>关联看板</th><th>详情</th></tr></thead><tbody>${list.map(m=>`<tr><th scope="row"><button class="metric-name-link" data-wp-detail="${m.id}">${esc(m.name)}</button><div class="wp-meta"><span>${esc(m.category)}</span><span>${wpGroupLabel(m)}</span>${wpReview(m)?'<span class="wp-review-tag">待核对</span>':''}</div></th><td class="wp-definition">${esc(m.definition)}</td><td>${m.bi==='✅'?wpLink(m)||wpText(m.dashboard):'<span class="wp-muted">未纳入看板</span>'}</td><td><button class="wp-open" data-wp-detail="${m.id}" aria-label="查看${esc(m.name)}详情">查看 ↗</button></td></tr>`).join('')}</tbody></table>`:`<table class="wp-table wp-dimensions"><thead><tr><th>维度 / 字段名</th><th>维度说明</th><th>可选值 / 枚举</th><th>详情</th></tr></thead><tbody>${list.map(d=>`<tr><th scope="row"><button class="metric-name-link" data-wp-dimension="${d.row}">${esc(d.name)}</button><code>${esc(d.field)}</code></th><td>${wpText(d.definition)}</td><td>${wpText(d.values)}</td><td><button class="wp-open" data-wp-dimension="${d.row}" aria-label="查看${esc(d.name)}维度">查看 ↗</button></td></tr>`).join('')}</tbody></table>`;
      if(!list.length)$('#metricRows').innerHTML='<div class="wp-empty"><h3>没有找到匹配项</h3><p>试试其他关键词，或点击重置清除筛选条件。</p></div>';
      $$('[data-wp-detail]').forEach(b=>b.onclick=()=>openMetric(b.dataset.wpDetail));
      $$('[data-wp-dimension]').forEach(b=>b.onclick=()=>wpOpenDimension(+b.dataset.wpDimension));
    }
    function wpDefinition(label,value){return `<div class="wp-detail-item"><dt>${label}</dt><dd>${wpText(value)}</dd></div>`}
    function wpBindCopy(sql){const button=$('#wpCopySql');if(button)button.onclick=async()=>{try{await navigator.clipboard.writeText(sql);button.textContent='已复制'}catch{button.textContent='复制失败，请选择下方 SQL 复制'}}}
    function openMetric(id){
      const m=whitepaper.metrics.find(x=>x.id===id);
      if(!m){openLegacyMetric(id);return}
      $('#metricDialogTitle').textContent=m.name;
      $('#metricDialogSub').textContent=`${m.category} · ${wpGroupLabel(m)} · ${m.report||'任务结束上报'}`;
      const review=wpReview(m),stage=production.stages.find(s=>s.table===m.table);
      const fieldNames=stage?Object.keys(productionQueries[`${stage.id}:0`].columns):[];
      const sqlBody=m.sql.replace(/--[^\n]*/g,'').replace(/'(?:''|[^'])*'/g,"''");
      const fields=fieldNames.filter(f=>new RegExp('\\b'+f+'\\b','i').test(sqlBody));
      $('#metricDialogBody').innerHTML=`<div class="wp-compact-detail">
        <div class="wp-detail-overview"><div><span class="metric-summary-label">指标口径</span><p>${esc(m.definition)}</p></div><div class="wp-detail-board"><span class="metric-summary-label">关联看板</span>${m.bi==='✅'?wpLink(m)||wpText(m.dashboard):'<span class="wp-muted">未纳入看板</span>'}</div></div>
        ${review?`<div class="wp-review"><b>待核对</b><p>${esc(review)}</p></div>`:''}
        <div class="wp-detail-source"><div class="wp-source-heading"><span class="metric-summary-label">来源表</span>${stage?`<button class="source-link" data-source-stage="${stage.id}" data-source-line="1">查看加工 SQL ↗</button>`:'<span class="wp-muted">加工 SQL 暂未接入</span>'}</div><code class="source-table-name">${esc(m.table)}</code><dl class="wp-detail-grid">${wpDefinition('PC 来源字段',m.pc)}${wpDefinition('移动端来源字段',m.mobile)}</dl>${fields.length?`<div class="wp-inline-fields"><span>字段血缘</span>${fields.map(f=>`<button class="source-link" data-prod-field="${f}" data-prod-grain="${stage.id===1?'seq':'task'}">${esc(f)} ↗</button>`).join('')}</div>`:''}</div>
        <div class="wp-detail-query"><div class="metric-sql-heading"><div><h3>取数 SQL</h3><span class="source-caption">&#36;{date}：yyyyMMdd</span></div><button class="btn small" id="wpCopySql">复制 SQL</button></div>${sqlPanel(m.sql)}</div></div>`;
      wpBindCopy(m.sql);bindProduction($('#metricDialogBody'));
      if(!$('#metricDialog').open)$('#metricDialog').showModal();
    }
    function wpOpenDimension(row){
      const d=whitepaper.dimensions.find(x=>x.row===row);
      $('#metricDialogTitle').textContent=d.name;$('#metricDialogSub').textContent=`维度字典 · ${d.field}`;
      $('#metricDialogBody').innerHTML=`<div class="wp-compact-detail"><dl class="wp-detail-grid">${[['适用范围','scope'],['维度说明 / 口径','definition'],['可选值 / 枚举','values'],['PC 来源字段','pc'],['移动端来源字段','mobile']].filter(([,key])=>d[key]).map(([label,key])=>wpDefinition(label,d[key])).join('')}</dl><div class="wp-detail-query"><div class="metric-sql-heading"><h3>常用加工 SQL</h3>${d.sql?'<button class="btn small" id="wpCopySql">复制 SQL</button>':''}</div>${d.sql?sqlPanel(d.sql):'<p class="source-caption">该维度暂无加工 SQL。</p>'}</div></div>`;
      wpBindCopy(d.sql);$('#metricDialog').showModal();
    }
