import QtQuick
import "ClockModel.js" as Clock
import "Kana.js" as Kana

// Mahtab face. Highly inspired by the Kronos Omarchy plugin (MASH2RAFI):
// a minimal greeting card with a vertical rule, a two-line
// "GOOD <time of day>" greeting, the weekday
// drawn in an angular faux-kana stroke alphabet, the date and time, closed by
// a second rule. Composed in a fixed 431x765 box scaled by `faceScale`, so a
// scale of 1 is pixel-identical to the reference design.
Item {
  id: face

  property real faceScale: 1
  property bool use24h: false
  property color ink: "#e9eaec"
  property string fontFamily: "sans-serif"
  property bool cardEnabled: true
  property color cardColor: "#101315"
  property real cardAlpha: 0.9
  property int cornerRadius: 16
  property date now: new Date()

  readonly property var t: Clock.clockParts(now, use24h)
  readonly property var dp: Clock.dateParts(now)
  readonly property string greetWord: Clock.greeting(now.getHours())

  implicitWidth: box.width * faceScale
  implicitHeight: box.height * faceScale

  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: face.now = new Date()
  }

  // Canvas takes a CSS color string; QML colors expose 0..1 channels.
  function inkCss() {
    return "rgba("
      + Math.round(ink.r * 255) + ","
      + Math.round(ink.g * 255) + ","
      + Math.round(ink.b * 255) + ","
      + ink.a + ")"
  }

  Item {
    id: box
    width: 431
    height: 765
    transform: Scale { xScale: face.faceScale; yScale: face.faceScale }

    Rectangle {
      visible: face.cardEnabled
      anchors.fill: parent
      radius: face.cornerRadius
      color: Qt.rgba(face.cardColor.r, face.cardColor.g, face.cardColor.b, face.cardAlpha)
    }

    Column {
      anchors.horizontalCenter: parent.horizontalCenter
      y: 120
      spacing: 26

      Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        width: 2
        height: 70
        color: face.ink
        opacity: 0.85
      }

      Column {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 12

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: "GOOD"
          color: face.ink
          font.family: face.fontFamily
          font.weight: Font.Medium
          font.pixelSize: 26
          font.letterSpacing: 10
        }

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: face.greetWord.toUpperCase()
          color: face.ink
          font.family: face.fontFamily
          font.weight: Font.Medium
          font.pixelSize: 26
          font.letterSpacing: 10
        }
      }

      Canvas {
        id: wk
        anchors.horizontalCenter: parent.horizontalCenter
        readonly property string txt: face.dp.weekdayShort
        readonly property real cell: 62
        readonly property real gap: 20
        property color inkColor: face.ink
        width: Kana.width(txt, cell, gap) + 12
        height: cell + 12
        onTxtChanged: requestPaint()
        onInkColorChanged: requestPaint()
        onPaint: {
          var c = getContext("2d")
          c.reset()
          c.clearRect(0, 0, width, height)
          Kana.draw(c, txt, 6, 6, cell, gap, 11, face.inkCss())
        }
        Component.onCompleted: requestPaint()
      }

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: face.dp.dom + " " + face.dp.month
        color: face.ink
        font.family: face.fontFamily
        font.weight: Font.DemiBold
        font.pixelSize: 22
        font.letterSpacing: 4
      }

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: face.t.hh + ":" + face.t.mm + (use24h ? "" : " " + face.t.ampm)
        color: face.ink
        font.family: face.fontFamily
        font.weight: Font.Medium
        font.pixelSize: 22
        font.letterSpacing: 3
      }

      Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        width: 2
        height: 70
        color: face.ink
        opacity: 0.85
      }
    }
  }
}
