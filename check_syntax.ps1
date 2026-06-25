Set-Location 'D:\软件\Zcode工作区\product-radar'
$html = Get-Content 'output\platform.html' -Raw
$match = [regex]::Match($html, '<script>([\s\S]*?)</script>')
if ($match.Success) {
  $js = $match.Groups[1].Value
  Write-Host "Script length: $($js.Length)"
  $ob = ([regex]::Matches($js, [char]123)).Count
  $cb = ([regex]::Matches($js, [char]125)).Count
  $osb = ([regex]::Matches($js, [char]91)).Count
  $csb = ([regex]::Matches($js, [char]93)).Count
  Write-Host "Curly braces: open=$ob close=$cb diff=$($ob-$cb)"
  Write-Host "Square brackets: open=$osb close=$csb diff=$($osb-$csb)"
  if ($ob -ne $cb) { Write-Host "ERROR: Unbalanced curly braces!" }
  if ($osb -ne $csb) { Write-Host "ERROR: Unbalanced square brackets!" }
} else {
  Write-Host "No script block found"
}
