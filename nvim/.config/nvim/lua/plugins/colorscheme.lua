-- Solarized dark in 24-bit colour. vim's altercation/vim-colors-solarized maps
-- onto the 16-colour terminal palette (hence quark's noctalia-foot-fix-bright0
-- patch); this one sets exact hex values and does not depend on the palette.

return {
   "maxmx03/solarized.nvim",
   lazy = false,
   priority = 1000,
   opts = {},
   config = function(_, opts)
      require("solarized").setup(opts)
      vim.cmd.colorscheme("solarized")
      -- vimrc: hi clear SpellBad | hi SpellBad cterm=underline
      vim.api.nvim_set_hl(0, "SpellBad", { underline = true })
   end,
}
