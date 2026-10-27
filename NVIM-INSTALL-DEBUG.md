# Neovim install hang / mason-lspconfig error: findings and fixes

Context: `install.conf.yaml` runs `nvim --headless -c "luafile install.nvim.lua"`
(Lazy restore, Mason tools, treesitter parsers) against `~/.config/nvim`
(elithrade/nvim-lazy-v2, LazyVim 16.0.1).

## Issue 1: the install script hangs

### Reports

- **Hang A:** the script appeared stuck on "random" plugins while
  `Lazy! restore` printed `[plugin] fetch/status/checkout | ...` lines.
  The last lines were `[nvim-dap] checkout | Finished ...` and
  `[which-key.nvim] checkout | Finished ...`.
- **Hang B:** on a later run it stopped after
  `mason: refreshing registry` and `mason: installing tools` and never finished.

### Findings

- **Hang A:** the checkout lines are normal output of `Lazy! restore`.
  No fetch, checkout or status task was actually stuck.
  The apparent hang was most likely the same failure mode as Hang B, a Lua error
  after the restore step (see below). I never reproduced Hang A on its own,
  so this explanation is inferred, not proven.
- **Hang B:** I inspected the hung process (`/proc/<pid>`).
  It was idle in `epoll_wait` with no child processes and no pending Mason install
  (the Mason log showed every package had succeeded).
  That means it was not waiting on the network or a package.
  The script was in a state where nothing would ever wake it.
- **Root cause (both):** a Lua error inside `nvim --headless -c "luafile ..."`
  does not exit nvim. The error is printed, the chunk is aborted, and nvim sits
  waiting forever because `vim.cmd("qa!")` at the end is never reached.
  An erroring script therefore looks like a hang.
  Here the error came from the script calling Mason APIs that did not match the
  installed plugin versions (see Issue 2), at `install.nvim.lua`'s
  `require("mason-lspconfig...ensure_installed")` and `p:is_installing()` calls.
- Running two nvim installs at once (I had one in the background while you ran
  another) also happened during debugging. I don't believe it contributed to the
  hang, but it is worth avoiding.

### Fix

`install.nvim.lua`: the body is wrapped in `local function run() ... end` and
called with `xpcall(run, debug.traceback)`.
On error it logs `install failed: <traceback>` and runs `cq`, so the script
exits non-zero. The existing `cq` for the registry-refresh timeout also works
inside the wrapper.

## Issue 2: `mason-lspconfig.mappings` not found when starting nvim

### Symptom

`Failed to run config for nvim-lspconfig ... lazyvim/plugins/lsp/init.lua:240:
module 'mason-lspconfig.mappings' not found`.

### Findings

- The installed `mason.nvim` and `mason-lspconfig.nvim` were the old v1 releases
  (commits `fc98833` and `1a31f82`, Feb 2025).
  `~/.config/nvim/lazy-lock.json` had been rewritten to those commits.
  The committed lockfile pins the v2 releases (`2a6940a` and `a338f44`).
  LazyVim 16 needs v2, and v1 has no `mason-lspconfig.mappings` module
  (only a `mappings/` directory with no `init.lua`).
- I do not know why the plugins ended up on v1 or why the lockfile was
  rewritten. Both remotes are `mason-org/*`, and no spec pins
  `version = "^1"`. `lua/plugins/example.lua` is disabled (`if true then return {} end`).
  The lockfile showed as modified in git (`M`).
- **Misdiagnosis along the way:** while the v1 plugins were installed, I changed
  `install.nvim.lua` to the v1 API (`mason-lspconfig.ensure_installed`,
  `Package:get_handle()`). That was wrong. The original v2 calls
  (`mason-lspconfig.features.ensure_installed`, `p:is_installing()`) are
  correct, and I reverted those changes.

### Fix

`git checkout lazy-lock.json` in `~/.config/nvim`, then re-ran the install
script so `Lazy! restore` checked out the pinned v2 plugins
(`mason-lspconfig.nvim` is now at `a338f44`).

## Verification done

- The install script ran to exit 0. Mason installed codelldb, csharpier,
  eslint-lsp, js-debug-adapter, json-lsp, lua-language-server, markdown-toc,
  markdownlint-cli2, marksman, netcoredbg, prettier, roslyn-language-server,
  shfmt, stylua, tree-sitter-cli and vtsls. Treesitter parsers were installed
  (29/29 in an earlier run).
- `nvim --headless -c "lua require('lazy').load({plugins={'nvim-lspconfig'}})" -c "qa!"`
  produced no errors.
- I did not open the full LazyVim UI.

## Please verify (on another machine)

- Fresh run: remove `~/.local/share/nvim/lazy` and `~/.local/state/nvim/mason.log`,
  then run the install script.
  It should exit 0, `git -C ~/.config/nvim status` should show no changes to
  `lazy-lock.json`, and starting `nvim` should show no lspconfig error.
- Check that `git -C ~/.local/share/nvim/lazy/mason-lspconfig.nvim log -1`
  is `a338f44` and `mason.nvim` is `2a6940a`.
- Confirm the hang is fixed: add a temporary `error("x")` at the top of `run()`
  in `install.nvim.lua`. The script should print `install failed: ...` and exit
  non-zero instead of hanging. Remove it afterwards.
- If the lockfile gets rewritten to the `1a31f82` / `fc98833` commits again,
  find what triggers it. Suspects are a stale `~/.local/share/nvim/lazy` from an
  earlier install, or an older nvim config or branch being used.
- Hang A (stuck during the restore output) was not reproduced on its own.
  If you still see a stall there on a clean run, capture `ps` and `/proc/<pid>/wchan`
  for the nvim process and any child `git` processes.
