function Update-Feature {
    param(
        [string]$featureName,
        [bool]$bool
    )
    
    $feature = Get-WindowsOptionalFeature -Online -FeatureName $featureName -ErrorAction SilentlyContinue
    if ($null -eq $feature) {
        Write-Host "Skipping $featureName (not available on this system)"
        return
    }

    $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Notifications\OptionalFeatures"
    $regKey = Get-ItemProperty -Path "$regPath\$featureName" -ErrorAction SilentlyContinue
	
	$dismCmd = if ($bool) { "Enable" } else { "Disable" }
	
    if ($null -eq $regKey -or ($regKey.Selection -eq 0 -and $bool) -or ($regKey.Selection -eq 1 -and !$bool)) {
        Write-Host "$dismCmd $featureName"
        if ($bool) {
            Enable-WindowsOptionalFeature -Online -FeatureName $featureName -NoRestart -All
        } else {
            # -Remove deletes the feature payload so it no longer appears in Windows Features
            Disable-WindowsOptionalFeature -Online -FeatureName $featureName -NoRestart -Remove
        }
    }
}


$features = @(
    @{ Name = "DirectPlay"; Bool = $true },
    @{ Name = "LegacyComponents"; Bool = $true },
    @{ Name = "MicrosoftWindowsPowerShellV2"; Bool = $false },
    @{ Name = "MicrosoftWindowsPowerShellV2Root"; Bool = $false },
    @{ Name = "MSRDC-Infrastructure"; Bool = $false },
    @{ Name = "Printing-Foundation-Features"; Bool = $false },
    @{ Name = "Printing-Foundation-InternetPrinting-Client"; Bool = $false },
    @{ Name = "WorkFolders-Client"; Bool = $false },
    @{ Name = "Printing-XPSServices-Features"; Bool = $false },
    @{ Name = "WindowsMediaPlayer"; Bool = $false },
    @{ Name = "MediaPlayback"; Bool = $false },
    @{ Name = "FaxServicesClientPackage"; Bool = $false }
    # ------> Below: names that only exist on some builds. The guard above skips
    # ------> any feature the running image does not carry.
    @{ Name = "Internet-Explorer-Optional-amd64"; Bool = $false }
    @{ Name = "TabletPCMath"; Bool = $false }
    @{ Name = "LA57Support"; Bool = $false }
    # @{ Name = "SmbDirect"; Bool = $false }
)
foreach ($feature in $features) {
    Update-Feature -featureName $feature.Name -bool $feature.Bool
}

# Remove XPS Viewer and Fax and Scan capabilities
$capabilities = @(
    "XPS.Viewer~~~~0.0.1.0",
    "Print.Fax.Scan~~~~0.0.1.0"
)
foreach ($capability in $capabilities) {
    $state = Get-WindowsCapability -Online -Name $capability -ErrorAction SilentlyContinue
    if ($state -and $state.State -ne "NotPresent") {
        Write-Host "Removing $capability"
        Remove-WindowsCapability -Online -Name $capability -NoRestart | Out-Null
    }
}

# These ship as Feature-on-Demand PACKAGES rather than optional features, so
# Get-WindowsOptionalFeature never lists them (names taken from the tiny11 Core
# builder, which removes the same packages offline).
$packagesToRemove = @(
    'Microsoft-Windows-InternetExplorer-Optional-Package',
    'Microsoft-Windows-Kernel-LA57-FoD-Package',
    'Microsoft-Windows-TabletPCMath-Package',
    'Microsoft-Windows-StepsRecorder-Package',
    # Handwriting only - OCR, speech and text-to-speech are left in place
    'Microsoft-Windows-LanguageFeatures-Handwriting-'
)

$installedPackages = Get-WindowsPackage -Online -ErrorAction SilentlyContinue
foreach ($pattern in $packagesToRemove) {
    # Wrapper stubs are not removable on their own; the payload package carries them.
    $matches = $installedPackages | Where-Object {
        $_.PackageName -like "$pattern*" -and $_.PackageState -eq 'Installed' -and $_.PackageName -notlike '*-Wrapper*'
    }
    foreach ($package in $matches) {
        Write-Host "Removing package $($package.PackageName)"
        try {
            Remove-WindowsPackage -Online -PackageName $package.PackageName -NoRestart -ErrorAction Stop | Out-Null
        }
        catch {
            Write-Host "Could not remove $($package.PackageName): $($_.Exception.Message)"
        }
    }
}
