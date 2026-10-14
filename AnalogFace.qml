pragma ComponentBehavior: Bound

import QtQuick

// Analog face: clean dial, twelve ticks (quarters bright), ink hour + minute
// hands and a thin accent second hand over an accent hub.
// Ported from the Ryoku shell's ClockAnalog.qml.
BaseFace {
  id: face

  readonly property real dia: Math.round(220 * faceScale)
  readonly property real s: faceScale

  implicitWidth: dia + pad * 2
  implicitHeight: dia + pad * 2

  Item {
    id: dial
    anchors.fill: parent
    anchors.margins: face.pad

    Rectangle {
      anchors.fill: parent
      radius: width / 2
      color: "transparent"
      border.width: Math.max(1, face.s)
      border.color: Qt.rgba(face.ink.r, face.ink.g, face.ink.b, 0.14)
    }

    Repeater {
      model: 12
      Item {
        required property int index
        readonly property bool major: index % 3 === 0
        anchors.fill: parent
        rotation: index * 30
        Rectangle {
          anchors.horizontalCenter: parent.horizontalCenter
          y: Math.round(8 * face.faceScale)
          width: parent.major ? Math.round(4 * face.faceScale) : Math.round(2 * face.faceScale)
          height: parent.major ? Math.round(15 * face.faceScale) : Math.round(8 * face.faceScale)
          radius: width / 2
          color: parent.major ? face.ink : face.inkDim
        }
      }
    }

    Rectangle {
      x: (dial.width - width) / 2
      y: dial.height / 2 - height
      width: Math.round(8 * face.faceScale)
      height: dial.height * 0.28
      radius: width / 2
      color: face.ink
      antialiasing: true
      transformOrigin: Item.Bottom
      rotation: face.t.hourAngle
    }

    Rectangle {
      x: (dial.width - width) / 2
      y: dial.height / 2 - height
      width: Math.round(6 * face.faceScale)
      height: dial.height * 0.40
      radius: width / 2
      color: face.ink
      antialiasing: true
      transformOrigin: Item.Bottom
      rotation: face.t.minuteAngle
    }

    Rectangle {
      x: (dial.width - width) / 2
      y: dial.height / 2 - height
      width: Math.max(2, Math.round(2.5 * face.faceScale))
      height: dial.height * 0.44
      radius: width / 2
      color: face.accent
      antialiasing: true
      transformOrigin: Item.Bottom
      rotation: face.t.secondAngle
    }

    Rectangle {
      anchors.centerIn: parent
      width: Math.round(14 * face.faceScale)
      height: width
      radius: width / 2
      color: face.accent
      border.width: Math.max(1, Math.round(2 * face.faceScale))
      border.color: face.ink
    }
  }
}
