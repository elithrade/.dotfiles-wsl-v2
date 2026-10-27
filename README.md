# .dotfiles-wsl-v2

Config files and a one-shot installer for my WSL environment: zsh, tmux, Neovim (LazyVim) and the tools they depend on.

Neovim configs live in a separate repo, [nvim-lazy-v2](https://github.com/elithrade/nvim-lazy-v2). `./install` clones it to `~/.config/nvim` and installs its plugins, Mason tools and treesitter parsers.

## Set up a new machine

1. Create a WSL distro (PowerShell), and pick a username and password at the first launch:

   ```powershell
   wsl --install Ubuntu-26.04
   ```

2. Install the prerequisites and clone the repo over https (no SSH key needed yet):

   ```sh
   sudo apt update && sudo apt install -y git zsh && chsh -s $(which zsh)
   git clone https://github.com/elithrade/.dotfiles-wsl-v2.git ~/.dotfiles-wsl-v2
   cd ~/.dotfiles-wsl-v2
   git remote set-url --push origin git@github.com:elithrade/.dotfiles-wsl-v2.git
   ```

3. Run the installer, it asks for the sudo password once:

   ```sh
   ./install
   ```

4. Open a new terminal. If zsh shows its first-run menu, press `q`.

5. Manual steps the installer can't do:
   - SSH key for GitHub: `ssh-keygen -t ed25519` and add `~/.ssh/id_ed25519.pub` to GitHub, or copy `~/.ssh` from another distro:
     `tar -C ~ -cf - .ssh | wsl.exe -d <new-distro> -u <user> -- tar -C /home/<user> -xf -` (run in the old distro), then `chmod 700 ~/.ssh && chmod 600 ~/.ssh/id_ed25519` in the new one
   - Sign in once: `gh auth login`, `claude` (follow the prompt), `copilot` then `/login`

`./install` is safe to re-run at any time. Already installed tools and existing clones are skipped, so re-running after pulling changes only applies what is new.

## What `./install` does

Defined in `install.conf.yaml`, run by [dotbot](https://github.com/anishathalye/dotbot):

- Links the configs into `~` (see [Files](#files))
- Sets git `user.name`, `user.email` and `init.defaultBranch`, only when missing
- apt: build tools, ripgrep, fd, unzip, xclip, chafa, .NET 10 SDK, then `fd` → `fdfind` link
- csharpier as a global dotnet tool (used by conform.nvim for C# formatting)
- Neovim via bob, antidote, starship, fnm + latest Node LTS, fzf, zoxide, lazygit
- GitHub CLI (from GitHub's apt repository), Claude Code and GitHub Copilot CLI
- tpm and the tmux plugins listed in `tmux.conf`
- Neovim config, then `install.nvim.lua` runs headless nvim to install plugins (pinned by `lazy-lock.json`), Mason tools and treesitter parsers

## Files

| File | Linked to | Purpose |
|---|---|---|
| `zshrc` | `~/.zshrc` | Shell config, PATH, tool init |
| `zsh_plugins.txt` | `~/.zsh_plugins.txt` | zsh plugins loaded by antidote |
| `aliases.sh` | `~/.aliases.sh` | Aliases |
| `history.zsh` | `~/.history.zsh` | History options |
| `tmux.conf` | `~/.tmux.conf` | tmux config and plugins |
| `starship.toml` | `~/.config/starship.toml` | Prompt config |
| `install.conf.yaml` | | Installer steps |
| `install.bob`, `install.lazygit`, `install.gh` | | Helper install scripts |
| `install.nvim.lua` | | Headless Neovim setup |

Configs are symlinks into this repo, so editing `~/.zshrc` edits the repo file. Checking out another branch changes the live config of every new shell, see [Testing changes](#testing-changes-safely).

## Tools

- zsh plugins: [antidote](https://github.com/mattmc3/antidote), add a line to `zsh_plugins.txt` (`zsh-syntax-highlighting` must stay last)
- Neovim versions: [bob](https://github.com/MordechaiHadad/bob), e.g. `bob use nightly`, `bob use stable`
- Node versions: [fnm](https://github.com/Schniz/fnm), same commands as nvm (`fnm install 22`, `fnm use 22`, `fnm default 22`), switches automatically on `cd` into a project with `.nvmrc` / `.node-version`
- tmux plugins: [tpm](https://github.com/tmux-plugins/tpm), add `set -g @plugin '...'` to `tmux.conf` then `prefix + I`
- Mason tools: add them to `ensure_installed` in the Neovim config, `./install` and LazyVim pick them up from there

tmux prefix is `Ctrl+Space`. Splits: `prefix -` (top/bottom), `prefix \` (side by side, full height), `prefix |` (side by side, current pane).

## Testing changes safely

Test installer changes in a throwaway distro instead of the daily one (PowerShell):

```powershell
wsl --install Ubuntu-26.04 --name dottest   # separate distro, the daily one is untouched
wsl -d dottest --cd "~"                     # quote the ~, PowerShell expands it to the Windows home otherwise
wsl --unregister dottest                    # delete it when done
```

Inside it, clone the branch under test and run `./install`, ideally twice to check re-runs.

An unpushed branch can be copied in with a git bundle:

```sh
git bundle create /mnt/c/Users/<windows-user>/AppData/Local/Temp/dotfiles.bundle <branch>   # in the daily distro
git clone -b <branch> /mnt/c/Users/<windows-user>/AppData/Local/Temp/dotfiles.bundle ~/.dotfiles-wsl-v2   # in dottest
```

For quick checks of zsh changes without a new distro, start a shell with a temporary `HOME` that links to the repo files:

```sh
T=$(mktemp -d) && git clone -q --depth=1 https://github.com/mattmc3/antidote.git $T/.antidote
for f in zshrc zsh_plugins.txt history.zsh aliases.sh; do ln -s ~/.dotfiles-wsl-v2/$f $T/.$f; done
HOME=$T zsh -i
```

## Troubleshooting

- **`[WARN] starship::context: Scanning current directory timed out`**: the shell is on a Windows drive (`/mnt/c/...`), where file access is slow. `starship.toml` raises `scan_timeout`, and `zshrc` moves shells that start in the Windows home folder to `~`.
- **tmux prefix seems dead, no `^SPACE` in the status bar, `prefix -` / `prefix \` do nothing**: the tmux plugins are not installed. Run `prefix + I` or `~/.tmux/plugins/tpm/bin/install_plugins`. To check whether the prefix itself arrives, run `tmux list-clients -F '#{client_prefix}'` right after pressing it (1 means received).
- **`command not found` errors from `antidote` in new shells**: the branch checked out needs `./install` to be run first (switching branches doesn't install anything).
- **Mason LSP servers missing after a headless install**: mason-lspconfig skips installs in headless mode, `install.nvim.lua` works around it. Opening nvim normally also installs anything missing.
- **`git status` in `~/.config/nvim` shows `lazy-lock.json` modified on a new machine**: the lockfile on GitHub is out of date, commit and push it from the machine where plugins were last updated.
