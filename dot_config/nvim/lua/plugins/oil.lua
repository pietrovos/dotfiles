-- oil.lua

-- Reads an entire file given its path.
local function read_file(filepath)
	local file = io.open(filepath, "r")
	if file then
		local content = file:read("*a")
		file:close()
		return content
	end
	return nil
end

-- Copies the contents of files listed in the selected lines.
-- Expects start and end line numbers.
local function copy_selected_files_contents(start_line, end_line)
	local oil = require("oil")
	local oil_dir = oil.get_current_dir(0)

	-- Fallback to current buffer's directory if Oil's directory isn't available.
	if not oil_dir or oil_dir == "" then
		oil_dir = vim.fn.expand("%:p:h") .. "/"
	end

	local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
	if not lines or #lines == 0 then
		print("No files selected. Try again.")
		return
	end

	local output = {}
	for _, line in ipairs(lines) do
		local filename = line:match("[^%s]+$")
		if filename then
			local filepath = oil_dir .. filename
			local content = read_file(filepath)
			if content and #content > 0 then
				table.insert(output, "// " .. filename .. "\n" .. content)
			end
		end
	end

	if #output > 0 then
		local final_content = table.concat(output, "\n\n")
		vim.fn.setreg("+", final_content)
		print("Copied file contents to clipboard")
	else
		print("No valid files found. Try again.")
	end
end

-- Create a user command that accepts a range.
vim.api.nvim_create_user_command("CopyOilContents", function(opts)
	copy_selected_files_contents(opts.line1, opts.line2)
end, { range = true })

-- Store marked directories
local marked_directories = {}

-- Function to mark current oil directory
local function mark_oil_directory(mark)
	local oil = require("oil")
	local current_dir = oil.get_current_dir(0)

	if not current_dir or current_dir == "" then
		vim.notify("Not in an Oil buffer", vim.log.levels.ERROR)
		return
	end

	marked_directories[mark] = current_dir
	vim.notify("Marked directory '" .. mark .. "' as " .. current_dir, vim.log.levels.INFO)
end

-- Function to jump to marked directory
local function goto_marked_directory(mark)
	local oil = require("oil")
	local dir = marked_directories[mark]

	if not dir then
		vim.notify("No directory marked as '" .. mark .. "'", vim.log.levels.ERROR)
		return
	end

	-- Open the marked directory using Oil
	oil.open(dir)
end

-- Visual mode mapping using mode "x" (for visual selections).
vim.keymap.set("x", "<leader>cy", ":CopyOilContents<CR>", { desc = "Copy selected file contents" })
-- Normal mode mapping to open Oil (parent directory)
vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
local function copy_selected_file_paths(start_line, end_line)
	local oil = require("oil")
	local oil_dir = oil.get_current_dir(0)

	-- Fallback to current buffer's directory if Oil's directory isn't available
	if not oil_dir or oil_dir == "" then
		oil_dir = vim.fn.expand("%:p:h") .. "/"
	end

	local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
	if not lines or #lines == 0 then
		print("No files selected. Try again.")
		return
	end

	local file_paths = {}
	for _, line in ipairs(lines) do
		local filename = line:match("[^%s]+$")
		if filename then
			local filepath = oil_dir .. filename
			table.insert(file_paths, filepath)
		end
	end

	if #file_paths > 0 then
		local final_content = table.concat(file_paths, "\n")
		vim.fn.setreg("+", final_content)
		print("Copied " .. #file_paths .. " file path(s) to clipboard")
	else
		print("No valid files found. Try again.")
	end
end

-- Create a user command for copying file paths
vim.api.nvim_create_user_command("CopyOilPaths", function(opts)
	copy_selected_file_paths(opts.line1, opts.line2)
end, { range = true })

-- Visual mode mapping for copying file paths
vim.keymap.set("x", "<leader>cp", ":CopyOilPaths<CR>", { desc = "Copy selected file paths" })
return {
	"stevearc/oil.nvim",
	-- event = { "BufReadPost", "BufNewFile", "BufWritePost" },
	-- cond = function()
	-- 	return vim.bo.filetype ~= "snacks_dashboard"
	-- end,
	-- cmd = "Oil",
	---@module 'oil'
	---@type oil.SetupOpts
	opts = {
		default_file_explorer = true,
		skip_confirm_for_simple_edits = true,
		watch_for_changes = true,
	},
	-- Optional dependencies
	dependencies = { { "echasnovski/mini.icons", opts = {} } },
	config = function(_, opts)
		local oil = require("oil")
		oil.setup(opts)

		-- Set up key mappings for marking and jumping to directories
		-- These use Neovim's built-in mark functionality but store directory paths instead

		-- Create autocommands that only apply to Oil buffers
		vim.api.nvim_create_autocmd("FileType", {
			pattern = "oil",
			callback = function(ev)
				-- Mark current directory with m{mark}
				vim.keymap.set("n", "m", function()
					-- Get the next character pressed
					local ok, char = pcall(function()
						return vim.fn.getcharstr()
					end)

					if ok and char and #char == 1 then
						mark_oil_directory(char)
					end
				end, { buffer = ev.buf, desc = "Mark Oil directory" })

				-- Jump to marked directory with '{mark}
				vim.keymap.set("n", "'", function()
					-- Get the next character pressed
					local ok, char = pcall(function()
						return vim.fn.getcharstr()
					end)

					if ok and char and #char == 1 then
						goto_marked_directory(char)
					end
				end, { buffer = ev.buf, desc = "Go to marked Oil directory" })
			end,
		})
	end,
}
