import QtQuick
import qs.Commons
import "ClockModel.js" as Clock

// Shared scaffold for the ported Ryoku clock faces. It exposes the same knob
// surface as GrandFace (faceScale / use24h / showSeconds / ink / accent / fonts
// / card) plus the date fields, so Service.qml can drive every face identically.
// Concrete faces set implicitWidth/Height and lay their content out against
// `parent`; the card rectangle below simply hugs whatever size they declare.
Item {
  id: face

  property real faceScale: 1
  // Smooth the scale changes driven by scrolling or the settings slider.
  Behavior on faceScale {
    NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
  }
  property bool use24h: false
  property bool showSeconds: true
  property color ink: Color.foreground
  property color accent: Color.accent
  property color shadowColor: Qt.rgba(0, 0, 0, 0.55)
  property string fontFamily: Style.font.family
  property string labelFontFamily: Style.font.family
  property string monoFamily: "JetBrainsMono Nerd Font"
  property bool cardEnabled: false
  property color cardColor: Color.background
  property real cardAlpha: 0.7
  property int cornerRadius: Style.cornerRadius > 0 ? Style.cornerRadius : 16
  property date now: new Date()

  readonly property var t: Clock.clockParts(now, use24h)
  readonly property var dp: Clock.dateParts(now)
  readonly property bool side: showSeconds || !use24h
  readonly property color inkDim: Qt.rgba(ink.r, ink.g, ink.b, 0.7)
  readonly property color inkSoft: Qt.rgba(ink.r, ink.g, ink.b, 0.85)
  // a single-family name for Canvas text (font stacks break the canvas parser).
  readonly property string canvasFont: String(fontFamily).split(",")[0].trim()
  // Card padding keeps the frame from cropping the glyphs.
  readonly property int pad: cardEnabled ? Math.round(24 * faceScale) : 0

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
}
