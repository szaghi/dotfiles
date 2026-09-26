-- Editor options, ported from ~/.vimrc "Editing behaviour".
--
-- Only values that differ from Neovim's defaults are set. Already default in
-- Neovim: nocompatible, filetype plugin indent on, syntax on, autoindent,
-- hidden, hlsearch, incsearch, smarttab, wildmenu, showcmd, laststatus=2,
-- backspace=indent,eol,start, encoding=utf-8, nobackup, Y = y$, the :Man
-- command and the cursor shape per mode (vimrc's t_SI/t_EI).
--
-- undodir is deliberately NOT set: the default ~/.local/state/nvim/undo keeps
-- nvim's undo files away from vim's ~/.vim/undo.

-- Leaders before any mapping or plugin (vimrc sets mapleader after
-- plugconf#load(), so vim's plugconf <leader> maps land on '\' instead).
vim.g.mapleader = ","
vim.g.maplocalleader = ","

local opt = vim.opt

-- appearance
opt.termguicolors = true -- 24-bit colours: solarized.nvim does not use the terminal palette
opt.background = "dark"
opt.cursorline = true
opt.number = true
opt.relativenumber = true
opt.signcolumn = "yes"
opt.showtabline = 2
opt.title = true
opt.list = false
opt.listchars = { tab = "▸ ", trail = "·", extends = "#", nbsp = "·" }

-- indentation: 3 spaces, overridden per filetype in after/ftplugin
opt.tabstop = 3
opt.softtabstop = 3
opt.shiftwidth = 3
opt.expandtab = true
opt.shiftround = true
opt.copyindent = true

-- movement and search
opt.wrap = false
opt.scrolloff = 4
opt.sidescrolloff = 8
opt.virtualedit = "all"
opt.showmatch = true
opt.ignorecase = true
opt.smartcase = true
opt.mouse = "a"
opt.switchbuf = "useopen"

-- files
opt.swapfile = false
opt.undofile = true
-- vimrc intends this list, but its quoted form (set fileformats="...") is
-- parsed as a comment and leaves 'fileformats' empty in vim.
opt.fileformats = { "unix", "dos", "mac" }
opt.modeline = true
opt.modelines = 1 -- only the first line: reduces the modeline CVE surface

-- command line and diff
opt.wildmode = "list:full"
opt.formatoptions:append("1")
opt.diffopt:append("iwhite")

-- folding
opt.foldenable = true
opt.foldcolumn = "1"
opt.foldmethod = "marker"
opt.foldlevelstart = 0
opt.foldopen = "block,hor,insert,jump,mark,percent,quickfix,search,tag,undo"

-- syntax-based folding for the runtime syntax files that support it
vim.g.fortran_fold = 1
vim.g.fortran_fold_conditionals = 1
vim.g.sh_fold_enabled = 1
vim.g.xml_syntax_folding = 1

-- No remote plugins are used: skip provider probing at startup (and the
-- checkhealth warnings). markdown-preview runs its own node process.
vim.g.loaded_python3_provider = 0
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0

-- WSL clipboard for the + and * registers ('clipboard' stays empty, as in
-- vim). Copy via OSC 52: UTF-8 safe, unlike clip.exe. Windows Terminal does
-- not answer OSC 52 reads, so paste goes through PowerShell instead; its
-- console output defaults to the OEM code page, which mangles non-ASCII.
-- Elsewhere the provider is autodetected (wl-clipboard on quark/astrobit).
if vim.fn.has("wsl") == 1 then
   local osc52 = require("vim.ui.clipboard.osc52")
   local paste = {
      "powershell.exe", "-NoLogo", "-NoProfile", "-Command",
      "[Console]::OutputEncoding = [Text.Encoding]::UTF8; "
         .. '[Console]::Out.Write($(Get-Clipboard -Raw).ToString().Replace("`r", ""))',
   }
   vim.g.clipboard = {
      name = "wsl-osc52-powershell",
      copy = { ["+"] = osc52.copy("+"), ["*"] = osc52.copy("*") },
      paste = { ["+"] = paste, ["*"] = paste },
      cache_enabled = 0,
   }
end

-- filetype detection (vim: ftdetect/fobos.vim)
vim.filetype.add({
   pattern = {
      [".*/fobos[^/]*"] = "dosini",
      [".*%.fobos"] = "dosini",
   },
})
