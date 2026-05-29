#!/usr/bin/env bash
# zanken setup bootstrap — replicates the full niri+quickshell+zanken workspace
# Usage: bash install.sh
set -euo pipefail

DOTFILES_REPO="https://github.com/selfAnnihilator/dotfiles.git"
ZANKEN_REPO="https://github.com/selfAnnihilator/zanken.git"

info()  { printf '\033[0;34m=> %s\033[0m\n' "$*"; }
ok()    { printf '\033[0;32m✓  %s\033[0m\n' "$*"; }
warn()  { printf '\033[0;33m!  %s\033[0m\n' "$*"; }

# ── 1. Base packages ─────────────────────────────────────────────
info "Installing base packages..."
sudo pacman -Sy --needed --noconfirm base-devel git fish

# ── 2. AUR helper ────────────────────────────────────────────────
if ! command -v yay &>/dev/null; then
    info "Installing yay..."
    git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin
    (cd /tmp/yay-bin && makepkg -si --noconfirm)
    rm -rf /tmp/yay-bin
fi
ok "AUR helper ready"

# ── 3. Required packages ─────────────────────────────────────────
info "Installing required packages..."
# --overwrite='*' handles file conflicts; --ask=4 auto-removes conflicting packages
yay -S --needed --noconfirm --overwrite='*' --ask=4 \
    niri \
    quickshell \
    cava \
    swayosd \
    elephant \
    elephant-bin \
    playerctl \
    brightnessctl \
    wireplumber \
    pipewire \
    pipewire-pulse \
    pipewire-audio \
    xdg-desktop-portal-gnome \
    hypridle \
    swayidle \
    swaybg \
    foot \
    fuzzel \
    walker \
    jq \
    polkit-gnome \
    grim \
    slurp \
    wl-clipboard \
    fastfetch \
    ripgrep \
    curl \
    tmux \
    imv \
    mpv \
    networkmanager \
    iwd \
    bluez \
    bluez-utils \
    sddm \
    mako \
    gnome-keyring \
    xdg-user-dirs \
    mpd \
    mpd-mpris \
    gamemode \
    ufw \
    ttf-jetbrains-mono-nerd \
    noto-fonts-cjk \
    qt6-5compat \
    imagemagick \
    socat \
    adw-gtk3 \
    qutebrowser \
    python-adblock \
    qt6-multimedia-ffmpeg \
    gst-plugins-base \
    gst-plugins-good \
    gst-plugins-bad \
    gst-plugins-ugly
ok "Packages installed"

# ── 3b. xdg user dirs ───────────────────────────────────────────
xdg-user-dirs-update 2>/dev/null || true

# ── 3c. System limits + hardening ───────────────────────────────
info "Applying system configuration..."

# Raise fd limit for niri/quickshell/dev tools
sudo mkdir -p /etc/systemd/system.conf.d /etc/systemd/user.conf.d
sudo tee /etc/systemd/system.conf.d/99-zanken-nofile.conf >/dev/null <<'EOF'
[Manager]
DefaultLimitNOFILE=65536:524288
EOF
sudo cp /etc/systemd/system.conf.d/99-zanken-nofile.conf \
        /etc/systemd/user.conf.d/99-zanken-nofile.conf

# Raise inotify watchers for dev tools
sudo tee /etc/sysctl.d/90-zanken-file-watchers.conf >/dev/null <<'EOF'
fs.inotify.max_user_watches=524288
fs.inotify.max_user_instances=512
EOF
sudo sysctl --system >/dev/null 2>&1

# Input group for gamepad, dictation, Xbox controllers
sudo usermod -aG input "$USER"

ok "System configuration applied"

# ── 3d. Git global config ────────────────────────────────────────
if [ -z "$(git config --global user.name 2>/dev/null)" ]; then
    read -rp "Git name: " GIT_NAME
    git config --global user.name "$GIT_NAME"
fi
if [ -z "$(git config --global user.email 2>/dev/null)" ]; then
    read -rp "Git email: " GIT_EMAIL
    git config --global user.email "$GIT_EMAIL"
fi
git config --global init.defaultBranch main 2>/dev/null || true

# ── 4. Zanken scripts layer ──────────────────────────────────────
if [ ! -d "$HOME/zanken" ]; then
    info "Cloning zanken..."
    git clone "$ZANKEN_REPO" "$HOME/zanken"
else
    info "Resetting zanken to latest..."
    git -C "$HOME/zanken" fetch origin
    git -C "$HOME/zanken" reset --hard FETCH_HEAD
    git -C "$HOME/zanken" clean -fd
fi
ok "zanken ready"

# ── 5. Dotfiles bare repo ────────────────────────────────────────
if [ ! -d "$HOME/dotfiles" ]; then
    info "Setting up dotfiles..."
    git clone --bare "$DOTFILES_REPO" "$HOME/dotfiles"
    git --git-dir="$HOME/dotfiles" --work-tree="$HOME" \
        config --local status.showUntrackedFiles no
else
    info "Updating dotfiles..."
    git --git-dir="$HOME/dotfiles" --work-tree="$HOME" fetch origin
    git --git-dir="$HOME/dotfiles" --work-tree="$HOME" reset --hard FETCH_HEAD
fi
git --git-dir="$HOME/dotfiles" --work-tree="$HOME" checkout --force
ok "Dotfiles applied"
xdg-settings set default-web-browser org.qutebrowser.qutebrowser.desktop 2>/dev/null || true

# ~/.local/share/zanken → zanken repo (legacy path some tools may probe)
mkdir -p "$HOME/.local/share/zanken"
ln -sfn "$HOME/zanken" "$HOME/.local/share/zanken/zanken"

# ~/.config/zanken/bin → ~/zanken/bin so PATH edits in zanken/bin are live immediately
mkdir -p "$HOME/.config/zanken"
ln -sfn "$HOME/zanken/bin" "$HOME/.config/zanken/bin"

# ── 6. Default shell ─────────────────────────────────────────────
if command -v fish &>/dev/null; then
    FISH_PATH=$(command -v fish)
    if [ "$SHELL" != "$FISH_PATH" ]; then
        info "Setting fish as default shell..."
        sudo usermod -s "$FISH_PATH" "$USER"
        ok "Default shell: fish"
    fi
fi

# ── 7. qylock lockscreen ─────────────────────────────────────────
if [ ! -d "$HOME/.local/share/qylock" ]; then
    info "Cloning qylock..."
    git clone https://github.com/Darkkal44/qylock "$HOME/.local/share/qylock"
else
    git -C "$HOME/.local/share/qylock" pull --rebase 2>/dev/null || true
fi
ln -sfn "$HOME/.local/share/qylock/themes" \
    "$HOME/.local/share/qylock/quickshell-lockscreen/themes_link"

mkdir -p "$HOME/.config/qylock"
[ -f "$HOME/.config/qylock/theme" ] || echo "pixel-night-city" > "$HOME/.config/qylock/theme"

# PAM config for quickshell auth
if [ ! -f /etc/pam.d/quickshell ]; then
    printf 'auth\tinclude\tlogin\naccount\tinclude\tlogin\n' | sudo tee /etc/pam.d/quickshell > /dev/null
fi

# SDDM theme
QYLOCK_THEME=$(cat "$HOME/.config/qylock/theme")
sudo mkdir -p /usr/share/sddm/themes /etc/sddm.conf.d
sudo cp -r "$HOME/.local/share/qylock/themes/$QYLOCK_THEME" /usr/share/sddm/themes/
sudo tee /etc/sddm.conf.d/theme.conf > /dev/null <<EOF
[Theme]
Current=$QYLOCK_THEME
EOF

# /etc/sddm.conf wins over all conf.d — default.conf (Current=) otherwise overrides theme.conf
sudo tee /etc/sddm.conf > /dev/null <<EOF
[Theme]
Current=$QYLOCK_THEME
EOF

# Suppress niri hotkey overlay on SDDM login screen
sudo tee /etc/sddm-niri.kdl > /dev/null <<'NIREOF'
hotkey-overlay {
    skip-at-startup
}
NIREOF
sudo tee /etc/sddm.conf.d/10-wayland.conf > /dev/null <<'WEOF'
[General]
DisplayServer=wayland

[Wayland]
CompositorCommand=niri --config /etc/sddm-niri.kdl
WEOF
ok "qylock lockscreen configured"

# ── 8. Zanken assets ─────────────────────────────────────────────
info "Installing zanken assets..."

# Font
mkdir -p "$HOME/.local/share/fonts"
cp "$HOME/zanken/config/omarchy.ttf" "$HOME/.local/share/fonts/"
fc-cache -f 2>/dev/null || true

# App icons (webapp icons referenced by .desktop launchers)
mkdir -p "$HOME/.local/share/applications/icons"
cp "$HOME/zanken/applications/icons/"* "$HOME/.local/share/applications/icons/"

# Desktop file overrides (foot, imv, mpv, typora)
cp "$HOME/zanken/applications/"*.desktop "$HOME/.local/share/applications/" 2>/dev/null || true

# Initial theme — populates ~/.config/zanken/current/theme/
export ZANKEN_PATH="$HOME/zanken"
export PATH="$HOME/zanken/bin:$PATH"
ZANKEN_THEME_SKIP_BACKGROUND=1 "$HOME/zanken/bin/zanken-theme-set" "tokyo-night" 2>/dev/null || true

# Default mono font for quickshell bar icons (written by zanken-font-set normally)
printf 'JetBrainsMono Nerd Font' > "$HOME/.config/zanken/current/mono-font"

# Default corners to round so the bar floats on first boot
mkdir -p "$HOME/.local/state/quickshell-desktop"
printf 'round' > "$HOME/.local/state/quickshell-desktop/corners"

# Btop theme symlink
mkdir -p "$HOME/.config/btop/themes"
ln -snf "$HOME/.config/zanken/current/theme/btop.theme" "$HOME/.config/btop/themes/current.theme"

# Mako (notifications) config symlink
mkdir -p "$HOME/.config/mako"
ln -snf "$HOME/.config/zanken/current/theme/mako.ini" "$HOME/.config/mako/config"

# Wallpapers come from dotfiles checkout at ~/Pictures/wallpaper/
# Set up backgrounds symlink and pick an initial wallpaper for swaybg
rm -rf "$HOME/.config/zanken/backgrounds"
ln -sfn "$HOME/Pictures/wallpaper" "$HOME/.config/zanken/backgrounds"
FIRST_BG=$(find "$HOME/Pictures/wallpaper" -maxdepth 1 -type f | sort | head -1)
[ -n "$FIRST_BG" ] && ln -sfn "$FIRST_BG" "$HOME/.config/zanken/current/background"

# Elephant menus (app launcher context menus)
mkdir -p "$HOME/.config/elephant/menus"
for lua in "$HOME/zanken/default/elephant/"*.lua; do
    ln -snf "$lua" "$HOME/.config/elephant/menus/$(basename "$lua")"
done

# Mimetypes
xdg-mime default imv.desktop image/png 2>/dev/null || true
xdg-mime default imv.desktop image/jpeg 2>/dev/null || true
xdg-mime default imv.desktop image/gif 2>/dev/null || true
xdg-mime default imv.desktop image/webp 2>/dev/null || true
xdg-mime default mpv.desktop video/mp4 2>/dev/null || true
xdg-mime default mpv.desktop video/x-matroska 2>/dev/null || true
xdg-mime default mpv.desktop video/webm 2>/dev/null || true
xdg-mime default org.qutebrowser.qutebrowser.desktop x-scheme-handler/http 2>/dev/null || true
xdg-mime default org.qutebrowser.qutebrowser.desktop x-scheme-handler/https 2>/dev/null || true
update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true

# Clean stale paths from fish universal variable
fish -c "set -e fish_user_paths; set -U fish_user_paths '$HOME/.local/bin'" 2>/dev/null || true

ok "zanken assets installed"

# ── 9. Systemd services ──────────────────────────────────────────
info "Enabling system services..."

# NetworkManager uses iwd as wifi backend so iwctl still works (bar uses it)
sudo mkdir -p /etc/NetworkManager/conf.d
sudo tee /etc/NetworkManager/conf.d/wifi_backend.conf > /dev/null <<'EOF'
[device]
wifi.backend=iwd
EOF
sudo systemctl enable --now NetworkManager iwd bluetooth 2>/dev/null || true
sudo systemctl set-default graphical.target
sudo systemctl enable sddm 2>/dev/null || true  # starts on next boot only

info "Enabling user services..."
systemctl --user daemon-reload
systemctl --user enable --now pipewire pipewire-pulse wireplumber 2>/dev/null || true
systemctl --user enable --now swayosd-server 2>/dev/null || true
systemctl --user enable --now swayidle 2>/dev/null || true
systemctl --user enable --now mpd mpd-mpris 2>/dev/null || true
systemctl --user enable --now gamemoded 2>/dev/null || true
systemctl --user enable zanken-battery-monitor.timer 2>/dev/null || true
systemctl --user enable zanken-recover-internal-monitor.service 2>/dev/null || true
systemctl --user enable gnome-keyring-daemon.socket 2>/dev/null || true
ok "Services enabled"

# Restart quickshell if already running so new theme + fonts take effect
if pgrep -x quickshell >/dev/null 2>&1; then
    info "Restarting quickshell to apply theme..."
    "$HOME/zanken/bin/zanken-restart-quickshell" 2>/dev/null || true
fi

echo ""
ok "Setup complete."
echo "   Log out and start a Niri session to get going."
echo "   Run: dotfiles push   to sync future config changes."
