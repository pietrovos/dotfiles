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

      WidgetButton {
        required property int modelData

        readonly property bool occupied: root.occupiedIds[modelData] === true
        readonly property bool focused: root.focusedId === modelData

        bar: root.bar
        text: String(modelData % 10)
        opacity: occupied || focused ? 1 : 0.5
        // The focused workspace shows a Sharingan in place of its number: the
        // eye fades in as the number fades out, and back when focus moves on.
        readonly property color labelColor: root.bar ? root.bar.barForeground : Color.foreground
        foreground: Qt.rgba(labelColor.r, labelColor.g, labelColor.b, 1 - eye.level)

        Sharingan {
          id: eye
          z: -1
          lit: parent.focused && !root.vertical
        }
        horizontalMargin: 6
        verticalPadding: 6
        fixedWidth: root.vertical ? root.barSize : Style.space(20)
        fixedHeight: root.barSize
        onPressed: function() { root.focusWorkspace(modelData) }
      }
    }
  }

  // A static Sharingan that fades in while lit and out when not. The
  // fade eases one frame at a time with each frame counted as at most 1/60s:
  // switching workspaces can stall the bar for ~100ms, and a timed animation
  // skipped most of its motion during that stall.
  component Sharingan: Item {
    id: ring
    property bool lit: false
    property real level: 0
    visible: level > 0
    opacity: level
    anchors.centerIn: parent
    height: parent.height - 14
    width: height

    // Theme colours: the iris is the bar's text colour at full strength, the
    // rim, pupil and tomoe the bar background, so it stays crisp on any theme.
    readonly property color irisColor: Color.bar.text
    readonly property color inkColor: Color.bar.background
    onIrisColorChanged: eye.requestPaint()
    onInkColorChanged: eye.requestPaint()

    // Drawn at 3x and scaled down so it stays crisp at this size.
    Canvas {
      id: eye
      anchors.centerIn: parent
      width: parent.width * 3
      height: parent.height * 3
      scale: 1 / 3
      smooth: true
      antialiasing: true
      onWidthChanged: requestPaint()

      onPaint: {
        var ctx = getContext("2d")
        var r = width / 2
        ctx.reset()
        ctx.translate(r, r)

        ctx.fillStyle = ring.irisColor
        ctx.beginPath()
        ctx.arc(0, 0, r - 2, 0, 2 * Math.PI)
        ctx.fill()
        ctx.strokeStyle = ring.inkColor
        ctx.lineWidth = 4
        ctx.stroke()

        // The faint ring the tomoe ride on.
        ctx.lineWidth = 1.5
        ctx.beginPath()
        ctx.arc(0, 0, r * 0.58, 0, 2 * Math.PI)
        ctx.stroke()

        ctx.fillStyle = ring.inkColor
        ctx.beginPath()
        ctx.arc(0, 0, r * 0.2, 0, 2 * Math.PI)
        ctx.fill()

        // Three tomoe: a round head with a thin tail curling back along the ring.
        var head = r * 0.16
        for (var i = 0; i < 3; i++) {
          var angle = i * 2 * Math.PI / 3 - Math.PI / 2
          var cx = Math.cos(angle) * r * 0.58
          var cy = Math.sin(angle) * r * 0.58
          var nx = Math.cos(angle), ny = Math.sin(angle)
          var tx = -ny, ty = nx

          ctx.beginPath()
          ctx.arc(cx, cy, head, 0, 2 * Math.PI)
          ctx.fill()

          ctx.beginPath()
          ctx.moveTo(cx + nx * head, cy + ny * head)
          ctx.quadraticCurveTo(cx + nx * head * 0.9 - tx * head * 1.8, cy + ny * head * 0.9 - ty * head * 1.8,
                               cx - tx * head * 3.4 + nx * head * 0.9, cy - ty * head * 3.4 + ny * head * 0.9)
          ctx.quadraticCurveTo(cx - tx * head * 1.6 + nx * head * 0.15, cy - ty * head * 1.6 + ny * head * 0.15,
                               cx - tx * head * 0.6 - nx * head * 0.8, cy - ty * head * 0.6 - ny * head * 0.8)
          ctx.closePath()
          ctx.fill()
        }
      }
    }

    FrameAnimation {
      running: ring.level !== (ring.lit ? 1 : 0)
      onTriggered: {
        var target = ring.lit ? 1 : 0
        var gap = target - ring.level
        ring.level = Math.abs(gap) < 0.01 ? target : ring.level + gap * (1 - Math.exp(-12 * Math.min(frameTime, 1 / 60)))
      }
    }
  }
}
