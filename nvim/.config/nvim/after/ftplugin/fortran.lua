-- Fortran local options (vim: ~/.vim/ftplugin/fortran.vim). The source form
-- is set in ftplugin/fortran.lua.

if vim.b.fortran_fixed_source == 1 then
   vim.opt_local.textwidth = 72
else
   vim.opt_local.textwidth = 132
   vim.opt_local.tabstop = 3
   vim.opt_local.shiftwidth = 3
   vim.opt_local.softtabstop = 3
   vim.opt_local.synmaxcol = 132
end
