import QtQuick

// Stacked date: a big day number with the weekday over month/year beside it --
// the torn-calendar look.
// Ported from the Ryoku shell's DateStacked.qml.
BaseFace {
  id: face

  implicitWidth: row.implicitWidth + pad * 2
  implicitHeight: row.implicitHeight + pad * 2

  Row {
    id: row
    anchors.centerIn: parent
    spacing: Math.round(14 * face.faceScale)

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: face.dp.dom
      color: face.ink
      font.family: face.monoFamily
      font.pixelSize: Math.round(52 * face.faceScale)
      font.weight: Font.Bold
    }

    Column {
      anchors.verticalCenter: parent.verticalCenter
      spacing: Math.round(3 * face.faceScale)

      Text {
        text: face.dp.weekday
        color: face.accent
        font.family: face.fontFamily
        font.pixelSize: Math.round(22 * face.faceScale)
        font.weight: Font.DemiBold
      }
      Text {
        text: face.dp.monthTitle + " " + face.dp.year
        color: face.inkDim
        font.family: face.fontFamily
        font.pixelSize: Math.round(17 * face.faceScale)
        font.weight: Font.Medium
      }
    }
  }
}
