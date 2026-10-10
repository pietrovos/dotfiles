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
-- o.window("qemu", { workspace = "5" })
o.window({ title = "discord%.com is sharing your screen%.", class = "^$" }, { workspace = "special silent" })
o.window("org.gnome.Nautilus", { opacity = "0.85 0.75" })
o.window("^termfilechooser$", { float = true, center = true, size = "1200 750" })
