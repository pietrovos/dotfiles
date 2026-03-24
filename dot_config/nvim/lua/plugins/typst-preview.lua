return {
	"chomosuke/typst-preview.nvim",
	-- lazy = false, -- or ft = 'typst'
	ft = "typst",
	version = "1.*",
	keys = {
		{ "<leader>tp", "<cmd>TypstPreviewToggle<cr>", desc = "Toggle Typst Preview" },
	},
	opts = {}, -- lazy.nvim will implicitly calls `setup {}`
}
