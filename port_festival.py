#!/usr/bin/env python3
"""Port the full festival planner from uk-festival-planner/index.html into product-radar/output/platform.html"""
import re

# Read source file
with open(r"D:\软件\Zcode工作区\index.html", "r", encoding="utf-8") as f:
    src = f.read()

# Read target file
with open(r"D:\软件\Zcode工作区\product-radar\output\platform.html", "r", encoding="utf-8") as f:
    tgt = f.read()

# ===== 1. Extract FESTIVALS array from source =====
fest_start = src.find("const FESTIVALS = [")
fest_end = src.find("\n];", fest_start) + 3
festivals_code = src[fest_start:fest_end]
print(f"Extracted FESTIVALS: {len(festivals_code)} chars, {festivals_code.count(chr(10))} lines")

# ===== 2. Extract CONFIG object from source =====
config_start = src.find("const CONFIG = {")
config_end = src.find("};", config_start) + 2
config_code = src[config_start:config_end]
print(f"Extracted CONFIG: {len(config_code)} chars")

# ===== 3. Extract State management from source =====
state_start = src.find("const State = {")
state_end = src.find("};", state_start) + 2
state_code = src[state_start:state_end]
print(f"Extracted State: {len(state_code)} chars")

# ===== 4. Extract Utils from source =====
utils_start = src.find("const Utils = {")
utils_end = src.find("};\n\n// ===", utils_start) + 2
utils_code = src[utils_start:utils_end]
print(f"Extracted Utils: {len(utils_code)} chars")

# ===== 5. Extract Render object from source =====
render_start = src.find("const Render = {")
render_end = src.find("};\n\n// === 筛选栏", render_start) + 2
render_code = src[render_start:render_end]
print(f"Extracted Render: {len(render_code)} chars")

# ===== 6. Extract Interact object from source =====
interact_start = src.find("const Interact = {")
interact_end = src.find("};\n\n// === 筛选栏事件", interact_start) + 2
interact_code = src[interact_start:interact_end]
print(f"Extracted Interact: {len(interact_code)} chars")

# ===== 7. Extract export/import/sync functions from source =====
export_start = src.find("function exportData()")
# Find the end - look for the scroll event listener
export_end = src.find("// 回到顶部按钮显隐", export_start)
export_code = src[export_start:export_end].strip()
print(f"Extracted export/sync: {len(export_code)} chars")

# ===== 8. Extract CSS from source (festival-specific styles) =====
css_start = src.find(":root {")
css_end = src.find("</style>", css_start)
css_code = src[css_start:css_end]
# Remove the :root variables (already in platform.html) and keep festival-specific styles
# Extract styles that are festival-specific
festival_css_patterns = [
    r'\.header[\s\S]*?\.month-nav[\s\S]*?\n\}',
    r'\.dashboard[\s\S]*?\.stat-card[\s\S]*?\n\}',
    r'\.filter-bar[\s\S]*?\.filter-group[\s\S]*?\n\}',
    r'\.cards-grid[\s\S]*?\.card-arrow[\s\S]*?\n\}',
    r'\.card-header[\s\S]*?\.card-controls[\s\S]*?\n\}',
    r'\.timeline[\s\S]*?\.tl-actions[\s\S]*?\n\}',
    r'\.products-table[\s\S]*?\.risk[\s\S]*?\n\}',
    r'\.footer[\s\S]*?\.footer-actions[\s\S]*?\n\}',
    r'\.sync-panel[\s\S]*?\.sync-tip[\s\S]*?\n\}',
    r'\.back-to-top[\s\S]*?\n\}',
    r'\.empty-state[\s\S]*?\n\}',
    r'\.hidden[\s\S]*?\n\}',
]
# Just extract all CSS between :root and </style>
print(f"Extracted CSS: {len(css_code)} chars")

# ===== Build the Festival module =====
festival_module = f"""
// ============================================
// Festival Planner Module (ported from uk-festival-planner)
// ============================================

{config_code}

{festivals_code}

{state_code}

{utils_code}

{render_code}

{interact_code}

{export_code}

// Festival filter event bindings
function bindFestFilters() {{
  document.getElementById('filterCategory').addEventListener('change', e => {{
    Filter.category = e.target.value; Filter.statCardUrgency = ''; Render.main();
  }});
  document.getElementById('filterMonth').addEventListener('change', e => {{
    Filter.month = e.target.value; Render.main();
  }});
  document.getElementById('filterUrgency').addEventListener('change', e => {{
    Filter.urgency = e.target.value; Filter.statCardUrgency = ''; Render.main();
  }});
  document.getElementById('filterStatus').addEventListener('change', e => {{
    Filter.status = e.target.value; Render.main();
  }});
  const debouncedSearch = Utils.debounce(v => {{ Filter.search = v; Render.main(); }}, 180);
  document.getElementById('filterSearch').addEventListener('input', e => {{
    debouncedSearch(e.target.value);
  }});
  document.getElementById('resetFilter').addEventListener('click', () => Interact.resetFilter());
}}

// Festival init
function initFestival() {{
  State.load();
  Render.monthNav();
  Render.dashboard();
  Render.main();
  bindFestFilters();
}}

// Override the simple renderFestival with the full version
renderFestival = function() {{
  // Already handled by Render.main()
}};
"""

# ===== Now replace the Festival section in platform.html =====

# 1. Replace the simple Festival CSS with full CSS
# Find the existing festival CSS block
fest_css_start = tgt.find("/* ===== FESTIVAL TAB ===== */")
fest_css_end = tgt.find("@media(max-width:768px)", fest_css_start)
if fest_css_end == -1:
    fest_css_end = tgt.find("</style>", fest_css_start)

# Build the full festival CSS
full_fest_css = """/* ===== FESTIVAL PLANNER (full version) ===== */
.fest-planner { max-width: 1400px; margin: 0 auto; }
.fp-header { margin-bottom: 16px; }
.fp-header h2 { font-size: 22px; font-weight: 700; }
.fp-header small { font-size: 12px; color: var(--muted); }

/* Dashboard */
.fp-dashboard { margin-bottom: 16px; }
.fp-countdown { font-size: 14px; color: var(--muted); margin-bottom: 8px; padding: 12px 16px; background: var(--card); border-radius: var(--r); box-shadow: var(--shadow); }
.fp-countdown strong { color: var(--text); font-size: 16px; }
.fp-stats { display: grid; grid-template-columns: repeat(4, 1fr); gap: 10px; margin-bottom: 12px; }
.fp-stat { background: var(--card); border-radius: 12px; padding: 12px; box-shadow: var(--shadow); cursor: pointer; border-left: 4px solid var(--border); transition: all .15s; }
.fp-stat:hover { box-shadow: 0 4px 16px rgba(0,0,0,.12); transform: translateY(-1px); }
.fp-stat.active { background: #eff6ff; }
.fp-stat .num { font-size: 24px; font-weight: 700; }
.fp-stat .lbl { font-size: 11px; color: var(--muted); }
.fp-stat.urgent { border-left-color: var(--red); }
.fp-stat.urgent .num { color: var(--red); }
.fp-stat.week { border-left-color: var(--orange); }
.fp-stat.week .num { color: var(--orange); }
.fp-stat.month { border-left-color: #eab308; }
.fp-stat.month .num { color: #eab308; }
.fp-stat.plan { border-left-color: var(--green); }
.fp-stat.plan .num { color: var(--green); }

/* Filters */
.fp-filters { display: flex; gap: 10px; flex-wrap: wrap; align-items: center; margin-bottom: 16px; padding: 10px 16px; background: var(--card); border-radius: var(--r); box-shadow: var(--shadow); position: sticky; top: 57px; z-index: 90; }
.fp-filters label { font-size: 12px; color: var(--muted); }
.fp-filters select, .fp-filters input[type="text"] { padding: 5px 10px; border: 1px solid var(--border); border-radius: 6px; font-size: 13px; background: #fff; }
.fp-filters input[type="text"] { min-width: 160px; }
.fp-filters button { padding: 5px 12px; border: 1px solid var(--border); border-radius: 6px; background: var(--card); cursor: pointer; font-size: 12px; }
.fp-filters button:hover { background: #f0f0f5; }

/* Month nav */
.fp-month-nav { display: flex; gap: 4px; flex-wrap: wrap; margin-bottom: 16px; }
.fp-month-nav a { padding: 4px 10px; border-radius: 6px; text-decoration: none; color: var(--muted); font-size: 13px; transition: all .15s; }
.fp-month-nav a:hover { background: #f0f0f5; color: var(--purple); }

/* Month sections */
.fp-month { margin-bottom: 24px; }
.fp-month h2 { font-size: 18px; font-weight: 700; margin-bottom: 12px; padding-bottom: 8px; border-bottom: 2px solid var(--border); }
.fp-month h2 .cnt { font-size: 13px; color: var(--muted); font-weight: 400; margin-left: 8px; }

/* Festival cards */
.fp-cards { display: flex; flex-direction: column; gap: 12px; }
.fp-card { background: var(--card); border-radius: var(--r); box-shadow: var(--shadow); overflow: hidden; border-left: 4px solid var(--orange); transition: all .2s; }
.fp-card:hover { box-shadow: 0 4px 20px rgba(0,0,0,.12); }
.fp-card.urgent { border-left-color: var(--red); }
.fp-card.week { border-left-color: var(--orange); }
.fp-card.month { border-left-color: #eab308; }
.fp-card.plan { border-left-color: var(--green); }
.fp-card.past { border-left-color: #8e8e93; opacity: .7; }

/* Card header */
.fp-hd { padding: 14px 18px; cursor: pointer; display: flex; align-items: center; gap: 12px; transition: background .15s; }
.fp-hd:hover { background: #f8f8fa; }
.fp-icon { font-size: 28px; flex-shrink: 0; }
.fp-info { flex: 1; min-width: 0; }
.fp-name { font-size: 16px; font-weight: 700; }
.fp-name-en { font-size: 11px; color: var(--muted); }
.fp-meta { display: flex; gap: 8px; margin-top: 4px; flex-wrap: wrap; align-items: center; }
.fp-badge { padding: 2px 8px; border-radius: 6px; font-size: 11px; font-weight: 700; }
.fp-badge.s { background: #FF2D5515; color: var(--red); }
.fp-badge.a { background: #FF950015; color: var(--orange); }
.fp-badge.b { background: #007AFF15; color: var(--blue); }
.fp-date { font-size: 12px; color: var(--muted); }
.fp-urgency { padding: 3px 10px; border-radius: 8px; font-size: 12px; font-weight: 700; flex-shrink: 0; }
.fp-urgency.urgent { background: var(--red); color: #fff; }
.fp-urgency.week { background: var(--orange); color: #fff; }
.fp-urgency.month { background: #eab308; color: #fff; }
.fp-urgency.plan { background: var(--green); color: #fff; }
.fp-urgency.past { background: #8e8e93; color: #fff; }
.fp-arrow { font-size: 18px; color: var(--muted); transition: transform .2s; flex-shrink: 0; }
.fp-card.open .fp-arrow { transform: rotate(90deg); }

/* Card detail (expanded) */
.fp-detail { display: none; padding: 0 18px 14px; }
.fp-card.open .fp-detail { display: block; }

/* Logistics toggle */
.fp-logistics { display: flex; gap: 4px; margin-bottom: 12px; align-items: center; }
.fp-logistics label { font-size: 12px; color: var(--muted); margin-right: 4px; }
.fp-log-btn { padding: 4px 12px; border: 1px solid var(--border); border-radius: 6px; background: var(--card); cursor: pointer; font-size: 12px; }
.fp-log-btn.active { background: var(--blue); color: #fff; border-color: var(--blue); }

/* Timeline */
.fp-timeline { display: flex; gap: 0; align-items: flex-start; margin-bottom: 14px; padding: 12px 0; overflow-x: auto; }
.fp-tl-item { display: flex; flex-direction: column; align-items: center; gap: 4px; flex: 1; min-width: 80px; position: relative; }
.fp-tl-item::after { content: ''; position: absolute; top: 10px; left: 50%; width: 100%; height: 2px; background: var(--border); z-index: 0; }
.fp-tl-item:last-child::after { display: none; }
.fp-tl-dot { width: 20px; height: 20px; border-radius: 50%; background: var(--border); border: 3px solid #fff; box-shadow: 0 0 0 2px var(--border); cursor: pointer; z-index: 1; transition: all .2s; }
.fp-tl-dot:hover { transform: scale(1.2); }
.fp-tl-dot.done { background: var(--green); box-shadow: 0 0 0 2px var(--green); }
.fp-tl-dot.active { background: var(--orange); box-shadow: 0 0 0 2px var(--orange); }
.fp-tl-name { font-size: 10px; color: var(--muted); text-align: center; white-space: nowrap; }
.fp-tl-date { font-size: 11px; font-weight: 600; color: var(--text); }
.fp-tl-actions { font-size: 10px; color: var(--blue); margin-top: 2px; max-width: 120px; text-align: center; line-height: 1.3; }

/* Status selector */
.fp-status { display: flex; gap: 4px; margin-bottom: 10px; align-items: center; flex-wrap: wrap; }
.fp-status label { font-size: 12px; color: var(--muted); margin-right: 4px; }
.fp-st-btn { padding: 3px 10px; border: 1px solid var(--border); border-radius: 6px; background: var(--card); cursor: pointer; font-size: 11px; }
.fp-st-btn.active { color: #fff; }

/* Products table */
.fp-products { margin-bottom: 12px; }
.fp-products h4 { font-size: 14px; font-weight: 600; margin-bottom: 8px; }
.fp-prod-table { width: 100%; border-collapse: collapse; font-size: 12px; }
.fp-prod-table th { text-align: left; padding: 6px 8px; background: #f8f8fa; color: var(--muted); font-weight: 600; border-bottom: 1px solid var(--border); }
.fp-prod-table td { padding: 6px 8px; border-bottom: 1px solid #f0f0f5; vertical-align: top; }
.fp-prod-table tr:hover { background: #f8f8fa; }
.fp-prod-table .sku-name { font-weight: 600; color: var(--text); }
.fp-prod-table .sku-en { color: var(--muted); font-size: 11px; }
.fp-prod-table .risk-low { color: var(--green); }
.fp-prod-table .risk-mid { color: var(--orange); }
.fp-prod-table .risk-high { color: var(--red); }
.fp-prod-table .match-stars { color: #f59e0b; }
.fp-sourcing { font-size: 11px; color: var(--blue); }
.fp-sourcing a { color: var(--blue); text-decoration: none; }
.fp-sourcing a:hover { text-decoration: underline; }

/* Notes */
.fp-notes { margin-bottom: 10px; }
.fp-notes textarea { width: 100%; padding: 8px; border: 1px solid var(--border); border-radius: 6px; font-size: 12px; min-height: 50px; resize: vertical; font-family: inherit; }

/* Validation */
.fp-validation { background: #eff6ff; border-radius: 8px; padding: 10px; margin-bottom: 10px; font-size: 12px; }
.fp-validation h4 { font-size: 12px; color: var(--blue); margin-bottom: 4px; }
.fp-validation ul { margin-left: 16px; color: var(--muted); }

/* Export/Sync panel in footer */
.fp-footer { margin-top: 24px; padding: 16px; background: var(--card); border-radius: var(--r); box-shadow: var(--shadow); font-size: 12px; color: var(--muted); }
.fp-footer h3 { font-size: 14px; color: var(--text); margin-bottom: 8px; }
.fp-footer .disclaimer { background: #fffbeb; border-left: 3px solid var(--orange); padding: 8px 12px; margin: 10px 0; border-radius: 4px; }
.fp-footer .sync-panel { background: #f0f9ff; border: 1px solid #bae6fd; border-radius: 8px; padding: 14px; margin: 12px 0; }
.fp-footer .sync-panel h4 { font-size: 13px; color: var(--blue); margin-bottom: 6px; }
.fp-footer .sync-row { display: flex; gap: 8px; align-items: center; margin-bottom: 6px; }
.fp-footer .sync-row label { min-width: 80px; font-size: 12px; }
.fp-footer .sync-row input { flex: 1; padding: 4px 8px; border: 1px solid var(--border); border-radius: 4px; font-size: 12px; min-width: 180px; }
.fp-footer .sync-actions { display: flex; gap: 6px; margin-top: 8px; flex-wrap: wrap; }
.fp-footer .sync-actions button { padding: 5px 12px; border: 1px solid var(--border); border-radius: 6px; cursor: pointer; font-size: 12px; }
.fp-footer .sync-actions .push { background: var(--blue); color: #fff; border-color: var(--blue); }
.fp-footer .sync-actions .pull { background: var(--green); color: #fff; border-color: var(--green); }
.fp-footer .fp-actions { display: flex; gap: 8px; margin-top: 10px; flex-wrap: wrap; }
.fp-footer .fp-actions button { padding: 5px 12px; border: 1px solid var(--border); border-radius: 6px; cursor: pointer; font-size: 12px; }
.fp-footer .fp-actions button:hover { background: #f0f0f5; }
.fp-footer .fp-actions button.danger { color: var(--red); border-color: var(--red); }

/* Empty state */
.fp-empty { text-align: center; padding: 40px; color: var(--muted); }
"""

# Replace the festival CSS
if fest_css_start >= 0 and fest_css_end >= 0:
    tgt = tgt[:fest_css_start] + full_fest_css + "\n" + tgt[fest_css_end:]
    print("Replaced festival CSS")

# 2. Replace the Festival HTML section
fest_html_start = tgt.find("<!-- FESTIVAL -->")
fest_html_end = tgt.find("<!-- KANBAN -->", fest_html_start)
if fest_html_start >= 0 and fest_html_end >= 0:
    fest_html = """<!-- FESTIVAL (full version) -->
<div class="section" id="sec-festival">
  <div class="fest-planner">
    <div class="fp-dashboard">
      <div class="fp-countdown" id="fpCountdown"></div>
      <div class="fp-stats" id="fpStats"></div>
    </div>
    <div class="fp-filters">
      <label>品类</label>
      <select id="fpCatFilter">
        <option value="">全部</option>
        <option value="decor">🎃装饰</option>
        <option value="gift">🎁礼品</option>
        <option value="apparel">👕服饰</option>
        <option value="home">🏠家居</option>
      </select>
      <label>月份</label>
      <select id="fpMonthFilter">
        <option value="">全部</option>
        <option value="1">1月</option><option value="2">2月</option><option value="3">3月</option>
        <option value="4">4月</option><option value="5">5月</option><option value="6">6月</option>
        <option value="7">7月</option><option value="8">8月</option><option value="9">9月</option>
        <option value="10">10月</option><option value="11">11月</option><option value="12">12月</option>
      </select>
      <label>紧急度</label>
      <select id="fpUrgencyFilter">
        <option value="">全部</option>
        <option value="urgent">🔴紧急</option>
        <option value="week">🟠本周</option>
        <option value="month">🟡本月</option>
        <option value="plan">🟢规划</option>
        <option value="past">⚫已过</option>
      </select>
      <label>状态</label>
      <select id="fpStatusFilter">
        <option value="">全部</option>
        <option value="none">未启动</option>
        <option value="selection">选品中</option>
        <option value="ordered">已下单</option>
        <option value="arrived">已到仓</option>
        <option value="listed">已上架</option>
      </select>
      <input type="text" id="fpSearch" placeholder="🔍 搜索节日/SKU/关键词">
      <button id="fpReset">重置</button>
    </div>
    <div class="fp-month-nav" id="fpMonthNav"></div>
    <div id="fpMain"></div>
    <div class="fp-empty" id="fpEmpty" style="display:none">没有匹配的节日，试试调整筛选条件。🔍</div>
  </div>
  <div class="fp-footer">
    <h3>📌 节日选品说明</h3>
    <p>• 点击节日卡片标题展开详情；点击时间线圆点勾选里程碑进度。</p>
    <p>• 切换物流方式（海运/卡航/空运）会重算该节日的时间线和紧急度。</p>
    <p>• 所有进度自动保存在浏览器本地（localStorage），建议定期导出备份。</p>
    <div class="disclaimer">
      <strong>⚠️ 数据免责声明：</strong>SKU建议、售价区间、毛利率为基于行业经验的参考值，非实时销量数据。请通过 Google Trends、亚马逊BSR、Keepa 等工具验证后再决策。
    </div>
    <div class="sync-panel">
      <h4>☁️ 团队数据同步（GitHub Gist）</h4>
      <div class="sync-row"><label>GitHub Token</label><input type="password" id="fpSyncToken" placeholder="ghp_xxx"></div>
      <div class="sync-row"><label>Gist ID</label><input type="text" id="fpSyncGistId" placeholder="abc123"></div>
      <div class="sync-actions">
        <button class="push" onclick="fpSyncPush()">⬆️ 推送</button>
        <button class="pull" onclick="fpSyncPull()">⬇️ 拉取</button>
        <button onclick="fpSyncCreate()">🆕 创建Gist</button>
        <button onclick="fpSaveSyncConfig()">💾 保存配置</button>
      </div>
      <div id="fpSyncStatus"></div>
    </div>
    <div class="fp-actions">
      <button onclick="fpExport()">📤 导出备份</button>
      <button onclick="document.getElementById('fpImportFile').click()">📥 导入恢复</button>
      <input type="file" id="fpImportFile" accept=".json" style="display:none" onchange="fpImport(event)">
      <button onclick="fpExportExcel()">📊 导出Excel</button>
      <button class="danger" onclick="fpReset()">🗑 清除所有进度</button>
    </div>
  </div>
</div>

"""
    tgt = tgt[:fest_html_start] + fest_html + tgt[fest_html_end:]
    print("Replaced festival HTML")

# 3. Add the festival JavaScript module before </script>
script_end = tgt.rfind("</script>")
if script_end >= 0:
    tgt = tgt[:script_end] + "\n" + festival_module + "\n" + tgt[script_end:]
    print("Added festival JS module")

# 4. Update renderAll to call initFestival
tgt = tgt.replace("renderDiscovery();\n  renderRadar();\n  renderFestival();",
                   "renderDiscovery();\n  renderRadar();\n  initFestival();")

# Write the result
with open(r"D:\软件\Zcode工作区\product-radar\output\platform.html", "w", encoding="utf-8") as f:
    f.write(tgt)

print(f"\nDone! Output: {len(tgt)} chars")
