-- Editing helpers.
--   kylechui/nvim-surround  (vim: tpope/vim-surround) — same ys/cs/ds/S keys,
--                           dot-repeat built in (no vim-repeat needed)
--   windwp/nvim-autopairs   (vim: cohama/lexima.vim)
-- Commenting (vim: tpope/vim-commentary) is built into Neovim: gc / gcc.

return {
   {
      "kylechui/nvim-surround",
      event = "VeryLazy",
      opts = {},
   },
   {
      "windwp/nvim-autopairs",
      event = "InsertEnter",
      opts = {
         map_cr = false, -- <CR> is mapped below, together with completion
      },
      config = function(_, opts)
         local npairs = require("nvim-autopairs")
         npairs.setup(opts)
         -- <CR>: accept the selected completion item if the popup is open,
         -- otherwise let autopairs expand (vim: pumvisible() ? <C-y> : lexima).
         -- autopairs_cr() returns already-escaped keys: no replace_keycodes.
         local accept = vim.api.nvim_replace_termcodes("<C-y>", true, false, true)
         vim.keymap.set("i", "<CR>", function()
            if vim.fn.pumvisible() == 1 then
               return accept
            end
            return npairs.autopairs_cr()
         end, { expr = true, replace_keycodes = false, desc = "Accept completion / autopairs CR" })
      end,
   },
}
