import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Shapes
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

  // Centre of the focused number, where the ring heads.
  readonly property real markerX: {
    var index = visibleIds.indexOf(focusedId)
    var item = buttons.count > 0 && index >= 0 ? buttons.itemAt(index) : null
    return item ? item.x + item.width / 2 : -1
  }
  readonly property bool markerShown: markerX >= 0 && !vertical

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
        // The Sharingan behind it marks the focused workspace; the glow's halo
        // ringed it in grey.
        layer.enabled: false
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

  // A slowly spinning Sharingan behind the focused number that slides to the
  // next one. It eases one frame at a time with each frame counted as at most
  // 1/60s: switching workspaces can stall the bar for ~100ms, and a timed
  // animation skipped most of a slide during that stall.
  Item {
    id: ring
    property real centerX: -1
    visible: root.markerShown
    z: -1
    height: root.height - 6
    width: height
    x: centerX - width / 2
    y: (root.height - height) / 2

    // Drawn at 3x and scaled down so it stays crisp at this size.
    Canvas {
      anchors.centerIn: parent
      width: parent.width * 3
      height: parent.height * 3
      scale: 1 / 3
      smooth: true
      antialiasing: true
      onWidthChanged: requestPaint()

      RotationAnimator on rotation {
        running: ring.visible
        loops: Animation.Infinite
        from: 0
        to: 360
        duration: 4000
      }

      onPaint: {
        var ctx = getContext("2d")
        var r = width / 2
        ctx.reset()
        ctx.translate(r, r)

        var iris = ctx.createRadialGradient(0, 0, r * 0.1, 0, 0, r)
        iris.addColorStop(0, "#e0262c")
        iris.addColorStop(1, "#8c0d12")
        ctx.fillStyle = iris
        ctx.beginPath()
        ctx.arc(0, 0, r - 2, 0, 2 * Math.PI)
        ctx.fill()
        ctx.strokeStyle = "#000000"
        ctx.lineWidth = 4
        ctx.stroke()

        // The faint ring the tomoe ride on.
        ctx.lineWidth = 1.5
        ctx.beginPath()
        ctx.arc(0, 0, r * 0.58, 0, 2 * Math.PI)
        ctx.stroke()

        ctx.fillStyle = "#000000"
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
      running: root.markerShown && ring.centerX !== root.markerX
      onTriggered: {
        var gap = root.markerX - ring.centerX
        if (ring.centerX < 0 || Math.abs(gap) < 0.3) {
          ring.centerX = root.markerX
          return
        }
        ring.centerX += gap * (1 - Math.exp(-16 * Math.min(frameTime, 1 / 60)))
      }
    }
  }
}
