pragma ComponentBehavior: Bound

import QtQuick
import "ClockModel.js" as Clock

// Big-hour face: a giant hour with the minute (solid) over the second (hollow)
// at its right, and the weekday/day plus a hollow-stroked month down its left.
// Ported from the Ryoku shell's ClockBigHour.qml.
BaseFace {
  id: face

  readonly property string monthName: dp.month

  implicitWidth: row.implicitWidth + pad * 2
  implicitHeight: row.implicitHeight + pad * 2

  component Hollow: Item {
    id: hollow
    property string txt: ""
    property real ps: 90
    property int weight: Font.Black
    property real lw: 3
    property real track: 0
    implicitWidth: meas.implicitWidth + lw * 2
    implicitHeight: ps * 1.02

    Text {
      id: meas
      visible: false
      text: hollow.txt
      font.family: face.fontFamily
      font.weight: hollow.weight
      font.pixelSize: hollow.ps
      font.letterSpacing: hollow.track
    }
    Canvas {
      anchors.fill: parent
      property var key: [hollow.txt, hollow.ps, hollow.lw, hollow.track]
      onKeyChanged: requestPaint()
      Component.onCompleted: requestPaint()
      onPaint: {
        var c = getContext("2d")
        c.reset(); c.clearRect(0, 0, width, height)
        var wt = hollow.weight >= Font.Black ? 900 : (hollow.weight >= Font.Bold ? 700 : 400)
        c.font = wt + " " + hollow.ps + "px '" + face.canvasFont + "'"
        c.textBaseline = "alphabetic"
        c.lineWidth = hollow.lw
        c.strokeStyle = face.ink
        c.lineJoin = "round"
        var x = hollow.lw, y = hollow.ps * 0.80
        for (var i = 0; i < hollow.txt.length; i++) {
          c.strokeText(hollow.txt[i], x, y)
          x += c.measureText(hollow.txt[i]).width + hollow.track
        }
      }
    }
  }

  Row {
    id: row
    anchors.centerIn: parent
    spacing: Math.round(22 * face.faceScale)

    Column {
      anchors.bottom: parent.bottom
      spacing: Math.round(2 * face.faceScale)
      Text {
        text: face.dp.weekdayShort + ", " + Clock.pad2(face.dp.dom)
        color: face.ink
        font.family: face.fontFamily
        font.weight: Font.Bold
        font.pixelSize: Math.round(33 * face.faceScale)
        font.letterSpacing: 2
      }
      Hollow {
        txt: face.monthName
        ps: Math.round(74 * face.faceScale)
        lw: Math.max(1.4, 2.0 * face.faceScale)
        track: 1
      }
      Item { width: 1; height: Math.round(30 * face.faceScale) }
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: face.t.hh
      color: face.ink
      font.family: face.fontFamily
      font.weight: Font.Black
      font.pixelSize: Math.round(300 * face.faceScale)
      font.letterSpacing: Math.round(-8 * face.faceScale)
    }

    Column {
      anchors.verticalCenter: parent.verticalCenter
      spacing: 0
      Text {
        text: face.t.mm
        color: face.ink
        font.family: face.fontFamily
        font.weight: Font.Black
        font.pixelSize: Math.round(116 * face.faceScale)
        font.letterSpacing: Math.round(-4 * face.faceScale)
      }
      Hollow {
        visible: face.showSeconds
        txt: face.t.ss
        ps: Math.round(116 * face.faceScale)
        lw: Math.max(1.8, 2.6 * face.faceScale)
      }
    }
  }
}
