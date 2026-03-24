return {
  "nvim-lualine/lualine.nvim",
  event = { "BufReadPost", "BufNewFile", "BufWritePost" },
  cond = function()
    return vim.bo.filetype ~= "snacks_dashboard"
  end,
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    require("lualine").setup({
      options = {
        icons_enabled = true,
        theme = "auto",
        disabled_filetypes = { "snacks_dashboard", "lazy", "oil", },
        always_divide_middle = true,
        globalstatus=true,
      },
      sections = {
        lualine_a = { { "mode", upper = true } },
        lualine_b = { "branch", "diff" },
        lualine_c = {
          {
            "filename",
            path = 1, -- relative path
            symbols = {
              modified = " ●", -- Text to show when the file is modified.
              readonly = " ", -- Text to show when the file is non-modifiable or readonly.
              unnamed = "[No Name]",
            },
          },
        },
        lualine_x = {
          {
            function()
              local reg = vim.fn.reg_recording()
              return reg ~= "" and "REC @" .. reg or ""
            end,
            color = { fg = "#ffffff", bg = "#ff0000", gui = "bold" },
          },
          {
            "diagnostics",
            sources = { "nvim_diagnostic" },
            symbols = { error = " ", warn = " ", info = " ", hint = " " },
          },
          "filetype",
        },
        lualine_y = {
          {
            function()
              return vim.fn.fnamemodify(vim.fn.getcwd(), ":~")
            end,
            icon = "",
          },
        },
        lualine_z = {
          "location", },
      },
      inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = {
          {
            "filename",
            path = 1,
          },
        },
        lualine_x = { "location" },
        lualine_y = {},
        lualine_z = {},
      },
      extensions = { "fugitive", "lazy", "quickfix", "nvim-tree" },
    })
    vim.api.nvim_create_autocmd({ "RecordingEnter", "RecordingLeave" }, {
      callback = function()
        require("lualine").refresh({ place = { "statusline" } })
      end,
    })
  end,
}
