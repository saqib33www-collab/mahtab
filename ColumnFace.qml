import QtQuick

// Column face: the hour stacked over the minute, both huge and tight. The
// minute carries the accent so the two lines read apart.
// Ported from the Ryoku shell's ClockColumn.qml.
BaseFace {
  id: face

  readonly property real px: Math.round(150 * faceScale)

  implicitWidth: col.implicitWidth + pad * 2
  implicitHeight: col.implicitHeight + pad * 2

  Column {
    id: col
    anchors.centerIn: parent
    spacing: Math.round(-0.2 * face.px)

    Text {
      text: face.t.hh
      color: face.ink
      font.family: face.fontFamily
      font.weight: Font.Bold
      font.pixelSize: face.px
      font.letterSpacing: Math.round(-2 * face.faceScale)
    }
    Text {
      text: face.t.mm
      color: face.accent
      font.family: face.fontFamily
      font.weight: Font.Bold
      font.pixelSize: face.px
      font.letterSpacing: Math.round(-2 * face.faceScale)
    }
    Row {
      spacing: Math.round(8 * face.faceScale)
      topPadding: Math.round(0.1 * face.px)
      visible: face.side
      Text {
        visible: face.showSeconds
        text: face.t.ss
        color: face.inkDim
        font.family: face.fontFamily
        font.weight: Font.DemiBold
        font.pixelSize: Math.round(face.px * 0.2)
      }
      Text {
        visible: !face.use24h
        text: face.t.ampm
        color: face.inkDim
        font.family: face.fontFamily
        font.weight: Font.DemiBold
        font.pixelSize: Math.round(face.px * 0.2)
        font.letterSpacing: 2
      }
    }
  }
}
