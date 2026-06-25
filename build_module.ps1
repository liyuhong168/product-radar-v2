Push-Location 'D:\软件\Zcode工作区\product-radar'

# Read source
$src = [System.IO.File]::ReadAllText('source.html', [System.Text.Encoding]::UTF8)
$srcLines = $src.Split("`n")
Write-Host "Source: $($srcLines.Count) lines"

# Extract sections
$config = ($srcLines[429..467] -join "`n")
$data = ($srcLines[472..1775] -join "`n")
$state = ($srcLines[1780..1849] -join "`n")
$utils = ($srcLines[1851..1929] -join "`n")
$render = ($srcLines[1931..2154] -join "`n")
$interact = ($srcLines[2156..2248] -join "`n")
$export = ($srcLines[2250..2399] -join "`n")

# Build module with FP_ prefix
$module = @"
// ============================================
// Festival Planner Module (FP_ prefixed)
// ============================================

// Rename CONFIG -> FP_CONFIG
$config

// FESTIVALS data
$data

// State -> FP_State
$state

// Utils -> FP_Utils
$utils

// Render -> FP_Render
$render

// Interact -> FP_Interact
$interact

// Export/Sync functions
$export

// ===== FP_ Renaming =====
// All renames done via text replacement below

"@

# Apply FP_ prefix renames
$renames = @(
  @('const CONFIG = ', 'const FP_CONFIG = '),
  @('CONFIG.', 'FP_CONFIG.'),
  @('const State = ', 'const FP_State = '),
  @('State.', 'FP_State.'),
  @('const Utils = ', 'const FP_Utils = '),
  @('Utils.', 'FP_Utils.'),
  @('const Render = ', 'const FP_Render = '),
  @('Render.', 'FP_Render.'),
  @('const Interact = ', 'const FP_Interact = '),
  @('Interact.', 'FP_Interact.'),
  @('const Filter = ', 'const FP_Filter = '),
  @('Filter.', 'FP_Filter.')
)

foreach ($r in $renames) {
  $module = $module.Replace($r[0], $r[1])
}

# Fix double-prefix issue (FP_FP_ -> FP_)
$module = $module.Replace('FP_FP_', 'FP_')

# Add init and filter binding functions
$module += @"

// ===== Festival Init & Filters =====
function FP_init() {
  FP_State.load();
  FP_Render.monthNav();
  FP_Render.dashboard();
  FP_Render.main();
  FP_bindFilters();
  fpLoadSync();
}

function FP_bindFilters() {
  ['fpCat','fpMonth','fpUrg','fpSt'].forEach(id => {
    const el = document.getElementById(id);
    if (el) el.addEventListener('change', () => FP_Render.main());
  });
  const s = document.getElementById('fpSearch');
  if (s) s.addEventListener('input', FP_Utils.debounce(() => { FP_Filter.search = s.value; FP_Render.main(); }, 180));
  const r = document.getElementById('fpReset');
  if (r) r.addEventListener('click', () => FP_Interact.resetFilter());
}

// ===== Sync (renamed to fp* to avoid conflicts) =====
const FP_SYNC_KEY = 'uk_festival_sync_config';
function fpGetSync() { try { return JSON.parse(localStorage.getItem(FP_SYNC_KEY)) || {}; } catch { return {}; } }
function fpSaveSync() {
  const t = document.getElementById('fpToken').value.trim();
  const g = document.getElementById('fpGistId').value.trim();
  localStorage.setItem(FP_SYNC_KEY, JSON.stringify({token:t,gistId:g}));
  document.getElementById('fpSyncStatus').textContent = '✅ 配置已保存';
}
function fpLoadSync() {
  const c = fpGetSync();
  if (c.token) document.getElementById('fpToken').value = c.token;
  if (c.gistId) document.getElementById('fpGistId').value = c.gistId;
}
async function fpSyncCreate() {
  const t = document.getElementById('fpToken').value.trim();
  if (!t) { document.getElementById('fpSyncStatus').textContent = '❌ 请先填Token'; return; }
  try {
    const r = await fetch('https://api.github.com/gists', {method:'POST',headers:{'Authorization':'Bearer '+t,'Accept':'application/vnd.github+json','Content-Type':'application/json'},body:JSON.stringify({description:'UK Festival Planner Sync',public:false,files:{'data.json':{content:FP_State.export()}}})});
    const d = await r.json();
    document.getElementById('fpGistId').value = d.id;
    fpSaveSync();
    document.getElementById('fpSyncStatus').textContent = '✅ Gist创建成功！ID: '+d.id;
  } catch(e) { document.getElementById('fpSyncStatus').textContent = '❌ '+e.message; }
}
async function fpSyncPush() {
  const c = fpGetSync(); if (!c.token||!c.gistId) { document.getElementById('fpSyncStatus').textContent = '❌ 请先配置'; return; }
  try {
    await fetch('https://api.github.com/gists/'+c.gistId, {method:'PATCH',headers:{'Authorization':'Bearer '+c.token,'Content-Type':'application/json'},body:JSON.stringify({files:{'data.json':{content:FP_State.export()}}})});
    document.getElementById('fpSyncStatus').textContent = '✅ 推送成功！'+new Date().toLocaleString('zh-CN');
  } catch(e) { document.getElementById('fpSyncStatus').textContent = '❌ '+e.message; }
}
async function fpSyncPull() {
  const c = fpGetSync(); if (!c.token||!c.gistId) { document.getElementById('fpSyncStatus').textContent = '❌ 请先配置'; return; }
  try {
    const r = await fetch('https://api.github.com/gists/'+c.gistId, {headers:{'Authorization':'Bearer '+c.token}});
    const d = await r.json();
    FP_State.import(d.files['data.json'].content);
    FP_Render.dashboard(); FP_Render.main();
    document.getElementById('fpSyncStatus').textContent = '✅ 拉取成功！'+new Date().toLocaleString('zh-CN');
  } catch(e) { document.getElementById('fpSyncStatus').textContent = '❌ '+e.message; }
}
function fpExport() {
  const b = new Blob([FP_State.export()], {type:'application/json'});
  const u = URL.createObjectURL(b);
  const a = document.createElement('a'); a.href = u; a.download = 'festival-backup-'+FP_Utils.fmtYMD(new Date())+'.json'; a.click();
}
function fpImport(e) {
  const f = e.target.files[0]; if (!f) return;
  const r = new FileReader();
  r.onload = ev => { try { FP_State.import(ev.target.result); FP_Render.dashboard(); FP_Render.main(); alert('✅ 导入成功！'); } catch(err) { alert('❌ '+err.message); } };
  r.readAsText(f); e.target.value = '';
}
function fpExportCSV() {
  const rows = [['月份','节日','日期','重要性','SKU','英文SKU','品类','成本','售价','利润率','匹配度','风险','风险说明','关键词']];
  FESTIVALS.forEach(f => {
    const u = FP_Utils.getUrgency(f);
    const fs = FP_State.getFestival(f.id);
    f.products.forEach(p => {
      rows.push([f.month+'月',f.name,f.date,f.importance,p.sku,p.skuEn,p.category,p.costRange,p.priceRange,p.margin,p.matchScore+'/5',p.riskLevel,p.riskNote,(p.keywords||[]).join('; ')]);
    });
  });
  const csv = '\uFEFF'+rows.map(r=>r.map(c=>'"'+String(c).replace(/"/g,'""')+'"').join(',')).join("\n");
  const b = new Blob([csv], {type:'text/csv;charset=utf-8'});
  const u = URL.createObjectURL(b);
  const a = document.createElement('a'); a.href = u; a.download = 'festival-skus.csv'; a.click();
}
function fpReset() {
  if (!confirm('⚠️ 确定清除所有进度？')) return;
  FP_State.reset(); FP_Render.dashboard(); FP_Render.main();
}
"@

# Write module
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText('fest_module.js', $module, $utf8NoBom)
Write-Host "Module written: $($module.Length) chars"

# Verify no FP_FP_ remaining
$fpfp = ([regex]::Matches($module, 'FP_FP_')).Count
Write-Host "FP_FP_ count: $fpfp"

# Verify key declarations
foreach ($name in @('FP_CONFIG', 'FP_State', 'FP_Utils', 'FP_Render', 'FP_Interact', 'FP_Filter', 'FESTIVALS')) {
  $cnt = ([regex]::Matches($module, "const $name")).Count
  Write-Host "const $name : $cnt"
}

Pop-Location
