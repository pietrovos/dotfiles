import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
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
  property bool tvActive: false

  readonly property var workspaceIds: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
  // 1-10 always; the TV's workspace 11 only while the TV is on as its own screen
  // (or if 11 is somehow occupied or focused without it).
  readonly property var visibleIds: workspaceIds.filter(function(id) {
    return id <= 10 || tvActive || occupiedIds[id] === true || focusedId === id
  })

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
    "monitoradded", "monitoraddedv2",
    "monitorremoved", "monitorremovedv2"
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
    if (parts.length < 2) return

    var active
    var list
    var monitors = []
    try {
      active = JSON.parse(parts[0].trim())
      list = JSON.parse(parts[1].trim())
      if (parts.length > 2) monitors = JSON.parse(parts[2].trim())
    } catch (error) {
      return
    }

    if (!active || !Array.isArray(list)) return

    var occupied = {}
    for (var i = 0; i < list.length; i++) {
      var id = list[i] && list[i].id
      if (id > 0 && id <= 11 && list[i].windows > 0) occupied[id] = true
    }

    root.occupiedIds = occupied
    root.tvActive = Array.isArray(monitors) && monitors.some(function(monitor) {
      return monitor && monitor.name === "HDMI-A-1" && !monitor.disabled && monitor.mirrorOf === "none"
    })
    root.focusedId = (active.id > 0 && active.id <= 11) ? active.id : 0
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
    command: ["sh", "-c", "hyprctl -j activeworkspace; printf '\\n@@@\\n'; hyprctl -j workspaces; printf '\\n@@@\\n'; hyprctl -j monitors"]

    onRunningChanged: {
      if (!running && root.refreshPending) root.refresh()
    }

    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.applyState(text)
    }
  }

  Component.onCompleted: root.refresh()

  readonly property real trailingGap: root.vertical ? 0 : Style.spaceReal(1.5)

  implicitWidth: grid.implicitWidth + trailingGap
  implicitHeight: grid.implicitHeight

  GridLayout {
    id: grid
    anchors.fill: parent
    anchors.rightMargin: root.trailingGap
    columns: root.vertical ? 1 : Math.max(1, root.visibleIds.length)
    columnSpacing: root.vertical ? 0 : Style.space(1)
    rowSpacing: root.vertical ? Style.space(2) : 0

    Repeater {
      model: root.visibleIds

      WidgetButton {
        required property int modelData

        readonly property bool occupied: root.occupiedIds[modelData] === true
        readonly property bool focused: root.focusedId === modelData

        bar: root.bar
        text: modelData === 10 ? "0" : String(modelData)
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
        horizontalMargin: 6
        verticalPadding: 6
        fixedWidth: root.vertical ? root.barSize : Style.space(20)
        fixedHeight: root.barSize
        onPressed: function() { root.focusWorkspace(modelData) }
      }
    }
  }
}
