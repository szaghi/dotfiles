-- Autocommands, ported from ~/.vimrc "Autocommands".

local function augroup(name)
   return vim.api.nvim_create_augroup(name, { clear = true })
end
local autocmd = vim.api.nvim_create_autocmd

-- let terminal resize scale the internal windows
autocmd("VimResized", { group = augroup("resize"), command = "wincmd =" })

-- position the cursor at the last position before closing the file
autocmd("BufReadPost", {
   group = augroup("last_position"),
   callback = function(ev)
      local mark = vim.api.nvim_buf_get_mark(ev.buf, '"')
      if mark[1] > 1 and mark[1] <= vim.api.nvim_buf_line_count(ev.buf) then
         pcall(vim.api.nvim_win_set_cursor, 0, mark)
      end
   end,
})

-- Don't screw up folds when inserting text that might affect them, until
-- leaving insert mode. foldmethod is local to the window.
local folding = augroup("folding")
autocmd("InsertEnter", {
   group = folding,
   callback = function()
      vim.w.last_fdm = vim.wo.foldmethod
      vim.opt_local.foldmethod = "manual"
   end,
})
autocmd("InsertLeave", {
   group = folding,
   callback = function()
      if vim.w.last_fdm then
         vim.opt_local.foldmethod = vim.w.last_fdm
         vim.w.last_fdm = nil
      end
   end,
})

-- relative numbers only in the focused normal-mode buffer
local relnum = augroup("relnum_toggle")
autocmd({ "BufEnter", "FocusGained", "InsertLeave", "WinEnter" }, {
   group = relnum,
   callback = function()
      if vim.wo.number then
         vim.opt_local.relativenumber = true
      end
   end,
})
autocmd({ "BufLeave", "FocusLost", "InsertEnter", "WinLeave" }, {
   group = relnum,
   callback = function()
      if vim.wo.number then
         vim.opt_local.relativenumber = false
      end
   end,
})

-- programming tips
local programming = augroup("programming")

-- Condense runs of blank lines on write for these filetypes. Trailing
-- whitespace is stripped for every filetype except those where it is content.
local squeeze_blank = {}
for _, ft in ipairs({ "fortran", "make", "sh", "bash", "c", "cpp", "tex", "vim", "css", "java", "php", "xml", "markdown" }) do
   squeeze_blank[ft] = true
end
local keep_trailing = { diff = true, gitsendemail = true, mail = true }

-- One buffer-agnostic autocmd, instead of vimrc's BufWritePre-inside-FileType
-- which stacks a duplicate every time FileType re-fires. keeppatterns and
-- winsaveview keep the search register and the view intact across the write.
autocmd("BufWritePre", {
   group = programming,
   callback = function(ev)
      if vim.bo[ev.buf].binary then
         return
      end
      local ft = vim.bo[ev.buf].filetype
      local view = vim.fn.winsaveview()
      if not keep_trailing[ft] then
         vim.cmd([[keeppatterns silent! %s/\s\+$//e]])
      end
      if squeeze_blank[ft] then
         vim.cmd([[keeppatterns silent! %s/\n\{3,}/\r\r/e]])
      end
      vim.fn.winrestview(view)
   end,
})

-- fold method per filetype (setlocal: vimrc's plain `set` leaks to new windows)
autocmd("FileType", {
   group = programming,
   pattern = { "fortran", "make", "dosini", "c", "cpp", "tex", "css", "java", "php", "xml", "markdown" },
   callback = function()
      vim.opt_local.foldmethod = "syntax"
   end,
})
autocmd("FileType", {
   group = programming,
   pattern = { "sh", "bash" },
   callback = function()
      vim.opt_local.foldmethod = "indent"
   end,
})
