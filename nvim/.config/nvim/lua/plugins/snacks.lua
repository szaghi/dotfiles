-- folke/snacks.nvim — collection of small utilities. Only bufdelete is used for
-- now (vim: moll/vim-bbye); other snacks are opt-in via opts.

return {
   "folke/snacks.nvim",
   lazy = false,
   priority = 1000,
   opts = {},
   keys = {
      {
         "qq",
         function()
            Snacks.bufdelete()
         end,
         desc = "Close buffer, keep window layout",
      },
   },
}
