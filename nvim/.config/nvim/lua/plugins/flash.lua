-- folke/flash.nvim — labelled jumps (vim: easymotion/vim-easymotion with
-- plugconf/easymotion.vim, whose mappings never loaded in vim).
-- The native f/t/F/T are left alone (modes.char disabled).

local function flash(opts)
   return function()
      require("flash").jump(opts)
   end
end

-- Label every match of `pattern` in the visible lines that satisfies
-- keep(row, col, cursor_row, cursor_col). Labels go nearest-first, so each
-- filter drops the cursor position itself (as easymotion does), otherwise the
-- first label is a no-op jump. The cursor is captured before flash starts:
-- flash moves it while scanning, so \%.l or \%# in a pattern are unreliable.
local function labels(pattern, keep)
   return function()
      local crow, ccol = unpack(vim.api.nvim_win_get_cursor(0))
      require("flash").jump({
         search = { mode = "search", max_length = 0, multi_window = false },
         label = { after = { 0, 0 } },
         matcher = function(win)
            local buf = vim.api.nvim_win_get_buf(win)
            local first = vim.fn.line("w0", win)
            local last = vim.fn.line("w$", win)
            local matches = {}
            for _, m in ipairs(vim.fn.matchbufline(buf, pattern, first, last)) do
               if keep(m.lnum, m.byteidx, crow, ccol) then
                  local pos = { m.lnum, m.byteidx }
                  table.insert(matches, { win = win, pos = pos, end_pos = pos })
               end
            end
            return matches
         end,
      })
   end
end

local word = [[\<\k]]

return {
   "folke/flash.nvim",
   keys = {
      -- type any characters, then the label of the target (easymotion-bd-f)
      { "<leader><leader>s", mode = { "n", "x", "o" }, flash(), desc = "Flash jump" },
      {
         "<leader><leader>w",
         labels(word, function(r, c, cr, cc)
            return r ~= cr or c ~= cc
         end),
         desc = "Jump to word",
      },
      {
         "<leader><leader>j",
         labels("^", function(r, _, cr)
            return r > cr
         end),
         desc = "Jump to line below",
      },
      {
         "<leader><leader>k",
         labels("^", function(r, _, cr)
            return r < cr
         end),
         desc = "Jump to line above",
      },
      {
         "<leader><leader>l",
         labels(word, function(r, c, cr, cc)
            return r == cr and c > cc
         end),
         desc = "Jump to word right",
      },
      {
         "<leader><leader>h",
         labels(word, function(r, c, cr, cc)
            return r == cr and c < cc
         end),
         desc = "Jump to word left",
      },
   },
   opts = {
      modes = { char = { enabled = false } },
   },
}
