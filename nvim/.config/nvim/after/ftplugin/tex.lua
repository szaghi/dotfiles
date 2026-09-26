-- LaTeX local options (vim: ~/.vim/ftplugin/tex.vim). vimtex settings live in
-- the vimtex plugin spec.

vim.opt_local.spell = true
vim.opt_local.spelllang = "en"
vim.cmd("syntax spell toplevel")
vim.opt_local.textwidth = 175
vim.opt_local.formatoptions:append("t")
vim.opt_local.formatoptions:remove("l")
vim.opt_local.synmaxcol = 0
