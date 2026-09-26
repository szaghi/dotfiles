-- stevearc/conform.nvim — formatting (vim: ALE fixers).
-- Python is fixed and formatted on save (vim: b:ale_fix_on_save for python);
-- every other filetype formats only on demand with <leader>lf.
-- Linting moved to language servers: ruff server (Python) and
-- bash-language-server, which runs shellcheck itself.

return {
   "stevearc/conform.nvim",
   event = "BufWritePre",
   cmd = "ConformInfo",
   keys = {
      {
         "<leader>lf",
         function()
            require("conform").format({ async = true, lsp_format = "fallback" })
         end,
         desc = "Format buffer",
      },
   },
   opts = {
      formatters_by_ft = {
         python = { "ruff_fix", "ruff_format" },
      },
      format_on_save = function(buf)
         if vim.bo[buf].filetype == "python" then
            return { timeout_ms = 2000, lsp_format = "never" }
         end
      end,
   },
}
