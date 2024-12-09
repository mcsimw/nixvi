return {
  {
    "lualine.nvim",
    for_cat = "general.always",
    event = "DeferredUIEnter",
    after = function(plugin)
      require("lualine").setup({
        options = {
          icons_enabled = true,
          theme = "auto",
          globalstatus = true,
        },
      })
    end,
  },
}
