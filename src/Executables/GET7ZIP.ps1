# Pinned to the 7-zip.org URL in case the GitHub release lookup fails
$fallbackUrl = 'https://www.7-zip.org/a/7z2606-x64.exe'
$destination = Join-Path (Get-Location) '7z-installer-x64.exe'
$headers = @{ 'User-Agent' = 'MithenOS' }

$downloaded = $false
try {
    $release = Invoke-RestMethod -Uri 'https://api.github.com/repos/ip7z/7zip/releases/latest' -Headers $headers -UseBasicParsing
    $asset = $release.assets | Where-Object { $_.name -match '^7z\d+-x64\.exe$' } | Select-Object -First 1
    if (-not $asset) {
        throw 'No x64 installer asset in the latest release'
    }

    Write-Host "Downloading 7-Zip $($release.tag_name)"
    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $destination -UseBasicParsing
    $downloaded = $true
} catch {
    Write-Host "Latest release lookup failed: $($_.Exception.Message)"
}

if (-not $downloaded) {
    Write-Host 'Falling back to the pinned download URL'
    try {
        Invoke-WebRequest -Uri $fallbackUrl -OutFile $destination -UseBasicParsing
    } catch {
        Write-Host "7-Zip download failed: $($_.Exception.Message)"
    }
}

if (-not (Test-Path -LiteralPath $destination)) {
    Write-Host '7-Zip installer is not available'
    exit 1
}

if ((Get-Item -LiteralPath $destination).Length -lt 500KB) {
    Write-Host '7-Zip installer download looks truncated'
    exit 1
}

Write-Host "7-Zip installer ready: $destination"
