Push-Location 'D:\软件\Zcode工作区\product-radar'

# Read original platform.html
$lines = [System.IO.File]::ReadAllLines('output\platform.html', [System.Text.Encoding]::UTF8)
$content = $lines -join "`n"
Write-Host "Original: $($lines.Count) lines"

# ===== 1. Add Festival CSS before </style> =====
$festCSS = @'

/* ===== FESTIVAL PLANNER ===== */
.fp-header h2{font-size:22px;font-weight:700;display:flex;align-items:center;gap:8px}
.fp-header small{font-size:12px;color:var(--muted);font-weight:400}
.fp-countdown{font-size:14px;color:var(--muted);margin-bottom:8px;padding:12px 16px;background:var(--card);border-radius:var(--r);box-shadow:var(--shadow)}
.fp-countdown strong{color:var(--text);font-size:16px}
.fp-stats{display:grid;grid-template-columns:repeat(4,1fr);gap:10px;margin-bottom:12px}
.fp-stat{background:var(--card);border-radius:12px;padding:12px;box-shadow:var(--shadow);cursor:pointer;border-left:4px solid var(--border);transition:all .15s}
.fp-stat:hover{box-shadow:0 4px 16px rgba(0,0,0,.12);transform:translateY(-1px)}
.fp-stat.active{background:#eff6ff}
.fp-stat .num{font-size:24px;font-weight:700}.fp-stat .lbl{font-size:11px;color:var(--muted)}
.fp-stat.urgent{border-left-color:var(--red)}.fp-stat.urgent .num{color:var(--red)}
.fp-stat.week{border-left-color:var(--orange)}.fp-stat.week .num{color:var(--orange)}
.fp-stat.month{border-left-color:#eab308}.fp-stat.month .num{color:#eab308}
.fp-stat.plan{border-left-color:var(--green)}.fp-stat.plan .num{color:var(--green)}
.fp-filters{display:flex;gap:10px;flex-wrap:wrap;align-items:center;margin-bottom:16px;padding:10px 16px;background:var(--card);border-radius:var(--r);box-shadow:var(--shadow)}
.fp-filters label{font-size:12px;color:var(--muted)}
.fp-filters select,.fp-filters input[type="text"]{padding:5px 10px;border:1px solid var(--border);border-radius:6px;font-size:13px;background:#fff}
.fp-filters input[type="text"]{min-width:160px}
.fp-filters button{padding:5px 12px;border:1px solid var(--border);border-radius:6px;background:var(--card);cursor:pointer;font-size:12px}
.fp-month-nav{display:flex;gap:4px;flex-wrap:wrap;margin-bottom:16px}
.fp-month-nav a{padding:4px 10px;border-radius:6px;text-decoration:none;color:var(--muted);font-size:13px;transition:all .15s}
.fp-month-nav a:hover{background:#f0f0f5;color:var(--purple)}
.fp-section{margin-bottom:24px}
.fp-section h2{font-size:18px;font-weight:700;margin-bottom:12px;padding-bottom:8px;border-bottom:2px solid var(--border)}
.fp-section .cnt{font-size:13px;color:var(--muted);font-weight:400;margin-left:8px}
.fp-cards{display:flex;flex-direction:column;gap:12px}
.fp-card{background:var(--card);border-radius:var(--r);box-shadow:var(--shadow);overflow:hidden;border-left:4px solid var(--orange);transition:all .2s}
.fp-card:hover{box-shadow:0 4px 20px rgba(0,0,0,.12)}
.fp-card.urgent{border-left-color:var(--red)}.fp-card.week{border-left-color:var(--orange)}.fp-card.month{border-left-color:#eab308}.fp-card.plan{border-left-color:var(--green)}.fp-card.past{border-left-color:#8e8e93;opacity:.7}
.fp-hd{padding:14px 18px;cursor:pointer;display:flex;align-items:center;gap:12px;transition:background .15s}
.fp-hd:hover{background:#f8f8fa}
.fp-icon{font-size:28px;flex-shrink:0}
.fp-info{flex:1;min-width:0}
.fp-name{font-size:16px;font-weight:700}.fp-name-en{font-size:11px;color:var(--muted)}
.fp-meta{display:flex;gap:8px;margin-top:4px;flex-wrap:wrap;align-items:center}
.fp-badge{padding:2px 8px;border-radius:6px;font-size:11px;font-weight:700}
.fp-badge.s{background:#FF2D5515;color:var(--red)}.fp-badge.a{background:#FF950015;color:var(--orange)}.fp-badge.b{background:#007AFF15;color:var(--blue)}
.fp-urgency{padding:3px 10px;border-radius:8px;font-size:12px;font-weight:700;flex-shrink:0}
.fp-urgency.urgent{background:var(--red);color:#fff}.fp-urgency.week{background:var(--orange);color:#fff}.fp-urgency.month{background:#eab308;color:#fff}.fp-urgency.plan{background:var(--green);color:#fff}.fp-urgency.past{background:#8e8e93;color:#fff}
.fp-arrow{font-size:18px;color:var(--muted);transition:transform .2s;flex-shrink:0}
.fp-card.open .fp-arrow{transform:rotate(90deg)}
.fp-detail{display:none;padding:0 18px 14px}
.fp-card.open .fp-detail{display:block}
.fp-logistics{display:flex;gap:4px;margin-bottom:12px;align-items:center}
.fp-logistics label{font-size:12px;color:var(--muted);margin-right:4px}
.fp-log-btn{padding:4px 12px;border:1px solid var(--border);border-radius:6px;background:var(--card);cursor:pointer;font-size:12px}
.fp-log-btn.active{background:var(--blue);color:#fff;border-color:var(--blue)}
.fp-timeline{display:flex;gap:0;align-items:flex-start;margin-bottom:14px;padding:12px 0;overflow-x:auto}
.fp-tl-item{display:flex;flex-direction:column;align-items:center;gap:4px;flex:1;min-width:80px;position:relative}
.fp-tl-item::after{content:'';position:absolute;top:10px;left:50%;width:100%;height:2px;background:var(--border);z-index:0}
.fp-tl-item:last-child::after{display:none}
.fp-tl-dot{width:20px;height:20px;border-radius:50%;background:var(--border);border:3px solid #fff;box-shadow:0 0 0 2px var(--border);cursor:pointer;z-index:1;transition:all .2s}
.fp-tl-dot:hover{transform:scale(1.2)}
.fp-tl-dot.done{background:var(--green);box-shadow:0 0 0 2px var(--green)}
.fp-tl-dot.active{background:var(--orange);box-shadow:0 0 0 2px var(--orange)}
.fp-tl-name{font-size:10px;color:var(--muted);text-align:center;white-space:nowrap}
.fp-tl-date{font-size:11px;font-weight:600;color:var(--text)}
.fp-tl-actions{font-size:10px;color:var(--blue);margin-top:2px;max-width:120px;text-align:center;line-height:1.3}
.fp-status{display:flex;gap:4px;margin-bottom:10px;align-items:center;flex-wrap:wrap}
.fp-status label{font-size:12px;color:var(--muted);margin-right:4px}
.fp-st-btn{padding:3px 10px;border:1px solid var(--border);border-radius:6px;background:var(--card);cursor:pointer;font-size:11px}
.fp-st-btn.active{color:#fff}
.fp-products{margin-bottom:12px}
.fp-products h4{font-size:14px;font-weight:600;margin-bottom:8px}
.fp-tbl{width:100%;border-collapse:collapse;font-size:12px}
.fp-tbl th{text-align:left;padding:6px 8px;background:#f8f8fa;color:var(--muted);font-weight:600;border-bottom:1px solid var(--border)}
.fp-tbl td{padding:6px 8px;border-bottom:1px solid #f0f0f5;vertical-align:top}
.fp-tbl tr:hover{background:#f8f8fa}
.fp-tbl .risk-low{color:var(--green)}.fp-tbl .risk-mid{color:var(--orange)}.fp-tbl .risk-high{color:var(--red)}
.fp-tbl .stars{color:#f59e0b}
.fp-src{font-size:11px;color:var(--blue);text-decoration:none}.fp-src:hover{text-decoration:underline}
.fp-notes{width:100%;padding:6px 8px;border:1px solid var(--border);border-radius:4px;font-size:12px;min-height:40px;resize:vertical;font-family:inherit;margin-top:6px}
.fp-valid{background:#eff6ff;border-radius:8px;padding:10px;margin-bottom:10px;font-size:12px}
.fp-valid h4{font-size:12px;color:var(--blue);margin-bottom:4px}
.fp-valid ul{margin-left:16px;color:var(--muted)}
.fp-cat-filter{display:flex;gap:4px;margin-bottom:8px}
.fp-cat-filter button{padding:3px 8px;border:1px solid var(--border);border-radius:6px;background:var(--card);cursor:pointer;font-size:11px}
.fp-cat-filter button.active{background:var(--blue);color:#fff;border-color:var(--blue)}
'@

$content = $content.Replace('</style>', $festCSS + "`n" + '</style>')
Write-Host "Step 1: Added Festival CSS"

# ===== 2. Add Festival tab button =====
$content = $content.Replace(
  '<button class="main-tab" data-tab="kanban" style="--tc:var(--green)">📋 选品看板</button>',
  '<button class="main-tab" data-tab="festival" style="--tc:var(--orange)">📅 节日选品 <span class="cnt" id="fpCnt">0</span></button>' + "`n" + '  <button class="main-tab" data-tab="kanban" style="--tc:var(--green)">📋 选品看板</button>'
)
Write-Host "Step 2: Added Festival tab button"

# ===== 3. Add Festival section HTML before KANBAN =====
$festHTML = @'
<!-- FESTIVAL -->
<div class="section" id="sec-festival">
  <div style="max-width:1400px;margin:0 auto">
    <div class="fp-header"><h2>📅 节日选备货工具 <small>2026年7月 - 2027年6月</small></h2></div>
    <div id="fpCountdown" class="fp-countdown"></div>
    <div id="fpStats" class="fp-stats"></div>
    <div class="fp-filters">
      <label>品类</label><select id="fpCat"><option value="">全部</option><option value="decor">🎃装饰</option><option value="gift">🎁礼品</option><option value="apparel">👕服饰</option><option value="home">🏠家居</option></select>
      <label>月份</label><select id="fpMonth"><option value="">全部</option><option value="1">1月</option><option value="2">2月</option><option value="3">3月</option><option value="4">4月</option><option value="5">5月</option><option value="6">6月</option><option value="7">7月</option><option value="8">8月</option><option value="9">9月</option><option value="10">10月</option><option value="11">11月</option><option value="12">12月</option></select>
      <label>紧急度</label><select id="fpUrg"><option value="">全部</option><option value="urgent">🔴紧急</option><option value="week">🟠本周</option><option value="month">🟡本月</option><option value="plan">🟢规划</option><option value="past">⚫已过</option></select>
      <label>状态</label><select id="fpSt"><option value="">全部</option><option value="none">未启动</option><option value="selection">选品中</option><option value="ordered">已下单</option><option value="arrived">已到仓</option><option value="listed">已上架</option></select>
      <input type="text" id="fpSearch" placeholder="🔍 搜索节日/SKU/关键词">
      <button id="fpReset">重置</button>
    </div>
    <div id="fpMonthNav" class="fp-month-nav"></div>
    <div id="fpMain"></div>
    <div style="margin-top:20px;padding:16px;background:var(--card);border-radius:var(--r);box-shadow:var(--shadow);font-size:12px;color:var(--muted)">
      <h3 style="font-size:14px;color:var(--text);margin-bottom:8px">📌 使用说明</h3>
      <p>• 点击节日卡片标题展开详情；点击时间线圆点勾选里程碑进度。</p>
      <p>• 切换物流方式（海运/卡航/空运）会重算该节日的时间线和紧急度。</p>
      <p>• 所有进度自动保存在浏览器本地，建议定期导出备份。</p>
      <div style="background:#fffbeb;border-left:3px solid var(--orange);padding:8px 12px;margin:10px 0;border-radius:4px"><strong>⚠️ 数据免责声明：</strong>SKU建议为行业经验参考值，非实时数据。请通过 Google Trends、亚马逊BSR 验证后再决策。</div>
      <div style="background:#f0f9ff;border:1px solid #bae6fd;border-radius:8px;padding:14px;margin:12px 0">
        <h4 style="font-size:13px;color:var(--blue);margin-bottom:6px">☁️ 团队数据同步（GitHub Gist）</h4>
        <div style="display:flex;gap:8px;align-items:center;margin-bottom:6px"><label style="min-width:60px">Token</label><input type="password" id="fpToken" placeholder="ghp_xxx" style="flex:1;padding:4px 8px;border:1px solid var(--border);border-radius:4px;font-size:12px"></div>
        <div style="display:flex;gap:8px;align-items:center;margin-bottom:6px"><label style="min-width:60px">Gist ID</label><input type="text" id="fpGistId" placeholder="abc123" style="flex:1;padding:4px 8px;border:1px solid var(--border);border-radius:4px;font-size:12px"></div>
        <div style="display:flex;gap:6px;margin-top:8px;flex-wrap:wrap">
          <button onclick="fpSyncPush()" style="padding:5px 12px;background:var(--blue);color:#fff;border:1px solid var(--blue);border-radius:6px;cursor:pointer;font-size:12px">⬆️ 推送</button>
          <button onclick="fpSyncPull()" style="padding:5px 12px;background:var(--green);color:#fff;border:1px solid var(--green);border-radius:6px;cursor:pointer;font-size:12px">⬇️ 拉取</button>
          <button onclick="fpSyncCreate()" style="padding:5px 12px;border:1px solid var(--border);border-radius:6px;cursor:pointer;font-size:12px">🆕 创建Gist</button>
          <button onclick="fpSaveSync()" style="padding:5px 12px;border:1px solid var(--border);border-radius:6px;cursor:pointer;font-size:12px">💾 保存配置</button>
        </div>
        <div id="fpSyncStatus" style="margin-top:6px;font-size:12px"></div>
      </div>
      <div style="display:flex;gap:8px;margin-top:10px;flex-wrap:wrap">
        <button onclick="fpExport()" style="padding:5px 12px;border:1px solid var(--border);border-radius:6px;cursor:pointer;font-size:12px">📤 导出备份</button>
        <button onclick="document.getElementById('fpImportFile').click()" style="padding:5px 12px;border:1px solid var(--border);border-radius:6px;cursor:pointer;font-size:12px">📥 导入恢复</button>
        <input type="file" id="fpImportFile" accept=".json" style="display:none" onchange="fpImport(event)">
        <button onclick="fpExportCSV()" style="padding:5px 12px;border:1px solid var(--border);border-radius:6px;cursor:pointer;font-size:12px">📊 导出Excel</button>
        <button onclick="fpReset()" style="padding:5px 12px;border:1px solid var(--red);color:var(--red);border-radius:6px;cursor:pointer;font-size:12px">🗑 清除进度</button>
      </div>
    </div>
  </div>
</div>

'@

$content = $content.Replace('<!-- KANBAN -->', $festHTML + '<!-- KANBAN -->')
Write-Host "Step 3: Added Festival section HTML"

# ===== 4. Update renderAll to call FP_init =====
$content = $content.Replace(
  'renderDiscovery();' + "`n" + '  renderRadar();' + "`n" + '}',
  'renderDiscovery();' + "`n" + '  renderRadar();' + "`n" + '  FP_init();' + "`n" + '}'
)
Write-Host "Step 4: Updated renderAll"

# ===== 5. Add Festival JS module before </script> =====
$festJS = [System.IO.File]::ReadAllText('fest_module.js', [System.Text.Encoding]::UTF8)
$content = $content.Replace('</script>', $festJS + "`n" + '</script>')
Write-Host "Step 5: Added Festival JS module"

# Write result
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText('output\platform.html', $content, $utf8NoBom)
Write-Host "Done! Output: $($content.Length) chars, $($content.Split("`n").Count) lines"

Pop-Location
