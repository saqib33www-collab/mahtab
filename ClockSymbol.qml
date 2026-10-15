import QtQuick

// A drawn clock face, used as the bar icon and in the settings panel. It fills
// whatever box it is given and reads its tint from `color`, so it drops into a
// BarIconButton.iconComponent or sits next to a label.
Item {
  id: root

  property color color: "#ffffff"

  onColorChanged: canvas.requestPaint()
  onWidthChanged: canvas.requestPaint()
  onHeightChanged: canvas.requestPaint()

  Canvas {
    id: canvas
    anchors.fill: parent
    onPaint: {
      var ctx = getContext("2d")
      ctx.reset()

      var cx = width / 2
      var cy = height / 2
      var lw = Math.max(1, Math.min(width, height) * 0.085)
      var r = Math.min(width, height) / 2 - lw

      ctx.strokeStyle = root.color
      ctx.fillStyle = root.color
      ctx.lineCap = "round"
      ctx.lineJoin = "round"

      ctx.lineWidth = lw
      ctx.beginPath()
      ctx.arc(cx, cy, r, 0, Math.PI * 2)
      ctx.stroke()

      // Quarter ticks anchor the dial at 12, 3, 6 and 9.
      var tick = r * 0.18
      ctx.lineWidth = lw
      for (var i = 0; i < 4; i++) {
        var a = i * Math.PI / 2 - Math.PI / 2
        ctx.beginPath()
        ctx.moveTo(cx + Math.cos(a) * (r - tick), cy + Math.sin(a) * (r - tick))
        ctx.lineTo(cx + Math.cos(a) * r, cy + Math.sin(a) * r)
        ctx.stroke()
      }

      // Hands at ten past ten, the classic legible pose.
      var hour = -Math.PI / 2 - Math.PI / 3
      ctx.lineWidth = lw * 1.15
      ctx.beginPath()
      ctx.moveTo(cx, cy)
      ctx.lineTo(cx + Math.cos(hour) * r * 0.44, cy + Math.sin(hour) * r * 0.44)
      ctx.stroke()

      var minute = -Math.PI / 2 + Math.PI / 3
      ctx.lineWidth = lw * 0.85
      ctx.beginPath()
      ctx.moveTo(cx, cy)
      ctx.lineTo(cx + Math.cos(minute) * r * 0.64, cy + Math.sin(minute) * r * 0.64)
      ctx.stroke()

      ctx.beginPath()
      ctx.arc(cx, cy, lw * 0.6, 0, Math.PI * 2)
      ctx.fill()
    }
  }
}
