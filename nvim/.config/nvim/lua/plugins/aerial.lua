-- stevearc/aerial.nvim — symbol outline (vim: majutsushi/tagbar).
-- Symbols come from the language server first (fortls knows modules, types
-- and type-bound procedures), then treesitter; no ctags involved.
-- Unlike tagbar_sort, symbols stay in source order.

return {
   "stevearc/aerial.nvim",
   cmd = { "AerialToggle", "AerialOpen", "AerialNavToggle" },
   keys = {
      { "<F3>", "<cmd>AerialToggle! left<CR>", desc = "Toggle symbol outline" },
   },
   opts = {
      backends = { "lsp", "treesitter", "markdown", "man" },
      layout = {
         default_direction = "left", -- vim: tagbar_left
         min_width = 30, -- vim: tagbar_width
         max_width = { 40, 0.25 },
      },
      nerd_font = false,
   },
}
