return {
	"stevearc/conform.nvim",
	event = { "BufWritePre" },
	cmd = { "ConformInfo" },
	keys = {
		{
			"<leader>df",
			function()
				require("conform").format({ lsp_format = "fallback" })
			end,
			mode = { "n", "v" },
			desc = "Format Document/Selection",
		},
	},
	-- This will provide type hinting with LuaLS
	---@module "conform"
	---@type conform.setupOpts
	opts = {
		-- Define your formatters
		formatters_by_ft = {
			lua = { "stylua" },
			python = { "ruff_format" },
			-- javascript = { "prettierd", stop_after_first = true },
			javascript = { "biome" },
			typescript = { "biome" },
			javascriptreact = { "biome" },
			typescriptreact = { "biome" },
			json = { "prettierd" },
			html = { "prettierd" },
			css = { "prettierd" },
   java = { "google-java-format" },
      xml = {"xmlformatter"},
		},
		-- Set default options
		default_format_opts = {
			lsp_format = "fallback",
		},
		-- Set up format-on-save
		-- format_on_save = { timeout_ms = 500 },
		-- Customize formatters
		formatters = {
			biome = {
				command = "biome",
				args = { "format", "--stdin-file-path", "$FILENAME" },
			},
		},
	},
}
