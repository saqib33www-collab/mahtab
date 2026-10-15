import QtQuick
import qs.Commons
import qs.Ui

Column {
  id: root

  property QtObject bar: null
  property string label: ""
  property string helpText: ""
  property real minimum: 0
  property real maximum: 1
  property real step: 0.05
  property bool integer: false
  property real value: 0
  property string valueText: ""

  signal moved(real value)
  signal released(real value)

  width: parent ? parent.width : implicitWidth
  spacing: Style.spacing.md

  Text {
    width: parent.width
    visible: root.label !== ""
    text: root.label
    color: Qt.darker(Color.foreground, 1.4)
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
    font.bold: true
  }

  Row {
    width: parent.width
    spacing: Style.spacing.md

    PanelSlider {
      id: slider
      bar: root.bar
      width: parent.width - valueLabel.width - parent.spacing
      minimum: root.minimum
      maximum: root.maximum
      step: root.step
      integer: root.integer
      value: root.value
      onMoved: function(v) { root.moved(v) }
      onReleased: function(v) { root.released(v) }

      // Take wheel events off the slider so scrolling never nudges a value.
      // The event is consumed here and handed to the enclosing flickable, so
      // the panel still scrolls while the slider only changes on click/drag.
      MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: function(wheel) {
          wheel.accepted = true
          var target = parent
          while (target && target.contentY === undefined) target = target.parent
          if (target) {
            var maxY = Math.max(0, target.contentHeight - target.height)
            target.contentY = Math.max(0, Math.min(maxY, target.contentY - wheel.angleDelta.y))
          }
        }
      }
    }

    Text {
      id: valueLabel
      anchors.verticalCenter: parent.verticalCenter
      width: Style.space(44)
      horizontalAlignment: Text.AlignRight
      text: root.valueText
      color: Color.foreground
      font.family: Style.font.family
      font.pixelSize: Style.font.bodySmall
    }
  }

  Text {
    width: parent.width
    visible: root.helpText !== ""
    wrapMode: Text.WordWrap
    text: root.helpText
    color: Qt.darker(Color.foreground, 1.45)
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
  }
}
