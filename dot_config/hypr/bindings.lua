-- Replace Omarchy defaults rather than registering a second command per key.
local function bind(keys, description, command)
  hl.unbind(keys)
  o.bind(keys, description, command)
end

-- SUPER + ESC previously: Omarchy default "System menu", then locally overridden to
-- focuscurrentorlast. Now always switches to workspace 6.
bind("SUPER + ESCAPE", "Switch to workspace 6", hl.dsp.focus({ workspace = "6" }))
bind("SUPER + G", "Toggle window grouping", hl.dsp.group.toggle())
hl.unbind("SUPER + ALT + G")
bind("ALT + G", "Move active window out of group", hl.dsp.window.move({ out_of_group = true }))

bind("SUPER + RETURN", "Terminal", { omarchy = "terminal" })
bind("SUPER + ALT + RETURN", "Tmux", { omarchy = "terminal-tmux" })
bind("SUPER + SHIFT + RETURN", "Browser", { omarchy = "browser" })
bind("SUPER + SHIFT + F", "File manager", { omarchy = "nautilus" })
bind("SUPER + ALT + SHIFT + F", "File manager (cwd)", { omarchy = "nautilus-cwd" })
bind("SUPER + SHIFT + B", "Browser", { omarchy = "browser" })
bind("SUPER + SHIFT + ALT + B", "Browser (private)", { omarchy = "browser --private" })
bind("SUPER + SHIFT + M", "Music", { omarchy = "or-focus spotify" })
bind("SUPER + SHIFT + ALT + M", "Music TUI", { tui = "cliamp", focus = true })
bind("SUPER + SHIFT + N", "Editor", { omarchy = "editor" })
bind("SUPER + SHIFT + R", "Open OpenCode (cwd)", "/home/pietrovos/.config/hypr/opencode-duplicate")bind("SUPER + SHIFT + T", "Activity", { tui = "btop" })
bind("SUPER + SHIFT + D", "Docker", { tui = "lazydocker" })
hl.unbind("SUPER + SHIFT + G")
bind("SUPER + SHIFT + O", "Obsidian", { launch = "obsidian", focus = "^obsidian$" })
bind("SUPER + SHIFT + W", "Typora", { launch = "typora --enable-wayland-ime" })
bind("SUPER + SHIFT + SLASH", "Passwords", { launch = "1password" })

-- Web app bindings.
bind("SUPER + SHIFT + ALT + A", "ChatGPT", { webapp = "https://chatgpt.com" })
bind("SUPER + SHIFT + A", "Grok", { webapp = "https://grok.com" })
bind("SUPER + SHIFT + C", "Calendar", { webapp = "https://app.hey.com/calendar/weeks/" })
bind("SUPER + SHIFT + E", "Email", { webapp = "https://mail.google.com/mail/u/0/#inbox" })
bind("SUPER + SHIFT + Y", "YouTube", { webapp = "https://youtube.com/" })
bind("SUPER + SHIFT + V", "Toggle microphone monitoring", "/home/pietrovos/.config/hypr/toggle-mic-monitor")

-- PRINT takes a region screenshot to the clipboard only, with a permanent
-- notification offering save/edit/discard. Nothing is written to disk unless
-- you choose to save from that notification.
bind("PRINT", "Screenshot to clipboard", "/home/pietrovos/.config/hypr/screenshot-to-clipboard")
bind("SUPER + SHIFT + ALT + G", "WhatsApp", { webapp = "https://web.whatsapp.com/", focus = true })
bind("SUPER + SHIFT + CTRL + G", "Google Messages", { webapp = "https://messages.google.com/web/conversations", focus = true })
bind("SUPER + SHIFT + P", "Paint", { webapp = "https://jspaint.app" })
bind("SUPER + SHIFT + X", "X", { webapp = "https://x.com/" })
bind("SUPER + SHIFT + ALT + X", "X Post", { webapp = "https://x.com/compose/post" })
bind("SUPER + SHIFT + I", "Install Theme menu", "omarchy-launch-tui omarchy-theme-install")
bind("SUPER + CTRL + ALT + C", "Toggle Codex account", "/home/pietrovos/.local/bin/codex-account toggle")
bind("SUPER + CTRL + ALT + S", "Toggle automatic chezmoi sync", "/home/pietrovos/.config/hypr/toggle-chezmoi-sync")

-- Swap whole workspace IDs, preserving their layout trees, groups and sizes.
-- Focus follows the original workspace to its new number. An unused destination
-- simply receives the current workspace; selecting the current number is a no-op.
local function swap_workspace(target)
  local current = hl.get_active_workspace()
  if not current or current.id <= 0 or current.id == target or hl.get_active_special_workspace() then
    return
  end

  local source = current.id
  local occupied = {}
  for _, workspace in ipairs(hl.get_workspaces()) do
    occupied[workspace.id] = true
  end

  if occupied[target] then
    local temporary = 11
    while occupied[temporary] do
      temporary = temporary + 1
    end
    hl.dispatch(hl.dsp.workspace.change_id({ workspace = tostring(target), id = temporary }))
    hl.dispatch(hl.dsp.workspace.change_id({ workspace = tostring(source), id = target }))
    hl.dispatch(hl.dsp.workspace.change_id({ workspace = tostring(temporary), id = source }))
  else
    hl.dispatch(hl.dsp.workspace.change_id({ workspace = tostring(source), id = target }))
  end
end

for index = 1, 10 do
  local target = index
  local key = index == 10 and "0" or tostring(index)
  bind("SUPER + CTRL + SHIFT + " .. key, "Swap workspace with " .. index, function()
    swap_workspace(target)
  end)
end

-- Grouped-window tabs: Alt+1 through Alt+0 select positions 1 through 10.
for index = 1, 10 do
  if index <= 5 then
    hl.unbind("SUPER + ALT + code:" .. tostring(index + 9))
  end

  local key = index == 10 and "0" or tostring(index)
  bind("ALT + " .. key, "Switch to group window " .. index, "/home/pietrovos/.config/hypr/select-group-window " .. index)
end

for index = 1, 10 do
  local key = index == 10 and "0" or tostring(index)
  bind("ALT + SHIFT + " .. key, "Move group window to position " .. index, "/home/pietrovos/.config/hypr/reorder-group-window " .. index)
end

bind("SUPER + ALT + N", "Name group subspace", "/home/pietrovos/.config/hypr/rename-group-subspace")

bind("mouse:275", "Dismiss last notification", "omarchy-shell notifications dismissOne")
bind("mouse:276", "Invoke last notification", "omarchy-shell notifications invokeLast")

-- Add extra bindings below.
-- o.bind("SUPER + SHIFT + R", "SSH", "alacritty -e ssh your-server")

-- Overwrite existing bindings with hl.unbind() first if needed.
-- hl.unbind("SUPER + SPACE")
-- o.bind("SUPER + SPACE", "Omarchy menu", "omarchy-menu")

-- Logitech MX Keys examples:
-- o.bind("SUPER + SHIFT + S", nil, "omarchy-capture-screenshot")
-- o.bind("SUPER + H", nil, "voxtype record toggle")
-- o.bind("SUPER + PERIOD", nil, { omarchy = "walker -m symbols" })
