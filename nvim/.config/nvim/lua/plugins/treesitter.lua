-- Treesitter: parsers, highlighting, folds, and plugins built on the syntax tree.
--
-- nvim-treesitter's main branch only installs parsers and queries; Neovim does
-- the highlighting and folding, enabled per buffer by the FileType autocmd
-- below. Parsers go to ~/.local/share/nvim/site (needs the tree-sitter CLI and
-- a C compiler, provided by ~/.scripts/install-nvim).
--
-- Fortran: 0 parse errors over the 189 first-party files of ~/fortran/adam
-- (OpenACC/OpenMP directives and cpp blocks included), so treesitter replaces
-- vim's regex syntax there too.

local parsers = {
   "fortran", "python", "bash", "c", "cpp", "cuda", "make", "cmake",
   "lua", "vim", "vimdoc", "query", "regex",
   "markdown", "markdown_inline", "latex", "bibtex",
   "json", "yaml", "toml", "ini",
   "diff", "gitcommit", "git_rebase",
}

-- vimtex needs its own syntax (motions, text objects, concealment); the latex
-- parser is still used for rainbow delimiters and for math in markdown.
local no_highlight = { tex = true, plaintex = true }

return {
   {
      "nvim-treesitter/nvim-treesitter",
      branch = "main",
      lazy = false, -- the main branch does not support lazy-loading
      build = ":TSUpdate",
      config = function()
         -- no-op for parsers already installed; provisions a new host
         require("nvim-treesitter").install(parsers)

         vim.api.nvim_create_autocmd("FileType", {
            group = vim.api.nvim_create_augroup("treesitter_start", { clear = true }),
            callback = function(ev)
               if no_highlight[ev.match] then
                  return
               end
               local lang = vim.treesitter.language.get_lang(ev.match)
               if not lang or not pcall(vim.treesitter.start, ev.buf, lang) then
                  return
               end
               -- Regex syntax is now off, so foldmethod=syntax (set in
               -- config/autocmds.lua) would find no folds: fold on the tree.
               -- Runs after the filetype plugins, so it wins wherever a
               -- parser has fold queries; autocmds.lua is the fallback.
               if vim.treesitter.query.get(lang, "folds") then
                  vim.wo[0][0].foldmethod = "expr"
                  vim.wo[0][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
               end
            end,
         })
      end,
   },

   -- Sticky header with the enclosing module / procedure / block when its
   -- first line has scrolled off screen.
   {
      "nvim-treesitter/nvim-treesitter-context",
      event = { "BufReadPost", "BufNewFile" },
      opts = { max_lines = 3 },
   },

   -- Nested brackets in alternating colours (vim: junegunn/rainbow_parentheses).
   -- Fortran has no upstream query: see queries/fortran/rainbow-delimiters.scm.
   { "HiPhish/rainbow-delimiters.nvim", lazy = false },
}
