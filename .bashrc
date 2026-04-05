# If not running interactively, don't do anything (leave this at the top of this file)
[[ $- != *i* ]] && return

# All the default Omarchy aliases and functions
# (don't mess with these directly, just overwrite them here!)
source ~/.local/share/omarchy/default/bash/rc

# Add your own exports, aliases, and functions here.
#
# Make an alias for invoking commands you use constantly
# alias p='python'
alias minecraft='prime-run java -jar ~/minecraft/TLauncher.v17/TLauncher.jar'
alias musicServer-start='sudo systemctl start navidrome'
alias musicServer-stop='sudo systemctl stop navidrome'
alias config='/usr/bin/git --git-dir=$HOME/dotfiles/ --work-tree=$HOME'
alias silksong='DRI_PRIME=1 wine /home/abhi/Downloads/game/Hollow-Knight-Silksong-SteamRIP.com/Hollow\ Knight\ Silksong/Hollow\ Knight\ Silksong.exe'
alias anil='DRI_PRIME=1 wine /home/abhi/Downloads/game/Pokemon\ Indigo\ 4.0.2/Pokemon\ Indigo\ 4.0.2\ EN-2/Game.exe'
source /usr/share/bash-completion/bash_completion

export PATH=$PATH:/home/abhi/.spicetify
export PATH=$PATH:~/.spicetify
export PATH=$PATH:~/.spicetify
