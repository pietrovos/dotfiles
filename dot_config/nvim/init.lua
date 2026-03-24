vim.g.mapleader = " "
vim.g.maplocalleader = "\\"
-- vim.g.loaded_matchparen = 1
vim.api.nvim_create_autocmd("BufReadPost", {
	callback = function(args)
		local file = args.file
		local stat = vim.loop.fs_stat(file)
		if stat and stat.size > 256 * 1024 then
			vim.b.matchup_matchparen_enabled = 0
			vim.b.matchup_matchparen_fallback = 0
			vim.cmd("NoMatchParen")
			-- vim.notify("MatchParen disabled for large file", vim.log.levels.WARN)
		end
	end,
})
require("config.lazy")
require("config.options")
require("config.keymaps")
require("config.autocmds")

-- Enable all our configured LSP servers
vim.lsp.enable({
	"pyright", -- Python
	"tsserver", -- JavaScript/TypeScript
	"clangd", -- C/C++
	"html", -- HTML
	"cssls", -- CSS
	-- 'eslint',        -- ESLint
	-- 'emmet_ls',      -- HTML/CSS expansion
	-- "lua_ls", -- Lua
	"emmylua_ls",
	"prismals", -- Prisma
	"tinymist",
  "jdtls", -- Java
  "copilot",
})

vim.lsp.inline_completion.enable()

-- LSP Configuration for Neovim 0.11
-- This file sets up LSP with the new vim.lsp.enable() API
-- Set up autocompletion
vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(ev)
		local bufnr = ev.buf
		local opts = { buffer = bufnr, noremap = true, silent = true }

		-- LSP keymaps
		vim.keymap.set("n", "gd", function()
			require("fzf-lua").lsp_definitions()
		end, opts)

		vim.keymap.set("n", "grr", function()
			require("fzf-lua").lsp_references()
		end, opts)

		-- Additional LSP keymaps using fzf-lua
		vim.keymap.set("n", "gD", function()
			require("fzf-lua").lsp_declarations()
		end, vim.tbl_extend("force", opts, { desc = "Go to Declaration" }))

		vim.keymap.set("n", "gy", function()
			require("fzf-lua").lsp_typedefs()
		end, vim.tbl_extend("force", opts, { desc = "Go to Type Definition" }))

		vim.keymap.set("n", "gi", function()
			require("fzf-lua").lsp_implementations()
		end, vim.tbl_extend("force", opts, { desc = "Go to Implementation" }))

		vim.keymap.set("n", "<leader>fs", function()
			require("fzf-lua").lsp_document_symbols()
		end, vim.tbl_extend("force", opts, { desc = "Document Symbols" }))

		vim.keymap.set("n", "<leader>fS", function()
			require("fzf-lua").lsp_workspace_symbols()
		end, vim.tbl_extend("force", opts, { desc = "Workspace Symbols" }))

		vim.keymap.set("n", "<leader>fi", function()
			require("fzf-lua").lsp_incoming_calls()
		end, vim.tbl_extend("force", opts, { desc = "Incoming Calls" }))

		vim.keymap.set("n", "<leader>fo", function()
			require("fzf-lua").lsp_outgoing_calls()
		end, vim.tbl_extend("force", opts, { desc = "Outgoing Calls" }))

		-- Code actions using fzf-lua
		vim.keymap.set({ "n", "v" }, "<leader>ca", function()
			require("fzf-lua").lsp_code_actions()
		end, vim.tbl_extend("force", opts, { desc = "Code Actions" }))

		-- Other LSP functionality (still using built-in as these don't benefit much from fzf)
		vim.keymap.set("n", "K", vim.lsp.buf.hover, vim.tbl_extend("force", opts, { desc = "Hover Documentation" }))
		-- vim.keymap.set(
		-- 	"n",
		-- 	"<C-k>",
		-- 	vim.lsp.buf.signature_help,
		-- 	vim.tbl_extend("force", opts, { desc = "Signature Help" })
		-- )
		vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, vim.tbl_extend("force", opts, { desc = "Rename Symbol" }))

		-- Workspace management
		vim.keymap.set(
			"n",
			"<leader>wa",
			vim.lsp.buf.add_workspace_folder,
			vim.tbl_extend("force", opts, { desc = "Add Workspace Folder" })
		)
		vim.keymap.set(
			"n",
			"<leader>wr",
			vim.lsp.buf.remove_workspace_folder,
			vim.tbl_extend("force", opts, { desc = "Remove Workspace Folder" })
		)
		vim.keymap.set("n", "<leader>wl", function()
			print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
		end, vim.tbl_extend("force", opts, { desc = "List Workspace Folders" }))

		-- Enable inlay hints if supported (Neovim 0.10+)
		if vim.lsp.inlay_hint and vim.lsp.inlay_hint.enable then
			vim.keymap.set("n", "<leader>uh", function()
				vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
			end, vim.tbl_extend("force", opts, { desc = "Toggle Inlay Hints" }))
		end
	end,
})

-- Configure diagnostics to use virtual lines
vim.diagnostic.config({
	virtual_lines = false,
	signs = true,
	underline = true,
	update_in_insert = false,
	severity_sort = true,
})
if vim.g.neovide then
	vim.g.neovide_cursor_animation_length = 0
	vim.g.neovide_scroll_animation_far_lines = 0
	vim.g.neovide_scroll_animation_length = 0
	vim.g.neovide_position_animation_length = 0
end
