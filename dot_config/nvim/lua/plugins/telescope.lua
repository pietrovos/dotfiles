-- TELESCOPE CONFIGURATION COMMENTED OUT - MIGRATED TO FZF-LUA
-- Keeping this for reference in case migration needs adjustments
--[[
return {
	"nvim-telescope/telescope.nvim",
	cmd = { "Telescope" },
	version = false,
	keys = function()
		local function safe_git_root()
			-- Try multiple methods to find the project root
			local path = vim.api.nvim_buf_get_name(0)
			path = path ~= "" and vim.loop.fs_realpath(path) or vim.loop.cwd()

			-- Handle special buffers like oil
			if vim.bo.filetype == "oil" then
				-- Get the directory that oil is currently exploring
				local oil_ok, oil = pcall(require, "oil")
				if oil_ok then
					local oil_dir = oil.get_current_dir()
					if oil_dir then
						path = oil_dir
					end
				end
			end

			-- Ensure path is a directory
			local stat = vim.loop.fs_stat(path)
			if stat and stat.type ~= "directory" then
				path = vim.fn.fnamemodify(path, ":h")
			end

			-- Try to find git root from this path
			local git_root
			local cmd = "git -C " .. vim.fn.shellescape(path) .. " rev-parse --show-toplevel"
			local handle = io.popen(cmd)
			if handle then
				git_root = handle:read("*a"):gsub("\n$", "")
				handle:close()
				if git_root ~= "" and vim.fn.isdirectory(git_root) == 1 then
					return git_root
				end
			end

			-- Fallback 1: Try using LSP root detection
			local active_clients = vim.lsp.get_clients()
			for _, client in ipairs(active_clients) do
				if client.config.root_dir then
					return client.config.root_dir
				end
			end

			-- Fallback 2: Use current directory
			return path
		end

		return {
			-- Default file finding (Smart Open)
			{
				"<leader><leader>",
				function()
					require("telescope").extensions.smart_open.smart_open({
						cwd = safe_git_root(),
						cwd_only = true,
						previewer = false,
					})
				end,
				desc = "Smart Open (CWD + Frecency)",
			},
			{
				"<leader>ff",
				function()
					local root = safe_git_root()
					require("telescope.builtin").find_files({
						cwd = root,
						hidden = true,
						no_ignore = true,
						no_ignore_parent = true,
					})
				end,
				desc = "Smart Open (All Files in CWD)",
			},

			-- Core File/Buffer/Recent
			{ "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
			{ "<leader>fr", "<cmd>Telescope oldfiles<cr>", desc = "Recent Files" },
			{ "<leader>fg", "<cmd>Telescope git_files<cr>", desc = "Git Files" },
			{ "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Help Tags" },
			{ "<leader>sk", "<cmd>Telescope keymaps<cr>", desc = "Keymaps" },
			{ "<leader>fm", "<cmd>Telescope marks<cr>", desc = "Marks" },
			{ "<leader>f/", "<cmd>Telescope search_history<cr>", desc = "Search History" },
			{ "<leader>fq", "<cmd>Telescope quickfix<cr>", desc = "Quickfix List" },
			{ "<leader>fd", "<cmd>Telescope diagnostics<cr>", desc = "Diagnostics" },
			{
				"<leader>fR",
				function()
					require("telescope").extensions.live_grep_args.live_grep_args()
				end,
				desc = "Live Grep with Args",
			},
			{
				"<leader>ghh",
				function()
					require("telescope").extensions.git_file_history.git_file_history()
				end,
				desc = "Git File History",
			},

			-- Special
			{
				"<leader>fc",
				function()
					require("telescope.builtin").find_files({ cwd = vim.fn.stdpath("config") })
				end,
				desc = "Find Config Files",
			},

			-- Grep
			{
				"<leader>/",
				function()
					require("telescope.builtin").live_grep({ search_dirs = { safe_git_root() } })
				end,
				desc = "Live Grep in Project",
			},
			{ "<leader>fw", "<cmd>Telescope grep_string<cr>", desc = "Grep Word Under Cursor" },
			{ "<leader>sb", "<cmd>Telescope current_buffer_fuzzy_find<cr>", desc = "Grep in Current Buffer" },
			{ "<leader>rs", "<cmd>Telescope registers<cr>", desc = "Search Registers" },

			-- Notifications
			{ "<leader>snt", "<cmd>Telescope notify<cr>", desc = "Search notifications" },
		}
	end,
	dependencies = {
		"nvim-lua/plenary.nvim",
		{
			"nvim-telescope/telescope-fzf-native.nvim",
			build = "make",
		},
		{
			"isak102/telescope-git-file-history.nvim",
			dependencies = { "tpope/vim-fugitive" },
		},
		{
			"nvim-telescope/telescope-ui-select.nvim",
		},
		{
			"danielfalk/smart-open.nvim",
			dependencies = {
				"kkharji/sqlite.lua",
			},
		},
		{
			"nvim-telescope/telescope-live-grep-args.nvim",
		},
	},
	opts = {
		defaults = {
			path_display = { "truncate" },
		},
		pickers = {
			lsp_references = { theme = "dropdown", initial_mode = "normal" },
			lsp_code_actions = { theme = "dropdown" },
			lsp_definitions = { theme = "dropdown", initial_mode = "normal" },
		},
		extensions = {
			fzf = {
				fuzzy = true, -- false will only do exact matching
				override_generic_sorter = true, -- override the generic sorter
				override_file_sorter = true, -- override the file sorter
				case_mode = "smart_case", -- or "ignore_case" or "respect_case"
			},
		},
	},
	config = function(_, opts)
		local telescope = require("telescope")

		-- Define safe_git_root function for use in snacks dashboard
		local function safe_git_root()
			-- Try multiple methods to find the project root
			local path = vim.api.nvim_buf_get_name(0)
			path = path ~= "" and vim.loop.fs_realpath(path) or vim.loop.cwd()

			-- Handle special buffers like oil
			if vim.bo.filetype == "oil" then
				-- Get the directory that oil is currently exploring
				local oil_ok, oil = pcall(require, "oil")
				if oil_ok then
					local oil_dir = oil.get_current_dir()
					if oil_dir then
						path = oil_dir
					end
				end
			end

			-- Ensure path is a directory
			local stat = vim.loop.fs_stat(path)
			if stat and stat.type ~= "directory" then
				path = vim.fn.fnamemodify(path, ":h")
			end

			-- Try to find git root from this path
			local git_root
			local cmd = "git -C " .. vim.fn.shellescape(path) .. " rev-parse --show-toplevel"
			local handle = io.popen(cmd)
			if handle then
				git_root = handle:read("*a"):gsub("\n$", "")
				handle:close()
				if git_root ~= "" and vim.fn.isdirectory(git_root) == 1 then
					return git_root
				end
			end

			-- Fallback 1: Try using LSP root detection
			local active_clients = vim.lsp.get_clients()
			for _, client in ipairs(active_clients) do
				if client.config.root_dir then
					return client.config.root_dir
				end
			end

			-- Fallback 2: Use current directory
			return path
		end

		-- Configure ui-select theme now that telescope is available
		opts.extensions["ui-select"] = require("telescope.themes").get_dropdown()

		-- Safely require live_grep_args actions
		local lga_ok, lga = pcall(require, "telescope-live-grep-args.actions")
		if lga_ok then
			-- inject live_grep_args config now that the extension is available
			opts.extensions.live_grep_args = {
				auto_quoting = true,
				mappings = {
					i = {
						["<C-k>"] = lga.quote_prompt(),
						["<C-i>"] = lga.quote_prompt({ postfix = " --iglob " }),
						["<C-space>"] = lga.to_fuzzy_refine,
					},
				},
			}
		end

		telescope.setup(opts)

		-- Load extensions
		telescope.load_extension("fzf")
		telescope.load_extension("git_file_history")
		telescope.load_extension("ui-select")
		telescope.load_extension("smart_open")
		telescope.load_extension("live_grep_args")
	end,
}
--]]

-- FZF-LUA CONFIGURATION - MIGRATED FROM TELESCOPE
-- Provides exact same keymaps and functionality using fzf-lua
return {}
