import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "pietrovos.opencode-completions"

  property bool popupOpen: false
  property var records: []
  readonly property string completionDir: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/opencode/completions"

  function refresh() {
    if (!recordsProbe.running) recordsProbe.running = true
  }

  function setRecords(output) {
    var next = []
    var lines = String(output || "").split("\n")
    for (var i = 0; i < lines.length; i++) {
      try {
        if (lines[i]) next.push(JSON.parse(lines[i]))
      } catch (error) {
        // Ignore an incomplete file while an OpenCode process is writing it.
      }
    }
    records = next
  }

  function focusRecord(record) {
    if (!record.address || !root.bar) return

    var command = "hyprctl dispatch " + Util.shellQuote("hl.dsp.focus({ window = \"address:" + record.address + "\" })")
    if (record.groupIndex > 0)
      command += " && hyprctl dispatch " + Util.shellQuote("hl.dsp.group.active({ index = " + record.groupIndex + " })")
    root.bar.run(command)
    popupOpen = false
  }

  function launchTui() {
    if (!root.bar) return
    root.bar.run("setsid uwsm-app -- xdg-terminal-exec --app-id=org.omarchy.opencode -e opencode-completions-tui >/dev/null 2>&1 &")
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    bar: root.bar
    text: "\uf00c"
    tooltipText: "OpenCode completions"
    onPressed: function(button) {
      if (button === Qt.RightButton) root.launchTui()
      else root.popupOpen = !root.popupOpen
    }

    Rectangle {
      visible: root.records.length > 0
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.margins: 2
      width: count.implicitWidth + 6
      height: count.implicitHeight + 2
      radius: height / 2
      color: Color.accent

      Text {
        id: count
        anchors.centerIn: parent
        text: root.records.length > 9 ? "9+" : String(root.records.length)
        color: Color.background
        font.family: Style.font.family
        font.pixelSize: Style.font.caption - 1
        font.bold: true
      }
    }
  }

  PopupCard {
    id: popup
    anchorItem: root
    owner: root
    bar: root.bar
    open: root.popupOpen
    contentWidth: popup.fittedContentWidth(Style.space(320))
    contentHeight: popup.fittedContentHeight(content.implicitHeight, Style.space(420))

    Column {
      id: content
      anchors.fill: parent
      spacing: Style.space(8)

      Text {
        text: "OpenCode completions"
        color: Color.foreground
        font.family: Style.font.family
        font.pixelSize: Style.font.body
        font.bold: true
      }

      Text {
        visible: root.records.length === 0
        text: "Completed sessions will appear here."
        color: Qt.darker(Color.foreground, 1.4)
        font.family: Style.font.family
        font.pixelSize: Style.font.bodySmall
      }

      Flickable {
        visible: root.records.length > 0
        width: parent.width
        implicitHeight: Math.min(recordsColumn.implicitHeight, Style.space(360))
        height: implicitHeight
        contentWidth: width
        contentHeight: recordsColumn.implicitHeight
        clip: true

        Column {
          id: recordsColumn
          width: parent.width
          spacing: Style.space(4)

          Repeater {
            model: root.records

            delegate: Rectangle {
              required property var modelData
              readonly property var record: modelData
              width: recordsColumn.width
              implicitHeight: Style.space(32)
              radius: Style.cornerRadius
              color: Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.08)

              Text {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: Style.space(8)
                text: "Workspace " + record.workspace + (record.groupCount > 1 ? " | Tab " + record.groupIndex + "/" + record.groupCount : "")
                color: Color.foreground
                font.family: Style.font.family
                font.pixelSize: Style.font.bodySmall
                elide: Text.ElideRight
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.focusRecord(record)
              }
            }
          }
        }
      }
    }
  }

  // Polling lets separate OpenCode processes append records without a shared daemon.
  Process {
    id: recordsProbe
    command: ["sh", "-c", "find \"" + root.completionDir + "\" -maxdepth 1 -type f -name '*.json' -printf '%T@ %p\\n' 2>/dev/null | sort -nr | head -n 50 | cut -d' ' -f2- | xargs -r cat"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.setRecords(text)
    }
    onExited: function(exitCode) {
      if (exitCode !== 0) root.records = []
    }
  }

  Timer {
    interval: 2000
    repeat: true
    running: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }
}
