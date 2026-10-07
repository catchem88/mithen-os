param()

Add-Type -AssemblyName System.Drawing

$wallpaperDir = Join-Path $env:SystemRoot 'Web\Wallpaper\MithenOS'
New-Item -Path $wallpaperDir -ItemType Directory -Force | Out-Null

# Windows has no solid colour lock screen option, so a plain black image is generated on the fly
$blackImage = Join-Path $wallpaperDir 'black.jpg'
$bitmap = New-Object System.Drawing.Bitmap 1920, 1080
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$graphics.Clear([System.Drawing.Color]::Black)
$bitmap.Save($blackImage, [System.Drawing.Imaging.ImageFormat]::Jpeg)
$graphics.Dispose()
$bitmap.Dispose()

# Desktop: black background colour, in case the wallpaper image is ever removed
Get-ChildItem -Path 'Registry::HKU' | ForEach-Object {
    $userKey = $_.Name
    try {
        [microsoft.win32.registry]::SetValue("$userKey\Control Panel\Colors", 'Background', '0 0 0', [Microsoft.Win32.RegistryValueKind]::String)
        [microsoft.win32.registry]::SetValue("$userKey\Control Panel\Desktop", 'WallPaper', $blackImage, [Microsoft.Win32.RegistryValueKind]::String)
    }
    catch {
        Write-Host "Skipping $userKey : $($_.Exception.Message)"
    }
}

$setwallpapersrc = @"
using System.Runtime.InteropServices;

public class DesktopWallpaper
{
  public const int SetDesktopWallpaper = 20;
  public const int UpdateIniFile = 0x01;
  public const int SendWinIniChange = 0x02;
  [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
  private static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
  public static void SetWallpaper(string path)
  {
    SystemParametersInfo(SetDesktopWallpaper, 0, path, UpdateIniFile | SendWinIniChange);
  }
}
"@
if (-not ([System.Management.Automation.PSTypeName]'DesktopWallpaper').Type) {
    Add-Type -TypeDefinition $setwallpapersrc
}
[DesktopWallpaper]::SetWallpaper($blackImage)

# Lock screen via WinRT
[Windows.System.UserProfile.LockScreen, Windows.System.UserProfile, ContentType = WindowsRuntime] | Out-Null
Add-Type -AssemblyName System.Runtime.WindowsRuntime
$asTaskGeneric = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' })[0]
function Await($WinRtTask, $ResultType) {
    $asTask = $asTaskGeneric.MakeGenericMethod($ResultType)
    $netTask = $asTask.Invoke($null, @($WinRtTask))
    $netTask.Wait(-1) | Out-Null
    $netTask.Result
}
function AwaitAction($WinRtAction) {
    $asTask = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and !$_.IsGenericMethod })[0]
    $netTask = $asTask.Invoke($null, @($WinRtAction))
    $netTask.Wait(-1) | Out-Null
}
[Windows.Storage.StorageFile, Windows.Storage, ContentType = WindowsRuntime] | Out-Null
$tempImage = Join-Path $wallpaperDir ((New-Guid).Guid + '.jpg')
Copy-Item $blackImage $tempImage -Force
$image = Await ([Windows.Storage.StorageFile]::GetFileFromPathAsync($tempImage)) ([Windows.Storage.StorageFile])
AwaitAction ([Windows.System.UserProfile.LockScreen]::SetImageFileAsync($image))
Remove-Item $tempImage -Force

[microsoft.win32.registry]::SetValue(
    'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Personalization',
    'LockScreenImage',
    $blackImage,
    [Microsoft.Win32.RegistryValueKind]::String
)
