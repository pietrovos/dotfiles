--- @sync entry

return {
	entry = function()
		local out = os.getenv("YAZI_SAVE_CHOOSER_FILE")
		if not out or out == "" then
			return ya.emit("open", {})
		end

		local file, err = io.open(out, "w")
		if not file then
			return ya.notify { title = "Save dialog", content = tostring(err), level = "error", timeout = 5 }
		end
		local ok, write_err = file:write(tostring(cx.active.current.cwd), "\n")
		local closed, close_err = file:close()
		if not ok or not closed then
			os.remove(out)
			return ya.notify { title = "Save dialog", content = tostring(write_err or close_err), level = "error", timeout = 5 }
		end
		ya.emit("quit", {})
	end,
}
