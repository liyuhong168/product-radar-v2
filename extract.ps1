$src = Get-Content 'D:\软件\Zcode工作区\index.html' -Raw
$lines = Get-Content 'D:\软件\Zcode工作区\index.html'

# Find line numbers
$configStart = ($lines | Select-String 'const CONFIG = ').LineNumber
$storageKey = ($lines | Select-String 'storageKey:').LineNumber | Select-Object -Last 1
$stateStart = ($lines | Select-String 'const State = ').LineNumber
$stateEnd = ($lines | Select-String 'reset\(\) \{').LineNumber | Select-Object -Last 1
$utilsStart = ($lines | Select-String 'const Utils = ').LineNumber
$utilsEnd = ($lines | Select-String '^\};$').LineNumber | Where-Object { $_ -gt $utilsStart } | Select-Object -First 1
$renderStart = ($lines | Select-String 'const Render = ').LineNumber
$filterStart = ($lines | Select-String '// 筛选栏事件绑定').LineNumber
$interactStart = ($lines | Select-String 'const Interact = ').LineNumber
$exportStart = ($lines | Select-String 'function exportData').LineNumber
$scrollStart = ($lines | Select-String '// 回到顶部按钮显隐').LineNumber

Write-Output "configStart=$configStart storageKey=$storageKey stateStart=$stateStart stateEnd=$stateEnd"
Write-Output "utilsStart=$utilsStart utilsEnd=$utilsEnd renderStart=$renderStart"
Write-Output "filterStart=$filterStart interactStart=$interactStart exportStart=$exportStart scrollStart=$scrollStart"

# Extract FESTIVALS (already done, verify)
$fest = Get-Content 'D:\软件\Zcode工作区\product-radar\festivals_data.js' -Raw
Write-Output "FESTIVALS data: $($fest.Length) chars"
