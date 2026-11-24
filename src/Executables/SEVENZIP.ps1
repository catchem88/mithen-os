$extensions = @(
    '001', '7z', 'apfs', 'arj', 'bz2', 'bzip2', 'cab', 'cpio', 'deb', 'dmg', 'esd', 'fat',
    'gz', 'gzip', 'hfs', 'lha', 'lzh', 'lzma', 'ntfs', 'rar', 'rpm', 'squashfs', 'swm',
    'tar', 'taz', 'tbz', 'tbz2', 'tgz', 'tpz', 'txz', 'tzst', 'vhd', 'vhdx', 'wim',
    'xar', 'xz', 'z', 'zip', 'zst'
)

# .iso is left to Windows, which mounts it.

$sevenZipRoot = Join-Path $env:ProgramFiles '7-Zip'
if (-not (Test-Path (Join-Path $sevenZipRoot '7zFM.exe'))) {
    Write-Host '7-Zip is not installed; skipping associations'
    return
}

# Same icon Windows uses for a compressed folder
$archiveIcon = Join-Path $env:SystemRoot 'System32\zipfldr.dll'

function Set-ExtensionAssociations {
    param(
        [string]$ClassesRoot
    )

    foreach ($extension in $extensions) {
        $key = Join-Path $ClassesRoot ".$extension"
        New-Item -Path $key -Force -ErrorAction SilentlyContinue | Out-Null
        Set-ItemProperty -Path $key -Name '(default)' -Value "7-Zip.$extension" -ErrorAction SilentlyContinue

        $openWith = Join-Path $key 'OpenWithProgIds'
        New-Item -Path $openWith -Force -ErrorAction SilentlyContinue | Out-Null
        New-ItemProperty -Path $openWith -Name "7-Zip.$extension" -Value ([byte[]]@()) -PropertyType None -Force -ErrorAction SilentlyContinue | Out-Null
    }
}

function Set-ProgIdIcons {
    param(
        [string]$ClassesRoot
    )

    # Only touch ProgIds that exist: creating a stub under HKCU would shadow the machine-wide one
    foreach ($extension in $extensions) {
        $progId = Join-Path $ClassesRoot "7-Zip.$extension"
        if (-not (Test-Path $progId)) {
            continue
        }

        $iconKey = Join-Path $progId 'DefaultIcon'
        New-Item -Path $iconKey -Force -ErrorAction SilentlyContinue | Out-Null
        Set-ItemProperty -Path $iconKey -Name '(default)' -Value $archiveIcon -ErrorAction SilentlyContinue
    }
}

function Remove-UserChoiceKey {
    param(
        [Parameter(Position = 0, Mandatory = $True)]
        [String]
        $Key
    )

    if (-not ('Registry.Utils' -as [type])) {
        $code = @'
  using System;
  using System.Runtime.InteropServices;
  using Microsoft.Win32;

  namespace Registry {
    public class Utils {
      [DllImport("advapi32.dll", SetLastError = true)]
      private static extern int RegOpenKeyEx(UIntPtr hKey, string subKey, int ulOptions, int samDesired, out UIntPtr hkResult);

      [DllImport("advapi32.dll", SetLastError=true, CharSet = CharSet.Unicode)]
      private static extern uint RegDeleteKey(UIntPtr hKey, string subKey);

      public static void DeleteKey(string key) {
        UIntPtr hKey = UIntPtr.Zero;
        RegOpenKeyEx((UIntPtr)0x80000003u, key, 0, 0x20019, out hKey);
        RegDeleteKey((UIntPtr)0x80000003u, key);
      }
     }
   }
'@
        Add-Type -TypeDefinition $code
    }

    [Registry.Utils]::DeleteKey($Key)
}

function Set-UserAssociations {
    param(
        [string]$Hive
    )

    $classesRoot = "HKU:\$Hive\SOFTWARE\Classes"
    Set-ExtensionAssociations -ClassesRoot $classesRoot
    Set-ProgIdIcons -ClassesRoot $classesRoot

    # 4375 = extract, extract here, extract to, test, add to archive, add to .zip
    $options = "HKU:\$Hive\SOFTWARE\7-Zip\Options"
    New-Item -Path $options -Force -ErrorAction SilentlyContinue | Out-Null
    New-ItemProperty -Path $options -Name 'ContextMenu' -Value 4375 -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null

    $toasts = "HKU:\$Hive\SOFTWARE\Microsoft\Windows\CurrentVersion\ApplicationAssociationToasts"
    New-Item -Path $toasts -Force -ErrorAction SilentlyContinue | Out-Null

    foreach ($extension in $extensions) {
        $fileExt = "HKU:\$Hive\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.$extension"
        if (Test-Path "$fileExt\UserChoice") {
            Remove-UserChoiceKey "$Hive\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.$extension\UserChoice"
        }

        New-Item -Path $fileExt -Force -ErrorAction SilentlyContinue | Out-Null
        $toastName = '7-Zip.' + $extension + '_.' + $extension
        New-ItemProperty -Path $toasts -Name $toastName -Value 0 -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null
    }

    Write-Host "Configured 7-Zip associations for $Hive"
}

Write-Host 'Pointing archive formats at 7-Zip'
Set-ExtensionAssociations -ClassesRoot 'HKLM:\SOFTWARE\Classes'
Set-ProgIdIcons -ClassesRoot 'HKLM:\SOFTWARE\Classes'

New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS -ErrorAction SilentlyContinue | Out-Null

Get-ChildItem 'HKU:\' -ErrorAction SilentlyContinue | ForEach-Object {
    $hive = $_.PSChildName
    if (-not (Test-Path "HKU:\$hive\Volatile Environment")) {
        return
    }

    Set-UserAssociations -Hive $hive
}

Write-Host '7-Zip associations configured'
