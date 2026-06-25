Push-Location 'D:\软件\Zcode工作区\product-radar'

# Read all parts with UTF-8
$platform = [System.IO.File]::ReadAllText('output\platform.html', [System.Text.Encoding]::UTF8)
$config = [System.IO.File]::ReadAllText('fest_config.js', [System.Text.Encoding]::UTF8)
$data = [System.IO.File]::ReadAllText('fest_data.js', [System.Text.Encoding]::UTF8)
$state = [System.IO.File]::ReadAllText('fest_state.js', [System.Text.Encoding]::UTF8)
$utils = [System.IO.File]::ReadAllText('fest_utils.js', [System.Text.Encoding]::UTF8)
$render = [System.IO.File]::ReadAllText('fest_render.js', [System.Text.Encoding]::UTF8)
$interact = [System.IO.File]::ReadAllText('fest_interact.js', [System.Text.Encoding]::UTF8)
$export = [System.IO.File]::ReadAllText('fest_export.js', [System.Text.Encoding]::UTF8)

# Remove BOM if present
if ($data[0] -eq [char]0xFEFF) { $data = $data.Substring(1) }

# Build festival module
$festModule = @"
// ============================================
// Festival Planner Module (from uk-festival-planner)
// ============================================

$config

$data

$state

$utils

$render

$interact

$export

function bindFestFilters() {
  ['fpCatFilter','fpMonthFilter','fpUrgencyFilter','fpStatusFilter'].forEach(id => {
    const el = document.getElementById(id);
    if (el) el.addEventListener('change', () => Render.main());
  });
  const searchEl = document.getElementById('fpSearch');
  if (searchEl) searchEl.addEventListener('input', Utils.debounce(() => { Filter.search = searchEl.value; Render.main(); }, 180));
  const resetEl = document.getElementById('fpReset');
  if (resetEl) resetEl.addEventListener('click', () => Interact.resetFilter());
}

function initFestival() {
  State.load();
  Render.monthNav();
  Render.dashboard();
  Render.main();
  bindFestFilters();
}
"@

# Insert before </script>
$insertPoint = $platform.LastIndexOf('</script>')
$result = $platform.Substring(0, $insertPoint) + "`n" + $festModule + "`n" + $platform.Substring($insertPoint)

# Update renderAll to call initFestival instead of renderFestival
$result = $result.Replace('renderDiscovery();' + "`n" + '  renderRadar();' + "`n" + '  renderFestival();', 'renderDiscovery();' + "`n" + '  renderRadar();' + "`n" + '  initFestival();')

# Write with UTF-8 no BOM
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText('output\platform.html', $result, $utf8NoBom)

Write-Host "Done! Output: $($result.Length) chars, lines: $($result.Split([char]10).Count)"
Pop-Location
