test -f /usr/share/cachyos-fish-config/cachyos-config.fish \
    && source /usr/share/cachyos-fish-config/cachyos-config.fish

set -gx ZANKEN_PATH $HOME/zanken
# Force override bin first — fish_add_path skips already-present paths so use
# explicit PATH manipulation to guarantee ~/.config/zanken/bin wins.
set -gx PATH (string match -v "$HOME/.config/zanken/bin" -- $PATH)
set -gx PATH $HOME/.config/zanken/bin $PATH

# Skip fastfetch in multiplexer panes.
function fish_greeting
    if not set -q TMUX; and not set -q ZELLIJ
        fastfetch
    end
end

alias dotfiles='/usr/bin/git --git-dir=$HOME/dotfiles/ --work-tree=$HOME'
alias silksong='prime-run wine /home/abhi/Downloads/game/Hollow.Knight.Silksong.v1.0.29315/game/Hollow\ Knight\ Silksong.exe'
alias terraria='prime-run wine /home/abhi/.wine/drive_c/GOG\ Games/Terraria/Launch\ Terraria.lnk'
alias sekiro='prime-run wine /home/abhi/Downloads/game/Sekiro.Shadows.Die.Twice.GOTY.Edition/Sekiro/sekiro.exe'
alias mecharena='prime-run wine "/home/abhi/.wine/drive_c/users/abhi/AppData/Local/PlariumPlay/PlariumPlay.exe"'
alias quit-mecharena='pkill -9 -fi "plarium"; pkill -9 -fi "mech arena"'
# alias z 'zoxide'

# Added by Antigravity CLI installer
set -gx PATH "/home/abhi/.local/bin" $PATH

function claude-native
    command /home/abhi/.local/bin/claude $argv
end

function reload-shell --description 'Restart fish in place to pick up new commands and shell startup changes'
    exec fish --login
end

function fish_user_key_bindings
    bind \er reload-shell
end

# Jarvis remote LLM (replace the placeholder with your Groq API key).
# Secrets live in ~/.config/fish/secrets.fish (untracked)
test -f ~/.config/fish/secrets.fish; and source ~/.config/fish/secrets.fish
alias genymotion='env QT_QPA_PLATFORM=xcb genymotion'

# qlty
set --export QLTY_INSTALL "$HOME/.qlty"
set --export PATH $QLTY_INSTALL/bin $PATH
