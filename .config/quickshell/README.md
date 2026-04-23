# Quickshell Dynamic Island Bar for Omarchy

A macOS Dynamic Island-inspired bar for [Omarchy](https://omarchy.org) — the Hyprland-based desktop built on Arch Linux. Built with [Quickshell](https://quickshell.outfoxxed.me).

> **Based on [Dynamic-Bar](https://github.com/turbogoomba/Dynamic-Bar) by turbogoomba.** Adapted for Omarchy (1920×1080), with iwd networking, PipeWire cava, generic MPRIS support, battery status, and various fixes and extensions.

---

## Preview

![Preview](Pasted%20image.png)

The bar lives at the top of the screen as three floating pills:

- **Left pill** — volume and network status
- **Center pill** — clock, media, launcher, notifications, and more
- **Right pill** — weather and battery

---

## Features

### Center Pill
| State | Description |
|---|---|
| **Idle** | Clock with seconds arc. When music plays, shows cava visualizer — hover to overlay the time |
| **Hub** | Quick-access grid for all bar functions |
| **Media** | Album art, track info, playback controls, progress bar, cava visualizer |
| **Launcher** | App launcher |
| **Stats** | CPU graph and RAM arc |
| **Notifications** | In-bar list of all notifications received this session |
| **Wallpaper** | Thumbnail grid from `~/Pictures/wallpaper` — click to set |
| **Theme picker** | Live preview switcher for all 6 themes |
| **Power** | Lock, suspend, reboot, poweroff |

### Left Pill
- **Volume arc** — scroll to adjust, click to open audio settings, hover to see percentage
- **Network** — wifi `󰖩` / wired `󰈀` / disconnected `󰤭`; hover for SSID and speed; click to open wifi manager

### Right Pill
- **Weather** — icon + temperature, auto-detected from your location
- **Battery** — icon + percentage; hover to see status
  - `󰂄` Charging · `󰚥` Plugged · `󰁹`–`󰂃` Discharging levels

### Themes
**gruvbox** (default) · catppuccin · tokyonight · nord · rosepine · everforest

---

## Requirements

Omarchy already provides everything needed. The only additional packages are:

```sh
paru -S quickshell-git cava
```

> **Font:** JetBrains Mono Nerd Font — already included in Omarchy.

---

## Installation

### 1. Install dependencies
```sh
paru -S quickshell-git cava
```

### 2. Clone the config
```sh
git clone <repo-url> ~/.config/quickshell
```

### 3. Set up the cava config
```sh
mkdir -p ~/.config/cava
cp ~/.config/quickshell/cava.conf ~/.config/cava/quickshell.conf
```

Find your audio sink and update `~/.config/cava/quickshell.conf`:
```sh
pactl list sinks short
```
Edit the source line:
```ini
[input]
method = pipewire
source = your_sink_name.monitor
```

### 4. Add wallpapers
```sh
mkdir -p ~/Pictures/wallpaper
# Copy your wallpapers into ~/Pictures/wallpaper/
```

### 5. Add keybindings
Add to `~/.config/hypr/bindings.conf`:
```
bindd = SUPER, D, App launcher, exec, qs ipc call island openLauncher
bindd = SUPER ALT, W, Wallpaper picker, exec, qs ipc call island openWallpaper
bindd = SUPER ALT, T, Theme picker, exec, qs ipc call island openThemePicker
```

### 6. Start the bar
```sh
quickshell &
```

Add to your Omarchy autostart if you want it on login.

---

## Usage

| Keybinding | Action |
|---|---|
| `SUPER+D` | Open app launcher |
| `SUPER+ALT+W` | Open wallpaper picker |
| `SUPER+ALT+T` | Open theme picker |
| Left click center pill | Open hub |
| Right click center pill | Toggle clock overlay (when music plays) |
| Scroll on volume arc | Adjust media volume |
| Click volume arc | Open audio settings |
| Click network icon | Open wifi manager |

---

## Configuration

### Themes
Change the default in `Theme.qml`:
```qml
property string currentTheme: "gruvbox"
```
Available: `gruvbox`, `catppuccin`, `tokyonight`, `nord`, `rosepine`, `everforest`

Switch at runtime with `SUPER+ALT+T`.

### Visualizer sensitivity
Edit `~/.config/cava/quickshell.conf`:
```ini
sensitivity = 175   # increase for louder bars, decrease to reduce
```

---

## Notifications

Works alongside Omarchy's mako notification daemon — mako handles popups as normal. The bar silently monitors D-Bus and stores every notification in the hub's notification panel for later review.

---

## Restarting after changes

```sh
killall quickshell && quickshell &
```
