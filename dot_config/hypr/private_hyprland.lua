-- Learn how to configure Hyprland: https://wiki.hypr.land/Configuring/Start/

-- Drop cached omarchy modules so hyprctl reload re-reads them from disk.
for k in pairs(package.loaded) do
  if k:match("^default%.hypr") or k:match("^hypr%.") then
    package.loaded[k] = nil
  end
end

-- Omarchy's bootstrap keeps path setup out of this user config.
dofile((os.getenv("OMARCHY_PATH") or "/usr/share/omarchy") .. "/default/hypr/bootstrap.lua")

-- All Omarchy default setups
require("default.hypr.omarchy")

-- Change your own setup in these files and override defaults.
require("hypr.monitors")
require("hypr.input")
require("hypr.bindings")
require("hypr.looknfeel")
require("hypr.autostart")

-- Toggle config flags dynamically.
require("default.hypr.toggles")

-- Add any other personal Hyprland configuration below.
-- Qt picks its basic render loop here, which draws every bar window in turn on
-- one thread and held bar animations to ~40fps across the 240/144/60Hz screens.
-- The threaded loop gives each window its own vsync (~210fps on the MSI).
hl.env("QSG_RENDER_LOOP", "threaded")
-- o.window("qemu", { workspace = "5" })
o.window({ title = "discord%.com is sharing your screen%.", class = "^$" }, { workspace = "special silent" })
o.window("org.gnome.Nautilus", { opacity = "0.85 0.75" })
o.window("^termfilechooser$", { float = true, center = true, size = "1200 750" })
-- SUPER+N quick notes: nvim in a floating kitty window.
o.window("^quicknote$", { float = true, center = true, size = "900 600" })
-- Bitwarden opens tiled like normal windows (Omarchy defaults it to floating).
o.window("^(Bitwarden)$", { tag = "-floating-window" })
