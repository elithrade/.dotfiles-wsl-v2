# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Dotfiles and a one-shot installer for a WSL (Ubuntu 26.04) dev environment: zsh, tmux, Neovim (LazyVim) and their tools. `README.md` is the user-facing guide (setup, work machine, troubleshooting); keep it in sync when behaviour changes.

## How it fits together

- `./install` updates the `dotbot` submodule and runs dotbot on `install.conf.yaml`: `link` symlinks the configs into `~`, then `shell` runs each install step in order.
- Configs in `~` are symlinks into this repo, so editing `~/.zshrc` edits `zshrc` here, and checking out a branch changes the live config of every new shell.
- Larger steps live in `install.*` helper scripts (bash, `set -e`, skip when already installed); `install.nvim.lua` runs in headless nvim.
- The Neovim config is a separate repo, [nvim-lazy-v2](https://github.com/elithrade/nvim-lazy-v2), cloned to `~/.config/nvim`. `install.nvim.lua` restores plugins from its `lazy-lock.json`, installs Mason tools and treesitter parsers. Changes to plugins or LSP setup belong in that repo, not here.
- Windows Terminal settings are a JSON fragment (`windows-terminal/`), copied by `install.wt`, layered on top of each machine's own `settings.json`.
- Per-machine shell settings go in `~/.zshrc.local` (sourced by `zshrc`), never in this repo.

## Rules for installer changes

- **`./install` must stay safe to re-run** after a partial failure, on a machine that has an older setup, or behind a work proxy. Every step checks that its work is *finished* (a binary or marker file exists), not merely that a folder exists.
- New git clones go through `install.clone <url> <dir> <marker-file> [git clone options]`. It skips when the marker exists and origin matches (https and ssh forms count as the same), otherwise moves the folder to `<dir>.bak.<timestamp>` and clones again. Never `rm -rf` user data; move it aside.
- Plugin data in `~/.local/share/nvim` from a different nvim config gets pinned into `lazy-lock.json` (lazy.nvim writes every installed plugin's commit after any install), which is why `install.conf.yaml` moves it aside when `~/.config/nvim` isn't nvim-lazy-v2.
- A Lua error in `nvim --headless -c "luafile ..."` doesn't exit nvim and looks like a hang; keep `install.nvim.lua`'s `xpcall` wrapper and `cq` on failure.
- `curl` calls should use `-f` so HTTP errors fail the step instead of feeding an error page to the next command.
- git identity is only set when missing (work machines set their own first).
- Docker is deliberately not installed by `./install`.

## Testing

No test suite. Check changes without touching the daily setup:

- `./install --dry-run` lists every step dotbot would run; `./install --only link clean` re-applies only the symlinks (no sudo).
- Full runs need sudo (apt), so the user has to run them. The real test is a throwaway distro (`wsl --install Ubuntu-26.04 --name dottest`), running `./install` twice; see "Testing changes safely" in `README.md`.
- zsh changes: start `zsh -i` with a temporary `HOME` whose dotfiles symlink to the repo (README has the snippet), so `~/.zsh_history` and the live shell are untouched.
- Helper scripts: `bash -n install.<name>`, and exercise failure paths with a fake `curl` earlier in `PATH`.

## Git

- Commits here use the personal email (`elithrade@gmail.com`). The work laptop's global identity is the work email, so this repo sets `user.email` locally there.
- Work on a branch and open a PR to `main` (merge commits, not squash).
