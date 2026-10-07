# MithenOS - Goal

MithenOS is a lightweight, privacy- and performance-focused Windows distribution delivered as an **AME Wizard playbook**. It is a fork/combination of **ReviOS** (base) and selected pieces of **AtlasOS**, with additional tweaks sourced from **ChrisTitusTech WinUtil**, and a companion desktop tool (**Mithen-Tool**) that can monitor the applied state.

## Core features

- **Debloat / app removal** - removes unwanted inbox AppX packages (Bing cloud apps, Teams, new Outlook, Feedback Hub, Quick Assist, Dev Home, Power Automate, Solitaire, Media Player, Movies & TV, Photos, Copilot, Clock, etc.) and Win32 apps (OneDrive, Teams, Edge optionally).
- **Privacy / telemetry** - telemetry, activity history, location tracking, advertising ID, consumer features and background apps disabled.
- **Performance** - trimmed services, optimized visual effects, Game Mode, long paths, MPO kept on, scheduled-task cleanup.
- **Windows Update** - WinUtil "Recommended" profile: feature updates deferred 365 days, quality updates 4 days, drivers excluded from quality updates, notify before installing.
- **Network hygiene** - IPv6 disabled, Adobe telemetry/activation domains blocked via the hosts file.
- **Optional Mithen apps** - auto-install of MithenView, MithenPDF, MithenPlayer and MithenZip from their GitHub releases (checkbox `install-mithen-apps`, on by default).
- **Mithen-Tool** - installs the companion tool (Flutter rewrite of Revision Tool) which exposes a **System Monitor** tab that shows whether disabled/removed items have drifted back (e.g. a Store app reinstalled or a service re-enabled by Windows Update).

## Stance

- **Security**: Windows Defender is **kept enabled by default** (disabling remains an opt-in wizard choice); updates are still delivered, only deferred; telemetry surfaces are disabled rather than the update stack.
- **Performance**: conservative service trimming, no kernel hacks, focused on responsiveness and reduced background activity.
- **Usability**: one-shot drag-and-drop install through AME Wizard, sane defaults, and a monitoring tool that makes every change visible and reversible.
- **Maintainability**: tweaks are declarative YAML task files; WinUtil/Atlas-sourced values are copied verbatim and documented with their source.
