# Applies the default Start pins through the ConfigureStartPins policy.
# A layout file is only read when Windows creates a profile and AME applies the
# playbook inside an existing session, so the policy is the only supported route.
#
# Each entry is resolved at apply time because the same app can be packaged
# (Store) or a plain Win32 shortcut depending on the image:
#   1. packaged Start app        -> packedAppId
#   2. existing Start shortcut   -> desktopAppLink
#   3. known System32 binary     -> shortcut created here, then pinned
# Anything not found is skipped and logged.
$programs = Join-Path $env:ProgramData 'Microsoft\Windows\Start Menu\Programs'
$userPrograms = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'
$startApps = @(Get-StartApps -ErrorAction SilentlyContinue)
$shell = New-Object -ComObject WScript.Shell

function Get-PackagedAppId($name) {
    $match = $startApps | Where-Object { $_.Name -eq $name -and $_.AppID -like '*!*' } | Select-Object -First 1
    if ($null -eq $match) {
        return $null
    }
    return $match.AppID
}

function Find-StartShortcut($name) {
    foreach ($root in @($programs, $userPrograms)) {
        $hit = Get-ChildItem -LiteralPath $root -Recurse -Filter "$name.lnk" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($null -ne $hit) {
            return $hit.FullName
        }
    }
    return $null
}

function New-StartShortcut($name, $target) {
    $linkPath = Join-Path $programs "$name.lnk"
    try {
        $shortcut = $shell.CreateShortcut($linkPath)
        $shortcut.TargetPath = $target
        $shortcut.Save()
        return $linkPath
    }
    catch {
        Write-Host "Could not create shortcut for $name"
        return $null
    }
}

$pins = @()

foreach ($app in @(
    @('Snipping Tool', "$env:SystemRoot\System32\SnippingTool.exe"),
    @('Camera', "$env:SystemRoot\System32\WindowsCamera.exe"),
    @('Calculator', "$env:SystemRoot\System32\win32calc.exe")
)) {
    $name = $app[0]
    $binary = $app[1]

    $appId = Get-PackagedAppId $name
    if ($appId) {
        $pins += '{"packagedAppId":"' + $appId + '"}'
        continue
    }

    $link = Find-StartShortcut $name
    if (-not $link -and (Test-Path -LiteralPath $binary)) {
        $link = New-StartShortcut $name $binary
    }
    if ($link) {
        $pins += '{"desktopAppLink":"' + $link.Replace('\', '\\') + '"}'
    }
    else {
        Write-Host "Not pinning $name (not installed)"
    }
}

foreach ($link in @('Microsoft Edge.lnk', 'MithenMusic.lnk', 'MithenTool.lnk')) {
    $path = Join-Path $programs $link
    if (Test-Path -LiteralPath $path) {
        $pins += '{"desktopAppLink":"' + $path.Replace('\', '\\') + '"}'
    }
    else {
        Write-Host "Not pinning $link (shortcut missing)"
    }
}

$json = '{"pinnedList":[' + ($pins -join ',') + ']}'
$key = 'HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Start'

if (-not (Test-Path $key)) {
    New-Item -Path $key -Force | Out-Null
}
Set-ItemProperty -LiteralPath $key -Name 'ConfigureStartPins' -Value $json
Set-ItemProperty -LiteralPath $key -Name 'ConfigureStartPins_ProviderSet' -Value 1 -Type DWord
Write-Host "ConfigureStartPins applied: $json"

# Let the Start host pick the policy up in this session
Get-Process -Name StartMenuExperienceHost -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
