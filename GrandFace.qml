import QtQuick
import qs.Commons
import "ClockModel.js" as Clock

// "Grand" layout: one big editorial time set in a display serif, with the colon
// (and the optional seconds) carrying the accent. Made for depth -- a calm,
// oversized numeral the wallpaper can sit behind.
//
// Ported from the Ryoku shell's desktop clock face ClockGrand.qml.
Item {
  id: face

  property real faceScale: 1
  Behavior on faceScale {
    NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
  }
  property bool use24h: false
  property bool showSeconds: true
  property color ink: Color.foreground
  property color accent: Color.accent
  property string fontFamily: "Noto Serif, serif"
  property string labelFontFamily: Style.font.family
  property bool cardEnabled: false
  property color cardColor: Color.background
  property real cardAlpha: 0.9
  property int cornerRadius: Style.cornerRadius
  property date now: new Date()

  readonly property var t: Clock.clockParts(now, use24h)
  readonly property bool side: showSeconds || !use24h
  readonly property real px: Math.round(168 * faceScale)
  readonly property color inkDim: Qt.darker(ink, 1.5)
  // Card padding scales with the numerals so the frame always hugs the time.
  readonly property int pad: cardEnabled ? Math.round(px * 0.22) : 0

  implicitWidth: row.implicitWidth + pad * 2
  implicitHeight: row.implicitHeight + pad * 2

  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: face.now = new Date()
  }

  Rectangle {
    visible: face.cardEnabled
    anchors.fill: parent
    radius: face.cornerRadius
    color: Qt.rgba(face.cardColor.r, face.cardColor.g, face.cardColor.b, face.cardAlpha)
  }

  Row {
    id: row
    anchors.centerIn: parent
    spacing: face.side ? Math.round(18 * face.faceScale) : 0

    Row {
      id: hm
      spacing: 0
      Text {
        text: face.t.hh
        color: face.ink
        font.family: face.fontFamily
        font.weight: Font.Medium
        font.pixelSize: face.px
      }
      Text {
        text: ":"
        color: face.accent
        font.family: face.fontFamily
        font.weight: Font.Medium
        font.pixelSize: face.px
      }
      Text {
        text: face.t.mm
        color: face.ink
        font.family: face.fontFamily
        font.weight: Font.Medium
        font.pixelSize: face.px
      }
    }

    Item {
      height: hm.height
      width: Math.max(secs.implicitWidth, ampm.implicitWidth)
      visible: face.side
      Column {
        anchors.verticalCenter: parent.verticalCenter
        spacing: Math.round(6 * face.faceScale)
        Text {
          id: secs
          visible: face.showSeconds
          text: face.t.ss
          color: face.accent
          font.family: face.fontFamily
          font.pixelSize: Math.round(face.px * 0.26)
          font.weight: Font.Medium
        }
        Text {
          id: ampm
          visible: !face.use24h
          text: face.t.ampm
          color: face.inkDim
          font.family: face.labelFontFamily
          font.pixelSize: Math.round(face.px * 0.15)
          font.weight: Font.DemiBold
          font.letterSpacing: 3
        }
      }
    }
  }
}
