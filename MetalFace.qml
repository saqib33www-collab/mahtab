import QtQuick

// Metal face: a heavy time over a single meta line "PM | Weekday". Bright,
// condensed, reference-design ink.
// Ported from the Ryoku shell's ClockMetal.qml (weather clause dropped).
BaseFace {
  id: face

  readonly property string meta: (use24h ? "" : (t.ampm + "  |  ")) + dp.weekday

  implicitWidth: col.implicitWidth + pad * 2
  implicitHeight: col.implicitHeight + pad * 2

  Column {
    id: col
    anchors.centerIn: parent
    spacing: Math.round(12 * face.faceScale)

    Text {
      text: face.t.hh + ":" + face.t.mm
      color: face.ink
      font.family: face.fontFamily
      font.weight: Font.Black
      font.pixelSize: Math.round(132 * face.faceScale)
      font.letterSpacing: Math.round(-2 * face.faceScale)
    }
    Text {
      text: face.meta
      color: face.ink
      font.family: face.fontFamily
      font.weight: Font.Bold
      font.pixelSize: Math.round(25 * face.faceScale)
      font.letterSpacing: 0.5
    }
  }
}
