-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
local opt = vim.opt
opt.clipboard = "unnamedplus" -- sync with system clipboard (wl-clipboard)
opt.expandtab = false -- use real tabs for indentation
opt.autoindent = true
opt.smartindent = true
opt.tabstop = 4
opt.shiftwidth = 4
opt.softtabstop = 4

-- Desktop launchers can omit rustup's binary directory from PATH. Keep
-- Rustaceanvim on the rustup-managed rust-analyzer instead of Mason's copy.
local rustup_bin = "/usr/lib/rustup/bin"
if vim.uv.fs_stat(rustup_bin) and not vim.env.PATH:find(rustup_bin, 1, true) then
  vim.env.PATH = rustup_bin .. ":" .. vim.env.PATH
end

vim.filetype.add({ extension = { scajl = "scajl" } })
