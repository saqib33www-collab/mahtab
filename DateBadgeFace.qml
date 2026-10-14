import QtQuick

// Badge date: an accent-tinted chip with a big day number and the weekday /
// month stacked beside it.
// Ported from the Ryoku shell's DateBadge.qml.
BaseFace {
  id: face

  implicitWidth: chip.width + pad * 2
  implicitHeight: chip.height + pad * 2

  Rectangle {
    id: chip
    anchors.centerIn: parent
    width: inner.implicitWidth + Math.round(28 * face.faceScale)
    height: inner.implicitHeight + Math.round(16 * face.faceScale)
    radius: Math.round(14 * face.faceScale)
    color: Qt.rgba(face.accent.r, face.accent.g, face.accent.b, 0.16)
    border.width: Math.max(1, Math.round(face.faceScale))
    border.color: Qt.rgba(face.accent.r, face.accent.g, face.accent.b, 0.42)

    Row {
      id: inner
      anchors.centerIn: parent
      spacing: Math.round(12 * face.faceScale)

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: face.dp.dom
        color: face.ink
        font.family: face.monoFamily
        font.pixelSize: Math.round(40 * face.faceScale)
        font.weight: Font.Bold
      }

      Column {
        anchors.verticalCenter: parent.verticalCenter
        spacing: Math.round(2 * face.faceScale)

        Text {
          text: face.dp.weekdayShort
          color: face.accent
          font.family: face.fontFamily
          font.pixelSize: Math.round(15 * face.faceScale)
          font.weight: Font.DemiBold
          font.letterSpacing: Math.round(2 * face.faceScale)
        }
        Text {
          text: face.dp.monthTitle
          color: face.inkSoft
          font.family: face.fontFamily
          font.pixelSize: Math.round(15 * face.faceScale)
          font.weight: Font.Medium
        }
      }
    }
  }
}
