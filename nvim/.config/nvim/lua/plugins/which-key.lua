-- folke/which-key.nvim — pops up the continuations of a pending key sequence,
-- labelled with each mapping's desc. Useful while the keymaps settle.

return {
   "folke/which-key.nvim",
   event = "VeryLazy",
   opts = {
      spec = {
         { "<leader>g", group = "git" },
         { "<leader>l", group = "lsp" },
      },
   },
}
