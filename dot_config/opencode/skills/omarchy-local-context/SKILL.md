---
name: omarchy-local-context
description: Use when modifying, diagnosing, or explaining this user's Omarchy, Hyprland, or Omarchy-shell configuration. Check the live user config and chezmoi source before making assumptions about defaults or prior customizations.
---

# Local Omarchy Context

Treat the user-owned configuration below as authoritative. Do not infer behavior
from Omarchy defaults when these files can be inspected.

## Current Customizations

- The lock screen uses `~/.config/omarchy/plugins/pietrovos.lock/`, replacing
  `omarchy.lock` in `shell.json`. Its display-blanking timer is 120 seconds
  of inactivity while locked, including after hibernation, instead of 5 seconds.
- Custom OpenCode updates are automated by the user timer
  `opencode-custom-update.timer` (daily 04:00, up to 30 minutes of jitter,
  catch-up enabled). `~/.local/bin/opencode-custom-update` merges upstream
  `origin/dev` plus the tracked local patch from `~/projects/opencode-custom`
  in a private worktree, then checks, tests, and builds before atomically
  installing in `~/.local/share/opencode-custom/bin/`. The source checkout
  is not committed or modified. `~/.local/bin/opencode` uses this installed
  binary with a fallback to the original source build and disables the
  upstream auto-updater. Failures notify without replacing the installed
  binary; `opencode-custom-update --rollback` restores the previous build.
  See `~/.config/opencode-custom-updater/README.md` for commands and paths.
- The user override `~/.local/share/applications/chromium.desktop` launches
  `~/.local/bin/chromium-workspace`, which passes `--new-window` to Chromium.
  External links (including terminal links and dev-server default-browser
  launches) open a new window in the current workspace. Omarchy browser
  shortcuts also use this launcher; its distinct name avoids Omarchy's
  cross-workspace focus helper matching an older Chromium window.
- Group controls render in the top bar through
  `~/.config/omarchy/plugins/pietrovos.group-tabs/`.
- The subspace widget has a single rounded, 1px border around its numbered
  tabs and optional name, using the bar foreground color at 50% opacity.
- The widget is placed after `pietrovos.workspaces` in
  `~/.config/omarchy/shell.json`.
- `~/.config/omarchy/shell.toml` pins only `[font]`/`[bar]` and the menu and
  launcher alpha/glass values; it deliberately omits `[menu]`/`[launcher]`
  colors so the Omarchy menu (`SUPER+SPACE`) and launcher (`SUPER+ALT+SPACE`)
  follow the active theme's generated `shell.toml`.
- GTK/Nautilus CSS is theme-generated. Templates
  `~/.config/omarchy/themed/gtk-user-{3,4}.css.tpl` are rendered per theme by
  `omarchy-theme-set-templates` (placeholders from `colors.toml`) and delivered
  to `~/.config/gtk-{3,4}.0/gtk.css` by
  `~/.config/omarchy/hooks/theme-set.d/apply-gtk-css.hook`, which also quits a
  running Nautilus to recolor it. Nautilus text/selection use the theme
  foreground. The delivered `gtk.css` files are generated, so they are not
  chezmoi-managed; the templates and hook are.
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
  `SUPER+SHIFT+L` opens Claude Code in the current terminal directory via
  `~/.config/hypr/claude-code`.
- `SUPER+ESC` always switches to workspace 6 (overriding Omarchy's default
  System menu) via `~/.config/hypr/bindings.lua`.
- `SUPER+CTRL+SHIFT+1` through `SUPER+CTRL+SHIFT+0` swap whole workspace
  IDs (1 through 10), preserving layouts and following the original windows,
  via `bindings.lua`. Quickshell's Hyprland cache cannot follow `change_id`:
  on `changeworkspaceid` its `HyprlandWorkspace` keeps the old ID and old
  toplevel associations, and `refreshWorkspaces()`/`refreshToplevels()` cannot
  repair that (IDs are fixed after creation and a refresh never un-homes a
  toplevel). The cloned `pietrovos.workspaces/Workspaces.qml` therefore ignores
  that cache and reads occupancy (`windows > 0` per workspace) and the focused
  ID straight from `hyprctl -j activeworkspace` plus `hyprctl -j workspaces`,
  refreshed on occupancy/focus Hyprland events (including `changeworkspaceid`)
  and a 5s safety poll, so the bar greys out the emptied source number the
  moment a swap lands.
- `SUPER+CTRL+SHIFT+1` through `SUPER+CTRL+SHIFT+0` swap the current
  workspace with workspaces 1 through 10 in `bindings.lua`. Native
  `hl.dispatch(hl.dsp.workspace.change_id(...))` calls exchange whole
  workspace IDs through an unused temporary ID, preserving layout trees,
  window sizes and groups. Focus follows the original windows to the new
  number. An unused destination receives the current workspace; the current
  number and an open special workspace are no-ops.
- `SUPER+ALT+N` names the focused group's subspace through
  `~/.config/hypr/rename-group-subspace`, which prompts with
  `omarchy-menu-input`. `~/.config/hypr/group-subspace` assigns a group UUID
  using session-scoped Hyprland stable window IDs and reconciles all groups
  by surviving membership, so names follow moves/swaps, tab reorders and
  member additions/removals. Names persist in the version-2
  `$XDG_STATE_HOME/omarchy/group-subspaces.json`; old workspace names migrate
  once to their current groups. Empty input clears a name; cancellation keeps
  it. `pietrovos.group-tabs` reads the helper's active-group name and watches
  the state file. On splits/merges, the largest surviving membership retains
  the name; new compositor sessions do not reuse old window identities.
- OpenCode completion notifications identify the originating workspace and
  group tab. Question notifications show only that location, remain visible
  until clicked, focus that window when clicked, and use critical urgency for
  red attention styling. OpenCode's built-in TUI desktop notifications are
  disabled so the custom notification is the only alert.
- The cloned `pietrovos.notifications` shell service renders only OpenCode
  question notifications with an explicit red background and border,
  independent of the active theme's urgent color.
- The Agents usage widget is the clone `pietrovos.agents` (in `shell.json`,
  replacing `omarchy.agents`). Its bar control is a percentage meter instead
  of the stock robot icon: a rounded track filled to the selected provider's
  five-hour usage only, labelled with the rounded percent, tooltipped with the
  provider and 5h window. Weekly usage never drives the bar percentage.
  Balance-funded providers fill from remaining credit.
  With no provider chosen the bar defaults to the first provider that has rate
  limits (Codex here), not index 0.
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
- `PRINT` runs `~/.config/hypr/screenshot-to-clipboard` instead of the stock
  command: it takes a smart-region screenshot to the clipboard only (via
  `omarchy-capture-screenshot smart copy`), writing no file, and posts a
  permanent (critical urgency) notification. Clicking that notification runs
  `~/.config/hypr/screenshot-clipboard-action`, a menu offering Save to
  Pictures, Save to… (folder chooser), Edit (tensaku-edit), or Discard. The
  image stays on the clipboard; nothing is saved to disk until chosen.
- `SUPER+CTRL+ALT+S` toggles the user `chezmoi-sync.timer` through
  `~/.config/hypr/toggle-chezmoi-sync`, with a desktop notification. The timer's
  enabled state is machine-local.

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
