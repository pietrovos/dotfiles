return {
	"mikavilpas/yazi.nvim",
	version = "*",
	event = "VeryLazy",
	dependencies = { "nvim-lua/plenary.nvim", "folke/snacks.nvim" },
	keys = {
		{ "-", "<cmd>Yazi<cr>", mode = { "n", "v" }, desc = "Open yazi at the current file" },
		{ "<leader>-", "<cmd>Yazi cwd<cr>", desc = "Open yazi in the working directory" },
	},
	opts = {
		open_for_directories = false,
	},
}
