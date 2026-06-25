Set-Location 'D:\软件\Zcode工作区\product-radar'

# Read source with correct encoding
$srcLines = [System.IO.File]::ReadAllLines('source.html', [System.Text.Encoding]::UTF8)
Write-Host "Source: $($srcLines.Count) lines"

# Extract all sections
$config = ($srcLines[429..467] -join "`n")
$festData = ($srcLines[472..1775] -join "`n")
$state = ($srcLines[1780..1842] -join "`n")
$filter = ($srcLines[1844..1847] -join "`n")
$utils = ($srcLines[1852..1927] -join "`n")
$render = ($srcLines[1932..2154] -join "`n")
$interact = ($srcLines[2157..2248] -join "`n")
$export = ($srcLines[2251..2399] -join "`n")

Write-Host "Config: $($config.Length) chars"
Write-Host "Data: $($festData.Length) chars"
Write-Host "State: $($state.Length) chars"
Write-Host "Utils: $($utils.Length) chars"
Write-Host "Render: $($render.Length) chars"
Write-Host "Interact: $($interact.Length) chars"
Write-Host "Export: $($export.Length) chars"

# Build complete module
$module = @"
<script>
// ===== Festival Planner Module =====
$config

$festData

$state

$filter

$utils

$render

$interact

$export

// ===== FP_ Renaming =====
"@

# Apply renames (order matters: specific first, then general)
$renames = @(
  @('const CONFIG', 'const FP_CONFIG'),
  @('CONFIG.', 'FP_CONFIG.'),
  @('const State', 'const FP_State'),
  @('State.', 'FP_State.'),
  @('const Utils', 'const FP_Utils'),
  @('Utils.', 'FP_Utils.'),
  @('const Render', 'const FP_Render'),
  @('Render.', 'FP_Render.'),
  @('const Interact', 'const FP_Interact'),
  @('Interact.', 'FP_Interact.'),
  @('const Filter', 'const FP_Filter'),
  @('Filter.', 'FP_Filter.')
)

foreach ($r in $renames) {
  $module = $module.Replace($r[0], $r[1])
}

# Fix double-prefix
$module = $module.Replace('FP_FP_', 'FP_')

# Add init function and bind filters
$module += @"

// ===== Init =====
function fpInit() {
  FP_State.load();
  FP_Render.monthNav();
  FP_Render.dashboard();
  FP_Render.main();
  // Bind filters
  ['fpCat','fpMonth','fpUrg','fpSt'].forEach(function(id) {
    var el = document.getElementById(id);
    if (el) el.addEventListener('change', function() { FP_Render.main(); });
  });
  var s = document.getElementById('fpSearch');
  if (s) s.addEventListener('input', FP_Utils.debounce(function() { FP_Filter.search = s.value; FP_Render.main(); }, 180));
  var r = document.getElementById('fpReset');
  if (r) r.addEventListener('click', function() { FP_Interact.resetFilter(); });
  // Load sync config
  var cfg = fpGetSync();
  if (cfg.token) document.getElementById('fpToken').value = cfg.token;
  if (cfg.gistId) document.getElementById('fpGistId').value = cfg.gistId;
}

// ===== Sync =====
var FP_SYNC_KEY = 'uk_festival_sync_config';
function fpGetSync() { try { return JSON.parse(localStorage.getItem(FP_SYNC_KEY)) || {}; } catch(e) { return {}; } }
function fpSaveSync() {
  var t = document.getElementById('fpToken').value.trim();
  var g = document.getElementById('fpGistId').value.trim();
  localStorage.setItem(FP_SYNC_KEY, JSON.stringify({token:t,gistId:g}));
  document.getElementById('fpSyncStatus').textContent = 'Saved!';
}
async function fpSyncCreate() {
  var t = document.getElementById('fpToken').value.trim();
  if (!t) { document.getElementById('fpSyncStatus').textContent = 'Please enter Token first'; return; }
  try {
    var r = await fetch('https://api.github.com/gists', {method:'POST',headers:{'Authorization':'Bearer '+t,'Content-Type':'application/json'},body:JSON.stringify({description:'Festival Planner Sync',public:false,files:{'data.json':{content:FP_State.export()}}})});
    var d = await r.json();
    document.getElementById('fpGistId').value = d.id;
    fpSaveSync();
    document.getElementById('fpSyncStatus').textContent = 'Gist created! ID: '+d.id;
  } catch(e) { document.getElementById('fpSyncStatus').textContent = 'Error: '+e.message; }
}
async function fpSyncPush() {
  var c = fpGetSync(); if (!c.token||!c.gistId) { document.getElementById('fpSyncStatus').textContent = 'Please configure first'; return; }
  try {
    await fetch('https://api.github.com/gists/'+c.gistId, {method:'PATCH',headers:{'Authorization':'Bearer '+c.token,'Content-Type':'application/json'},body:JSON.stringify({files:{'data.json':{content:FP_State.export()}}})});
    document.getElementById('fpSyncStatus').textContent = 'Pushed! '+new Date().toLocaleString();
  } catch(e) { document.getElementById('fpSyncStatus').textContent = 'Error: '+e.message; }
}
async function fpSyncPull() {
  var c = fpGetSync(); if (!c.token||!c.gistId) { document.getElementById('fpSyncStatus').textContent = 'Please configure first'; return; }
  try {
    var r = await fetch('https://api.github.com/gists/'+c.gistId, {headers:{'Authorization':'Bearer '+c.token}});
    var d = await r.json();
    FP_State.import(d.files['data.json'].content);
    FP_Render.dashboard(); FP_Render.main();
    document.getElementById('fpSyncStatus').textContent = 'Pulled! '+new Date().toLocaleString();
  } catch(e) { document.getElementById('fpSyncStatus').textContent = 'Error: '+e.message; }
}
function fpExportJSON() {
  var b = new Blob([FP_State.export()], {type:'application/json'});
  var u = URL.createObjectURL(b);
  var a = document.createElement('a'); a.href = u; a.download = 'festival-backup.json'; a.click();
}
function fpImportJSON(e) {
  var f = e.target.files[0]; if (!f) return;
  var r = new FileReader();
  r.onload = function(ev) { try { FP_State.import(ev.target.result); FP_Render.dashboard(); FP_Render.main(); alert('Import success!'); } catch(err) { alert('Error: '+err.message); } };
  r.readAsText(f); e.target.value = '';
}
function fpExportCSV() {
  var rows = [['Month','Festival','Date','Importance','SKU','SKU EN','Category','Cost','Price','Margin','Match','Risk','Risk Note','Keywords']];
  FESTIVALS.forEach(function(f) {
    f.products.forEach(function(p) {
      rows.push([f.month+'M',f.name,f.date,f.importance,p.sku,p.skuEn,p.category,p.costRange,p.priceRange,p.margin,p.matchScore+'/5',p.riskLevel,p.riskNote,(p.keywords||[]).join('; ')]);
    });
  });
  var csv = '\uFEFF'+rows.map(function(r){return r.map(function(c){return '"'+String(c).replace(/"/g,'""')+'"'}).join(',')}).join('\n');
  var b = new Blob([csv], {type:'text/csv;charset=utf-8'});
  var u = URL.createObjectURL(b);
  var a = document.createElement('a'); a.href = u; a.download = 'festival-skus.csv'; a.click();
}
function fpResetAll() {
  if (!confirm('Clear all progress? This cannot be undone.')) return;
  FP_State.reset(); FP_Render.dashboard(); FP_Render.main();
}

fpInit();
</script>
"@

# Read platform.html
$platform = [System.IO.File]::ReadAllText('output\platform.html', [System.Text.Encoding]::UTF8)

# Check if festival section HTML exists, if not add it
if ($platform.IndexOf('id="sec-festival"') -lt 0) {
  Write-Host "Adding festival section HTML..."
  $festHTML = @"

<!-- FESTIVAL -->
<div class="section" id="sec-festival">
  <div style="max-width:1400px;margin:0 auto">
    <h2 style="font-size:22px;font-weight:700;margin-bottom:16px">Festival Planner <small style="font-size:12px;color:var(--muted)">2026 Jul - 2027 Jun | 61 Events | 300+ SKUs</small></h2>
    <div id="countdown" style="font-size:14px;color:var(--muted);margin-bottom:8px;padding:12px 16px;background:var(--card);border-radius:var(--r);box-shadow:var(--shadow)"></div>
    <div id="statCards" style="display:grid;grid-template-columns:repeat(4,1fr);gap:10px;margin-bottom:12px"></div>
    <nav id="monthNav" style="display:flex;gap:4px;flex-wrap:wrap;margin-bottom:16px"></nav>
    <div style="display:flex;gap:10px;flex-wrap:wrap;align-items:center;margin-bottom:16px;padding:10px 16px;background:var(--card);border-radius:var(--r);box-shadow:var(--shadow);position:sticky;top:57px;z-index:90">
      <label style="font-size:12px;color:var(--muted)">Category</label>
      <select id="fpCat" style="padding:5px 10px;border:1px solid var(--border);border-radius:6px;font-size:13px"><option value="">All</option><option value="decor">Decor</option><option value="gift">Gift</option><option value="apparel">Apparel</option><option value="home">Home</option></select>
      <label style="font-size:12px;color:var(--muted)">Month</label>
      <select id="fpMonth" style="padding:5px 10px;border:1px solid var(--border);border-radius:6px;font-size:13px"><option value="">All</option><option value="1">Jan</option><option value="2">Feb</option><option value="3">Mar</option><option value="4">Apr</option><option value="5">May</option><option value="6">Jun</option><option value="7">Jul</option><option value="8">Aug</option><option value="9">Sep</option><option value="10">Oct</option><option value="11">Nov</option><option value="12">Dec</option></select>
      <label style="font-size:12px;color:var(--muted)">Urgency</label>
      <select id="fpUrg" style="padding:5px 10px;border:1px solid var(--border);border-radius:6px;font-size:13px"><option value="">All</option><option value="urgent">Urgent</option><option value="week">This Week</option><option value="month">This Month</option><option value="plan">Planning</option><option value="past">Past</option></select>
      <label style="font-size:12px;color:var(--muted)">Status</label>
      <select id="fpSt" style="padding:5px 10px;border:1px solid var(--border);border-radius:6px;font-size:13px"><option value="">All</option><option value="none">Not Started</option><option value="selection">Selecting</option><option value="ordered">Ordered</option><option value="arrived">Arrived</option><option value="listed">Listed</option></select>
      <input type="text" id="fpSearch" placeholder="Search..." style="padding:5px 10px;border:1px solid var(--border);border-radius:6px;font-size:13px;min-width:160px">
      <button id="fpReset" style="padding:5px 12px;border:1px solid var(--border);border-radius:6px;cursor:pointer;font-size:12px">Reset</button>
    </div>
    <main id="main"></main>
    <div style="margin-top:20px;padding:16px;background:var(--card);border-radius:var(--r);box-shadow:var(--shadow);font-size:12px;color:var(--muted)">
      <h3 style="font-size:14px;color:var(--text);margin-bottom:8px">Usage</h3>
      <p>Click festival card to expand. Click timeline dots to toggle milestones.</p>
      <p>Switch logistics (Sea/Rail/Air) to recalculate timeline and urgency.</p>
      <p>All progress saves to browser localStorage. Export backup regularly.</p>
      <div style="background:#fffbeb;border-left:3px solid var(--orange);padding:8px 12px;margin:10px 0;border-radius:4px"><strong>Disclaimer:</strong> SKU suggestions are reference values based on industry experience. Verify via Google Trends, Amazon BSR before sourcing.</div>
      <div style="background:#f0f9ff;border:1px solid #bae6fd;border-radius:8px;padding:14px;margin:12px 0">
        <h4 style="font-size:13px;color:var(--blue);margin-bottom:6px">Team Sync (GitHub Gist)</h4>
        <div style="display:flex;gap:8px;align-items:center;margin-bottom:6px"><label style="min-width:60px">Token</label><input type="password" id="fpToken" placeholder="ghp_xxx" style="flex:1;padding:4px 8px;border:1px solid var(--border);border-radius:4px;font-size:12px"></div>
        <div style="display:flex;gap:8px;align-items:center;margin-bottom:6px"><label style="min-width:60px">Gist ID</label><input type="text" id="fpGistId" placeholder="abc123" style="flex:1;padding:4px 8px;border:1px solid var(--border);border-radius:4px;font-size:12px"></div>
        <div style="display:flex;gap:6px;margin-top:8px;flex-wrap:wrap">
          <button onclick="fpSyncPush()" style="padding:5px 12px;background:var(--blue);color:#fff;border:1px solid var(--blue);border-radius:6px;cursor:pointer;font-size:12px">Push</button>
          <button onclick="fpSyncPull()" style="padding:5px 12px;background:var(--green);color:#fff;border:1px solid var(--green);border-radius:6px;cursor:pointer;font-size:12px">Pull</button>
          <button onclick="fpSyncCreate()" style="padding:5px 12px;border:1px solid var(--border);border-radius:6px;cursor:pointer;font-size:12px">Create Gist</button>
          <button onclick="fpSaveSync()" style="padding:5px 12px;border:1px solid var(--border);border-radius:6px;cursor:pointer;font-size:12px">Save Config</button>
        </div>
        <div id="fpSyncStatus" style="margin-top:6px;font-size:12px"></div>
      </div>
      <div style="display:flex;gap:8px;margin-top:10px;flex-wrap:wrap">
        <button onclick="fpExportJSON()" style="padding:5px 12px;border:1px solid var(--border);border-radius:6px;cursor:pointer;font-size:12px">Export JSON</button>
        <button onclick="document.getElementById('fpImportFile').click()" style="padding:5px 12px;border:1px solid var(--border);border-radius:6px;cursor:pointer;font-size:12px">Import JSON</button>
        <input type="file" id="fpImportFile" accept=".json" style="display:none" onchange="fpImportJSON(event)">
        <button onclick="fpExportCSV()" style="padding:5px 12px;border:1px solid var(--border);border-radius:6px;cursor:pointer;font-size:12px">Export CSV</button>
        <button onclick="fpResetAll()" style="padding:5px 12px;border:1px solid var(--red);color:var(--red);border-radius:6px;cursor:pointer;font-size:12px">Clear All</button>
      </div>
    </div>
  </div>
</div>

"@
  $platform = $platform.Replace('<!-- KANBAN -->', $festHTML + '<!-- KANBAN -->')
}

# Check if festival tab button exists
if ($platform.IndexOf('data-tab="festival"') -lt 0) {
  Write-Host "Adding festival tab button..."
  $platform = $platform.Replace(
    '<button class="main-tab" data-tab="kanban"',
    '<button class="main-tab" data-tab="festival" style="--tc:var(--orange)">Festival Planner <span class="cnt" id="fpCnt">0</span></button>' + "`n" + '  <button class="main-tab" data-tab="kanban"'
  )
}

# Insert festival script before </body>
$result = $platform.Replace('</body>', $module + "`n" + '</body>')

# Write with UTF-8 no BOM
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText('output\platform.html', $result, $utf8NoBom)

Write-Host "Done! Lines: $($result.Split("`n").Count)"

# Verify
$fpfp = ([regex]::Matches($result, 'FP_FP_')).Count
Write-Host "FP_FP_ count: $fpfp"
$consts = @('FP_CONFIG','FP_State','FP_Utils','FP_Render','FP_Interact','FP_Filter','FESTIVALS')
foreach ($c in $consts) {
  $cnt = ([regex]::Matches($result, "const $c")).Count
  Write-Host "const $c : $cnt"
}
