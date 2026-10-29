# Keep PATH entries unique, so nested shells (e.g. in tmux) don't keep appending duplicates
typeset -U path PATH

path=(
  $HOME/.local/bin
  $HOME/.local/share/bob/nvim-bin
  $HOME/.local/share/fnm
  $HOME/.yarn/bin
  $HOME/.config/yarn/global/node_modules/.bin
  $path
  $HOME/.dotnet/tools
)

# WSL opens shells in the Windows home folder (e.g. /mnt/c/Users/hub), start in the Linux home instead
[[ $PWD =~ '^/mnt/[a-z]/Users/[^/]+$' ]] && cd ~

# https://github.com/jeffreytse/zsh-vi-mode/issues/24#issuecomment-873029329
# Doing initialization at the plugin sourcing (Instantly)
ZVM_INIT_MODE=sourcing

# Define what to do after zsh-vi-mode initializes
function zvm_after_init() {
  # Initialize starship prompt
  eval "$(starship init zsh)"
}

# oh-my-zsh lib expects a cache dir
export ZSH_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/oh-my-zsh"
[ -d "$ZSH_CACHE_DIR" ] || mkdir -p "$ZSH_CACHE_DIR"

# Plugins are listed in ~/.zsh_plugins.txt
source ~/.antidote/antidote.zsh
antidote load

source ~/.history.zsh

# Node version manager, switches version on cd when a .node-version/.nvmrc is present
command -v fnm >/dev/null && eval "$(fnm env --use-on-cd --shell zsh)"

export EDITOR=nvim

source ~/.aliases.sh

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
# Use `` as the trigger sequence instead of the default **
export FZF_COMPLETION_TRIGGER='``'

# Setting rg as the default source for fzf
# Follow symbolic links, and don't want it to exclude hidden files, use the following command
export FZF_DEFAULT_COMMAND="rg --files --hidden --follow --glob '!.git'"

# To apply the command to CTRL-T as well
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

# Install zoxide, a smarter cd command
eval "$(zoxide init zsh)"

# Turn off all beeps
unsetopt BEEP

# Machine-specific settings (e.g. work proxy, company tools), not tracked in this repo
[ -f ~/.zshrc.local ] && source ~/.zshrc.local

# Work related
export CONTAINER_APP_ENV=local
