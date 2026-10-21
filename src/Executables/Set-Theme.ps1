param (
    [Parameter(Mandatory = $true, ParameterSetName = 'SetExistingTheme')]
    [string]$Path,

    [Parameter(Mandatory = $true, ParameterSetName = 'NewCustomTheme')]
    [hashtable]$New
)

if (-not ([Security.Principal.WindowsPrincipal] `
            [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
            [Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "This script must be run as Administrator. Exiting."
    exit 1
}

function Set-ExistingTheme {
    param ([string]$ThemePath)
    
    if (-not (Test-Path $ThemePath)) {
        Write-Error "Theme file not found at: $ThemePath"
        exit 1
    }
    
    Write-Host "Applying existing theme from: $ThemePath"
    
    $regPathTemplate = "Registry::HKEY_USERS\{0}\Software\Microsoft\Windows\CurrentVersion\Themes"
    
    Get-ChildItem Registry::HKEY_USERS | ForEach-Object {
        $sid = $_.PSChildName
        if ($sid -notmatch '(_Classes|^\.DEFAULT$)') {
            $themeKey = $regPathTemplate -f $sid
            if (-not (Test-Path $themeKey)) {
                New-Item -Path $themeKey -Force | Out-Null
            }
            Set-ItemProperty -Path $themeKey -Name "CurrentTheme" -Value $ThemePath
            Write-Host "Theme assigned for user SID: $sid"
        }
    }
    
    Start-Process -FilePath $ThemePath
}

function New-CustomTheme {
    param ([hashtable]$Config)
    
    if (-not $Config.ContainsKey('WallpaperPath')) {
        Write-Error "WallpaperPath is required in the hashtable"
        exit 1
    }
    
    $wallpaperPath = $Config['WallpaperPath']
    $themeExportPath = if ($Config.ContainsKey('ThemeExportPath')) { $Config['ThemeExportPath'] } else { "$env:SystemRoot\Resources\Themes\mithen.theme" }
    $systemMode = if ($Config.ContainsKey('SystemMode')) { $Config['SystemMode'] } else { 'Dark' }
    $appMode = if ($Config.ContainsKey('AppMode')) { $Config['AppMode'] } else { 'Dark' }
    
    if ($systemMode -notin @('Dark', 'Light')) {
        Write-Error "SystemMode must be 'Dark' or 'Light'"
        exit 1
    }
    if ($appMode -notin @('Dark', 'Light')) {
        Write-Error "AppMode must be 'Dark' or 'Light'"
        exit 1
    }
    
    if (-not (Test-Path $wallpaperPath)) {
        Write-Error "Wallpaper file not found at: $wallpaperPath"
        exit 1
    }
    
    $themesDir = "$env:SystemRoot\Resources\Themes"
    $baseTheme = if ($systemMode -eq 'Dark') { "$themesDir\dark.theme" } else { "$themesDir\aero.theme" }
    if (-not (Test-Path $baseTheme)) {
        Write-Error "Base theme not found at: $baseTheme"
        exit 1
    }
    
    Copy-Item -Path $baseTheme -Destination $themeExportPath -Force

    # Strip the [Sounds] section: the base theme carries the Windows Default sound
    # scheme, and applying it restores every event sound. The playbook sets the
    # "No Sounds" scheme separately, so the theme must not touch sounds at all.
    $lines = Get-Content $themeExportPath
    $kept = @()
    $skipSounds = $false
    foreach ($line in $lines) {
        if ($line -match '^\s*\[Sounds\]') {
            $skipSounds = $true
            continue
        }
        if ($skipSounds) {
            if ($line -match '^\s*\[') {
                $skipSounds = $false
            }
            else {
                continue
            }
        }
        $kept += $line
    }

    $kept | ForEach-Object {
        switch -Regex ($_) {
            '^Wallpaper=' { "Wallpaper=$wallpaperPath" }
            '^SystemMode=' { "SystemMode=$systemMode" }
            '^AppMode=' { "AppMode=$appMode" }
            default { $_ }
        }
    } | Set-Content $themeExportPath
    
    Write-Host "Custom theme created at $themeExportPath"
    
    Set-ExistingTheme -ThemePath $themeExportPath
}

switch ($PSCmdlet.ParameterSetName) {
    'SetExistingTheme' {
        Set-ExistingTheme -ThemePath $Path
    }
    'NewCustomTheme' {
        New-CustomTheme -Config $New
    }
}