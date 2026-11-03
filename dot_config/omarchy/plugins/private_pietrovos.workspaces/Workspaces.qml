import QtQuick
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

        implicitWidth: button.implicitWidth
        implicitHeight: button.implicitHeight
        opacity: occupied || focused ? 1 : 0.5

        WidgetButton {
          id: button
          anchors.fill: parent
          bar: root.bar
          text: String(slot.modelData % 10)
          labelVisible: !slot.focused
          horizontalMargin: 6
          verticalPadding: 6
          fixedWidth: root.vertical ? root.barSize : Style.space(20)
          fixedHeight: root.barSize
          onPressed: function() { root.focusWorkspace(slot.modelData) }
        }

        // The focused workspace shows a dimmed ring in place of its number, with
        // a bright point and fading tail travelling around it. The light stays
        // inside the ring's outline: a blurred glow spilled past it.
        Item {
          id: marker
          readonly property color tint: root.bar ? root.bar.barForeground : Color.foreground
          visible: slot.focused && !root.vertical
          anchors.centerIn: parent
          width: 12
          height: 12
          onTintChanged: halo.requestPaint()

          // Drawn at 3x and scaled down so it stays crisp at this size.
          Canvas {
            id: halo
            anchors.centerIn: parent
            width: parent.width * 3
            height: parent.height * 3
            scale: 1 / 3
            smooth: true
            antialiasing: true
            onWidthChanged: requestPaint()

            RotationAnimator on rotation {
              running: marker.visible
              loops: Animation.Infinite
              from: 0
              to: 360
              duration: 1600
            }

            onPaint: {
              var ctx = getContext("2d")
              var line = 4.5
              var r = width / 2 - line / 2
              var tint = marker.tint
              ctx.reset()
              ctx.lineWidth = line

              ctx.strokeStyle = Qt.rgba(tint.r, tint.g, tint.b, 0.4)
              ctx.beginPath()
              ctx.arc(width / 2, height / 2, r, 0, 2 * Math.PI)
              ctx.stroke()

              var comet = ctx.createConicalGradient(width / 2, height / 2, 0)
              comet.addColorStop(0, Qt.rgba(tint.r, tint.g, tint.b, 1))
              comet.addColorStop(0.35, Qt.rgba(tint.r, tint.g, tint.b, 0))
              comet.addColorStop(1, Qt.rgba(tint.r, tint.g, tint.b, 0))
              ctx.strokeStyle = comet
              ctx.beginPath()
              ctx.arc(width / 2, height / 2, r, 0, 2 * Math.PI)
              ctx.stroke()
            }
          }
        }
      }
    }
  }
}
