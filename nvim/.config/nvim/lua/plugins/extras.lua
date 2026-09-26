-- Plugins with no vim counterpart, on trial. Kept in one file so any of them
-- can be dropped by deleting its block.
--
-- The terminal font (Cascadia Mono) has no Nerd Font glyphs, so every icon
-- is replaced by ASCII or plain Unicode.

-- trouble shows LSP symbol-kind icons; blank them all
local kinds = {}
for _, name in ipairs(vim.lsp.protocol.SymbolKind) do
   kinds[name] = ""
end

return {
   -- folke/trouble.nvim — navigable lists for diagnostics, symbols, quickfix
   {
      "folke/trouble.nvim",
      cmd = "Trouble",
      keys = {
         { "<leader>xx", "<cmd>Trouble diagnostics toggle<CR>", desc = "Diagnostics (workspace)" },
         { "<leader>xb", "<cmd>Trouble diagnostics toggle filter.buf=0<CR>", desc = "Diagnostics (buffer)" },
         { "<leader>xs", "<cmd>Trouble symbols toggle focus=false<CR>", desc = "Symbols" },
         { "<leader>xq", "<cmd>Trouble qflist toggle<CR>", desc = "Quickfix list" },
      },
      opts = {
         icons = {
            indent = { fold_open = "v ", fold_closed = "> " },
            folder_closed = "+ ",
            folder_open = "- ",
            kinds = kinds,
         },
      },
   },

   -- sindrets/diffview.nvim — tabpage for reviewing a diff or a file's history
   {
      "sindrets/diffview.nvim",
      cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory" },
      keys = {
         { "<leader>gD", "<cmd>DiffviewOpen<CR>", desc = "Diffview: working tree" },
         { "<leader>gH", "<cmd>DiffviewFileHistory %<CR>", desc = "Diffview: file history" },
      },
      opts = {
         use_icons = false,
         signs = { fold_closed = ">", fold_open = "v" },
      },
   },

   -- folke/todo-comments.nvim — highlight TODO/FIXME/NOTE/... in comments
   {
      "folke/todo-comments.nvim",
      event = { "BufReadPost", "BufNewFile" },
      dependencies = { "nvim-lua/plenary.nvim" },
      keys = {
         { "<leader>T", "<cmd>TodoFzfLua<CR>", desc = "Search TODO comments" },
      },
      opts = { signs = false },
   },

   -- MeanderingProgrammer/render-markdown.nvim — render markdown in the buffer
   -- (headings, tables, checkboxes, code blocks). Off by default: toggle it.
   {
      "MeanderingProgrammer/render-markdown.nvim",
      ft = "markdown",
      cmd = "RenderMarkdown",
      -- A plain key: an ft-scoped lazy key raised E31 when the ft trigger
      -- loaded the plugin first.
      keys = {
         { "<leader>m", "<cmd>RenderMarkdown toggle<CR>", desc = "Toggle markdown rendering" },
      },
      opts = {
         enabled = false,
         html = { enabled = false }, -- no html parser; HTML in notes is rare
         heading = { icons = { "# ", "## ", "### ", "#### ", "##### ", "###### " } },
         checkbox = {
            unchecked = { icon = "[ ] " },
            checked = { icon = "[x] " },
         },
      },
   },
}
