-- nvim-lualine/lualine.nvim — statusline + buffer tabline
-- (vim: itchyny/lightline.vim + mengelbrecht/lightline-bufferline).
--
-- Plain ASCII separators and no file icons, as in vim: powerline/Nerd Font
-- glyphs render as tofu unless the terminal font is patched.

-- Buffer labels degrade in stages so that every listed buffer stays visible:
-- full path relative to cwd, then shortened directories, then filename only.
-- lualine's own "..." elision remains only as the last resort.
local label_styles = {
   function(file)
      return vim.fn.fnamemodify(file, ":~:.")
   end,
   function(file)
      return vim.fn.pathshorten(vim.fn.fnamemodify(file, ":~:."))
   end,
   function(file)
      return vim.fn.fnamemodify(file, ":t")
   end,
}

local function label_style()
   local bufs = vim.fn.getbufinfo({ buflisted = 1 })
   for _, style in ipairs(label_styles) do
      local width = 0
      for _, b in ipairs(bufs) do
         -- rendered as " <nr> <name>[ [+]] |"
         width = width + vim.fn.strdisplaywidth(style(b.name)) + #tostring(b.bufnr) + 4 + (b.changed == 1 and 4 or 0)
      end
      if width <= vim.o.columns then
         return style
      end
   end
   return label_styles[#label_styles]
end

return {
   "nvim-lualine/lualine.nvim",
   lazy = false,
   opts = {
      options = {
         theme = "auto", -- derived from the active colorscheme (solarized)
         icons_enabled = false,
         component_separators = "|",
         section_separators = "",
      },
      -- vim: active.left = [ [mode, paste], [readonly, filename, modified] ]
      sections = {
         lualine_a = { "mode" },
         lualine_b = { "branch", "diagnostics" },
         lualine_c = { { "filename", path = 1 } }, -- path relative to cwd, flags [+] [-]
         lualine_x = { "encoding", "fileformat", "filetype" },
         lualine_y = { "progress" },
         lualine_z = { "location" },
      },
      -- vim: tabline.left = [ [buffers] ], show_number = 1, shorten_path = 0
      tabline = {
         lualine_a = {
            {
               "buffers",
               mode = 4, -- buffer name + buffer number
               show_filename_only = false,
               -- lualine always pathshortens (s/l/file.F90); vim shows the
               -- full path relative to cwd. Special buffers (help, terminal,
               -- quickfix, directories, [No Name]) keep lualine's naming.
               fmt = function(name, buf)
                  if buf.buftype == "" and buf.file ~= "" and vim.fn.isdirectory(buf.file) == 0 then
                     return label_style()(buf.file)
                  end
                  return name
               end,
               max_length = function()
                  return vim.o.columns
               end,
               symbols = { modified = " [+]", alternate_file = "", directory = "" },
            },
         },
      },
   },
}
