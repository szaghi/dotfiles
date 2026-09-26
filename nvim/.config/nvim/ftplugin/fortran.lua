-- Runs BEFORE $VIMRUNTIME/ftplugin/fortran.vim and syntax/fortran.vim, which
-- read b:fortran_fixed_source. Decided per buffer, never via g:, so the form
-- of one file does not stick to the next one opened. Local options are in
-- after/ftplugin/fortran.lua, so the runtime ftplugin cannot override them.

local ext = vim.fn.expand("%:e"):lower()
local fixed = { f77 = true, f = true, ["for"] = true, fpp = true, fortran = true }
vim.b.fortran_fixed_source = fixed[ext] and 1 or 0
