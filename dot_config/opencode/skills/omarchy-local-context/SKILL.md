---
name: omarchy-local-context
description: Use when modifying, diagnosing, or explaining this user's Omarchy, Hyprland, or Omarchy-shell configuration. Check the live user config and chezmoi source before making assumptions about defaults or prior customizations.
---

# Local Omarchy Context

Treat the user-owned configuration below as authoritative. Do not infer behavior
from Omarchy defaults when these files can be inspected.

## Current Customizations

- `F10` toggles disposable **native Omarchy screen + default-mic + webcam**
  recording through `~/.local/bin/disposable-screenrecord`, a wrapper around
  `omarchy screenrecord --fullscreen --with-microphone-audio --with-webcam`.
  The first press records the full MSI monitor (currently DP-2) without a picker,
  regardless of focused monitor; the second stops/finalizes through
  Omarchy and opens mpv. Closing the preview (or Q) deletes the clip and its
  private `/dev/shm/omarchy-disposable-<uid>/clip.*` directory. F10 during preview
  focuses it. Own toasts: “Recording started.” (normal urgency, 3s), replaced
  in place by “Recording ended.”, or by a critical “Recording failed.” if the
  worker dies without finishing (not shown when F10 cancels during startup).
  Native toasts and preview/deletion messages are suppressed for this wrapper,
  without affecting normal recording notifications.
  The started cue fires 600ms after the MP4 exists: gpu-screen-recorder creates
  the file with its first frame (file age matched clip duration within ~30ms),
  so this clears the finalizer's 0.1s trim and 400ms mute/50ms fade. Do NOT wait
  on file size: the file grows in 256KB buffer flushes that track bitrate, which
  made the cue 2–15s late and sometimes timed out silently (2026-10-21 fix).
  Measured: cue ~0.7s after capture start, ~4.5s after the keypress (mostly
  Omarchy's webcam startup). The webcam appears first; the toast is the cue.
  F10 also starts Voxtype dictation (without its OSD or extra notifications),
  just before the 600ms wait. Stopping issues a single background
  `voxtype record stop --wait --json` (overlapping native finalization), then
  waits for it and types the text with wtype into the focused app before
  opening the preview. A plain `stop` followed later by `stop --wait` breaks:
  the second call sees the daemon idle and returns "empty", so nothing was
  typed. Whisper can hallucinate short text (“Thank you.”) on silence.
  Voxtype's `pause_media = true` pauses MPRIS players while dictating, which
  froze the webcam overlay (Omarchy's mpv) on one frame until dictation
  stopped. The worker exports `MPV_HOME` to a session dir whose `mpv.conf` has
  `load-scripts=no`, so F10's mpv never loads `/etc/mpv/scripts/mpris.so`;
  `pause_media` stays on for F9 and other players (2026-10-21).
  The transcript is temporary in the same RAM
  directory and is discarded with the video. Existing F9 hold-to-dictate
  bindings are unchanged, and an already-active F9 dictation is not taken over.
  Voxtype's `audio.max_duration_secs` is 3600 to cover longer recording sessions.
  the normal capture indicator/overlay/finalization remain native. It refuses
  to interfere with an existing normal recording. No desktop audio is requested.
  Scoped helper overrides select the connected MSI by model and anchor its
  webcam overlay there without changing desktop focus. Storage is temporary,
  not a strict no-swap/no-hibernation guarantee. This replaces the earlier
  isolated-OBS `obs-disposable` implementation, removed at the user's request.

- The LG TV (`HDMI-A-1`, 1920x1080@60) is independent at 150% scale,
  to the right of the ASUS, with persistent default workspace 11 via
  `~/.config/hypr/monitors.lua`. MSI (`DP-2`) keeps workspaces 1–5 and 7–10;
  ASUS (`DP-3`) keeps workspace 6. `SUPER+CTRL+T` focuses TV workspace 11;
  `SUPER+CTRL+SHIFT+T` moves the active window there and follows it.
  `SUPER+CTRL+ALT+T` toggles between this independent setup and mirroring MSI
  at 1080p/60, via `~/.config/hypr/toggle-tv-mirror`. The machine-local flag
  `$XDG_STATE_HOME/omarchy/tv-mirror` (default `~/.local/state/omarchy/tv-mirror`)
  remembers mirror mode across reloads/logins; absent means independent.
  Enabling HDMI ULTRA HD Deep Color on TV HDMI 1 exposed 4K/60 modes,
  but 4K/60 caused repeated brief blackouts over the current long HDMI run.
  Restored 1080p/60 pending confirmation; cable/link instability is suspected,
  not confirmed.
  Monitor settings stay machine-local.

- Kitty's `CTRL+SHIFT+A` copies the active terminal's screen and retained
  scrollback to the clipboard as plain text through `launch --type=clipboard
  --stdin-source=@screen_scrollback` in `~/.config/kitty/kitty.conf`.
  The scrollback limit is 20,000 lines.
- The KT USB headphone adapter uses software volume via
  `~/.config/wireplumber/wireplumber.conf.d/kt-usb-audio-software-volume.conf`.
  Full-level digital input caused screechy distortion on Discord sounds and
  videos despite reduced hardware volume; a 12 dB digital reduction cleared it.
  A 16-bit playback test did not help. Raising hardware playback from raw 66
  (-17 dB) to raw 90 (-5 dB), with software volume around 61–63%, restored
  approximately the original loudness and remained clean. This supports a
  full-level digital playback/volume-handling issue. The rule matches only
  this USB device. System ALSA-state saving requires authentication; the
  hardware setting was applied live but not saved to the system state file.
- PDF files open with the default Chromium browser through the
  `application/pdf=chromium.desktop` association in `~/.config/mimeapps.list`.
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
- The subspace widget (`pietrovos.group-tabs`) and workspaces widget
  (`pietrovos.workspaces`) mark the shown tab/focused workspace by keeping its
  number and making it glow, instead of replacing it with a filled-square
  glyph. The glow is a `layer.effect` of three stacked `MultiEffect` shadows
  in the bar foreground color (one shadow tops out at full opacity):
  `shadowBlur` 1.0, `blurMax` 32, `shadowScale` 1.2, with manual
  `paddingRect: Qt.rect(48, 48, 48, 48)`. Auto padding clipped the halo into
  a visible box; asymmetric padding (e.g. 96 right/bottom) pushed the scaled
  glow off-centre toward the bottom-right.
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
  action when the requested position is absent. `ALT+mouse_down` and
  `ALT+mouse_up` cycle to the next and previous window in the active subspace
  (group), alongside `SUPER+ALT+TAB` and `SUPER+ALT+SHIFT+TAB`.
  Every group-switch path (`ALT+1–0`, `ALT`/`SUPER+ALT`+scroll,
  `SUPER+ALT+(SHIFT+)TAB`, `SUPER+CTRL+LEFT/RIGHT`, and bar tab clicks in
  `pietrovos.group-tabs`) runs `~/.config/hypr/select-group-window
  <1-10|0|next|prev>`, which preserves fullscreen. Stock switching hands
  fullscreen to the new member, so Chromium exits page/video fullscreen.
  The script parks a fullscreen member with `fullscreen_state` internal 0 /
  client kept (tiled, but the app still thinks it is fullscreen), then
  restores a shown member with internal 0 / client 2 to 2/2 (2026-10-25).
  `ALT+SHIFT+1` through
  `ALT+SHIFT+0` move the active member to positions 1 through 10 via
  `~/.config/hypr/reorder-group-window`. `SUPER+SHIFT+R` opens the custom OpenCode build in the
  current terminal directory via `~/.config/hypr/opencode-duplicate`.
  `SUPER+SHIFT+L` opens Claude Code in the current terminal directory via
  `~/.config/hypr/claude-code`.
- `SUPER+ESC` switches to workspace 6, or back to the previous workspace when
  already on 6 (overriding Omarchy's default
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
- `pietrovos.workspaces` shows only occupied workspaces (windows > 0) plus the
  focused one, hiding empty numbers instead of dimming them. It covers
  workspaces 1–11, so the TV's workspace 11 appears (labelled "11") when it
  has windows or is focused (2026-10-25).
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
  group tab. Completions are suppressed only while the session's window is
  on the focused workspace and is the shown tab of its subspace (Hyprland
  `visible`); otherwise they notify.
  Claude Code mirrors this completion behavior through
  `~/.claude/hooks/notify.sh`, a separate hook script rather than a shared
  OpenCode plugin; both must be updated when changing notification behavior.
  Question notifications show only that location, remain visible
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
- The Agents widget invokes `~/.local/bin/omarchy-agent-usage-update` explicitly.
  It delegates other providers to Omarchy and Codex to a local collector wrapper
  that fixes buffered RPC reads, allows 12 seconds per request, retries once,
  and sets `retryAdvised` for the widget's 30-second retry on repeated failure.
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
- File-chooser dialogs (browsers, Electron, GTK apps) use
  `xdg-desktop-portal-termfilechooser` (AUR, hunkyburrito fork) with yazi in
  kitty instead of the GTK picker. `~/.config/xdg-desktop-portal/hyprland-portals.conf`
  routes `FileChooser` to `termfilechooser`; the backend config is
  `~/.config/xdg-desktop-portal-termfilechooser/config` (both machine-local
  portal settings, not chezmoi-managed). Kitty runs with class
  `termfilechooser`, floated and centered by a rule in `hyprland.lua`. Inside
  yazi, `z` jumps via zoxide; remove the `FileChooser` line to revert to GTK.
  The backend `cmd` is a user copy of the yazi wrapper at
  `~/.config/xdg-desktop-portal-termfilechooser/yazi-wrapper.sh`. When saving,
  `q` and `Q` cancel without saving; an explicit selection is required.
  Picking a folder saves into it, picking a file saves beside it (never
  overwrites it), all under the suggested name. The stock
  backend rejects a picked folder ("selected SaveFile is a directory") and
  gives no way to save into the current folder. The backend also stats the
  returned save path and fails ("failed to stat … No such file or directory",
  Chrome's save silently does nothing) if it is missing, so the wrapper
  creates an empty placeholder at the final path; the app overwrites it.
  In save dialogs, Enter runs `save-chooser.yazi` and explicitly returns the
  current folder (including empty folders) through `YAZI_SAVE_CHOOSER_FILE`;
  Right/`l` enters folders and `q`/`Q` cancels. Outside save dialogs, Enter
  retains normal open/choose behavior.
  `create_help_file=0` in the backend config stops the stock instructions
  file ("Opening a file OVERWRITES it!"), which contradicted this flow.
  After choosing files for upload, the wrapper returns the selection and opens
  a separate regular Yazi window on the first selected file for manual cleanup.
  It never auto-deletes; wait for the upload to finish before trashing the file.
  Save and directory-selection dialogs do not open this cleanup window.
  Yazi adds every visited directory to zoxide (`~/.config/yazi/init.lua`).
- Yazi has undo on `u` (`~/.config/yazi/plugins/undo.yazi`). `init.lua`
  subscribes to the `rename`, `bulk`, `move`, `trash` and `delete` DDS events
  and appends them to `$XDG_STATE_HOME/yazi/undo.jsonl` (last 200 kept, shared
  by all yazi instances including the file picker). `u` runs `undo.py`, which
  pops the newest entry: renames/moves are moved back, trashed items are
  restored from `~/.local/share/Trash` by matching `.trashinfo` paths, and a
  permanent delete (`D`) reports that it can't be undone. Copies (`y`/`p`)
  aren't journaled. An entry is dropped even if undoing it fails.
- `SUPER+N` runs `~/.config/hypr/quick-note`: a new blank note
  `~/Quick Notes/YYYY-MM-DD HH-MM-SS.md` (a counter is appended if the
  name exists) in nvim (`wrap linebreak`, starts in insert mode) inside a kitty
  window with class `quicknote`, started in the Quick Notes folder so `:w name`
  saves there, floated and centered (900x600) by a rule in `hyprland.lua`. nvim
  runs with `-n` (no swap file) and autosaves on every change, because closing
  the window kills it and a leftover swap file triggered E325 on the next note.
  If one is open it is focused instead; whitespace-only quick notes are deleted
  on the next launch. nvim replaced micro and `~/Quick Notes` replaced
  `~/Obsidian/Quick Notes` at the user's request (2026-10-14). Rejected: Typora (license nag), GNOME Text
  Editor (opens with keyboard focus off the text area).
- Bitwarden opens tiled like normal windows: `o.window("^(Bitwarden)$", { tag = "-floating-window" })`
  in `hyprland.lua` removes Omarchy's floating tag (a `tile = true` rule
  lost to the tag-based float rule).
- `SUPER+Y` opens yazi in a new terminal window (`{ tui = "yazi" }`, i.e.
  `omarchy-launch-tui yazi`) via `bindings.lua`. `SUPER+SHIFT+Y` stays YouTube.
- Mouse wheel scrolling is 3x faster via `input.scroll_factor = 3.0` in
  `~/.config/hypr/input.lua` (machine-local input setting; touchpad keeps
  its own `scroll_factor = 0.8`).
- Notification cards are 20% smaller: `sizeScale: 0.8` in
  `pietrovos.notifications/components/NotificationCard.qml` scales width,
  padding, icon and font sizes (borders unchanged); popup spacing is
  `Style.space(6)` in its `Service.qml`. Adjust `sizeScale` to resize.
- `SUPER+CTRL+ALT+S` toggles the user `chezmoi-sync.timer` through
  `~/.config/hypr/toggle-chezmoi-sync`, with a desktop notification. The timer's
  enabled state is machine-local.
- Greenify replicas: `~/.local/bin/theme-replica` makes themes that are
  Greenify recoloured. The seven custom `*iffy` themes live in
  `~/.config/omarchy/custom-themes/`, with relative symlinks at
  `~/.config/omarchy/themes/<name>` for Omarchy discovery and switching.
  New replicas are created in `custom-themes/` with compatibility symlinks;
  listing/syncing supports both locations without duplicates. Downloaded
  themes, including Greenify, remain in `themes/`. Theme files and these
  symlinks stay machine-local, not chezmoi-managed.
  A replica is a theme dir with `replica.toml`
  (`colour`/`hue`, optional `vibrancy`, `saturation`, `lightness`, `icons`).
  Everything except its `backgrounds/` and `replica.toml` is regenerated from
  `themes/greenify` by rotating Greenify's greens in OKLCH (the default
  vibrancy 0.5 balances brightness against vividness; a vivid blue is darker
  than a vivid green). It skips the files Omarchy ignores in Greenify because
  that theme is a git clone (terminal configs, `*.lua`), so replicas render the
  same way. `theme-replica new <name> <colour>`, `theme-replica sync` after
  changing Greenify, `theme-replica list`.

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
