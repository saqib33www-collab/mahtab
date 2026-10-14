pragma ComponentBehavior: Bound

import QtQuick
import "ClockModel.js" as Clock

// Banner face: one wide line reading "hh:mm AP - MM/DD", big and calm, with a
// soft halo behind the ink so it stays legible on any wallpaper.
// Ported from the Ryoku shell's ClockBanner.qml.
BaseFace {
  id: face

  readonly property real px: Math.round(150 * faceScale)
  readonly property real track: Math.round(px * -0.01)

  implicitWidth: row.implicitWidth + pad * 2
  implicitHeight: row.implicitHeight + pad * 2

  Row {
    id: row
    anchors.centerIn: parent
    spacing: Math.round(face.px * 0.16)

    Row {
      id: hm
      spacing: 0
      anchors.verticalCenter: parent.verticalCenter
      Text {
        text: face.t.hh
        color: face.ink
        font.family: face.fontFamily
        font.weight: Font.Bold
        font.pixelSize: face.px
        font.letterSpacing: face.track
      }
      Text {
        text: ":"
        color: face.accent
        font.family: face.fontFamily
        font.weight: Font.Bold
        font.pixelSize: face.px
        font.letterSpacing: face.track
      }
      Text {
        text: face.t.mm
        color: face.ink
        font.family: face.fontFamily
        font.weight: Font.Bold
        font.pixelSize: face.px
        font.letterSpacing: face.track
      }
    }

    Text {
      visible: !face.use24h
      anchors.bottom: hm.bottom
      anchors.bottomMargin: Math.round(face.px * 0.14)
      text: face.t.ampm
      color: face.inkDim
      font.family: face.fontFamily
      font.weight: Font.DemiBold
      font.pixelSize: Math.round(face.px * 0.24)
      font.letterSpacing: 2
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: "\u2013"
      color: face.inkDim
      font.family: face.fontFamily
      font.weight: Font.Bold
      font.pixelSize: face.px
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: Clock.pad2(face.dp.mon + 1) + "/" + Clock.pad2(face.dp.dom)
      color: face.ink
      font.family: face.fontFamily
      font.weight: Font.Bold
      font.pixelSize: face.px
      font.letterSpacing: face.track
    }
  }
}
