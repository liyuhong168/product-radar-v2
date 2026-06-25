Set-Location 'D:\软件\Zcode工作区\product-radar'

# Read source file with UTF-8
$src = [System.IO.File]::ReadAllText('source.html', [System.Text.Encoding]::UTF8)

# Extract just the FESTIVALS array (from "const FESTIVALS = [" to "];")
$startIdx = $src.IndexOf("const FESTIVALS = [")
$endIdx = $src.IndexOf("];`n", $startIdx) + 3
$festivalsBlock = $src.Substring($startIdx, $endIdx - $startIdx)

Write-Host "FESTIVALS block: $($festivalsBlock.Length) chars"
Write-Host "First 100 chars: $($festivalsBlock.Substring(0, 100))"
Write-Host "Last 100 chars: $($festivalsBlock.Substring($festivalsBlock.Length - 100))"

# Write to a separate file for testing
[System.IO.File]::WriteAllText('festivals_only.js', $festivalsBlock, [System.Text.Encoding]::UTF8)
Write-Host "Written to festivals_only.js"

# Check the file
$testFile = [System.IO.File]::ReadAllText('festivals_only.js', [System.Text.Encoding]::UTF8)
Write-Host "File size: $($testFile.Length) chars"
Write-Host "Starts with: $($testFile.Substring(0, 50))"
Write-Host "Ends with: $($testFile.Substring($testFile.Length - 20))"
