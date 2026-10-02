#!/usr/bin/env bash
# Desktop notification for Claude Code, mirroring ~/.config/opencode/plugins/completion-notification.ts.
# Usage: notify.sh finished|question   (hook JSON arrives on stdin and is ignored)

kind=${1:-finished}
cat >/dev/null

# Walk up the process tree to the Hyprland window hosting this Claude session.
clients=$(hyprctl clients -j 2>/dev/null) || exit 0
pid=$$
window=
for _ in $(seq 1 10); do
  pid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')
  [[ -z $pid || $pid -le 1 ]] && break
  window=$(jq -c --argjson pid "$pid" 'map(select(.pid == $pid)) | first // empty' <<<"$clients")
  [[ -n $window ]] && break
done

address=
if [[ -n $window ]]; then
  address=$(jq -r '.address' <<<"$window")
  # Skip when the session's window already has focus.
  [[ $(hyprctl activewindow -j 2>/dev/null | jq -r '.address // empty') == "$address" ]] && exit 0
  workspace=$(jq -r '.workspace.name // (.workspace.id | tostring)' <<<"$window")
  group_index=$(jq -r '.address as $a | (.grouped | index($a)) as $i | if $i == null then 0 else $i + 1 end' <<<"$window")
  group_size=$(jq -r '.grouped | length' <<<"$window")
  tab=
  (( group_size > 1 )) && tab=", Group $group_index/$group_size"
else
  workspace=unknown
  tab=
  group_index=0
fi

if [[ $kind == question ]]; then
  args=(--app-name="Claude Code Question" --urgency=critical --expire-time=0 "Workspace $workspace$tab")
else
  args=(--app-name="Claude Code" --urgency=critical --expire-time=0 "Claude Code finished" "Workspace $workspace$tab")
fi

# Detach so the hook returns immediately while notify-send waits for a click.
(
  if [[ -z $address ]]; then
    notify-send "${args[@]}"
    exit
  fi
  # Omarchy invokes the default action when the notification card is clicked.
  action=$(notify-send --action=default=Focus "${args[@]}")
  if [[ $action == default ]]; then
    hyprctl dispatch "hl.dsp.focus({ window = \"address:$address\" })" >/dev/null
    (( group_index > 0 )) && hyprctl dispatch "hl.dsp.group.active({ index = $group_index })" >/dev/null
  fi
) </dev/null >/dev/null 2>&1 &
disown
exit 0
