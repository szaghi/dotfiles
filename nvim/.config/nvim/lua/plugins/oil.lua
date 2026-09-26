-- stevearc/oil.nvim — directory as a buffer (vim: justinmk/vim-dirvish).
-- Same model as dirvish, but the buffer is editable: rename, move, create and
-- delete files by editing lines, then :w applies the changes after a
-- confirmation. Deletions go to the trash, since dd + :w is now a real delete.
--
-- Replaces netrw (default_file_explorer), so scp:// editing is gone; oil has
-- oil-ssh://host/path for remote directories instead.

return {
   "stevearc/oil.nvim",
   lazy = false, -- must be loaded to take over `nvim <dir>` and :e <dir>
   keys = {
      { "-", "<cmd>Oil<CR>", desc = "Open parent directory" },
   },
   opts = {
      default_file_explorer = true,
      columns = {}, -- bare names as in dirvish; no icon font needed
      delete_to_trash = true,
      view_options = { show_hidden = true },
   },
}
