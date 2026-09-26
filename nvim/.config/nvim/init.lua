-- Neovim entry point. Independent from vim: nothing here reads ~/.vimrc or
-- ~/.vim, and every piece of state (plugins, undo, shada) lives under the XDG
-- dirs (~/.local/share/nvim, ~/.local/state/nvim), never under ~/.vim.
--
-- Order matters: options sets the leader keys, which must exist before
-- lazy.nvim registers plugin keymaps.

require("config.options")
require("config.keymaps")
require("config.autocmds")
require("config.lazy")
