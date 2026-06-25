Set-Location 'D:\软件\Zcode工作区\product-radar'
$content = [System.IO.File]::ReadAllText('output\platform.html', [System.Text.Encoding]::UTF8)

# Extract the festival script block
$start = $content.IndexOf('<script>') + 8
$end = $content.IndexOf('</script>', $start)
$festScript = $content.Substring($start, $end - $start)

# Try to find the FESTIVALS array end
$festStart = $festScript.IndexOf('const FESTIVALS = [')
$festEnd = $festScript.IndexOf('];', $festStart) + 2
$festArray = $festScript.Substring($festStart, $festEnd - $festStart)

# Count opening and closing brackets
$openBrackets = ([regex]::Matches($festArray, '\[')).Count
$closeBrackets = ([regex]::Matches($festArray, '\]')).Count
$openBraces = ([regex]::Matches($festArray, '\{')).Count
$closeBraces = ([regex]::Matches($festArray, '\}')).Count

Write-Host "FESTIVALS array length: $($festArray.Length) chars"
Write-Host "Square brackets: open=$openBrackets close=$closeBrackets diff=$($openBrackets - $closeBrackets)"
Write-Host "Curly braces: open=$openBraces close=$closeBraces diff=$($openBraces - $closeBraces)"

# Check for common syntax issues
$unclosedStrings = ([regex]::Matches($festArray, '"[^"]*$', [System.Text.RegularExpressions.RegexOptions]::Multiline)).Count
Write-Host "Potential unclosed strings: $unclosedStrings"

# Check for commas between objects
$objectCloses = ([regex]::Matches($festArray, '^\s*\}\s*$', [System.Text.RegularExpressions.RegexOptions]::Multiline)).Count
$objectOpens = ([regex]::Matches($festArray, '^\s*\{\s*$', [System.Text.RegularExpressions.RegexOptions]::Multiline)).Count
Write-Host "Object opens: $objectOpens closes: $objectCloses"

# Check the last few characters
Write-Host "Last 50 chars of FESTIVALS array:"
Write-Host $festArray.Substring($festArray.Length - 50)
