import QtQuick
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
  property int activeWorkspaceId: -1
  property var names: ({})
  readonly property real leadingGap: Style.spaceReal(14)

  readonly property string stateDir: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/omarchy"
  readonly property string namesPath: stateDir + "/group-subspaces.json"
  readonly property string subspaceName: {
    var value = names[String(activeWorkspaceId)]
    return value === undefined || value === null ? "" : String(value)
  }
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
        activeWorkspaceId = -1
        return
      }

      activeWorkspaceId = active.workspace ? active.workspace.id : -1
      var grouped = active.grouped || []
      members = grouped
      activeIndex = grouped.indexOf(active.address)
    } catch (error) {
      members = []
      activeIndex = -1
      activeWorkspaceId = -1
    }
  }

  function loadNames(content) {
    try {
      var parsed = JSON.parse(String(content || "{}"))
      names = parsed && typeof parsed === "object" ? parsed : ({})
    } catch (error) {
      names = ({})
    }
  }

  function focusMember(index) {
    if (!root.bar) return
    activeIndex = index - 1
    root.bar.run("hyprctl dispatch " + Util.shellQuote("hl.dsp.group.active({ index = " + index + " })"))
  }

  visible: members.length > 0 && !vertical
  implicitWidth: visible ? leadingGap + tabGroup.implicitWidth + labelGap + labelBox.implicitWidth : 0
  implicitHeight: root.barSize

  Process {
    id: groupProbe
    command: ["hyprctl", "activewindow", "-j"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.updateGroup(text)
    }
    onExited: function(exitCode) {
      if (exitCode !== 0) {
        root.members = []
        root.activeIndex = -1
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
      if (["activewindow", "activewindowv2", "closewindow", "movewindowv2", "openwindow"].indexOf(event.name) !== -1) {
        root.refresh()
      }
    }
  }

  FileView {
    id: namesFile
    path: root.namesPath
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.loadNames(text())
    onLoadFailed: root.names = ({})
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
          text: focused ? "\uDB85\uDCFB" : (index === 9 ? "0" : String(index + 1))
          opacity: focused ? 1 : 0.55
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
