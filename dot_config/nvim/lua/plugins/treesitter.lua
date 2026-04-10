return {
	"nvim-treesitter/nvim-treesitter",
	version = false,
	build = ":TSUpdate",
	event = { "BufReadPre", "BufNewFile" },
	lazy = vim.fn.argc(-1) == 0,
	dependencies = {
		"nvim-treesitter/nvim-treesitter-textobjects",
	},
	init = function(plugin)
		require("lazy.core.loader").add_to_rtp(plugin)
	end,
	cmd = { "TSUpdateSync", "TSUpdate", "TSInstall" },
	keys = {
		{ "<c-space>", desc = "Increment Selection" },
		{ "<bs>", desc = "Decrement Selection", mode = "x" },
	},
	opts = {
		highlight = {
			enable = true,
			disable = function(lang, buf)
				if lang == "markdown" then
					return true
				end
				local max_filesize = 100 * 1024
				local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
				return ok and stats and stats.size > max_filesize
			end,
		},
		indent = { enable = true },
		ensure_installed = {
			"bash",
			"c",
			"diff",
			"html",
			"javascript",
			"jsdoc",
			"json",
			"jsonc",
			"lua",
			"luadoc",
			"luap",
			"markdown",
			"markdown_inline",
			"printf",
			"python",
			"query",
			"regex",
			"toml",
			"tsx",
			"typescript",
			"vim",
			"vimdoc",
			"xml",
			"yaml",
      "prisma",
		},
		incremental_selection = {
			enable = true,
			keymaps = {
				init_selection = "<C-space>",
				node_incremental = "<C-space>",
				scope_incremental = false,
				node_decremental = "<bs>",
			},
		},
		textobjects = {
			select = {
				enable = true,
				lookahead = true,
				keymaps = {
					["af"] = "@function.outer",
					["if"] = "@function.inner",
					["ac"] = "@class.outer",
					["ic"] = "@class.inner",
					["aa"] = "@parameter.outer",
					["ia"] = "@parameter.inner",
				},
			},
			move = {
				enable = true,
				goto_next_start = {
					["]f"] = "@function.outer",
					["]c"] = "@class.outer",
					["]a"] = "@parameter.inner",
				},
				goto_next_end = {
					["]F"] = "@function.outer",
					["]C"] = "@class.outer",
					["]A"] = "@parameter.inner",
				},
				goto_previous_start = {
					["[f"] = "@function.outer",
					["[c"] = "@class.outer",
					["[a"] = "@parameter.inner",
				},
				goto_previous_end = {
					["[F"] = "@function.outer",
					["[C"] = "@class.outer",
					["[A"] = "@parameter.inner",
				},
			},
		},
	},
	config = function(_, opts)
		local function dedup(t)
			local seen, res = {}, {}
			for _, item in ipairs(t) do
				if not seen[item] then
					table.insert(res, item)
					seen[item] = true
				end
			end
			return res
		end

		opts.ensure_installed = dedup(opts.ensure_installed)
		require("nvim-treesitter").setup(opts)
	end,
}
