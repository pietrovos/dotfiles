import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.Commons
import qs.Ui
import "../pietrovos.workspaces"

BarWidget {
  id: root
  moduleName: "pietrovos.group-tabs"

  property var members: []
  property int activeIndex: -1
  property string subspaceName: ""
  readonly property real leadingGap: Style.spaceReal(14)

  readonly property string stateDir: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/omarchy"
  readonly property string namesPath: stateDir + "/group-subspaces.json"
  readonly property string agentsDir: stateDir + "/agent-marks"
  // Window address -> "running", "question" or "done", from agent-status marks.
  // pietrovos.workspaces leaves these to the tabs while this group is shown.
  property var agentMarks: ({})
  readonly property real labelGap: shownName !== "" ? Style.spaceReal(-1) : 0

  // What is drawn, kept through the fade-out after the group goes away.
  property var shownMembers: []
  property string shownName: ""
  // 0 hidden, 1 fully open: the widget widens and fades in from nothing. It
  // eases one frame at a time with each frame counted as at most 1/60s, since
  // it opens on workspace switches, which can stall the bar for ~100ms.
  property real reveal: 0
  readonly property real revealTarget: members.length > 0 && !vertical ? 1 : 0

  FrameAnimation {
    running: root.reveal !== root.revealTarget
    onTriggered: {
      var gap = root.revealTarget - root.reveal
      root.reveal = Math.abs(gap) < 0.005 ? root.revealTarget : root.reveal + gap * (1 - Math.exp(-14 * Math.min(frameTime, 1 / 60)))
    }
  }

  function refresh() {
    if (!groupProbe.running) groupProbe.running = true
    if (!marksProbe.running) marksProbe.running = true
  }

  function updateMarks(output) {
    var marks = {}
    var lines = String(output).trim().split("\n")
    for (var i = 0; i < lines.length; i++) {
      var fields = lines[i].trim().split(" ")
      if (["running", "question", "done"].indexOf(fields[1]) !== -1) marks[fields[0]] = fields[1]
    }
    agentMarks = marks
  }

  function updateGroup(output) {
    try {
      var active = JSON.parse(output)
      if (!active.address) {
        members = []
        activeIndex = -1
        subspaceName = ""
        return
      }

      subspaceName = active.subspaceName || ""
      var grouped = active.grouped || []
      members = grouped
      activeIndex = grouped.indexOf(active.address)
      if (grouped.length > 0) {
        shownMembers = grouped
        shownName = subspaceName
      }
    } catch (error) {
      members = []
      activeIndex = -1
      subspaceName = ""
    }
  }

  function focusMember(index) {
    if (!root.bar) return
    activeIndex = index - 1
    root.bar.run("/home/pietrovos/.config/hypr/select-group-window " + index)
  }

  visible: reveal > 0
  opacity: reveal
  clip: reveal < 1
  implicitWidth: visible ? (leadingGap + tabGroup.implicitWidth + labelGap + labelBox.implicitWidth) * reveal : 0
  implicitHeight: root.barSize

  Process {
    id: groupProbe
    command: [Quickshell.env("HOME") + "/.config/hypr/group-subspace"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.updateGroup(text)
    }
    onExited: function(exitCode) {
      if (exitCode !== 0) {
        root.members = []
        root.activeIndex = -1
        root.subspaceName = ""
      }
    }
  }

  Process {
    id: marksProbe
    command: ["sh", "-c", "for mark in \"$1\"/0x*; do [ -f \"$mark\" ] && printf '%s %s\\n' \"${mark##*/}\" \"$(cat \"$mark\")\"; done; true", "sh", root.agentsDir]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.updateMarks(text)
    }
  }

  // Touched by agent-status whenever an agent starts or finishes.
  FileView {
    path: root.agentsDir + "/changed"
    watchChanges: true
    printErrors: false
    onFileChanged: root.refresh()
  }

  Timer {
    interval: 1000
    repeat: true
    running: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  Connections {
    target: Hyprland
    function onRawEvent(event) {
      if (["activewindow", "activewindowv2", "closewindow", "movewindowv2", "openwindow", "changeworkspaceid", "togglegroup", "moveintogroup", "moveoutofgroup"].indexOf(event.name) !== -1) {
        root.refresh()
      }
    }
  }

  FileView {
    id: namesFile
    path: root.namesPath
    watchChanges: true
    printErrors: false
    onFileChanged: {
      reload()
      root.refresh()
    }
  }

  Rectangle {
    x: tabGroup.x
    anchors.verticalCenter: parent.verticalCenter
    width: tabGroup.width + (labelBox.visible ? root.labelGap + labelBox.width : 0)
    height: tabGroup.height
    color: "transparent"
    radius: Math.min(Style.cornerRadius, height / 2)
    border.width: 1
    border.color: root.bar ? root.bar.barForeground : Color.foreground
    opacity: 0.5
  }

  Item {
    id: tabGroup
    x: root.leadingGap
    anchors.verticalCenter: parent.verticalCenter
    implicitWidth: grid.implicitWidth + Style.space(2)
    implicitHeight: root.barSize - Style.space(2)
    width: implicitWidth
    height: implicitHeight

    Rectangle {
      anchors.fill: parent
      color: root.bar ? root.bar.barForeground : Color.foreground
      radius: Math.min(Style.cornerRadius, height / 2)
      opacity: 0.12
    }

    GridLayout {
      id: grid
      anchors.centerIn: parent
      columns: root.shownMembers.length
      columnSpacing: Style.space(1)

      Repeater {
        model: root.shownMembers

        WidgetButton {
          id: tab
          required property string modelData
          required property int index
          readonly property bool focused: index === root.activeIndex
          readonly property string agent: root.agentMarks[modelData] || ""

          bar: root.bar
          text: index === 9 ? "0" : String(index + 1)
          // A ring or checkmark takes the number's place while its agent has news.
          labelVisible: agent === ""
          opacity: focused ? 1 : 0.55
          // The shown tab glows instead of being replaced by a filled square.
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
          fixedWidth: Style.space(20)
          fixedHeight: tabGroup.height
          onPressed: root.focusMember(index + 1)

          AgentMark {
            anchors.centerIn: parent
            agent: tab.agent
            tint: root.bar ? root.bar.barForeground : Color.foreground
          }
        }
      }
    }
  }

  Item {
    id: labelBox
    visible: root.shownName !== ""
    x: tabGroup.x + tabGroup.width + root.labelGap
    anchors.verticalCenter: parent.verticalCenter
    implicitWidth: subspaceLabel.implicitWidth + Style.space(8)
    implicitHeight: root.barSize - Style.space(2)
    width: implicitWidth
    height: implicitHeight

    Rectangle {
      anchors.fill: parent
      color: root.bar ? root.bar.barForeground : Color.foreground
      radius: Math.min(Style.cornerRadius, height / 2)
      opacity: 0.12
    }

    Text {
      id: subspaceLabel
      anchors.verticalCenter: parent.verticalCenter
      x: Style.space(4)
      text: root.shownName
      color: root.bar ? root.bar.barForeground : Color.foreground
      opacity: 0.85
      font.family: Style.font.family
      font.pixelSize: Style.font.body
    }
  }
}
