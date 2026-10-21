# Applies the "No Sounds" scheme and silences every event.
# The value the Sounds dialog and Windows actually use is the DEFAULT value of
# each event's .Current subkey (empty = no sound). Setting the event key's own
# default, or deleting .Current values, leaves the previous sound in place.
$schemeKey = 'HKCU:\AppEvents\Schemes'
if (-not (Test-Path $schemeKey)) {
    Write-Host 'AppEvents missing, nothing to do'
    exit 0
}

Set-ItemProperty -LiteralPath $schemeKey -Name '(default)' -Value '.None'

$names = Join-Path $schemeKey 'Names'
if (-not (Test-Path $names)) {
    New-Item -Path $names -Force | Out-Null
}
if (-not (Test-Path (Join-Path $names '.None'))) {
    New-Item -Path (Join-Path $names '.None') -Force | Out-Null
}
Set-ItemProperty -LiteralPath (Join-Path $names '.None') -Name '(default)' -Value 'No Sounds'

$silenced = 0
foreach ($app in (Get-ChildItem (Join-Path $schemeKey 'Apps') -ErrorAction SilentlyContinue)) {
    foreach ($event in (Get-ChildItem $app.PSPath -ErrorAction SilentlyContinue)) {
        $current = Join-Path $event.PSPath '.Current'
        if (-not (Test-Path $current)) {
            New-Item -Path $current -Force | Out-Null
        }
        Set-ItemProperty -LiteralPath $current -Name '(default)' -Value '' -ErrorAction SilentlyContinue
        $silenced++
    }
}

Write-Host "Sound scheme set to No Sounds, events silenced: $silenced"
