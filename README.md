# .dotfiles-wsl-v2

This repo contains config files for my WSL environment.

All Neovim configs are now managed by [nvim-lazy](https://github.com/elithrade/nvim-lazy).

## Installation

- Install `zsh` via `sudo apt install zsh && chsh -s $(which zsh)`
- Clone the repo and `cd ~/.dotfiles-wsl-v2/`
- `./install`
- Ensure `tmux` plugins are installed by `prefix + shift + i`
- `nvm install --lts` to install the latest node LTS
- `nvm use --lts`
- Restart WSL
