--- Undo the last rename, move or trash recorded by the journal in init.lua.
local script = os.getenv("HOME") .. "/.config/yazi/plugins/undo.yazi/undo.py"

return {
	entry = function()
		local out, err = Command("python3"):arg("-I"):arg(script):stdout(Command.PIPED):stderr(Command.PIPED):output()
		if not out then
			return ya.notify { title = "Undo", content = tostring(err), level = "error", timeout = 5 }
		end
		local msg = out.stdout:gsub("%s+$", "")
		if msg == "" then
			msg = out.stderr:gsub("%s+$", "")
		end
		ya.notify {
			title = "Undo",
			content = msg,
			level = out.status.success and "info" or "warn",
			timeout = 4,
		}
	end,
}
