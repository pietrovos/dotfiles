import QtQuick
import qs.Commons

// What a coding agent shows in place of a number in the bar: a ring with a
// bright point and fading tail travelling around it while the agent runs, a
// question mark while it waits on an answer, and a checkmark once it finishes. The light stays inside the ring's outline: a
// blurred glow spilled past it. Used by pietrovos.workspaces and, through a
// directory import, pietrovos.group-tabs.
Item {
  id: mark

  // "running", "question", "done" or "" for nothing.
  property string agent: ""
  property color tint: "white"

  visible: agent !== ""
  width: 13
  height: 13
  onTintChanged: {
    halo.requestPaint()
    check.requestPaint()
  }

  // Drawn at 3x and scaled down so it stays crisp at this size.
  Canvas {
    id: halo
    visible: mark.agent === "running"
    anchors.centerIn: parent
    width: parent.width * 3
    height: parent.height * 3
    scale: 1 / 3
    smooth: true
    antialiasing: true
    onWidthChanged: requestPaint()

    RotationAnimator on rotation {
      running: halo.visible && mark.visible
      loops: Animation.Infinite
      from: 0
      to: 360
      duration: 1600
    }

    onPaint: {
      var ctx = getContext("2d")
      var line = 6
      var r = width / 2 - line / 2
      var tint = mark.tint
      ctx.reset()
      ctx.lineWidth = line

      ctx.strokeStyle = Qt.rgba(tint.r, tint.g, tint.b, 0.3)
      ctx.beginPath()
      ctx.arc(width / 2, height / 2, r, 0, 2 * Math.PI)
      ctx.stroke()

      var comet = ctx.createConicalGradient(width / 2, height / 2, 0)
      comet.addColorStop(0, Qt.rgba(tint.r, tint.g, tint.b, 1))
      comet.addColorStop(0.45, Qt.rgba(tint.r, tint.g, tint.b, 0))
      comet.addColorStop(1, Qt.rgba(tint.r, tint.g, tint.b, 0))
      ctx.strokeStyle = comet
      ctx.beginPath()
      ctx.arc(width / 2, height / 2, r, 0, 2 * Math.PI)
      ctx.stroke()
    }
  }

  Text {
    visible: mark.agent === "question"
    anchors.centerIn: parent
    text: "?"
    color: mark.tint
    font.family: Style.font.family
    font.pixelSize: 15
    font.bold: true
  }

  Canvas {
    id: check
    visible: mark.agent === "done"
    anchors.fill: parent
    antialiasing: true

    onPaint: {
      var ctx = getContext("2d")
      ctx.reset()
      ctx.strokeStyle = mark.tint
      ctx.lineWidth = 2
      ctx.lineCap = "round"
      ctx.lineJoin = "round"
      ctx.beginPath()
      ctx.moveTo(2, 7)
      ctx.lineTo(5.5, 10.5)
      ctx.lineTo(11, 3)
      ctx.stroke()
    }
  }
}
