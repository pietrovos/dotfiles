#!/usr/bin/env bash
# Desktop notification for Claude Code, mirroring ~/.config/opencode/plugins/completion-notification.ts.
# Usage: notify.sh finished|question   (hook JSON arrives on stdin and is ignored)

# Detached half: shows the notification and waits for a click (see the end of the file).
# kind, address and group_index arrive through the environment.
if [[ ${1:-} == --show ]]; then
  shift
  if [[ -z $address ]]; then
    notify-send "$@"
    exit
  fi
  # Omarchy invokes the default action when the notification card is clicked.
  if [[ $kind == question ]]; then
    action=$(notify-send --action=default=Focus "$@")
  else
    # Completions close themselves once their window is on screen.
    exec {notification}< <(notify-send --print-id --action=default=Focus "$@")
    read -r id <&"$notification"
    "$HOME/.local/bin/notification-dismiss-on-view" "$id" "$address" &
    watcher=$!
    action=$(cat <&"$notification")
    kill "$watcher" 2>/dev/null
  fi
  if [[ $action == default ]]; then
    hyprctl dispatch "hl.dsp.focus({ window = \"address:$address\" })" >/dev/null
    (( group_index > 0 )) && hyprctl dispatch "hl.dsp.group.active({ index = $group_index })" >/dev/null
  fi
  exit
fi

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
  # Questions are silent when focused; completions are silent while the window is the
  # shown tab of its group on the focused workspace.
  if [[ $kind == question ]]; then
    [[ $(hyprctl activewindow -j 2>/dev/null | jq -r '.address // empty') == "$address" ]] && exit 0
  elif [[ $(jq -r '.visible' <<<"$window") == true &&
          $(hyprctl activeworkspace -j 2>/dev/null | jq -r '.id') == $(jq -r '.workspace.id' <<<"$window") ]]; then
    exit 0
  fi
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

# Claude Code kills the hook's process group when it returns, so the waiting part runs
# in its own session (re-invoked as --show) to outlive the hook.
export kind address group_index
setsid -f "$0" --show "${args[@]}" </dev/null >/dev/null 2>&1
exit 0
