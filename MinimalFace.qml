import QtQuick

// Minimal face: thin airy time, wide tracking, a short accent rule below it,
// with seconds / AM-PM as a quiet caption.
// Ported from the Ryoku shell's ClockMinimal.qml.
BaseFace {
  id: face

  readonly property real px: Math.round(82 * faceScale)
  readonly property string caption: (showSeconds ? t.ss : "")
    + (showSeconds && !use24h ? "  " : "")
    + (!use24h ? t.ampm.toLowerCase() : "")

  implicitWidth: col.implicitWidth + pad * 2
  implicitHeight: col.implicitHeight + pad * 2

  Column {
    id: col
    anchors.centerIn: parent
    spacing: Math.round(10 * face.faceScale)

    Text {
      id: time
      text: face.t.hh + ":" + face.t.mm
      color: face.ink
      font.family: face.fontFamily
      font.pixelSize: face.px
      font.weight: Font.Light
      font.letterSpacing: Math.round(2 * face.faceScale)
    }

    Rectangle {
      width: Math.round(time.implicitWidth * 0.34)
      height: Math.max(2, Math.round(3 * face.faceScale))
      radius: height / 2
      color: face.accent
    }

    Text {
      visible: face.caption.length > 0
      text: face.caption
      color: face.inkDim
      font.family: face.fontFamily
      font.pixelSize: Math.round(face.px * 0.22)
      font.weight: Font.Medium
      font.letterSpacing: Math.round(3 * face.faceScale)
    }
  }
}
