import QtQuick

// Digital face: big tabular mono time, the colon breathing in the accent, with
// the seconds and AM/PM stacked small to the right.
// Ported from the Ryoku shell's ClockDigital.qml.
BaseFace {
  id: face

  readonly property real px: Math.round(82 * faceScale)

  implicitWidth: row.implicitWidth + pad * 2
  implicitHeight: row.implicitHeight + pad * 2

  Row {
    id: row
    anchors.centerIn: parent
    spacing: face.side ? Math.round(14 * face.faceScale) : 0

    Row {
      id: hm
      spacing: 0

      Text {
        text: face.t.hh
        color: face.ink
        font.family: face.monoFamily
        font.pixelSize: face.px
        font.weight: Font.Bold
      }
      Text {
        text: ":"
        color: face.accent
        font.family: face.monoFamily
        font.pixelSize: face.px
        font.weight: Font.Bold
      }
      Text {
        text: face.t.mm
        color: face.ink
        font.family: face.monoFamily
        font.pixelSize: face.px
        font.weight: Font.Bold
      }
    }

    Item {
      height: hm.height
      width: Math.max(secs.implicitWidth, ampm.implicitWidth)
      visible: face.side

      Column {
        anchors.verticalCenter: parent.verticalCenter
        spacing: Math.round(4 * face.faceScale)

        Text {
          id: secs
          visible: face.showSeconds
          text: face.t.ss
          color: face.accent
          font.family: face.monoFamily
          font.pixelSize: Math.round(face.px * 0.3)
          font.weight: Font.DemiBold
        }
        Text {
          id: ampm
          visible: !face.use24h
          text: face.t.ampm
          color: face.inkDim
          font.family: face.monoFamily
          font.pixelSize: Math.round(face.px * 0.24)
          font.weight: Font.DemiBold
          font.letterSpacing: 1
        }
      }
    }
  }
}
