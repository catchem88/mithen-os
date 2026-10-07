# MithenOS - State

## Current status

MithenOS **playbook development is complete** (rebrand + tweaks + apps + associations). Not committed; **not yet tested on a VM**. Mithen-Tool work (Flutter) is the next workstream and has not started.

## Done (this session)

- Rebranded the whole repo from ReviOS/Revision to MithenOS/Mithen (30 files + templates); new `<UniqueId>` GUID; tool path/CLI renamed to `%ProgramFiles%\Mithen-Tool\mithentool.exe`; artifact is now `Mithen-PB-<YY.MM>.apbx`.
- AppX list adjusted: kept Camera and Sound Recorder (Clipchamp and Sticky Notes were re-added to the removal list); Clock removed; added Xbox App-only removal (`Microsoft.GamingApp` + `Microsoft.XboxApp`); removed the whole-suite Xbox option and its `win-sxs.yml`/`revert.yml` references.
- Added WinUtil-sourced tweaks (new task files): IPv6 off, long paths, Num Lock, Game Mode, MPO on, visual effects custom set, window snapping, Explorer auto-folder-discovery, Edge debloat, Store recommended search results, Logitech Download Assistant block, services-to-manual.
- Added XPS and Fax & Scan removal to `DISM-FEATURES.ps1` (features + capabilities), plus legacy Windows Media Player (`WindowsMediaPlayer`, `MediaPlayback`) and the Windows Fax and Scan feature (`FaxServicesClientPackage`); `Update-Feature` now skips feature names that do not exist on the running build.
- Recreated the deleted `src/Executables/hosts` with the Adobe block list (Ruddernation-Designs).
- Unhid the Settings Home page; added restore-point creation in `start.yml`.
- Windows Update switched from pause-to-2038 to the WinUtil "Recommended" profile; removed conflicting WU scheduled-task disables from `FINALIZE.cmd`.
- Added optional Mithen apps auto-install (`software-mithen.yml` + `Executables/MITHENAPPS.ps1`) with per-app silent flags and fallbacks.
- Added Mithen file associations: `OEMDefaultAssociations-Mithen.xml` (69 associations), new `registry/misc/mithen-view-associations.yml` (creates the `MithenView.Image` ProgId + Default apps capabilities + OpenWithProgids), rewritten `FILEASSOC.cmd` with `mithen`/`photos` modes, and a second `FILEASSOC.cmd mithen` run in `final.yml` gated on `install-mithen-apps`.
- `playbook.conf` option defaults: `remove-edge` off, Defender enable (default), `install-mithen-apps` on.
- Verified: no brand strings left outside license text; XML parses; no tabs in YAML; PowerShell scripts pass the parser; **local packaging smoke test passed** with `7za` (97 files / 18 folders, includes hosts, `playbook.conf` and all new tasks).

## Learnings

- The ReviOS base delegates all heavy lifting to an external tool; the playbook only calls its CLI. The tool lives at `../mithen-tool` and is a **Flutter/Dart** app (not C#), with an Inno Setup installer. It is a **feature-based clean architecture**: `src/lib/features/{appx,home,ms_store,tweaks,winsxs}` each with `data/domain/presentation`, Riverpod state, Fluent UI, a CLI generator (`core/cli_generator`) and `main_cli.dart`, i18n via slang, and a Rust FFI package `src/packages/revitool_native`. Package name is still `revitool`; README still says "Revision Tool".
- Mithen app installer types and silent flags (from `../mithen-*` sources):
  - MithenView - **NSIS** (`dist/scripts/installer.nsi`) -> `/S` (optional `/LANG=<code>`).
  - MithenPDF - **custom installer** (SumatraPDF-based, `src/Installer.cpp`) -> `-silent` (also `-run-install-now`, `-all-users`).
  - MithenPlayer - **Inno Setup** (`distrib/mpc-be_setup.iss`) -> `/VERYSILENT /NORESTART`.
  - MithenZip - **custom C++ installer** (`Installer/MithenZipSetup.cpp`) -> `/s` (also `/uninstall`).
- Optional feature names (WinUtil `config/feature.json`): legacy WMP = `WindowsMediaPlayer` + `MediaPlayback`; Fax and Scan = `FaxServicesClientPackage`; XPS = `Printing-XPSServices-Features` + `XPS.Viewer~~~~0.0.1.0`.
- The playbook **changes the wallpaper by default** (`configure-wallpaper` IsChecked=true): ships `src/Executables/Wallpapers/desktop.jpg` + `lockscreen.jpg`, copies them to `%systemroot%\Web\Wallpaper\MithenOS\v2`, applies via `WALLPAPER.ps1`, and re-applies at first logon via a RunOnce entry. No wallpaper images are shipped: `BLACKSCREEN.ps1` generates a black image and sets the desktop and lock screen to plain black. `WALLPAPER.ps1`, `WallpaperStartup.cmd` and the two JPGs were deleted (test archive 1.16 MB -> 148 KB).
- Registered ProgIds (this machine):
  - MithenPDF -> `MithenPDF.<ext>` for PDF/XPS/OXPS/comics/ebooks/images.
  - MithenZip -> `MithenZip.Archive` (archives).
  - MithenPlayer -> `mpc-be64.<ext>` - **video only here; audio ProgIds (`mpc-be64.mp3/flac/wav/...`) do not exist**, so audio was intentionally left unassociated.
  - MithenView -> **no ProgIds**; the playbook now creates `MithenView.Image` itself.
- 7z: `C:\Program Files\7-Zip` contains only `7-zip.dll`; MithenZip is a GUI (`MithenZip.exe` + `7z.dll`), no console 7z. Usable console binaries: `../BatchConvertToCHD-Forked/BatchConvertToCHD/7za.exe`, `C:\Program Files\NVIDIA Corporation\NVIDIA app\7z.exe`, `../War of Genesis III - Part 1/Setup/installer/7z.exe`.
- 7z keeps the `src\` prefix when packing (matches upstream ReviOS behaviour); the official CI uses `7z a -pmalte -mhe=on <out>.apbx ./src/*`.
- mithen-zip's release `v.1.0.0` is a **pre-release**, so `releases/latest/download/` does not resolve it - the download URL is pinned to the tag.

## Failed / corrected

- First bulk rebrand pass also rewrote URL hosts; `revi.cc`/Discord links were fixed afterwards manually (README rewritten, FUNDING/issue templates cleaned).
- `MITHENAPPS.ps1` initially used `"$Name: ..."` which is invalid PowerShell; changed to `${Name}` (caught by the parser check).
- `DISM-FEATURES.ps1` array insertion initially missed a comma; fixed.
- Bulk PowerShell edits via one long `shell_command` failed (`command line is too long`) - work was split into smaller batches.
- A `? :` ternary and a `/releases/latest` call for a pre-release both failed; fixed by rewriting and by pinning the tag.
- Initial Mithen association plan assumed MithenPlayer registers audio ProgIds and that MithenView registers image ProgIds - neither is true; resolved by checking the machine and creating the MithenView ProgId in the playbook.

## Behavior notes

- Use **Windows PowerShell 5.1 compatible** syntax (no ternary, no `&&`/`||`).
- Long shell commands fail: split into batches or write a script.
- Prefer reading/inspection over guessing; verify with grep/parser after edits.
- `revert.yml` runs after `registry.yml`; check it before adding a conflicting value.
- `FILEASSOC.cmd` chooses ProgIds at runtime and skips the photos pass when MithenView is installed.
- Keep the archive password `malte`.

## Backlog

1. **Phase 5 - Mithen-Tool** (`../mithen-tool`, Flutter): rebrand to Mithen-Tool, then add the **System Monitor** feature (new `features/system_monitor` module + route/nav) driven by a JSON manifest of appx/services/features/tasks/registry/hosts expectations; green = ok, red = drifted; per-row "Fix". Publish a release with `MithenTool-Setup.exe` (required before the playbook CI can bundle it).
2. (done) ReviOS wallpaper artwork removed - desktop and lock screen are generated plain black.
3. Commit the playbook changes.
3. Clean-VM install test (appx list, features, hosts, WU policy, associations, Mithen apps).
4. Optional: audio associations if MithenPlayer ever registers audio ProgIds.
