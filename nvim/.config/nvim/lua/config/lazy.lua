-- lazy.nvim bootstrap and setup. Plugins install into
-- ~/.local/share/nvim/lazy, never into ~/.vim/plugged (vim-plug's tree).
-- lazy-lock.json is written next to init.lua and is committed, so every host
-- runs the same plugin revisions; update deliberately with :Lazy update.

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
   local lazyrepo = "https://github.com/folke/lazy.nvim.git"
   local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
   if vim.v.shell_error ~= 0 then
      vim.api.nvim_echo({
         { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
         { out, "WarningMsg" },
         { "\nPress any key to exit..." },
      }, true, {})
      vim.fn.getchar()
      os.exit(1)
   end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
   spec = { { import = "plugins" } },
   install = { colorscheme = { "solarized", "habamax" } },
   -- No background git traffic: updates happen only on :Lazy update.
   checker = { enabled = false },
   change_detection = { notify = false },
   -- No plugin here needs luarocks; skip hererocks and its health warnings.
   rocks = { enabled = false },
   performance = {
      rtp = {
         disabled_plugins = { "gzip", "tarPlugin", "tohtml", "tutor", "zipPlugin" },
      },
   },
})
