import QtQuick

// Inline date: one quiet caption -- weekday in the accent, then month + day in
// soft ink, split by a dot.
// Ported from the Ryoku shell's DateInline.qml.
BaseFace {
  id: face

  readonly property real px: Math.round(22 * faceScale)

  implicitWidth: row.implicitWidth + pad * 2
  implicitHeight: row.implicitHeight + pad * 2

  Row {
    id: row
    anchors.centerIn: parent
    spacing: Math.round(8 * face.faceScale)

    Text {
      text: face.dp.weekday
      color: face.accent
      font.family: face.fontFamily
      font.pixelSize: face.px
      font.weight: Font.DemiBold
    }
    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: "\u00b7"
      color: face.inkDim
      font.family: face.fontFamily
      font.pixelSize: face.px
      font.weight: Font.Bold
    }
    Text {
      text: face.dp.monthTitle + " " + face.dp.dom
      color: face.inkSoft
      font.family: face.fontFamily
      font.pixelSize: face.px
      font.weight: Font.Medium
    }
  }
}
