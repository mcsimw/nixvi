require("lze").register_handlers(require("lze.x"))
require("lze").register_handlers(require("nixCatsUtils.lzUtils").for_cat)

require("lemon.plugins")

require("lze").load({
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
})
