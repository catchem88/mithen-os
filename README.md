<p align="center">
  <img src="img/logo.png" alt="MithenOS banner">
</p>

<h1 align="center">MithenOS</h1>

<div align="center">
MithenOS is a lightweight, privacy and performance focused customization of Windows 10 and 11, applied as an <a href="https://amelabs.net">AME Wizard</a> playbook. It is a fork of <a href="https://github.com/meetrevision/playbook">ReviOS</a>, combined with tweaks from <a href="https://github.com/Atlas-OS/Atlas">AtlasOS</a> and <a href="https://github.com/ChrisTitusTech/winutil">ChrisTitusTech's WinUtil</a>.
</div>

## Features
* Removes bloatware and unnecessary inbox apps: Bing apps, Teams, new Outlook, Feedback Hub, Quick Assist, Dev Home, Power Automate, Clipchamp, Sticky Notes, Clock, Xbox App, and more.
* Removes OneDrive and Copilot, and optionally Microsoft Edge (off by default; Edge is debloated with policies when it is kept).
* Sets Windows Update to the WinUtil "Recommended" profile: feature updates deferred 365 days, quality updates 4 days, drivers excluded from quality updates, and notify before installing.
* Privacy hardening: telemetry, activity history, location tracking, advertising ID, consumer features and background apps disabled.
* Blocks Adobe telemetry and activation domains through the hosts file.
* Performance and quality of life tweaks: trimmed services, custom visual effects, Game Mode, long paths, window snapping, Num Lock on startup, Multiplane Overlay kept on, and more.
* Removes or disables Internet Printing, Work Folders, XPS, Fax and Scan, legacy Windows Media Player and PowerShell 2.
* Keeps the Windows default power plan.
* Removes the Microsoft Store automatically on LTSC editions.
* Installs the Mithen apps (MithenView, MithenPDF, MithenPlayer, MithenZip) and the Mithen-Tool with its System Monitor tab.
* Desktop and lock screen are set to plain black.

## Supported platforms
* Windows 10 21H2 `19044` and 22H2 `19045` (AMD64, ARM64)
* Windows 11 23H2 `22631`, 24H2 `26100` and 25H2 `26200` (AMD64, ARM64)

## How to use
1. Download the [AME Wizard](https://amelabs.net) and the latest playbook from [Releases](https://github.com/catchem88/mithen-os/releases).
2. Start from a clean, stock Windows installation.
3. Drag and drop the playbook into AME Wizard and follow the on-screen steps.

> ISO injection is supported for Windows 11 ISOs only.

## Part of MithenOS
* No telemetry.
* Windows Defender is kept enabled by default.
* Every applied change is visible and reversible from the Mithen-Tool System Monitor.
* No bundled third-party tooling beyond the Mithen apps and the Mithen-Tool.

## Credits
* [ReviOS](https://github.com/meetrevision/playbook) - the playbook this project is forked from.
* [AtlasOS](https://github.com/Atlas-OS/Atlas) - selected tweaks (visual effects, Xbox App removal, long paths).
* [ChrisTitusTech WinUtil](https://github.com/ChrisTitusTech/winutil) - tweak values and the Windows Update profile.
* [Ruddernation-Designs](https://github.com/Ruddernation-Designs/Adobe-URL-Block-List) - the Adobe hosts block list.

## License
MithenOS Playbook is licensed under [Attribution-ShareAlike 4.0 International](https://creativecommons.org/licenses/by-sa/4.0/).
