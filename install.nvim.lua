-- Headless setup for the LazyVim config: plugins, Mason tools and treesitter parsers.
-- Usage: nvim --headless -c "luafile install.nvim.lua"

local function log(msg)
  io.stdout:write(msg .. "\n")
  io.stdout:flush()
end

local timeout = 30 * 60 * 1000

-- A Lua error in a -c luafile leaves headless nvim running forever, so fail instead
local function run()

-- Plugins, pinned to lazy-lock.json
log("lazy: restoring plugins")
vim.cmd("Lazy! restore")

-- Loading these runs LazyVim's own config, which starts installing every tool in its ensure_installed lists
require("lazy").load({ plugins = { "mason.nvim", "mason-lspconfig.nvim", "nvim-lspconfig", "mason-nvim-dap.nvim" } })

local mr = require("mason-registry")
log("mason: refreshing registry")
local refreshed = false
mr.refresh(function()
  refreshed = true
end)
-- The registry is a small download, if it takes this long the network is blocking it
if not vim.wait(2 * 60 * 1000, function()
  return refreshed
end, 200) then
  log("mason: registry refresh timed out, check network access to github.com")
  vim.cmd("cq")
end

log("mason: installing tools")

-- mason-lspconfig skips its ensure_installed in headless mode, so run it ourselves
require("mason-lspconfig.features.ensure_installed")()

local function installing()
  local names = {}
  for _, p in ipairs(mr.get_all_packages()) do
    if p:is_installing() then
      table.insert(names, p.name)
    end
  end
  return names
end

-- Wait until nothing has been installing for a few seconds, installs can be queued one after another
local idle_since = vim.uv.now()
local last = ""
vim.wait(timeout, function()
  local names = installing()
  if #names > 0 then
    idle_since = vim.uv.now()
    local current = table.concat(names, ", ")
    if current ~= last then
      log("mason installing: " .. current)
      last = current
    end
  end
  return vim.uv.now() - idle_since > 5000
end, 500)
log("mason installed: " .. table.concat(mr.get_installed_package_names(), ", "))

-- Treesitter parsers, built with the tree-sitter CLI that Mason just installed
log("treesitter: installing parsers")
require("lazy").load({ plugins = { "nvim-treesitter" } })
local parsers = LazyVim.opts("nvim-treesitter").ensure_installed or {}
require("nvim-treesitter").install(parsers, { summary = true }):wait(timeout)
log("treesitter parsers: " .. table.concat(require("nvim-treesitter").get_installed(), ", "))

end

local ok, err = xpcall(run, debug.traceback)
if not ok then
  log("install failed: " .. tostring(err))
  vim.cmd("cq")
end
vim.cmd("qa!")
