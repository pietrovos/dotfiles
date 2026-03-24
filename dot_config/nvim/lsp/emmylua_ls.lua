return {
	cmd = { "emmylua_ls" },
	filetypes = { "lua" },
	root_markers = {
		".luarc.json",
		".emmyrc.json",
		".luacheckrc",
		".git",
	},

	workspace_required = false,
	settings = {
		Lua = {
			diagnostics = {
				-- Make the LSP recognize the `vim` global
				globals = { "vim" },
			},
			workspace = {
				-- Tell LSP about Neovim runtime files
				library = vim.api.nvim_get_runtime_file("", true),
				checkThirdParty = false,
			},
		},
	},
}
