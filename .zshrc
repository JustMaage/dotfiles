# The font I use is contained in this repository

# Fixes errors when insatlling zoxide with the install script
export PATH="$PATH:$HOME/.local/bin"

# Set the directory we want to store zinit and plugins
PLUGIN_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/antidote/antidote.git"

# Download the plugin manager if it's not there yet
if [ ! -d "$PLUGIN_HOME" ]; then
   mkdir -p "$(dirname $PLUGIN_HOME)"
   git clone git clone --depth=1 https://github.com/mattmc3/antidote.git "$PLUGIN_HOME"
fi

# Source/Load the plugin manager
source "${PLUGIN_HOME}/antidote.zsh"

# Add in zsh plugins and snippets
antidote load $HOME/.zsh_plugins.txt

# Load completions
autoload -Uz compinit && compinit

eval "$(oh-my-posh init zsh --config $HOME/.config/ohmyposh/zen.toml)"

# Keybindings
bindkey '^[w' kill-region
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word
bindkey '^H' backward-kill-word
bindkey "${terminfo[kcuu1]}" history-search-backward # Up Arrow
bindkey "${terminfo[kcud1]}" history-search-forward # Down Arrow
bindkey '5~' kill-word

# History
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':fzf-tab:complete:z:*' fzf-preview 'ls --color $realpath'

# Aliases
alias ls="ls --color"
alias ll="ls -la"
alias cd="z"

# Custom additions
if [ -f $HOME/.extras.zsh ]; then
  source $HOME/.extras.zsh
fi

# Shell integrations
eval "$(zoxide init zsh)"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
