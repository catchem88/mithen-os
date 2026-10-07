function Install-MithenApp {
    param(
        [string]$Name,
        [string]$Url,
        [string]$File,
        [string[]]$Args,
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
        Write-Host "Installing $Name"
        $process = Start-Process -FilePath $path -ArgumentList $Args -Wait -PassThru

        if ($process.ExitCode -ne 0 -and $FallbackArgs) {
            Write-Host "${Name}: primary flags failed (exit $($process.ExitCode)), retrying with fallback flags"
            Start-Process -FilePath $path -ArgumentList $FallbackArgs -Wait
        }
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
        Args         = @('/VERYSILENT', '/NORESTART')
        FallbackArgs = @('/S')
    },
    @{
        Name         = 'MithenZip'
        # v.1.0.0 is currently a pre-release, so /releases/latest/download/ does not resolve for it.
        Url          = 'https://github.com/catchem88/mithen-zip/releases/download/v.1.0.0/MithenZip-setup.exe'
        File         = 'MithenZip-setup.exe'
        Args         = @('/s')
        FallbackArgs = @('/S')
    }
)

foreach ($app in $apps) {
    Install-MithenApp -Name $app.Name -Url $app.Url -File $app.File -Args $app.Args -FallbackArgs $app.FallbackArgs
}
