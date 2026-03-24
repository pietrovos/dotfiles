return {
	"tpope/vim-abolish",
	event = { "BufReadPost", "BufNewFile", "BufWritePost" },
	cond = function()
		return vim.bo.filetype ~= "snacks_dashboard"
	end,
	-- lazy = true,
}
