source ~/antigen.zsh

# https://github.com/jeffreytse/zsh-vi-mode/issues/24#issuecomment-873029329
# Doing initialization at the plugin sourcing (Instantly)
ZVM_INIT_MODE=sourcing

antigen use oh-my-zsh
antigen bundle zsh-users/zsh-autosuggestions
antigen bundle jump
antigen bundle jeffreytse/zsh-vi-mode

# Syntax highlighting bundle.
antigen bundle zsh-users/zsh-syntax-highlighting

antigen apply

source ~/.history.zsh

# Initialize starship prompt
eval "$(starship init zsh)"

# Make Vi mode transitions faster (KEYTIMEOUT is in hundredths of a second)
export KEYTIMEOUT=1

export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

export EDITOR=nvim
export PATH=$PATH:$HOME/.local/bin

source ~/.aliases.sh

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
# Use `` as the trigger sequence instead of the default **
export FZF_COMPLETION_TRIGGER='``'

# Setting rg as the default source for fzf
# Follow symbolic links, and don't want it to exclude hidden files, use the following command
export FZF_DEFAULT_COMMAND="rg --files --hidden --follow --glob '!.git'"

# To apply the command to CTRL-T as well
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Install zoxide, a smarter cd command
eval "$(zoxide init zsh)"
