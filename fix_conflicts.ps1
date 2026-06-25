Push-Location 'D:\软件\Zcode工作区\product-radar'

$content = [System.IO.File]::ReadAllText('output\platform.html', [System.Text.Encoding]::UTF8)

# Find the festival module start (after "// Festival Planner Module")
$festStart = $content.IndexOf('// Festival Planner Module')
if ($festStart -lt 0) { Write-Host "ERROR: Festival module not found"; exit 1 }

# Split into platform part and festival part
$platformPart = $content.Substring(0, $festStart)
$festPart = $content.Substring($festStart)

Write-Host "Platform part: $($platformPart.Length) chars"
Write-Host "Festival part: $($festPart.Length) chars"

# Rename conflicting variables in festival part only
# Order matters: longer names first to avoid partial replacements
$replacements = @(
  @('const CONFIG = ', 'const FP_CONFIG = '),
  @('CONFIG.logisticsModes', 'FP_CONFIG.logisticsModes'),
  @('CONFIG.arrivalBuffer', 'FP_CONFIG.arrivalBuffer'),
  @('CONFIG.defaultLogistics', 'FP_CONFIG.defaultLogistics'),
  @('CONFIG.milestones', 'FP_CONFIG.milestones'),
  @('CONFIG.urgencyThresholds', 'FP_CONFIG.urgencyThresholds'),
  @('CONFIG.categories', 'FP_CONFIG.categories'),
  @('CONFIG.months', 'FP_CONFIG.months'),
  @('CONFIG.storageKey', 'FP_CONFIG.storageKey'),
  @('const State = ', 'const FP_State = '),
  @('State.load()', 'FP_State.load()'),
  @('State.init()', 'FP_State.init()'),
  @('State.save()', 'FP_State.save()'),
  @('State.getFestival', 'FP_State.getFestival'),
  @('State.updateFestival', 'FP_State.updateFestival'),
  @('State.toggleMilestone', 'FP_State.toggleMilestone'),
  @('State.toggleSku', 'FP_State.toggleSku'),
  @('State.export', 'FP_State.export'),
  @('State.import', 'FP_State.import'),
  @('State.reset', 'FP_State.reset'),
  @('State.data', 'FP_State.data'),
  @('const Utils = ', 'const FP_Utils = '),
  @('Utils.parseDate', 'FP_Utils.parseDate'),
  @('Utils.today', 'FP_Utils.today'),
  @('Utils.diffDays', 'FP_Utils.diffDays'),
  @('Utils.fmtMD', 'FP_Utils.fmtMD'),
  @('Utils.fmtYMD', 'FP_Utils.fmtYMD'),
  @('Utils.getSelectionDeadline', 'FP_Utils.getSelectionDeadline'),
  @('Utils.getMilestoneDates', 'FP_Utils.getMilestoneDates'),
  @('Utils.getUrgency', 'FP_Utils.getUrgency'),
  @('Utils.urgencyLabel', 'FP_Utils.urgencyLabel'),
  @('Utils.stars', 'FP_Utils.stars'),
  @('Utils.escape', 'FP_Utils.escape'),
  @('Utils.debounce', 'FP_Utils.debounce'),
  @('const Render = ', 'const FP_Render = '),
  @('Render.monthNav', 'FP_Render.monthNav'),
  @('Render.dashboard', 'FP_Render.dashboard'),
  @('Render.main', 'FP_Render.main'),
  @('Render.festivalCard', 'FP_Render.festivalCard'),
  @('const Interact = ', 'const FP_Interact = '),
  @('Interact.applyFilter', 'FP_Interact.applyFilter'),
  @('Interact.resetFilter', 'FP_Interact.resetFilter'),
  @('Interact.switchLogistics', 'FP_Interact.switchLogistics'),
  @('Interact.toggleMilestone', 'FP_Interact.toggleMilestone'),
  @('Interact.toggleSku', 'FP_Interact.toggleSku'),
  @('Interact.setStatus', 'FP_Interact.setStatus'),
  @('Interact.setNotes', 'FP_Interact.setNotes'),
  @('Interact.filterProductCat', 'FP_Interact.filterProductCat'),
  @('const Filter = ', 'const FP_Filter = '),
  @('Filter.category', 'FP_Filter.category'),
  @('Filter.month', 'FP_Filter.month'),
  @('Filter.urgency', 'FP_Filter.urgency'),
  @('Filter.status', 'FP_Filter.status'),
  @('Filter.search', 'FP_Filter.search'),
  @('Filter.statCardUrgency', 'FP_Filter.statCardUrgency')
)

foreach ($r in $replacements) {
  $festPart = $festPart.Replace($r[0], $r[1])
}

# Also update initFestival to use FP_ names
$festPart = $festPart.Replace('State.load()', 'FP_State.load()')
$festPart = $festPart.Replace('Render.monthNav()', 'FP_Render.monthNav()')
$festPart = $festPart.Replace('Render.dashboard()', 'FP_Render.dashboard()')
$festPart = $festPart.Replace('Render.main()', 'FP_Render.main()')

# Recombine
$result = $platformPart + $festPart

# Write with UTF-8 no BOM
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText('output\platform.html', $result, $utf8NoBom)

Write-Host "Done! Output: $($result.Length) chars"

# Verify no remaining conflicts
$conflicts = @('const CONFIG = ', 'const State = ', 'const Utils = ', 'const Render = ', 'const Interact = ')
foreach ($c in $conflicts) {
  $count = ([regex]::Matches($result, [regex]::Escape($c))).Count
  Write-Host "'$c' count: $count"
}

Pop-Location
