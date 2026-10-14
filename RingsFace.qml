import QtQuick

// Rings face: three concentric arcs sweeping hour / minute / second over faint
// tracks, with the time set digitally in the centre.
// Ported from the Ryoku shell's ClockRings.qml.
BaseFace {
  id: face

  readonly property real dia: Math.round(232 * faceScale)

  implicitWidth: dia + pad * 2
  implicitHeight: dia + pad * 2

  onTChanged: canvas.requestPaint()
  onAccentChanged: canvas.requestPaint()
  onDiaChanged: canvas.requestPaint()

  function css(c, a) {
    return "rgba(" + Math.round(c.r * 255) + "," + Math.round(c.g * 255) + ","
      + Math.round(c.b * 255) + "," + a + ")"
  }
  function ringColor(i) {
    var c = i === 0 ? Qt.lighter(face.accent, 1.15)
      : (i === 1 ? face.accent : Qt.lighter(face.accent, 1.4))
    return face.css(c, 1)
  }

  Canvas {
    id: canvas
    anchors.fill: parent
    anchors.margins: face.pad
    renderStrategy: Canvas.Cooperative
    Component.onCompleted: requestPaint()
    onPaint: {
      var ctx = getContext("2d")
      var w = width
      ctx.reset()
      ctx.clearRect(0, 0, w, w)
      var cx = w / 2, cy = w / 2
      var lineW = w * 0.05
      var gap = lineW * 1.75
      var r0 = w / 2 - lineW * 0.7 - 2
      var radii = [r0 - 2 * gap, r0 - gap, r0]
      var fr = [
        ((face.t.hours % 12) + face.t.minutes / 60) / 12,
        (face.t.minutes + face.t.seconds / 60) / 60,
        face.t.seconds / 60
      ]
      for (var i = 0; i < 3; i++) {
        ctx.beginPath()
        ctx.lineWidth = lineW
        ctx.lineCap = "butt"
        ctx.strokeStyle = face.css(face.ink, 0.12)
        ctx.arc(cx, cy, radii[i], 0, 2 * Math.PI, false)
        ctx.stroke()
        if (fr[i] > 0.0001) {
          ctx.beginPath()
          ctx.lineWidth = lineW
          ctx.lineCap = "round"
          ctx.strokeStyle = face.ringColor(i)
          ctx.arc(cx, cy, radii[i], -Math.PI / 2, -Math.PI / 2 + fr[i] * 2 * Math.PI, false)
          ctx.stroke()
        }
      }
    }
  }

  Column {
    anchors.centerIn: parent
    spacing: 0

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: face.t.hh + ":" + face.t.mm
      color: face.ink
      font.family: face.monoFamily
      font.pixelSize: Math.round(face.dia * 0.16)
      font.weight: Font.Bold
    }
    Text {
      visible: !face.use24h
      anchors.horizontalCenter: parent.horizontalCenter
      text: face.t.ampm
      color: face.inkDim
      font.family: face.monoFamily
      font.pixelSize: Math.round(face.dia * 0.066)
      font.weight: Font.DemiBold
      font.letterSpacing: 2
    }
  }
}
