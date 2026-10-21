# Reports the state of the settings this playbook applies, to the apply log and
# to C:\MithenVerify.txt so they can be read even without the AME log viewer.
$script:report = @()

function Say($text) {
    Write-Host $text
    $script:report += $text
}

Say '=== MithenOS verify ==='

$startKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Start'
if (Test-Path $startKey) {
    $start = Get-ItemProperty $startKey
    Say ('Start: ShowRecentList={0} AllAppsViewMode={1}' -f $start.ShowRecentList, $start.AllAppsViewMode)
    $places = (Get-Item $startKey).GetValue('VisiblePlaces')
    if ($null -eq $places) {
        Say 'Start: VisiblePlaces missing'
    }
    else {
        Say ('Start: VisiblePlaces={0}' -f (($places | ForEach-Object { $_.ToString('X2') }) -join ''))
    }
}
else {
    Say 'Start key missing'
}

$advanced = Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -ErrorAction SilentlyContinue
if ($null -ne $advanced) {
    Say ('Advanced: Start_TrackDocs={0} Start_TrackProgs={1} TaskbarSize={2}' -f $advanced.Start_TrackDocs, $advanced.Start_TrackProgs, $advanced.TaskbarSize)
}

$schemeKey = Get-Item 'HKCU:\AppEvents\Schemes' -ErrorAction SilentlyContinue
$scheme = ''
if ($null -ne $schemeKey) {
    $scheme = $schemeKey.GetValue('')
}
$loud = 0
foreach ($app in (Get-ChildItem 'HKCU:\AppEvents\Schemes\Apps' -ErrorAction SilentlyContinue)) {
    foreach ($event in (Get-ChildItem $app.PSPath -ErrorAction SilentlyContinue)) {
        $current = Join-Path $event.PSPath '.Current'
        if (Test-Path $current) {
            if ((Get-Item $current).GetValue('')) {
                $loud++
            }
        }
    }
}
Say ('Sound: scheme={0} events with a sound={1}' -f $scheme, $loud)

foreach ($path in @((Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Shell\LayoutModification.json'), 'C:\Users\Default\AppData\Local\Microsoft\Windows\Shell\LayoutModification.json')) {
    if (Test-Path $path) {
        Say ('Pins {0}: {1}' -f $path, (Get-Content $path -Raw).Trim())
    }
    else {
        Say ('Pins {0}: missing' -f $path)
    }
}

$startPolicy = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Start' -ErrorAction SilentlyContinue
if ($null -ne $startPolicy -and $null -ne $startPolicy.ConfigureStartPins) {
    Say ('StartPins policy: {0}' -f $startPolicy.ConfigureStartPins)
}
else {
    Say 'StartPins policy: absent'
}
if ($null -ne $startPolicy) {
    Say ('AllowPinnedFolderSettings={0}/{1} AllowPinnedFolderFileExplorer={2}/{3}' -f $startPolicy.AllowPinnedFolderSettings, $startPolicy.AllowPinnedFolderSettings_ProviderSet, $startPolicy.AllowPinnedFolderFileExplorer, $startPolicy.AllowPinnedFolderFileExplorer_ProviderSet)
}

$shortcutRoot = Join-Path $env:ProgramData 'Microsoft\Windows\Start Menu\Programs'
foreach ($name in @('Snipping Tool.lnk', 'Calculator.lnk', 'Microsoft Edge.lnk', 'MithenMusic.lnk', 'MithenTool.lnk')) {
    $path = Join-Path $shortcutRoot $name
    if (Test-Path -LiteralPath $path) {
        Say ('Shortcut {0}: present' -f $name)
    }
    else {
        Say ('Shortcut {0}: missing' -f $name)
    }
}
foreach ($binary in @('SnippingTool.exe', 'win32calc.exe')) {
    $path = Join-Path $env:SystemRoot "System32\$binary"
    if (Test-Path -LiteralPath $path) {
        Say ('Binary {0}: present' -f $binary)
    }
    else {
        Say ('Binary {0}: missing' -f $binary)
    }
}

foreach ($browser in @(@('Edge', 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'), @('Chrome', 'HKLM:\SOFTWARE\Policies\Google\Chrome'))) {
    $name = $browser[0]
    $root = $browser[1]
    $forcelist = (Get-ItemProperty "$root\ExtensionInstallForcelist" -ErrorAction SilentlyContinue).'1'
    if ($forcelist) {
        Say ('Extension {0}: forcelist={1}' -f $name, $forcelist)
    }
    else {
        Say ('Extension {0}: forcelist MISSING' -f $name)
    }
}

if (Test-Path (Join-Path $env:ProgramFiles 'MithenTool\mithentool.exe')) {
    Say 'MithenTool: installed'
}
else {
    Say 'MithenTool: missing'
}

$logs = @(Get-ChildItem -Path @("$env:TEMP\AME", "$env:LOCALAPPDATA\AME", 'C:\ProgramData\AME', 'C:\AME', (Split-Path $PSCommandPath -Parent)) -Recurse -Filter Log.yml -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending | Select-Object -First 3)
if ($logs.Count -gt 0) {
    foreach ($log in $logs) {
        Say ('AME log: {0}' -f $log.FullName)
    }
}
else {
    Say 'AME log: not found in the usual places'
}

Say '=== end verify ==='

foreach ($target in @('C:\MithenVerify.txt', (Join-Path $env:TEMP 'MithenVerify.txt'))) {
    try {
        Set-Content -LiteralPath $target -Value $script:report -Encoding UTF8
    }
    catch {
        Write-Host "Could not write $target"
    }
}

# Leave nothing behind when the apply logged no errors. The newest AME log is the
# run that just finished, so an error anywhere in it keeps the report for review.
$ameLog = Get-ChildItem -Path @('C:\ProgramData\AME\Logs') -Recurse -Filter 'Log.yml' -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending | Select-Object -First 1

if ($null -ne $ameLog) {
    $hasErrors = Select-String -Path $ameLog.FullName -Pattern '^Type: Error' -Quiet
    if ($hasErrors) {
        Write-Host 'Verify: errors were logged, report kept at C:\MithenVerify.txt'
    }
    else {
        Remove-Item -LiteralPath 'C:\MithenVerify.txt' -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath (Join-Path $env:TEMP 'MithenVerify.txt') -Force -ErrorAction SilentlyContinue
        Write-Host 'Verify: no errors logged, report removed'
    }
}
else {
    Write-Host 'Verify: AME log not found, report kept'
}
