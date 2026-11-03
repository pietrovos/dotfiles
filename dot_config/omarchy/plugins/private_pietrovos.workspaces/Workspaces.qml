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

  readonly property string stateDir: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/omarchy"
  readonly property string tvKeysPath: stateDir + "/tv-workspace-keys"

  // How the focused workspace is marked: "dot", "orbit" or "underline".
  property string marker: "dot"
  readonly property real markerX: {
    var index = visibleIds.indexOf(focusedId)
    var item = buttons.count > 0 && index >= 0 ? buttons.itemAt(index) : null
    return item ? item.x + item.width / 2 : -1
  }
  readonly property bool markerShown: markerX >= 0 && !vertical
  onMarkerXChanged: console.log("MARKERDBG markerX", markerX, "focused", focusedId)

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
    "activespecial"
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
    try {
      active = JSON.parse(parts[0].trim())
      list = JSON.parse(parts[1].trim())
    } catch (error) {
      return
    }

    if (!active || !Array.isArray(list)) return

    var occupied = {}
    for (var i = 0; i < list.length; i++) {
      var id = list[i] && list[i].id
      if (id > 0 && id <= 20 && list[i].windows > 0) occupied[id] = true
    }

    root.occupiedIds = occupied
    root.focusedId = (active.id > 0 && active.id <= 20) ? active.id : 0
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
    command: ["sh", "-c", "hyprctl -j activeworkspace; printf '\\n@@@\\n'; hyprctl -j workspaces"]

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

  FileView {
    path: root.stateDir + "/workspace-marker"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: {
      var value = text().trim()
      root.marker = ["dot", "orbit", "underline"].indexOf(value) !== -1 ? value : "dot"
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

      WidgetButton {
        required property int modelData

        readonly property bool occupied: root.occupiedIds[modelData] === true
        readonly property bool focused: root.focusedId === modelData

        bar: root.bar
        text: String(modelData % 10)
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

  readonly property color markerColor: root.bar ? root.bar.barForeground : Color.foreground

  // A dot under the number that bobs, and glides to the next workspace.
  Rectangle {
    id: dot
    property real bob: 0
    visible: root.markerShown && root.marker === "dot"
    width: 4
    height: 4
    radius: 2
    color: root.markerColor
    x: root.markerX - width / 2
    y: root.height - 7 + bob
    Behavior on x { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
    SequentialAnimation on bob {
      running: dot.visible
      loops: Animation.Infinite
      NumberAnimation { to: -2.5; duration: 700; easing.type: Easing.InOutSine }
      NumberAnimation { to: 0; duration: 700; easing.type: Easing.InOutSine }
    }
  }

  // A dot circling the number.
  Item {
    id: orbit
    property real angle: 0
    visible: root.markerShown && root.marker === "orbit"
    x: root.markerX
    y: root.height / 2
    Behavior on x { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
    NumberAnimation on angle {
      running: orbit.visible
      loops: Animation.Infinite
      from: 0
      to: 2 * Math.PI
      duration: 2400
    }

    Rectangle {
      width: 3
      height: 3
      radius: 1.5
      color: root.markerColor
      x: 11 * Math.cos(orbit.angle) - width / 2
      y: 10 * Math.sin(orbit.angle) - height / 2
    }
  }

  // A short line under the number that slides to the next workspace.
  Rectangle {
    visible: root.markerShown && root.marker === "underline"
    onXChanged: console.log("MARKERDBG ux", x.toFixed(1))
    width: 12
    height: 2
    radius: 1
    color: root.markerColor
    x: root.markerX - width / 2
    y: root.height - 5
    Behavior on x { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
  }
}
