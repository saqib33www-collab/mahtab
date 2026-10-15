import QtQuick

// A drawn audio-visualizer mark: five rounded equaliser bars of mixed height.
// Same contract as ClockSymbol - fills its box and tints from `color` - so the
// two read as a set wherever they appear together.
Item {
  id: root

  property color color: "#ffffff"
  property var barHeights: [0.42, 0.72, 1.0, 0.6, 0.86]
  property real gapRatio: 0.4

  onColorChanged: canvas.requestPaint()
  onWidthChanged: canvas.requestPaint()
  onHeightChanged: canvas.requestPaint()

  Canvas {
    id: canvas
    anchors.fill: parent
    onPaint: {
      var ctx = getContext("2d")
      ctx.reset()

      var n = root.barHeights.length
      var slot = width / n
      var bw = slot * (1 - root.gapRatio)
      var radius = Math.max(1, bw * 0.35)

      ctx.fillStyle = root.color
      for (var i = 0; i < n; i++) {
        var bh = height * root.barHeights[i]
        var x = i * slot + (slot - bw) / 2
        var y = (height - bh) / 2
        var r = Math.min(radius, bw / 2, bh / 2)
        ctx.beginPath()
        ctx.moveTo(x + r, y)
        ctx.arcTo(x + bw, y, x + bw, y + bh, r)
        ctx.arcTo(x + bw, y + bh, x, y + bh, r)
        ctx.arcTo(x, y + bh, x, y, r)
        ctx.arcTo(x, y, x + bw, y, r)
        ctx.closePath()
        ctx.fill()
      }
    }
  }
}
