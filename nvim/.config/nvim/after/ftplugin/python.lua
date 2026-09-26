-- Python local options (vim: ~/.vim/ftplugin/python.vim). vim's
-- python_highlight_* globals are dropped with python-syntax; treesitter
-- supplies the highlighting and the folds (functions, classes, blocks),
-- replacing vim's foldmethod=indent.

vim.opt_local.expandtab = true
vim.opt_local.tabstop = 4
vim.opt_local.shiftwidth = 4
vim.opt_local.softtabstop = 4
vim.opt_local.textwidth = 300
