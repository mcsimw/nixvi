require("lemon.plugins")

require('lze').load {
  {
    "lualine.nvim",
    for_cat = 'general.always',
    -- cmd = { "" },
    event = "DeferredUIEnter",
    -- ft = "",
    -- keys = "",
    -- colorscheme = "",
    after = function (plugin)

      require('lualine').setup({
        options = {
          icons_enabled = true,
	  theme = 'auto',
	  globalstatus = true,
        },
      })
    end,
  },
}

