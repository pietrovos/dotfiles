return {
	"ibhagwan/fzf-lua",
	cmd = { "FzfLua" },
	keys = function()
		local git_utils = require("utils.git")

		return {
			-- Smart Open using frecency
			{
				"<leader><leader>",
				function()
					require("fzf-lua-frecency").frecency({
						cwd = git_utils.get_git_root(),
						cwd_only = true,
						previewer = false,
					})
				end,
				desc = "Smart Open (CWD + Frecency)",
			},
			{
				"<leader>ff",
				function()
					require("fzf-lua").files({
						cwd = git_utils.get_git_root(),
						fd_opts = [[--color=never --hidden --type f --type l --exclude .git --no-ignore]],
					})
				end,
				desc = "Smart Open (All Files in CWD)",
			},

			-- Core File/Buffer/Recent
			{ "<leader>fb", "<cmd>FzfLua buffers<cr>", desc = "Buffers" },
			{ "<leader>fr", "<cmd>FzfLua resume<cr>", desc = "Resume" },
			{ "<leader>fg", "<cmd>FzfLua git_files<cr>", desc = "Git Files" },
			{ "<leader>fh", "<cmd>FzfLua help_tags<cr>", desc = "Help Tags" },
			{ "<leader>sk", "<cmd>FzfLua keymaps<cr>", desc = "Keymaps" },
			{ "<leader>fm", "<cmd>FzfLua marks<cr>", desc = "Marks" },
			{ "<leader>f/", "<cmd>FzfLua search_history<cr>", desc = "Search History" },
			{ "<leader>fq", "<cmd>FzfLua quickfix<cr>", desc = "Quickfix List" },
			{ "<leader>fd", "<cmd>FzfLua diagnostics_document<cr>", desc = "Diagnostics" },
			{
				"<leader>fR",
				function()
					require("fzf-lua").live_grep({
            cwd = git_utils.get_git_root(),
						rg_glob = true,
						exec_empty_query = true,
					})
				end,
				desc = "Live Grep with Args",
			},
			{ "<leader>ghh", "<cmd>FzfLua git_bcommits<cr>", desc = "Git File History" },

			-- Special
			{
				"<leader>fc",
				function()
					require("fzf-lua").files({ cwd = vim.fn.stdpath("config") })
				end,
				desc = "Find Config Files",
			},

			-- Grep
			{
				"<leader>/",
				function()
					require("fzf-lua").live_grep({
						cwd = git_utils.get_git_root(),
						exec_empty_query = true,
					})
				end,
				desc = "Live Grep in Project",
			},
			{ "<leader>fw", "<cmd>FzfLua grep_cword<cr>", desc = "Grep Word Under Cursor" },
			{ "<leader>sb", "<cmd>FzfLua lgrep_curbuf<cr>", desc = "Grep in Current Buffer" },
			{ "<leader>rs", "<cmd>FzfLua registers<cr>", desc = "Search Registers" },

			-- Notifications
			{
				"<leader>snt",
				function()
					local ok = pcall(require, "notify")
					if ok then
						vim.cmd("Notifications")
					else
						vim.notify("Notify extension not available", vim.log.levels.WARN)
					end
				end,
				desc = "Search notifications",
			},

			-- LSP
			{ "<leader>sws", "<cmd>FzfLua lsp_live_workspace_symbols<cr>", desc = "Live Workspace Symbols" },
			{ "<leader>sd", "<cmd>FzfLua diagnostics_workspace<cr>", desc = "Workspace Diagnostics" },
		}
	end,
	dependencies = {
		"nvim-tree/nvim-web-devicons",
		{
			"elanmed/fzf-lua-frecency.nvim",
			config = function()
				require("fzf-lua-frecency").setup({
					db_dir = vim.fs.joinpath(vim.fn.stdpath("data"), "fzf-lua-frecency"),
					stat_file = true,
					display_score = false,
				})
			end,
		},
	},
	opts = {
		"max-perf",
		-- Override specific options
		keymap = {
			fzf = {
				["ctrl-q"] = "select-all+accept",
			},
		},
		fzf_colors = true,
		lsp = {
			code_actions = {
				previewer = "codeaction_native",
			},
		},
	},
	config = function(_, opts)
		require("fzf-lua").setup(opts)
		require("fzf-lua").register_ui_select()
	end,
}
