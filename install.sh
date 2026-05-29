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
yay -S --needed --noconfirm \
    niri \
    quickshell \
    cava \
    swayosd \
    elephant \
    playerctl \
    brightnessctl \
    wireplumber \
    pipewire \
    pipewire-pulse \
    pipewire-audio \
    xdg-desktop-portal-gnome \
    hypridle \
    swaybg \
    foot \
    fuzzel \
    jq \
    polkit-gnome \
    grim \
    slurp \
    wl-clipboard \
    fastfetch \
    ripgrep \
    curl \
    networkmanager \
    bluez \
    bluez-utils \
    ttf-jetbrains-mono-nerd \
    qutebrowser \
    python-adblock \
    qt6-multimedia-ffmpeg \
    gst-plugins-base \
    gst-plugins-good \
    gst-plugins-bad \
    gst-plugins-ugly
ok "Packages installed"

# ── 4. Zanken scripts layer ──────────────────────────────────────
if [ ! -d "$HOME/zanken" ]; then
    info "Cloning zanken..."
    git clone "$ZANKEN_REPO" "$HOME/zanken"
    ok "zanken ready at ~/zanken"
else
    warn "~/zanken already exists, skipping clone"
fi

# ── 5. Dotfiles bare repo ────────────────────────────────────────
if [ ! -d "$HOME/dotfiles" ]; then
    info "Setting up dotfiles..."
    git clone --bare "$DOTFILES_REPO" "$HOME/dotfiles"
    git --git-dir="$HOME/dotfiles" --work-tree="$HOME" \
        config --local status.showUntrackedFiles no

    # Back up any files that would be overwritten
    conflicts=$(git --git-dir="$HOME/dotfiles" --work-tree="$HOME" checkout 2>&1 \
        | grep -E "^\s+" | awk '{print $1}' || true)
    if [ -n "$conflicts" ]; then
        warn "Backing up conflicting files..."
        mkdir -p "$HOME/.dotfiles-backup"
        echo "$conflicts" | xargs -I{} bash -c \
            'src="$HOME/{}"; dst="$HOME/.dotfiles-backup/{}"; mkdir -p "$(dirname "$dst")"; mv "$src" "$dst"'
    fi

    git --git-dir="$HOME/dotfiles" --work-tree="$HOME" checkout --force
    ok "Dotfiles checked out"

    # Set qutebrowser as default browser once dotfiles are in place
    xdg-settings set default-web-browser org.qutebrowser.qutebrowser.desktop 2>/dev/null || true
else
    warn "~/dotfiles already exists, pulling latest..."
    git --git-dir="$HOME/dotfiles" --work-tree="$HOME" pull --rebase
fi

# Fix local/share/omarchy symlink to point at zanken
mkdir -p "$HOME/.local/share/omarchy"
ln -sfn "$HOME/zanken" "$HOME/.local/share/omarchy/omarchy"

# ── 6. Default shell ─────────────────────────────────────────────
if command -v fish &>/dev/null; then
    FISH_PATH=$(command -v fish)
    if [ "$SHELL" != "$FISH_PATH" ]; then
        info "Setting fish as default shell..."
        chsh -s "$FISH_PATH"
        ok "Default shell: fish"
    fi
fi

# ── 7. qylock lockscreen ─────────────────────────────────────────
if [ ! -d "$HOME/.local/share/qylock" ]; then
    info "Cloning qylock..."
    git clone https://github.com/Darkkal44/qylock "$HOME/.local/share/qylock"
    ok "qylock ready"
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
sudo mkdir -p /usr/share/sddm/themes
sudo cp -r "$HOME/.local/share/qylock/themes/$QYLOCK_THEME" /usr/share/sddm/themes/
sudo tee /etc/sddm.conf.d/theme.conf > /dev/null <<EOF
[Theme]
Current=$QYLOCK_THEME
EOF
ok "qylock lockscreen configured"

# ── 8. Systemd user services ─────────────────────────────────────
info "Enabling user services..."
systemctl --user enable --now pipewire pipewire-pulse wireplumber 2>/dev/null || true
sudo systemctl enable --now NetworkManager bluetooth 2>/dev/null || true
ok "Services enabled"

echo ""
ok "Setup complete."
echo "   Log out and start a Niri session to get going."
echo "   Run: dotfiles push   to sync future config changes."
