# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a **Quickshell desktop shell configuration** for Hyprland on Wayland. It implements a floating "island" pill UI (similar to macOS Dynamic Island) that appears at the top-center of the screen, with side pills for system status.

## Running

Quickshell reloads configuration at runtime — there is no build step. Apply changes by restarting Quickshell:

```sh
quickshell &          # start
killall quickshell    # stop
qs ipc call shell reloadConfig   # hot-reload if supported
```

## Architecture

All UI is declarative QML. The entry point is `shell.qml`, which composes several `WlrLayershell` windows rendered at the Wayland compositor level.

### Key files

| File | Role |
|---|---|
| `shell.qml` | All panels, state machine, system integrations |
| `NotifPopup.qml` | Animated notification toast component |
| `Theme.qml` | Singleton with 6 color palettes; accessed via `Theme.*` |
| `qmldir` | Module registration (`module quickshell`) |

### State machine

The central `pill` component in `shell.qml` drives everything through a single `islandState` string property:

```
idle → launcher | hub | power | wallpaper | media | notifications | recorder | stats
```

State changes animate the pill's width/height with `Easing.OutBack`. All sub-panels are conditionally shown based on `islandState`.

### Wayland windows

Each logical surface is a separate `WlrLayershell` window:
- **Hotzone** — 2560×4 px invisible strip at top that triggers bar visibility
- **Island Window** — 600×700 px container for the main interactive pill
- **Status Window** — CPU/RAM gauge + weather icon (top-left)
- **Now Playing Tooltip** — 320×120 px music metadata card

### External process integrations

The config shells out to these programs; they must be installed:

| Command | Purpose |
|---|---|
| `playerctl` | Music playback control and metadata |
| `nmcli` | Network status |
| `cava` | Audio visualizer bars (reads stdout) |
| `hyprlock` | Lock screen |
| `wf-recorder` | Screen recording toggle |
| `awww` / `wal` | Wallpaper setting |
| `systemctl` | Suspend/reboot/poweroff |

### Theming

`Theme.qml` exposes `Theme.current` (object with named color properties). Switch themes by setting `Theme.themeName` to one of: `"gruvbox"`, `"catppuccin"`, `"tokyonight"`, `"nord"`, `"rosepine"`, `"everforest"`.

Colors are referenced throughout `shell.qml` as `Theme.current.bg`, `Theme.current.accent`, etc. — add new palette keys to all six theme objects in `Theme.qml`.
