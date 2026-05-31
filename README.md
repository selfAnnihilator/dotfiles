# dotfiles

Personal `~/.config` dotfiles tracked as a bare git repo.

## Setup on a new machine

```bash
git clone --bare git@github.com:selfAnnihilator/dotfiles.git ~/dotfiles
git --git-dir=~/dotfiles --work-tree=~ checkout
git --git-dir=~/dotfiles --work-tree=~ config status.showUntrackedFiles no
```

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
