Push-Location 'D:\软件\Zcode工作区\product-radar'

# Read source with explicit UTF-8 encoding
$src = [System.IO.File]::ReadAllText('source.html', [System.Text.Encoding]::UTF8)
$srcLines = $src.Split("`n")
Write-Host "Read $($srcLines.Count) lines"

# Check encoding of first Chinese line
Write-Host "Sample: $($srcLines[477])"

# Extract CONFIG (lines 430-468, 0-indexed 429-467)
$cfg = ($srcLines[429..467] -join "`n")
[System.IO.File]::WriteAllText('fest_config.js', $cfg, [System.Text.Encoding]::UTF8)
Write-Host "CONFIG done"

# Extract FESTIVALS (lines 473-1776, 0-indexed 472-1775)
$fest = ($srcLines[472..1775] -join "`n")
[System.IO.File]::WriteAllText('fest_data.js', $fest, [System.Text.Encoding]::UTF8)
Write-Host "FESTIVALS done: $($fest.Length) chars"

# Extract State (lines 1781-1850, 0-indexed 1780-1849)
$st = ($srcLines[1780..1849] -join "`n")
[System.IO.File]::WriteAllText('fest_state.js', $st, [System.Text.Encoding]::UTF8)
Write-Host "State done"

# Extract Utils (lines 1852-1930, 0-indexed 1851-1929)
$ut = ($srcLines[1851..1929] -join "`n")
[System.IO.File]::WriteAllText('fest_utils.js', $ut, [System.Text.Encoding]::UTF8)
Write-Host "Utils done"

# Extract Render (lines 1932-2155, 0-indexed 1931-2154)
$rd = ($srcLines[1931..2154] -join "`n")
[System.IO.File]::WriteAllText('fest_render.js', $rd, [System.Text.Encoding]::UTF8)
Write-Host "Render done"

# Extract Interact (lines 2157-2249, 0-indexed 2156-2248)
$it = ($srcLines[2156..2248] -join "`n")
[System.IO.File]::WriteAllText('fest_interact.js', $it, [System.Text.Encoding]::UTF8)
Write-Host "Interact done"

# Extract Export (lines 2251-2400, 0-indexed 2250-2399)
$ex = ($srcLines[2250..2399] -join "`n")
[System.IO.File]::WriteAllText('fest_export.js', $ex, [System.Text.Encoding]::UTF8)
Write-Host "Export done"

# Verify Chinese characters
$testLine = ($srcLines[477])
Write-Host "Verify: $testLine"

Pop-Location
