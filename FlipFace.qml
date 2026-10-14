pragma ComponentBehavior: Bound

import QtQuick

// Flip face: split-flap cards, one per digit. Dark cards with a centre seam and
// a faint accent edge; the colon carries the accent. Seconds get their own cards
// when enabled.
// Ported from the Ryoku shell's ClockFlip.qml.
BaseFace {
  id: face

  readonly property real ch: Math.round(104 * faceScale)
  readonly property real cw: Math.round(ch * 0.72)

  implicitWidth: row.implicitWidth + pad * 2
  implicitHeight: row.implicitHeight + pad * 2

  component FlipDigit: Item {
    id: fd
    property string value: "0"
    property string shown: "0"
    implicitWidth: face.cw
    implicitHeight: face.ch

    onValueChanged: if (fd.value !== fd.shown) flip.start()

    SequentialAnimation {
      id: flip
      NumberAnimation { target: rot; property: "angle"; from: 0; to: 88; duration: 120; easing.type: Easing.InQuad }
      ScriptAction { script: fd.shown = fd.value }
      NumberAnimation { target: rot; property: "angle"; from: -88; to: 0; duration: 150; easing.type: Easing.OutQuad }
    }

    Rectangle {
      id: card
      anchors.fill: parent
      radius: Math.round(10 * face.faceScale)
      color: face.shadowColor
      border.width: Math.max(1, Math.round(face.faceScale))
      border.color: Qt.rgba(face.accent.r, face.accent.g, face.accent.b, 0.42)

      Text {
        anchors.centerIn: parent
        text: fd.shown
        color: face.ink
        font.family: face.monoFamily
        font.pixelSize: Math.round(face.ch * 0.64)
        font.weight: Font.Bold
      }

      Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: Math.max(1, Math.round(2 * face.faceScale))
        color: Qt.rgba(0, 0, 0, 0.4)
      }
    }

    transform: Rotation {
      id: rot
      origin.x: face.cw / 2
      origin.y: face.ch / 2
      axis { x: 1; y: 0; z: 0 }
      angle: 0
    }
  }

  Row {
    id: row
    anchors.centerIn: parent
    spacing: Math.round(7 * face.faceScale)

    FlipDigit { value: face.t.hh.charAt(0) }
    FlipDigit { value: face.t.hh.charAt(1) }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: ":"
      color: face.accent
      font.family: face.monoFamily
      font.pixelSize: Math.round(face.ch * 0.5)
      font.weight: Font.Bold
      SequentialAnimation on opacity {
        loops: Animation.Infinite
        NumberAnimation { from: 1; to: 0.3; duration: 620; easing.type: Easing.InOutSine }
        NumberAnimation { from: 0.3; to: 1; duration: 620; easing.type: Easing.InOutSine }
      }
    }

    FlipDigit { value: face.t.mm.charAt(0) }
    FlipDigit { value: face.t.mm.charAt(1) }

    Text {
      visible: face.showSeconds
      anchors.verticalCenter: parent.verticalCenter
      text: ":"
      color: face.accent
      font.family: face.monoFamily
      font.pixelSize: Math.round(face.ch * 0.5)
      font.weight: Font.Bold
    }
    FlipDigit { visible: face.showSeconds; value: face.t.ss.charAt(0) }
    FlipDigit { visible: face.showSeconds; value: face.t.ss.charAt(1) }
  }
}
