# Changelog

All notable changes to the MithenOS playbook. This file starts at 1.1.0 - earlier builds were released without a changelog.

## [1.1.0] - 2026-10-21

A pass over the whole configuration: one fixed, non-interactive setup, far fewer silent failures, and the Start menu / sound / taskbar work that previously did nothing now actually lands on the installed system.

### Changed

- **The playbook is no longer interactive.** The wizard's option pages were removed; the setup applies one fixed configuration. Concretely: Defender stays enabled, hibernate is disabled, OneDrive / AI components / Teams / Photos / Dev Home / Your Phone are removed, Mithen apps are installed, wallpaper + dark mode + legacy context menu + no transparency are applied, Start pins are reset, and Automatic Maintenance is disabled.
- **Edge is kept** (still debloated with policies). The removal option and its steps are gone.
- **No browser is installed** by the playbook anymore (the Brave/Firefox selection and its download steps were removed).
- **Mithen apps are installed last**, after all configuration, so a slow or stuck installer cannot hold up the rest of the setup. Each installer is bounded to 3 minutes and falls back to alternative silent flags.
- **Mithen apps and MithenTool no longer create desktop icons** (the installer is no longer asked for one and any `Mithen*.lnk` is removed afterwards).
- **Default Start pins** are now Snipping Tool, Calculator, Microsoft Edge, MithenMusic and MithenTool (plus Camera when the app exists). They are applied via policy and released at the first sign-in, so you can re-pin freely afterwards.
- **Sounds**: the scheme is set to "No Sounds" and every event is silenced. The generated theme no longer carries a sound scheme, which is what used to restore the Windows Default sounds after the setup finished.
- **Release naming** now follows `playbook.conf` `<Version>`: the artifact is `MithenOS_Playbook_v<version>.apbx` under tag `v.<version>`.

### Added

- **Start menu**: all-apps view defaults to **List**; "recently added apps", "recommended files in Start / recent files in File Explorer / Jump Lists", "recommendations for tips, shortcuts…", and account notifications default to **off**; Settings and File Explorer default to **on** in the folders row.
- **Taskbar**: size **Small**, icons **left**, search **hidden**, taskbar buttons **never combined**, far-corner show-desktop **on**, badges and flashing **off**, "share any window" **off**, emoji panel and touch keyboard **never**.
- **Desktop icons** default to **small**.
- **Recycle Bin**: "Display delete confirmation dialog" defaults to **on**.
- **Narrator**: the Win+Ctrl+Enter launch shortcut is **disabled**.
- **Edge**: favorites bar **never**, new-tab quick links / content / background **off**, Startup Boost and background mode **off**, and Edge is **disabled in Startup apps**. **Copilot is off**: sidebar hidden, page-context access blocked, inline AI "Compose" disabled.
- **Usage reporting** ("report battery health and data use") defaults to **off** - the same state the MithenTool toggle shows.
- **Security defaults**: Spectre & Meltdown mitigations **off**, cloud-delivered protection **off**, automatic sample submission **never**, UAC **does not dim the desktop**, "Reduce CTFMon overhead" **on**.
- **Privacy/visual defaults**: Dynamic Lighting **off**, Storage Sense **off**, custom inking dictionary **off**, account search in Start **off**, master notifications **off**.
- A **`C:\MithenVerify.txt`** report is written at the end of every run, listing what actually landed (Start values, sound scheme, pins, extension policies, tool presence). It is deleted automatically when the run logs no errors.

### Fixed

- **Optional Windows features were never removed.** The feature step ran a script in a way Windows could not resolve, so Windows Media Player (Legacy), Work Folders, PowerShell v2, Media Playback, Fax and XPS silently stayed installed. They are removed properly now (and no longer merely disabled).
- **The Mithen apps step had never installed anything.** Every download succeeded and then every install failed, because of a PowerShell parameter that is an automatic variable. All five apps install now.
- **An apply could hang for 10+ minutes** waiting for a service that cannot stop (Diagnostic Policy Service). Service stops during cleanup are now time-bounded.
- **A failed MithenTool install no longer aborts the whole setup** - it is logged and the configuration continues.
- **Several task files were never executed** because they were missing from the task list (Edge policies, optional features, BitLocker). All task files are wired up now.
- Start menu values, Start folders and pinned items were being overwritten by the Start host during the run; they are now written in a way that survives it.
- "Show recently added apps" and "Show recommended files…" used the wrong registry values and stayed enabled; both now default to off.

### Known limitations

- **uBlock Origin Lite cannot be force-installed in Edge** on an unmanaged device - Edge rejects every policy form with "Invalid extension ID" and states that only its own store may be used. The playbook therefore no longer writes an Edge entry (install it once from the Edge Add-ons store). The Chrome Web Store entry for Chrome is kept.
- **Windows Camera is not part of LTSC images**, so its Start pin is skipped there. Calculator and Snipping Tool exist as Win32 entries on such images and are pinned through generated shortcuts.
- **Defender Dev Drive protection** has to be switched off manually; Defender's tamper protection blocks writes to the local Defender key.
