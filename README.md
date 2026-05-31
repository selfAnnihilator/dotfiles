# dotfiles

Personal `~/.config` dotfiles tracked as a bare git repo.

## Install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/selfAnnihilator/dotfiles/main/install.sh) --clean
```

Installs all packages, clones zanken, and sets up this dotfiles repo automatically.

## Manual setup (existing machine)

## Usage

```bash
# alias recommended: add to fish config
alias dots='git --git-dir=$HOME/dotfiles --work-tree=$HOME'

dots status
dots add ~/.config/niri/config.kdl
dots commit -m "update niri config"
dots push
```

## What's tracked

- `niri/` — Niri compositor config (KDL)
- `quickshell/` — QML bar and popups
- `nvim/` — Neovim config
- `fish/` — Fish shell config
- `tmux/` — tmux config
- `fastfetch/` — fastfetch config + assets
- `cava/` — CAVA visualizer config + shaders
- `swayosd/` — SwayOSD theme
- `mpd/` / `rmpc/` — Music player config
- `qutebrowser/` — Browser config
- `easyeffects/` — Audio effects presets
