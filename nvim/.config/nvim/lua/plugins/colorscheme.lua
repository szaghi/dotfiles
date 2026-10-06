-- Solarized dark in 24-bit colour: exact hex values, no dependence on the
-- terminal palette (vim uses lifepillar/vim-solarized8 for the same reason).

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
