test -f /usr/share/cachyos-fish-config/cachyos-config.fish \
    && source /usr/share/cachyos-fish-config/cachyos-config.fish

set -gx ZANKEN_PATH $HOME/zanken
# Force override bin first — fish_add_path skips already-present paths so use
# explicit PATH manipulation to guarantee ~/.config/zanken/bin wins.
set -gx PATH (string match -v "$HOME/.config/zanken/bin" -- $PATH)
set -gx PATH $HOME/.config/zanken/bin $PATH

# skip fastfetch inside tmux — $TMUX is set automatically by tmux for every pane
function fish_greeting
    if not set -q TMUX
        fastfetch
    end
end

alias dotfiles='/usr/bin/git --git-dir=$HOME/dotfiles/ --work-tree=$HOME'
alias silksong='prime-run wine /home/abhi/Downloads/game/Hollow.Knight.Silksong.v1.0.29315/game/Hollow\ Knight\ Silksong.exe'
alias terraria='prime-run wine /home/abhi/.wine/drive_c/GOG\ Games/Terraria/Launch\ Terraria.lnk'
alias sekiro='prime-run wine /home/abhi/Downloads/game/Sekiro.Shadows.Die.Twice.GOTY.Edition/Sekiro/sekiro.exe'
alias mecharena='prime-run wine "/home/abhi/.wine/drive_c/users/abhi/AppData/Local/PlariumPlay/PlariumPlay.exe"'
alias quit-mecharena='pkill -9 -fi "plarium"; pkill -9 -fi "mech arena"'
# Added by Antigravity CLI installer
set -gx PATH "/home/abhi/.local/bin" $PATH
