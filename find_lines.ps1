Set-Location 'D:\软件\Zcode工作区'
$src = Get-Content 'index.html'
Write-Host "Total: $($src.Length)"

for ($i = 0; $i -lt $src.Length; $i++) {
  $line = $src[$i]
  if ($line.Contains('const CONFIG')) { Write-Host "CONFIG=$i" }
  if ($line.Contains('storageKey')) { Write-Host "STORAGEKEY=$i" }
  if ($line.Contains('const State')) { Write-Host "STATE=$i" }
  if ($line.Contains('const Utils')) { Write-Host "UTILS=$i" }
  if ($line.Contains('const Render')) { Write-Host "RENDER=$i" }
  if ($line.Contains('const Interact')) { Write-Host "INTERACT=$i" }
  if ($line.Contains('function exportData')) { Write-Host "EXPORT=$i" }
  if ($line.Contains('FESTIVALS')) { Write-Host "FEST=$i" }
}
