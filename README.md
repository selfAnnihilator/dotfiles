# dotfiles

Personal `~/.config` dotfiles tracked as a bare git repo.

## Install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/selfAnnihilator/dotfiles/main/install.sh) --clean
```

Installs all packages, clones zanken, and sets up this dotfiles repo automatically.

## Manual setup (new machine)

Clone the repo as a bare repo and check it out into `$HOME`. The remote is SSH, so
add an SSH key to GitHub first, or use `https://github.com/selfAnnihilator/dotfiles.git`.

```bash
git clone --bare git@github.com:selfAnnihilator/dotfiles.git $HOME/dotfiles
alias dotfiles='/usr/bin/git --git-dir=$HOME/dotfiles/ --work-tree=$HOME'
dotfiles config status.showUntrackedFiles no
dotfiles checkout
```

- `status.showUntrackedFiles no` keeps `dotfiles status` from listing all of `$HOME`.
- If `dotfiles checkout` fails with "untracked working tree files would be overwritten",
  move the listed files (for example a default `.bashrc`) aside and run it again, or use
  `dotfiles checkout -f` to overwrite them.
- The `alias` only lasts for the current shell; the tracked fish config defines it again.

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
