-- Git.
--   lewis6991/gitsigns.nvim (vim: airblade/vim-gitgutter) — signs and hunks
--   tpope/vim-fugitive      (kept) — the git porcelain
--
-- Everything git lives under <leader>g. gitgutter's <leader>h* hunk maps
-- would collide with <leader>h (recent files), so hunks are <leader>g{h,a,u}.

return {
   {
      "lewis6991/gitsigns.nvim",
      event = { "BufReadPre", "BufNewFile" },
      opts = {
         on_attach = function(buf)
            local gs = require("gitsigns")
            local function map(mode, lhs, rhs, desc)
               vim.keymap.set(mode, lhs, rhs, { buffer = buf, desc = desc })
            end
            -- ]c / [c jump between hunks, or between changes in diff mode
            map("n", "]c", function()
               if vim.wo.diff then
                  vim.cmd.normal({ "]c", bang = true })
               else
                  gs.nav_hunk("next")
               end
            end, "Next hunk")
            map("n", "[c", function()
               if vim.wo.diff then
                  vim.cmd.normal({ "[c", bang = true })
               else
                  gs.nav_hunk("prev")
               end
            end, "Previous hunk")
            map("n", "<leader>gh", gs.preview_hunk, "Preview hunk")
            map("n", "<leader>ga", gs.stage_hunk, "Stage hunk")
            map("n", "<leader>gu", gs.reset_hunk, "Reset hunk")
         end,
      },
   },
   {
      "tpope/vim-fugitive",
      cmd = { "Git", "G", "Gdiffsplit", "Gvdiffsplit", "Gread", "Gwrite", "GBrowse" },
      keys = {
         { "<leader>gs", "<cmd>Git<CR>", desc = "Git status" },
         { "<leader>gb", "<cmd>Git blame<CR>", desc = "Git blame" },
         { "<leader>gd", "<cmd>Gdiffsplit<CR>", desc = "Git diff split" },
         { "<leader>gl", "<cmd>Git log --oneline --decorate --all<CR>", desc = "Git log" },
         { "<leader>gc", "<cmd>Git commit<CR>", desc = "Git commit" },
         { "<leader>gp", "<cmd>Git push<CR>", desc = "Git push" },
      },
   },
}
