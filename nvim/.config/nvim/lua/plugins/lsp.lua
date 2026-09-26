-- Native LSP client (vim: yegappan/lsp + plugconf/lsp.vim).
--
-- nvim-lspconfig is used only as a data package: it ships lsp/<name>.lua
-- server definitions (cmd, filetypes, root markers) on the runtimepath.
-- vim.lsp.config overrides them, vim.lsp.enable turns them on.
--
-- No mason: the servers are provisioned by ~/.scripts/install-vim-lsp.sh and
-- shared with vim (stateless processes, one install for both editors).

-- server name -> executable that must be on $PATH
local servers = {
   fortls = "fortls",
   basedpyright = "basedpyright-langserver",
   ruff = "ruff",
   texlab = "texlab",
   bashls = "bash-language-server",
}

local function on_attach(ev)
   local client = vim.lsp.get_client_by_id(ev.data.client_id)
   if not client then
      return
   end
   local buf = ev.buf

   -- basedpyright owns hover; ruff owns lint and fixes (ruff docs' split).
   if client.name == "ruff" then
      client.server_capabilities.hoverProvider = false
   end

   -- Manual completion only (vim: autoComplete false); <Tab> triggers it.
   if client:supports_method("textDocument/completion") then
      vim.lsp.completion.enable(true, client.id, buf, { autotrigger = false })
   end

   local function map(lhs, rhs, desc, opts)
      vim.keymap.set("n", lhs, rhs, vim.tbl_extend("force", { buffer = buf, desc = desc }, opts or {}))
   end
   -- K (hover) and <C-s> (signature help, insert mode) are Neovim defaults.
   map("gd", vim.lsp.buf.definition, "Goto definition")
   -- nowait: fire at once instead of waiting for the default grn/gra/grr/gri
   map("gr", vim.lsp.buf.references, "References (quickfix)", { nowait = true })
   -- ,lr not ,rn: ,r is grep, and a ,rn map would delay it by 'timeoutlen'
   map("<leader>lr", vim.lsp.buf.rename, "Rename symbol")
   map("<leader>la", vim.lsp.buf.code_action, "Code action")
   map("<leader>ld", vim.diagnostic.open_float, "Line diagnostics")
   map("[d", function()
      vim.diagnostic.jump({ count = -1, float = true })
   end, "Previous diagnostic")
   map("]d", function()
      vim.diagnostic.jump({ count = 1, float = true })
   end, "Next diagnostic")
end

-- <Tab> completion (vim: s:LspTabComplete):
--   popup visible      -> select next item
--   after a word char  -> LSP completion if a server offers it, else omnifunc
--   otherwise          -> literal <Tab>
local function tab_complete()
   if vim.fn.pumvisible() == 1 then
      return "<C-n>"
   end
   local col = vim.fn.col(".") - 1
   if col == 0 or vim.fn.getline("."):sub(col, col):match("%s") then
      return "<Tab>"
   end
   if #vim.lsp.get_clients({ bufnr = 0, method = "textDocument/completion" }) > 0 then
      return "<Cmd>lua vim.lsp.completion.get()<CR>"
   end
   return "<C-x><C-o>"
end

return {
   "neovim/nvim-lspconfig",
   lazy = false,
   config = function()
      vim.diagnostic.config({
         -- vim: gutter signs, highlighted ranges, message on demand only
         signs = {
            text = {
               [vim.diagnostic.severity.ERROR] = "✗",
               [vim.diagnostic.severity.WARN] = "!",
            },
         },
         underline = true,
         virtual_text = false,
         severity_sort = true,
         float = { source = true },
      })

      vim.lsp.config("fortls", {
         cmd = { "fortls", "--notify_init", "--hover_signature", "--use_signature_help", "--lowercase_intrinsics" },
         -- fortls diagnostics are dropped: on repos with FoBiS-fetched
         -- third-party libs and FORD shadow trees it reports spurious errors
         -- for every shadow-duplicated module. Navigation, hover, completion
         -- and references are unaffected.
         handlers = {
            ["textDocument/publishDiagnostics"] = function() end,
         },
      })

      vim.api.nvim_create_autocmd("LspAttach", {
         group = vim.api.nvim_create_augroup("lsp_attach", { clear = true }),
         callback = on_attach,
      })

      for name, exe in pairs(servers) do
         if vim.fn.executable(exe) == 1 then
            vim.lsp.enable(name)
         end
      end

      vim.keymap.set("i", "<Tab>", tab_complete, { expr = true, desc = "Complete / next item" })
      vim.keymap.set("i", "<S-Tab>", function()
         return vim.fn.pumvisible() == 1 and "<C-p>" or "<S-Tab>"
      end, { expr = true, desc = "Previous item" })
      -- <CR> (accept completion) is mapped in plugins/editing.lua, together
      -- with the autopairs fallback.
   end,
}
