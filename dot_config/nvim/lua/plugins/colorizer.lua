
return {
  "catgoose/nvim-colorizer.lua",
  event = { "BufReadPost", "BufNewFile" },
  config = function()
    if vim.o.termguicolors then
      require("colorizer").setup()
    end
  end,
}
