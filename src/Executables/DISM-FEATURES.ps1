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
            Disable-WindowsOptionalFeature -Online -FeatureName $featureName -NoRestart
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
