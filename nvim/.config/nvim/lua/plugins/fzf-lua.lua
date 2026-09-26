-- ibhagwan/fzf-lua — fuzzy finders (vim: junegunn/fzf.vim). Same fzf binary,
-- same leader keys. Also serves vim.ui.select, so code actions (<leader>la)
-- get a fuzzy picker.

local function fzf(picker, opts)
   return function()
      require("fzf-lua")[picker](opts)
   end
end

return {
   "ibhagwan/fzf-lua",
   cmd = "FzfLua",
   keys = {
      { "<leader>f", fzf("files"), desc = "Files" },
      { "<leader>b", fzf("buffers"), desc = "Buffers" },
      -- vim: :Rg <pattern>; live_grep re-runs rg as the pattern is typed
      { "<leader>r", fzf("live_grep"), desc = "Live grep (rg)" },
      { "<leader>t", fzf("tags"), desc = "Tags" },
      -- vim: :History = v:oldfiles plus buffers opened this session
      { "<leader>h", fzf("oldfiles", { include_current_session = true }), desc = "Recent files" },
      -- vim: :Lines = lines of all loaded buffers
      { "<leader>/", fzf("lines"), desc = "Lines in open buffers" },
   },
   init = function()
      -- Load fzf-lua on the first vim.ui.select call, then hand it over.
      ---@diagnostic disable-next-line: duplicate-set-field
      vim.ui.select = function(...)
         require("fzf-lua").register_ui_select()
         return vim.ui.select(...)
      end
   end,
   opts = {
      defaults = { file_icons = false, git_icons = false },
      fzf_colors = true, -- follow the colorscheme
   },
}
