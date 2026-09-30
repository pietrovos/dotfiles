---
name: omarchy-local-context
description: Use when modifying, diagnosing, or explaining this user's Omarchy, Hyprland, or Omarchy-shell configuration. Check the live user config and chezmoi source before making assumptions about defaults or prior customizations.
---

# Local Omarchy Context

Treat the user-owned configuration below as authoritative. Do not infer behavior
from Omarchy defaults when these files can be inspected.

## Current Customizations

- Group controls render in the top bar through
  `~/.config/omarchy/plugins/pietrovos.group-tabs/`.
- The widget is placed after `pietrovos.workspaces` in
  `~/.config/omarchy/shell.json`.
- Hyprland's in-window group bar is disabled in
  `~/.config/hypr/looknfeel.lua`.
- New group windows appear immediately to the right of the active member because
  `group.insert_after_current = true` is set in `looknfeel.lua`.
- `SUPER+G` toggles window grouping. `ALT+G` moves the active window out of a
  group. `ALT+1` through `ALT+0` select group members 1 through 10 with no
  action when the requested position is absent. `ALT+SHIFT+1` through
  `ALT+SHIFT+0` move the active member to positions 1 through 10 via
  `~/.config/hypr/reorder-group-window`. `SUPER+SHIFT+R` opens the custom OpenCode build in the
  current terminal directory via `~/.config/hypr/opencode-duplicate`.
- `SUPER+ALT+N` names the focused group's subspace through
  `~/.config/hypr/rename-group-subspace`, which prompts with
  `omarchy-menu-input`. The name is keyed to the active window's workspace and
  persisted in `$XDG_STATE_HOME/omarchy/group-subspaces.json` (excluding the
  name clears it; cancelling keeps it). `pietrovos.group-tabs` watches that
  file and renders the name just right of the numbered tabs, shifted right as
  members are added.
- OpenCode completion notifications identify the originating workspace and
  group tab. Question notifications show only that location, remain visible
  until clicked, focus that window when clicked, and use critical urgency for
  red attention styling. OpenCode's built-in TUI desktop notifications are
  disabled so the custom notification is the only alert.
- The cloned `pietrovos.notifications` shell service renders only OpenCode
  question notifications with an explicit red background and border,
  independent of the active theme's urgent color.
- `SUPER+CTRL+ALT+C` toggles the active Codex CLI account between `primary`
  and `secondary` through `~/.local/bin/codex-account`. The selected login
  also supplies the Codex usage widget's rate limits; credentials remain
  machine-local in `~/.local/share/codex-accounts/`.
- `SUPER+SHIFT+V` toggles the Blue Yeti's zero-latency headphone monitoring
  through `~/.config/hypr/toggle-mic-monitor`.
- The rear side mouse button (`mouse:275`) dismisses the last notification
  (Omarchy's `SUPER+comma`). The front side button (`mouse:276`) invokes the
  last notification — the same default action and dismissal as clicking it
  (Omarchy's `SUPER+ALT+comma`).

## Required Workflow

1. Read the relevant files under `~/.config/hypr/` and
   `~/.config/omarchy/` before changing them.
2. Never edit `/usr/share/omarchy/`; it is package-owned.
3. After Hyprland Lua changes, run `hyprctl reload` followed by
   `hyprctl configerrors`.
4. After shell plugin changes, run `qmllint` on changed QML. Hot reload
   re-reads plugin code but does NOT re-instantiate bar widgets already
   mounted on the bar, so a changed widget keeps running its old code until
   `omarchy restart shell` (this is the usual reason a widget edit "doesn't
   show up").
5. Add every changed portable target to chezmoi with `chezmoi add <target>`.
   Do not assume scheduled automation captures an unadded target.
6. When adding or materially changing a persistent customization, update this
   skill's `Current Customizations` section in the same change.

## Chezmoi Scope

The chezmoi source is `~/.local/share/chezmoi`. Portable Omarchy and Hyprland
settings are managed there. Themes, backgrounds, monitors, input/sensitivity,
autostart, environment, portal settings, and credentials are intentionally
machine-local unless the user explicitly changes that policy.
