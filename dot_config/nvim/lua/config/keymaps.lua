local git_utils = require("utils.git")

-- noice keymaps
vim.keymap.set("c", "<S-Enter>", function()
	require("noice").redirect(vim.fn.getcmdline())
end, { desc = "Redirect Cmdline" })
vim.keymap.set("n", "<leader>snl", function()
	require("noice").cmd("last")
end, { desc = "Noice Last Message" })
vim.keymap.set("n", "<leader>snh", function()
	require("noice").cmd("history")
end, { desc = "Noice History" })
vim.keymap.set("n", "<leader>sna", function()
	require("noice").cmd("all")
end, { desc = "Noice All" })
vim.keymap.set("n", "<leader>snd", function()
	require("noice").cmd("dismiss")
end, { desc = "Dismiss All" })

-- codecompanion keymaps
-- vim.keymap.set("n", "<leader>ac", "<cmd>CodeCompanionChat Toggle<cr>", { desc = "Code Companion Chat" })

-- quitting keymaps
vim.keymap.set("n", "<leader>qq", "<cmd>qa<cr>", { desc = "Quit all" })

-- window keymaps
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Go to Left Window", remap = true })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Go to Lower Window", remap = true })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Go to Upper Window", remap = true })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Go to Right Window", remap = true })

-- buffer keymaps set in bufferline.lua
-- vim.keymap.set("n", "<leader>`", "<cmd>e #<cr>", { desc = "Switch to Other Buffer" })
-- vim.keymap.set("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Prev Buffer" })
-- vim.keymap.set("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next Buffer" })
-- vim.keymap.set("n", "[b", "<cmd>bprevious<cr>", { desc = "Prev Buffer" })
-- vim.keymap.set("n", "]b", "<cmd>bnext<cr>", { desc = "Next Buffer" })
-- vim.keymap.set( "<leader>bp", "<Cmd>BufferLineTogglePin<CR>", {desc = "Toggle Pin" })
-- vim.keymap.set( "<leader>bP", "<Cmd>BufferLineGroupClose ungrouped<CR>", {desc = "Delete Non-Pinned Buffers" })

-- vim.keymap.set( "<leader>br", "<Cmd>BufferLineCloseRight<CR>", {desc = "Delete Buffers to the Right" })
-- vim.keymap.set( "<leader>bl", "<Cmd>BufferLineCloseLeft<CR>", {desc = "Delete Buffers to the Left" })
-- vim.keymap.set( "<S-h>", "<cmd>BufferLineCyclePrev<cr>", {desc = "Prev Buffer" })
-- vim.keymap.set( "<S-l>", "<cmd>BufferLineCycleNext<cr>", {desc = "Next Buffer" })
-- vim.keymap.set( "[b", "<cmd>BufferLineCyclePrev<cr>", {desc = "Prev Buffer" })
-- vim.keymap.set( "]b", "<cmd>BufferLineCycleNext<cr>", {desc = "Next Buffer" })
-- vim.keymap.set( "[B", "<cmd>BufferLineMovePrev<cr>", {desc = "Move buffer prev" })
-- vim.keymap.set( "]B", "<cmd>BufferLineMoveNext<cr>", {desc = "Move buffer next" })

-- quality of life qol keymaps
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Scroll Down" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Scroll Up" })
vim.keymap.set({ "i", "n", "s" }, "<esc>", function()
	vim.cmd("noh")
	return "<esc>"
end, { expr = true, desc = "Escape and Clear hlsearch" })
vim.keymap.set("n", "<leader>m", "a{}<Esc>i<CR><Esc>O", { desc = "Curly brace around" })
vim.keymap.set("n", "J", "mzJ`z", { desc = "Join lines without moving cursor" })
-- Toggle diagnostics
local diagnostics_active = true
vim.keymap.set("n", "<leader>ud", function()
	diagnostics_active = not diagnostics_active
	if diagnostics_active then
		vim.diagnostic.enable(diagnostics_active)
		vim.notify("Diagnostics Enabled", vim.log.levels.INFO)
	else
		vim.diagnostic.enable(diagnostics_active)
		vim.notify("Diagnostics Disabled", vim.log.levels.WARN)
	end
end, { desc = "Toggle Diagnostics" })

-- Toggle wrap
vim.keymap.set("n", "<leader>uw", function()
	vim.wo.wrap = not vim.wo.wrap
	vim.notify("Wrap: " .. (vim.wo.wrap and "ON" or "OFF"))
end, { desc = "Toggle Wrap" })
vim.keymap.set({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
vim.keymap.set({ "n", "x" }, "<Down>", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
vim.keymap.set({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })
vim.keymap.set({ "n", "x" }, "<Up>", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })

-- saner n N
vim.keymap.set("n", "n", "'Nn'[v:searchforward].'zv'", { expr = true, desc = "Next Search Result" })
vim.keymap.set("x", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
vim.keymap.set("o", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
vim.keymap.set("n", "N", "'nN'[v:searchforward].'zv'", { expr = true, desc = "Prev Search Result" })
vim.keymap.set("x", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev Search Result" })
vim.keymap.set("o", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev Search Result" })
-- move lines
-- comment so that tmux doesn't have issues
-- vim.keymap.set("n", "<A-j>", "<cmd>execute 'move .+' . v:count1<cr>==", { desc = "Move Down" })
-- vim.keymap.set("n", "<A-k>", "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==", { desc = "Move Up" })
-- vim.keymap.set("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move Down" })
-- vim.keymap.set("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move Up" })
-- vim.keymap.set("v", "<A-j>", ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv", { desc = "Move Down" })
-- vim.keymap.set("v", "<A-k>", ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv", { desc = "Move Up" })

-- quickfix list keymaps
vim.keymap.set("n", "<leader>xq", function()
	local success, err = pcall(vim.fn.getqflist({ winid = 0 }).winid ~= 0 and vim.cmd.cclose or vim.cmd.copen)
	if not success and err then
		vim.notify(err, vim.log.levels.ERROR)
	end
end, { desc = "Quickfix List" })

vim.keymap.set("n", "[q", vim.cmd.cprev, { desc = "Previous Quickfix" })
vim.keymap.set("n", "]q", vim.cmd.cnext, { desc = "Next Quickfix" })

-- diagnostic keymaps
local diagnostic_goto = function(next, severity)
	local go = next and vim.diagnostic.goto_next or vim.diagnostic.goto_prev
	severity = severity and vim.diagnostic.severity[severity] or nil
	return function()
		go({ severity = severity })
	end
end
vim.keymap.set("n", "]d", diagnostic_goto(true), { desc = "Next Diagnostic" })
vim.keymap.set("n", "[d", diagnostic_goto(false), { desc = "Prev Diagnostic" })
vim.keymap.set("n", "]e", diagnostic_goto(true, "ERROR"), { desc = "Next Error" })
vim.keymap.set("n", "[e", diagnostic_goto(false, "ERROR"), { desc = "Prev Error" })
vim.keymap.set("n", "]w", diagnostic_goto(true, "WARN"), { desc = "Next Warning" })
vim.keymap.set("n", "[w", diagnostic_goto(false, "WARN"), { desc = "Prev Warning" })

-- window keymaps
vim.keymap.set("n", "<leader>|", "<C-W>v", { desc = "Split Window Right", remap = true })
vim.keymap.set("n", "<leader>wd", "<C-W>c", { desc = "Delete Window", remap = true })
vim.keymap.set("n", "<leader>wo", "<C-W>o", { desc = "Close other windows", remap = true })

-- lazygit snacks
local Snacks = require("snacks")

if vim.fn.executable("lazygit") == 1 then
	vim.keymap.set("n", "<leader>gg", function()
		local root = git_utils.get_git_root()
		if root then
			Snacks.lazygit({ cwd = root }) -- use Git root if valid
		else
			Snacks.lazygit() -- fallback to current directory so Lazygit prompts
		end
	end, { desc = "Lazygit (smart cwd)" })
end

-- new file keymaps
vim.keymap.set("n", "<leader>fn", "<cmd>enew<cr>", { desc = "New File" })

-- bufdelete keymaps
vim.keymap.set("n", "<leader>bd", function()
	Snacks.bufdelete()
end, { desc = "Delete Buffer" })
vim.keymap.set("n", "<leader>bo", function()
	Snacks.bufdelete.other()
end, { desc = "Delete Other Buffers" })

-- whole file selection

vim.keymap.set({ "o", "x" }, "ig", ":<C-u>normal! ggVG<CR>", { desc = "Whole file text object" })

-- snacks terminal
vim.keymap.set("n", "", function()
	local root = git_utils.get_git_root()
	require("snacks").terminal(nil, { cwd = root or vim.loop.cwd() })
end, { desc = "Terminal (Git Root or CWD)" })
vim.keymap.set("t", "", "<cmd>close<cr>", { desc = "Hide Terminal" })

-- Mason
vim.keymap.set("n", "<leader>cm", function()
	vim.cmd("Mason")
end, { desc = "Mason" })

-- Lazy keymaps
vim.keymap.set("n", "<leader>l", function()
	vim.cmd("Lazy")
end, { desc = "Lazy" })

local function swap_path_line()
	-- Path mappings (without requiring the exact path with trailing slash)
	local paths = {
		["/home/safi/safihasanfaraz%-share"] = "/home/hassan/sharefiles-text",
		["/home/hassan/sharefiles%-text"] = "/home/safi/safihasanfaraz-share",
	}

	-- Get the current line
	local line = vim.api.nvim_get_current_line()
	local new_line = line

	-- Try each path mapping
	for from_path, to_path in pairs(paths) do
		if line:find(from_path) then
			new_line = line:gsub(from_path, to_path)
			break
		end
	end

	-- Update the current line if a replacement was made
	if new_line ~= line then
		vim.api.nvim_set_current_line(new_line)
		print("Path swapped!")
	else
		print("No matching path found on this line.")
	end
end

local function swap_paths_file()
	-- Path mappings (without requiring the exact path with trailing slash)
	local paths = {
		["/home/safi/safihasanfaraz%-share"] = "/home/hassan/sharefiles-text",
		["/home/hassan/sharefiles%-text"] = "/home/safi/safihasanfaraz-share",
	}

	-- Get all lines in the buffer
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	local changes_made = false

	for i, line in ipairs(lines) do
		local new_line = line

		-- Try each path mapping on this line
		for from_path, to_path in pairs(paths) do
			if line:find(from_path) then
				new_line = line:gsub(from_path, to_path)
				changes_made = true
				break
			end
		end

		-- Update the line if changes were made
		if new_line ~= line then
			lines[i] = new_line
		end
	end

	-- Update the buffer with modified lines
	if changes_made then
		vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
		print("All paths in file swapped!")
	else
		print("No matching paths found in file.")
	end
end

-- Add your keymaps here
vim.keymap.set("n", "<leader>an", swap_path_line, { noremap = true, desc = "Swap file path on current line" })
vim.keymap.set("n", "<leader>aN", swap_paths_file, { noremap = true, desc = "Swap all file paths in the entire file" })

-- dynamic gf
local api = vim.api
local fn = vim.fn
local lsp = vim.lsp
local util = vim.lsp.util
local notify = vim.notify

-- Resolve a single VAR name to its string value
local function resolve_var(var)
	-- 1) scan upwards in this buffer
	local cur = api.nvim_win_get_cursor(0)[1]
	local lines = api.nvim_buf_get_lines(0, 0, cur, false)
	for i = #lines, 1, -1 do
		local l = lines[i]
		local dbl = l:match(var .. '%s*=%s*"([^"]+)"')
		local sng = l:match(var .. "%s*=%s*'([^']+)'")
		if dbl or sng then
			return dbl or sng
		end
	end

	-- 2) fallback to LSP definition
	local clients = lsp.get_clients({ bufnr = 0 })
	if #clients == 0 then
		return nil, "no LSP client"
	end
	local client = clients[1]
	local enc = client.offset_encoding or "utf-16"
	local params = util.make_position_params(nil, enc)
	local results = lsp.buf_request_sync(0, "textDocument/definition", params, 500)
	if not results then
		return nil, "no LSP definition"
	end

	for _, resp in pairs(results) do
		for _, loc in ipairs(resp.result or {}) do
			local bufnr = fn.bufnr(fn.uri_to_fname(loc.uri))
			api.nvim_buf_load(bufnr)
			local line = api.nvim_buf_get_lines(bufnr, loc.range.start.line, loc.range.start.line + 1, false)[1] or ""
			local dbl = line:match('"(.-)"')
			local sng = line:match("'(.-)'")
			if dbl or sng then
				return dbl or sng
			end
		end
	end

	return nil, "no string literal found"
end

-- main function
local function dynamic_gf()
	-- 1) get the full WORD under cursor
	local target = fn.expand("<cWORD>")
	-- 2) find all {VARS}
	local any = false
	local real = target:gsub("{(.-)}", function(var)
		any = true
		local val, err = resolve_var(var)
		if not val then
			notify(("Could not resolve {%s}: %s"):format(var, err), vim.log.levels.WARN)
			error("abort gf") -- stop the gsub and skip opening
		end
		return val
	end)

	if not any then
		-- no braces → plain gf
		return vim.cmd("normal! gf")
	end

	-- 3) open the resolved path
	vim.cmd("edit " .. fn.fnameescape(real))
end

-- Map it: keep plain 'gf' untouched
vim.keymap.set("n", "<leader>gf", function()
	-- protect against our abort
	local ok, _ = pcall(dynamic_gf)
	if not ok then
		return
	end
end, {
	noremap = true,
	silent = true,
	desc = "gf that expands {VARS} via nearest assignment or LSP",
})
