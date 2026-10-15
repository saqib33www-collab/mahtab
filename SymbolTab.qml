import QtQuick
import qs.Commons

// One clickable symbol button for the settings footer: a drawn clock or
// visualizer mark, highlighted and accented while its group is the active tab.
Item {
  id: root

  property string kind: "clock"
  property bool active: false
  property color foreground: Color.foreground
  property real iconSize: 20

  signal activated()

  readonly property color tint: root.active
    ? Color.accent
    : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b,
              tabMouse.containsMouse ? 0.75 : 0.45)

  implicitWidth: root.iconSize + Style.space(18)
  implicitHeight: root.iconSize + Style.space(10)

  Rectangle {
    anchors.fill: parent
    radius: height / 2
    color: root.active
      ? Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.16)
      : (tabMouse.containsMouse
         ? Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.08)
         : "transparent")
  }

  ClockSymbol {
    anchors.centerIn: parent
    width: root.iconSize
    height: root.iconSize
    color: root.tint
    visible: root.kind !== "viz"
  }

  VizSymbol {
    anchors.centerIn: parent
    width: root.iconSize
    height: root.iconSize
    color: root.tint
    visible: root.kind === "viz"
  }

  MouseArea {
    id: tabMouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.activated()
  }
}
