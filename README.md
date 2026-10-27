# .dotfiles-wsl-v2

This repo contains config files for my WSL environment.

All Neovim configs are now managed by [nvim-lazy](https://github.com/elithrade/nvim-lazy).

## Installation

- Install `zsh` via `sudo apt install zsh && chsh -s $(which zsh)`
- Clone the repo and `cd ~/.dotfiles-wsl-v2/`
- `./install` (safe to re-run, already installed tools are skipped)
- Ensure `tmux` plugins are installed by `prefix + shift + i`
- `fnm install --lts` to install the latest node LTS
- `fnm default lts-latest`
- Restart WSL

## Tools

- zsh plugins are managed by [antidote](https://github.com/mattmc3/antidote), listed in `zsh_plugins.txt`
- Neovim versions are managed by [bob](https://github.com/MordechaiHadad/bob), e.g. `bob use nightly`
- Node versions are managed by [fnm](https://github.com/Schniz/fnm)
