pragma ComponentBehavior: Bound

import QtQuick

// Outline face: the time as giant hollow-stroked numerals so the wallpaper reads
// through the digits, with a filled accent colon anchoring it.
// Ported from the Ryoku shell's ClockOutline.qml.
BaseFace {
  id: face

  readonly property real px: Math.round(190 * faceScale)

  implicitWidth: row.implicitWidth + pad * 2
  implicitHeight: row.implicitHeight + pad * 2

  component Hollow: Item {
    id: hollow
    property string txt: ""
    property color col: "#ffffff"
    property real ps: 90
    property real lw: 3
    implicitWidth: meas.implicitWidth + lw * 2
    implicitHeight: ps * 1.02

    Text {
      id: meas
      visible: false
      text: hollow.txt
      font.family: face.fontFamily
      font.weight: Font.Bold
      font.pixelSize: hollow.ps
    }

    Canvas {
      anchors.fill: parent
      property var key: [hollow.txt, hollow.ps, hollow.lw, hollow.col]
      onKeyChanged: requestPaint()
      Component.onCompleted: requestPaint()
      onPaint: {
        var c = getContext("2d")
        c.reset()
        c.clearRect(0, 0, width, height)
        c.font = "700 " + hollow.ps + "px '" + face.canvasFont + "'"
        c.textBaseline = "alphabetic"
        c.lineWidth = hollow.lw
        c.strokeStyle = hollow.col
        c.lineJoin = "round"
        var x = hollow.lw
        var y = hollow.ps * 0.82
        for (var i = 0; i < hollow.txt.length; i++) {
          c.strokeText(hollow.txt[i], x, y)
          x += c.measureText(hollow.txt[i]).width
        }
      }
    }
  }

  Row {
    id: row
    anchors.centerIn: parent
    spacing: Math.round(6 * face.faceScale)

    Hollow {
      anchors.verticalCenter: parent.verticalCenter
      txt: face.t.hh
      col: face.ink
      ps: face.px
      lw: Math.max(2, 3 * face.faceScale)
    }
    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: ":"
      color: face.accent
      font.family: face.fontFamily
      font.weight: Font.Bold
      font.pixelSize: face.px
    }
    Hollow {
      anchors.verticalCenter: parent.verticalCenter
      txt: face.t.mm
      col: face.ink
      ps: face.px
      lw: Math.max(2, 3 * face.faceScale)
    }
  }
}
