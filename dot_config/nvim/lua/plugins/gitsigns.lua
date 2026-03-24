return {
	"lewis6991/gitsigns.nvim",
	event = { "BufReadPost", "BufNewFile" },
	opts = {
		signs = {
			add = { text = "█" },
			change = { text = "█" },
			delete = { text = "" },
			topdelete = { text = "" },
			changedelete = { text = "▎" },
			untracked = { text = "▎" },
		},
		signs_staged = {
			add = { text = "▎" },
			change = { text = "▎" },
			delete = { text = "" },
			topdelete = { text = "" },
			changedelete = { text = "▎" },
		},
		on_attach = function(buffer)
			local gs = package.loaded.gitsigns

			vim.keymap.set("n", "]h", function()
				if vim.wo.diff then
					vim.cmd.normal({ "]c", bang = true })
				else
					gs.nav_hunk("next")
				end
			end, { buffer = buffer, desc = "Next Hunk" })

			vim.keymap.set("n", "[h", function()
				if vim.wo.diff then
					vim.cmd.normal({ "[c", bang = true })
				else
					gs.nav_hunk("prev")
				end
			end, { buffer = buffer, desc = "Prev Hunk" })

			vim.keymap.set("n", "]H", function()
				gs.nav_hunk("last")
			end, { buffer = buffer, desc = "Last Hunk" })
			vim.keymap.set("n", "[H", function()
				gs.nav_hunk("first")
			end, { buffer = buffer, desc = "First Hunk" })
			vim.keymap.set(
				{ "n", "v" },
				"<leader>ghs",
				":Gitsigns stage_hunk<CR>",
				{ buffer = buffer, desc = "Stage Hunk" }
			)
			vim.keymap.set(
				{ "n", "v" },
				"<leader>ghr",
				":Gitsigns reset_hunk<CR>",
				{ buffer = buffer, desc = "Reset Hunk" }
			)
			vim.keymap.set("n", "<leader>ghS", gs.stage_buffer, { buffer = buffer, desc = "Stage Buffer" })
			vim.keymap.set("n", "<leader>ghu", gs.undo_stage_hunk, { buffer = buffer, desc = "Undo Stage Hunk" })
			vim.keymap.set("n", "<leader>ghR", gs.reset_buffer, { buffer = buffer, desc = "Reset Buffer" })
			vim.keymap.set(
				"n",
				"<leader>ghp",
				gs.preview_hunk_inline,
				{ buffer = buffer, desc = "Preview Hunk Inline" }
			)
			vim.keymap.set("n", "<leader>ghb", function()
				gs.blame_line({ full = true })
			end, { buffer = buffer, desc = "Blame Line" })
			vim.keymap.set("n", "<leader>ghB", function()
				gs.blame()
			end, { buffer = buffer, desc = "Blame Buffer" })
			vim.keymap.set("n", "<leader>ghd", gs.diffthis, { buffer = buffer, desc = "Diff This" })
			vim.keymap.set("n", "<leader>ghD", function()
				gs.diffthis("~")
			end, { buffer = buffer, desc = "Diff This ~" })
			vim.keymap.set(
				{ "o", "x" },
				"ih",
				":<C-U>Gitsigns select_hunk<CR>",
				{ buffer = buffer, desc = "GitSigns Select Hunk" }
			)

			vim.keymap.set("n", "<leader>ghw", "<cmd>Gitsigns toggle_word_diff<cr>", { desc = "Toggle word diff" })
		end,
	},
}
