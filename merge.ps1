Push-Location 'D:\软件\Zcode工作区\product-radar'

# Read platform.html
$platform = Get-Content 'output\platform.html' -Raw

# Read all extracted parts
$config = Get-Content 'fest_config.js' -Raw
$data = Get-Content 'fest_data.js' -Raw
$state = Get-Content 'fest_state.js' -Raw
$utils = Get-Content 'fest_utils.js' -Raw
$render = Get-Content 'fest_render.js' -Raw
$interact = Get-Content 'fest_interact.js' -Raw
$export = Get-Content 'fest_export.js' -Raw

# Build the festival module
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

// Festival filter bindings
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

# Find the </script> tag and insert before it
$insertPoint = $platform.LastIndexOf('</script>')
$result = $platform.Substring(0, $insertPoint) + "`n" + $festModule + "`n" + $platform.Substring($insertPoint)

# Also update renderAll to call initFestival
$result = $result.Replace('renderDiscovery();`n  renderRadar();`n  renderFestival();', 'renderDiscovery();`n  renderRadar();`n  initFestival();')

# Write result
[System.IO.File]::WriteAllLines('output\platform.html', $result.Split("`n"), [System.Text.Encoding]::UTF8)
Write-Host "Done! Output: $($result.Length) chars"

Pop-Location
