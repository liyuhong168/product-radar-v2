Set-Location 'D:\软件\Zcode工作区\product-radar'

# Read platform.html
$platform = [System.IO.File]::ReadAllText('output\platform.html', [System.Text.Encoding]::UTF8)

# Read FESTIVALS data from source
$srcLines = [System.IO.File]::ReadAllLines('source.html', [System.Text.Encoding]::UTF8)
$festData = ($srcLines[472..1775] -join "`n")

# Build separate script block
$festScript = @"
<script>
// ===== Festival Planner Module =====
$festData

var fpState = JSON.parse(localStorage.getItem('fp_state') || '{"festivals":{}}');
function fpSave() { localStorage.setItem('fp_state', JSON.stringify(fpState)); }
function fpGet(id) {
  if (!fpState.festivals[id]) fpState.festivals[id] = {status:'none',logistics:'truck',notes:'',skus:[]};
  return fpState.festivals[id];
}

function fpUrg(dateStr) {
  var d = new Date(dateStr); var now = new Date(); now.setHours(0,0,0,0);
  var diff = Math.ceil((d - now) / 86400000);
  if (diff < 0) return 'past';
  if (diff <= 7) return 'urgent';
  if (diff <= 30) return 'week';
  if (diff <= 60) return 'month';
  return 'plan';
}
function fpDays(dateStr) {
  var d = new Date(dateStr); var now = new Date(); now.setHours(0,0,0,0);
  var diff = Math.ceil((d - now) / 86400000);
  if (diff < 0) return Math.abs(diff) + 'd ago';
  if (diff === 0) return 'TODAY';
  return diff + 'd';
}

function fpDash() {
  var s = {urgent:0,week:0,month:0,plan:0,past:0};
  FESTIVALS.forEach(function(f) { s[fpUrg(f.date)]++; });
  var el = document.getElementById('fpDash');
  if (!el) return;
  el.innerHTML = '<div style="display:grid;grid-template-columns:repeat(4,1fr);gap:10px">' +
    '<div style="background:var(--card);border-radius:12px;padding:12px;box-shadow:var(--shadow);border-left:4px solid var(--red)"><div style="font-size:24px;font-weight:700;color:var(--red)">'+s.urgent+'</div><div style="font-size:11px;color:var(--muted)">Urgent</div></div>' +
    '<div style="background:var(--card);border-radius:12px;padding:12px;box-shadow:var(--shadow);border-left:4px solid var(--orange)"><div style="font-size:24px;font-weight:700;color:var(--orange)">'+s.week+'</div><div style="font-size:11px;color:var(--muted)">This Week</div></div>' +
    '<div style="background:var(--card);border-radius:12px;padding:12px;box-shadow:var(--shadow);border-left:4px solid #eab308"><div style="font-size:24px;font-weight:700;color:#eab308">'+s.month+'</div><div style="font-size:11px;color:var(--muted)">This Month</div></div>' +
    '<div style="background:var(--card);border-radius:12px;padding:12px;box-shadow:var(--shadow);border-left:4px solid var(--green)"><div style="font-size:24px;font-weight:700;color:var(--green)">'+s.plan+'</div><div style="font-size:11px;color:var(--muted)">Planning</div></div></div>';
  var cnt = document.getElementById('fpCnt');
  if (cnt) cnt.textContent = FESTIVALS.length;
}

function fpRender() {
  var mF = document.getElementById('fpMonth');
  var uF = document.getElementById('fpUrg');
  var sF = document.getElementById('fpSearch');
  if (!mF || !uF || !sF) return;
  var monthVal = mF.value;
  var urgVal = uF.value;
  var searchVal = (sF.value || '').toLowerCase();

  var filtered = FESTIVALS.filter(function(f) {
    if (monthVal && f.month !== parseInt(monthVal)) return false;
    var urg = fpUrg(f.date);
    if (urgVal && urg !== urgVal) return false;
    if (searchVal) {
      var hay = (f.name + ' ' + f.nameEn + ' ' + f.products.map(function(p){return p.sku+' '+p.skuEn}).join(' ')).toLowerCase();
      if (hay.indexOf(searchVal) < 0) return false;
    }
    return true;
  });

  var byMonth = {};
  filtered.forEach(function(f) {
    if (!byMonth[f.month]) byMonth[f.month] = [];
    byMonth[f.month].push(f);
  });

  var months = [{n:1,l:'Jan'},{n:2,l:'Feb'},{n:3,l:'Mar'},{n:4,l:'Apr'},{n:5,l:'May'},{n:6,l:'Jun'},{n:7,l:'Jul'},{n:8,l:'Aug'},{n:9,l:'Sep'},{n:10,l:'Oct'},{n:11,l:'Nov'},{n:12,l:'Dec'}];
  var urgColors = {urgent:'var(--red)',week:'var(--orange)',month:'#eab308',plan:'var(--green)',past:'#8e8e93'};
  var impBg = {s:'#FF2D5515',a:'#FF950015',b:'#007AFF15'};
  var impFg = {s:'var(--red)',a:'var(--orange)',b:'var(--blue)'};

  var html = '';
  months.forEach(function(m) {
    if (!byMonth[m.n]) return;
    var fests = byMonth[m.n].sort(function(a,b){return new Date(a.date)-new Date(b.date)});
    html += '<div style="margin-bottom:24px"><h2 style="font-size:18px;font-weight:700;margin-bottom:12px;padding-bottom:8px;border-bottom:2px solid var(--border)">'+m.l+' <span style="font-size:13px;color:var(--muted);font-weight:400">('+fests.length+')</span></h2><div style="display:flex;flex-direction:column;gap:12px">';
    fests.forEach(function(f) {
      var urg = fpUrg(f.date);
      var imp = (f.importance||'B').toLowerCase();
      html += '<div style="background:var(--card);border-radius:var(--r);box-shadow:var(--shadow);overflow:hidden;border-left:4px solid '+urgColors[urg]+'" onclick="var d=this.querySelector(\'.fd\');d.style.display=d.style.display===\'block\'?\'none\':\'block\'">';
      html += '<div style="padding:14px 18px;cursor:pointer;display:flex;align-items:center;gap:12px">';
      html += '<span style="font-size:28px">'+f.icon+'</span><div style="flex:1;min-width:0">';
      html += '<div style="font-size:16px;font-weight:700">'+f.name+' <span style="font-size:11px;color:var(--muted)">'+f.nameEn+'</span></div>';
      html += '<div style="display:flex;gap:8px;margin-top:4px;flex-wrap:wrap;align-items:center">';
      html += '<span style="padding:2px 8px;border-radius:6px;font-size:11px;font-weight:700;background:'+impBg[imp]+';color:'+impFg[imp]+'">'+f.importance+'</span>';
      html += '<span style="font-size:12px;color:var(--muted)">'+f.date+'</span>';
      html += '<span style="font-size:12px;color:var(--muted)">'+f.products.length+' SKUs</span>';
      html += '</div></div>';
      html += '<span style="padding:3px 10px;border-radius:8px;font-size:12px;font-weight:700;background:'+urgColors[urg]+';color:#fff">'+fpDays(f.date)+'</span>';
      html += '<span style="font-size:18px;color:var(--muted)">&#9654;</span></div>';
      html += '<div class="fd" style="display:none;padding:0 18px 14px">';
      html += '<table style="width:100%;border-collapse:collapse;font-size:12px;margin-top:8px">';
      html += '<tr style="background:#f8f8fa"><th style="text-align:left;padding:6px 8px;color:var(--muted);font-weight:600;border-bottom:1px solid var(--border)">SKU</th><th style="text-align:left;padding:6px 8px;color:var(--muted);font-weight:600;border-bottom:1px solid var(--border)">Cat</th><th style="text-align:left;padding:6px 8px;color:var(--muted);font-weight:600;border-bottom:1px solid var(--border)">Cost</th><th style="text-align:left;padding:6px 8px;color:var(--muted);font-weight:600;border-bottom:1px solid var(--border)">Price</th><th style="text-align:left;padding:6px 8px;color:var(--muted);font-weight:600;border-bottom:1px solid var(--border)">Margin</th><th style="text-align:left;padding:6px 8px;color:var(--muted);font-weight:600;border-bottom:1px solid var(--border)">Risk</th><th style="text-align:left;padding:6px 8px;color:var(--muted);font-weight:600;border-bottom:1px solid var(--border)">1688</th></tr>';
      f.products.forEach(function(p) {
        var rc = p.riskLevel === 'low' ? 'var(--green)' : p.riskLevel === 'medium' ? 'var(--orange)' : 'var(--red)';
        var kw = p.sourcing ? p.sourcing.replace('1688: ','') : '';
        html += '<tr style="border-bottom:1px solid #f0f0f5"><td style="padding:6px 8px"><div style="font-weight:600">'+p.sku+'</div><div style="color:var(--muted);font-size:11px">'+p.skuEn+'</div></td>';
        html += '<td style="padding:6px 8px;color:var(--muted)">'+p.category+'</td>';
        html += '<td style="padding:6px 8px">'+p.costRange+'</td>';
        html += '<td style="padding:6px 8px">'+p.priceRange+'</td>';
        html += '<td style="padding:6px 8px;font-weight:600;color:var(--green)">'+p.margin+'</td>';
        html += '<td style="padding:6px 8px;color:'+rc+'">'+p.riskLevel+'</td>';
        html += '<td style="padding:6px 8px"><a href="https://s.1688.com/selloffer/offer_search.htm?keywords='+encodeURIComponent(kw)+'" target="_blank" style="color:var(--blue);font-size:11px">Search</a></td></tr>';
      });
      html += '</table>';
      if (f.validation) {
        html += '<div style="background:#eff6ff;border-radius:8px;padding:10px;margin-top:10px;font-size:12px">';
        html += '<div style="font-weight:600;color:var(--blue);margin-bottom:4px">Validation</div>';
        if (f.validation.amazonCheck) html += '<div>Amazon: '+f.validation.amazonCheck+'</div>';
        if (f.validation.sourcing) html += '<div>1688: '+f.validation.sourcing+'</div>';
        html += '</div>';
      }
      html += '</div></div>';
    });
    html += '</div></div>';
  });
  document.getElementById('fpMain').innerHTML = html || '<div style="text-align:center;padding:40px;color:var(--muted)">No matching festivals</div>';
}

fpDash();
fpRender();
document.getElementById('fpMonth').addEventListener('change', fpRender);
document.getElementById('fpUrg').addEventListener('change', fpRender);
document.getElementById('fpSearch').addEventListener('input', function(){setTimeout(fpRender,200)});
</script>
"@

# Insert before </body>
$result = $platform.Replace('</body>', $festScript + '</body>')

# Write with UTF-8 no BOM
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText('output\platform.html', $result, $utf8NoBom)

Write-Host "Done! Lines: $($result.Split("`n").Count)"
