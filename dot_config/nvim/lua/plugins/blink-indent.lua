return {
	"saghen/blink.indent",
	--- @module 'blink.indent'
	--- @type blink.indent.Config

	vim.keymap.set("n", "<leader>ui", function()
		if vim.g.indent_guide then
			vim.g.indent_guide = false
		else
			vim.g.indent_guide = true
		end
	end, { desc = "Toggle indent guides" }),
}
