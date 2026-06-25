Push-Location 'D:\软件\Zcode工作区\product-radar'
$lines = Get-Content 'source.html'
Write-Host "Read $($lines.Count) lines"

# Use Set-Content with encoding
$lines[429..467] | Set-Content 'fest_config.js' -Encoding UTF8
Write-Host "CONFIG done"

$lines[472..1775] | Set-Content 'fest_data.js' -Encoding UTF8
Write-Host "FESTIVALS done"

$lines[1780..1849] | Set-Content 'fest_state.js' -Encoding UTF8
Write-Host "State done"

$lines[1851..1929] | Set-Content 'fest_utils.js' -Encoding UTF8
Write-Host "Utils done"

$lines[1931..2154] | Set-Content 'fest_render.js' -Encoding UTF8
Write-Host "Render done"

$lines[2156..2248] | Set-Content 'fest_interact.js' -Encoding UTF8
Write-Host "Interact done"

$lines[2250..2399] | Set-Content 'fest_export.js' -Encoding UTF8
Write-Host "Export done"

Write-Host "All extracted!"
Pop-Location
