-- Add every directory entered in yazi to zoxide.
require("zoxide"):setup { update_db = true }

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
