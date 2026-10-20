-- Add every directory entered in yazi to zoxide.
require("zoxide"):setup { update_db = true }

-- Keep pending cuts visibly dimmed until pasted or cancelled.
local entity_style = Entity.style
function Entity:style()
	local style = entity_style(self)
	return self._file:is_yanked() == 2 and style:dim() or style
end

-- Journal renames, moves and trashing so `u` (plugins/undo.yazi) can reverse them.
local journal = (os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") .. "/.local/state")) .. "/yazi/undo.jsonl"
local escapes = { ['"'] = '\\"', ["\\"] = "\\\\", ["\n"] = "\\n", ["\r"] = "\\r", ["\t"] = "\\t" }

local function json_str(s)
	local escaped = tostring(s):gsub('[%c"\\]', function(c)
		return escapes[c] or string.format("\\u%04x", c:byte())
	end)
	return '"' .. escaped .. '"'
end

local function record(op, field, values)
	if #values == 0 then
		return
	end
	local line = string.format('{"op":%s,"t":%d,%s:[%s]}\n', json_str(op), os.time(), json_str(field), table.concat(values, ","))
	local f = io.open(journal, "a")
	if not f then
		os.execute("mkdir -p " .. string.format("%q", journal:match("^(.*)/")))
		f = io.open(journal, "a")
	end
	if f then
		f:write(line)
		f:close()
	end
end

local function pair(from, to)
	return "[" .. json_str(from) .. "," .. json_str(to) .. "]"
end

local function urls(body)
	local values = {}
	for _, url in pairs(body.urls or {}) do
		values[#values + 1] = json_str(url)
	end
	return values
end

ps.sub("rename", function(body)
	record("move", "items", { pair(body.from, body.to) })
end)

ps.sub("bulk", function(body)
	local values = {}
	for from, to in pairs(body) do
		values[#values + 1] = pair(from, to)
	end
	record("move", "items", values)
end)

ps.sub("move", function(body)
	local values = {}
	for _, item in pairs(body.items or {}) do
		values[#values + 1] = pair(item.from, item.to)
	end
	record("move", "items", values)
end)

ps.sub("trash", function(body)
	record("trash", "paths", urls(body))
end)

ps.sub("delete", function(body)
	record("delete", "paths", urls(body))
end)

-- Reopen in the directory yazi was last closed in, unless a path was passed on the command line.
local last_dir = (os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") .. "/.local/state")) .. "/yazi/last-dir"

local function save_dir()
	local f = io.open(last_dir, "w")
	if not f then
		os.execute("mkdir -p " .. string.format("%q", last_dir:match("^(.*)/")))
		f = io.open(last_dir, "w")
	end
	if f then
		f:write(tostring(cx.active.current.cwd))
		f:close()
	end
end

ps.sub("cd", save_dir)
ps.sub("tab", save_dir)

local function has_path_arg()
	local f = io.open("/proc/self/cmdline", "rb")
	if not f then
		return true
	end
	local args = f:read("*a")
	f:close()
	local first = true
	for arg in args:gmatch("[^%z]+") do
		if not first and arg:sub(1, 1) ~= "-" then
			return true
		end
		first = false
	end
	return false
end

if not has_path_arg() then
	local f = io.open(last_dir, "r")
	local dir = f and f:read("*l")
	if f then
		f:close()
	end
	if dir and dir ~= "" then
		ya.emit("cd", { dir })
	end
end
