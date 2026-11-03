import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "omarchy.workspaces"

  // Quickshell's Hyprland cache cannot follow change_id: on changeworkspaceid it
  // keeps a workspace's old ID and its old toplevel associations, so after a swap
  // the bar keeps showing the source workspace as occupied until something else
  // forces a resync. Neither refreshWorkspaces() nor refreshToplevels() repairs
  // that (IDs are fixed after creation, and refresh never un-homes a toplevel),
  // so read occupancy and focus straight from the compositor instead, which is
  // authoritative the moment the swap lands.
  property var occupiedIds: ({})
  property int focusedId: 0
  property bool refreshPending: false
  property bool tvKeys: false
  // Workspace id -> "running" or "done", from the marks agent-status leaves.
  property var agentStates: ({})

  readonly property string stateDir: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/omarchy"
  readonly property string tvKeysPath: stateDir + "/tv-workspace-keys"
  readonly property string agentsDir: stateDir + "/agent-marks"

  // The ten workspaces the number keys currently reach.
  readonly property var visibleIds: tvKeys
    ? [11, 12, 13, 14, 15, 16, 17, 18, 19, 20]
    : [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

  readonly property var stateEvents: [
    "workspace", "workspacev2",
    "focusedmon", "focusedmonv2",
    "openwindow", "closewindow",
    "movewindow", "movewindowv2",
    "createworkspace", "createworkspacev2",
    "destroyworkspace", "destroyworkspacev2",
    "moveworkspace", "moveworkspacev2",
    "changeworkspaceid",
    "activespecial",
    // Switching group tabs decides which agent marks move to the tabs.
    "activewindow", "activewindowv2"
  ]

  function refresh() {
    if (stateProc.running) {
      refreshPending = true
      return
    }

    refreshPending = false
    stateProc.running = true
  }

  function applyState(text) {
    var parts = String(text).split("@@@")
    if (parts.length < 5) return

    var active
    var list
    var clients
    var activeWindow
    try {
      active = JSON.parse(parts[0].trim())
      list = JSON.parse(parts[1].trim())
      clients = JSON.parse(parts[2].trim())
      activeWindow = JSON.parse(parts[4].trim())
    } catch (error) {
      return
    }

    if (!active || !Array.isArray(list) || !Array.isArray(clients)) return

    var occupied = {}
    for (var i = 0; i < list.length; i++) {
      var id = list[i] && list[i].id
      if (id > 0 && id <= 20 && list[i].windows > 0) occupied[id] = true
    }

    root.occupiedIds = occupied
    root.focusedId = (active.id > 0 && active.id <= 20) ? active.id : 0

    // A running agent wins over a finished one on the same workspace. A
    // checkmark clears once its window is the shown tab on the focused
    // workspace, like the completion notification.
    var windows = {}
    for (var c = 0; c < clients.length; c++) windows[clients[c].address] = clients[c]
    // The subspace whose tabs pietrovos.group-tabs shows (it follows the active
    // window too), where its members' agents are marked instead.
    var shownGroup = activeWindow && activeWindow.workspace && activeWindow.workspace.id === active.id ? (activeWindow.grouped || []) : []

    var agents = {}
    var lines = parts[3].trim().split("\n")
    for (var l = 0; l < lines.length; l++) {
      var fields = lines[l].trim().split(" ")
      var window = windows[fields[0]]
      if (!window || (fields[1] !== "running" && fields[1] !== "done")) continue

      var workspace = window.workspace.id
      if (fields[1] === "done" && window.visible && workspace === active.id) {
        root.clearAgent(fields[0])
        continue
      }
      if (shownGroup.indexOf(fields[0]) !== -1) continue
      if (agents[workspace] !== "running") agents[workspace] = fields[1]
    }
    root.agentStates = agents
  }

  function clearAgent(address) {
    if (root.bar) root.bar.run("rm -f " + Util.shellQuote(root.agentsDir + "/" + address))
  }

  function focusWorkspace(id) {
    if (!root.bar) return
    root.bar.run("hyprctl dispatch " + Util.shellQuote("hl.dsp.focus({ workspace = \"" + id + "\" })"))
  }

  Connections {
    target: Hyprland
    function onRawEvent(event) {
      if (!event || !event.name) return
      if (root.stateEvents.indexOf(String(event.name)) !== -1) refreshDebounce.restart()
    }
  }

  Timer {
    id: refreshDebounce
    interval: 30
    onTriggered: root.refresh()
  }

  // Safety net for state that changes without one of the listed events.
  Timer {
    interval: 5000
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  Process {
    id: stateProc
    command: ["sh", "-c", "hyprctl -j activeworkspace; printf '\\n@@@\\n'; hyprctl -j workspaces; printf '\\n@@@\\n'; hyprctl -j clients; printf '\\n@@@\\n'; for mark in \"$1\"/0x*; do [ -f \"$mark\" ] && printf '%s %s\\n' \"${mark##*/}\" \"$(cat \"$mark\")\"; done; printf '\\n@@@\\n'; hyprctl -j activewindow", "sh", root.agentsDir]

    onRunningChanged: {
      if (!running && root.refreshPending) root.refresh()
    }

    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.applyState(text)
    }
  }

  // Written by the SUPER + CTRL + T binding in bindings.lua.
  FileView {
    path: root.tvKeysPath
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.tvKeys = text().trim() === "1"
  }

  // Touched by agent-status whenever an agent starts or finishes.
  FileView {
    path: root.agentsDir + "/changed"
    watchChanges: true
    printErrors: false
    onFileChanged: root.refresh()
  }

  Component.onCompleted: root.refresh()

  readonly property real trailingGap: root.vertical ? 0 : Style.spaceReal(1.5)

  implicitWidth: grid.implicitWidth + trailingGap
  implicitHeight: grid.implicitHeight

  GridLayout {
    id: grid
    anchors.fill: parent
    anchors.rightMargin: root.trailingGap
    columns: root.vertical ? 1 : root.visibleIds.length + (root.tvKeys ? 1 : 0)
    columnSpacing: root.vertical ? 0 : Style.space(1)
    rowSpacing: root.vertical ? Style.space(2) : 0

    WidgetButton {
      visible: root.tvKeys
      bar: root.bar
      text: "TV"
      horizontalMargin: 6
      verticalPadding: 6
      fixedWidth: root.vertical ? root.barSize : Style.space(20)
      fixedHeight: root.barSize
    }

    Repeater {
      id: buttons
      model: root.visibleIds

      // WidgetButton fades its opacity and label colour, so dimming happens on
      // this plain wrapper and the focused number is hidden outright: both snap.
      Item {
        id: slot
        required property int modelData

        readonly property bool occupied: root.occupiedIds[modelData] === true
        readonly property bool focused: root.focusedId === modelData
        readonly property string agent: root.agentStates[modelData] || ""

        implicitWidth: button.implicitWidth
        implicitHeight: button.implicitHeight
        opacity: occupied || focused ? 1 : 0.5
        // The focused workspace glows instead of being replaced by a filled square.
        layer.enabled: focused
        layer.effect: Item {
          id: glow
          property var source
          // Stacked shadows: one MultiEffect shadow tops out at full opacity.
          Repeater {
            model: 3
            MultiEffect {
              anchors.fill: parent
              source: glow.source
              shadowEnabled: true
              shadowColor: root.bar ? root.bar.barForeground : Color.foreground
              shadowBlur: 1.0
              blurMax: 32
              shadowScale: 1.2
              autoPaddingEnabled: false
              paddingRect: Qt.rect(48, 48, 48, 48)
              shadowOpacity: 1
              shadowHorizontalOffset: 0
              shadowVerticalOffset: 0
            }
          }
        }

        WidgetButton {
          id: button
          anchors.fill: parent
          bar: root.bar
          text: String(slot.modelData % 10)
          // A ring or checkmark takes the number's place while an agent has news.
          labelVisible: slot.agent === "" || root.vertical
          horizontalMargin: 6
          verticalPadding: 6
          fixedWidth: root.vertical ? root.barSize : Style.space(20)
          fixedHeight: root.barSize
          onPressed: function() { root.focusWorkspace(slot.modelData) }
        }

        AgentMark {
          anchors.centerIn: parent
          agent: root.vertical ? "" : slot.agent
          tint: root.bar ? root.bar.barForeground : Color.foreground
        }
      }
    }
  }
}
