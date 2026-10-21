function Install-MithenApp {
    param(
        [string]$Name,
        [string]$Url,
        [string]$File,
        # Not named $Args on purpose: that is an automatic variable and the value passed in arrives as null
        [string[]]$SilentArgs,
        [string[]]$FallbackArgs
    )

    $installed = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*' -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -like "$Name*" }

    if ($installed) {
        Write-Host "$Name is already installed. Skipping."
        return
    }

    try {
        Write-Host "Downloading $Name"
        Invoke-WebRequest -Uri $Url -OutFile $File -UseBasicParsing

        $path = Join-Path (Get-Location) $File
        $timeoutSeconds = 180

        foreach ($flags in @($SilentArgs, $FallbackArgs)) {
            if (-not $flags) {
                continue
            }

            Write-Host "Installing $Name with $($flags -join ' ')"
            $process = Start-Process -FilePath $path -ArgumentList $flags -PassThru

            # An installer that opens a dialog never returns and an unattended run has
            # nothing to dismiss it with, so the wait has to be bounded
            if (-not $process.WaitForExit($timeoutSeconds * 1000)) {
                Write-Host "$Name`: installer did not finish within $timeoutSeconds seconds, killing it"
                Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
                Get-Process -Name ([System.IO.Path]::GetFileNameWithoutExtension($File)) -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
                continue
            }

            if ($process.ExitCode -eq 0) {
                Write-Host "$Name installed"
                return
            }

            Write-Host "$Name`: installer exited with $($process.ExitCode)"
        }

        Write-Host "Failed to install $Name"
    }
    catch {
        Write-Host "Failed to install ${Name}: $($_.Exception.Message)"
    }
}

# Silent flags taken from each app's own installer source:
#   MithenView   - NSIS (dist/scripts/installer.nsi)                 -> /S
#   MithenPDF    - custom SumatraPDF-based (src/Installer.cpp)       -> -silent
#   MithenPlayer - Inno Setup (distrib/mpc-be_setup.iss)             -> /VERYSILENT /NORESTART
#   MithenZip    - custom 7-Zip-based (Installer/MithenZipSetup.cpp) -> /s
$apps = @(
    @{
        Name         = 'MithenView'
        Url          = 'https://github.com/catchem88/mithen-view/releases/latest/download/MithenView-setup.exe'
        File         = 'MithenView-setup.exe'
        Args         = @('/S')
        FallbackArgs = @('/VERYSILENT', '/NORESTART')
    },
    @{
        Name         = 'MithenPDF'
        Url          = 'https://github.com/catchem88/mithen-pdf/releases/latest/download/MithenPDF-setup.exe'
        File         = 'MithenPDF-setup.exe'
        Args         = @('-silent')
        FallbackArgs = @('/silent')
    },
    @{
        Name         = 'MithenPlayer'
        Url          = 'https://github.com/catchem88/mithen-player/releases/latest/download/MithenPlayer-setup.exe'
        File         = 'MithenPlayer-setup.exe'
        Args         = @('/VERYSILENT', '/NORESTART', '/TASKS=!desktopicon')
        FallbackArgs = @('/S')
    },
    @{
        Name         = 'MithenMusic'
        Url          = 'https://github.com/catchem88/mithen-music/releases/latest/download/MithenMusic-setup.exe'
        File         = 'MithenMusic-setup.exe'
        Args         = @('/S')
        FallbackArgs = @('/VERYSILENT', '/NORESTART')
    },
    @{
        Name         = 'MithenZip'
        Url          = 'https://github.com/catchem88/mithen-zip/releases/latest/download/MithenZip-setup.exe'
        File         = 'MithenZip-setup.exe'
        Args         = @('/s')
        FallbackArgs = @('/S', '/VERYSILENT', '/NORESTART')
    }
)

foreach ($app in $apps) {
    Install-MithenApp -Name $app.Name -Url $app.Url -File $app.File -SilentArgs $app.Args -FallbackArgs $app.FallbackArgs
}

# No desktop icons
foreach ($desktop in @((Join-Path $env:PUBLIC 'Desktop'), (Join-Path $env:USERPROFILE 'Desktop'))) {
    Get-ChildItem -Path $desktop -Filter 'Mithen*.lnk' -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
}
