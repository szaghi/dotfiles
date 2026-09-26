-- Core keymaps, ported from ~/.vimrc "Mappings". Plugin keymaps live in each
-- plugin's spec under lua/plugins/ so they are lazy-loaded with the plugin.

local map = vim.keymap.set

-- Perl/Python regex
map({ "n", "x" }, "/", "/\\v")

-- speed up scrolling of the viewport slightly
map("n", "<C-e>", "2<C-e>")
map("n", "<C-y>", "2<C-y>")

-- change window splits
map("n", "<A-Up>", "<cmd>wincmd k<CR>", { desc = "Window up" })
map("n", "<A-Down>", "<cmd>wincmd j<CR>", { desc = "Window down" })
map("n", "<A-Left>", "<cmd>wincmd h<CR>", { desc = "Window left" })
map("n", "<A-Right>", "<cmd>wincmd l<CR>", { desc = "Window right" })

-- wrap on/off
map("", "<F2>", "<cmd>set wrap! wrap?<CR>", { desc = "Toggle wrap" })

-- buffer navigation (qq, buffer close, is in lua/plugins/snacks.lua)
map("n", "<C-Right>", "<cmd>bnext<CR>", { desc = "Next buffer" })
map("n", "<C-Left>", "<cmd>bprevious<CR>", { desc = "Previous buffer" })

-- toggle relative line numbers
map("n", "<C-n>", "<cmd>setlocal relativenumber!<CR>", { desc = "Toggle relativenumber" })

-- cursor movements limited or not
map("n", "<leader>v", function()
   if vim.o.virtualedit ~= "" then
      vim.o.virtualedit = ""
      vim.notify("Cursor movements limited")
   else
      vim.o.virtualedit = "all"
      vim.notify("Cursor movements unlimited")
   end
end, { desc = "Toggle virtualedit" })

-- Ctrl-J inserts a line break (the opposite of J)
map("n", "<C-j>", "i<CR><Esc>", { desc = "Split line" })

-- cycle through visual modes: visual -> visual-block -> visual-line -> visual
map("x", "v", function()
   local mode = vim.fn.mode()
   if mode == "v" then
      return "<C-v>"
   elseif mode == "V" then
      return "v"
   end
   return "V"
end, { expr = true, desc = "Cycle visual modes" })
