-- vimscript plugins kept from the vim setup: they work unchanged in Neovim and
-- have no better Lua replacement. Installed separately from vim's copies
-- (~/.local/share/nvim/lazy, not ~/.vim/plugged).

return {
   -- LaTeX. vimtex asks not to be lazy-loaded: it sets up filetype detection
   -- and its own ftplugin at startup.
   {
      "lervag/vimtex",
      lazy = false,
      init = function()
         vim.g.vimtex_view_general_viewer = "evince"
      end,
   },

   -- Markdown preview in the browser (vim: plugconf/markdown-preview.vim;
   -- only the values that differ from the plugin defaults are kept).
   {
      "iamcco/markdown-preview.nvim",
      ft = "markdown",
      cmd = { "MarkdownPreview", "MarkdownPreviewStop", "MarkdownPreviewToggle" },
      -- Load first: build runs before a lazy (ft) plugin is on the rtp, so
      -- its autoload functions are unknown. install_sync: the async
      -- mkdp#util#install() downloads the prebuilt binary in a terminal job
      -- that a headless `Lazy! sync` never awaits.
      build = function()
         require("lazy").load({ plugins = { "markdown-preview.nvim" } })
         vim.fn["mkdp#util#install_sync"]()
      end,
      init = function()
         vim.g.mkdp_auto_close = 0
         vim.g.mkdp_theme = "dark"
      end,
   },

   -- Encrypted files (*.gpg, *.asc, *.pgp). Not lazy: it hooks BufReadCmd,
   -- which must exist before the first encrypted file is read.
   { "jamessan/vim-gnupg", lazy = false },

   -- Alignment (vim also had godlygeek/tabular, redundant with this one).
   { "junegunn/vim-easy-align", cmd = { "EasyAlign", "LiveEasyAlign" } },

   -- Column increments in visual-block mode (:I, :II, :IX, :IYMD, ...).
   {
      "vim-scripts/VisIncr",
      cmd = { "I", "II", "IB", "IIB", "IO", "IIO", "IX", "IIX", "IYMD", "IMDY", "IDMY", "IA", "ID", "IM", "IPOW", "IIPOW" },
   },

   -- Evaluate arithmetic in a visual selection.
   { "sk1418/HowMuch", cmd = "HowMuch" },

   -- CSV-ish selection to markdown table (:MakeTable, :UnmakeTable).
   { "mattn/vim-maketable", cmd = { "MakeTable", "UnmakeTable" } },
}
