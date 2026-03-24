return {
  "akinsho/bufferline.nvim",
  version = "*",
  event = { "BufReadPost", "BufNewFile", "BufWritePost" },
  cond = function()
    return vim.bo.filetype ~= "snacks_dashboard"
  end,
  dependencies = { "nvim-tree/nvim-web-devicons" },
  keys = {
    { "<leader>br", "<Cmd>BufferLineCloseRight<CR>", desc = "Delete Buffers to the Right" },
    { "<leader>bl", "<Cmd>BufferLineCloseLeft<CR>",  desc = "Delete Buffers to the Left" },
    { "<S-h>",      "<cmd>BufferLineCyclePrev<cr>",  desc = "Prev Buffer" },
    { "<S-l>",      "<cmd>BufferLineCycleNext<cr>",  desc = "Next Buffer" },
    { "[b",         "<cmd>BufferLineCyclePrev<cr>",  desc = "Prev Buffer" },
    { "]b",         "<cmd>BufferLineCycleNext<cr>",  desc = "Next Buffer" },
    { "[B",         "<cmd>BufferLineMovePrev<cr>",   desc = "Move buffer prev" },
    { "]B",         "<cmd>BufferLineMoveNext<cr>",   desc = "Move buffer next" },
    -- Add other bufferline-specific keys here if desired
  },
  opts = {
    options = {
      mode = "buffers",
      numbers = "none",
      close_command = "bdelete! %d",
      right_mouse_command = "bdelete! %d",
      left_mouse_command = "buffer %d",
      indicator = {
        icon = "▎",
        style = "icon",
      },
      buffer_close_icon = "󰅖",
      modified_icon = "●",
      close_icon = "",
      left_trunc_marker = "",
      right_trunc_marker = "",
      max_name_length = 22,
      max_prefix_length = 15,
      truncate_names = true,
      tab_size = 18,
      diagnostics = "nvim_lsp",
      diagnostics_indicator = function(count, level)
        local icon = level:match("error") and " " or " "
        return " " .. icon .. count
      end,
      -- Hides bufferline for specific filetypes
      custom_filter = function(bufnr)
        local excluded_ft = { "qf", "lazy", "alpha", "snacks_dashboard", "starter" }
        local ft = vim.bo[bufnr].filetype
        return not vim.tbl_contains(excluded_ft, ft)
      end,
      show_buffer_icons = true,
      show_buffer_close_icons = true,
      show_close_icon = true,
      show_tab_indicators = true,
      persist_buffer_sort = true,
      separator_style = "thin",
      enforce_regular_tabs = false,
      always_show_bufferline = false,
      sort_by = "insert_after_current",
    },
  },
}
