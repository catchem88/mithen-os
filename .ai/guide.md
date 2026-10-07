# MithenOS - Guide

## What this project is

An **AME Wizard playbook** (not an OS image, not a compiled app). All shipped content lives under `src/`; the build packs it into a password-protected archive named `Mithen-PB-<YY.MM>.apbx` (7z, password `malte`).

## Entry points

- `src/playbook.conf` - playbook manifest: identity, supported builds, requirements, bundled software, and the wizard option pages (checkboxes/radios).
- `src/Configuration/main.yml` - the orchestrator: ordered chain of every task.
- `.github/workflows/main.yml` - release pipeline (manual `workflow_dispatch`): stamps the version, downloads `MithenTool-Setup.exe` from `catchem88/mithen-tool`, packs `src/*` with 7z, publishes a release.

## Get started (local build)

1. Need a 7z console binary. This machine has no `7z.exe` on PATH and `C:\Program Files\7-Zip` only holds `7-zip.dll` (shell extension). Working console binaries on this machine:
   - `../BatchConvertToCHD-Forked/BatchConvertToCHD/7za.exe`
   - `C:\Program Files\NVIDIA Corporation\NVIDIA app\7z.exe`
   - `../War of Genesis III - Part 1/Setup/installer/7z.exe`
2. Pack: `7za a -pmalte -mhe=on Mithen-PB-test.apbx ./src/*`
3. Test: drag the `.apbx` into AME Wizard on a clean Windows 10/11 VM.

## Application lifecycle (order in `main.yml`)

`registry/os-info/edition.yml` + `oem-info.yml` -> `start.yml` -> `packages/app-win32.yml` -> `packages/win-sxs.yml` -> `packages/appx.yml` -> explorer/shell task kills -> `software.yml` -> `software-mithen.yml` -> `services.yml` -> `services-manual.yml` -> `registry.yml` -> `revert.yml` -> `final.yml`.

`registry.yml` chains: os-info, explorer (incl. `visual-effects.yml`, `window-snapping.yml`, `explorer-auto-folder-discovery.yml`), privacy (incl. `edge-debloat.yml`, `store-recommended-search.yml`), security, system (incl. `ipv6.yml`, `long-paths.yml`, `numlock.yml`, `game-mode.yml`, `mpo.yml`), updates, misc (incl. `logitech-download-assistant.yml`, `deprovisioned-apps.yml`).

## Languages / technologies

- **AME Wizard playbook YAML** (`!task`, `!registryValue`, `!registryKey`, `!service`, `!appx`, `!powerShell`, `!cmd`, `!run`, `!download`, `!file`, `!taskKill`, `!writeStatus`, `!software`).
- **PowerShell** helper scripts in `src/Executables/`.
- **cmd/batch** helper scripts in `src/Executables/`.
- Companion tool (separate repo `../mithen-tool`): **Flutter/Dart** GUI + CLI (`src/lib/main.dart`, `src/lib/main_cli.dart`), Flutter-Rust bridge (`src/packages/revitool_native`), small C helper (`native_utils/process_checker.c`), **Inno Setup** installer (`inno-setup.iss`).

## Data storage

No database. State lives in the OS: registry, services, scheduled tasks, optional features/capabilities, AppX provisioning (`HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned`), and the hosts file. Mithen-Tool's System Monitor manifest is planned to live in the tool repo.

## Core requirements

- AME Wizard (closed-source frontend; TrustedUninstaller backend).
- 7z (build only), Windows 10 19044/19045 or Windows 11 22631/26100/26200 target.
- Internet during install (VCRedist, Mithen apps, browser install).

## External dependencies

- **Mithen-Tool**: `github.com/catchem88/mithen-tool` (asset `MithenTool-Setup.exe`); local clone at `../mithen-tool`. The playbook calls its CLI at `%ProgramFiles%\Mithen-Tool\mithentool.exe` (`tweaks`, `appx`, `winpackage`, `msstore-apps`, `registry hide-page`).
- **Mithen apps**: `../mithen-view`, `../mithen-pdf`, `../mithen-player`, `../mithen-zip`; downloaded at install time from `releases/latest/download/<Setup>.exe`.
- **WinUtil reference values**: ChrisTitusTech/winutil `config/tweaks.json` and `functions/public/Invoke-WPFUpdatessecurity.ps1`.
- **Atlas reference**: `../atlas-os` (visual-effects value set, Xbox App-only removal).

## Feature / function list

- `Playbook identity and wizard options` - name, GUID, install choices
  - `src/playbook.conf` - identity, supported builds, software packages, checkbox/radio option pages (`remove-edge` now default off, Defender default enable, `install-mithen-apps` default on)
- `Rebranding and OEM information` - visible OS/product naming
  - `src/Configuration/Tasks/registry/os-info/edition.yml` - edition strings
  - `src/Configuration/Tasks/registry/os-info/oem-info.yml` - OEM manufacturer/support info
  - `src/Executables/FINALIZE.cmd` - boot description and RegisteredOrganization
- `Initialization` - hosts, VCRedist, restore point, tool install, power plan
  - `src/Configuration/Tasks/start.yml` - start sequence
  - `src/Executables/hosts` - localhost + Adobe block list (Ruddernation-Designs)
  - `src/Executables/ngen.ps1` - .NET assembly optimization
- `App removal` - win32 + AppX + optional features
  - `src/Configuration/Tasks/packages/app-win32.yml` - Edge, OneDrive, Teams, Copilot
  - `src/Configuration/Tasks/packages/appx.yml` - baked-in AppX list, Photos, Dev Home, Your Phone, Xbox App
  - `src/Configuration/Tasks/packages/win-sxs.yml` - system component removal via the tool
  - `src/Configuration/Tasks/packages/optional-features.yml` + `src/Executables/DISM-FEATURES.ps1` - DirectPlay on; PowerShell v2, MSRDC, printing foundation, InternetPrinting, WorkFolders, XPS, Fax&Scan off
  - `src/Configuration/Tasks/registry/misc/deprovisioned-apps.yml` - anti-resurrection keys
- `Mithen apps` - optional auto-install
  - `src/Configuration/Tasks/software-mithen.yml` - task wrapper
  - `src/Executables/MITHENAPPS.ps1` - download + silent install with flag fallback
- `Services` - trimming
  - `src/Configuration/Tasks/services.yml` - disabled services list
  - `src/Configuration/Tasks/services-manual.yml` - WinUtil "Set to Manual" entries
- `Windows Update` - recommended deferral profile
  - `src/Configuration/Tasks/registry/updates/updates.yml` - deferrals, AUOptions, services
  - `src/Configuration/Tasks/registry/updates/drivers.yml` - driver exclusion policies
- `Tweaks ported from WinUtil` - one file per tweak
  - `src/Configuration/Tasks/registry/privacy/edge-debloat.yml`
  - `src/Configuration/Tasks/registry/privacy/store-recommended-search.yml`
  - `src/Configuration/Tasks/registry/explorer/visual-effects.yml`
  - `src/Configuration/Tasks/registry/explorer/window-snapping.yml`
  - `src/Configuration/Tasks/registry/explorer/explorer-auto-folder-discovery.yml`
  - `src/Configuration/Tasks/registry/system/ipv6.yml`, `long-paths.yml`, `numlock.yml`, `game-mode.yml`, `mpo.yml`
  - `src/Configuration/Tasks/registry/misc/logitech-download-assistant.yml`
- `Rollback` - reverts outdated/previous tweaks
  - `src/Configuration/Tasks/revert.yml`
- `Finalization` - black desktop/lock screen, theme, cleanup, task tuning
  - `src/Configuration/Tasks/final.yml`, `src/Executables/FINALIZE.cmd`, `src/Executables/CLEANER.ps1`
  - `src/Executables/BLACKSCREEN.ps1` - generates a black JPEG and sets the desktop background colour + lock screen to plain black (no wallpaper images are shipped)

## GOTCHAs

- The GUI is **not** in this repo: it is `../mithen-tool` (Flutter). Nothing here can change the tool UI except the CLI contract and its install path/binary name.
- `src/Executables/hosts` **replaces** the system hosts file; it must exist or `start.yml` fails (it had been deleted in this fork and was recreated).
- AME Wizard requires the archive password `malte`; keep `-m/-mhe=on`.
- A rebrand needs a **new `<UniqueId>` GUID**, otherwise AME treats the fork as the same playbook.
- `Microsoft.WindowsAlarms` is the **Clock** app; on Windows 11 the **Xbox app** is `Microsoft.GamingApp` (`Microsoft.XboxApp` is the legacy console companion).
- `revert.yml` runs **after** `registry.yml` and can overwrite values (e.g. `SvcHostSplitThresholdInKB`) - check it before adding conflicting tweaks.
- The WinUtil "Recommended" update profile **enables** Windows Update scheduled tasks; `FINALIZE.cmd` deliberately no longer disables `WindowsUpdate\Scheduled Start` / `UpdateOrchestrator\Schedule Scan`.
- WinUtil's "Services - Set to Manual" only covers CscService, SharedAccess, MapsBroker, StorSvc (DiagTrack is already disabled in `services.yml`).
- Policy-based update deferrals require Windows Pro/Enterprise/Education.
