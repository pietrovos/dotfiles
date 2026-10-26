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
  moduleName: "pietrovos.group-tabs"

  property var members: []
  property int activeIndex: -1
  property string subspaceName: ""
  readonly property real leadingGap: Style.spaceReal(14)

  readonly property string stateDir: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/omarchy"
  readonly property string namesPath: stateDir + "/group-subspaces.json"
  readonly property real labelGap: subspaceName !== "" ? Style.spaceReal(-1) : 0

  function refresh() {
    if (!groupProbe.running) groupProbe.running = true
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

  visible: members.length > 0 && !vertical
  implicitWidth: visible ? leadingGap + tabGroup.implicitWidth + labelGap + labelBox.implicitWidth : 0
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
      columns: root.members.length
      columnSpacing: Style.space(1)

      Repeater {
        model: root.members

        WidgetButton {
          readonly property bool focused: index === root.activeIndex

          bar: root.bar
          text: index === 9 ? "0" : String(index + 1)
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
                autoPaddingEnabled: false
                paddingRect: Qt.rect(48, 48, 96, 96)
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
        }
      }
    }
  }

  Item {
    id: labelBox
    visible: root.subspaceName !== ""
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
      text: root.subspaceName
      color: root.bar ? root.bar.barForeground : Color.foreground
      opacity: 0.85
      font.family: Style.font.family
      font.pixelSize: Style.font.body
    }
  }
}
