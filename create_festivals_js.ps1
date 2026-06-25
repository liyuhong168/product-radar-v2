Set-Location 'D:\软件\Zcode工作区\product-radar'

# Read source file
$src = [System.IO.File]::ReadAllText('source.html', [System.Text.Encoding]::UTF8)

# Extract FESTIVALS array
$startIdx = $src.IndexOf("const FESTIVALS = [")
$endIdx = $src.IndexOf("];`n", $startIdx) + 3
$festivalsBlock = $src.Substring($startIdx, $endIdx - $startIdx)

# Write to festivals.js with UTF-8 no BOM
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText('output\festivals.js', $festivalsBlock, $utf8NoBom)

Write-Host "festivals.js: $($festivalsBlock.Length) chars"

# Verify
$test = [System.IO.File]::ReadAllText('output\festivals.js', [System.Text.Encoding]::UTF8)
Write-Host "Verify starts: $($test.Substring(0, 50))"
Write-Host "Verify ends: $($test.Substring($test.Length - 30))"
