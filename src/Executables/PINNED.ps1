# Writes the Start pinned defaults into every deployed LayoutModification.json and
# resets the Start pinning state so Windows actually reads that layout.
# MithenTool and MithenMusic are only pinned when their shortcut exists, so an
# offline install (where the app installers could not run) leaves no dead pins.
$programs = Join-Path $env:ProgramData 'Microsoft\Windows\Start Menu\Programs'

$pins = @(
    '{"packagedAppId":"Microsoft.ScreenSketch_8wekyb3d8bbwe!App"}',
    '{"packagedAppId":"Microsoft.WindowsCamera_8wekyb3d8bbwe!App"}',
    '{"packagedAppId":"Microsoft.WindowsCalculator_8wekyb3d8bbwe!App"}'
)

foreach ($link in @('Microsoft Edge.lnk', 'MithenMusic.lnk', 'MithenTool.lnk')) {
    if (Test-Path -LiteralPath (Join-Path $programs $link)) {
        $pins += '{"desktopAppLink":"%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\' + $link + '"}'
    }
    else {
        Write-Host "Not pinning $link (shortcut missing)"
    }
}

$json = '{"pinnedList":[' + ($pins -join ',') + ']}'

$targets = @(Get-ChildItem -Path 'C:\Users\*\AppData\Local\Microsoft\Windows\Shell\LayoutModification.json' -ErrorAction SilentlyContinue)
foreach ($file in $targets) {
    Set-Content -LiteralPath $file.FullName -Value $json -Encoding UTF8
    Write-Host "Updated $($file.FullName)"
}

# The layout file is only read when Windows (re)initialises the Start pinning
# state, and the Start host rewrites its cache while the session is live - so it
# has to be stopped before the cache is cleared, otherwise the delete is undone.
Get-Process -Name StartMenuExperienceHost -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

$state = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\LocalState'
if (Test-Path $state) {
    Get-ChildItem -LiteralPath $state -Filter 'start*.bin' -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
}

$cache = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\CloudStore\Store\Cache\DefaultAccount'
foreach ($key in @(Get-ChildItem -LiteralPath $cache -ErrorAction SilentlyContinue)) {
    if ($key.PSChildName -like '*start.tilegrid*') {
        Remove-Item -LiteralPath $key.PSPath -Recurse -Force -ErrorAction SilentlyContinue
    }
}
Remove-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Start' -Name 'Config' -ErrorAction SilentlyContinue

Write-Host "Start pinning state cleared; layout: $json"
